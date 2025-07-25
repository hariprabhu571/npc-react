<?php
require 'conn.php'; // Database connection

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get Session-ID from headers
    $headers = getallheaders();
    $sessionid = $headers['Session-ID'] ?? null;

    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate session ID
    if (empty($sessionid)) {
        echo json_encode(['status' => 'error', 'message' => 'Session ID is required.']);
        exit;
    }

    $stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired session. Please log in again.']);
        exit;
    }

    // Validate input
    if (empty($input['customer_name']) || empty($input['mobile_no']) || empty($input['slot_date']) || 
        empty($input['slot_time']) || empty($input['address']) || empty($input['payment_mode']) || 
        empty($input['type_of_service']) || empty($input['space']) || empty($input['amount']) || 
        empty($input['paymentid'])) {
        echo json_encode(['status' => 'error', 'message' => 'All fields are required.']);
        exit;
    }

    // Extract input data
    $customer_name = $input['customer_name'];
    $mobile_no = $input['mobile_no'];
    $slot_date = $input['slot_date'];
    $slot_time = $input['slot_time'];
    $address = $input['address'];
    $payment_mode = $input['payment_mode'];
    $type_of_service = $input['type_of_service'];
    $space = $input['space'];
    $amount = $input['amount'];
    $paymentid = $input['paymentid'];

    // Default values
    $status = 'Pending';
    $assigned_technician = NULL;
    $session = 'Pest Session 1';
    $booked_date = date('Y-m-d H:i:s');
    $status_updated_date = NULL;
    $session2_date = NULL;

    // Insert order into the database
    $stmt = $conn->prepare("
        INSERT INTO orders (
            customer_name, mobile_no, slot_date, slot_time, address, payment_mode, 
            status, assigned_technician, session, type_of_service, space, amount, 
            status_updated_date, booked_date, paymentid, session2_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->bind_param(
        "sssssssssssdssss", 
        $customer_name, $mobile_no, $slot_date, $slot_time, $address, $payment_mode,
        $status, $assigned_technician, $session, $type_of_service, $space, $amount,
        $status_updated_date, $booked_date, $paymentid, $session2_date
    );

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Order created successfully.']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to create order.']);
    }

    $stmt->close();
}

$conn->close();
?>
