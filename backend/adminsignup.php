<?php
// Include the database connection file
require 'conn.php';

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle signup request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get JSON input from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (empty($input['email']) || empty($input['password'])) {
        echo json_encode(['status' => 'error', 'message' => 'Email and password are required.']);
        exit;
    }

    $email = $input['email'];
    $password = $input['password'];

    // Hash the password
    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

    // Prepare the SQL statement
    $stmt = $conn->prepare("INSERT INTO admin_login (email, password) VALUES (?, ?)");
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $conn->error]);
        exit;
    }

    // Bind parameters and execute the query
    $stmt->bind_param("ss", $email, $hashedPassword);
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Admin signed up successfully.']);
    } else {
        // Check if the error is due to duplicate email
        if ($stmt->errno === 1062) { // MySQL error code for duplicate entry
            echo json_encode(['status' => 'error', 'message' => 'Email already exists.']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $stmt->error]);
        }
    }

    // Close the statement
    $stmt->close();
}

// Close the database connection
$conn->close();
?>
