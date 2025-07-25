<?php
// Image serving script with proper headers
if (!isset($_GET['path'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Image path not provided']);
    exit;
}

$image_path = $_GET['path'];
$full_path = __DIR__ . '/' . $image_path;

// Security check - only allow images from ServiceImages directory
if (strpos($image_path, 'ServiceImages/') !== 0) {
    http_response_code(403);
    echo json_encode(['error' => 'Access denied']);
    exit;
}

// Check if file exists
if (!file_exists($full_path)) {
    http_response_code(404);
    echo json_encode(['error' => 'Image not found']);
    exit;
}

// Get file extension
$extension = strtolower(pathinfo($full_path, PATHINFO_EXTENSION));

// Set proper content type
switch ($extension) {
    case 'jpg':
    case 'jpeg':
        header('Content-Type: image/jpeg');
        break;
    case 'png':
        header('Content-Type: image/png');
        break;
    case 'gif':
        header('Content-Type: image/gif');
        break;
    case 'webp':
        header('Content-Type: image/webp');
        break;
    default:
        http_response_code(400);
        echo json_encode(['error' => 'Unsupported image type']);
        exit;
}

// Set CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept');
header('Cache-Control: public, max-age=31536000');

// Output the image
readfile($full_path);
?> 