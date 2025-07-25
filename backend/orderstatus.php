<?php
require 'conn.php'; // Database connection
require 'functions.php'; // Include session validation function

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

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input['order_id']) || empty($input['status'])) {
        echo json_encode(['status' => 'error', 'message' => 'Order ID and status are required.']);
        exit;
    }

    $order_id = $input['order_id'];
    $status = $input['status'];

    // Fetch order details
    $stmt = $conn->prepare("SELECT type_of_service, slot_date FROM orders WHERE order_id = ?");
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $order = $result->fetch_assoc();

    if (!$order) {
        echo json_encode(['status' => 'error', 'message' => 'Order not found.']);
        exit;
    }

    $type_of_service = $order['type_of_service'];
    $slot_date = $order['slot_date'];

    // Status change logic for "General Pest"
    if ($type_of_service === 'General Pest' && $status === 'Completed') {
        $session = 'Pest Session 2';
        $status = 'Pending';
        $session2_date = date('Y-m-d', strtotime($slot_date . ' +7 days'));

        $updateStmt = $conn->prepare("UPDATE orders SET status = ?, session = ?, session2_date = ?, status_updated_date = NOW() WHERE order_id = ?");
        $updateStmt->bind_param("sssi", $status, $session, $session2_date, $order_id);
    } else {
        $updateStmt = $conn->prepare("UPDATE orders SET status = ?, status_updated_date = NOW() WHERE order_id = ?");
        $updateStmt->bind_param("si", $status, $order_id);
    }

    if ($updateStmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Order status updated successfully.']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update order status.']);
    }

    $updateStmt->close();
}

$conn->close();
?>
