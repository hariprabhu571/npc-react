<?php
// Include required files
include 'conn.php'; // Database connection
include 'functions.php'; // Include session validation function

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = $headers['Session-ID'] ?? '';

// Validate session ID from the users table itself
$stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ?");
$stmt->bind_param("s", $sessionId);
$stmt->execute();
$result = $stmt->get_result();
$userSession = $result->fetch_assoc();

if (!$userSession) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Fetch user details from the users table
$stmt = $conn->prepare("
    SELECT user_id, customer_name, mobile_number, address1, address2, profile_pic, 
           email_id, gender, country 
    FROM users 
    WHERE sessionid = ?
");
$stmt->bind_param("s", $sessionId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

// Check if user exists
if (!$user) {
    echo json_encode([
        "status" => "error",
        "message" => "User not found."
    ]);
    exit;
}

// Return user details
echo json_encode([
    "status" => "success",
    "user" => $user
]);

// Close connection
$stmt->close();
$conn->close();
?>
