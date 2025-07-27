<?php
// technician_orders.php - Get orders assigned to specific technician

// Prevent any output before JSON response
ob_start();

// Set error reporting to prevent HTML error output
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Technician-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Clear any previous output
ob_clean();

require_once 'conn.php';

// Function to send JSON response and exit
function sendJsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit;
}

// Function to log errors
function logError($message) {
    error_log("Technician Orders Error: " . $message);
}

// GET - Fetch technician's assigned orders
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Get session ID from headers or query parameter
        $sessionId = null;
        $headers = getallheaders();
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'session-id') {
                    $sessionId = trim($value);
                    break;
                }
            }
        }
        if (isset($_GET['session_id']) && empty($sessionId)) {
            $sessionId = trim($_GET['session_id']);
        }
        if (!$sessionId) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Session ID is required'
            ], 401);
        }
        // Validate session in technicians table
        $sessionQuery = "SELECT technician_id, employee_name, phone_number, email FROM technicians WHERE sessionid = ? AND session_expiry > NOW()";
        $sessionStmt = $conn->prepare($sessionQuery);
        if (!$sessionStmt) {
            logError("Failed to prepare session query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        $sessionStmt->bind_param("s", $sessionId);
        $sessionStmt->execute();
        $sessionResult = $sessionStmt->get_result();
        $technician = $sessionResult->fetch_assoc();
        $sessionStmt->close();
        if (!$technician) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Invalid or expired session'
            ], 401);
        }

        // Check database connection
        if (!$conn) {
            logError("Database connection failed");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database connection failed'
            ], 500);
        }

        $actualTechnicianId = $technician['technician_id'];

        // Get assigned bookings with customer details
        $bookingsQuery = "
            SELECT 
                b.booking_id,
                b.service_name,
                b.service_date,
                b.time_slot,
                b.service_address,
                b.special_notes,
                b.total_amount,
                b.booking_status,
                b.created_at,
                u.customer_name,
                u.mobile_number,
                u.email_id
            FROM bookings b
            LEFT JOIN users u ON b.user_id = u.user_id
            WHERE b.assigned_technician = ?
            AND b.booking_status IN ('confirmed', 'in_progress', 'completed')
            ORDER BY 
                CASE 
                    WHEN b.booking_status = 'confirmed' THEN 1
                    WHEN b.booking_status = 'in_progress' THEN 2
                    WHEN b.booking_status = 'completed' THEN 3
                    ELSE 4
                END,
                b.service_date ASC, 
                b.time_slot ASC
        ";
        
        $bookingsStmt = $conn->prepare($bookingsQuery);
        
        if (!$bookingsStmt) {
            logError("Failed to prepare bookings query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        
        $bookingsStmt->bind_param("i", $actualTechnicianId);
        $bookingsStmt->execute();
        $bookingsResult = $bookingsStmt->get_result();
        
        $bookings = [];
        while ($row = $bookingsResult->fetch_assoc()) {
            $bookings[] = $row;
        }
        $bookingsStmt->close();
        
        // Format bookings and get latest technician status from log
        $formattedBookings = [];
        foreach ($bookings as $booking) {
            // Get latest status from technician_status_log
            $statusQuery = "
                SELECT status, timestamp, notes 
                FROM technician_status_log 
                WHERE booking_id = ? AND technician_id = ? 
                ORDER BY timestamp DESC 
                LIMIT 1
            ";
            $statusStmt = $conn->prepare($statusQuery);
            
            $technicianStatus = 'assigned';
            $lastUpdate = $booking['created_at'];
            $lastNotes = '';
            
            if ($statusStmt) {
                $statusStmt->bind_param("si", $booking['booking_id'], $actualTechnicianId);
                $statusStmt->execute();
                $statusResult = $statusStmt->get_result();
                $statusData = $statusResult->fetch_assoc();
                
                if ($statusData) {
                    $technicianStatus = $statusData['status'];
                    $lastUpdate = $statusData['timestamp'];
                    $lastNotes = $statusData['notes'];
                }
                $statusStmt->close();
            }
            
            $formattedBookings[] = [
                'booking_id' => $booking['booking_id'],
                'service_name' => $booking['service_name'] ?? '',
                'service_date' => $booking['service_date'],
                'service_date_formatted' => $booking['service_date'] ? date('d M Y', strtotime($booking['service_date'])) : 'N/A',
                'time_slot' => $booking['time_slot'] ?? '',
                'service_address' => $booking['service_address'] ?? '',
                'special_notes' => $booking['special_notes'] ?? '',
                'total_amount' => (float)($booking['total_amount'] ?? 0),
                'booking_status' => $booking['booking_status'] ?? '',
                'technician_status' => $technicianStatus,
                'customer_name' => $booking['customer_name'] ?? '',
                'customer_phone' => $booking['mobile_number'] ?? '',
                'customer_email' => $booking['email_id'] ?? '',
                'created_at' => $booking['created_at'],
                'last_update' => $lastUpdate,
                'last_update_formatted' => date('d M Y, h:i A', strtotime($lastUpdate)),
                'last_notes' => $lastNotes,
                
                // Additional helper fields
                'can_mark_reached' => $technicianStatus === 'assigned',
                'can_start_work' => $technicianStatus === 'reached',
                'can_complete' => $technicianStatus === 'started',
                'is_completed' => $technicianStatus === 'completed',
                
                // Status display
                'status_display' => ucfirst($technicianStatus),
                'status_color' => getStatusColor($technicianStatus),
                'next_action' => getNextAction($technicianStatus)
            ];
        }
        
        // Group bookings by status for easier frontend handling
        $assignedBookings = array_filter($formattedBookings, function($b) { 
            return $b['technician_status'] === 'assigned'; 
        });
        $activeBookings = array_filter($formattedBookings, function($b) { 
            return in_array($b['technician_status'], ['reached', 'started']); 
        });
        $completedBookings = array_filter($formattedBookings, function($b) { 
            return $b['technician_status'] === 'completed'; 
        });
        
        $response = [
            'status' => 'success',
            'message' => 'Orders retrieved successfully',
            'technician' => [
                'technician_id' => $technician['technician_id'],
                'employee_name' => $technician['employee_name'] ?? '',
                'phone_number' => $technician['phone_number'] ?? '',
                'email' => $technician['email'] ?? ''
            ],
            'bookings' => $formattedBookings,
            'summary' => [
                'total_orders' => count($formattedBookings),
                'assigned_count' => count($assignedBookings),
                'active_count' => count($activeBookings),
                'completed_count' => count($completedBookings)
            ],
            'grouped_bookings' => [
                'assigned' => array_values($assignedBookings),
                'active' => array_values($activeBookings),
                'completed' => array_values($completedBookings)
            ]
        ];
        
        sendJsonResponse($response, 200);
        
    } catch (Exception $e) {
        logError("Exception in GET request: " . $e->getMessage());
        sendJsonResponse([
            'status' => 'error',
            'message' => 'An error occurred while fetching orders',
            'debug' => $e->getMessage() // Remove this in production
        ], 500);
    }
}

