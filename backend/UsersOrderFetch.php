<?php
// Include database connection and helper functions
include 'conn.php';
include 'functions.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = $headers['Session-ID'] ?? '';

// Validate session ID
if (empty($sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Session ID is required."
    ]);
    exit;
}

// Fetch user details from the `users` table using session ID
$stmt = $conn->prepare("SELECT mobile_number, session_expiry FROM users WHERE sessionid = ?");
$stmt->bind_param("s", $sessionId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

// If user not found
if (!$user) {
    echo json_encode([
        "status" => "error",
        "message" => "Invalid session. User not found."
    ]);
    exit;
}

// Check if session is expired
$currentTime = date("Y-m-d H:i:s");
if (strtotime($user['session_expiry']) < strtotime($currentTime)) {
    echo json_encode([
        "status" => "error",
        "message" => "Session expired. Please login again."
    ]);
    exit;
}

// Get user mobile number
$mobileNumber = $user['mobile_number'];

// Fetch orders where `mobile_number` matches in the orders table
$stmt = $conn->prepare("SELECT * FROM orders WHERE mobile_no = ?");
$stmt->bind_param("s", $mobileNumber);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];
while ($row = $result->fetch_assoc()) {
    $orders[] = $row;
}
$stmt->close();
$conn->close();

// Return response
if (!empty($orders)) {
    echo json_encode(["status" => "success", "orders" => $orders]);
} else {
    echo json_encode(["status" => "success", "message" => "No orders found", "orders" => []]);
}
?>
