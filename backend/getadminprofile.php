<?php
require 'conn.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $headers = getallheaders();
    $sessionid = null;
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'session-id') {
            $sessionid = $value;
            break;
        }
    }
    if (empty($sessionid)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Session ID is required.'
        ]);
        exit;
    }
    $stmt = $conn->prepare("SELECT id as admin_id, email FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $admin = $result->fetch_assoc();
    if ($admin) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Admin profile retrieved successfully',
            'data' => [
                'id' => $admin['admin_id'],
                'email_id' => $admin['email'],
                'customer_name' => 'Admin',
                'profile_pic' => null,
                'mobile_number' => null
            ]
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid or expired session. Please log in again.'
        ]);
    }
    $stmt->close();
}
$conn->close(); 