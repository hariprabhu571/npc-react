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
    $stmt = $conn->prepare("SELECT technician_id, email, employee_name FROM technicians WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $tech = $result->fetch_assoc();
    if ($tech) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Technician profile retrieved successfully',
            'data' => [
                'id' => $tech['technician_id'],
                'email_id' => $tech['email'],
                'employee_name' => $tech['employee_name'],
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