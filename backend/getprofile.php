<?php
// Include required files
require 'conn.php'; // Database connection

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle profile retrieval request
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get Session-ID from headers
    $headers = getallheaders();
    $sessionid = null;
    
    // Case-insensitive header matching for better reliability
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'session-id') {
            $sessionid = $value;
            break;
        }
    }

    // Validate session ID
    if (empty($sessionid)) {
        echo json_encode([
            'status' => 'error', 
            'message' => 'Session ID is required.'
        ]);
        exit;
    }

    // Validate session ID and get user info
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        echo json_encode([
            'status' => 'error', 
            'message' => 'Invalid or expired session. Please log in again.'
        ]);
        exit;
    }

    $user_id = $user['user_id'];

    // Get full user profile information
    $profileStmt = $conn->prepare(
        "SELECT 
            email_id, 
            address1, 
            address2, 
            profile_pic, 
            gender, 
            country
        FROM users 
        WHERE user_id = ?"
    );
    $profileStmt->bind_param("i", $user_id);
    $profileStmt->execute();
    $profileResult = $profileStmt->get_result();
    $profileData = $profileResult->fetch_assoc();

    if ($profileData) {
        // Return user profile data
        echo json_encode([
            'status' => 'success',
            'message' => 'Profile retrieved successfully',
            'data' => $profileData
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to retrieve profile data'
        ]);
    }

    $profileStmt->close();
    $stmt->close();
}

$conn->close();
?>