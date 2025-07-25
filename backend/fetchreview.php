<?php
// Include database connection
include 'conn.php';


//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get session ID from request headers
$headers = getallheaders();
$sessionId = $headers['Session-ID'] ?? '';

// Check if session ID is provided
if (!empty($sessionId)) {
    // Fetch user_id from session (and check expiry)
    $stmt = $conn->prepare("
        SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()
    ");
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    $stmt->close();

    // If session is invalid or expired
    if (!$user) {
        echo json_encode([
            "status" => "error",
            "message" => "Unauthorized access. Invalid or expired session."
        ]);
        exit;
    }

    $user_id = $user['user_id'];

    // Fetch only this user's reviews
    $stmt = $conn->prepare("SELECT * FROM reviews WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
} else {
    // Fetch all reviews
    $stmt = $conn->prepare("SELECT * FROM reviews");
}

$stmt->execute();
$result = $stmt->get_result();
$reviews = $result->fetch_all(MYSQLI_ASSOC);
$stmt->close();
$conn->close();

// Return response
echo json_encode([
    "status" => "success",
    "reviews" => $reviews
]);
?>
