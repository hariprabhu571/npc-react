<?php
// Include required files
require 'conn.php';
require 'functions.php';  // Include session ID generation functions

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle login request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get JSON input from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (empty($input['email']) || empty($input['password'])) {
        echo json_encode(['status' => 'error', 'message' => 'Email and password are required.']);
        exit;
    }

    $email = $input['email'];
    $password = $input['password'];
    $fcm_token = isset($input['fcm_token']) ? $input['fcm_token'] : null; // Check if FCM token is provided

    // Fetch technician details from the database
    $stmt = $conn->prepare("SELECT technician_id, password FROM technicians WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $technician = $result->fetch_assoc();

    if ($technician && password_verify($password, $technician['password'])) {
        // Login successful
        $sessionId = generateSessionId();
        $sessionExpiry = getSessionExpiry();

        // Update the session ID, expiry, and FCM token in the database
        $updateStmt = $conn->prepare("UPDATE technicians SET sessionid = ?, session_expiry = ?, fcm_token = ? WHERE technician_id = ?");
        $updateStmt->bind_param("sssi", $sessionId, $sessionExpiry, $fcm_token, $technician['technician_id']);
        $updateStmt->execute();

        // Return the session ID, session expiry, and FCM token to the client
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
        echo json_encode(['status' => 'error', 'message' => 'Invalid email or password']);
    }

    // Close the select statement
    $stmt->close();
}

// Close connection
$conn->close();
?>
