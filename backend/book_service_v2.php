<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', '/tmp/booking_errors.log');

//added for CROS (hari)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Custom error handler
function customErrorHandler($errno, $errstr, $errfile, $errline) {
    $errorMsg = "PHP Error [$errno]: $errstr in $errfile on line $errline";
    error_log("[CUSTOM_ERROR] " . $errorMsg);
    return false; // Let PHP handle it normally
}

// Custom exception handler
function customExceptionHandler($exception) {
    $errorMsg = "Uncaught Exception: " . $exception->getMessage() . " in " . $exception->getFile() . " on line " . $exception->getLine();
    error_log("[CUSTOM_EXCEPTION] " . $errorMsg);
    echo json_encode([
        "status" => "error",
        "message" => "Exception: " . $exception->getMessage(),
        "file" => $exception->getFile(),
        "line" => $exception->getLine()
    ]);
}

// Set custom handlers
set_error_handler('customErrorHandler');
set_exception_handler('customExceptionHandler');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Session-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Test endpoint
if (isset($_GET['test'])) {
    echo json_encode([
        "status" => "success",
        "message" => "PHP endpoint working",
        "timestamp" => date('Y-m-d H:i:s'),
        "php_version" => PHP_VERSION
    ]);
    exit;
}

// Log function
function writeLog($message) {
    error_log("[BOOKING] " . date('Y-m-d H:i:s') . " - " . $message);
}

writeLog("=== SCRIPT STARTED ===");

