<?php

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

include 'conn.php'; // Include the database connection

// Function to validate session ID
function validateSession($conn, $sessionId) {
    $sql = "SELECT id FROM admin_login WHERE sessionid = ? AND session_expiry > NOW()";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $sessionId);
    $stmt->execute();
    $stmt->store_result();
    return $stmt->num_rows > 0;
}

// Get session ID from request headers
$headers = getallheaders();
error_log(print_r($headers, true));

// Try different header case variations as header names can be case-insensitive
$sessionId = '';
foreach ($headers as $name => $value) {
    if (strtolower($name) === 'session-id') {
        $sessionId = $value;
        break;
    }
}

// Validate session ID
if (empty($sessionId) || !validateSession($conn, $sessionId)) {
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized access. Invalid or expired session."
    ]);
    exit;
}

// Get the raw POST data (JSON)
$data = json_decode(file_get_contents("php://input"), true);

// Validate input fields
if (
    isset($data['offer_name'], $data['coupon_number'], $data['offer_starts_on'], $data['expires_on'], $data['offer_percentage'], $data['offer_banner'])
) {
    $offer_name = $data['offer_name'];
    $coupon_number = $data['coupon_number'];
    $offer_starts_on = $data['offer_starts_on'];
    $expires_on = $data['expires_on'];
    $offer_percentage = $data['offer_percentage'];
    $offer_banner_base64 = $data['offer_banner'];

    // Decode the base64 image and save it in the `offer-banner` folder
    $banner_directory = "offer-banner/";
    if (!is_dir($banner_directory)) {
        mkdir($banner_directory, 0777, true); // Create the directory if it doesn't exist
    }

    // Generate a unique filename for the banner
    $file_name = $coupon_number . "_" . uniqid() . ".jpg";
    $file_path = $banner_directory . $file_name;

    // Save the image
    if (file_put_contents($file_path, base64_decode($offer_banner_base64))) {
        // Insert the offer data into the database
        $stmt = $conn->prepare("
            INSERT INTO offers (offer_name, coupon_number, offer_starts_on, expires_on, offer_percentage, offer_banner_location) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->bind_param("ssssis", $offer_name, $coupon_number, $offer_starts_on, $expires_on, $offer_percentage, $file_path);

        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success",
                "message" => "Offer added successfully"
            ]);
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Failed to add offer",
                "error" => $stmt->error
            ]);
        }

        $stmt->close();
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Failed to save offer banner"
        ]);
    }
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Missing required fields"
    ]);
}

$conn->close();
?>
