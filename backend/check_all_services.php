<?php
include 'conn.php';

echo "Checking all services in the database:\n";
echo "=====================================\n\n";

try {
    $query = "SELECT service_id, service_name, image_path FROM services ORDER BY service_id";
    $result = $conn->query($query);
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            echo "Service ID: " . $row['service_id'] . "\n";
            echo "Service Name: " . $row['service_name'] . "\n";
            echo "Image Path: " . ($row['image_path'] ?: 'NULL') . "\n";
            echo "Has Image: " . (!empty($row['image_path']) ? 'YES' : 'NO') . "\n";
            echo "---\n";
        }
    } else {
        echo "Error querying database: " . $conn->error . "\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?> 