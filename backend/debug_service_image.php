<?php
include 'conn.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

try {
    // Get service name from query parameters
    $service_name = isset($_GET['service_name']) ? trim($_GET['service_name']) : '';

    if (empty($service_name)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service name is required as query parameter"
        ]);
        exit;
    }

    // Check the services table for this service
    $stmt_service = $conn->prepare("SELECT service_id, service_name, image_path FROM services WHERE service_name = ?");
    if (!$stmt_service) {
        throw new Exception("Failed to prepare service query: " . $conn->error);
    }
    
    $stmt_service->bind_param("s", $service_name);
    
    if (!$stmt_service->execute()) {
        throw new Exception("Failed to execute service query: " . $stmt_service->error);
    }
    
    $result_service = $stmt_service->get_result();

    if ($result_service->num_rows === 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service not found in database"
        ]);
        exit;
    }

    $service = $result_service->fetch_assoc();
    
    echo json_encode([
        "status" => "success",
        "service_data" => [
            "service_id" => $service['service_id'],
            "service_name" => $service['service_name'],
            "image_path" => $service['image_path'],
            "image_path_is_null" => is_null($service['image_path']),
            "image_path_is_empty" => empty($service['image_path'])
        ],
        "message" => "Service data retrieved successfully"
    ]);

} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Exception: " . $e->getMessage()
    ]);
} finally {
    if (isset($stmt_service) && $stmt_service !== false) {
        $stmt_service->close();
    }
    if (isset($conn) && $conn !== false) {
        $conn->close();
    }
}
?> 