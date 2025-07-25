<?php
include 'conn.php'; // Database connection
include 'functions.php'; // Include session validation function

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = $headers['Session-ID'] ?? '';

// Validate session ID
if (empty($sessionId)) {  // ✅ Fixed missing closing parenthesis
    echo json_encode([
        "status" => "error",
        "message" => "Session ID is required."
    ]);
    exit;
}

if (!validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Get input parameters
$input = json_decode(file_get_contents('php://input'), true);
$order_status = $input['status'] ?? null;
$slot_date = $input['slot_date'] ?? null;
$payment_mode = $input['payment_mode'] ?? null;

// Build dynamic query
$query = "SELECT * FROM orders WHERE 1";
$params = [];
$types = "";

// Apply filters dynamically
if ($order_status) {
    $query .= " AND status = ?";
    $params[] = $order_status;
    $types .= "s";
}

if ($slot_date) {
    $query .= " AND slot_date = ?";
    $params[] = $slot_date;
    $types .= "s";
}

if ($payment_mode) {
    $query .= " AND payment_mode = ?";
    $params[] = $payment_mode;
    $types .= "s";
}

// Prepare and execute statement
$stmt = $conn->prepare($query);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

// Fetch results
$orders = [];
while ($row = $result->fetch_assoc()) {
    $orders[] = $row;
}

// Response
if (!empty($orders)) {
    echo json_encode(["status" => "success", "orders" => $orders]);
} else {
    echo json_encode(["status" => "success", "message" => "No orders found", "orders" => []]);
}

// Close connection
$stmt->close();
$conn->close();
?>
