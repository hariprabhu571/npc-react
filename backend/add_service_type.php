<?php
include 'conn.php'; // Include the database connection
include 'functions.php'; // Include session validation function


//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
// Get session ID from request headers
$headers = getallheaders();
error_log(print_r($headers, true));

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

// Get the raw POST data (JSON)
$data = json_decode(file_get_contents("php://input"), true);

// Validate input
if (!isset($data['service_name'], $data['service_type_name'], $data['pricing'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$service_name = $data['service_name'];
$service_type_name = $data['service_type_name'];
$pricing = $data['pricing'];

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

// Insert each pricing detail into the service_details table
foreach ($pricing as $price_detail) {
    if (!isset($price_detail['room_size'], $price_detail['price'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid pricing details provided"
        ]);
        exit;
    }

    $room_size = $price_detail['room_size'];
    $price = $price_detail['price'];

    // Insert into service_details table
    $stmt_insert = $conn->prepare("INSERT INTO service_details (service_type_name, service_id, room_size, price) VALUES (?, ?, ?, ?)");
    $stmt_insert->bind_param("sisd", $service_type_name, $service_id, $room_size, $price);

    if (!$stmt_insert->execute()) {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to insert pricing detail",
            "error" => $stmt_insert->error
        ]);
        exit;
    }
}

// Success response
echo json_encode([
    "status" => "success",
    "message" => "Service details added successfully"
]);

// Close prepared statements and connection
$stmt_service->close();
$conn->close();
?>
