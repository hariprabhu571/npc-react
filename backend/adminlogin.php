<?php
// Include required files
require 'conn.php';
require 'functions.php'; // Include session ID generation functions
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
    if (empty($input['email']) || empty($input['password']) || empty($input['fcm_token'])) {
        echo json_encode(['status' => 'error', 'message' => 'Email, password, and FCM token are required.']);
        exit;
    }

    $email = $input['email'];
    $password = $input['password'];
    $fcm_token = $input['fcm_token'];

    // Debug: Check if input is received correctly
    error_log("Received email: $email");
    error_log("Received password: $password");

    // Fetch admin details from the database
    $stmt = $conn->prepare("SELECT id, password FROM admin_login WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $admin = $result->fetch_assoc();
    $stmt->close();

    // Debug: Check what was fetched
    error_log("Fetched admin: " . json_encode($admin));

    if ($admin && password_verify($password, $admin['password'])) {
        // Login successful
        $sessionId = generateSessionId();
        $sessionExpiry = getSessionExpiry();

        // Update the session ID, expiry, and FCM token in the database
        $updateStmt = $conn->prepare("UPDATE admin_login SET sessionid = ?, session_expiry = ?, fcm_token = ? WHERE id = ?");
        $updateStmt->bind_param("sssi", $sessionId, $sessionExpiry, $fcm_token, $admin['id']);
        $updateStmt->execute();
        $updateStmt->close();

        // Return response to the client
        echo json_encode([
            'status' => 'success',
            'sessionid' => $sessionId,
            'session_expiry' => $sessionExpiry,
            'fcm_token' => $fcm_token
        ]);
    } else {
        // Debugging: Log if password verification failed
        if ($admin) {
            error_log("Password verification failed for email: $email");
        } else {
            error_log("No admin found for email: $email");
        }

        // Login failed
        echo json_encode(['status' => 'error', 'message' => 'Invalid email or password']);
    }
}

// Close connection
$conn->close();
?>
