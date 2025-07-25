<?php

// Function to validate session ID for authentication

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

function generateSessionId() {
    return bin2hex(random_bytes(32)); // Generates a 64-character random string
}

// Function to calculate session expiry (2 days from now)
function getSessionExpiry() {
    return date('Y-m-d H:i:s', strtotime('+2 days'));
}
function validateSession($conn, $sessionId) {
    // SQL query to check if the session ID exists and is not expired
    $sql = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    // Check if session is valid
    return $result->num_rows > 0;
}

function validateSessionUser($conn, $sessionId) {
    // SQL query to check if the session ID exists and is not expired
    $sql = "SELECT id FROM users WHERE sessionid = ? AND session_expiry > NOW()";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    // Check if session is valid
    return $result->num_rows > 0;
}

// Function to sanitize user input to prevent SQL injection
function sanitizeInput($conn, $input) {
    return mysqli_real_escape_string($conn, trim($input));
}

// Function to validate required fields
function validateRequiredFields($data, $requiredFields) {
    foreach ($requiredFields as $field) {
        if (empty($data[$field])) {
            return "Field '$field' is required.";
        }
    }
    return true;
}

// Function to validate email format
function validateEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

// Function to validate if a string is a number
function validateNumber($number) {
    return is_numeric($number);
}

// Function to check if a value exists in a database column
function valueExistsInDb($conn, $table, $column, $value) {
    $sql = "SELECT * FROM $table WHERE $column = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $value);
    $stmt->execute();
    $result = $stmt->get_result();
    
    return $result->num_rows > 0;
}

?>
