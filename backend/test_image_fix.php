<?php
// Test script to verify the image_path fix
include 'conn.php';

// Test with a service that exists in the database
$service_name = "Rat Control"; // This service exists in the database with image_path

// Simulate the get_user_service_details.php logic
try {
    // First, get the service_id for the service name
    $stmt_service = $conn->prepare("SELECT service_id, image_path FROM services WHERE service_name = ?");
    $stmt_service->bind_param("s", $service_name);
    $stmt_service->execute();
    $result_service = $stmt_service->get_result();

    if ($result_service->num_rows === 0) {
        echo "Service not found: $service_name\n";
        exit;
    }

    $service = $result_service->fetch_assoc();
    $service_id = $service['service_id'];
    $service_image_path = $service['image_path'];

    echo "Service found:\n";
    echo "Service ID: $service_id\n";
    echo "Service Name: $service_name\n";
    echo "Image Path: " . ($service_image_path ?: 'NULL') . "\n";
    echo "Image Path is null: " . (is_null($service_image_path) ? 'YES' : 'NO') . "\n";
    echo "Image Path is empty: " . (empty($service_image_path) ? 'YES' : 'NO') . "\n";

    // Create service_info object (simulating the fixed logic)
    $service_info = [
        'service_name' => $service_name,
        'service_description' => null,
        'image_path' => $service_image_path
    ];

    echo "\nService Info Object:\n";
    echo json_encode($service_info, JSON_PRETTY_PRINT) . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
} finally {
    if (isset($stmt_service)) {
        $stmt_service->close();
    }
    if (isset($conn)) {
        $conn->close();
    }
}
?> 