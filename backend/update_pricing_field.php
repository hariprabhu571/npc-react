<?php
include 'conn.php'; 
include 'functions.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');


$headers = getallheaders();
$sessionId = '';

foreach ($headers as $name => $value) {
    if (strtolower($name) === 'session-id') {
        $sessionId = $value;
        break;
    }
}


if (empty($sessionId) || !validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}


$data = json_decode(file_get_contents("php://input"), true);


if (!isset($data['pricing_field_id'], $data['room_size'], $data['price'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$pricing_field_id = $data['pricing_field_id'];
$room_size = $data['room_size'];
$price = $data['price'];


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
    // First check if pricing field exists
    // Check if the pricing field exists in service_details table
$stmt_check = $conn->prepare("SELECT service_type_id FROM service_details WHERE service_type_id = ?");
$stmt_check->bind_param("i", $pricing_field_id);
$stmt_check->execute();
$result = $stmt_check->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Pricing field not found"
    ]);
    exit;
}

// Update the pricing field
$stmt_update = $conn->prepare("UPDATE service_details SET room_size = ?, price = ? WHERE service_type_id = ?");
$stmt_update->bind_param("sdi", $room_size, $price, $pricing_field_id);
$stmt_update->execute();

    
    // Commit the transaction
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Pricing field updated successfully"
    ]);
} catch (Exception $e) {
    // Rollback in case of error
    $conn->rollback();
    
    echo json_encode([
        "status" => "error",
        "message" => "Failed to update pricing field",
        "error" => $e->getMessage()
    ]);
}

// Close connection
$conn->close();
?>