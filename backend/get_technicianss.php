<?php
// get_technicians.php - Fetch all active technicians

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

// GET - Fetch all technicians
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
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

        // Fetch all technicians with their current workload
        $techniciansQuery = "
            SELECT 
                t.technician_id,
                t.employee_name,
                t.phone_number,
                t.email,
                t.service_type,
                t.address,
                COUNT(b.booking_id) as active_bookings
            FROM technicians t
            LEFT JOIN bookings b ON t.technician_id = b.assigned_technician 
                AND b.booking_status IN ('confirmed', 'in_progress', 'assigned')
            GROUP BY t.technician_id
            ORDER BY active_bookings ASC, t.employee_name ASC
        ";
        
        $techniciansStmt = $conn->prepare($techniciansQuery);
        
        if (!$techniciansStmt) {
            throw new Exception("Failed to prepare technicians query: " . $conn->error);
        }
        
        $techniciansStmt->execute();
        $techniciansResult = $techniciansStmt->get_result();
        $technicians = $techniciansResult->fetch_all(MYSQLI_ASSOC);
        
        // Format the technicians data
        $formattedTechnicians = [];
        foreach ($technicians as $technician) {
            $formattedTechnicians[] = [
                'technician_id' => $technician['technician_id'],
                'employee_name' => $technician['employee_name'],
                'phone_number' => $technician['phone_number'],
                'email' => $technician['email'],
                'service_type' => $technician['service_type'] ?? 'General Service',
                'address' => $technician['address'],
                'active_bookings' => (int)$technician['active_bookings'],
                'workload_status' => $technician['active_bookings'] == 0 ? 'Available' : 
                                   ($technician['active_bookings'] <= 2 ? 'Light Load' : 
                                   ($technician['active_bookings'] <= 4 ? 'Moderate Load' : 'Heavy Load')),
            ];
        }
        
        $response = [
            'status' => 'success',
            'message' => 'Technicians retrieved successfully',
            'count' => count($formattedTechnicians),
            'technicians' => $formattedTechnicians
        ];
        
        http_response_code(200);
        echo json_encode($response);
        
    } catch (Exception $e) {
        error_log("Technicians fetch error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database error occurred',
            'error' => $e->getMessage()
        ]);
    }
}

// POST - Add new technician (optional)
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
        
        $employeeName = isset($data['employee_name']) ? trim($data['employee_name']) : null;
        $phoneNumber = isset($data['phone_number']) ? trim($data['phone_number']) : null;
        $email = isset($data['email']) ? trim($data['email']) : null;
        $specialization = isset($data['specialization']) ? trim($data['specialization']) : null;
        
        if (!$employeeName || !$phoneNumber) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Employee name and phone number are required']);
            exit;
        }

        // Check if phone number already exists
        $checkQuery = "SELECT technician_id FROM technicians WHERE phone_number = ?";
        $checkStmt = $conn->prepare($checkQuery);
        
        if (!$checkStmt) {
            throw new Exception("Failed to prepare check query: " . $conn->error);
        }
        
        $checkStmt->bind_param("s", $phoneNumber);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        
        if ($checkResult->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Phone number already exists']);
            exit;
        }

        // Insert new technician
        $insertQuery = "
            INSERT INTO technicians (employee_name, phone_number, email, service_type) 
            VALUES (?, ?, ?, ?)
        ";
        $insertStmt = $conn->prepare($insertQuery);
        
        if (!$insertStmt) {
            throw new Exception("Failed to prepare insert query: " . $conn->error);
        }
        
        $insertStmt->bind_param("ssss", $employeeName, $phoneNumber, $email, $specialization);
        $insertResult = $insertStmt->execute();
        
        if (!$insertResult) {
            throw new Exception("Failed to insert technician: " . $conn->error);
        }
        
        $newTechnicianId = $conn->insert_id;
        
        $response = [
            'status' => 'success',
            'message' => 'Technician added successfully',
            'data' => [
                'technician_id' => $newTechnicianId,
                'employee_name' => $employeeName,
                'phone_number' => $phoneNumber,
                'email' => $email,
                'service_type' => $specialization
            ]
        ];
        
        http_response_code(201);
        echo json_encode($response);
        
    } catch (Exception $e) {
        error_log("Add technician error: " . $e->getMessage());
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