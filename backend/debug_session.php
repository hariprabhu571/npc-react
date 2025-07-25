<?php
include 'conn.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = '';
foreach ($headers as $name => $value) {
    if (strtolower($name) === 'session-id') {
        $sessionId = $value;
        break;
    }
}

echo json_encode([
    "session_id_provided" => !empty($sessionId),
    "session_id" => $sessionId,
    "headers_received" => $headers
]);

if (!empty($sessionId)) {
    // Check if session exists in admin_login table
    $sql = "SELECT id, email, session_expiry FROM admin_login WHERE sessionid = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $admin = $result->fetch_assoc();
        echo json_encode([
            "session_found" => true,
            "admin_id" => $admin['id'],
            "admin_email" => $admin['email'],
            "session_expiry" => $admin['session_expiry'],
            "is_expired" => strtotime($admin['session_expiry']) < time()
        ]);
    } else {
        echo json_encode([
            "session_found" => false,
            "message" => "Session not found in admin_login table"
        ]);
    }
}

$conn->close();
?> 