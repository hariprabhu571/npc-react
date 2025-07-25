<?php
// log_notification_request.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Session-ID");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'conn.php';

// Function to validate session (same as in get_fcm_token.php)
function validateSession($conn, $sessionId) {
    $currentTime = date('Y-m-d H:i:s');
    
    // Check in admin_login table
    $stmt = $conn->prepare("SELECT id, email, 'admin' as user_type FROM admin_login WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // Check in technicians table
    $stmt = $conn->prepare("SELECT technician_id as id, email, 'technician' as user_type FROM technicians WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // Check in users table
    $stmt = $conn->prepare("SELECT user_id as id, email_id as email, 'user' as user_type FROM users WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    return false;
}

// Create notification_requests table if it doesn't exist
function createNotificationRequestsTable($conn) {
    $sql = "CREATE TABLE IF NOT EXISTS notification_requests (
        id INT AUTO_INCREMENT PRIMARY KEY,
        request_id VARCHAR(255) UNIQUE NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        target_user_type ENUM('user', 'technician', 'admin', 'all') NOT NULL,
        priority ENUM('low', 'normal', 'high', 'critical') DEFAULT 'normal',
        sender_id INT,
        sender_type ENUM('user', 'technician', 'admin'),
        sender_info VARCHAR(255),
        status ENUM('pending', 'approved', 'rejected', 'sent') DEFAULT 'pending',
        additional_data JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        processed_at TIMESTAMP NULL,
        processed_by INT NULL
    )";
    
    return $conn->query($sql);
}

try {
    // Create table if needed
    createNotificationRequestsTable($conn);
    
    // Get headers and POST data
    $headers = getallheaders();
    $sessionId = $headers['Session-ID'] ?? '';
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Get request parameters
    $action = $input['action'] ?? 'log_request';
    
    switch ($action) {
        case 'log_request':
            // Validate session ID
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            // Validate session and get user info
            $userInfo = validateSession($conn, $sessionId);
            
            if (!$userInfo) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Unauthorized access. Invalid or expired session."
                ]);
                exit;
            }
            
            // Get request data
            $requestData = $input['request_data'] ?? null;
            
            if (!$requestData) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Request data is required"
                ]);
                exit;
            }
            
            // Validate required fields
            $requiredFields = ['id', 'title', 'message', 'target_user_type'];
            foreach ($requiredFields as $field) {
                if (empty($requestData[$field])) {
                    echo json_encode([
                        "status" => "error",
                        "message" => "Field '$field' is required"
                    ]);
                    exit;
                }
            }
            
            // Prepare data for insertion
            $requestId = $requestData['id'];
            $title = $requestData['title'];
            $message = $requestData['message'];
            $targetUserType = $requestData['target_user_type'];
            $priority = $requestData['priority'] ?? 'normal';
            $senderInfo = $requestData['sender_info'] ?? null;
            $additionalData = json_encode($requestData['data'] ?? []);
            
            // Insert notification request
            $stmt = $conn->prepare("INSERT INTO notification_requests 
                (request_id, title, message, target_user_type, priority, sender_id, sender_type, sender_info, additional_data) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            
            $stmt->bind_param("sssssisss", 
                $requestId, 
                $title, 
                $message, 
                $targetUserType, 
                $priority, 
                $userInfo['id'], 
                $userInfo['user_type'], 
                $senderInfo, 
                $additionalData
            );
            
            if ($stmt->execute()) {
                echo json_encode([
                    "status" => "success",
                    "message" => "Notification request logged successfully",
                    "request_id" => $requestId
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to log notification request: " . $stmt->error
                ]);
            }
            break;
            
        case 'get_pending_requests':
            // Get all pending notification requests (admin only)
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            $userInfo = validateSession($conn, $sessionId);
            
            if (!$userInfo || $userInfo['user_type'] !== 'admin') {
                echo json_encode([
                    "status" => "error",
                    "message" => "Admin access required"
                ]);
                exit;
            }
            
            $stmt = $conn->prepare("SELECT * FROM notification_requests WHERE status = 'pending' ORDER BY created_at DESC");
            $stmt->execute();
            $result = $stmt->get_result();
            
            $requests = [];
            while ($row = $result->fetch_assoc()) {
                $row['additional_data'] = json_decode($row['additional_data'], true);
                $requests[] = $row;
            }
            
            echo json_encode([
                "status" => "success",
                "message" => "Pending requests retrieved successfully",
                "data" => [
                    "count" => count($requests),
                    "requests" => $requests
                ]
            ]);
            break;
            
        case 'update_request_status':
            // Update notification request status (admin only)
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            $userInfo = validateSession($conn, $sessionId);
            
            if (!$userInfo || $userInfo['user_type'] !== 'admin') {
                echo json_encode([
                    "status" => "error",
                    "message" => "Admin access required"
                ]);
                exit;
            }
            
            $requestId = $input['request_id'] ?? '';
            $newStatus = $input['status'] ?? '';
            
            if (empty($requestId) || empty($newStatus)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Request ID and status are required"
                ]);
                exit;
            }
            
            $validStatuses = ['pending', 'approved', 'rejected', 'sent'];
            if (!in_array($newStatus, $validStatuses)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Invalid status. Valid values: " . implode(', ', $validStatuses)
                ]);
                exit;
            }
            
            $stmt = $conn->prepare("UPDATE notification_requests SET status = ?, processed_at = CURRENT_TIMESTAMP, processed_by = ? WHERE request_id = ?");
            $stmt->bind_param("sis", $newStatus, $userInfo['id'], $requestId);
            
            if ($stmt->execute()) {
                echo json_encode([
                    "status" => "success",
                    "message" => "Request status updated successfully"
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to update request status"
                ]);
            }
            break;
            
        case 'get_request_history':
            // Get notification request history for current user
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            $userInfo = validateSession($conn, $sessionId);
            
            if (!$userInfo) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Unauthorized access. Invalid or expired session."
                ]);
                exit;
            }
            
            $limit = $input['limit'] ?? 50;
            $offset = $input['offset'] ?? 0;
            
            if ($userInfo['user_type'] === 'admin') {
                // Admin can see all requests
                $stmt = $conn->prepare("SELECT * FROM notification_requests ORDER BY created_at DESC LIMIT ? OFFSET ?");
                $stmt->bind_param("ii", $limit, $offset);
            } else {
                // Other users can only see their own requests
                $stmt = $conn->prepare("SELECT * FROM notification_requests WHERE sender_id = ? AND sender_type = ? ORDER BY created_at DESC LIMIT ? OFFSET ?");
                $stmt->bind_param("isii", $userInfo['id'], $userInfo['user_type'], $limit, $offset);
            }
            
            $stmt->execute();
            $result = $stmt->get_result();
            
            $requests = [];
            while ($row = $result->fetch_assoc()) {
                $row['additional_data'] = json_decode($row['additional_data'], true);
                $requests[] = $row;
            }
            
            echo json_encode([
                "status" => "success",
                "message" => "Request history retrieved successfully",
                "data" => [
                    "count" => count($requests),
                    "requests" => $requests
                ]
            ]);
            break;
            
        case 'get_manager_token':
            // Get manager's FCM token
            $stmt = $conn->prepare("SELECT fcm_token FROM admin_login WHERE email = 'manager@npc.com' OR id = 1 LIMIT 1");
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo json_encode([
                    "status" => "success",
                    "message" => "Manager FCM token retrieved",
                    "data" => [
                        "fcm_token" => $row['fcm_token']
                    ]
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Manager not found"
                ]);
            }
            break;
            
        default:
            echo json_encode([
                "status" => "error",
                "message" => "Invalid action. Available actions: log_request, get_pending_requests, update_request_status, get_request_history, get_manager_token"
            ]);
            break;
    }
    
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Server error: " . $e->getMessage()
    ]);
}

$conn->close();
?>