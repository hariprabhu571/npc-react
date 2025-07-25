<?php
// Set proper content type header
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Session-ID');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'conn.php'; // Include the database connection

try {
    // Check database connection first
    if (!$conn || $conn->connect_error) {
        echo json_encode([
            "status" => "error",
            "message" => "Database connection failed"
        ]);
        exit;
    }

    // Get service name from query parameters
    $service_name = isset($_GET['service_name']) ? trim($_GET['service_name']) : '';

    if (empty($service_name)) {
        echo json_encode([
            "status" => "error",
            "message" => "Service name is required as query parameter"
        ]);
        exit;
    }

    // First, get the service_id for the service name
    $stmt_service = $conn->prepare("SELECT service_id FROM services WHERE service_name = ?");
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
            "message" => "Service not found"
        ]);
        exit;
    }

    $service = $result_service->fetch_assoc();
    $service_id = $service['service_id'];

    // Now fetch all service details using the actual schema
    $stmt_details = $conn->prepare("
        SELECT 
            sd.service_type_id,
            sd.service_type_name, 
            sd.room_size, 
            sd.price,
            sd.service_type_id as pricing_field_id,
            s.service_name,
            s.description as service_description
        FROM 
            service_details sd
        INNER JOIN 
            services s ON sd.service_id = s.service_id
        WHERE 
            sd.service_id = ? 
        ORDER BY 
            sd.service_type_name, 
            sd.room_size
    ");
    
    if (!$stmt_details) {
        throw new Exception("Failed to prepare details query: " . $conn->error);
    }
    
    $stmt_details->bind_param("i", $service_id);
    
    if (!$stmt_details->execute()) {
        throw new Exception("Failed to execute details query: " . $stmt_details->error);
    }
    
    $result_details = $stmt_details->get_result();

    // Check if any service details found
    if ($result_details->num_rows === 0) {
        echo json_encode([
            "status" => "success",
            "message" => "No service options available for this service",
            "data" => []
        ]);
        exit;
    }

    // Group by service_type_name and collect service info
    $grouped_data = [];
    $service_info = null;
    
    while ($row = $result_details->fetch_assoc()) {
        // Store service info from first row
        if ($service_info === null) {
            $service_info = [
                'service_name' => $row['service_name'],
                'service_description' => $row['service_description']
            ];
        }
        
        $service_type_name = $row['service_type_name'];
        
        // Check if this service type name already exists in our grouped data
        $found = false;
        foreach ($grouped_data as &$group) {
            if ($group['service_type_name'] === $service_type_name) {
                // Add this pricing field to the existing group
                $group['pricing'][] = [
                    'id' => $row['pricing_field_id'],
                    'room_size' => $row['room_size'],
                    'price' => floatval($row['price'])
                ];
                $found = true;
                break;
            }
        }
        
        // If not found, create a new group
        if (!$found) {
            $grouped_data[] = [
                'service_type_id' => intval($row['service_type_id']),
                'service_type_name' => $service_type_name,
                'pricing' => [
                    [
                        'id' => $row['pricing_field_id'],
                        'room_size' => $row['room_size'],
                        'price' => floatval($row['price'])
                    ]
                ]
            ];
        }
    }

    // Return the grouped data with service information
    echo json_encode([
        "status" => "success",
        "message" => "Service details retrieved successfully",
        "service_info" => $service_info,
        "data" => $grouped_data,
        "total_service_types" => count($grouped_data)
    ]);

} catch (Exception $e) {
    // Log error for debugging (in production, log to file)
    error_log("Error in get_user_service_details.php: " . $e->getMessage());
    
    echo json_encode([
        "status" => "error",
        "message" => "An error occurred while fetching service details: " . $e->getMessage()
    ]);
} finally {
    // Close prepared statements and connection - only if they exist and are valid
    if (isset($stmt_service) && $stmt_service !== false) {
        $stmt_service->close();
    }
    if (isset($stmt_details) && $stmt_details !== false) {
        $stmt_details->close();
    }
    if (isset($conn) && $conn !== false) {
        $conn->close();
    }
}
?>