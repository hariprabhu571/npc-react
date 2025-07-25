<?php
// user-bookings.php - Updated for your actual bookings table structure

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

// GET - Fetch user bookings by session ID
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_GET['booking_id'])) {
    try {
        $sessionId = isset($_GET['session_id']) ? trim($_GET['session_id']) : null;
        
        if (!$sessionId) {
            http_response_code(400);
            echo json_encode(['error' => 'Session ID is required']);
            exit;
        }
        
        // First, get user details from session
        $userQuery = "SELECT user_id, customer_name, email_id, mobile_number, address1, address2 FROM users WHERE sessionid = ?";
        $userStmt = $conn->prepare($userQuery);
        
        if (!$userStmt) {
            throw new Exception("Failed to prepare user query: " . $conn->error);
        }
        
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $userData = $userResult->fetch_assoc();
        
        if (!$userData) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found with provided session ID']);
            exit;
        }
        
        // Format user data for response
        $user = [
            'id' => $userData['user_id'],
            'name' => $userData['customer_name'],
            'email' => $userData['email_id'],
            'phone' => $userData['mobile_number'],
            'address' => trim(($userData['address1'] ?? '') . ' ' . ($userData['address2'] ?? ''))
        ];
        
        // Get user's bookings using your actual bookings table structure
        $bookingsQuery = "
            SELECT 
                booking_id,
                user_id,
                service_name,
                service_date,
                time_slot,
                service_address,
                special_notes,
                subtotal,
                discount_amount,
                coupon_code,
                coupon_discount,
                total_amount,
                payment_method,
                payment_status,
                razorpay_order_id,
                razorpay_payment_id,
                booking_status,
                created_at,
                updated_at
            FROM bookings 
            WHERE user_id = ?
            ORDER BY created_at DESC
        ";
        
        $bookingsStmt = $conn->prepare($bookingsQuery);
        
        if (!$bookingsStmt) {
            throw new Exception("Failed to prepare bookings query: " . $conn->error);
        }
        
        $bookingsStmt->bind_param("i", $userData['user_id']);
        $bookingsStmt->execute();
        $bookingsResult = $bookingsStmt->get_result();
        $bookings = $bookingsResult->fetch_all(MYSQLI_ASSOC);
        
        // Process and categorize bookings
        $activeBookings = [];
        $completedBookings = [];
        $cancelledBookings = [];
        
        foreach ($bookings as $booking) {
            // Format the booking data to match expected response structure
            $formattedBooking = [
                'booking_id' => $booking['booking_id'],
                'service_id' => null, // Not available in your schema
                'service_name' => $booking['service_name'] ?? 'Unknown Service',
                'service_description' => $booking['special_notes'] ?? 'Professional service as per your requirements',
                'service_image' => null, // Not available in your schema
                'category' => 'Home Service', // Default category
                'space_type' => 'Standard', // Not available in your schema, using default
                'item_total' => (float)$booking['subtotal'],
                'taxes' => (float)$booking['discount_amount'], // Using discount as taxes for now
                'total_amount' => (float)$booking['total_amount'],
                'booking_date' => $booking['created_at'] ? date('Y-m-d', strtotime($booking['created_at'])) : null,
                'service_date' => $booking['service_date'],
                'service_time' => $booking['time_slot'] ?? 'N/A',
                'status' => $booking['booking_status'],
                'address' => $booking['service_address'],
                'special_instructions' => $booking['special_notes'],
                'payment_mode' => $booking['payment_method'],
                'payment_status' => $booking['payment_status'],
                'payment_id' => $booking['razorpay_payment_id'],
                'created_at' => $booking['created_at'],
                'updated_at' => $booking['updated_at']
            ];
            
            // Format dates safely
            $formattedBooking['booking_date_formatted'] = $formattedBooking['booking_date'] ? date('d M Y', strtotime($formattedBooking['booking_date'])) : 'N/A';
            $formattedBooking['service_date_formatted'] = $formattedBooking['service_date'] ? date('d M Y', strtotime($formattedBooking['service_date'])) : 'N/A';
            $formattedBooking['created_at_formatted'] = $formattedBooking['created_at'] ? date('d M Y, h:i A', strtotime($formattedBooking['created_at'])) : 'N/A';
            
            // Check 24-hour cancellation policy for active bookings
            $canCancel = false;
            if (in_array(strtolower($booking['booking_status']), ['pending', 'confirmed', 'in_progress'])) {
                $serviceDateTime = $booking['service_date'];
                $timeSlot = $booking['time_slot'] ?? '';
                
                // Extract start time from time slot
                $startTime = $timeSlot;
                if (strpos($timeSlot, ' - ') !== false) {
                    $startTime = trim(explode(' - ', $timeSlot)[0]);
                }
                
                // Combine service date and start time
                if ($serviceDateTime && $startTime) {
                    try {
                        $serviceTimestamp = strtotime($serviceDateTime . ' ' . $startTime);
                        if ($serviceTimestamp) {
                            $currentTimestamp = time();
                            $timeDifference = $serviceTimestamp - $currentTimestamp;
                            $hoursUntilService = $timeDifference / 3600;
                            $canCancel = $hoursUntilService >= 24;
                        }
                    } catch (Exception $e) {
                        $canCancel = false;
                    }
                }
            }
            
            $formattedBooking['can_cancel'] = $canCancel;
            
            // Add status color and icon based on booking_status field
            switch (strtolower($formattedBooking['status'])) {
                case 'completed':
                    $formattedBooking['status_color'] = '#4CAF50';
                    $formattedBooking['status_icon'] = 'check_circle';
                    $completedBookings[] = $formattedBooking;
                    break;
                    
                case 'cancelled':
                    $formattedBooking['status_color'] = '#f44336';
                    $formattedBooking['status_icon'] = 'cancel';
                    $cancelledBookings[] = $formattedBooking;
                    break;
                    
                case 'pending':
                    $formattedBooking['status_color'] = '#FFC107';
                    $formattedBooking['status_icon'] = 'hourglass_empty';
                    $activeBookings[] = $formattedBooking;
                    break;
                    
                case 'confirmed':
                    $formattedBooking['status_color'] = '#2196F3';
                    $formattedBooking['status_icon'] = 'check';
                    $activeBookings[] = $formattedBooking;
                    break;
                    
                case 'in_progress':
                    $formattedBooking['status_color'] = '#FF9800';
                    $formattedBooking['status_icon'] = 'build';
                    $activeBookings[] = $formattedBooking;
                    break;
                    
                default:
                    // Fallback for any other status
                    $formattedBooking['status_color'] = '#9E9E9E';
                    $formattedBooking['status_icon'] = 'help';
                    $activeBookings[] = $formattedBooking;
                    break;
            }
        }
        
        // Calculate summary statistics
        $totalBookings = count($bookings);
        $totalSpent = array_sum(array_column($bookings, 'total_amount'));
        $activeCount = count($activeBookings);
        $completedCount = count($completedBookings);
        
        $response = [
            'user' => $user,
            'summary' => [
                'total_bookings' => $totalBookings,
                'total_spent' => $totalSpent,
                'active_bookings' => $activeCount,
                'completed_bookings' => $completedCount
            ],
            'bookings' => [
                'active' => $activeBookings,
                'completed' => $completedBookings,
                'cancelled' => $cancelledBookings
            ]
        ];
        
        http_response_code(200);
        echo json_encode($response);
        
    } catch (Exception $e) {
        error_log("Booking fetch error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'error' => 'Database error occurred',
            'message' => $e->getMessage(),
            'debug_info' => [
                'session_id' => isset($sessionId) ? $sessionId : 'not provided',
                'user_found' => isset($userData) ? 'yes' : 'no'
            ]
        ]);
    }
}

