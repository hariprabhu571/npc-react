<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set content type to JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Function to send JSON response with detailed error info
function sendResponse($status, $message, $data = null, $debug = null) {
    $response = ['status' => $status, 'message' => $message];
    if ($data) {
        $response = array_merge($response, $data);
    }
    if ($debug) {
        $response['debug'] = $debug;
    }
    echo json_encode($response);
    exit();
}

// Handle signup request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Step 1: Check if required files exist
        if (!file_exists('conn.php')) {
            sendResponse('error', 'Database connection file not found', null, 'conn.php missing');
        }
        
        // Include database connection
        require 'conn.php';
        
        // Step 2: Check database connection
        if (!isset($conn)) {
            sendResponse('error', 'Database connection not established', null, 'conn variable not set');
        }
        
        if ($conn->connect_error) {
            sendResponse('error', 'Database connection failed', null, 'MySQL Error: ' . $conn->connect_error);
        }
        
        // Step 3: Get and validate JSON input
        $inputRaw = file_get_contents('php://input');
        
        if (empty($inputRaw)) {
            sendResponse('error', 'No input data received', null, 'Raw input is empty');
        }
        
        $input = json_decode($inputRaw, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            sendResponse('error', 'Invalid JSON format', null, 'JSON Error: ' . json_last_error_msg());
        }
        
        // Step 4: Validate required fields
        if (!isset($input['customer_name']) || empty(trim($input['customer_name']))) {
            sendResponse('error', 'Full name is required', null, 'customer_name field missing or empty');
        }
        
        if (!isset($input['mobile_number']) || empty(trim($input['mobile_number']))) {
            sendResponse('error', 'Mobile number is required', null, 'mobile_number field missing or empty');
        }
        
        if (!isset($input['password']) || empty($input['password'])) {
            sendResponse('error', 'Password is required', null, 'password field missing or empty');
        }
        
        $customer_name = trim($input['customer_name']);
        $mobile_number = trim($input['mobile_number']);
        $password = $input['password'];
        
        // Step 5: Additional validation
        if (strlen($customer_name) < 2) {
            sendResponse('error', 'Name must be at least 2 characters long');
        }
        
        if (strlen($mobile_number) < 10) {
            sendResponse('error', 'Mobile number must be at least 10 digits');
        }
        
        if (!preg_match('/^[0-9]+$/', $mobile_number)) {
            sendResponse('error', 'Mobile number must contain only digits');
        }
        
        if (strlen($password) < 6) {
            sendResponse('error', 'Password must be at least 6 characters long');
        }
        
        // Step 6: Check if users table exists
        $tableCheck = $conn->query("SHOW TABLES LIKE 'users'");
        if ($tableCheck->num_rows == 0) {
            sendResponse('error', 'Users table does not exist', null, 'Table users not found in database');
        }
        
        // Step 7: Check table structure and get column info
        $columnCheck = $conn->query("DESCRIBE users");
        $columns = [];
        $columnDetails = [];
        while ($row = $columnCheck->fetch_assoc()) {
            $columns[] = $row['Field'];
            $columnDetails[$row['Field']] = $row;
        }
        
        $requiredColumns = ['customer_name', 'mobile_number', 'password'];
        $missingColumns = array_diff($requiredColumns, $columns);
        
        if (!empty($missingColumns)) {
            sendResponse('error', 'Database table missing required columns', null, 'Missing columns: ' . implode(', ', $missingColumns));
        }
        
        // Step 8: Check if mobile number already exists
        $checkStmt = $conn->prepare("SELECT user_id FROM users WHERE mobile_number = ?");
        if (!$checkStmt) {
            sendResponse('error', 'Database prepare error', null, 'Prepare failed: ' . $conn->error);
        }
        
        $checkStmt->bind_param("s", $mobile_number);
        if (!$checkStmt->execute()) {
            sendResponse('error', 'Database execution error', null, 'Execute failed: ' . $checkStmt->error);
        }
        
        $result = $checkStmt->get_result();
        if ($result->num_rows > 0) {
            $checkStmt->close();
            sendResponse('error', 'Mobile number already registered');
        }
        $checkStmt->close();
        
        // Step 9: Hash the password
        $hashed_password = password_hash($password, PASSWORD_DEFAULT);
        if (!$hashed_password) {
            sendResponse('error', 'Password hashing failed', null, 'password_hash() returned false');
        }
        
        // Step 10: Prepare INSERT query based on available columns
        $insertColumns = ['customer_name', 'mobile_number', 'password'];
        $insertValues = [$customer_name, $mobile_number, $hashed_password];
        $paramTypes = 'sss';
        
        // Handle email_id column if it exists
        if (in_array('email_id', $columns)) {
            // Check if email_id column allows NULL
            if ($columnDetails['email_id']['Null'] == 'YES') {
                // Column allows NULL, so we can insert NULL
                $insertColumns[] = 'email_id';
                $insertValues[] = null;
                $paramTypes .= 's';
            } else {
                // Column doesn't allow NULL, generate a unique placeholder email
                $uniqueEmail = 'user_' . time() . '_' . rand(1000, 9999) . '@placeholder.com';
                $insertColumns[] = 'email_id';
                $insertValues[] = $uniqueEmail;
                $paramTypes .= 's';
            }
        }
        
        // Build the INSERT query
        $columnsStr = implode(', ', $insertColumns);
        $placeholders = str_repeat('?,', count($insertColumns) - 1) . '?';
        $insertQuery = "INSERT INTO users ($columnsStr) VALUES ($placeholders)";
        
        $stmt = $conn->prepare($insertQuery);
        if (!$stmt) {
            sendResponse('error', 'Database prepare error for insert', null, 'Insert prepare failed: ' . $conn->error);
        }
        
        // Bind parameters dynamically
        $stmt->bind_param($paramTypes, ...$insertValues);
        
        if ($stmt->execute()) {
            $user_id = $stmt->insert_id;
            $stmt->close();
            
            // Step 11: Handle session (optional)
            $sessionId = null;
            $sessionExpiry = null;
            
            if (file_exists('functions.php')) {
                require_once 'functions.php';
                
                if (function_exists('generateSessionId') && function_exists('getSessionExpiry')) {
                    $sessionId = generateSessionId();
                    $sessionExpiry = getSessionExpiry();
                    
                    // Check if session columns exist
                    if (in_array('sessionid', $columns) && in_array('session_expiry', $columns)) {
                        $updateStmt = $conn->prepare("UPDATE users SET sessionid = ?, session_expiry = ? WHERE user_id = ?");
                        if ($updateStmt) {
                            $updateStmt->bind_param("ssi", $sessionId, $sessionExpiry, $user_id);
                            $updateStmt->execute();
                            $updateStmt->close();
                        }
                    }
                }
            }
            
            // Success response
            $responseData = [
                'user_id' => $user_id,
                'customer_name' => $customer_name
            ];
            
            if ($sessionId && $sessionExpiry) {
                $responseData['sessionid'] = $sessionId;
                $responseData['session_expiry'] = $sessionExpiry;
            }
            
            sendResponse('success', 'Account created successfully', $responseData);
            
        } else {
            $stmt->close();
            sendResponse('error', 'Failed to create account', null, 'Insert execution failed: ' . $stmt->error);
        }
        
    } catch (mysqli_sql_exception $e) {
        sendResponse('error', 'Database error occurred', null, 'MySQL Exception: ' . $e->getMessage());
    } catch (Exception $e) {
        sendResponse('error', 'An unexpected error occurred', null, 'PHP Exception: ' . $e->getMessage() . ' in ' . $e->getFile() . ' line ' . $e->getLine());
    }
    
} else {
    sendResponse('error', 'Only POST method is allowed', null, 'Received method: ' . $_SERVER['REQUEST_METHOD']);
}

// Close connection
if (isset($conn)) {
    $conn->close();
}
?>