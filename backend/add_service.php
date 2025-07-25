<?php
//add_service.php
include 'conn.php';  // Include database connection
include 'functions.php';  // Include session validation function

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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

// Check if form data exists
if (!isset($_POST['service_name']) || !isset($_POST['description'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
    exit;
}

$service_name = trim($_POST['service_name']);
$description = trim($_POST['description']);
$image_path = null;

// Handle locations (JSON format)
$locations_json = isset($_POST['locations']) ? $_POST['locations'] : '[]';

// Validate inputs
if (empty($service_name)) {
    echo json_encode([
        "status" => "error",
        "message" => "Service name is required"
    ]);
    exit;
}

// Handle image upload if an image was provided
if (isset($_FILES['service_image']) && $_FILES['service_image']['error'] == 0) {
    // Create directory if it doesn't exist
    $upload_dir = 'ServiceImages/';
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    // Generate a unique filename
    $file_extension = pathinfo($_FILES['service_image']['name'], PATHINFO_EXTENSION);
    $filename = 'service_' . time() . '_' . uniqid() . '.' . $file_extension;
    $target_path = $upload_dir . $filename;
    
    // Check file type
    $allowed_types = ['jpg', 'jpeg', 'png', 'gif'];
    if (!in_array(strtolower($file_extension), $allowed_types)) {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid file type. Only JPG, JPEG, PNG, and GIF files are allowed."
        ]);
        exit;
    }
    
    // Move the uploaded file to our directory
    if (move_uploaded_file($_FILES['service_image']['tmp_name'], $target_path)) {
        $image_path = $target_path;
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to upload image."
        ]);
        exit;
    }
}

// Prepare the SQL statement with image_path and locations
$stmt = $conn->prepare("INSERT INTO services (service_name, description, image_path, locations) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $service_name, $description, $image_path, $locations_json);

// Execute the query and check if successful
if ($stmt->execute()) {
    echo json_encode([
        "status" => "success",
        "message" => "Service added successfully",
        "service_id" => $conn->insert_id
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to add service",
        "error" => $stmt->error
    ]);
}

// Close the statement and connection
$stmt->close();
$conn->close();
?>