try {
    writeLog("Attempting to include conn.php");
    
    // Check if conn.php exists
    if (!file_exists('conn.php')) {
        throw new Exception("conn.php file not found");
    }
    
    include 'conn.php';
    writeLog("conn.php included successfully");
    
    // Check connection variable
    if (!isset($conn)) {
        throw new Exception("Connection variable \$conn not set");
    }
    
    if (!$conn) {
        throw new Exception("Database connection is null or false");
    }
    
    // Test the connection
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    writeLog("Database connection verified");
    
    // Session validation function
    function validateSession($conn, $sessionId) {
        writeLog("Starting session validation for: " . substr($sessionId, 0, 10) . "...");
        
        try {
            $stmt = $conn->prepare("SELECT user_id FROM users WHERE sessionid = ?");
            if (!$stmt) {
                throw new Exception("Failed to prepare session query: " . $conn->error);
            }
            
            $stmt->bind_param("s", $sessionId);
            
            if (!$stmt->execute()) {
                throw new Exception("Failed to execute session query: " . $stmt->error);
            }
            
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $user = $result->fetch_assoc();
                $stmt->close();
                writeLog("Session valid - User ID: " . $user['user_id']);
                return $user['user_id'];
            }
            
            $stmt->close();
            writeLog("Session invalid - no matching user found");
            return false;
            
        } catch (Exception $e) {
            writeLog("Session validation error: " . $e->getMessage());
            return false;
        }
    }
    
    // Get session ID from headers
    writeLog("Getting headers...");
    $headers = getallheaders();
    
    if (!$headers) {
        throw new Exception("Failed to get headers");
    }
    
    $sessionId = '';
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'session-id') {
            $sessionId = $value;
            break;
        }
    }
    
    writeLog("Session ID found: " . (empty($sessionId) ? "EMPTY" : "PRESENT"));
    
    if (empty($sessionId)) {
        echo json_encode(["status" => "error", "message" => "Session ID required"]);
        exit;
    }
    
    // Validate session
    $userId = validateSession($conn, $sessionId);
    if (!$userId) {
        echo json_encode(["status" => "error", "message" => "Invalid session"]);
        exit;
    }
    
    writeLog("User authenticated successfully: " . $userId);
    
    // Handle GET requests
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = $_GET['action'] ?? '';
        writeLog("GET Action requested: " . $action);
        
        if ($action === 'get_address') {
            try {
                $stmt = $conn->prepare("SELECT address1, address2, customer_name, mobile_number, email_id FROM users WHERE user_id = ?");
                $stmt->bind_param("i", $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows > 0) {
                    $user = $result->fetch_assoc();
                    $fullAddress = trim($user['address1'] ?? '');
                    if (!empty($user['address2'])) {
                        $fullAddress .= ', ' . trim($user['address2']);
                    }
                    
                    echo json_encode([
                        "status" => "success",
                        "address" => $fullAddress,
                        "has_address" => !empty($fullAddress),
                        "customer_name" => $user['customer_name'] ?? '',
                        "mobile_number" => $user['mobile_number'] ?? '',
                        "email_id" => $user['email_id'] ?? ''
                    ]);
                } else {
                    echo json_encode(["status" => "error", "message" => "User not found"]);
                }
            } catch (Exception $e) {
                writeLog("Get address error: " . $e->getMessage());
                echo json_encode(["status" => "error", "message" => "Failed to get address"]);
            }
        }
        
        elseif ($action === 'validate_coupon') {
            $couponCode = $_GET['coupon_code'] ?? '';
            $orderAmount = floatval($_GET['order_amount'] ?? 0);
            
            if (empty($couponCode)) {
                echo json_encode(["status" => "error", "message" => "Coupon code is required"]);
                exit;
            }
            
            try {
                $stmt = $conn->prepare("SELECT * FROM offers WHERE coupon_number = ? AND offer_starts_on <= CURDATE() AND expires_on >= CURDATE()");
                $stmt->bind_param("s", $couponCode);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows > 0) {
                    $offer = $result->fetch_assoc();
                    $discountAmount = ($orderAmount * $offer['offer_percentage']) / 100;
                    
                    echo json_encode([
                        "status" => "success",
                        "offer" => $offer,
                        "discount_amount" => $discountAmount,
                        "message" => "Coupon applied successfully! You saved ₹" . number_format($discountAmount, 2)
                    ]);
                } else {
                    echo json_encode(["status" => "error", "message" => "Invalid or expired coupon code"]);
                }
            } catch (Exception $e) {
                writeLog("Validate coupon error: " . $e->getMessage());
                echo json_encode(["status" => "error", "message" => "Failed to validate coupon"]);
            }
        }
    }
    
    // Handle POST requests
    elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        writeLog("Processing POST request");
        
        $input = file_get_contents('php://input');
        writeLog("Input received - Length: " . strlen($input));
        
        if (empty($input)) {
            echo json_encode(["status" => "error", "message" => "No data received"]);
            exit;
        }
        
        $data = json_decode($input, true);
        $jsonError = json_last_error();
        
        if ($jsonError !== JSON_ERROR_NONE) {
            writeLog("JSON decode error: " . json_last_error_msg());
            echo json_encode(["status" => "error", "message" => "Invalid JSON: " . json_last_error_msg()]);
            exit;
        }
        
        $action = $data['action'] ?? '';
        writeLog("POST Action requested: " . $action);
        
        if ($action === 'update_address') {
            $address = $data['address'] ?? '';
            
            if (empty($address)) {
                echo json_encode(["status" => "error", "message" => "Address is required"]);
                exit;
            }
            
            try {
                $stmt = $conn->prepare("UPDATE users SET address1 = ? WHERE user_id = ?");
                $stmt->bind_param("si", $address, $userId);
                
                if ($stmt->execute()) {
                    echo json_encode(["status" => "success", "message" => "Address updated successfully"]);
                } else {
                    echo json_encode(["status" => "error", "message" => "Failed to update address"]);
                }
            } catch (Exception $e) {
                writeLog("Update address error: " . $e->getMessage());
                echo json_encode(["status" => "error", "message" => "Failed to update address"]);
            }
        }
        
        elseif ($action === 'create_booking') {
            writeLog("=== CREATING BOOKING ===");
            
            // Generate booking ID
            $bookingId = 'BK' . date('Ymd') . rand(1000, 9999);
            writeLog("Generated booking ID: " . $bookingId);
            
            // Extract and validate data - INCLUDING RAZORPAY FIELDS
            $serviceName = $data['service_name'] ?? '';
            $serviceDate = $data['service_date'] ?? '';
            $timeSlot = $data['time_slot'] ?? '';
            $serviceAddress = $data['service_address'] ?? '';
            $specialNotes = $data['special_notes'] ?? '';
            $subtotal = floatval($data['subtotal'] ?? 0);
            $discountAmount = floatval($data['discount_amount'] ?? 0);
            $couponCode = $data['coupon_code'] ?? null;
            $couponDiscount = floatval($data['coupon_discount'] ?? 0);
            $totalAmount = floatval($data['total_amount'] ?? 0);
            $paymentMethod = $data['payment_method'] ?? 'cash';
            $cartItems = $data['cart_items'] ?? [];
            $razorpayOrderId = $data['razorpay_order_id'] ?? null;
            
            writeLog("Extracted data - Service: $serviceName, Date: $serviceDate, Payment: $paymentMethod, Items: " . count($cartItems));
            writeLog("Razorpay Order ID: " . ($razorpayOrderId ?? 'NULL'));
            
            // Validation
            $missingFields = [];
            if (empty($serviceName)) $missingFields[] = "service_name";
            if (empty($serviceDate)) $missingFields[] = "service_date";
            if (empty($timeSlot)) $missingFields[] = "time_slot";
            if (empty($serviceAddress)) $missingFields[] = "service_address";
            if (empty($cartItems)) $missingFields[] = "cart_items";
            
            if (!empty($missingFields)) {
                writeLog("Missing fields: " . implode(", ", $missingFields));
                echo json_encode([
                    "status" => "error", 
                    "message" => "Missing required fields: " . implode(", ", $missingFields)
                ]);
                exit;
            }
            
            // Check if tables exist
            writeLog("Checking if tables exist...");
            $tableCheck = $conn->query("SHOW TABLES LIKE 'bookings'");
            if ($tableCheck->num_rows === 0) {
                throw new Exception("Table 'bookings' does not exist");
            }
            
            $tableCheck = $conn->query("SHOW TABLES LIKE 'booking_items'");
            if ($tableCheck->num_rows === 0) {
                throw new Exception("Table 'booking_items' does not exist");
            }
            
            writeLog("Tables verified - starting transaction");
            
            // Start transaction
            if (!$conn->begin_transaction()) {
                throw new Exception("Failed to start transaction: " . $conn->error);
            }
            
            try {
                // Insert booking - CORRECTED PARAMETER COUNT
                writeLog("Preparing booking insert statement");
                $sql = "INSERT INTO bookings (booking_id, user_id, service_name, service_date, time_slot, service_address, special_notes, subtotal, discount_amount, coupon_code, coupon_discount, total_amount, payment_method, payment_status, razorpay_order_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)";
                
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    throw new Exception("Failed to prepare booking statement: " . $conn->error);
                }
                
                writeLog("Binding parameters for booking");
                // FIXED: 14 parameters total (payment_status is hardcoded, so 13 bind params + 1 hardcoded = 14)
                // But we're binding 14 variables, so we need 14 characters in type string
                $bindResult = $stmt->bind_param("sisssssddsdsss", 
                    $bookingId,        // s - string (1)
                    $userId,           // i - integer (2)
                    $serviceName,      // s - string (3)
                    $serviceDate,      // s - string (4)
                    $timeSlot,         // s - string (5)
                    $serviceAddress,   // s - string (6)
                    $specialNotes,     // s - string (7)
                    $subtotal,         // d - double (8)
                    $discountAmount,   // d - double (9)
                    $couponCode,       // s - string (10)
                    $couponDiscount,   // d - double (11)
                    $totalAmount,      // d - double (12)
                    $paymentMethod,    // s - string (13)
                    $razorpayOrderId   // s - string (14)
                );
                
                if (!$bindResult) {
                    throw new Exception("Failed to bind parameters: " . $stmt->error);
                }
                
                writeLog("Executing booking insert");
                if (!$stmt->execute()) {
                    throw new Exception("Failed to execute booking insert: " . $stmt->error);
                }
                
                writeLog("Booking record inserted successfully");
                $stmt->close();
                
                // Insert booking items
                writeLog("Processing " . count($cartItems) . " cart items");
                $itemSql = "INSERT INTO booking_items (booking_id, service_type_name, room_size, price, quantity, item_total) VALUES (?, ?, ?, ?, ?, ?)";
                $itemStmt = $conn->prepare($itemSql);
                
                if (!$itemStmt) {
                    throw new Exception("Failed to prepare item statement: " . $conn->error);
                }
                
                foreach ($cartItems as $index => $item) {
                    writeLog("Processing item " . ($index + 1) . ": " . ($item['service_type_name'] ?? 'UNKNOWN'));
                    
                    // Store values in variables first
                    $itemServiceType = $item['service_type_name'] ?? '';
                    $itemRoomSize = $item['room_size'] ?? '';
                    $itemPrice = floatval($item['price'] ?? 0);
                    $itemQuantity = intval($item['quantity'] ?? 0);
                    $itemTotal = $itemPrice * $itemQuantity;
                    
                    // Bind with variables
                    $itemBindResult = $itemStmt->bind_param("sssdid",
                        $bookingId,        // s - string
                        $itemServiceType,  // s - string
                        $itemRoomSize,     // s - string  
                        $itemPrice,        // d - double
                        $itemQuantity,     // i - integer
                        $itemTotal         // d - double
                    );
                    
                    if (!$itemBindResult) {
                        throw new Exception("Failed to bind item parameters: " . $itemStmt->error);
                    }
                    
                    if (!$itemStmt->execute()) {
                        throw new Exception("Failed to insert item " . ($index + 1) . ": " . $itemStmt->error);
                    }
                }
                
                $itemStmt->close();
                writeLog("All items inserted successfully");
                
                // Commit transaction
                if (!$conn->commit()) {
                    throw new Exception("Failed to commit transaction: " . $conn->error);
                }
                
                writeLog("=== BOOKING CREATED SUCCESSFULLY ===");
                
                echo json_encode([
                    "status" => "success",
                    "message" => "Booking created successfully",
                    "booking_id" => $bookingId
                ]);
                
            } catch (Exception $e) {
                writeLog("Rolling back transaction due to error: " . $e->getMessage());
                $conn->rollback();
                
                echo json_encode([
                    "status" => "error",
                    "message" => "Database error: " . $e->getMessage()
                ]);
            }
        }
        
        elseif ($action === 'update_payment') {
            writeLog("=== UPDATING PAYMENT STATUS ===");
            
            $bookingId = $data['booking_id'] ?? '';
            $paymentStatus = $data['payment_status'] ?? '';
            $razorpayPaymentId = $data['razorpay_payment_id'] ?? null;
            
            writeLog("Booking ID: $bookingId");
            writeLog("Payment Status: $paymentStatus");
            writeLog("Razorpay Payment ID: $razorpayPaymentId");
            
            // Validate required fields
            if (empty($bookingId)) {
                echo json_encode(["status" => "error", "message" => "Booking ID is required"]);
                exit;
            }
            
            if (empty($paymentStatus)) {
                echo json_encode(["status" => "error", "message" => "Payment status is required"]);
                exit;
            }
            
            try {
                // Check if booking exists and belongs to current user
                writeLog("Checking if booking exists for user");
                $checkStmt = $conn->prepare("SELECT booking_id FROM bookings WHERE booking_id = ? AND user_id = ?");
                $checkStmt->bind_param("si", $bookingId, $userId);
                $checkStmt->execute();
                $checkResult = $checkStmt->get_result();
                
                if ($checkResult->num_rows === 0) {
                    writeLog("Booking not found or doesn't belong to user");
                    echo json_encode(["status" => "error", "message" => "Booking not found"]);
                    exit;
                }
                $checkStmt->close();
                
                // Update payment status
                writeLog("Updating payment status");
                $updateSql = "UPDATE bookings SET payment_status = ?, razorpay_payment_id = ? WHERE booking_id = ? AND user_id = ?";
                $updateStmt = $conn->prepare($updateSql);
                
                if (!$updateStmt) {
                    throw new Exception("Failed to prepare update statement: " . $conn->error);
                }
                
                $updateStmt->bind_param("sssi", $paymentStatus, $razorpayPaymentId, $bookingId, $userId);
                
                if (!$updateStmt->execute()) {
                    throw new Exception("Failed to update payment: " . $updateStmt->error);
                }
                
                $affectedRows = $updateStmt->affected_rows;
                writeLog("Payment update completed. Affected rows: $affectedRows");
                $updateStmt->close();
                
                if ($affectedRows > 0) {
                    echo json_encode([
                        "status" => "success",
                        "message" => "Payment updated successfully",
                        "booking_id" => $bookingId,
                        "payment_status" => $paymentStatus
                    ]);
                } else {
                    echo json_encode([
                        "status" => "warning",
                        "message" => "No rows updated - booking may already have this status"
                    ]);
                }
                
            } catch (Exception $e) {
                writeLog("Payment update error: " . $e->getMessage());
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to update payment: " . $e->getMessage()
                ]);
            }
        }
        
        else {
            writeLog("Unknown POST action requested: " . $action);
            echo json_encode(["status" => "error", "message" => "Unknown action: " . $action]);
        }
    }
    
    else {
        writeLog("Unsupported HTTP method: " . $_SERVER['REQUEST_METHOD']);
        echo json_encode(["status" => "error", "message" => "Method not supported"]);
    }
    
} catch (Exception $e) {
    writeLog("FATAL EXCEPTION: " . $e->getMessage());
    writeLog("Exception file: " . $e->getFile());
    writeLog("Exception line: " . $e->getLine());
    
    echo json_encode([
        "status" => "error",
        "message" => "Server exception: " . $e->getMessage(),
        "file" => basename($e->getFile()),
        "line" => $e->getLine()
    ]);
    
} catch (Error $e) {
    writeLog("FATAL PHP ERROR: " . $e->getMessage());
    writeLog("Error file: " . $e->getFile());
    writeLog("Error line: " . $e->getLine());
    
    echo json_encode([
        "status" => "error",
        "message" => "PHP Fatal Error: " . $e->getMessage(),
        "file" => basename($e->getFile()),
        "line" => $e->getLine()
    ]);
}

writeLog("=== SCRIPT COMPLETED ===");

if (isset($conn)) {
    $conn->close();
}
?>