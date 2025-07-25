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

// Validate session ID
if (empty($sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Session ID is required."
    ]);
    exit;
}

// Fetch user details and validate session in a single query
$stmt = $conn->prepare("
    SELECT user_id, customer_name, session_expiry 
    FROM users
    WHERE sessionid = ? AND session_expiry > NOW()
");
$stmt->bind_param("s", $sessionId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

// If user not found or session expired
if (!$user) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Extract user details
$user_id = $user['user_id'];
$username = $user['customer_name'];

// Get input parameters
$input = json_decode(file_get_contents('php://input'), true);
$ratings = $input['ratings'] ?? null;
$review_description = $input['review_description'] ?? null;

// Validate input
if (empty($ratings) || empty($review_description)) {
    echo json_encode([
        "status" => "error",
        "message" => "Ratings and review description are required."
    ]);
    exit;
}

// Validate ratings (must be between 1.0 and 5.0)
if ($ratings < 1.0 || $ratings > 5.0) {
    echo json_encode([
        "status" => "error",
        "message" => "Ratings must be between 1.0 and 5.0."
    ]);
    exit;
}

// Insert review into the database
$stmt = $conn->prepare("
    INSERT INTO reviews (user_id, username, ratings, review_description) 
    VALUES (?, ?, ?, ?)
");
$stmt->bind_param("isds", $user_id, $username, $ratings, $review_description);

if ($stmt->execute()) {
    echo json_encode([
        "status" => "success",
        "message" => "Review submitted successfully."
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to submit review."
    ]);
}

// Close connection
$stmt->close();
$conn->close();
?>
