<?php
include 'conn.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

try {
    // Fetch service types with their pricing details
    $query = "
        SELECT 
            sd.service_type_id,
            sd.service_type_name,
            sd.room_size,
            sd.price,
            s.service_name,
            s.description,
            s.locations
        FROM service_details sd
        JOIN services s ON sd.service_id = s.service_id
        ORDER BY s.service_name, sd.service_type_name, sd.room_size
    ";
    
    $result = $conn->query($query);
    
    // Debug: Log the query and result
    error_log("Service types query (no auth): " . $query);
    error_log("Query result rows (no auth): " . ($result ? $result->num_rows : 'NULL'));
    
    if ($result) {
        $serviceTypes = [];
        $groupedServices = [];
        
        while ($row = $result->fetch_assoc()) {
            $serviceName = $row['service_name'];
            $serviceTypeName = $row['service_type_name'];
            
            // Group by service and service type
            if (!isset($groupedServices[$serviceName])) {
                $groupedServices[$serviceName] = [
                    'service_name' => $serviceName,
                    'description' => $row['description'],
                    'locations' => $row['locations'],
                    'service_types' => []
                ];
            }
            
            if (!isset($groupedServices[$serviceName]['service_types'][$serviceTypeName])) {
                $groupedServices[$serviceName]['service_types'][$serviceTypeName] = [
                    'type_name' => $serviceTypeName,
                    'pricing_fields' => []
                ];
            }
            
            // Add pricing field
            $groupedServices[$serviceName]['service_types'][$serviceTypeName]['pricing_fields'][] = [
                'id' => $row['service_type_id'],
                'room_size' => $row['room_size'],
                'price' => $row['price']
            ];
        }
        
        // Convert to array format
        foreach ($groupedServices as $serviceName => $service) {
            $serviceTypes[] = [
                'service_name' => $service['service_name'],
                'description' => $service['description'],
                'locations' => $service['locations'],
                'service_types' => array_values($service['service_types'])
            ];
        }
        
        echo json_encode([
            "status" => "success",
            "data" => $serviceTypes,
            "count" => count($serviceTypes),
            "debug_info" => [
                "total_rows" => $result->num_rows,
                "grouped_services_count" => count($groupedServices)
            ]
        ]);
        
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to fetch service types: " . $conn->error
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Exception: " . $e->getMessage()
    ]);
}

// Close the database connection
if (isset($conn)) {
    $conn->close();
}
?> 