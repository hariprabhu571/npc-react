<?php
include 'conn.php';

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

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // Check database connection
    if (!isset($conn) || $conn->connect_error) {
        error_log("Database connection failed: " . ($conn->connect_error ?? 'Connection not initialized'));
        echo json_encode(["status" => "error", "message" => "Database connection failed"]);
        exit();
    }

    // Function to validate session ID
    function validateSession($conn, $sessionId) {
        if (empty($sessionId)) {
            return false;
        }
        
        $sql = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
            error_log("Session validation prepare failed: " . $conn->error);
            return false;
        }
        
        $stmt->bind_param("s", $sessionId);
        $stmt->execute();
        $result = $stmt->get_result();
        $isValid = $result->num_rows > 0;
        $stmt->close();
        
        return $isValid;
    }

    // Get session ID from headers
    $sessionId = '';
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
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

    error_log("Session ID received: " . ($sessionId ? $sessionId : 'EMPTY'));

    // Validate session
    if (empty($sessionId) || !validateSession($conn, $sessionId)) {
        error_log("Session validation failed");
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Unauthorized access. Invalid or expired session."]);
        exit();
    }

    // Get the raw POST data
    $data = file_get_contents("php://input");
    
    // Debug: Log the raw input
    error_log("Raw input: " . $data);
    
    if (empty($data)) {
        echo json_encode(["status" => "error", "message" => "No input data received"]);
        exit();
    }
    
    $request = json_decode($data, true);
    
    // Debug: Log the decoded request
    error_log("Decoded request: " . print_r($request, true));
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(["status" => "error", "message" => "Invalid JSON: " . json_last_error_msg()]);
        exit();
    }
    
    // Check if all required fields are provided
    $required_fields = ['employee_name', 'phone_number', 'service_type', 'address', 'id_proof', 'email', 'password'];
    $missing_fields = [];
    
    foreach ($required_fields as $field) {
        if (!isset($request[$field]) || empty(trim($request[$field]))) {
            $missing_fields[] = $field;
        }
    }
    
    if (!empty($missing_fields)) {
        echo json_encode([
            "status" => "error", 
            "message" => "Missing or empty fields: " . implode(', ', $missing_fields)
        ]);
        exit();
    }
    
    // Extract and sanitize data
    $employee_name = trim($request['employee_name']);
    $phone_number = trim($request['phone_number']);
    $service_type = trim($request['service_type']);
    $address = trim($request['address']);
    $id_proof_base64 = $request['id_proof'];
    $email = trim($request['email']);
    $password = password_hash(trim($request['password']), PASSWORD_DEFAULT);
    
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(["status" => "error", "message" => "Invalid email format"]);
        exit();
    }
    
    // Validate base64 image data
    if (!preg_match('/^[a-zA-Z0-9\/\+]*={0,2}$/', $id_proof_base64)) {
        echo json_encode(["status" => "error", "message" => "Invalid ID proof data"]);
        exit();
    }
    
    // Create directory for ID proofs
    $id_proof_folder = 'tech_idproof/';
    if (!file_exists($id_proof_folder)) {
        if (!mkdir($id_proof_folder, 0755, true)) {
            echo json_encode(["status" => "error", "message" => "Failed to create upload directory"]);
            exit();
        }
    }
    
    // Generate unique filename with proper extension
    $file_extension = '.png'; // You might want to detect actual file type
    $file_name = uniqid('tech_', true) . $file_extension;
    $file_path = $id_proof_folder . $file_name;
    
    // Decode and save the ID proof image
    $image_data = base64_decode($id_proof_base64);
    if ($image_data === false) {
        echo json_encode(["status" => "error", "message" => "Failed to decode ID proof image"]);
        exit();
    }
    
    if (!file_put_contents($file_path, $image_data)) {
        echo json_encode(["status" => "error", "message" => "Failed to save ID proof file"]);
        exit();
    }

    // Check both possible table names (case sensitivity issue)
    $table_name = 'technicians'; // default lowercase
    
    // Check if table exists (try both cases)
    $table_check = $conn->query("SHOW TABLES LIKE 'technicians'");
    if ($table_check->num_rows === 0) {
        $table_check = $conn->query("SHOW TABLES LIKE 'Technicians'");
        if ($table_check->num_rows > 0) {
            $table_name = 'Technicians'; // use uppercase if that's what exists
        } else {
            echo json_encode(["status" => "error", "message" => "Technicians table does not exist"]);
            exit();
        }
    }

    error_log("Using table name: " . $table_name);
    
    // Check if email already exists (using dynamic table name)
    $check_sql = "SELECT technician_id FROM $table_name WHERE email = ?";
    $check_stmt = $conn->prepare($check_sql);
    if (!$check_stmt) {
        echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
        exit();
    }
    
    $check_stmt->bind_param("s", $email);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Delete the uploaded file since we're not using it
        unlink($file_path);
        echo json_encode(["status" => "error", "message" => "Email already exists"]);
        exit();
    }
    $check_stmt->close();
    
    // Insert into the database (using dynamic table name)
    $sql = "INSERT INTO $table_name (employee_name, phone_number, service_type, address, id_proof, email, password) 
            VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        // Delete the uploaded file on error
        unlink($file_path);
        echo json_encode(["status" => "error", "message" => "Database prepare error: " . $conn->error]);
        exit();
    }
    
    $stmt->bind_param("sssssss", $employee_name, $phone_number, $service_type, $address, $file_path, $email, $password);
    
    if ($stmt->execute()) {
        $technician_id = $conn->insert_id;
        error_log("Technician added successfully with ID: " . $technician_id);
        echo json_encode([
            "status" => "success", 
            "message" => "Technician added successfully",
            "technician_id" => $technician_id
        ]);
    } else {
        // Delete the uploaded file on database error
        unlink($file_path);
        error_log("Failed to insert technician: " . $stmt->error);
        echo json_encode(["status" => "error", "message" => "Failed to add technician: " . $stmt->error]);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    // Clean up file if it was created
    if (isset($file_path) && file_exists($file_path)) {
        unlink($file_path);
    }
    
    error_log("Exception in add_technician.php: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "Server error occurred: " . $e->getMessage()]);
    
} finally {
    if (isset($conn) && $conn) {
        $conn->close();
    }
}
?>