<?php
// user_notifications.php - Get user notifications based on technician status updates

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
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Session-ID");
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
    error_log("User Notifications Error: " . $message);
}

// GET - Fetch user notifications
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
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
                'message' => 'Session ID is required'
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

        // Verify user session and get user details
        $userQuery = "SELECT user_id, customer_name FROM users WHERE sessionid = ? AND session_expiry > NOW()";
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

        $userId = $user['user_id'];

        // Get notifications from technician_status_log for this user's bookings
        $notificationsQuery = "
            SELECT 
                tsl.log_id as id,
                tsl.booking_id,
                tsl.status,
                tsl.timestamp,
                tsl.notes,
                COALESCE(t.employee_name, 'Technician') as technician_name,
                b.service_name,
                b.service_address,
                0 as is_read,
                CASE 
                    WHEN tsl.status = 'assigned' THEN CONCAT('Your order #', tsl.booking_id, ' has been assigned to a technician')
                    WHEN tsl.status = 'reached' THEN CONCAT('Technician has arrived at your location for order #', tsl.booking_id)
                    WHEN tsl.status = 'started' THEN CONCAT('Your service for order #', tsl.booking_id, ' has been started')
                    WHEN tsl.status = 'completed' THEN CONCAT('Great news! Your service for order #', tsl.booking_id, ' has been completed successfully')
                    ELSE CONCAT('Status update for order #', tsl.booking_id)
                END as message
            FROM technician_status_log tsl
            LEFT JOIN bookings b ON tsl.booking_id = b.booking_id
            LEFT JOIN technicians t ON tsl.technician_id = t.technician_id
            WHERE b.user_id = ?
            ORDER BY tsl.timestamp DESC
            LIMIT 50
        ";
        
        $notificationsStmt = $conn->prepare($notificationsQuery);
        
        if (!$notificationsStmt) {
            logError("Failed to prepare notifications query: " . $conn->error);
            sendJsonResponse([
                'status' => 'error', 
                'message' => 'Database query preparation failed'
            ], 500);
        }
        
        $notificationsStmt->bind_param("i", $userId);
        $notificationsStmt->execute();
        $notificationsResult = $notificationsStmt->get_result();
        
        $notifications = [];
        while ($row = $notificationsResult->fetch_assoc()) {
            $notifications[] = [
                'id' => $row['id'],
                'booking_id' => $row['booking_id'],
                'status' => $row['status'],
                'message' => $row['message'],
                'technician_name' => $row['technician_name'],
                'service_name' => $row['service_name'],
                'service_address' => $row['service_address'],
                'notes' => $row['notes'],
                'timestamp' => $row['timestamp'],
                'is_read' => (bool)$row['is_read'],
                'formatted_time' => date('M d, Y h:i A', strtotime($row['timestamp']))
            ];
        }
        $notificationsStmt->close();

        // Count unread notifications
        $unreadCount = array_reduce($notifications, function($count, $notification) {
            return $count + ($notification['is_read'] ? 0 : 1);
        }, 0);

        $response = [
            'status' => 'success',
            'message' => 'Notifications retrieved successfully',
            'notifications' => $notifications,
            'unread_count' => $unreadCount,
            'total_count' => count($notifications),
            'user' => [
                'user_id' => $user['user_id'],
                'customer_name' => $user['customer_name']
            ]
        ];
        
        sendJsonResponse($response, 200);
        
    } catch (Exception $e) {
        logError("Notifications fetch error: " . $e->getMessage());
        sendJsonResponse([
            'status' => 'error',
            'message' => 'An error occurred while fetching notifications',
            'debug' => $e->getMessage() // Remove this in production
        ], 500);
    }
}

// Invalid request method
sendJsonResponse([
    'status' => 'error',
    'message' => 'Invalid request method'
], 405);

// Close connection if it exists
if (isset($conn)) {
    $conn->close();
}
?>