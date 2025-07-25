<?php
// Test file to check image accessibility
header('Content-Type: application/json');

$base_url = 'https://npcpest.com/npc/';
$test_images = [
    'ServiceImages/pest1.jpg',
    'ServiceImages/service_1752339543_687294578d3ef.jpg',
    'ServiceImages/service_1751909796_686c05a4715e4.jpg',
    'ServiceImages/service_1744306811_67f8027b63d16.jpg',
    'ServiceImages/image.png'
];

$results = [];

foreach ($test_images as $image_path) {
    $full_url = $base_url . $image_path;
    
    // Check if file exists locally
    $local_exists = file_exists($image_path);
    
    // Check if file is accessible via HTTP
    $headers = @get_headers($full_url);
    $http_accessible = $headers && strpos($headers[0], '200') !== false;
    
    $results[] = [
        'image_path' => $image_path,
        'full_url' => $full_url,
        'local_exists' => $local_exists,
        'http_accessible' => $http_accessible,
        'headers' => $headers ? $headers[0] : 'No response'
    ];
}

echo json_encode($results, JSON_PRETTY_PRINT);
?> 