// POST - Update technician status for a booking
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get session ID from headers or query parameter
        $sessionId = null;
        $headers = getallheaders();
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'session-id') {
                    $sessionId = trim($value);
                    break;
                }
            }
        }
        if (isset($_GET['session_id']) && empty($sessionId)) {
            $sessionId = trim($_GET['session_id']);
        }
        if (!$sessionId) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Session ID is required'
            ], 401);
        }
        // Validate session in technicians table
        $sessionQuery = "SELECT technician_id, employee_name FROM technicians WHERE sessionid = ? AND session_expiry > NOW()";
        $sessionStmt = $conn->prepare($sessionQuery);
        if (!$sessionStmt) {
            logError("Failed to prepare session query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        $sessionStmt->bind_param("s", $sessionId);
        $sessionStmt->execute();
        $sessionResult = $sessionStmt->get_result();
        $technician = $sessionResult->fetch_assoc();
        $sessionStmt->close();
        if (!$technician) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Invalid or expired session'
            ], 401);
        }
        
        // Check database connection
        if (!$conn) {
            logError("Database connection failed");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database connection failed'
            ], 500);
        }

        $actualTechnicianId = $technician['technician_id'];

        // Get POST data
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        if (!$data) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Invalid JSON data'
            ], 400);
        }
        
        $bookingId = isset($data['booking_id']) ? trim($data['booking_id']) : null;
        $status = isset($data['status']) ? trim($data['status']) : null;
        $notes = isset($data['notes']) ? trim($data['notes']) : null;
        
        if (!$bookingId || !$status) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Booking ID and status are required'
            ], 400);
        }

        // Validate status
        $validStatuses = ['assigned', 'reached', 'started', 'completed'];
        if (!in_array($status, $validStatuses)) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Invalid status. Valid statuses: ' . implode(', ', $validStatuses)
            ], 400);
        }

        // Start transaction
        $conn->begin_transaction();

        try {
            // Check if booking exists and is assigned to this technician
            $bookingQuery = "
                SELECT booking_id, assigned_technician, booking_status, user_id, service_name 
                FROM bookings 
                WHERE booking_id = ? AND assigned_technician = ?
            ";
            $bookingStmt = $conn->prepare($bookingQuery);
            
            if (!$bookingStmt) {
                throw new Exception("Failed to prepare booking query: " . $conn->error);
            }
            
            $bookingStmt->bind_param("si", $bookingId, $actualTechnicianId);
            $bookingStmt->execute();
            $bookingResult = $bookingStmt->get_result();
            $booking = $bookingResult->fetch_assoc();
            $bookingStmt->close();
            
            if (!$booking) {
                $conn->rollback();
                sendJsonResponse([
                    'status' => 'error', 
                    'message' => 'Booking not found or not assigned to this technician'
                ], 404);
            }

            // Update booking status based on technician status
            $bookingStatus = $booking['booking_status'];
            switch ($status) {
                case 'reached':
                case 'started':
                    $bookingStatus = 'in_progress';
                    break;
                case 'completed':
                    $bookingStatus = 'completed';
                    break;
            }
            
            // Update booking if status changed
            if ($bookingStatus !== $booking['booking_status']) {
                $updateQuery = "UPDATE bookings SET booking_status = ?, updated_at = NOW() WHERE booking_id = ?";
                $updateStmt = $conn->prepare($updateQuery);
                
                if (!$updateStmt) {
                    throw new Exception("Failed to prepare update query: " . $conn->error);
                }
                
                $updateStmt->bind_param("ss", $bookingStatus, $bookingId);
                $updateResult = $updateStmt->execute();
                $updateStmt->close();
                
                if (!$updateResult) {
                    throw new Exception("Failed to update booking");
                }
            }

            // Log the status update
            $logQuery = "
                INSERT INTO technician_status_log (booking_id, technician_id, status, timestamp, notes) 
                VALUES (?, ?, ?, NOW(), ?)
            ";
            $logStmt = $conn->prepare($logQuery);
            
            if (!$logStmt) {
                throw new Exception("Failed to prepare log query: " . $conn->error);
            }
            
            $logStmt->bind_param("siss", $bookingId, $actualTechnicianId, $status, $notes);
            $logResult = $logStmt->execute();
            $logStmt->close();
            
            if (!$logResult) {
                throw new Exception("Failed to log status");
            }

            // Create notification for customer if notifications table exists
            $notificationTitle = '';
            $notificationMessage = '';
            
            switch ($status) {
                case 'reached':
                    $notificationTitle = "Technician Arrived";
                    $notificationMessage = "Your technician {$technician['employee_name']} has arrived at your location for booking #{$bookingId}.";
                    break;
                case 'started':
                    $notificationTitle = "Service Started";
                    $notificationMessage = "Your service for booking #{$bookingId} has been started by technician {$technician['employee_name']}.";
                    break;
                case 'completed':
                    $notificationTitle = "Service Completed";
                    $notificationMessage = "Great news! Your service for booking #{$bookingId} has been completed successfully by {$technician['employee_name']}.";
                    break;
            }
            
            if ($notificationTitle && $notificationMessage) {
                // Check if notifications table exists
                $tableCheck = $conn->query("SHOW TABLES LIKE 'notifications'");
                if ($tableCheck && $tableCheck->num_rows > 0) {
                    $notificationQuery = "
                        INSERT INTO notifications (user_type, user_id, title, message, type, related_booking_id, created_at) 
                        VALUES ('customer', ?, ?, ?, 'status_update', ?, NOW())
                    ";
                    $notificationStmt = $conn->prepare($notificationQuery);
                    
                    if ($notificationStmt) {
                        $notificationStmt->bind_param("isss", $booking['user_id'], $notificationTitle, $notificationMessage, $bookingId);
                        $notificationStmt->execute();
                        $notificationStmt->close();
                    }
                }
            }

            // Commit transaction
            $conn->commit();
            
            $response = [
                'status' => 'success',
                'message' => 'Status updated successfully',
                'data' => [
                    'booking_id' => $bookingId,
                    'technician_id' => $actualTechnicianId,
                    'technician_name' => $technician['employee_name'],
                    'new_status' => $status,
                    'booking_status' => $bookingStatus,
                    'timestamp' => date('Y-m-d H:i:s'),
                    'notes' => $notes
                ]
            ];
            
            sendJsonResponse($response, 200);
            
        } catch (Exception $e) {
            $conn->rollback();
            throw $e;
        }
        
    } catch (Exception $e) {
        if (isset($conn) && $conn->inTransaction) {
            $conn->rollback();
        }
        
        logError("Status update error: " . $e->getMessage());
        sendJsonResponse([
            'status' => 'error',
            'message' => 'An error occurred while updating status',
            'debug' => $e->getMessage() // Remove this in production
        ], 500);
    }
}

// Helper function to get status color
function getStatusColor($status) {
    switch (strtolower($status)) {
        case 'assigned': return '#2196F3';
        case 'reached': return '#FF9800';
        case 'started': return '#9C27B0';
        case 'completed': return '#4CAF50';
        default: return '#9E9E9E';
    }
}

// Helper function to get next action
function getNextAction($status) {
    switch (strtolower($status)) {
        case 'assigned': return 'Mark as Reached';
        case 'reached': return 'Start Work';
        case 'started': return 'Complete Job';
        case 'completed': return 'Completed';
        default: return 'Update Status';
    }
}

// Close connection if it exists
if (isset($conn)) {
    $conn->close();
}

// Send default error if no valid request method
sendJsonResponse([
    'status' => 'error',
    'message' => 'Invalid request method'
], 405);
?>