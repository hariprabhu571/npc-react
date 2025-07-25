<?php
include 'conn.php';  // Include database connection

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Function to validate session ID
function validateSession($conn, $sessionId) {
    // Query to check if the session ID is valid and has not expired
    $sql = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $result = $stmt->get_result();

    return $result->num_rows > 0;
}

// Get the session ID from the request headers
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

// For debugging
error_log("Retrieved session ID: " . $sessionId);

// Validate session ID
if (empty($sessionId) || !validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Get the raw POST data
$json = file_get_contents('php://input');

// Decode the JSON data to an associative array
$data = json_decode($json, true);

// Check if the necessary parameters are provided
if (isset($data['technician_id']) && isset($data['newpassword'])) {
    $technician_id = $data['technician_id'];
    $newPassword = $data['newpassword'];

    // Hash the new password before saving it
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

    // Validate that the technician_id exists in the database
    $stmt_check = $conn->prepare("SELECT technician_id FROM Technicians WHERE technician_id = ?");
    $stmt_check->bind_param("s", $technician_id);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();

    if ($result_check->num_rows > 0) {
        // If technician_id exists, update the password
        $stmt_update = $conn->prepare("UPDATE Technicians SET password = ? WHERE technician_id = ?");
        $stmt_update->bind_param("ss", $hashedPassword, $technician_id);

        if ($stmt_update->execute()) {
            echo json_encode([
                "status" => "success",
                "message" => "Password reset successfully."
            ]);
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Failed to reset password. Please try again later."
            ]);
        }

        $stmt_update->close();
    } else {
        // If technician_id doesn't exist, return an error
        echo json_encode([
            "status" => "error",
            "message" => "Technician ID not found."
        ]);
    }

    $stmt_check->close();
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Technician ID and new password are required."
    ]);
}

// Close the connection
$conn->close();
?>
