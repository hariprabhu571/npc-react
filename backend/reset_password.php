<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers first
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Session-ID');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Include database connection
    include 'conn.php';
    
    // Check if connection is successful
    if (!isset($conn) || $conn->connect_error) {
        throw new Exception("Database connection failed: " . ($conn->connect_error ?? 'Unknown error'));
    }

    // Function to validate session ID
    function validateSession($conn, $sessionId) {
        if (empty($sessionId)) {
            return false;
        }
        
        // Query to check if the session ID is valid and has not expired
        $sql = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            error_log("Failed to prepare session validation statement: " . $conn->error);
            return false;
        }
        
        $stmt->bind_param("s", $sessionId);
        $stmt->execute();
        $result = $stmt->get_result();
        $isValid = $result->num_rows > 0;
        $stmt->close();
        
        return $isValid;
    }

    // Get the session ID from the request headers
    $sessionId = '';
    
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        error_log("All headers: " . print_r($headers, true));
        
        // Try different header case variations as header names can be case-insensitive
        foreach ($headers as $name => $value) {
            if (strtolower($name) === 'session-id') {
                $sessionId = trim($value);
                break;
            }
        }
    } else {
        // Fallback for servers that don't support getallheaders()
        foreach ($_SERVER as $name => $value) {
            if (strtolower($name) === 'http_session_id') {
                $sessionId = trim($value);
                break;
            }
        }
    }

    // For debugging
    error_log("Retrieved session ID: " . ($sessionId ? $sessionId : 'EMPTY'));

    // Validate session ID
    if (empty($sessionId) || !validateSession($conn, $sessionId)) {
        error_log("Session validation failed for ID: " . $sessionId);
        http_response_code(401);
        echo json_encode([
            "status" => "error",
            "message" => "Unauthorized access. Invalid or expired session."
        ]);
        exit();
    }

    // Check if it's a POST request
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Only POST method is allowed");
    }

    // Get the raw POST data
    $json = file_get_contents('php://input');
    error_log("Raw input data: " . $json);

    if (empty($json)) {
        throw new Exception("No input data received");
    }

    // Decode the JSON data to an associative array
    $data = json_decode($json, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON format: " . json_last_error_msg());
    }

    error_log("Decoded data: " . print_r($data, true));

    // Check if the necessary parameters are provided
    if (!isset($data['technician_id']) || !isset($data['newpassword'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Technician ID and new password are required."
        ]);
        exit();
    }

    $technician_id = trim($data['technician_id']);
    $newPassword = trim($data['newpassword']);

    // Validate input
    if (empty($technician_id)) {
        echo json_encode([
            "status" => "error",
            "message" => "Technician ID cannot be empty."
        ]);
        exit();
    }

    if (empty($newPassword)) {
        echo json_encode([
            "status" => "error",
            "message" => "New password cannot be empty."
        ]);
        exit();
    }

    if (strlen($newPassword) < 6) {
        echo json_encode([
            "status" => "error",
            "message" => "Password must be at least 6 characters long."
        ]);
        exit();
    }

    // Hash the new password before saving it
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

    // Check which table name exists (case sensitivity issue)
    $tableName = 'Technicians'; // default
    $tableCheck = $conn->query("SHOW TABLES LIKE 'Technicians'");
    if ($tableCheck->num_rows === 0) {
        $tableCheck = $conn->query("SHOW TABLES LIKE 'technicians'");
        if ($tableCheck->num_rows > 0) {
            $tableName = 'technicians';
        } else {
            throw new Exception("Technicians table not found");
        }
    }

    error_log("Using table name: " . $tableName);

    // Validate that the technician_id exists in the database
    $stmt_check = $conn->prepare("SELECT technician_id, employee_name FROM $tableName WHERE technician_id = ?");
    if (!$stmt_check) {
        throw new Exception("Failed to prepare check statement: " . $conn->error);
    }

    $stmt_check->bind_param("s", $technician_id);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();

    if ($result_check->num_rows > 0) {
        $technician = $result_check->fetch_assoc();
        $stmt_check->close();
        
        error_log("Found technician: " . $technician['employee_name'] . " (ID: " . $technician_id . ")");

        // If technician_id exists, update the password
        $stmt_update = $conn->prepare("UPDATE $tableName SET password = ? WHERE technician_id = ?");
        if (!$stmt_update) {
            throw new Exception("Failed to prepare update statement: " . $conn->error);
        }

        $stmt_update->bind_param("ss", $hashedPassword, $technician_id);
        
        if ($stmt_update->execute()) {
            $stmt_update->close();
            error_log("Password updated successfully for technician ID: " . $technician_id);
            
            echo json_encode([
                "status" => "success",
                "message" => "Password reset successfully for " . $technician['employee_name'] . "."
            ]);
        } else {
            $stmt_update->close();
            throw new Exception("Failed to update password: " . $stmt_update->error);
        }
    } else {
        $stmt_check->close();
        error_log("Technician ID not found: " . $technician_id);
        
        // If technician_id doesn't exist, return an error
        echo json_encode([
            "status" => "error",
            "message" => "Technician ID not found."
        ]);
    }

} catch (Exception $e) {
    error_log("Reset password error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Server error: " . $e->getMessage()
    ]);
} finally {
    // Close the connection
    if (isset($conn) && $conn) {
        $conn->close();
    }
}
?>