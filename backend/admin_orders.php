<?php
// admin_orders.php - Admin order management

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Session-ID");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'conn.php';

// GET - Fetch all orders for admin dashboard
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Get Session-ID from headers for admin authentication
        $headers = getallheaders();
        $sessionId = null;
        
        foreach ($headers as $name => $value) {
            if (strtolower($name) === 'session-id') {
                $sessionId = $value;
                break;
            }
        }

        if (!$sessionId) {
            http_response_code(401);
            echo json_encode(['error' => 'Admin session required']);
            exit;
        }

        // Verify admin session using admin_login table
        $adminQuery = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
        $adminStmt = $conn->prepare($adminQuery);
        
        if (!$adminStmt) {
            throw new Exception("Failed to prepare admin query: " . $conn->error);
        }
        
        $adminStmt->bind_param("s", $sessionId);
        $adminStmt->execute();
        $adminResult = $adminStmt->get_result();
        $admin = $adminResult->fetch_assoc();
        
        if (!$admin) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid admin session']);
            exit;
        }

        // Fetch all orders with customer and technician details
        $ordersQuery = "
            SELECT 
                b.booking_id,
                b.user_id,
                b.service_name,
                b.service_date,
                b.time_slot,
                b.service_address,
                b.special_notes,
                b.subtotal,
                b.discount_amount,
                b.total_amount,
                b.payment_method,
                b.payment_status,
                b.booking_status,
                b.created_at,
                b.updated_at,
                u.customer_name,
                u.email_id,
                u.mobile_number,
                t.employee_name as assigned_technician_name,
                t.phone_number as technician_phone
            FROM bookings b
            LEFT JOIN users u ON b.user_id = u.user_id
            LEFT JOIN technicians t ON b.assigned_technician = t.technician_id
            ORDER BY b.created_at DESC
        ";
        
        $ordersStmt = $conn->prepare($ordersQuery);
        
        if (!$ordersStmt) {
            throw new Exception("Failed to prepare orders query: " . $conn->error);
        }
        
        $ordersStmt->execute();
        $ordersResult = $ordersStmt->get_result();
        $orders = $ordersResult->fetch_all(MYSQLI_ASSOC);
        
        // Categorize orders
        $pendingOrders = [];
        $acceptedOrders = [];
        $completedOrders = [];
        
        foreach ($orders as $order) {
            // Format the order data
            $formattedOrder = [
                'booking_id' => $order['booking_id'],
                'user_id' => $order['user_id'],
                'service_name' => $order['service_name'] ?? 'Unknown Service',
                'service_date' => $order['service_date'],
                'time_slot' => $order['time_slot'] ?? 'N/A',
                'service_address' => $order['service_address'],
                'special_notes' => $order['special_notes'],
                'subtotal' => (float)$order['subtotal'],
                'discount_amount' => (float)$order['discount_amount'],
                'total_amount' => (float)$order['total_amount'],
                'payment_method' => $order['payment_method'],
                'payment_status' => $order['payment_status'],
                'booking_status' => $order['booking_status'],
                'created_at' => $order['created_at'],
                'updated_at' => $order['updated_at'],
                'customer_name' => $order['customer_name'] ?? 'Unknown Customer',
                'customer_email' => $order['email_id'],
                'customer_phone' => $order['mobile_number'],
                'assigned_technician_name' => $order['assigned_technician_name'],
                'technician_phone' => $order['technician_phone'],
                
                // Format dates
                'service_date_formatted' => $order['service_date'] ? date('d M Y', strtotime($order['service_date'])) : 'N/A',
                'created_at_formatted' => $order['created_at'] ? date('d M Y, h:i A', strtotime($order['created_at'])) : 'N/A',
            ];
            
            // Categorize based on status
            switch (strtolower($order['booking_status'])) {
                case 'pending':
                    $pendingOrders[] = $formattedOrder;
                    break;
                    
                case 'confirmed':
                case 'accepted':
                case 'assigned':
                case 'in_progress':
                    $acceptedOrders[] = $formattedOrder;
                    break;
                    
                case 'completed':
                    $completedOrders[] = $formattedOrder;
                    break;
            }
        }
        
        // Get summary statistics
        $totalOrders = count($orders);
        $totalRevenue = array_sum(array_column($orders, 'total_amount'));
        $pendingCount = count($pendingOrders);
        $acceptedCount = count($acceptedOrders);
        $completedCount = count($completedOrders);
        
        $response = [
            'status' => 'success',
            'message' => 'Orders retrieved successfully',
            'summary' => [
                'total_orders' => $totalOrders,
                'total_revenue' => $totalRevenue,
                'pending_count' => $pendingCount,
                'accepted_count' => $acceptedCount,
                'completed_count' => $completedCount
            ],
            'orders' => [
                'pending' => $pendingOrders,
                'accepted' => $acceptedOrders,
                'completed' => $completedOrders
            ]
        ];
        
        http_response_code(200);
        echo json_encode($response);
        
    } catch (Exception $e) {
        error_log("Admin orders fetch error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database error occurred',
            'error' => $e->getMessage()
        ]);
    }
}

$conn->close();
?>