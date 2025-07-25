<?php
// mark_notification_read.php - Mark notification as read

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
        $userStmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()");
        $userStmt->bind_param("s", $sessionId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $user = $userResult->fetch_assoc();
        $userStmt->close();

        if (!$user) {
            echo json_encode(['status' => 'error', 'message' => 'Session expired']);
            exit;
        }

        // Get POST data
        $input = json_decode(file_get_contents('php://input'), true);
        $notificationId = $input['notification_id'] ?? null;

        if (!$notificationId) {
            echo json_encode(['status' => 'error', 'message' => 'Notification ID is required']);
            exit;
        }

        // Check if user_notifications table exists, if not create it
        $tableCheck = $conn->query("SHOW TABLES LIKE 'user_notifications'");
        if (!$tableCheck || $tableCheck->num_rows == 0) {
            $createTable = "
                CREATE TABLE user_notifications (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    status_log_id INT NOT NULL,
                    is_read BOOLEAN DEFAULT FALSE,
                    read_at TIMESTAMP NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE KEY unique_user_notification (user_id, status_log_id),
                    INDEX idx_user_id (user_id),
                    INDEX idx_status_log_id (status_log_id)
                )
            ";
            $conn->query($createTable);
        }

        // Insert or update notification read status
        $updateStmt = $conn->prepare("
            INSERT INTO user_notifications (user_id, status_log_id, is_read, read_at) 
            VALUES (?, ?, 1, NOW()) 
            ON DUPLICATE KEY UPDATE is_read = 1, read_at = NOW()
        ");
        $updateStmt->bind_param("ii", $user['user_id'], $notificationId);
        
        if ($updateStmt->execute()) {
            echo json_encode([
                'status' => 'success',
                'message' => 'Notification marked as read'
            ]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to update notification']);
        }
        
        $updateStmt->close();
        
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'An error occurred: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
}

$conn->close();
?>