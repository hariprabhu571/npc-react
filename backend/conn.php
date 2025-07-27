<?php
// conn.php - Database connection file

// Allow CORS for local development and production
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: http://localhost:3000'); // Change to * for all origins, or add more as needed
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Session-ID, session-id');
header('Access-Control-Max-Age: 86400');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}


$host = 'localhost';
$dbname = 'u457989556_npc';
$username = 'u457989556_npc';
$password = 'u457989556_Npc';

// Create connection
$conn = new mysqli($host, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}
?>