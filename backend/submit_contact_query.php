<?php
// submit_contact_query.php - Handle contact form submissions

// Disable error display to prevent breaking JSON response
ini_set('display_errors', 0);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Session-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

function getAdminFcmTokens() {
    global $conn;
    
    try {
        // Query to get all FCM tokens from admin_login table where fcm_token is not null
        // Your table has: id, email, password, sessionid, session_expiry, fcm_token
        $sql = "SELECT id, email, fcm_token FROM admin_login WHERE fcm_token IS NOT NULL AND fcm_token != ''";
        $result = $conn->query($sql);
        
        $fcmTokens = array();
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $fcmTokens[] = array(
                    'admin_id' => $row['id'],
                    'admin_email' => $row['email'],  // Changed from admin_name to admin_email
                    'fcm_token' => $row['fcm_token']
                );
            }
        } else {
            // If no FCM tokens found, let's add one to the first admin for testing
            error_log("No FCM tokens found. Attempting to add test token to first admin...");
            
            $firstAdminQuery = "SELECT id, email FROM admin_login LIMIT 1";
            $firstAdminResult = $conn->query($firstAdminQuery);
            
            if ($firstAdminResult && $firstAdminResult->num_rows > 0) {
                $firstAdmin = $firstAdminResult->fetch_assoc();
                $testToken = 'fYCIzg9vSUWisfeeDD9VS6:APA91bE1vWgcSVJNvetbozgkOlLj3Edt78xpKryY1-pw7XMgJdN9ZKDwN31E4KCLuO_L_sSMNw_apNC49EJ6qBMPasy9UIYeNCDoCBEI8u8Udu6HtVhn-6Q';
                
                $updateQuery = "UPDATE admin_login SET fcm_token = ? WHERE id = ?";
                $stmt = $conn->prepare($updateQuery);
                $stmt->bind_param("si", $testToken, $firstAdmin['id']);
                
                if ($stmt->execute()) {
                    error_log("Test FCM token added to admin ID: " . $firstAdmin['id']);
                    
                    // Return the newly added token
                    $fcmTokens[] = array(
                        'admin_id' => $firstAdmin['id'],
                        'admin_email' => $firstAdmin['email'],
                        'fcm_token' => $testToken
                    );
                } else {
                    error_log("Failed to add test FCM token: " . $stmt->error);
                }
            }
        }
        
        return $fcmTokens;
        
    } catch (Exception $e) {
        error_log("Error getting admin FCM tokens: " . $e->getMessage());
        return array();
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get Session-ID from headers
        $headers = getallheaders();
        $sessionId = null;
        
        foreach ($headers as $name => $value) {
            if (strtolower($name) === 'session-id') {
                $sessionId = trim($value);
                break;
            }
        }

        if (!$sessionId) {
            echo json_encode(['status' => 'error', 'message' => 'Session ID is required']);
            exit;
        }

        // Verify user session
        $userStmt = $conn->prepare("SELECT user_id, customer_name FROM users WHERE sessionid = ? AND session_expiry > NOW()");
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $user = $userResult->fetch_assoc();
        $userStmt->close();

        if (!$user) {
            echo json_encode(['status' => 'error', 'message' => 'Session expired. Please login again.']);
            exit;
        }

        // Get POST data
        $input = json_decode(file_get_contents('php://input'), true);
        
        $firstName = trim($input['first_name'] ?? '');
        $lastName = trim($input['last_name'] ?? '');
        $email = trim($input['email'] ?? '');
        $phone = trim($input['phone'] ?? '');
        $subject = trim($input['subject'] ?? '');
        $message = trim($input['message'] ?? '');

        // Validate input
        if (empty($firstName) || empty($lastName) || empty($email) || empty($phone) || empty($subject) || empty($message)) {
            echo json_encode(['status' => 'error', 'message' => 'All fields are required']);
            exit;
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            echo json_encode(['status' => 'error', 'message' => 'Please enter a valid email address']);
            exit;
        }

        // Create contact_queries table if it doesn't exist
        $createTableQuery = "
            CREATE TABLE IF NOT EXISTS contact_queries (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                first_name VARCHAR(100) NOT NULL,
                last_name VARCHAR(100) NOT NULL,
                email VARCHAR(255) NOT NULL,
                phone VARCHAR(20) NOT NULL,
                subject VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                status ENUM('pending', 'responded', 'closed') DEFAULT 'pending',
                admin_response TEXT NULL,
                response_date TIMESTAMP NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_user_id (user_id),
                INDEX idx_status (status),
                INDEX idx_created_at (created_at)
            )
        ";
        $conn->query($createTableQuery);

        // Insert contact query
        $insertStmt = $conn->prepare("
            INSERT INTO contact_queries 
            (user_id, first_name, last_name, email, phone, subject, message) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        $insertStmt->bind_param("issssss", 
            $user['user_id'], 
            $firstName, 
            $lastName, 
            $email, 
            $phone, 
            $subject, 
            $message
        );
        
        if ($insertStmt->execute()) {
            $queryId = $conn->insert_id;
            
            // Get admin FCM tokens after successful submission
            $adminFcmTokens = getAdminFcmTokens();
            
            // Print FCM tokens to console/log for debugging
            if (!empty($adminFcmTokens)) {
                error_log("=== NEW CONTACT QUERY SUBMITTED ===");
                error_log("Query ID: " . $queryId);
                error_log("Subject: " . $subject);
                error_log("User: " . $firstName . ' ' . $lastName);
                error_log("Email: " . $email);
                error_log("Phone: " . $phone);
                error_log("Customer Name: " . $user['customer_name']);
                error_log("Admin FCM Tokens Retrieved:");
                
                foreach ($adminFcmTokens as $index => $admin) {
                    error_log("Admin " . ($index + 1) . ":");
                    error_log("  - ID: " . $admin['admin_id']);
                    error_log("  - Email: " . $admin['admin_email']);  // Fixed: now matches the array key
                    error_log("  - FCM Token: " . $admin['fcm_token']);
                }
                error_log("Total Admin Tokens: " . count($adminFcmTokens));
                error_log("===================================");
            } else {
                error_log("No admin FCM tokens found for new contact query (ID: $queryId)");
            }
            
            echo json_encode([
                'status' => 'success',
                'message' => 'Your message has been submitted successfully. We will get back to you soon!',
                'data' => [
                    'query_id' => $queryId,
                    'customer_name' => $user['customer_name'],
                    'subject' => $subject,
                    'submitted_at' => date('Y-m-d H:i:s')
                ],
                'admin_fcm_tokens' => $adminFcmTokens,
                'admin_token_count' => count($adminFcmTokens)
            ]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to submit your message. Please try again.']);
        }
        
        $insertStmt->close();
        
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'An error occurred: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
}

$conn->close();
?>