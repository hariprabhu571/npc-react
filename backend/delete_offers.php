<?php
include 'conn.php'; // Include the database connection
include 'functions.php'; // Include session validation function

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
error_log(print_r($headers, true));

// Try different header case variations as header names can be case-insensitive
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

// Check if offer_id is provided
if (!isset($_GET['offer_id']) || empty($_GET['offer_id'])) {
    echo json_encode([
        "status" => "error",
        "message" => "Offer ID is required."
    ]);
    exit;
}

$offerId = $_GET['offer_id'];

// Delete the offer
$query = "DELETE FROM offers WHERE offer_id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $offerId);
$result = $stmt->execute();

if ($result) {
    echo json_encode([
        "status" => "success",
        "message" => "Offer deleted successfully."
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to delete offer: " . $conn->error
    ]);
}

// Close the connection
$stmt->close();
$conn->close();
?>