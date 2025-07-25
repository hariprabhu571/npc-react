<?php
// change_password.php - Handle user password change requests


//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Prevent any output before JSON response
ob_start();

// Set error reporting to prevent HTML error output
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Session-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Clear any previous output
ob_clean();

require_once 'conn.php';

// Function to send JSON response and exit
function sendJsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit;
}

// Function to log errors
function logError($message) {
    error_log("Change Password Error: " . $message);
}

// Handle password change request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get Session-ID from headers
        $headers = getallheaders();
        $sessionId = null;
        
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'session-id') {
                    $sessionId = trim($value);
                    break;
                }
            }
        }

        if (!$sessionId) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Session ID is required. Please login again.'
            ], 401);
        }

        // Check database connection
        if (!$conn) {
            logError("Database connection failed");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database connection failed'
            ], 500);
        }

        // Get JSON input from the request body
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);

        if (!$data) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Invalid JSON data'
            ], 400);
        }

        // Validate input
        $oldPassword = isset($data['old_password']) ? trim($data['old_password']) : null;
        $newPassword = isset($data['new_password']) ? trim($data['new_password']) : null;

        if (empty($oldPassword) || empty($newPassword)) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Old password and new password are required'
            ], 400);
        }

        // Validate new password strength
        if (strlen($newPassword) < 6) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'New password must be at least 6 characters long'
            ], 400);
        }

        // Check if new password is different from old password
        if ($oldPassword === $newPassword) {
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'New password must be different from current password'
            ], 400);
        }

        // Verify user session and get user details
        $userQuery = "SELECT user_id, password, customer_name, mobile_number FROM users WHERE sessionid = ? AND session_expiry > NOW()";
        $userStmt = $conn->prepare($userQuery);
        
        if (!$userStmt) {
            logError("Failed to prepare user query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $user = $userResult->fetch_assoc();
        $userStmt->close();

        if (!$user) {
            logError("User not found or session expired for session ID: $sessionId");
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Session expired. Please login again.'
            ], 401);
        }

        // Verify old password
        if (!password_verify($oldPassword, $user['password'])) {
            logError("Incorrect old password for user ID: " . $user['user_id']);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Current password is incorrect'
            ], 400);
        }

        // Hash the new password
        $hashedNewPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        
        if (!$hashedNewPassword) {
            logError("Failed to hash new password for user ID: " . $user['user_id']);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Failed to process new password'
            ], 500);
        }

        // Start transaction
        $conn->begin_transaction();

        try {
            // Update the password in the database
            $updateQuery = "UPDATE users SET password = ? WHERE user_id = ?";
            $updateStmt = $conn->prepare($updateQuery);
            
            if (!$updateStmt) {
                throw new Exception("Failed to prepare update query: " . $conn->error);
            }
            
            $updateStmt->bind_param("si", $hashedNewPassword, $user['user_id']);
            $updateResult = $updateStmt->execute();
            $updateStmt->close();
            
            if (!$updateResult) {
                throw new Exception("Failed to update password");
            }

            // Log the password change (optional - for security audit)
            // Check if password_change_log table exists first
            $tableCheck = $conn->query("SHOW TABLES LIKE 'password_change_log'");
            if ($tableCheck && $tableCheck->num_rows > 0) {
                $logQuery = "
                    INSERT INTO password_change_log (user_id, user_type, changed_at, ip_address) 
                    VALUES (?, 'customer', NOW(), ?)
                ";
                $logStmt = $conn->prepare($logQuery);
                
                // Get user's IP address
                $userIP = $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
                
                if ($logStmt) {
                    $logStmt->bind_param("is", $user['user_id'], $userIP);
                    $logStmt->execute();
                    $logStmt->close();
                }
            }

            // Optional: Create notification for user (check if notifications table exists)
            $notificationTableCheck = $conn->query("SHOW TABLES LIKE 'notifications'");
            if ($notificationTableCheck && $notificationTableCheck->num_rows > 0) {
                $notificationQuery = "
                    INSERT INTO notifications (user_type, user_id, title, message, type, created_at) 
                    VALUES ('customer', ?, 'Password Changed', 'Your password has been successfully updated.', 'security', NOW())
                ";
                $notificationStmt = $conn->prepare($notificationQuery);
                
                if ($notificationStmt) {
                    $notificationStmt->bind_param("i", $user['user_id']);
                    $notificationStmt->execute();
                    $notificationStmt->close();
                }
            }

            // Commit transaction
            $conn->commit();
            
            // Log successful password change
            logError("Password successfully changed for user ID: " . $user['user_id'] . " (" . $user['customer_name'] . ")");
            
            // Return success response
            sendJsonResponse([
                'status' => 'success',
                'message' => 'Password changed successfully',
                'data' => [
                    'user_id' => $user['user_id'],
                    'customer_name' => $user['customer_name'],
                    'timestamp' => date('Y-m-d H:i:s')
                ]
            ], 200);
            
        } catch (Exception $e) {
            $conn->rollback();
            throw $e;
        }
        
    } catch (Exception $e) {
        if (isset($conn) && $conn->inTransaction) {
            $conn->rollback();
        }
        
        logError("Password change error: " . $e->getMessage());
        sendJsonResponse([
            'status' => 'error',
            'message' => 'An error occurred while changing password',
            'debug' => $e->getMessage() // Remove this in production
        ], 500);
    }
}

// Handle invalid request methods
sendJsonResponse([
    'status' => 'error',
    'message' => 'Invalid request method. Only POST is allowed.'
], 405);

// Close connection if it exists
if (isset($conn)) {
    $conn->close();
}
?>