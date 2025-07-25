<?php
// get_fcm_token.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Session-ID");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'conn.php';

// Function to validate session and return user info
function validateSession($conn, $sessionId) {
    $currentTime = date('Y-m-d H:i:s');
    
    // Check in admin_login table
    $stmt = $conn->prepare("SELECT id, email, fcm_token, 'admin' as user_type FROM admin_login WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // Check in technicians table
    $stmt = $conn->prepare("SELECT technician_id as id, email, fcm_token, 'technician' as user_type FROM technicians WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // Check in users table
    $stmt = $conn->prepare("SELECT user_id as id, email_id as email, fcm_token, 'user' as user_type FROM users WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    return false;
}

// Function to get FCM token for current logged-in user only
function getCurrentUserFCMToken($conn, $sessionId) {
    $currentTime = date('Y-m-d H:i:s');
    
    // Check in admin_login table
    $stmt = $conn->prepare("SELECT id, email, fcm_token, 'admin' as user_type FROM admin_login WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'user_id' => $user['id'],
            'email' => $user['email'],
            'fcm_token' => $user['fcm_token'],
            'user_type' => 'admin'
        ];
    }
    
    // Check in technicians table
    $stmt = $conn->prepare("SELECT technician_id as id, email, fcm_token, 'technician' as user_type FROM technicians WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'user_id' => $user['id'],
            'email' => $user['email'],
            'fcm_token' => $user['fcm_token'],
            'user_type' => 'technician'
        ];
    }
    
    // Check in users table
    $stmt = $conn->prepare("SELECT user_id as id, email_id as email, fcm_token, 'user' as user_type FROM users WHERE sessionid = ? AND session_expiry > ?");
    $stmt->bind_param("ss", $sessionId, $currentTime);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'user_id' => $user['id'],
            'email' => $user['email'],
            'fcm_token' => $user['fcm_token'],
            'user_type' => 'user'
        ];
    }
    
    return false;
}

