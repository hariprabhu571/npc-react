import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:npc/Urls.dart';
import 'add_service_page.dart';

class ChooseYourSpace extends StatefulWidget {
  final String serviceName;
  final String? serviceImage;
  final String? serviceDescription;

  const ChooseYourSpace({
    Key? key,
    required this.serviceName,
    this.serviceImage,
    this.serviceDescription,
  }) : super(key: key);

  @override
  _ChooseYourSpaceState createState() => _ChooseYourSpaceState();
}

class _ChooseYourSpaceState extends State<ChooseYourSpace> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _serviceTypes = [];
  Map<String, List<Map<String, dynamic>>> _cartItems = {};
  int _totalCartItems = 0;
  double _totalAmount = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchServiceTypes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");
      print(sessionId);

      if (sessionId == null) {
        _showErrorSnackBar("Session ID not found. Please login again.");
        return;
      }

      final response = await http.get(
        Uri.parse('$ip/get_user_service_details.php?service_name=${widget.serviceName}'),

        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _serviceTypes = List<Map<String, dynamic>>.from(data['data']);
          });
          _animationController.forward();
        } else {
          _showErrorSnackBar("Error: ${data['message']}");
        }
      } else {
        _showErrorSnackBar("Failed to fetch service types. Status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addToCart(Map<String, dynamic> serviceType, Map<String, dynamic> pricingOption) {
    setState(() {
      String key = "${serviceType['service_type_name']}_${pricingOption['room_size']}";

      if (_cartItems.containsKey(key)) {
        _cartItems[key]![0]['quantity']++;
      } else {
        _cartItems[key] = [{
          'service_type_name': serviceType['service_type_name'],
          'room_size': pricingOption['room_size'],
          'price': double.parse(pricingOption['price'].toString()),
          'quantity': 1,
          'service_name': widget.serviceName,
        }];
      }

      _updateCartTotals();
    });

    _showSuccessSnackBar("${pricingOption['room_size']} added to cart!");
  }

  void _removeFromCart(String key) {
    setState(() {
      if (_cartItems.containsKey(key)) {
        if (_cartItems[key]![0]['quantity'] > 1) {
          _cartItems[key]![0]['quantity']--;
        } else {
          _cartItems.remove(key);
        }
        _updateCartTotals();
      }
    });
  }

  void _updateCartTotals() {
    _totalCartItems = 0;
    _totalAmount = 0.0;

    _cartItems.forEach((key, items) {
      for (var item in items) {
        _totalCartItems += item['quantity'] as int;
        _totalAmount += (item['price'] as double) * (item['quantity'] as int);
      }
    });
  }

  int _getItemQuantity(String serviceTypeName, String roomSize) {
    String key = "${serviceTypeName}_${roomSize}";
    return _cartItems[key]?[0]['quantity'] ?? 0;
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar("Please add items to cart before proceeding");
      return;
    }

    List<Map<String, dynamic>> cartItemsList = [];
    _cartItems.forEach((key, items) {
      cartItemsList.addAll(items);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServicePage(
          serviceName: widget.serviceName,
          cartItems: cartItemsList,
          totalAmount: _totalAmount,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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
        backgroundColor: Color(0xFF0F766E),
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
              // App Bar with Service Header
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: Color(0xFF0F766E),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // IconButton(
                  //   icon: Icon(Icons.share, color: Colors.white),
                  //   onPressed: () {
                  //     // Share functionality
                  //   },
                  // ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F766E),
                          Color(0xFF134E4A),
                          Color(0xFF065F46),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Service Area: Chennai',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'sora',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                widget.serviceName,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'sora',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.serviceDescription ?? "Professional ${widget.serviceName.toLowerCase()} service for your space",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'sora',
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('4.8', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                        Icon(Icons.star, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Save 15% Today',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'sora',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Section
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: _isLoading
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F766E),
                            strokeWidth: 4,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Loading service options...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontFamily: 'sora',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : _serviceTypes.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "No service options available",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            fontFamily: 'sora',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "We're working on adding options for this service",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontFamily: 'sora',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == 0) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Your Space Type',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'sora',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Select the space type and size that matches your needs',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                  fontFamily: 'sora',
                                ),
                              ),
                              SizedBox(height: 24),
                            ],
                          ),
                        );
                      }

                      final serviceType = _serviceTypes[index - 1];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildServiceTypeCard(serviceType),
                      );
                    },
                    childCount: _serviceTypes.length + 1,
                  ),
                ),
              ),

              // Bottom spacing for cart
              SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ),
            ],
          ),

          // Floating Cart Button
          if (_totalCartItems > 0)
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
                    onTap: _proceedToCheckout,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_totalCartItems ${_totalCartItems == 1 ? 'item' : 'items'} in cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'sora',
                                  ),
                                ),
                                Text(
                                  '₹${_totalAmount.toStringAsFixed(0)}',
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
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Proceed',
                              style: TextStyle(
                                color: Color(0xFF0F766E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'sora',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: 150,)
        ],
      ),
    );
  }

  Widget _buildServiceTypeCard(Map<String, dynamic> serviceType) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Type Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F766E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_work,
                    color: Color(0xFF0F766E),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceType['service_type_name'] ?? 'Service Type',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'sora',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose your space size',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'sora',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pricing Options
          if (serviceType['pricing'] != null && serviceType['pricing'].isNotEmpty)
            ...List.generate(
              serviceType['pricing'].length,
                  (index) => _buildPricingOption(
                serviceType,
                serviceType['pricing'][index],
                index == serviceType['pricing'].length - 1,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No pricing options available',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontFamily: 'sora',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingOption(
      Map<String, dynamic> serviceType,
      Map<String, dynamic> pricingOption,
      bool isLast,
      ) {
    final quantity = _getItemQuantity(
      serviceType['service_type_name'],
      pricingOption['room_size'],
    );

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pricingOption['room_size'] ?? 'Room Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'sora',
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${pricingOption['price'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                          fontFamily: 'sora',
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'per service',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'sora',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            quantity > 0
                ? Container(
              decoration: BoxDecoration(
                color: Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _removeFromCart(
                      "${serviceType['service_type_name']}_${pricingOption['room_size']}",
                    ),
                    icon: Icon(Icons.remove, color: Colors.white, size: 18),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sora',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addToCart(serviceType, pricingOption),
                    icon: Icon(Icons.add, color: Colors.white, size: 18),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            )
                : ElevatedButton(
              onPressed: () => _addToCart(serviceType, pricingOption),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'sora',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}