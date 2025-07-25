<?php
// admin_contact_queries.php - Admin management for contact queries

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'conn.php';

// Function to verify admin session
function verifyAdminSession($conn, $sessionId) {
    if (empty($sessionId)) {
        return false;
    }
    
    // Query the correct table: admin_login with correct column names
    $stmt = $conn->prepare("SELECT id as admin_id, email as admin_name FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()");
    
    if ($stmt) {
        $stmt->bind_param("s", $sessionId);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $admin = $result->fetch_assoc();
            $stmt->close();
            if ($admin) {
                return $admin;
            }
        } else {
            $stmt->close();
        }
    }
    
    // If no result with expiry check, try without expiry check (in case session_expiry is NULL or has different format)
    $stmt = $conn->prepare("SELECT id as admin_id, email as admin_name FROM admin_login WHERE sessionid = ?");
    
    if ($stmt) {
        $stmt->bind_param("s", $sessionId);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $admin = $result->fetch_assoc();
            $stmt->close();
            return $admin;
        } else {
            $stmt->close();
        }
    }
    
    return false;
}

// GET - Fetch all contact queries for admin
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Get session ID from request headers (same pattern as fetch_all_offers.php)
        $headers = getallheaders();
        $sessionId = '';
        
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'session-id') {
                    $sessionId = trim($value);
                    break;
                }
            }
        }

        // For debugging - you can remove this line later
        error_log("DEBUG: Session ID received: " . $sessionId);

        if (empty($sessionId)) {
            echo json_encode(['status' => 'error', 'message' => 'Admin session ID is required']);
            exit;
        }

        // Verify admin session
        $admin = verifyAdminSession($conn, $sessionId);
        if (!$admin) {
            echo json_encode(['status' => 'error', 'message' => 'Invalid admin session or session expired']);
            exit;
        }

        // Get filter parameters
        $status = $_GET['status'] ?? 'all';
        $page = (int)($_GET['page'] ?? 1);
        $limit = (int)($_GET['limit'] ?? 20);
        $offset = ($page - 1) * $limit;

        // Build query based on status filter
        $whereClause = "";
        $params = [];
        $paramTypes = "";

        if ($status !== 'all') {
            $whereClause = "WHERE cq.status = ?";
            $params[] = $status;
            $paramTypes = "s";
        }

        // Get total count
        $countQuery = "SELECT COUNT(*) as total FROM contact_queries cq $whereClause";
        
        if (!empty($params)) {
            $countStmt = $conn->prepare($countQuery);
            if (!$countStmt) {
                throw new Exception("Failed to prepare count query: " . $conn->error);
            }
            $countStmt->bind_param($paramTypes, ...$params);
            $countStmt->execute();
            $totalResult = $countStmt->get_result();
            $totalCount = $totalResult->fetch_assoc()['total'];
            $countStmt->close();
        } else {
            $result = $conn->query($countQuery);
            if (!$result) {
                throw new Exception("Failed to execute count query: " . $conn->error);
            }
            $totalCount = $result->fetch_assoc()['total'];
        }

        // Get queries with user information
        $queriesQuery = "
            SELECT 
                cq.id,
                cq.user_id,
                cq.first_name,
                cq.last_name,
                cq.email,
                cq.phone,
                cq.subject,
                cq.message,
                cq.status,
                cq.admin_response,
                cq.response_date,
                cq.created_at,
                cq.updated_at,
                u.customer_name,
                u.mobile_number
            FROM contact_queries cq
            LEFT JOIN users u ON cq.user_id = u.user_id
            $whereClause
            ORDER BY cq.created_at DESC
            LIMIT ? OFFSET ?
        ";

        $params[] = $limit;
        $params[] = $offset;
        $paramTypes .= "ii";
        
        $queriesStmt = $conn->prepare($queriesQuery);
        if (!$queriesStmt) {
            throw new Exception("Failed to prepare queries query: " . $conn->error);
        }
        
        $queriesStmt->bind_param($paramTypes, ...$params);
        $queriesStmt->execute();
        $queriesResult = $queriesStmt->get_result();
        
        $queries = [];
        while ($row = $queriesResult->fetch_assoc()) {
            $queries[] = [
                'id' => $row['id'],
                'user_id' => $row['user_id'],
                'customer_name' => $row['customer_name'],
                'first_name' => $row['first_name'],
                'last_name' => $row['last_name'],
                'email' => $row['email'],
                'phone' => $row['phone'],
                'mobile_number' => $row['mobile_number'],
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
        }
        $queriesStmt->close();

        // Get status counts
        $statusCountsQuery = "
            SELECT 
                status,
                COUNT(*) as count
            FROM contact_queries
            GROUP BY status
        ";
        $statusResult = $conn->query($statusCountsQuery);
        $statusCounts = [
            'pending' => 0,
            'responded' => 0,
            'closed' => 0
        ];
        
        if ($statusResult && $statusResult->num_rows > 0) {
            while ($row = $statusResult->fetch_assoc()) {
                $statusCounts[$row['status']] = (int)$row['count'];
            }
        }

        echo json_encode([
            'status' => 'success',
            'message' => count($queries) > 0 ? 'Queries retrieved successfully' : 'No queries found',
            'queries' => $queries,
            'pagination' => [
                'current_page' => $page,
                'total_count' => $totalCount,
                'per_page' => $limit,
                'total_pages' => ceil($totalCount / $limit)
            ],
            'status_counts' => $statusCounts,
            'admin' => [
                'admin_id' => $admin['admin_id'],
                'admin_name' => $admin['admin_name']
            ]
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to fetch queries: ' . $e->getMessage(),
            'queries' => []
        ]);
    }
}

