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
if (!isset($data['service_type_id'], $data['service_type_name'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$service_type_id = $data['service_type_id'];
$type_name = $data['service_type_name'];

// Validate type name is not empty
if (empty($type_name)) {
    echo json_encode([
        "status" => "error",
        "message" => "Type name cannot be empty"
    ]);
    exit;
}

// Begin transaction
$conn->begin_transaction();

try {
    // First check if service type exists
    $stmt_check = $conn->prepare("SELECT service_type_id FROM service_details WHERE service_type_id = ?");
    $stmt_check->bind_param("i", $service_type_id);
    $stmt_check->execute();
    $result = $stmt_check->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service type not found"
        ]);
        exit;
    }
    
    // Update the service type
    $stmt_update = $conn->prepare("UPDATE service_details SET service_type_name = ? WHERE service_type_id = ?");
    $stmt_update->bind_param("si", $type_name, $service_type_id);
    $stmt_update->execute();
    
    
    // Commit the transaction
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Service type updated successfully"
    ]);
} catch (Exception $e) {
    // Rollback in case of error
    $conn->rollback();
    
    echo json_encode([
        "status" => "error",
        "message" => "Failed to update service type",
        "error" => $e->getMessage()
    ]);
}

// Close connection
$conn->close();
?>