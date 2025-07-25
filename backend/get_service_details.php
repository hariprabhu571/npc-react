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

// Get service name from query parameters
$service_name = isset($_GET['service_name']) ? $_GET['service_name'] : '';

if (empty($service_name)) {
    echo json_encode([
        "status" => "error",
        "message" => "Service name is required"
    ]);
    exit;
}

// First, get the service_id for the service name
$stmt_service = $conn->prepare("SELECT service_id FROM services WHERE service_name = ?");
$stmt_service->bind_param("s", $service_name);
$stmt_service->execute();
$result_service = $stmt_service->get_result();

if ($result_service->num_rows === 0) {
    echo json_encode([
        "status" => "error",
        "message" => "Service not found"
    ]);
    exit;
}

$service = $result_service->fetch_assoc();
$service_id = $service['service_id'];

// Now fetch all service details using the actual schema
$stmt_details = $conn->prepare("
    SELECT 
        service_type_id,
        service_type_name, 
        room_size, 
        price,
        service_type_id as pricing_field_id
    FROM 
        service_details
    WHERE 
        service_id = ? 
    ORDER BY 
        service_type_name, room_size
");
$stmt_details->bind_param("i", $service_id);
$stmt_details->execute();
$result_details = $stmt_details->get_result();

// Group by service_type_name
$grouped_data = [];
while ($row = $result_details->fetch_assoc()) {
    $service_type_name = $row['service_type_name'];
    
    // Check if this service type name already exists in our grouped data
    $found = false;
    foreach ($grouped_data as &$group) {
        if ($group['service_type_name'] === $service_type_name) {
            // Add this pricing field to the existing group
            $group['pricing_fields'][] = [
                'pricing_field_id' => $row['pricing_field_id'],
                'room_size' => $row['room_size'],
                'price' => $row['price']
            ];
            $found = true;
            break;
        }
    }
    
    // If not found, create a new group
    if (!$found) {
        $grouped_data[] = [
            'service_type_id' => $row['service_type_id'],
            'service_type_name' => $service_type_name,
            'pricing_fields' => [
                [
                    'pricing_field_id' => $row['pricing_field_id'],
                    'room_size' => $row['room_size'],
                    'price' => $row['price']
                ]
            ]
        ];
    }
}

// Return the grouped data
echo json_encode([
    "status" => "success",
    "data" => $grouped_data
]);

// Close prepared statements and connection
$stmt_service->close();
$stmt_details->close();
$conn->close();
?>