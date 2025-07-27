<?php
require 'conn.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Session-ID, session-id');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function getMonthRange($offset = 0) {
    $firstDay = date('Y-m-01', strtotime("$offset month"));
    $lastDay = date('Y-m-t', strtotime("$offset month"));
    return [$firstDay, $lastDay];
}

function safe_fetch($result, $key, $default = 0) {
    if ($result && $row = $result->fetch_assoc()) {
        return isset($row[$key]) ? $row[$key] : $default;
    }
    return $default;
}

// Current month
[$curStart, $curEnd] = getMonthRange(0);
// Last month
[$lastStart, $lastEnd] = getMonthRange(-1);

// Bookings (current month)
$curBookings = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM bookings WHERE service_date BETWEEN '$curStart' AND '$curEnd'"), 'cnt');
$curPending = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM bookings WHERE service_date BETWEEN '$curStart' AND '$curEnd' AND booking_status = 'pending'"), 'cnt');
$curRevenue = safe_fetch($conn->query("SELECT SUM(total_amount) as sum FROM bookings WHERE service_date BETWEEN '$curStart' AND '$curEnd' AND payment_status = 'paid'"), 'sum');
$curEmployees = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM technicians"), 'cnt');

// Bookings (last month)
$lastBookings = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM bookings WHERE service_date BETWEEN '$lastStart' AND '$lastEnd'"), 'cnt');
$lastPending = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM bookings WHERE service_date BETWEEN '$lastStart' AND '$lastEnd' AND booking_status = 'pending'"), 'cnt');
$lastRevenue = safe_fetch($conn->query("SELECT SUM(total_amount) as sum FROM bookings WHERE service_date BETWEEN '$lastStart' AND '$lastEnd' AND payment_status = 'paid'"), 'sum');
$lastEmployees = safe_fetch($conn->query("SELECT COUNT(*) as cnt FROM technicians"), 'cnt');

$response = [
    'current' => [
        'bookings' => (int)$curBookings,
        'pending' => (int)$curPending,
        'revenue' => (float)$curRevenue,
        'employees' => (int)$curEmployees
    ],
    'last_month' => [
        'bookings' => (int)$lastBookings,
        'pending' => (int)$lastPending,
        'revenue' => (float)$lastRevenue,
        'employees' => (int)$lastEmployees
    ]
];
echo json_encode($response);
$conn->close(); 