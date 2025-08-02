<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', 'email_errors.log');

require_once 'conn.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Only POST method allowed']);
    exit;
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Log the received input
    error_log("Received input: " . json_encode($input));
    
    if (!$input) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON input']);
        exit;
    }
    
    // Validate required fields
    $required_fields = ['user_email', 'user_name', 'booking_id', 'service_name', 'total_amount'];
    foreach ($required_fields as $field) {
        if (empty($input[$field])) {
            echo json_encode(['status' => 'error', 'message' => "Missing required field: $field"]);
            exit;
        }
    }
    
    $user_email = $input['user_email'];
    $user_name = $input['user_name'];
    $booking_id = $input['booking_id'];
    $service_name = $input['service_name'];
    $total_amount = $input['total_amount'];
    $service_date = $input['service_date'] ?? '';
    $service_time = $input['service_time'] ?? '';
    $address = $input['address'] ?? '';
    $cart_items = $input['cart_items'] ?? [];
    $discount = $input['discount'] ?? 0;
    $taxes = $input['taxes'] ?? 0;
    $payment_status = $input['payment_status'] ?? 'Pending';
    
    // Log the processed data
    error_log("Processing email for: $user_email, Booking: $booking_id, Service: $service_name");
    
    // Validate email format
    if (!filter_var($user_email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid email format']);
        exit;
    }
    
    // Generate PDF invoice
    $pdf_content = generateInvoicePDF($user_name, $booking_id, $service_name, $total_amount, $service_date, $service_time, $address, $cart_items, $discount, $taxes, $payment_status);
    
    // If PDF generation fails, we'll send HTML email instead
    $has_pdf = !empty($pdf_content);
    error_log("PDF generation result: " . ($has_pdf ? "SUCCESS - PDF size: " . strlen($pdf_content) . " bytes" : "FAILED - will send HTML email"));
    
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
            .button { display: inline-block; padding: 10px 20px; background: #0d9488; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0; }
            .services-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
            .services-table th, .services-table td { border: 1px solid #ddd; padding: 12px; text-align: left; }
            .services-table th { background: #f8f9fa; font-weight: bold; }
            .payment-summary { margin-top: 30px; }
            .payment-row { display: flex; justify-content: space-between; margin-bottom: 8px; }
            .total-row { border-top: 2px solid #0d9488; padding-top: 10px; margin-top: 10px; font-weight: bold; font-size: 18px; }
            .status { padding: 5px 10px; border-radius: 4px; font-size: 12px; font-weight: bold; display: inline-block; }
            .status-pending { background: #fef3c7; color: #92400e; }
            .status-completed { background: #d1fae5; color: #065f46; }
            .status-cancelled { background: #fee2e2; color: #991b1b; }
            .invoice-section { margin: 30px 0; padding: 20px; border: 2px solid #0d9488; border-radius: 8px; background: #f8f9fa; }
            .invoice-title { text-align: center; font-size: 24px; font-weight: bold; color: #0d9488; margin-bottom: 20px; }
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
                " . ($service_date ? "<p><strong>Service Date:</strong> $service_date</p>" : "") . "
                " . ($service_time ? "<p><strong>Service Time:</strong> $service_time</p>" : "") . "
                " . ($address ? "<p><strong>Address:</strong> $address</p>" : "") . "
                <p><strong>Payment Status:</strong> <span class='status status-" . strtolower($payment_status) . "'>$payment_status</span></p>
                <p><strong>Total Amount:</strong> <span class='amount'>₹$total_amount</span></p>
            </div>
            
            " . (!$has_pdf ? "
            <div class='invoice-section'>
                <div class='invoice-title'>INVOICE</div>
                
                <div style='margin-bottom: 20px;'>
                    <div style='display: flex; justify-content: space-between; margin-bottom: 10px;'>
                        <div>
                            <strong>Invoice Number:</strong><br>
                            #$booking_id
                        </div>
                        <div>
                            <strong>Date:</strong><br>
                            " . date('d/m/Y') . "
                        </div>
                    </div>
                    
                    <div style='display: flex; justify-content: space-between; margin-bottom: 10px;'>
                        <div>
                            <strong>Customer:</strong><br>
                            " . htmlspecialchars($user_name) . "
                        </div>
                        <div>
                            <strong>Payment Status:</strong><br>
                            <span class='status status-" . strtolower($payment_status) . "'>$payment_status</span>
                        </div>
                    </div>
                    
                    <div style='display: flex; justify-content: space-between; margin-bottom: 10px;'>
                        <div>
                            <strong>Service Date:</strong><br>
                            " . ($service_date ? date('d/m/Y', strtotime($service_date)) : 'To be scheduled') . "
                        </div>
                        <div>
                            <strong>Service Time:</strong><br>
                            " . ($service_time ? $service_time : 'To be scheduled') . "
                        </div>
                    </div>
                    
                    <div style='margin-bottom: 10px;'>
                        <strong>Address:</strong><br>
                        " . htmlspecialchars($address) . "
                    </div>
                </div>
                
                <table class='services-table'>
                    <thead>
                        <tr>
                            <th>Service</th>
                            <th>Description</th>
                            <th>Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>" . htmlspecialchars($service_name) . "</td>
                            <td>Main Service</td>
                            <td>₹" . number_format($total_amount, 2) . "</td>
                        </tr>";
                
                // Add sub-services if available
                if (!empty($cart_items) && is_array($cart_items)) {
                    foreach ($cart_items as $item) {
                        if (isset($item['service_type_name']) && isset($item['price'])) {
                            $message .= "
                        <tr>
                            <td>" . htmlspecialchars($item['service_type_name']) . "</td>
                            <td>Sub-service</td>
                            <td>₹" . number_format($item['price'], 2) . "</td>
                        </tr>";
                        }
                    }
                }
                
                $message .= "
                    </tbody>
                </table>
                
                <div class='payment-summary'>
                    <div class='payment-row'>
                        <span>Subtotal:</span>
                        <span>₹" . number_format($total_amount, 2) . "</span>
                    </div>";
                
                if ($discount > 0) {
                    $message .= "
                    <div class='payment-row'>
                        <span>Discount:</span>
                        <span>-₹" . number_format($discount, 2) . "</span>
                    </div>";
                }
                
                if ($taxes > 0) {
                    $message .= "
                    <div class='payment-row'>
                        <span>Taxes:</span>
                        <span>₹" . number_format($taxes, 2) . "</span>
                    </div>";
                }
                
                $final_total = $total_amount - $discount + $taxes;
                $message .= "
                    <div class='payment-row total-row'>
                        <span>Total:</span>
                        <span>₹" . number_format($final_total, 2) . "</span>
                    </div>
                </div>
            </div>" : "") . "
            
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
    
    // Log email attempt
    $email_type = $has_pdf ? "with PDF attachment" : "HTML only";
    error_log("Attempting to send email $email_type to: $user_email");
    error_log("Subject: $subject");
    error_log("Headers: " . implode("\r\n", $headers));
    
    // Send email with PDF attachment
    $mail_sent = mail($user_email, $subject, $email_body, implode("\r\n", $headers));
    
    // Log the result
    error_log("Mail send result: " . ($mail_sent ? "SUCCESS" : "FAILED"));
    
    if ($mail_sent) {
        // Log the email sending
        try {
            $log_sql = "INSERT INTO email_logs (user_email, user_name, booking_id, service_name, total_amount, sent_at) 
                         VALUES (?, ?, ?, ?, ?, NOW())";
            $log_stmt = $conn->prepare($log_sql);
            $log_stmt->bind_param("sssss", $user_email, $user_name, $booking_id, $service_name, $total_amount);
            $log_result = $log_stmt->execute();
            error_log("Database log result: " . ($log_result ? "SUCCESS" : "FAILED"));
        } catch (Exception $db_error) {
            error_log("Database logging error: " . $db_error->getMessage());
        }
        
        echo json_encode([
            'status' => 'success', 
            'message' => $has_pdf ? 'Invoice email with PDF attachment sent successfully' : 'Invoice email sent successfully',
            'email_sent_to' => $user_email,
            'method' => $has_pdf ? 'php_mail_with_pdf' : 'php_mail_html'
        ]);
    } else {
        // Get the last error from PHP mail function
        $error = error_get_last();
        error_log("Mail function error: " . json_encode($error));
        
        echo json_encode([
            'status' => 'error', 
            'message' => 'Failed to send email. Please check server mail configuration.',
            'debug_info' => [
                'mail_function_available' => function_exists('mail'),
                'sendmail_path' => ini_get('sendmail_path'),
                'smtp_host' => ini_get('SMTP'),
                'last_error' => $error,
                'pdf_generation' => $has_pdf ? 'success' : 'failed'
            ]
        ]);
    }
    
} catch (Exception $e) {
    error_log("Send invoice email error: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Internal server error']);
}

// Function to generate PDF invoice
function generateInvoicePDF($user_name, $booking_id, $service_name, $total_amount, $service_date, $service_time, $address, $cart_items, $discount, $taxes, $payment_status) {
    try {
        error_log("Starting PDF generation for booking: $booking_id");
        
        // Create HTML content for PDF
        $html = '
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Invoice #' . $booking_id . '</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 0; padding: 20px; color: #333; }
                .header { text-align: center; margin-bottom: 30px; }
                .logo { font-size: 24px; font-weight: bold; color: #0d9488; margin-bottom: 10px; }
                .company-info { font-size: 12px; color: #666; }
                .invoice-title { font-size: 28px; font-weight: bold; text-align: center; margin: 20px 0; color: #0d9488; }
                .invoice-details { margin-bottom: 30px; }
                .row { display: flex; justify-content: space-between; margin-bottom: 10px; }
                .label { font-weight: bold; }
                .status { padding: 5px 10px; border-radius: 4px; font-size: 12px; font-weight: bold; }
                .status-pending { color: #92400e; }
                .status-completed { color: #065f46; }
                .status-cancelled { color: #991b1b; }
                .services-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                .services-table th, .services-table td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                .services-table th { background: #f8f9fa; font-weight: bold; }
                .payment-summary { margin-top: 30px; }
                .payment-row { display: flex; justify-content: space-between; margin-bottom: 8px; }
                .total-row { border-top: 2px solid #0d9488; padding-top: 10px; margin-top: 10px; font-weight: bold; font-size: 18px; }
                .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #666; }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="logo">NPC Services</div>
                <div class="company-info">Professional Pest Control & Home Services</div>
            </div>
            
            <div class="invoice-title">INVOICE</div>
            
            <div class="invoice-details">
                <div class="row">
                    <div>
                        <div class="label">Invoice Number:</div>
                        <div>#' . $booking_id . '</div>
                    </div>
                    <div>
                        <div class="label">Date:</div>
                        <div>' . date('d/m/Y') . '</div>
                    </div>
                </div>
                
                <div class="row">
                    <div>
                        <div class="label">Customer:</div>
                        <div>' . htmlspecialchars($user_name) . '</div>
                    </div>
                    <div>
                        <div class="label">Payment Status:</div>
                        <div class="status status-' . strtolower($payment_status) . '">' . $payment_status . '</div>
                    </div>
                </div>
                
                <div class="row">
                    <div>
                        <div class="label">Service Date:</div>
                        <div>' . ($service_date ? date('d/m/Y', strtotime($service_date)) : 'To be scheduled') . '</div>
                    </div>
                    <div>
                        <div class="label">Service Time:</div>
                        <div>' . ($service_time ? $service_time : 'To be scheduled') . '</div>
                    </div>
                </div>
                
                <div class="row">
                    <div>
                        <div class="label">Address:</div>
                        <div>' . htmlspecialchars($address) . '</div>
                    </div>
                </div>
            </div>
            
            <table class="services-table">
                <thead>
                    <tr>
                        <th>Service</th>
                        <th>Description</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>';
        
        // Calculate subtotal (sum of main service + all sub-services)
        $subtotal = $total_amount;
        if (!empty($cart_items) && is_array($cart_items)) {
            foreach ($cart_items as $item) {
                if (isset($item['price'])) {
                    $subtotal += $item['price'];
                }
            }
        }
        
        // Add main service
        $html .= '
                    <tr>
                        <td>' . htmlspecialchars($service_name) . '</td>
                        <td>Main Service</td>
                        <td>₹' . number_format($total_amount, 2) . '</td>
                    </tr>';
        
        // Add sub-services if available
        if (!empty($cart_items) && is_array($cart_items)) {
            foreach ($cart_items as $item) {
                if (isset($item['service_type_name']) && isset($item['price'])) {
                    $html .= '
                    <tr>
                        <td>' . htmlspecialchars($item['service_type_name']) . '</td>
                        <td>Sub-service</td>
                        <td>₹' . number_format($item['price'], 2) . '</td>
                    </tr>';
                }
            }
        }
        
        $html .= '
                </tbody>
            </table>
            
            <div class="payment-summary">
                <div class="payment-row">
                    <span>Subtotal:</span>
                    <span>₹' . number_format($subtotal, 2) . '</span>
                </div>';
        
        if ($discount > 0) {
            $html .= '
                <div class="payment-row">
                    <span>Discount:</span>
                    <span>-₹' . number_format($discount, 2) . '</span>
                </div>';
        }
        
        if ($taxes > 0) {
            $html .= '
                <div class="payment-row">
                    <span>Taxes:</span>
                    <span>₹' . number_format($taxes, 2) . '</span>
                </div>';
        }
        
        $final_total = $subtotal - $discount + $taxes;
        $html .= '
                <div class="payment-row total-row">
                    <span>Total:</span>
                    <span>₹' . number_format($final_total, 2) . '</span>
                </div>
            </div>
            
            <div class="footer">
                <p>Thank you for choosing NPC Services!</p>
                <p>For support, contact us at support@npcservices.com</p>
            </div>
        </body>
        </html>';
        
        error_log("HTML content generated for PDF, length: " . strlen($html));
        
        // Check if shell_exec is available
        if (!function_exists('shell_exec')) {
            error_log("shell_exec function is not available");
            return false;
        }
        
        // Try to use wkhtmltopdf if available
        $wkhtmltopdf_paths = [
            '/usr/bin/wkhtmltopdf',
            '/usr/local/bin/wkhtmltopdf',
            'wkhtmltopdf'
        ];
        
        $found_wkhtmltopdf = false;
        foreach ($wkhtmltopdf_paths as $path) {
            if (is_executable($path)) {
                error_log("Found wkhtmltopdf at: $path");
                $found_wkhtmltopdf = true;
                
                // Create temporary HTML file
                $temp_html = tempnam(sys_get_temp_dir(), 'invoice_') . '.html';
                $html_written = file_put_contents($temp_html, $html);
                error_log("HTML file written to: $temp_html, bytes written: $html_written");
                
                if (!$html_written) {
                    error_log("Failed to write HTML file");
                    continue;
                }
                
                // Generate PDF using wkhtmltopdf
                $temp_pdf = tempnam(sys_get_temp_dir(), 'invoice_') . '.pdf';
                $command = "$path --page-size A4 --margin-top 10 --margin-right 10 --margin-bottom 10 --margin-left 10 --encoding UTF-8 '$temp_html' '$temp_pdf'";
                error_log("Executing command: $command");
                
                $output = shell_exec($command);
                error_log("Command output: " . ($output ? $output : 'No output'));
                
                if (file_exists($temp_pdf)) {
                    $pdf_content = file_get_contents($temp_pdf);
                    $pdf_size = strlen($pdf_content);
                    error_log("PDF file created successfully! Size: $pdf_size bytes");
                    
                    // Clean up temp files
                    unlink($temp_html);
                    unlink($temp_pdf);
                    error_log("Temp files cleaned up");
                    
                    return $pdf_content;
                } else {
                    error_log("PDF file was NOT created at: $temp_pdf");
                    unlink($temp_html); // Clean up temp HTML even if PDF fails
                }
            } else {
                error_log("wkhtmltopdf not found or not executable at: $path");
            }
        }
        
        if (!$found_wkhtmltopdf) {
            error_log("No wkhtmltopdf found in any of the checked paths");
        }
        
        // Fallback: return false to send HTML email instead
        error_log("PDF generation failed, will send HTML email instead");
        return false;
        
    } catch (Exception $e) {
        error_log("PDF generation error: " . $e->getMessage());
        return false;
    }
}
?> 