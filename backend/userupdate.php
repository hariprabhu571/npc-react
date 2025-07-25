<?php
// Include required files
require 'conn.php'; // Database connection

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle user details update request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get Session-ID from headers
    $headers = getallheaders();
    $sessionid = null;
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'session-id') {
            $sessionid = $value;
            break;
        }
    }

    // Get JSON input from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate required fields
    if (empty($sessionid) || empty($input['address1']) || empty($input['email_id'])) {
        echo json_encode(['status' => 'error', 'message' => 'Session ID, address1, and email ID are required.']);
        exit;
    }

    $address1 = $input['address1'];
    $address2 = $input['address2'] ?? null; // Optional field
    $email_id = $input['email_id'];
    $gender = $input['gender'] ?? null; // Optional field
    $country = $input['country'] ?? null; // Optional field

    // Validate session ID
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired session. Please log in again.']);
        exit;
    }

    $user_id = $user['user_id'];

    // Update user profile in the database
    $updateStmt = $conn->prepare("UPDATE users SET address1 = ?, address2 = ?, email_id = ?, gender = ?, country = ? WHERE user_id = ?");
    $updateStmt->bind_param("sssssi", $address1, $address2, $email_id, $gender, $country, $user_id);

    if ($updateStmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Profile updated successfully.']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update profile.']);
    }

    $updateStmt->close();
}

$conn->close();
?>
