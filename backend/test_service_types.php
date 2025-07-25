<?php
include 'conn.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

try {
    // Simple query to check if data exists
    $query = "SELECT COUNT(*) as total FROM service_details";
    $result = $conn->query($query);
    
    if ($result) {
        $row = $result->fetch_assoc();
        $total = $row['total'];
        
        // Also get a sample of the data
        $sampleQuery = "SELECT * FROM service_details LIMIT 5";
        $sampleResult = $conn->query($sampleQuery);
        
        $samples = [];
        if ($sampleResult) {
            while ($sampleRow = $sampleResult->fetch_assoc()) {
                $samples[] = $sampleRow;
            }
        }
        
        echo json_encode([
            "status" => "success",
            "total_records" => $total,
            "sample_data" => $samples,
            "message" => "Test completed successfully"
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to query database: " . $conn->error
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