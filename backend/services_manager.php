<?php
//services_manager.php
include 'conn.php';
include 'functions.php';

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

// Get the action from POST data
$action = isset($_POST['action']) ? $_POST['action'] : '';

switch ($action) {
    case 'fetch_services':
        fetchServices();
        break;
    case 'add_service':
        addService();
        break;
    case 'update_service':
        updateService();
        break;
    case 'delete_service':
        deleteService();
        break;
    case 'fetch_locations':
        fetchLocations();
        break;
    case 'add_location':
        addLocation();
        break;
    case 'delete_location':
        deleteLocation();
        break;
    default:
        echo json_encode([
            "status" => "error",
            "message" => "Invalid action"
        ]);
        break;
}

function fetchServices() {
    global $conn;
    
    try {
        $query = "SELECT service_id, service_name, description, image_path, locations, created_at FROM services ORDER BY created_at DESC";
        $result = $conn->query($query);
        
        if ($result) {
            $services = [];
            
            while ($row = $result->fetch_assoc()) {
                // Format the created_at date
                $created_date = new DateTime($row['created_at']);
                $formatted_date = $created_date->format('M d, Y');
                
                $services[] = [
                    'service_id' => $row['service_id'],
                    'service_name' => $row['service_name'],
                    'description' => $row['description'],
                    'image_path' => $row['image_path'],
                    'locations' => $row['locations'],
                    'created_at' => $formatted_date
                ];
            }
            
            echo json_encode([
                "status" => "success",
                "services" => $services,
                "count" => count($services)
            ]);
            
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Failed to fetch services: " . $conn->error
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Error: " . $e->getMessage()
        ]);
    }
}

function addService() {
    global $conn;
    
    // Check if form data exists
    if (!isset($_POST['service_name']) || !isset($_POST['description'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Missing required fields"
        ]);
        return;
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
        return;
    }

    // Handle image upload if an image was provided
    if (isset($_FILES['service_image']) && $_FILES['service_image']['error'] == 0) {
        $image_path = handleImageUpload($_FILES['service_image']);
        if ($image_path === false) {
            return; // Error already echoed in handleImageUpload
        }
    }

    // Prepare the SQL statement
    $stmt = $conn->prepare("INSERT INTO services (service_name, description, image_path, locations) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $service_name, $description, $image_path, $locations_json);

    // Execute the query
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
    
    $stmt->close();
}

function updateService() {
    global $conn;
    
    // Check if required data exists
    if (!isset($_POST['service_id']) || !isset($_POST['service_name']) || !isset($_POST['description'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Missing required fields"
        ]);
        return;
    }

    $service_id = trim($_POST['service_id']);
    $service_name = trim($_POST['service_name']);
    $description = trim($_POST['description']);
    $locations_json = isset($_POST['locations']) ? $_POST['locations'] : '[]';

    // Validate inputs
    if (empty($service_id) || empty($service_name)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service ID and name are required"
        ]);
        return;
    }

    // First, get the current service data
    $stmt = $conn->prepare("SELECT image_path FROM services WHERE service_id = ?");
    $stmt->bind_param("i", $service_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service not found"
        ]);
        return;
    }

    $current_service = $result->fetch_assoc();
    $current_image_path = $current_service['image_path'];
    $new_image_path = $current_image_path; // Keep current image by default

    // Handle image upload if a new image was provided
    if (isset($_FILES['service_image']) && $_FILES['service_image']['error'] == 0) {
        $new_image_path = handleImageUpload($_FILES['service_image']);
        if ($new_image_path === false) {
            return; // Error already echoed in handleImageUpload
        }
        
        // Delete old image if it exists and new image uploaded successfully
        if ($current_image_path && file_exists($current_image_path)) {
            unlink($current_image_path);
        }
    }

    // Update the service in database
    $stmt = $conn->prepare("UPDATE services SET service_name = ?, description = ?, image_path = ?, locations = ? WHERE service_id = ?");
    $stmt->bind_param("ssssi", $service_name, $description, $new_image_path, $locations_json, $service_id);

    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Service updated successfully",
            "service_id" => $service_id
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to update service",
            "error" => $stmt->error
        ]);
    }

    $stmt->close();
}