// POST - Respond to a query
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get session ID from request headers (same pattern as fetch_all_offers.php)
        $headers = getallheaders();
        $sessionId = '';
        
        if ($headers) {
            foreach ($headers as $name => $value) {
                if (strtolower($name) === 'session-id') {
                    $sessionId = trim($value);
                    break;
                }
            }
        }

        if (empty($sessionId)) {
            echo json_encode(['status' => 'error', 'message' => 'Admin session ID is required']);
            exit;
        }

        // Verify admin session
        $admin = verifyAdminSession($conn, $sessionId);
        if (!$admin) {
            echo json_encode(['status' => 'error', 'message' => 'Invalid admin session or session expired']);
            exit;
        }

        // Get POST data
        $input = json_decode(file_get_contents('php://input'), true);
        
        $queryId = (int)($input['query_id'] ?? 0);
        $response = trim($input['response'] ?? '');
        $newStatus = trim($input['status'] ?? 'responded');

        if (empty($queryId) || empty($response)) {
            echo json_encode(['status' => 'error', 'message' => 'Query ID and response are required']);
            exit;
        }

        // Update the query with admin response
        $updateStmt = $conn->prepare("
            UPDATE contact_queries 
            SET admin_response = ?, status = ?, response_date = NOW(), updated_at = NOW()
            WHERE id = ?
        ");
        
        if (!$updateStmt) {
            throw new Exception('Failed to prepare update statement: ' . $conn->error);
        }
        
        $updateStmt->bind_param("ssi", $response, $newStatus, $queryId);
        
        if ($updateStmt->execute()) {
            // Get updated query details
            $getQueryStmt = $conn->prepare("
                SELECT cq.*, u.customer_name, u.email_id as user_email
                FROM contact_queries cq
                LEFT JOIN users u ON cq.user_id = u.user_id
                WHERE cq.id = ?
            ");
            
            if ($getQueryStmt) {
                $getQueryStmt->bind_param("i", $queryId);
                $getQueryStmt->execute();
                $queryResult = $getQueryStmt->get_result();
                $queryData = $queryResult->fetch_assoc();
                $getQueryStmt->close();

                echo json_encode([
                    'status' => 'success',
                    'message' => 'Response submitted successfully',
                    'data' => [
                        'query_id' => $queryId,
                        'admin_name' => $admin['admin_name'],
                        'response' => $response,
                        'new_status' => $newStatus,
                        'customer_name' => $queryData['customer_name'] ?? '',
                        'customer_email' => $queryData['user_email'] ?? $queryData['email'] ?? '',
                        'response_date' => date('Y-m-d H:i:s'),
                        'response_date_formatted' => date('M d, Y h:i A')
                    ]
                ]);
            } else {
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Response submitted successfully',
                    'data' => [
                        'query_id' => $queryId,
                        'admin_name' => $admin['admin_name'],
                        'response' => $response,
                        'new_status' => $newStatus,
                        'response_date' => date('Y-m-d H:i:s'),
                        'response_date_formatted' => date('M d, Y h:i A')
                    ]
                ]);
            }
        } else {
            throw new Exception('Failed to submit response: ' . $updateStmt->error);
        }
        
        $updateStmt->close();
        
    } catch (Exception $e) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to process request: ' . $e->getMessage()
        ]);
    }
}

$conn->close();
?>