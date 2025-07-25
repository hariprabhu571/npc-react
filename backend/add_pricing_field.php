<?php
include 'conn.php'; // Include the database connection
include 'functions.php'; // Include session validation function

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

// Validate session ID
if (empty($sessionId) || !validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Get the raw POST data (JSON)
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['service_name'], $data['service_type_name'], $data['room_size'], $data['price'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$service_name = $data['service_name']; // Get service name
$service_type_name = $data['service_type_name'];
$room_size = $data['room_size'];
$price = $data['price'];

// Validate price is numeric
if (!is_numeric($price)) {
    echo json_encode([
        "status" => "error",
        "message" => "Price must be a valid number"
    ]);
    exit;
}

// Begin transaction
$conn->begin_transaction();

try {
    // Step 1: Get service_id from services table based on service_name
    $stmt_service = $conn->prepare("SELECT service_id FROM services WHERE service_name = ? LIMIT 1");
    $stmt_service->bind_param("s", $service_name);
    $stmt_service->execute();
    $result_service = $stmt_service->get_result();

    if ($result_service->num_rows === 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service name not found in services table"
        ]);
        $conn->rollback();
        exit;
    }

    $service_row = $result_service->fetch_assoc();
    $service_id = $service_row['service_id']; // Found service_id

    // Step 2: Check if the same service_type_name and room_size exist in service_details
    $stmt_check = $conn->prepare("SELECT service_type_id FROM service_details WHERE service_type_name = ? AND room_size = ? AND service_id = ?");
    $stmt_check->bind_param("ssi", $service_type_name, $room_size, $service_id);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();

    if ($result_check->num_rows > 0) {
        // If record exists, update the price
        $row = $result_check->fetch_assoc();
        $existing_service_type_id = $row['service_type_id'];

        $stmt_update = $conn->prepare("UPDATE service_details SET price = ? WHERE service_type_id = ?");
        $stmt_update->bind_param("di", $price, $existing_service_type_id);
        $stmt_update->execute();

        $conn->commit();
        echo json_encode([
            "status" => "success",
            "message" => "Service detail updated successfully",
            "service_type_id" => $existing_service_type_id
        ]);
    } else {
        // If no existing record, insert a new one
        $stmt_insert = $conn->prepare("INSERT INTO service_details (service_type_name, service_id, room_size, price) VALUES (?, ?, ?, ?)");
        $stmt_insert->bind_param("sisd", $service_type_name, $service_id, $room_size, $price);
        $stmt_insert->execute();

        $new_service_type_id = $conn->insert_id;
        $conn->commit();

        echo json_encode([
            "status" => "success",
            "message" => "Service detail added successfully",
            "service_type_id" => $new_service_type_id
        ]);
    }
} catch (Exception $e) {
    // Rollback in case of error
    $conn->rollback();
    
    echo json_encode([
        "status" => "error",
        "message" => "Failed to add or update service detail",
        "error" => $e->getMessage()
    ]);
}

// Close connection
$conn->close();
?>
