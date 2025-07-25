<?php
// Include required files
require 'conn.php'; // Database connection

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle profile picture update request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get Session-ID from headers
    $headers = getallheaders();
    $sessionid = null;
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'session-id') {
            $sessionid = $value;
            break;
        }
    }

    // Get JSON input from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (empty($sessionid) || empty($input['profile_pic'])) {
        echo json_encode(['status' => 'error', 'message' => 'Session ID and profile picture are required.']);
        exit;
    }

    $profile_pic_base64 = $input['profile_pic'];

    // Validate session ID
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ? AND session_expiry > NOW()");
    $stmt->bind_param("s", $sessionid);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired session. Please log in again.']);
        exit;
    }

    $user_id = $user['user_id'];

    // Handle profile picture upload
    $profile_pic_path = null;
    if ($profile_pic_base64) {
        // Decode the base64 image
        $image_data = base64_decode($profile_pic_base64);
        if ($image_data === false) {
            echo json_encode(['status' => 'error', 'message' => 'Invalid base64 image data.']);
            exit;
        }

        // Create the userprofile folder if it doesn't exist
        $folder_path = 'userprofile';
        if (!is_dir($folder_path)) {
            mkdir($folder_path, 0777, true);
        }

        // Generate a unique filename
        $filename = uniqid('profile_', true) . '.jpg';
        $file_path = $folder_path . '/' . $filename;

        // Save the image to the folder
        if (file_put_contents($file_path, $image_data)) {
            $profile_pic_path = $file_path;
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to save profile picture.']);
            exit;
        }
    }

    // Update user profile picture in the database
    $updateStmt = $conn->prepare("UPDATE users SET profile_pic = ? WHERE user_id = ?");
    $updateStmt->bind_param("si", $profile_pic_path, $user_id);

    if ($updateStmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Profile picture updated successfully.', 'profile_pic' => $profile_pic_path]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update profile picture.']);
    }

    $updateStmt->close();
}

$conn->close();
?>
