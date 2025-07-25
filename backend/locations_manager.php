<?php
//locations_manager.php
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

$conn->close();
?>