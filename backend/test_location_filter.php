<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include 'conn.php';

if (!isset($conn)) {
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit;
}

// Test location filtering
$testLocation = "Coimbatore";

echo "Testing location filter for: " . $testLocation . "\n\n";

// Test 1: Check all services and their locations
echo "=== ALL SERVICES ===\n";
$sql1 = "SELECT service_id, service_name, locations FROM services ORDER BY service_id";
$result1 = $conn->query($sql1);

if ($result1->num_rows > 0) {
    while ($row = $result1->fetch_assoc()) {
        echo "Service ID: " . $row['service_id'] . ", Name: " . $row['service_name'] . ", Locations: " . $row['locations'] . "\n";
    }
}

echo "\n=== TESTING JSON_SEARCH ===\n";

// Test 2: Test JSON_SEARCH function
$sql2 = "SELECT service_id, service_name, locations, 
         JSON_SEARCH(locations, 'one', ?) as search_result,
         JSON_SEARCH(locations, 'one', ?) IS NOT NULL as is_found
         FROM services 
         ORDER BY service_id";

$stmt2 = $conn->prepare($sql2);
$stmt2->bind_param("ss", $testLocation, $testLocation);
$stmt2->execute();
$result2 = $stmt2->get_result();

if ($result2->num_rows > 0) {
    while ($row = $result2->fetch_assoc()) {
        echo "Service ID: " . $row['service_id'] . 
             ", Name: " . $row['service_name'] . 
             ", Locations: " . $row['locations'] . 
             ", Search Result: " . ($row['search_result'] ?: 'NULL') . 
             ", Is Found: " . ($row['is_found'] ? 'YES' : 'NO') . "\n";
    }
}

echo "\n=== FILTERED RESULTS ===\n";

// Test 3: Apply the actual filter
$sql3 = "SELECT service_id, service_name, locations FROM services WHERE JSON_SEARCH(locations, 'one', ?) IS NOT NULL ORDER BY service_id";
$stmt3 = $conn->prepare($sql3);
$stmt3->bind_param("s", $testLocation);
$stmt3->execute();
$result3 = $stmt3->get_result();

echo "Services found for '$testLocation': " . $result3->num_rows . "\n";
if ($result3->num_rows > 0) {
    while ($row = $result3->fetch_assoc()) {
        echo "Service ID: " . $row['service_id'] . ", Name: " . $row['service_name'] . ", Locations: " . $row['locations'] . "\n";
    }
}

// Test 4: Check for services with empty or null locations
echo "\n=== SERVICES WITH EMPTY/NULL LOCATIONS ===\n";
$sql4 = "SELECT service_id, service_name, locations FROM services WHERE locations IS NULL OR locations = '[]' OR locations = '' ORDER BY service_id";
$result4 = $conn->query($sql4);

if ($result4->num_rows > 0) {
    while ($row = $result4->fetch_assoc()) {
        echo "Service ID: " . $row['service_id'] . ", Name: " . $row['service_name'] . ", Locations: " . $row['locations'] . "\n";
    }
}

$conn->close();
?> 