<?php
include 'conn.php';

// Get the raw POST data
$data = file_get_contents("php://input");
$request = json_decode($data, true); // Decode the JSON input into an associative array

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Check if all required fields are provided
if (
    isset($request['employee_name']) &&
    isset($request['phone_number']) &&
    isset($request['service_type']) &&
    isset($request['address']) &&
    isset($request['id_proof']) &&
    isset($request['email']) &&
    isset($request['password'])
) {
    // Extract data
    $employee_name = $request['employee_name'];
    $phone_number = $request['phone_number'];
    $service_type = $request['service_type'];
    $address = $request['address'];
    $id_proof_base64 = $request['id_proof'];
    $email = $request['email'];
    $password = password_hash($request['password'], PASSWORD_DEFAULT); // Hash the password

    // Decode and save the ID proof image
    $id_proof_folder = 'tech_idproof/';
    if (!file_exists($id_proof_folder)) {
        mkdir($id_proof_folder, 0777, true); // Create folder if it doesn't exist
    }
    $file_name = uniqid() . ".png"; // Unique file name
    $file_path = $id_proof_folder . $file_name;

    if (file_put_contents($file_path, base64_decode($id_proof_base64))) {
        // Insert into the database
        $sql = "INSERT INTO Technicians (employee_name, phone_number, service_type, address, id_proof, email, password) 
                VALUES (?, ?, ?, ?, ?, ?, ?)";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("sssssss", $employee_name, $phone_number, $service_type, $address, $file_path, $email, $password);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Technician added successfully"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Failed to add technician: " . $stmt->error]);
        }

        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to save ID proof"]);
    }
} else {
    // Missing fields
    echo json_encode(["status" => "error", "message" => "Incomplete input data"]);
}

$conn->close();
?>
