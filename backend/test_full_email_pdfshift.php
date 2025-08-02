<?php
// Test full email sending with PDFShift
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', 'email_errors.log');

require_once 'conn.php';

echo "<h1>Full Email Test with PDFShift</h1>";

// Simulate the exact data that would be sent from the frontend
$test_data = [
    'user_email' => 'hariprabhu571@gmail.com', // Change this to your email
    'user_name' => 'Test User',
    'booking_id' => 'TEST' . time(),
    'service_name' => 'Pest Control Service',
    'total_amount' => '1500.00',
    'service_date' => '2024-01-15',
    'service_time' => '10:00 AM',
    'address' => '123 Test Street, Test City, Test State 12345',
    'cart_items' => [
        [
            'service_type_name' => 'General Pest Control',
            'price' => 1000.00
        ],
        [
            'service_type_name' => 'Cockroach Treatment',
            'price' => 500.00
        ]
    ],
    'discount' => 100.00,
    'taxes' => 0.00,
    'payment_status' => 'Pending'
];

echo "<h2>Test Data:</h2>";
echo "<pre>" . json_encode($test_data, JSON_PRETTY_PRINT) . "</pre>";

// Include the functions from the PDFShift email script
function generateInvoiceHTML($user_name, $booking_id, $service_name, $total_amount, $service_date, $service_time, $address, $cart_items, $discount, $taxes, $payment_status) {
    // Calculate item total (sum of all cart items)
    $item_total = 0;
    if (!empty($cart_items) && is_array($cart_items)) {
        foreach ($cart_items as $item) {
            if (isset($item['price']) && isset($item['quantity'])) {
                $item_total += $item['price'] * $item['quantity'];
            }
        }
    }
    
    // Calculate final total
    $final_total = $item_total - $discount + $taxes;
    
    $html = '
    <div style="margin: 20px 0; padding: 32px; border: 1px solid #ddd; border-radius: 8px; background: white;">
        <!-- Header -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 32px;">
            <div>
                <div style="display: flex; align-items: center; margin-bottom: 16px;">
                    <div style="width: 48px; height: 48px; background: #0d9488; border-radius: 8px; display: flex; align-items: center; justify-content: center; overflow: hidden; margin-right: 12px; flex-shrink: 0;">
                        <img src="https://npcservices.in/assets/images/npc_logo.png" alt="NPC Pest Control Logo" style="width: 32px; height: 32px; object-fit: contain; display: block; max-width: 100%; height: auto;">
                    </div>
                    <div style="display: flex; flex-direction: column; justify-content: center;">
                        <h1 style="font-size: 24px; font-weight: bold; color: #111827; margin: 0; line-height: 1.2;">NPC Pest Control</h1>
                        <p style="color: #6b7280; margin: 0; line-height: 1.2;">Professional Services</p>
                    </div>
                </div>
                <div style="font-size: 14px; color: #6b7280;">
                    <p style="margin: 0 0 4px 0;">NPC PVT LTD, NO. 158, Murugan Kovil Street</p>
                    <p style="margin: 0 0 4px 0;">Vanashakthi Nagar, Kolather, Chennai - 99</p>
                    <p style="margin: 0 0 4px 0;">Phone: +91 86374 54428</p>
                    <p style="margin: 0;">Email: ashikali613@gmail.com</p>
                </div>
            </div>
            
            <div style="text-align: right;">
                <h2 style="font-size: 32px; font-weight: bold; color: #111827; margin: 0 0 8px 0;">INVOICE</h2>
                <div style="font-size: 14px; color: #6b7280;">
                    <p style="margin: 0 0 4px 0;"><strong>Invoice Date:</strong> ' . date('d/m/Y') . '</p>
                    <p style="margin: 0 0 4px 0;"><strong>Invoice #:</strong> ' . $booking_id . '</p>
                    <div style="display: flex; align-items: center; margin-top: 8px;">
                        <span style="margin-right: 8px;"><strong>Status:</strong></span>
                        <span style="color: #111827; font-weight: 500;">' . ucfirst($payment_status) . '</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Customer Information -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 32px; margin-bottom: 32px;">
            <div>
                <h3 style="font-size: 18px; font-weight: 600; color: #111827; margin: 0 0 12px 0;">Bill To:</h3>
                <div style="font-size: 14px; color: #374151;">
                    <p style="font-weight: 600; margin: 0 0 4px 0;">' . htmlspecialchars($user_name) . '</p>
                    <p style="margin: 0 0 4px 0;">' . htmlspecialchars($address) . '</p>
                </div>
            </div>
            
            <div>
                <h3 style="font-size: 18px; font-weight: 600; color: #111827; margin: 0 0 12px 0;">Service Details:</h3>
                <div style="font-size: 14px; color: #374151; margin-bottom: 4px;">
                    <div style="margin-bottom: 4px;"><strong>Service Date:</strong> ' . ($service_date ? date('d/m/Y', strtotime($service_date)) : 'To be scheduled') . '</div>
                    <div style="margin-bottom: 4px;"><strong>Time Slot:</strong> ' . ($service_time ? $service_time : 'To be scheduled') . '</div>
                </div>
            </div>
        </div>

        <!-- Service Items -->
        <div style="margin-bottom: 32px;">
            <h3 style="font-size: 18px; font-weight: 600; color: #111827; margin: 0 0 16px 0;">Service Details</h3>
            <div style="border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden;">
                <table style="width: 100%; border-collapse: collapse;">
                    <thead style="background: #f9fafb;">
                        <tr>
                            <th style="padding: 12px 24px; text-align: left; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">Service</th>
                            <th style="padding: 12px 24px; text-align: left; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">Description</th>
                            <th style="padding: 12px 24px; text-align: right; font-size: 12px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em;">Amount</th>
                        </tr>
                    </thead>
                    <tbody style="background: white;">
                        <!-- Main Service -->
                        <tr>
                            <td style="padding: 16px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap;">' . htmlspecialchars($service_name) . '</td>
                            <td style="padding: 16px 24px; font-size: 14px; color: #6b7280;">' . ($service_name . ' - Professional pest control service') . '</td>
                            <td style="padding: 16px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">-</td>
                        </tr>';
    
    // Add sub-services if available
    if (!empty($cart_items) && is_array($cart_items)) {
        foreach ($cart_items as $item) {
            if (isset($item['service_type_name']) && isset($item['price']) && isset($item['quantity'])) {
                // Fix common misspellings
                $service_name_fixed = str_replace('Appartment', 'Apartment', $item['service_type_name']);
                $html .= '
                        <tr style="background: #f9fafb;">
                            <td style="padding: 8px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap; padding-left: 32px;">• ' . htmlspecialchars($service_name_fixed) . ' - ' . (isset($item['room_size']) ? $item['room_size'] : '') . '</td>
                            <td style="padding: 8px 24px; font-size: 14px; color: #6b7280;">Quantity: ' . $item['quantity'] . ' × ₹' . number_format($item['price'], 2) . '</td>
                            <td style="padding: 8px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">₹' . number_format($item['price'] * $item['quantity'], 2) . '</td>
                        </tr>';
            }
        }
    } else {
        // If no cart items, show main service with total
        $html .= '
                        <tr style="background: #f9fafb;">
                            <td style="padding: 8px 24px; font-size: 14px; font-weight: 500; color: #111827; white-space: nowrap; padding-left: 32px;">• ' . htmlspecialchars($service_name) . '</td>
                            <td style="padding: 8px 24px; font-size: 14px; color: #6b7280;">Professional pest control service</td>
                            <td style="padding: 8px 24px; font-size: 14px; color: #111827; text-align: right; white-space: nowrap;">₹' . number_format($item_total, 2) . '</td>
                        </tr>';
    }
    
    $html .= '
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Payment Summary -->
        <div style="display: flex; justify-content: flex-end;">
            <div style="width: 320px;">
                <div style="background: #f9fafb; border-radius: 8px; padding: 24px;">
                    <h3 style="font-size: 18px; font-weight: 600; color: #111827; margin: 0 0 16px 0;">Payment Summary</h3>
                    <div style="margin-bottom: 12px;">
                        <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                            <span style="color: #6b7280;">Item Total:</span>
                            <span style="color: #111827;">₹' . number_format($item_total, 2) . '</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                            <span style="color: #6b7280;">Discount:</span>
                            <span style="color: #059669;">-₹' . number_format($discount, 2) . '</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; font-size: 14px; margin-bottom: 12px;">
                            <span style="color: #6b7280;">Taxes:</span>
                            <span style="color: #111827;">₹' . number_format($taxes, 2) . '</span>
                        </div>
                        <div style="border-top: 1px solid #e5e7eb; padding-top: 12px;">
                            <div style="display: flex; justify-content: space-between; font-size: 18px; font-weight: 600;">
                                <span style="color: #111827;">Total Amount:</span>
                                <span style="color: #0d9488;">₹' . number_format($final_total, 2) . '</span>
                            </div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 24px; padding-top: 16px; border-top: 1px solid #e5e7eb;">
                        <div style="display: flex; justify-content: space-between; align-items: center; font-size: 14px; margin-bottom: 8px;">
                            <span style="color: #6b7280;">Payment Status:</span>
                            <span style="color: #111827; font-weight: 500;">' . ucfirst($payment_status) . '</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

                    <!-- Footer -->
            <div style="margin-top: 48px; padding-top: 32px; border-top: 1px solid #e5e7eb;">
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 32px; font-size: 14px; color: #6b7280;">
                    <div>
                        <h4 style="font-weight: 600; color: #111827; margin: 0 0 8px 0;">Terms & Conditions</h4>
                        <ul style="margin: 0; padding: 0; list-style: none; font-size: 12px;">
                            <li style="margin-bottom: 4px;">• Payment is due upon receipt of this invoice</li>
                            <li style="margin-bottom: 4px;">• Late payments may incur additional charges</li>
                            <li style="margin-bottom: 0;">• Service satisfaction is guaranteed</li>
                        </ul>
                    </div>
                    <div>
                        <h4 style="font-weight: 600; color: #111827; margin: 0 0 8px 0;">Contact Information</h4>
                        <div style="font-size: 12px;">
                            <p style="margin: 0 0 4px 0;">Phone: +91 86374 54428</p>
                            <p style="margin: 0 0 4px 0;">Email: ashikali613@gmail.com</p>
                            <p style="margin: 0;">Website: www.npcservices.com</p>
                        </div>
                    </div>
                    <div>
                        <h4 style="font-weight: 600; color: #111827; margin: 0 0 8px 0;">Thank You</h4>
                        <p style="font-size: 12px; margin: 0;">
                            Thank you for choosing NPC Pest Control for your service needs. 
                            We appreciate your business and look forward to serving you again.
                        </p>
                    </div>
                </div>
            </div>
    </div>';
    
    return $html;
}

