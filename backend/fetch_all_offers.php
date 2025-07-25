<?php
// fetch_all_offers.php - Fetch all offers
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

try {
    // Get session ID from request headers
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

    // Query to fetch all offers
    $query = "
        SELECT 
            offer_id, 
            offer_name, 
            coupon_number, 
            offer_starts_on, 
            expires_on, 
            offer_percentage, 
            offer_banner_location
        FROM offers 
        ORDER BY expires_on DESC
    ";
    
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Query execution failed: " . $conn->error);
    }

    $offers = [];
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            // Determine status
            $current_date = date('Y-m-d');
            $expires_on = $row['expires_on'];
            $status = (strtotime($expires_on) >= strtotime($current_date)) ? "Active" : "Expired";

            $offers[] = [
                "offer_id" => $row['offer_id'],
                "offer_name" => $row['offer_name'],
                "coupon_number" => $row['coupon_number'],
                "offer_starts_on" => $row['offer_starts_on'],
                "expires_on" => $row['expires_on'],
                "offer_percentage" => $row['offer_percentage'],
                "offer_banner_location" => $row['offer_banner_location'],
                "status" => $status
            ];
        }
    }

    // Return response
    echo json_encode([
        "status" => "success",
        "message" => count($offers) > 0 ? "Offers retrieved successfully" : "No offers found",
        "offers" => $offers
    ]);

} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Failed to fetch offers: " . $e->getMessage(),
        "offers" => []
    ]);
}

$conn->close();
?>