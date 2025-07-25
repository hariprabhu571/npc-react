<?php
// assign_technician.php - Assign technician to booking

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Session-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

// POST - Assign technician to booking
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get Session-ID from headers for admin authentication
        $headers = getallheaders();
        $sessionId = null;
        
        foreach ($headers as $name => $value) {
            if (strtolower($name) === 'session-id') {
                $sessionId = $value;
                break;
            }
        }

        if (!$sessionId) {
            http_response_code(401);
            echo json_encode(['status' => 'error', 'message' => 'Admin session required']);
            exit;
        }

        // Verify admin session using admin_login table
        $adminQuery = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
        $adminStmt = $conn->prepare($adminQuery);
        
        if (!$adminStmt) {
            throw new Exception("Failed to prepare admin query: " . $conn->error);
        }
        
        $adminStmt->bind_param("s", $sessionId);
        $adminStmt->execute();
        $adminResult = $adminStmt->get_result();
        $admin = $adminResult->fetch_assoc();
        
        if (!$admin) {
            http_response_code(401);
            echo json_encode(['status' => 'error', 'message' => 'Invalid admin session']);
            exit;
        }

        // Get POST data
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Invalid JSON data']);
            exit;
        }
        
        $bookingId = isset($data['booking_id']) ? trim($data['booking_id']) : null;
        $technicianId = isset($data['technician_id']) ? trim($data['technician_id']) : null;
        
        if (!$bookingId || !$technicianId) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Booking ID and Technician ID are required']);
            exit;
        }

        // Start transaction
        $conn->begin_transaction();

        // Check if booking exists and is in pending status
        $bookingQuery = "SELECT booking_id, booking_status, service_name, service_date, time_slot, user_id FROM bookings WHERE booking_id = ? AND booking_status = 'pending'";
        $bookingStmt = $conn->prepare($bookingQuery);
        
        if (!$bookingStmt) {
            throw new Exception("Failed to prepare booking query: " . $conn->error);
        }
        
        $bookingStmt->bind_param("s", $bookingId);
        $bookingStmt->execute();
        $bookingResult = $bookingStmt->get_result();
        $booking = $bookingResult->fetch_assoc();
        
        if (!$booking) {
            $conn->rollback();
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Booking not found or not in pending status']);
            exit;
        }

        // Check if technician exists and is active
        $technicianQuery = "SELECT technician_id, employee_name, phone_number FROM technicians WHERE technician_id = ?";
        $technicianStmt = $conn->prepare($technicianQuery);
        
        if (!$technicianStmt) {
            throw new Exception("Failed to prepare technician query: " . $conn->error);
        }
        
        $technicianStmt->bind_param("i", $technicianId);
        $technicianStmt->execute();
        $technicianResult = $technicianStmt->get_result();
        $technician = $technicianResult->fetch_assoc();
        
        if (!$technician) {
            $conn->rollback();
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Technician not found or not active']);
            exit;
        }

        // Update booking with assigned technician
        $updateBookingQuery = "
            UPDATE bookings 
            SET assigned_technician = ?, 
                booking_status = 'confirmed',
                updated_at = NOW() 
            WHERE booking_id = ?
        ";
        $updateBookingStmt = $conn->prepare($updateBookingQuery);
        
        if (!$updateBookingStmt) {
            throw new Exception("Failed to prepare update booking query: " . $conn->error);
        }
        
        $updateBookingStmt->bind_param("is", $technicianId, $bookingId);
        $updateBookingResult = $updateBookingStmt->execute();
        
        if (!$updateBookingResult) {
            $conn->rollback();
            throw new Exception("Failed to update booking: " . $conn->error);
        }

        // Log the technician status assignment
        $logQuery = "
            INSERT INTO technician_status_log (booking_id, technician_id, status, timestamp, notes) 
            VALUES (?, ?, 'assigned', NOW(), 'Technician assigned by admin')
        ";
        $logStmt = $conn->prepare($logQuery);
        
        if (!$logStmt) {
            throw new Exception("Failed to prepare log query: " . $conn->error);
        }
        
        $logStmt->bind_param("si", $bookingId, $technicianId);
        $logResult = $logStmt->execute();
        
        if (!$logResult) {
            $conn->rollback();
            throw new Exception("Failed to log status: " . $conn->error);
        }

        // Get customer details for notification
        $customerQuery = "SELECT customer_name, mobile_number FROM users WHERE user_id = ?";
        $customerStmt = $conn->prepare($customerQuery);
        
        if (!$customerStmt) {
            throw new Exception("Failed to prepare customer query: " . $conn->error);
        }
        
        $customerStmt->bind_param("i", $booking['user_id']);
        $customerStmt->execute();
        $customerResult = $customerStmt->get_result();
        $customer = $customerResult->fetch_assoc();

        // Create notification for technician
        $technicianNotificationTitle = "New Job Assignment";
        $technicianNotificationMessage = "You have been assigned to a new job. Booking ID: {$bookingId}. Service: {$booking['service_name']}. Date: {$booking['service_date']} at {$booking['time_slot']}.";
        
        $technicianNotificationQuery = "
            INSERT INTO notifications (user_type, user_id, title, message, type, related_booking_id, created_at) 
            VALUES ('technician', ?, ?, ?, 'booking_assigned', ?, NOW())
        ";
        $technicianNotificationStmt = $conn->prepare($technicianNotificationQuery);
        
        if (!$technicianNotificationStmt) {
            throw new Exception("Failed to prepare technician notification query: " . $conn->error);
        }
        
        $technicianNotificationStmt->bind_param("isss", $technicianId, $technicianNotificationTitle, $technicianNotificationMessage, $bookingId);
        $technicianNotificationResult = $technicianNotificationStmt->execute();
        
        if (!$technicianNotificationResult) {
            $conn->rollback();
            throw new Exception("Failed to create technician notification: " . $conn->error);
        }

        // Create notification for customer
        if ($customer) {
            $customerNotificationTitle = "Technician Assigned";
            $customerNotificationMessage = "Good news! Technician {$technician['employee_name']} has been assigned to your booking #{$bookingId}. They will contact you soon.";
            
            $customerNotificationQuery = "
                INSERT INTO notifications (user_type, user_id, title, message, type, related_booking_id, created_at) 
                VALUES ('customer', ?, ?, ?, 'status_update', ?, NOW())
            ";
            $customerNotificationStmt = $conn->prepare($customerNotificationQuery);
            
            if (!$customerNotificationStmt) {
                throw new Exception("Failed to prepare customer notification query: " . $conn->error);
            }
            
            $customerNotificationStmt->bind_param("isss", $booking['user_id'], $customerNotificationTitle, $customerNotificationMessage, $bookingId);
            $customerNotificationResult = $customerNotificationStmt->execute();
            
            if (!$customerNotificationResult) {
                $conn->rollback();
                throw new Exception("Failed to create customer notification: " . $conn->error);
            }
        }

        // Commit transaction
        $conn->commit();
        
        // Prepare response
        $response = [
            'status' => 'success',
            'message' => 'Technician assigned successfully',
            'data' => [
                'booking_id' => $bookingId,
                'technician_id' => $technicianId,
                'technician_name' => $technician['employee_name'],
                'technician_phone' => $technician['phone_number'],
                'booking_status' => 'confirmed',
                'technician_status' => 'assigned',
                'assigned_at' => date('Y-m-d H:i:s')
            ]
        ];
        
        http_response_code(200);
        echo json_encode($response);
        
    } catch (Exception $e) {
        // Rollback transaction on error
        if ($conn->inTransaction) {
            $conn->rollback();
        }
        
        error_log("Technician assignment error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database error occurred',
            'error' => $e->getMessage()
        ]);
    }
}

$conn->close();
?>