function generatePDFWithPDFShift($html_content) {
    try {
        // PDFShift API endpoint
        $api_url = 'https://api.pdfshift.io/v3/convert/';
        
        // Your PDFShift API key
        $api_key = 'sk_761477660d949d7142ba5aa4a6c2483f65711464';
        
        // Prepare the request data
        $data = array(
            'source' => $html_content,
            'landscape' => false,
            'use_print' => true,
            'margin_top' => '10mm',
            'margin_right' => '10mm',
            'margin_bottom' => '10mm',
            'margin_left' => '10mm'
        );
        
        // Initialize cURL
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $api_url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array(
            'Authorization: Bearer ' . $api_key,
            'Content-Type: application/json'
        ));
        
        // Execute the request
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($http_code === 200) {
            error_log("PDFShift: PDF generated successfully");
            return $response; // This is the PDF content
        } else {
            error_log("PDFShift: Failed to generate PDF. HTTP Code: $http_code, Response: $response");
            return false;
        }
        
    } catch (Exception $e) {
        error_log("PDFShift error: " . $e->getMessage());
        return false;
    }
}

echo "<h2>1. Generating HTML Content</h2>";

// Generate HTML content for PDF
$html_content = generateInvoiceHTML(
    $test_data['user_name'],
    $test_data['booking_id'],
    $test_data['service_name'],
    $test_data['total_amount'],
    $test_data['service_date'],
    $test_data['service_time'],
    $test_data['address'],
    $test_data['cart_items'],
    $test_data['discount'],
    $test_data['taxes'],
    $test_data['payment_status']
);

