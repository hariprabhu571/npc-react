<?php
include 'conn.php';  // Database connection
include 'functions.php';  // Include session validation function

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = $headers['Session-ID'] ?? '';

// Validate session ID
if (empty($sessionId) || !validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Get raw POST data
$data = json_decode(file_get_contents("php://input"), true);

// Check if required fields exist
if (!isset($data['order_id'], $data['technician_id'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Order ID and Technician ID are required."
    ]);
    exit;
}

$order_id = intval($data['order_id']);
$technician_id = intval($data['technician_id']);

// Validate inputs
if ($order_id <= 0 || $technician_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Invalid Order ID or Technician ID."
    ]);
    exit;
}

// Update technician assignment in the database
$stmt = $conn->prepare("UPDATE orders SET assigned_technician = ? WHERE order_id = ?");
$stmt->bind_param("ii", $technician_id, $order_id);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode([
        "status" => "success",
        "message" => "Technician assigned successfully."
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to assign technician. Order ID may not exist."
    ]);
}

// Close the statement and connection
$stmt->close();
$conn->close();
?>
