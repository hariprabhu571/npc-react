<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'conn.php';

// Function to send email with PDF attachment
function sendEmailWithPDF($to, $subject, $message, $pdfData, $filename) {
    $boundary = md5(time());
    
    $headers = array(
        'MIME-Version: 1.0',
        'Content-Type: multipart/mixed; boundary="' . $boundary . '"',
        'From: NPC <paymentnpc@gmail.com>',
        'Reply-To: paymentnpc@gmail.com',
        'X-Mailer: PHP/' . phpversion()
    );
    
    $body = "--" . $boundary . "\r\n";
    $body .= "Content-Type: text/html; charset=UTF-8\r\n";
    $body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
    $body .= $message . "\r\n\r\n";
    
    // Add PDF attachment
    $body .= "--" . $boundary . "\r\n";
    $body .= "Content-Type: application/pdf; name=\"" . $filename . "\"\r\n";
    $body .= "Content-Disposition: attachment; filename=\"" . $filename . "\"\r\n";
    $body .= "Content-Transfer-Encoding: base64\r\n\r\n";
    $body .= chunk_split(base64_encode($pdfData)) . "\r\n";
    
    $body .= "--" . $boundary . "--\r\n";
    
    return mail($to, $subject, $body, implode("\r\n", $headers));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            throw new Exception('Invalid JSON input');
        }
        
        $userEmail = $input['user_email'] ?? '';
        $userName = $input['user_name'] ?? 'Customer';
        $bookingId = $input['booking_id'] ?? '';
        $serviceName = $input['service_name'] ?? '';
        $totalAmount = $input['total_amount'] ?? 0;
        $serviceDate = $input['service_date'] ?? '';
        $serviceTime = $input['service_time'] ?? '';
        $address = $input['address'] ?? '';
        $cartItems = $input['cart_items'] ?? [];
        $discount = $input['discount'] ?? 0;
        $taxes = $input['taxes'] ?? 0;
        $paymentStatus = $input['payment_status'] ?? 'Pending';
        $pdfData = $input['pdf_data'] ?? '';
        
        if (empty($userEmail)) {
            throw new Exception('User email is required');
        }
        
        if (empty($pdfData)) {
            throw new Exception('PDF data is required');
        }
        
        // Decode base64 PDF data
        $pdfBinary = base64_decode($pdfData);
        
        if ($pdfBinary === false) {
            throw new Exception('Invalid PDF data format');
        }
        
        // Create email subject and message
        $subject = "Invoice for Booking #$bookingId - NPC Services";
        
        $message = "
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .header { background-color: #f8f9fa; padding: 20px; text-align: center; }
                .content { padding: 20px; }
                .footer { background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }
            </style>
        </head>
        <body>
            <div class='header'>
                <h2>NPC Services</h2>
                <p>Your invoice is attached to this email</p>
            </div>
            <div class='content'>
                <p>Dear $userName,</p>
                <p>Thank you for choosing NPC Services. Your booking has been confirmed and your invoice is attached to this email.</p>
                <p><strong>Booking Details:</strong></p>
                <ul>
                    <li><strong>Booking ID:</strong> $bookingId</li>
                    <li><strong>Service:</strong> $serviceName</li>
                    <li><strong>Date:</strong> $serviceDate</li>
                    <li><strong>Time:</strong> $serviceTime</li>
                    <li><strong>Total Amount:</strong> ₹$totalAmount</li>
                    <li><strong>Payment Status:</strong> $paymentStatus</li>
                </ul>
                <p>If you have any questions, please don't hesitate to contact us.</p>
            </div>
            <div class='footer'>
                <p>NPC Services<br>
                Email: paymentnpc@gmail.com<br>
                Thank you for your business!</p>
            </div>
        </body>
        </html>";
        
        $filename = "Invoice_$bookingId.pdf";
        
        // Send email with PDF attachment
        $emailSent = sendEmailWithPDF($userEmail, $subject, $message, $pdfBinary, $filename);
        
        if ($emailSent) {
            echo json_encode([
                'status' => 'success',
                'message' => 'Invoice email sent successfully with PDF attachment'
            ]);
        } else {
            throw new Exception('Failed to send email');
        }
        
    } catch (Exception $e) {
        error_log("Invoice email error: " . $e->getMessage());
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Only POST method is allowed'
    ]);
}
?> 