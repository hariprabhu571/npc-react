<?php
// technician_status_update.php - Handle technician status updates

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
    error_log("Technician Status Update Error: " . $message);
}

// POST - Update technician status for a booking
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get Technician-ID from headers
        $headers = getallheaders();
        $technicianIdFromHeader = null;
        
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'technician-id') {
                    $technicianIdFromHeader = trim($value);
                    break;
                }
            }
        }

        if (!$technicianIdFromHeader) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Technician ID is required'
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

        // First try session-based lookup (since Flutter sends session ID)
        $sessionQuery = "SELECT technician_id, employee_name FROM technicians WHERE sessionid = ? AND session_expiry > NOW()";
        $sessionStmt = $conn->prepare($sessionQuery);
        
        if (!$sessionStmt) {
            logError("Failed to prepare session query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        
        $sessionStmt->bind_param("s", $technicianIdFromHeader);
        $sessionStmt->execute();
        $sessionResult = $sessionStmt->get_result();
        $technician = $sessionResult->fetch_assoc();
        $sessionStmt->close();
        
        // If session lookup fails, try direct technician ID lookup (fallback)
        if (!$technician && is_numeric($technicianIdFromHeader)) {
            logError("Session lookup failed for ID: $technicianIdFromHeader, trying direct lookup");
            $directQuery = "SELECT technician_id, employee_name FROM technicians WHERE technician_id = ?";
            $directStmt = $conn->prepare($directQuery);
            
            if (!$directStmt) {
                logError("Failed to prepare direct query: " . $conn->error);
                sendJsonResponse([
                    'status' => 'error', 
                    'message' => 'Database query preparation failed'
                ], 500);
            }
            
            $directStmt->bind_param("i", $technicianIdFromHeader);
            $directStmt->execute();
            $directResult = $directStmt->get_result();
            $technician = $directResult->fetch_assoc();
            $directStmt->close();
        }
        
        if (!$technician) {
            logError("Technician not found for ID: $technicianIdFromHeader");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Technician not found or session expired'
            ], 404);
        }
        
        // Use the actual technician_id from the database
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
        $locationLat = isset($data['location_lat']) ? $data['location_lat'] : null;
        $locationLng = isset($data['location_lng']) ? $data['location_lng'] : null;
        
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
            // Check if booking exists and is assigned to this technician (using actual technician_id)
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
                logError("Booking not found for booking_id: $bookingId, technician_id: $actualTechnicianId");
                sendJsonResponse([
                    'status' => 'error', 
                    'message' => 'Booking not found or not assigned to this technician',
                    'debug_info' => [
                        'booking_id' => $bookingId,
                        'technician_id' => $actualTechnicianId,
                        'session_id' => $technicianIdFromHeader
                    ]
                ], 404);
            }

            // Get the last status from technician_status_log for validation
            $lastStatusQuery = "
                SELECT status 
                FROM technician_status_log 
                WHERE booking_id = ? AND technician_id = ? 
                ORDER BY timestamp DESC 
                LIMIT 1
            ";
            $lastStatusStmt = $conn->prepare($lastStatusQuery);
            
            $currentStatus = 'assigned'; // Default status
            
            if ($lastStatusStmt) {
                $lastStatusStmt->bind_param("si", $bookingId, $actualTechnicianId);
                $lastStatusStmt->execute();
                $lastStatusResult = $lastStatusStmt->get_result();
                $lastStatusData = $lastStatusResult->fetch_assoc();
                
                if ($lastStatusData) {
                    $currentStatus = $lastStatusData['status'];
                }
                $lastStatusStmt->close();
            }

            // Validate status transition
            $statusFlow = ['assigned', 'reached', 'started', 'completed'];
            $currentIndex = array_search($currentStatus, $statusFlow);
            $newIndex = array_search($status, $statusFlow);
            
            if ($newIndex !== false && $currentIndex !== false && $newIndex < $currentIndex) {
                $conn->rollback();
                sendJsonResponse([
                    'status' => 'error', 
                    'message' => 'Invalid status transition. Cannot go backwards in status flow.',
                    'current_status' => $currentStatus,
                    'requested_status' => $status
                ], 400);
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
                INSERT INTO technician_status_log (booking_id, technician_id, status, timestamp, notes, location_lat, location_lng) 
                VALUES (?, ?, ?, NOW(), ?, ?, ?)
            ";
            $logStmt = $conn->prepare($logQuery);
            
            if (!$logStmt) {
                throw new Exception("Failed to prepare log query: " . $conn->error);
            }
            
            $logStmt->bind_param("sissdd", $bookingId, $actualTechnicianId, $status, $notes, $locationLat, $locationLng);
            $logResult = $logStmt->execute();
            $logStmt->close();
            
            if (!$logResult) {
                throw new Exception("Failed to log status");
            }

            // Create notification for customer
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
            
            // Prepare response
            $response = [
                'status' => 'success',
                'message' => 'Status updated successfully',
                'data' => [
                    'booking_id' => $bookingId,
                    'technician_id' => $actualTechnicianId,
                    'technician_name' => $technician['employee_name'],
                    'previous_status' => $currentStatus,
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

// GET - Get technician's assigned bookings
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Get Technician-ID from headers
        $headers = getallheaders();
        $technicianIdFromHeader = null;
        
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'technician-id') {
                    $technicianIdFromHeader = trim($value);
                    break;
                }
            }
        }

        if (!$technicianIdFromHeader) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Technician ID is required'
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

        // First try session-based lookup
        $sessionQuery = "SELECT technician_id, employee_name FROM technicians WHERE sessionid = ? AND session_expiry > NOW()";
        $sessionStmt = $conn->prepare($sessionQuery);
        
        if (!$sessionStmt) {
            logError("Failed to prepare session query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        
        $sessionStmt->bind_param("s", $technicianIdFromHeader);
        $sessionStmt->execute();
        $sessionResult = $sessionStmt->get_result();
        $technician = $sessionResult->fetch_assoc();
        $sessionStmt->close();
        
        // If session lookup fails, try direct technician ID lookup
        if (!$technician && is_numeric($technicianIdFromHeader)) {
            logError("Session lookup failed for ID: $technicianIdFromHeader, trying direct lookup");
            $directQuery = "SELECT technician_id, employee_name FROM technicians WHERE technician_id = ?";
            $directStmt = $conn->prepare($directQuery);
            
            if (!$directStmt) {
                logError("Failed to prepare direct query: " . $conn->error);
                sendJsonResponse([
                    'status' => 'error', 
                    'message' => 'Database query preparation failed'
                ], 500);
            }
            
            $directStmt->bind_param("i", $technicianIdFromHeader);
            $directStmt->execute();
            $directResult = $directStmt->get_result();
            $technician = $directResult->fetch_assoc();
            $directStmt->close();
        }
        
        if (!$technician) {
            logError("Technician not found for ID: $technicianIdFromHeader");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Technician not found or session expired'
            ], 404);
        }

        $actualTechnicianId = $technician['technician_id'];

        // Get assigned bookings
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
            ORDER BY b.service_date ASC, b.time_slot ASC
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
        
        // Format bookings
        $formattedBookings = [];
        foreach ($bookings as $booking) {
            // Get latest status from technician_status_log
            $statusQuery = "
                SELECT status, timestamp 
                FROM technician_status_log 
                WHERE booking_id = ? AND technician_id = ? 
                ORDER BY timestamp DESC 
                LIMIT 1
            ";
            $statusStmt = $conn->prepare($statusQuery);
            
            $technicianStatus = 'assigned';
            $lastUpdate = $booking['created_at'];
            
            if ($statusStmt) {
                $statusStmt->bind_param("si", $booking['booking_id'], $actualTechnicianId);
                $statusStmt->execute();
                $statusResult = $statusStmt->get_result();
                $statusData = $statusResult->fetch_assoc();
                
                if ($statusData) {
                    $technicianStatus = $statusData['status'];
                    $lastUpdate = $statusData['timestamp'];
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
            ];
        }
        
        $response = [
            'status' => 'success',
            'message' => 'Bookings retrieved successfully',
            'technician' => [
                'technician_id' => $technician['technician_id'],
                'employee_name' => $technician['employee_name']
            ],
            'bookings' => $formattedBookings,
            'count' => count($formattedBookings)
        ];
        
        sendJsonResponse($response, 200);
        
    } catch (Exception $e) {
        logError("Technician bookings fetch error: " . $e->getMessage());
        sendJsonResponse([
            'status' => 'error',
            'message' => 'An error occurred while fetching bookings',
            'debug' => $e->getMessage() // Remove this in production
        ], 500);
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