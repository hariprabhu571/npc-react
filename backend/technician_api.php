<?php
// technician_api.php - Complete technician management API

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Technician-ID, Action");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

// Get action from headers or query parameter
$headers = getallheaders();
$action = isset($headers['Action']) ? $headers['Action'] : (isset($_GET['action']) ? $_GET['action'] : '');

// Log incoming request
error_log("Technician API called with action: " . $action);
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);

try {
    switch ($action) {
        case 'login':
            handleTechnicianLogin();
            break;
        case 'verify_session':
            handleSessionVerification();
            break;
        case 'get_orders':
            handleGetOrders();
            break;
        case 'update_status':
            handleStatusUpdate();
            break;
        case 'get_profile':
            handleGetProfile();
            break;
        default:
            // Default to get orders if no action specified and technician ID provided
            if (isset($headers['Technician-ID']) && $_SERVER['REQUEST_METHOD'] === 'GET') {
                handleGetOrders();
            } else {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'Invalid action or missing parameters']);
            }
            break;
    }
} catch (Exception $e) {
    error_log("API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error occurred',
        'error' => $e->getMessage()
    ]);
}

// Function to handle technician login
function handleTechnicianLogin() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
        return;
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON data']);
        return;
    }
    
    $email = isset($data['email']) ? trim($data['email']) : null;
    $password = isset($data['password']) ? trim($data['password']) : null;
    
    if (!$email || !$password) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Email and password are required']);
        return;
    }

    // Check technician credentials
    $technicianQuery = "SELECT technician_id, employee_name, phone_number, email, password FROM technicians WHERE email = ?";
    $technicianStmt = $conn->prepare($technicianQuery);
    
    if (!$technicianStmt) {
        throw new Exception("Failed to prepare technician query: " . $conn->error);
    }
    
    $technicianStmt->bind_param("s", $email);
    $technicianStmt->execute();
    $technicianResult = $technicianStmt->get_result();
    $technician = $technicianResult->fetch_assoc();
    
    if (!$technician || !password_verify($password, $technician['password'])) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid email or password']);
        return;
    }

    // Generate session ID
    $sessionId = bin2hex(random_bytes(32));
    $sessionExpiry = date('Y-m-d H:i:s', strtotime('+24 hours'));
    
    // Update technician with session info
    $updateSessionQuery = "UPDATE technicians SET sessionid = ?, session_expiry = ? WHERE technician_id = ?";
    $updateSessionStmt = $conn->prepare($updateSessionQuery);
    
    if (!$updateSessionStmt) {
        throw new Exception("Failed to prepare session update query: " . $conn->error);
    }
    
    $updateSessionStmt->bind_param("ssi", $sessionId, $sessionExpiry, $technician['technician_id']);
    $updateResult = $updateSessionStmt->execute();
    
    if (!$updateResult) {
        throw new Exception("Failed to update session: " . $conn->error);
    }

    $response = [
        'status' => 'success',
        'message' => 'Login successful',
        'data' => [
            'technician_id' => $technician['technician_id'],
            'employee_name' => $technician['employee_name'],
            'phone_number' => $technician['phone_number'],
            'email' => $technician['email'],
            'session_id' => $sessionId,
            'session_expiry' => $sessionExpiry
        ]
    ];
    
    http_response_code(200);
    echo json_encode($response);
}

// Function to verify technician session
function handleSessionVerification() {
    global $conn;
    
    $headers = getallheaders();
    $sessionId = null;
    
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'technician-id') {
            $sessionId = $value;
            break;
        }
    }

    if (!$sessionId) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Session ID is required']);
        return;
    }

    $technician = verifyTechnicianSession($sessionId);
    
    if (!$technician) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired session']);
        return;
    }

    http_response_code(200);
    echo json_encode([
        'status' => 'success',
        'message' => 'Session valid',
        'data' => $technician
    ]);
}