// GET - Fetch specific booking details
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['booking_id'])) {
    try {
        $bookingId = $_GET['booking_id'];
        $sessionId = isset($_GET['session_id']) ? trim($_GET['session_id']) : null;
        
        if (!$sessionId || !$bookingId) {
            http_response_code(400);
            echo json_encode(['error' => 'Session ID and Booking ID are required']);
            exit;
        }
        
        // Get user ID from session
        $userStmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ?");
        if (!$userStmt) {
            throw new Exception("Failed to prepare user query: " . $conn->error);
        }
        
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $user = $userResult->fetch_assoc();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            exit;
        }
        
        // Get booking details
        $bookingQuery = "
            SELECT 
                booking_id,
                user_id,
                service_name,
                service_date,
                time_slot,
                service_address,
                special_notes,
                subtotal,
                discount_amount,
                coupon_code,
                coupon_discount,
                total_amount,
                payment_method,
                payment_status,
                razorpay_order_id,
                razorpay_payment_id,
                booking_status,
                created_at,
                updated_at
            FROM bookings
            WHERE booking_id = ? AND user_id = ?
        ";
        
        $bookingStmt = $conn->prepare($bookingQuery);
        if (!$bookingStmt) {
            throw new Exception("Failed to prepare booking query: " . $conn->error);
        }
        
        $bookingStmt->bind_param("si", $bookingId, $user['user_id']);
        $bookingStmt->execute();
        $bookingResult = $bookingStmt->get_result();
        $bookingData = $bookingResult->fetch_assoc();
        
        if (!$bookingData) {
            http_response_code(404);
            echo json_encode(['error' => 'Booking not found']);
            exit;
        }
        
        // Format response
        $booking = [
            'booking_id' => $bookingData['booking_id'],
            'service_name' => $bookingData['service_name'] ?? 'Unknown Service',
            'service_description' => $bookingData['special_notes'] ?? 'Professional service as per your requirements',
            'service_image' => null,
            'category' => 'Home Service',
            'space_type' => 'Standard',
            'item_total' => (float)$bookingData['subtotal'],
            'taxes' => (float)$bookingData['discount_amount'],
            'total_amount' => (float)$bookingData['total_amount'],
            'booking_date' => $bookingData['created_at'] ? date('Y-m-d', strtotime($bookingData['created_at'])) : null,
            'service_date' => $bookingData['service_date'],
            'service_time' => $bookingData['time_slot'] ?? 'N/A',
            'status' => $bookingData['booking_status'],
            'address' => $bookingData['service_address'],
            'special_instructions' => $bookingData['special_notes'],
            'payment_mode' => $bookingData['payment_method'],
            'payment_status' => $bookingData['payment_status'],
            'payment_id' => $bookingData['razorpay_payment_id']
        ];
        
        // Format dates
        $booking['booking_date_formatted'] = $booking['booking_date'] ? date('d M Y', strtotime($booking['booking_date'])) : 'N/A';
        $booking['service_date_formatted'] = $booking['service_date'] ? date('d M Y', strtotime($booking['service_date'])) : 'N/A';
        $booking['created_at_formatted'] = $bookingData['created_at'] ? date('d M Y, h:i A', strtotime($bookingData['created_at'])) : 'N/A';
        
        http_response_code(200);
        echo json_encode($booking);
        
    } catch (Exception $e) {
        error_log("Single booking fetch error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
    }
}

