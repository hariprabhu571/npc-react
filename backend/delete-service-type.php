<?php
//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include 'conn.php'; // Include the database connection
include 'functions.php'; // Include session validation function

$headers = getallheaders();

// Try different header case variations as header names can be case-insensitive
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

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

// Get the request body
$requestData = json_decode(file_get_contents('php://input'), true);

// Validate request data
if (!isset($requestData['service_type_id']) || empty($requestData['service_type_id'])) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Service type ID is required']);
    exit;
}

// Extract data
$serviceTypeId = intval($requestData['service_type_id']);

// Start transaction
$conn->begin_transaction();

try {
    // Delete all records with this service type ID
    $deleteQuery = "DELETE FROM service_details WHERE service_type_id = ?";
    $stmt = $conn->prepare($deleteQuery);
    $stmt->bind_param("i", $serviceTypeId);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to delete service type: " . $stmt->error);
    }
    
    $rowsAffected = $stmt->affected_rows;
    $stmt->close();
    
    // Commit transaction
    $conn->commit();
    
    echo json_encode([
        'status' => 'success', 
        'message' => 'Service type deleted successfully',
        'rows_affected' => $rowsAffected
    ]);
} catch (Exception $e) {
    // Roll back transaction on error
    $conn->rollback();
    
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
} finally {
    // Close the database connection
    $conn->close();
}
?>