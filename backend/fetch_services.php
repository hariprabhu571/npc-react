<?php
//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');


// Suppress warnings and notices to prevent them from breaking JSON output
error_reporting(0);
// Include files with @ to suppress any potential warnings
@include 'conn.php';  // Include database connection
@include 'functions.php';  // Include session validation function

// Check if conn.php was successfully included
if (!isset($conn)) {
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit;
}

// Get session ID from request headers
$headers = getallheaders();
$sessionId = '';
foreach ($headers as $name => $value) {
    if (strtolower($name) === 'session-id') {
        $sessionId = $value;
        break;
    }
}

// Get the action from POST data
$action = isset($_POST['action']) ? $_POST['action'] : 'fetch_services';

switch ($action) {
    case 'fetch_services':
        fetchServices();
        break;
    case 'fetch_locations':
        fetchLocations();
        break;
    default:
        fetchServices(); // Default to fetching services for backward compatibility
        break;
}

function fetchServices() {
    global $conn;
    
    try {
        // Get location filter if provided
        $selectedLocation = isset($_POST['location']) ? trim($_POST['location']) : '';
        
        // Base query
        $sql = "SELECT service_id, service_name, description, image_path, locations, created_at FROM services";
        $whereConditions = [];
        $params = [];
        $types = "";
        
        // Add location filter if specified
        if (!empty($selectedLocation)) {
            $whereConditions[] = "JSON_SEARCH(locations, 'one', ?) IS NOT NULL";
            $params[] = $selectedLocation;
            $types .= "s";
        }
        
        // Add WHERE clause if we have conditions
        if (!empty($whereConditions)) {
            $sql .= " WHERE " . implode(" AND ", $whereConditions);
        }
        
        $sql .= " ORDER BY created_at DESC";
        
        // Prepare and execute query
        if (!empty($params)) {
            $stmt = $conn->prepare($sql);
            $stmt->bind_param($types, ...$params);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            $result = $conn->query($sql);
        }
        
        if ($result === false) {
            echo json_encode([
                "status" => "error",
                "message" => "Database query error: " . $conn->error
            ]);
            exit;
        }
        
        $services = [];
        if ($result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $services[] = $row;
            }
        }
        
        echo json_encode([
            "status" => "success",
            "services" => $services,
            "filtered_by_location" => !empty($selectedLocation) ? $selectedLocation : null,
            "total_count" => count($services)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Exception: " . $e->getMessage()
        ]);
    }
}

function fetchLocations() {
    global $conn;
    
    try {
        $sql = "SELECT id, location_name FROM locations ORDER BY location_name ASC";
        $result = $conn->query($sql);
        
        if ($result === false) {
            echo json_encode([
                "status" => "error",
                "message" => "Database query error: " . $conn->error
            ]);
            exit;
        }
        
        $locations = [];
        if ($result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $locations[] = [
                    'id' => $row['id'],
                    'location_name' => $row['location_name']
                ];
            }
        }
        
        echo json_encode([
            "status" => "success",
            "locations" => $locations,
            "total_count" => count($locations)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Exception: " . $e->getMessage()
        ]);
    }
}

// Close the database connection
if (isset($conn)) {
    $conn->close();
}
?>