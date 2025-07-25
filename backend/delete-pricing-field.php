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
if (!isset($data['service_type_id'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing service type ID"
    ]);
    exit;
}

$service_type_id = $data['service_type_id'];

// Begin transaction
$conn->begin_transaction();

try {
    // First check if the service type exists
    $stmt_check = $conn->prepare("SELECT service_type_id FROM service_details WHERE service_type_id = ?");
    $stmt_check->bind_param("i", $service_type_id);
    $stmt_check->execute();
    $result = $stmt_check->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service type not found"
        ]);
        $conn->rollback();
        exit;
    }
    
    // Delete the service detail row
    $stmt_delete = $conn->prepare("DELETE FROM service_details WHERE service_type_id = ?");
    $stmt_delete->bind_param("i", $service_type_id);
    $stmt_delete->execute();
    
    // Commit the transaction
    $conn->commit();
    
    echo json_encode([
        "status" => "success",
        "message" => "Service detail deleted successfully"
    ]);
} catch (Exception $e) {
    // Rollback in case of error
    $conn->rollback();
    
    echo json_encode([
        "status" => "error",
        "message" => "Failed to delete service detail",
        "error" => $e->getMessage()
    ]);
}

// Close connection
$conn->close();
?>