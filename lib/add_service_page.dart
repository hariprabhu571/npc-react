import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:npc/Urls.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'widgets/add_service_widgets.dart'; // Import the widgets file

class AddServicePage extends StatefulWidget {
  final String serviceName;
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const AddServicePage({
    Key? key,
    required this.serviceName,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _AddServicePageState createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> with TickerProviderStateMixin {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _successController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _successAnimation;

  String _selectedTimeSlot = '';
  DateTime? _selectedDate;
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _hasAddress = false;
  bool _showAddressInput = false;
  bool _isCouponApplied = false;
  double _couponDiscount = 0.0;
  String _appliedCouponCode = '';

  // Razorpay
  late Razorpay _razorpay;
  String? _currentBookingId;

  List<String> _timeSlots = [
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'name': 'Cash on Delivery',
      'icon': Icons.money,
      'subtitle': 'Pay when service is completed'
    },
    {
      'id': 'razorpay',
      'name': 'Pay Online',
      'icon': Icons.credit_card,
      'subtitle': 'Pay securely using Razorpay'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRazorpay();
    _selectedDate = DateTime.now().add(Duration(days: 1));
    _fetchUserAddress();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _successController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchUserAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      final response = await http.get(
        Uri.parse('$ip/book_service_v2.php?action=get_address'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _hasAddress = data['has_address'];
            if (_hasAddress) {
              _addressController.text = data['address'];
            } else {
              _showAddressInput = true;
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _showAddressInput = true;
      });
    }
  }

  Future<void> _updateAddress() async {
    if (_addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      final response = await http.post(
        Uri.parse('$ip/book_service_v2.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'update_address',
          'address': _addressController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _hasAddress = true;
            _showAddressInput = false;
          });
          _showSuccessSnackBar('Address saved successfully');
        } else {
          _showErrorSnackBar(data['message']);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error updating address: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a coupon code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      final orderAmount = _calculateSubtotal();
      final response = await http.get(
        Uri.parse('$ip/book_service_v2.php?action=validate_coupon&coupon_code=${_couponController.text.trim()}&order_amount=$orderAmount'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _isCouponApplied = true;
            _couponDiscount = data['discount_amount'].toDouble();
            _appliedCouponCode = _couponController.text.trim();
          });
          _showSuccessSnackBar(data['message']);
        } else {
          _showErrorSnackBar(data['message']);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error applying coupon: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _isCouponApplied = false;
      _couponDiscount = 0.0;
      _appliedCouponCode = '';
      _couponController.clear();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double _calculateSubtotal() {
    return widget.totalAmount;
  }

  double _calculateDiscount() {
    return _calculateSubtotal() * 0.15; // 15% discount
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _calculateDiscount() - _couponDiscount;
  }

  Future<void> _submitBooking() async {
    // Validations
    if (!_hasAddress && _addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your address');
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a service date');
      return;
    }

    if (_selectedTimeSlot.isEmpty) {
      _showErrorSnackBar('Please select a time slot');
      return;
    }

    if (!_agreedToTerms) {
      _showErrorSnackBar('Please agree to terms and conditions');
      return;
    }

    // Update address if needed
    if (!_hasAddress) {
      await _updateAddress();
      if (!_hasAddress) return;
    }

    if (_selectedPaymentMethod == 'razorpay') {
      _initiateRazorpayPayment();
    } else {
      _createBooking();
    }
  }

  void _initiateRazorpayPayment() {
    var options = {
      'key': 'rzp_test_TGcPYUXCQVm6fX',
      'amount': (_calculateTotal() * 100).toInt(), // Amount in paise
      'name': 'NPC Services',
      'description': widget.serviceName,
      'prefill': {'contact': '', 'email': ''},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _createBooking(
      razorpayPaymentId: response.paymentId,
      razorpayOrderId: response.orderId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorSnackBar('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showErrorSnackBar('External wallet selected: ${response.walletName}');
  }

  Future<void> _createBooking({
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      print('=== CREATE BOOKING REQUEST ===');
      print('Session ID: $sessionId');
      print('Service Name: ${widget.serviceName}');
      print('Selected Date: $_selectedDate');
      print('Selected Time Slot: $_selectedTimeSlot');
      print('Payment Method: $_selectedPaymentMethod');
      print('Razorpay Payment ID: $razorpayPaymentId');
      print('Razorpay Order ID: $razorpayOrderId');

      if (sessionId == null || sessionId.isEmpty) {
        _showErrorSnackBar('Session expired. Please login again.');
        return;
      }

      final bookingData = {
        'action': 'create_booking',
        'service_name': widget.serviceName,
        'service_date': _selectedDate!.toIso8601String().split('T')[0],
        'time_slot': _selectedTimeSlot,
        'service_address': _addressController.text.trim(),
        'special_notes': _notesController.text.trim(),
        'subtotal': _calculateSubtotal(),
        'discount_amount': _calculateDiscount(),
        'coupon_code': _isCouponApplied ? _appliedCouponCode : null,
        'coupon_discount': _couponDiscount,
        'total_amount': _calculateTotal(),
        'payment_method': _selectedPaymentMethod,
        'cart_items': widget.cartItems,
        'razorpay_order_id': razorpayOrderId,
      };

      print('Request Body: ${json.encode(bookingData)}');

      final response = await http.post(
        Uri.parse('$ip/book_service_v2.php'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      print('=== CREATE BOOKING RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      print('Response Length: ${response.body.length}');
      print('Response Body: ${response.body}');

      // Check for empty response
      if (response.body.isEmpty) {
        print('❌ Empty response body');
        _showErrorSnackBar('Server returned empty response');
        return;
      }

      // Check for HTML/PHP errors in response
      if (response.body.contains('<br') ||
          response.body.contains('Fatal error') ||
          response.body.contains('Warning:') ||
          response.body.contains('Notice:') ||
          response.body.contains('<!DOCTYPE')) {
        print('❌ PHP/HTML ERROR DETECTED IN RESPONSE');
        print('Error response: ${response.body}');
        _showErrorSnackBar('Server error detected. Please check server logs.');
        return;
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Parsed Response: $data');

          if (data['status'] == 'success') {
            _currentBookingId = data['booking_id'];
            print('✅ Booking created successfully with ID: $_currentBookingId');

            // Update payment status if razorpay
            if (razorpayPaymentId != null) {
              print('🔄 Updating payment status...');
              await _updatePaymentStatus(razorpayPaymentId);
            }

            _showSuccessAnimation();
          } else {
            print('❌ Booking creation failed: ${data['message']}');
            _showErrorSnackBar(data['message'] ?? 'Booking creation failed');
          }
        } catch (parseError) {
          print('❌ JSON Parse Error: $parseError');
          print('Response that failed to parse: ${response.body}');
          _showErrorSnackBar('Invalid server response format');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        _showErrorSnackBar("Server error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _createBooking: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar("Booking failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePaymentStatus(String razorpayPaymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      print('=== UPDATE PAYMENT STATUS REQUEST ===');
      print('Session ID: $sessionId');
      print('Booking ID: $_currentBookingId');
      print('Razorpay Payment ID: $razorpayPaymentId');

      if (sessionId == null || sessionId.isEmpty) {
        print('❌ Session ID is null or empty');
        return; // Don't show error for payment update failure
      }

      if (_currentBookingId == null || _currentBookingId!.isEmpty) {
        print('❌ Booking ID is null or empty');
        return; // Don't show error for payment update failure
      }

      final requestBody = {
        'action': 'update_payment',
        'booking_id': _currentBookingId,
        'payment_status': 'paid',
        'razorpay_payment_id': razorpayPaymentId,
      };

      print('Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$ip/book_service_v2.php'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('=== UPDATE PAYMENT RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Length: ${response.body.length}');
      print('Response Body: ${response.body}');

      // Check for empty response
      if (response.body.isEmpty) {
        print('❌ Empty response body for payment update');
        return; // Don't fail the booking for payment update issues
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Parsed Payment Response: $data');

          if (data['status'] == 'success') {
            print('✅ Payment status updated successfully');
          } else {
            print('❌ Payment update failed: ${data['message']}');
            // Don't show error to user, booking is still successful
          }
        } catch (parseError) {
          print('❌ Payment update JSON Parse Error: $parseError');
          print('Payment response: ${response.body}');
          // Don't fail the booking for payment update parse errors
        }
      } else {
        print('❌ Payment update HTTP Error: ${response.statusCode}');
      }

    } catch (e, stackTrace) {
      print('❌ Exception in _updatePaymentStatus: $e');
      print('Stack trace: $stackTrace');
      // Don't fail the booking for payment update exceptions
    }
  }




  void _showSuccessAnimation() {
    _successController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Animation
                AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _successAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  'Booking ID: $_currentBookingId',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontFamily: 'sora',
                  ),
                ),

                SizedBox(height: 8),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedPaymentMethod == 'razorpay'
                        ? 'Payment Successful'
                        : 'Cash on Delivery',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'sora',
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Text(
                  'Our team will contact you shortly to confirm the details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'sora',
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'sora',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                title: Text(
                  'Complete Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'sora',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Color(0xFF0F766E),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                elevation: 0,
                pinned: true,
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Order Summary
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildOrderSummary(widget.cartItems),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Address Section
                    if (_showAddressInput || !_hasAddress)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ServiceWidgets.buildAddressSection(
                            _addressController,
                            _hasAddress,
                            _updateAddress,
                          ),
                        ),
                      ),

                    if (_hasAddress && !_showAddressInput) SizedBox(height: 24),

                    // Service Schedule
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildServiceSchedule(
                          _selectedDate,
                          _selectedTimeSlot,
                          _timeSlots,
                          _selectDate,
                              (slot) => setState(() => _selectedTimeSlot = slot),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Coupon Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildCouponSection(
                          _isCouponApplied,
                          _couponController,
                          _appliedCouponCode,
                          _couponDiscount,
                          _applyCoupon,
                          _removeCoupon,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Payment Method
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildPaymentMethod(
                          _paymentMethods,
                          _selectedPaymentMethod,
                              (method) => setState(() => _selectedPaymentMethod = method),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Price Breakdown
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildPriceBreakdown(
                          _calculateSubtotal(),
                          _calculateDiscount(),
                          _isCouponApplied,
                          _couponDiscount,
                          _calculateTotal(),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Special Instructions
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildSpecialInstructions(_notesController),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Terms and Conditions
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ServiceWidgets.buildTermsAndConditions(
                          _agreedToTerms,
                              (value) => setState(() => _agreedToTerms = value),
                        ),
                      ),
                    ),

                    SizedBox(height: 100), // Space for floating button
                  ]),
                ),
              ),
            ],
          ),

          // Floating Book Now Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF065F46)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0F766E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _submitBooking,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          _isLoading ? 'Processing...' : 'Book Now - ₹${_calculateTotal().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'sora',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0F766E)),
                      SizedBox(height: 16),
                      Text(
                        'Processing your booking...',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'sora',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}