echo "✅ HTML content generated successfully<br>";
echo "HTML Length: " . strlen($html_content) . " bytes<br>";

echo "<h2>2. Generating PDF with PDFShift</h2>";

// Try to generate PDF using PDFShift
$pdf_content = generatePDFWithPDFShift($html_content);

$has_pdf = !empty($pdf_content);
echo "PDF Generation: " . ($has_pdf ? "✅ SUCCESS" : "❌ FAILED") . "<br>";

if ($has_pdf) {
    echo "PDF Size: " . strlen($pdf_content) . " bytes<br>";
    
    // Save the PDF for inspection
    $pdf_filename = 'test_invoice_full.pdf';
    if (file_put_contents($pdf_filename, $pdf_content)) {
        echo "✅ PDF saved as: $pdf_filename<br>";
        echo "<a href='$pdf_filename' target='_blank'>Click here to view the PDF</a><br>";
    }
}

echo "<h2>3. Testing Email Sending</h2>";

$user_email = $test_data['user_email'];
$user_name = $test_data['user_name'];
$booking_id = $test_data['booking_id'];
$service_name = $test_data['service_name'];
$total_amount = $test_data['total_amount'];

// Email content
$subject = "NPC Services - Invoice for Booking #$booking_id";

$message = "
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; }
        .header { background: linear-gradient(135deg, #0d9488, #0891b2); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: white; padding: 20px; border: 1px solid #ddd; border-top: none; }
        .invoice-details { background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .amount { font-size: 24px; font-weight: bold; color: #0d9488; }
        .footer { background: #f8f9fa; padding: 15px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 8px 8px; }
    </style>
</head>
<body>
    <div class='header'>
        <h1>NPC Services</h1>
        <p>Professional Pest Control & Home Services</p>
    </div>
    
    <div class='content'>
        <h2>Dear $user_name,</h2>
        
        <p>Thank you for choosing NPC Services! Your booking has been confirmed and your invoice is " . ($has_pdf ? "attached to this email." : "included below.") . "</p>
        
        <div class='invoice-details'>
            <h3>Booking Details:</h3>
            <p><strong>Booking ID:</strong> #$booking_id</p>
            <p><strong>Service:</strong> $service_name</p>
            <p><strong>Service Date:</strong> " . $test_data['service_date'] . "</p>
            <p><strong>Service Time:</strong> " . $test_data['service_time'] . "</p>
            <p><strong>Address:</strong> " . $test_data['address'] . "</p>
            <p><strong>Total Amount:</strong> <span class='amount'>₹$total_amount</span></p>
        </div>
        
        " . (!$has_pdf ? $html_content : "") . "
        
        <p>" . ($has_pdf ? "Please find your detailed invoice attached to this email." : "Your invoice is displayed above.") . " You can also view your booking details in your account dashboard.</p>
        
        <p>If you have any questions or need to make changes to your booking, please don't hesitate to contact our support team.</p>
        
        <p>Thank you for trusting NPC Services!</p>
        
        <p>Best regards,<br>
        NPC Services Team</p>
    </div>
    
    <div class='footer'>
        <p>This is an automated email. Please do not reply to this message.</p>
        <p>For support, contact us at support@npcservices.com</p>
    </div>
</body>
</html>
";

echo "Email Type: " . ($has_pdf ? "Multipart with PDF attachment" : "HTML only") . "<br>";
echo "To: $user_email<br>";
echo "Subject: $subject<br>";

// Create email headers and body based on whether we have PDF
if ($has_pdf) {
    // Create multipart email with PDF attachment
    $boundary = md5(time());
    
    $headers = array(
        'MIME-Version: 1.0',
        'Content-Type: multipart/mixed; boundary="' . $boundary . '"',
        'From: NPC Services <paymentnpc@gmail.com>',
        'Reply-To: support@npcservices.com',
        'X-Mailer: PHP/' . phpversion()
    );
    
    // Build multipart message
    $email_body = "--" . $boundary . "\r\n";
    $email_body .= "Content-Type: text/html; charset=UTF-8\r\n";
    $email_body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
    $email_body .= $message . "\r\n\r\n";
    
    // Add PDF attachment
    $email_body .= "--" . $boundary . "\r\n";
    $email_body .= "Content-Type: application/pdf; name=\"Invoice_$booking_id.pdf\"\r\n";
    $email_body .= "Content-Disposition: attachment; filename=\"Invoice_$booking_id.pdf\"\r\n";
    $email_body .= "Content-Transfer-Encoding: base64\r\n\r\n";
    $email_body .= chunk_split(base64_encode($pdf_content)) . "\r\n";
    
    $email_body .= "--" . $boundary . "--\r\n";
} else {
    // Send HTML email without PDF attachment
    $headers = array(
        'MIME-Version: 1.0',
        'Content-Type: text/html; charset=UTF-8',
        'From: NPC Services <paymentnpc@gmail.com>',
        'Reply-To: support@npcservices.com',
        'X-Mailer: PHP/' . phpversion()
    );
    
    $email_body = $message;
}

echo "Email Headers: " . implode("\r\n", $headers) . "<br>";

// Send email
$mail_sent = mail($user_email, $subject, $email_body, implode("\r\n", $headers));

echo "Email Send Result: " . ($mail_sent ? "✅ SUCCESS" : "❌ FAILED") . "<br>";

if (!$mail_sent) {
    $error = error_get_last();
    echo "Error: " . json_encode($error) . "<br>";
}

echo "<h2>4. Final Results</h2>";
echo "1. HTML Generation: ✅ SUCCESS<br>";
echo "2. PDF Generation: " . ($has_pdf ? "✅ SUCCESS" : "❌ FAILED") . "<br>";
echo "3. Email Sending: " . ($mail_sent ? "✅ SUCCESS" : "❌ FAILED") . "<br>";

if ($mail_sent) {
    echo "<h3>✅ Test Completed Successfully!</h3>";
    echo "Please check your email inbox for the test email.<br>";
    echo "If PDF generation worked, you should have received an email with a PDF attachment.<br>";
    echo "If PDF generation failed, you should have received an HTML email with the invoice embedded.<br>";
} else {
    echo "<h3>❌ Email Sending Failed</h3>";
    echo "Please check the server mail configuration.<br>";
}

echo "<h2>5. Next Steps</h2>";
if ($mail_sent) {
    echo "✅ The email system is working! You can now test it with real bookings.<br>";
    echo "1. Make a test booking on your website<br>";
    echo "2. Check if you receive the invoice email<br>";
    echo "3. Verify the PDF attachment (if generated)<br>";
} else {
    echo "❌ Email sending failed. Please check:<br>";
    echo "1. Server mail configuration<br>";
    echo "2. PHP mail() function availability<br>";
    echo "3. SMTP settings<br>";
}

echo "<h2>6. Cleanup</h2>";
if (file_exists($pdf_filename)) {
    echo "Test PDF file created: $pdf_filename<br>";
    echo "You can delete this file after testing.<br>";
}
?> 