// POST - Update booking status (for cancellation, etc.)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON data']);
            exit;
        }
        
        $bookingId = isset($data['booking_id']) ? trim($data['booking_id']) : null;
        $sessionId = isset($data['session_id']) ? trim($data['session_id']) : null;
        $action = isset($data['action']) ? trim($data['action']) : null;
        
        if (!$bookingId || !$sessionId || !$action) {
            http_response_code(400);
            echo json_encode(['error' => 'Booking ID, Session ID, and action are required']);
            exit;
        }
        
        // Get user ID from session
        $userStmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ?");
        if (!$userStmt) {
            throw new Exception("Failed to prepare user query: " . $conn->error);
        }
        
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $user = $userResult->fetch_assoc();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            exit;
        }
        
        // Check if booking belongs to user
        $checkStmt = $conn->prepare("SELECT booking_id, booking_status FROM bookings WHERE booking_id = ? AND user_id = ?");
        if (!$checkStmt) {
            throw new Exception("Failed to prepare check query: " . $conn->error);
        }
        
        $checkStmt->bind_param("si", $bookingId, $user['user_id']);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        $booking = $checkResult->fetch_assoc();
        
        if (!$booking) {
            http_response_code(404);
            echo json_encode(['error' => 'Booking not found']);
            exit;
        }
        
        // Handle different actions
        switch ($action) {
            case 'cancel':
                // Only allow cancellation for pending, confirmed, and in_progress bookings
                if (in_array(strtolower($booking['booking_status']), ['completed', 'cancelled'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Cannot cancel this booking. Booking is already ' . $booking['booking_status']]);
                    exit;
                }
                
                // Check 24-hour cancellation policy
                $serviceDateTime = $booking['service_date'];
                $timeSlot = isset($booking['time_slot']) ? $booking['time_slot'] : '';
                
                // Extract start time from time slot (e.g., "9:00 AM - 11:00 AM" -> "9:00 AM")
                $startTime = $timeSlot;
                if (strpos($timeSlot, ' - ') !== false) {
                    $startTime = trim(explode(' - ', $timeSlot)[0]);
                }
                
                // Combine service date and start time
                $serviceTimestamp = null;
                if ($serviceDateTime && $startTime) {
                    try {
                        $serviceTimestamp = strtotime($serviceDateTime . ' ' . $startTime);
                    } catch (Exception $e) {
                        // If time parsing fails, just use the date
                        $serviceTimestamp = strtotime($serviceDateTime);
                    }
                }
                
                if ($serviceTimestamp) {
                    $currentTimestamp = time();
                    $timeDifference = $serviceTimestamp - $currentTimestamp;
                    $hoursUntilService = $timeDifference / 3600; // Convert seconds to hours
                    
                    if ($hoursUntilService < 24) {
                        $remainingHours = max(0, round($hoursUntilService, 1));
                        http_response_code(400);
                        echo json_encode([
                            'error' => 'Cannot cancel booking within 24 hours of service time',
                            'message' => "Service is in {$remainingHours} hours. Cancellation must be made at least 24 hours before the scheduled service.",
                            'service_date' => date('d M Y', $serviceTimestamp),
                            'service_time' => $timeSlot,
                            'hours_remaining' => $remainingHours
                        ]);
                        exit;
                    }
                }
                
                $updateStmt = $conn->prepare("UPDATE bookings SET booking_status = 'cancelled', updated_at = NOW() WHERE booking_id = ?");
                if (!$updateStmt) {
                    throw new Exception("Failed to prepare update query: " . $conn->error);
                }
                
                $updateStmt->bind_param("s", $bookingId);
                $updateStmt->execute();
                
                http_response_code(200);
                echo json_encode(['message' => 'Booking cancelled successfully']);
                break;
                
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Invalid action']);
                break;
        }
        
    } catch (Exception $e) {
        error_log("Booking update error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
    }
}
?>