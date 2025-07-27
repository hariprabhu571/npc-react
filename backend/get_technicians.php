<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers first
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Session-ID');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Include the database connection file
    require 'conn.php';
    
    // Debug: Check if $conn is initialized
    if (!isset($conn)) {
        error_log("Database connection is not initialized");
        echo json_encode([
            "status" => "error",
            "message" => "Database connection failed"
        ]);
        exit();
    }
    
    // Check if connection is valid
    if ($conn->connect_error) {
        error_log("Database connection error: " . $conn->connect_error);
        echo json_encode([
            "status" => "error",
            "message" => "Database connection error"
        ]);
        exit();
    }
    
    error_log("Database connection successful - fetching technicians without session validation");
    
    // Check if technicians table exists (try both cases)
    $tableName = 'technicians'; // default lowercase
    $tableCheck = $conn->query("SHOW TABLES LIKE 'technicians'");
    
    if ($tableCheck->num_rows === 0) {
        // Try uppercase
        $tableCheck = $conn->query("SHOW TABLES LIKE 'Technicians'");
        if ($tableCheck->num_rows > 0) {
            $tableName = 'Technicians';
        } else {
            error_log("Neither 'technicians' nor 'Technicians' table exists");
            echo json_encode([
                "status" => "error",
                "message" => "Technicians table not found"
            ]);
            exit();
        }
    }
    
    error_log("Using table name: " . $tableName);
    
    // Fetch all technicians with prepared statement
    $sql = "SELECT technician_id, employee_name, phone_number, service_type, address, id_proof, email FROM $tableName ORDER BY technician_id DESC";
    $result = $conn->query($sql);
    
    if (!$result) {
        error_log("Query failed: " . $conn->error);
        echo json_encode([
            "status" => "error",
            "message" => "Database query failed: " . $conn->error
        ]);
        exit();
    }
    
    if ($result->num_rows > 0) {
        $technicians = [];
        while ($row = $result->fetch_assoc()) {
            // Process id_proof path for frontend usage
            if (!empty($row['id_proof']) && file_exists($row['id_proof'])) {
                // Convert to relative URL path
                $row['id_proof_url'] = str_replace('../', '', $row['id_proof']);
            } else {
                $row['id_proof_url'] = null;
            }
            
            $technicians[] = $row;
        }
        
        error_log("Found " . count($technicians) . " technicians");
        
        // Send JSON response
        echo json_encode([
            "status" => "success",
            "data" => $technicians,
            "count" => count($technicians),
            "message" => "Technicians fetched successfully"
        ]);
    } else {
        error_log("No technicians found in database");
        echo json_encode([
            "status" => "success",
            "data" => [],
            "message" => "No technicians found",
            "count" => 0
        ]);
    }

} catch (Exception $e) {
    error_log("Exception occurred: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Server error occurred: " . $e->getMessage()
    ]);
} finally {
    // Close connection if it exists
    if (isset($conn) && $conn) {
        $conn->close();
    }
}
?>