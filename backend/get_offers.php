<?php
// get_offers.php - Fetch all available offers

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
        // Check if offers table exists
        $tableCheck = $conn->query("SHOW TABLES LIKE 'offers'");
        if (!$tableCheck || $tableCheck->num_rows == 0) {
            // Create offers table if it doesn't exist
            $createTable = "
                CREATE TABLE IF NOT EXISTS offers (
                    offer_id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    description TEXT,
                    discount DECIMAL(5,2),
                    offer_image VARCHAR(500),
                    valid_from DATE,
                    valid_to DATE,
                    status ENUM('active', 'inactive') DEFAULT 'active',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ";
            $conn->query($createTable);
            
            // Insert sample offers
            $sampleOffers = [
                ['First Time Customer Discount', 'Get 20% off on your first service booking with us', 20.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+30 days'))],
                ['Weekend Special', 'Special weekend pricing on all cleaning services', 15.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+7 days'))],
                ['Bulk Booking Offer', 'Book 3 services and get 25% off on total amount', 25.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+15 days'))],
                ['Monsoon Special', 'Special rates for pest control and waterproofing', 30.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+45 days'))],
                ['Happy Hours Discount', 'Book between 10 AM - 2 PM and save 10%', 10.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+60 days'))],
                ['Refer & Earn', 'Refer friends and both get 15% discount', 15.00, null, date('Y-m-d'), date('Y-m-d', strtotime('+90 days'))]
            ];
            
            $insertStmt = $conn->prepare("INSERT INTO offers (title, description, discount, offer_image, valid_from, valid_to) VALUES (?, ?, ?, ?, ?, ?)");
            foreach ($sampleOffers as $offer) {
                $insertStmt->bind_param("ssdsss", $offer[0], $offer[1], $offer[2], $offer[3], $offer[4], $offer[5]);
                $insertStmt->execute();
            }
            $insertStmt->close();
        }

        // Fetch active offers that are still valid
        $query = "
            SELECT 
                offer_id, 
                title, 
                description, 
                discount, 
                offer_image, 
                valid_from, 
                valid_to,
                DATEDIFF(valid_to, CURDATE()) as days_remaining
            FROM offers 
            WHERE status = 'active' 
            AND valid_to >= CURDATE() 
            ORDER BY discount DESC, created_at DESC
        ";
        
        $result = $conn->query($query);
        
        $offers = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $offers[] = [
                    'offer_id' => $row['offer_id'],
                    'title' => $row['title'],
                    'description' => $row['description'],
                    'discount' => (float)$row['discount'],
                    'offer_image' => $row['offer_image'],
                    'valid_from' => $row['valid_from'],
                    'valid_to' => $row['valid_to'],
                    'days_remaining' => (int)$row['days_remaining'],
                    'valid_from_formatted' => date('M d, Y', strtotime($row['valid_from'])),
                    'valid_to_formatted' => date('M d, Y', strtotime($row['valid_to']))
                ];
            }
        }
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Offers retrieved successfully',
            'offers' => $offers,
            'count' => count($offers)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to fetch offers: ' . $e->getMessage(),
            'offers' => []
        ]);
    }
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Only GET method allowed'
    ]);
}

$conn->close();
?>