// Function to get technician orders
function handleGetOrders() {
    global $conn;
    
    $headers = getallheaders();
    $technicianId = null;
    
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'technician-id') {
            $technicianId = $value;
            break;
        }
    }

    if (!$technicianId) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Technician ID is required']);
        return;
    }

    // For session-based authentication, extract technician ID from session
    $technician = verifyTechnicianSession($technicianId);
    
    if (!$technician) {
        // If session verification fails, try direct technician ID
        $technicianQuery = "SELECT technician_id, employee_name, phone_number, email FROM technicians WHERE technician_id = ?";
        $technicianStmt = $conn->prepare($technicianQuery);
        
        if (!$technicianStmt) {
            throw new Exception("Failed to prepare technician query: " . $conn->error);
        }
        
        $technicianStmt->bind_param("i", $technicianId);
        $technicianStmt->execute();
        $technicianResult = $technicianStmt->get_result();
        $technician = $technicianResult->fetch_assoc();
        
        if (!$technician) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Technician not found']);
            return;
        }
    }

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
        throw new Exception("Failed to prepare bookings query: " . $conn->error);
    }
    
    $bookingsStmt->bind_param("i", $technician['technician_id']);
    $bookingsStmt->execute();
    $bookingsResult = $bookingsStmt->get_result();
    $bookings = $bookingsResult->fetch_all(MYSQLI_ASSOC);
    
    // Format bookings and get technician status
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
            $statusStmt->bind_param("si", $booking['booking_id'], $technician['technician_id']);
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
            'service_name' => $booking['service_name'],
            'service_date' => $booking['service_date'],
            'service_date_formatted' => $booking['service_date'] ? date('d M Y', strtotime($booking['service_date'])) : 'N/A',
            'time_slot' => $booking['time_slot'],
            'service_address' => $booking['service_address'],
            'special_notes' => $booking['special_notes'],
            'total_amount' => (float)$booking['total_amount'],
            'booking_status' => $booking['booking_status'],
            'technician_status' => $technicianStatus,
            'customer_name' => $booking['customer_name'],
            'customer_phone' => $booking['mobile_number'],
            'customer_email' => $booking['email_id'],
            'created_at' => $booking['created_at'],
            'last_update' => $lastUpdate,
            'last_update_formatted' => date('d M Y, h:i A', strtotime($lastUpdate)),
            'last_notes' => $lastNotes
        ];
    }
    
    $response = [
        'status' => 'success',
        'message' => 'Orders retrieved successfully',
        'technician' => $technician,
        'bookings' => $formattedBookings,
        'count' => count($formattedBookings)
    ];
    
    http_response_code(200);
    echo json_encode($response);
}

