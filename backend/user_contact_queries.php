<?php
// user_contact_queries.php - Get user's contact queries

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Session-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
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

        // Check if contact_queries table exists
        $tableCheck = $conn->query("SHOW TABLES LIKE 'contact_queries'");
        if (!$tableCheck || $tableCheck->num_rows == 0) {
            echo json_encode([
                'status' => 'success',
                'message' => 'No queries found',
                'queries' => [],
                'total_count' => 0,
                'pending_count' => 0,
                'responded_count' => 0
            ]);
            exit;
        }

        // Get user's contact queries
        $queriesStmt = $conn->prepare("
            SELECT 
                id,
                first_name,
                last_name,
                email,
                phone,
                subject,
                message,
                status,
                admin_response,
                response_date,
                created_at,
                updated_at
            FROM contact_queries 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        ");
        
        $queriesStmt->bind_param("i", $user['user_id']);
        $queriesStmt->execute();
        $queriesResult = $queriesStmt->get_result();
        
        $queries = [];
        $pendingCount = 0;
        $respondedCount = 0;
        
        while ($row = $queriesResult->fetch_assoc()) {
            $queries[] = [
                'id' => $row['id'],
                'first_name' => $row['first_name'],
                'last_name' => $row['last_name'],
                'email' => $row['email'],
                'phone' => $row['phone'],
                'subject' => $row['subject'],
                'message' => $row['message'],
                'status' => $row['status'],
                'admin_response' => $row['admin_response'],
                'response_date' => $row['response_date'],
                'response_date_formatted' => $row['response_date'] ? date('M d, Y h:i A', strtotime($row['response_date'])) : null,
                'created_at' => $row['created_at'],
                'created_at_formatted' => date('M d, Y h:i A', strtotime($row['created_at'])),
                'updated_at' => $row['updated_at'],
                'has_response' => !empty($row['admin_response'])
            ];
            
            if ($row['status'] === 'pending') {
                $pendingCount++;
            } else {
                $respondedCount++;
            }
        }
        $queriesStmt->close();

        echo json_encode([
            'status' => 'success',
            'message' => 'Queries retrieved successfully',
            'queries' => $queries,
            'total_count' => count($queries),
            'pending_count' => $pendingCount,
            'responded_count' => $respondedCount,
            'user' => [
                'user_id' => $user['user_id'],
                'customer_name' => $user['customer_name']
            ]
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'An error occurred: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Only GET method allowed']);
}

$conn->close();
?>