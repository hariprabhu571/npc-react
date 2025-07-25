<?php

// added for CROS (Hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Include required files
require 'conn.php';          // Database connection
require 'functions.php';     // Include session ID generation functions

// Handle login request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get JSON input from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (empty($input['email']) || empty($input['password']) || empty($input['fcm_token'])) {
        echo json_encode(['status' => 'error', 'message' => 'Mobile number, password, and FCM token are required.']);
        exit;
    }

    $mobile_number = $input['email'];
    $password = $input['password'];
    $fcm_token = $input['fcm_token'];

    // Fetch user details from the database
    $stmt = $conn->prepare("SELECT user_id, password FROM users WHERE mobile_number = ?");
    $stmt->bind_param("s", $mobile_number);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if ($user && password_verify($password, $user['password'])) {
        // Login successful
        $sessionId = generateSessionId();
        $sessionExpiry = getSessionExpiry();

        // Update session ID, expiry, and FCM token in the database
        $updateStmt = $conn->prepare("UPDATE users SET sessionid = ?, session_expiry = ?, fcm_token = ? WHERE user_id = ?");
        $updateStmt->bind_param("sssi", $sessionId, $sessionExpiry, $fcm_token, $user['user_id']);
        $updateStmt->execute();

        // Return the session ID, expiry, and FCM token to the client
        echo json_encode([
            'status' => 'success',
            'sessionid' => $sessionId,
            'session_expiry' => $sessionExpiry,
            'fcm_token' => $fcm_token
        ]);

        // Close the update statement
        $updateStmt->close();
    } else {
        // Login failed
        echo json_encode(['status' => 'error', 'message' => 'Invalid mobile number or password']);
    }

    // Close the select statement
    $stmt->close();
}

// Close connection
$conn->close();
?>
