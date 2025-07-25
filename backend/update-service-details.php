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
if (!isset($data['service_name'], $data['service_types'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$service_name = $data['service_name'];
$service_types = $data['service_types'];

// Find the service_id from the services table
$stmt_service = $conn->prepare("SELECT service_id FROM services WHERE service_name = ?");
$stmt_service->bind_param("s", $service_name);
$stmt_service->execute();
$result = $stmt_service->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Service not found"
    ]);
    exit;
}

$service = $result->fetch_assoc();
$service_id = $service['service_id'];  // Get the service_id

// Begin transaction
$conn->begin_transaction();

try {
    // Delete all existing service details for this service to start fresh
    $stmt_delete_all = $conn->prepare("DELETE FROM service_details WHERE service_id = ?");
    $stmt_delete_all->bind_param("i", $service_id);
    $stmt_delete_all->execute();
    
    // Insert all service types and their pricing fields
    foreach ($service_types as $serviceType) {
        if (!isset($serviceType['typeName'], $serviceType['pricingFields']) || empty($serviceType['typeName'])) {
            continue; // Skip invalid entries
        }
        
        $service_type_name = $serviceType['typeName'];
        $pricing_fields = $serviceType['pricingFields'];
        
        foreach ($pricing_fields as $field) {
            if (!isset($field['roomSize'], $field['price']) || empty($field['roomSize']) || empty($field['price'])) {
                continue; // Skip invalid entries
            }
            
            $room_size = $field['roomSize'];
            $price = $field['price'];
            
            // Insert into service_details table
            $stmt_insert = $conn->prepare("INSERT INTO service_details (service_id, service_type_name, room_size, price) VALUES (?, ?, ?, ?)");
            $stmt_insert->bind_param("issd", $service_id, $service_type_name, $room_size, $price);
            $stmt_insert->execute();
        }
    }
    
    // Commit the transaction
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Service details updated successfully"
    ]);
} catch (Exception $e) {
    // Rollback in case of error
    $conn->rollback();
    
    echo json_encode([
        "status" => "error",
        "message" => "Failed to update service details",
        "error" => $e->getMessage()
    ]);
}

// Close prepared statements and connection
$stmt_service->close();
$conn->close();
?>
