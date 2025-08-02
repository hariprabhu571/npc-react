<?php
// Test PDFShift API integration
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', 'email_errors.log');

echo "<h1>PDFShift API Test</h1>";

// Test data
$test_html = '
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test Invoice</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: bold; color: #0d9488; }
        .invoice-title { font-size: 28px; font-weight: bold; text-align: center; margin: 20px 0; color: #0d9488; }
        .details { margin-bottom: 30px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 10px; }
        .label { font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background: #f8f9fa; font-weight: bold; }
        .total { border-top: 2px solid #0d9488; padding-top: 10px; margin-top: 10px; font-weight: bold; font-size: 18px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">NPC Services</div>
        <div>Professional Pest Control & Home Services</div>
    </div>
    
    <div class="invoice-title">INVOICE</div>
    
    <div class="details">
        <div class="row">
            <div>
                <div class="label">Invoice Number:</div>
                <div>#TEST123</div>
            </div>
            <div>
                <div class="label">Date:</div>
                <div>' . date('d/m/Y') . '</div>
            </div>
        </div>
        
        <div class="row">
            <div>
                <div class="label">Customer:</div>
                <div>Test User</div>
            </div>
            <div>
                <div class="label">Payment Status:</div>
                <div>Pending</div>
            </div>
        </div>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Service</th>
                <th>Description</th>
                <th>Amount</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Pest Control Service</td>
                <td>Main Service</td>
                <td>₹1,500.00</td>
            </tr>
            <tr>
                <td>General Pest Control</td>
                <td>Sub-service</td>
                <td>₹1,000.00</td>
            </tr>
            <tr>
                <td>Cockroach Treatment</td>
                <td>Sub-service</td>
                <td>₹500.00</td>
            </tr>
        </tbody>
    </table>
    
    <div class="total">
        <div style="display: flex; justify-content: space-between;">
            <span>Total:</span>
            <span>₹1,500.00</span>
        </div>
    </div>
    
    <div style="margin-top: 40px; text-align: center; font-size: 12px; color: #666;">
        <p>Thank you for choosing NPC Services!</p>
        <p>For support, contact us at support@npcservices.com</p>
    </div>
</body>
</html>';

echo "<h2>1. Testing PDFShift API Connection</h2>";

// PDFShift API configuration
$api_url = 'https://api.pdfshift.io/v3/convert/';
$api_key = 'sk_761477660d949d7142ba5aa4a6c2483f65711464';

// Prepare the request data
$data = array(
    'source' => $test_html,
    'landscape' => false,
    'use_print' => true,
    'margin_top' => '10mm',
    'margin_right' => '10mm',
    'margin_bottom' => '10mm',
    'margin_left' => '10mm'
);

echo "API URL: $api_url<br>";
echo "API Key: " . substr($api_key, 0, 10) . "...<br>";
echo "HTML Content Length: " . strlen($test_html) . " bytes<br>";

// Check if cURL is available
if (!function_exists('curl_init')) {
    echo "❌ cURL is not available on this server<br>";
    exit;
}

echo "✅ cURL is available<br>";

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

echo "<h2>2. Making API Request</h2>";
echo "Sending request to PDFShift...<br>";

// Execute the request
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "HTTP Response Code: $http_code<br>";

if ($curl_error) {
    echo "❌ cURL Error: $curl_error<br>";
} else {
    echo "✅ No cURL errors<br>";
}

if ($http_code === 200) {
    echo "✅ PDF generated successfully!<br>";
    echo "PDF Size: " . strlen($response) . " bytes<br>";
    
    // Save the PDF for inspection
    $pdf_filename = 'test_invoice_pdfshift.pdf';
    if (file_put_contents($pdf_filename, $response)) {
        echo "✅ PDF saved as: $pdf_filename<br>";
        echo "<a href='$pdf_filename' target='_blank'>Click here to view the PDF</a><br>";
    } else {
        echo "❌ Failed to save PDF file<br>";
    }
    
    echo "<h2>3. Test Result: SUCCESS</h2>";
    echo "✅ PDFShift API is working correctly!<br>";
    echo "✅ PDF generation is successful<br>";
    echo "✅ Your API key is valid<br>";
    
} else {
    echo "❌ Failed to generate PDF<br>";
    echo "Response: " . htmlspecialchars($response) . "<br>";
    
    echo "<h2>3. Test Result: FAILED</h2>";
    echo "❌ PDFShift API test failed<br>";
    echo "❌ HTTP Code: $http_code<br>";
    echo "❌ Response: " . htmlspecialchars($response) . "<br>";
}

echo "<h2>4. Next Steps</h2>";
if ($http_code === 200) {
    echo "✅ PDFShift is working! You can now test the full email system.<br>";
    echo "1. Make a test booking on your website<br>";
    echo "2. Check if you receive an email with PDF attachment<br>";
    echo "3. Verify the PDF contains the correct invoice information<br>";
} else {
    echo "❌ PDFShift test failed. Please check:<br>";
    echo "1. API key is correct<br>";
    echo "2. Internet connection is available<br>";
    echo "3. Server can make outbound HTTP requests<br>";
    echo "4. PDFShift service is not down<br>";
}

echo "<h2>5. Cleanup</h2>";
if (file_exists($pdf_filename)) {
    echo "Test PDF file created: $pdf_filename<br>";
    echo "You can delete this file after testing.<br>";
}
?> 