// Function to handle status updates
function handleStatusUpdate() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
        return;
    }
    
    $headers = getallheaders();
    $technicianId = null;
    
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'technician-id') {
            $technicianId = $value;
            break;
        }
    }

    if (!$technicianId) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Technician ID is required']);
        return;
    }

    // Verify technician
    $technician = verifyTechnicianSession($technicianId);
    if (!$technician) {
        // Try direct ID lookup
        $technicianQuery = "SELECT technician_id, employee_name FROM technicians WHERE technician_id = ?";
        $technicianStmt = $conn->prepare($technicianQuery);
        $technicianStmt->bind_param("i", $technicianId);
        $technicianStmt->execute();
        $technicianResult = $technicianStmt->get_result();
        $technician = $technicianResult->fetch_assoc();
        
        if (!$technician) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Technician not found']);
            return;
        }
    }

    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON data']);
        return;
    }
    
    $bookingId = isset($data['booking_id']) ? trim($data['booking_id']) : null;
    $status = isset($data['status']) ? trim($data['status']) : null;
    $notes = isset($data['notes']) ? trim($data['notes']) : null;
    
    if (!$bookingId || !$status) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Booking ID and status are required']);
        return;
    }

    // Validate status
    $validStatuses = ['assigned', 'reached', 'started', 'completed'];
    if (!in_array($status, $validStatuses)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Invalid status']);
        return;
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
        $bookingStmt->bind_param("si", $bookingId, $technician['technician_id']);
        $bookingStmt->execute();
        $bookingResult = $bookingStmt->get_result();
        $booking = $bookingResult->fetch_assoc();
        
        if (!$booking) {
            throw new Exception("Booking not found or not assigned to this technician");
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
            $updateStmt->bind_param("ss", $bookingStatus, $bookingId);
            $updateStmt->execute();
        }

        // Log the status update
        $logQuery = "
            INSERT INTO technician_status_log (booking_id, technician_id, status, timestamp, notes) 
            VALUES (?, ?, ?, NOW(), ?)
        ";
        $logStmt = $conn->prepare($logQuery);
        $logStmt->bind_param("siss", $bookingId, $technician['technician_id'], $status, $notes);
        $logStmt->execute();

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
            $notificationQuery = "
                INSERT INTO notifications (user_type, user_id, title, message, type, related_booking_id, created_at) 
                VALUES ('customer', ?, ?, ?, 'status_update', ?, NOW())
            ";
            $notificationStmt = $conn->prepare($notificationQuery);
            $notificationStmt->bind_param("isss", $booking['user_id'], $notificationTitle, $notificationMessage, $bookingId);
            $notificationStmt->execute();
        }

        // Commit transaction
        $conn->commit();
        
        $response = [
            'status' => 'success',
            'message' => 'Status updated successfully',
            'data' => [
                'booking_id' => $bookingId,
                'technician_id' => $technician['technician_id'],
                'new_status' => $status,
                'booking_status' => $bookingStatus,
                'timestamp' => date('Y-m-d H:i:s'),
                'notes' => $notes
            ]
        ];
        
        http_response_code(200);
        echo json_encode($response);
        
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }
}

// Function to get technician profile
function handleGetProfile() {
    global $conn;
    
    $headers = getallheaders();
    $technicianId = null;
    
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'technician-id') {
            $technicianId = $value;
            break;
        }
    }

    if (!$technicianId) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Technician ID is required']);
        return;
    }

    $technician = verifyTechnicianSession($technicianId);
    
    if (!$technician) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Invalid session']);
        return;
    }

    // Get additional statistics
    $statsQuery = "
        SELECT 
            COUNT(*) as total_jobs,
            SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) as completed_jobs,
            SUM(CASE WHEN booking_status IN ('confirmed', 'in_progress') THEN 1 ELSE 0 END) as active_jobs
        FROM bookings 
        WHERE assigned_technician = ?
    ";
    $statsStmt = $conn->prepare($statsQuery);
    $statsStmt->bind_param("i", $technician['technician_id']);
    $statsStmt->execute();
    $statsResult = $statsStmt->get_result();
    $stats = $statsResult->fetch_assoc();

    $response = [
        'status' => 'success',
        'message' => 'Profile retrieved successfully',
        'data' => array_merge($technician, [
            'statistics' => [
                'total_jobs' => (int)$stats['total_jobs'],
                'completed_jobs' => (int)$stats['completed_jobs'],
                'active_jobs' => (int)$stats['active_jobs']
            ]
        ])
    ];
    
    http_response_code(200);
    echo json_encode($response);
}

// Helper function to verify technician session
function verifyTechnicianSession($sessionId) {
    global $conn;
    
    $sessionQuery = "SELECT technician_id, employee_name, phone_number, email FROM technicians WHERE sessionid = ? AND session_expiry > NOW()";
    $sessionStmt = $conn->prepare($sessionQuery);
    
    if (!$sessionStmt) {
        return false;
    }
    
    $sessionStmt->bind_param("s", $sessionId);
    $sessionStmt->execute();
    $sessionResult = $sessionStmt->get_result();
    $technician = $sessionResult->fetch_assoc();
    $sessionStmt->close();
    
    return $technician;
}

$conn->close();
?>