// Function to get ALL FCM tokens by user type (regardless of who's requesting)
function getAllFCMTokensByType($conn, $userType) {
    $tokens = [];
    
    switch (strtolower($userType)) {
        case 'admin':
            // Get ALL admins with FCM tokens
            $stmt = $conn->prepare("SELECT id, email, fcm_token FROM admin_login WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            break;
        case 'technician':
            // Get ALL technicians with FCM tokens
            $stmt = $conn->prepare("SELECT technician_id as id, email, fcm_token FROM technicians WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            break;
        case 'user':
            // Get ALL users with FCM tokens
            $stmt = $conn->prepare("SELECT user_id as id, email_id as email, fcm_token FROM users WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            break;
        case 'all':
            // Get ALL users from all tables
            $allTokens = [];
            
            // Get all admins
            $stmt = $conn->prepare("SELECT id, email, fcm_token, 'admin' as user_type FROM admin_login WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            $stmt->execute();
            $result = $stmt->get_result();
            while ($row = $result->fetch_assoc()) {
                $allTokens[] = [
                    'user_id' => $row['id'],
                    'email' => $row['email'],
                    'fcm_token' => $row['fcm_token'],
                    'user_type' => 'admin'
                ];
            }
            
            // Get all technicians
            $stmt = $conn->prepare("SELECT technician_id as id, email, fcm_token, 'technician' as user_type FROM technicians WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            $stmt->execute();
            $result = $stmt->get_result();
            while ($row = $result->fetch_assoc()) {
                $allTokens[] = [
                    'user_id' => $row['id'],
                    'email' => $row['email'],
                    'fcm_token' => $row['fcm_token'],
                    'user_type' => 'technician'
                ];
            }
            
            // Get all users
            $stmt = $conn->prepare("SELECT user_id as id, email_id as email, fcm_token, 'user' as user_type FROM users WHERE fcm_token IS NOT NULL AND fcm_token != '' AND fcm_token != 'no_token_available'");
            $stmt->execute();
            $result = $stmt->get_result();
            while ($row = $result->fetch_assoc()) {
                $allTokens[] = [
                    'user_id' => $row['id'],
                    'email' => $row['email'],
                    'fcm_token' => $row['fcm_token'],
                    'user_type' => 'user'
                ];
            }
            
            return $allTokens;
        default:
            return false;
    }
    
    if (isset($stmt)) {
        $stmt->execute();
        $result = $stmt->get_result();
        
        while ($row = $result->fetch_assoc()) {
            $tokens[] = [
                'user_id' => $row['id'],
                'email' => $row['email'],
                'fcm_token' => $row['fcm_token'],
                'user_type' => $userType
            ];
        }
    }
    
    return $tokens;
}

// Function to get specific user's FCM token by user type and ID
function getSpecificUserFCMToken($conn, $userType, $userId) {
    switch (strtolower($userType)) {
        case 'admin':
            $stmt = $conn->prepare("SELECT id, email, fcm_token FROM admin_login WHERE id = ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            break;
        case 'technician':
            $stmt = $conn->prepare("SELECT technician_id as id, email, fcm_token FROM technicians WHERE technician_id = ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            break;
        case 'user':
            $stmt = $conn->prepare("SELECT user_id as id, email_id as email, fcm_token FROM users WHERE user_id = ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            break;
        default:
            return false;
    }
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'user_id' => $user['id'],
            'email' => $user['email'],
            'fcm_token' => $user['fcm_token'],
            'user_type' => $userType
        ];
    }
    
    return false;
}

try {
    // Get headers and POST data
    $headers = getallheaders();
    $sessionId = $headers['Session-ID'] ?? '';
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Get request parameters
    $action = $input['action'] ?? $_GET['action'] ?? 'get_token';
    $userType = $input['user_type'] ?? $_GET['user_type'] ?? null;
    $specificUserId = $input['user_id'] ?? $_GET['user_id'] ?? null;
    
    // Handle different actions
    switch ($action) {
        case 'get_token':
            // Get current logged-in user's FCM token only
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required in headers"
                ]);
                exit;
            }
            
            // Get current user's FCM token
            $userToken = getCurrentUserFCMToken($conn, $sessionId);
            
            if (!$userToken) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Unauthorized access. Invalid session or no FCM token found."
                ]);
                exit;
            }
            
            // Return current user's FCM token
            echo json_encode([
                "status" => "success",
                "message" => "FCM token retrieved successfully",
                "data" => $userToken
            ]);
            break;
            
        case 'get_all_tokens':
            // Get ALL FCM tokens by user type (for notification broadcasting)
            if (!$userType) {
                echo json_encode([
                    "status" => "error",
                    "message" => "User type is required for this action"
                ]);
                exit;
            }
            
            // Validate session (but don't restrict who can request - for manager system)
            if (!empty($sessionId)) {
                $requesterInfo = validateSession($conn, $sessionId);
                if (!$requesterInfo) {
                    echo json_encode([
                        "status" => "error",
                        "message" => "Invalid session"
                    ]);
                    exit;
                }
                
                // Log who requested the tokens
                error_log("FCM tokens requested by {$requesterInfo['user_type']} ID {$requesterInfo['id']} for user type: $userType");
            }
            
            $tokens = getAllFCMTokensByType($conn, $userType);
            
            if ($tokens === false) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Invalid user type. Valid types: admin, technician, user, all"
                ]);
                exit;
            }
            
            echo json_encode([
                "status" => "success",
                "message" => "FCM tokens retrieved successfully",
                "data" => [
                    "user_type" => $userType,
                    "count" => count($tokens),
                    "tokens" => $tokens
                ]
            ]);
            break;
            
        case 'get_specific_user_token':
            // Get specific user's FCM token
            if (!$userType || !$specificUserId) {
                echo json_encode([
                    "status" => "error",
                    "message" => "User type and user ID are required"
                ]);
                exit;
            }
            
            // Validate session
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            $requesterInfo = validateSession($conn, $sessionId);
            if (!$requesterInfo) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Invalid session"
                ]);
                exit;
            }
            
            $userToken = getSpecificUserFCMToken($conn, $userType, $specificUserId);
            
            if (!$userToken) {
                echo json_encode([
                    "status" => "error",
                    "message" => "User not found or no FCM token available"
                ]);
                exit;
            }
            
            echo json_encode([
                "status" => "success",
                "message" => "Specific user FCM token retrieved",
                "data" => $userToken
            ]);
            break;
            
        case 'verify_session':
            // Just verify if session is valid
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
                    "message" => "Invalid or expired session"
                ]);
                exit;
            }
            
            echo json_encode([
                "status" => "success",
                "message" => "Session is valid",
                "data" => [
                    "user_id" => $userInfo['id'],
                    "email" => $userInfo['email'],
                    "user_type" => $userInfo['user_type']
                ]
            ]);
            break;
            
        case 'update_fcm_token':
            // Update FCM token for current logged-in user
            if (empty($sessionId)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "Session ID is required"
                ]);
                exit;
            }
            
            $newFcmToken = $input['fcm_token'] ?? '';
            
            if (empty($newFcmToken)) {
                echo json_encode([
                    "status" => "error",
                    "message" => "FCM token is required"
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
            
            // Update FCM token based on user type
            switch ($userInfo['user_type']) {
                case 'admin':
                    $stmt = $conn->prepare("UPDATE admin_login SET fcm_token = ? WHERE id = ?");
                    break;
                case 'technician':
                    $stmt = $conn->prepare("UPDATE technicians SET fcm_token = ? WHERE technician_id = ?");
                    break;
                case 'user':
                    $stmt = $conn->prepare("UPDATE users SET fcm_token = ? WHERE user_id = ?");
                    break;
            }
            
            $stmt->bind_param("si", $newFcmToken, $userInfo['id']);
            
            if ($stmt->execute()) {
                echo json_encode([
                    "status" => "success",
                    "message" => "FCM token updated successfully"
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to update FCM token"
                ]);
            }
            break;
            
        case 'get_manager_token':
            // Get manager's FCM token (assuming first admin or specific email)
            $stmt = $conn->prepare("SELECT id, email, fcm_token FROM admin_login WHERE fcm_token IS NOT NULL AND fcm_token != '' ORDER BY id ASC LIMIT 1");
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo json_encode([
                    "status" => "success",
                    "message" => "Manager FCM token retrieved",
                    "data" => [
                        "user_id" => $row['id'],
                        "email" => $row['email'],
                        "fcm_token" => $row['fcm_token'],
                        "user_type" => "admin"
                    ]
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Manager not found or no FCM token available"
                ]);
            }
            break;
            
        default:
            echo json_encode([
                "status" => "error",
                "message" => "Invalid action. Available actions: get_token, get_all_tokens, get_specific_user_token, verify_session, update_fcm_token, get_manager_token"
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