function deleteService() {
    global $conn;
    
    if (!isset($_POST['service_id'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Service ID is required"
        ]);
        return;
    }

    $service_id = trim($_POST['service_id']);

    if (empty($service_id)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service ID is required"
        ]);
        return;
    }

    // First, get the service data to delete associated image
    $stmt = $conn->prepare("SELECT image_path FROM services WHERE service_id = ?");
    $stmt->bind_param("i", $service_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        echo json_encode([
            "status" => "error",
            "message" => "Service not found"
        ]);
        return;
    }

    $service = $result->fetch_assoc();
    $image_path = $service['image_path'];

    // Delete the service from database
    $stmt = $conn->prepare("DELETE FROM services WHERE service_id = ?");
    $stmt->bind_param("i", $service_id);

    if ($stmt->execute()) {
        // Delete associated image file if it exists
        if ($image_path && file_exists($image_path)) {
            unlink($image_path);
        }
        
        echo json_encode([
            "status" => "success",
            "message" => "Service deleted successfully"
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to delete service",
            "error" => $stmt->error
        ]);
    }

    $stmt->close();
}

function fetchLocations() {
    global $conn;
    
    try {
        $query = "SELECT id, location_name FROM locations ORDER BY location_name ASC";
        $result = $conn->query($query);
        
        if ($result) {
            $locations = [];
            while ($row = $result->fetch_assoc()) {
                $locations[] = [
                    'id' => $row['id'],
                    'location_name' => $row['location_name']
                ];
            }
            
            echo json_encode([
                "status" => "success",
                "locations" => $locations
            ]);
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Failed to fetch locations: " . $conn->error
            ]);
        }
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Error: " . $e->getMessage()
        ]);
    }
}

function addLocation() {
    global $conn;
    
    if (!isset($_POST['location_name']) || empty(trim($_POST['location_name']))) {
        echo json_encode([
            "status" => "error",
            "message" => "Location name is required"
        ]);
        return;
    }
    
    $location_name = trim($_POST['location_name']);
    
    try {
        $stmt = $conn->prepare("INSERT INTO locations (location_name) VALUES (?)");
        $stmt->bind_param("s", $location_name);
        
        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success",
                "message" => "Location added successfully",
                "location_id" => $conn->insert_id,
                "location_name" => $location_name
            ]);
        } else {
            if ($conn->errno == 1062) { // Duplicate entry error
                echo json_encode([
                    "status" => "error",
                    "message" => "Location already exists"
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to add location: " . $stmt->error
                ]);
            }
        }
        
        $stmt->close();
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Error: " . $e->getMessage()
        ]);
    }
}

function deleteLocation() {
    global $conn;
    
    if (!isset($_POST['location_id']) || empty($_POST['location_id'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Location ID is required"
        ]);
        return;
    }
    
    $location_id = intval($_POST['location_id']);
    
    try {
        $stmt = $conn->prepare("DELETE FROM locations WHERE id = ?");
        $stmt->bind_param("i", $location_id);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode([
                    "status" => "success",
                    "message" => "Location deleted successfully"
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Location not found"
                ]);
            }
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Failed to delete location: " . $stmt->error
            ]);
        }
        
        $stmt->close();
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Error: " . $e->getMessage()
        ]);
    }
}

function handleImageUpload($file) {
    // Create directory if it doesn't exist
    $upload_dir = 'ServiceImages/';
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    // Generate a unique filename
    $file_extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'service_' . time() . '_' . uniqid() . '.' . $file_extension;
    $target_path = $upload_dir . $filename;
    
    // Check file type
    $allowed_types = ['jpg', 'jpeg', 'png', 'gif'];
    if (!in_array(strtolower($file_extension), $allowed_types)) {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid file type. Only JPG, JPEG, PNG, and GIF files are allowed."
        ]);
        return false;
    }
    
    // Check file size (5MB limit)
    if ($file['size'] > 5 * 1024 * 1024) {
        echo json_encode([
            "status" => "error",
            "message" => "File size too large. Maximum 5MB allowed."
        ]);
        return false;
    }
    
    // Move the uploaded file to our directory
    if (move_uploaded_file($file['tmp_name'], $target_path)) {
        return $target_path;
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to upload image."
        ]);
        return false;
    }
}

$conn->close();
?>