import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'choose_your_space.dart';
import 'package:npc/Urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _searchQuery = "";
  String _selectedLocation = "";
  bool _isLoading = false;
  bool _isLoadingOffers = false;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _offers = [];
  List<String> _locationSuggestions = [];
  bool _showLocationDropdown = false;

  GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  late TabController _tabController;

  // Sample city suggestions (same as web app)
  final List<String> _citySuggestions = [
    'Chennai',
    'Coimbatore',
    'Erode',
    'Salem',
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Surat',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Pimpri-Chinchwad',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan-Dombivali',
    'Vasai-Virar',
    'Varanasi',
    'Srinagar',
    'Aurangabad',
    'Dhanbad',
    'Amritsar',
    'Allahabad',
    'Ranchi',
    'Howrah',
    'Jabalpur',
    'Gwalior',
    'Vijayawada',
    'Jodhpur',
    'Madurai'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchServices();
    _fetchOffers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _searchController.clear();
        _searchQuery = "";
      }
      if (_tabController.index == 1) {
        _fetchOffers();
      }
    });
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");
      print('Fetching services with session: $sessionId');

      if (sessionId == null) {
        _showErrorSnackBar("Session ID not found. Please login again.");
        return;
      }

      final response = await http.get(
        Uri.parse(ip + "fetch_services.php"),
        headers: {'Session-ID': sessionId, "Content-Type": "application/json"},
      );

      print('Services response: ${response.statusCode}');
      print('Services body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _services = List<Map<String, dynamic>>.from(data['services'] ?? []);
          });
        } else {
          _showErrorSnackBar("Error: ${data['message']}");
        }
      } else {
        _showErrorSnackBar(
            "Failed to fetch services. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Services error: $e');
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");
      print('Fetching offers with session: $sessionId');

      if (sessionId == null) {
        _showErrorSnackBar("Session ID not found. Please login again.");
        return;
      }

      final response = await http.get(
        Uri.parse(ip + "fetch_all_offers.php"),
        headers: {'Session-ID': sessionId, "Content-Type": "application/json"},
      );

      print('Offers response: ${response.statusCode}');
      print('Offers body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _offers = List<Map<String, dynamic>>.from(data['offers'] ?? []);
          });
          print('Offers loaded: ${_offers.length}');
        } else {
          _showErrorSnackBar("Error: ${data['message']}");
        }
      } else {
        _showErrorSnackBar(
            "Failed to fetch offers. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Offers error: $e');
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  void _filterServices(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: TextStyle(fontSize: 14, fontFamily: 'Sora')),
          backgroundColor: Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    List<Map<String, dynamic>> filteredServices = _services;
    List<Map<String, dynamic>> filteredOffers = _offers;

    if (_searchQuery.isNotEmpty) {
      filteredServices = _services
          .where((service) => service['service_name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery))
          .toList();

      filteredOffers = _offers
          .where((offer) => offer['offer_name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery))
          .toList();
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          if (_tabController.index == 0) {
            await _fetchServices();
          } else {
            await _fetchOffers();
          }
        },
        color: Color(0xFF0F766E),
        child: SafeArea(
          child: Column(
            children: [
              // Fixed Header
              _buildFixedHeader(screenWidth),

              // Fixed Tab Bar
              _buildFixedTabBar(screenWidth),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServicesTab(filteredServices, screenWidth),
                    _buildOffersTab(filteredOffers, screenWidth),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeader(double screenWidth) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          // Header content
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Icon(Icons.pest_control,
                    color: Colors.white, size: screenWidth * 0.07),
                SizedBox(width: 12),
                Text(
                  "NPC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sora',
                  ),
                ),
                Spacer(),
                Text(
                  "Professional Services",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: screenWidth * 0.035,
                    fontFamily: 'Sora',
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontFamily: 'Sora',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.search, color: Color(0xFF6B7280), size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _filterServices("");
                            FocusScope.of(context).unfocus();
                          },
                          child: Icon(Icons.clear,
                              color: Color(0xFF6B7280), size: 20),
                        )
                      : null,
                  hintText: "Search services or offers...",
                  hintStyle: TextStyle(
                    fontFamily: 'Sora',
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: _filterServices,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedTabBar(double screenWidth) {
    // Responsive sizing
    double fontSize = screenWidth < 350 ? 12 : (screenWidth < 400 ? 14 : 16);
    double iconSize = screenWidth < 350 ? 14 : (screenWidth < 400 ? 16 : 18);
    double horizontalPadding =
        screenWidth < 350 ? 8 : (screenWidth < 400 ? 12 : 16);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF0F766E).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xFF64748B),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicatorPadding: EdgeInsets.all(3),
          labelPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          labelStyle: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
          tabs: [
            Container(
              height: 39,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build, size: iconSize),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "Services",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 39,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer, size: iconSize),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "Offers",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab(
      List<Map<String, dynamic>> services, double screenWidth) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0F766E),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              "Loading services...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.pest_control_outlined
                    : Icons.search_off,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? "No services available"
                  : "No services match your search",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Sora',
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? "We're working on adding more services for you"
                  : "Try searching with different keywords",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Sora',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(service, screenWidth);
      },
    );
  }

  Widget _buildOffersTab(
      List<Map<String, dynamic>> offers, double screenWidth) {
    if (_isLoadingOffers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0F766E),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              "Loading offers...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
      );
    }

    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? "No offers available"
                  : "No offers match your search",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Sora',
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? "Check back soon for exciting deals!"
                  : "Try searching with different keywords",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Sora',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _buildOfferCard(offer, screenWidth);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, double screenWidth) {
    bool isHighlighted = _searchQuery.isNotEmpty &&
        service['service_name'].toString().toLowerCase().contains(_searchQuery);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChooseYourSpace(
            serviceName: service['service_name'].toString(),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? Color(0xFF0F766E).withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: isHighlighted
              ? Border.all(color: Color(0xFF0F766E), width: 2)
              : Border.all(color: Color(0xFFE2E8F0), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFE2E8F0),
                      ],
                    ),
                  ),
                  child: service['image_path'] != null &&
                          service['image_path'].toString().isNotEmpty
                      ? Image.network(
                          ip + service['image_path'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0F766E).withOpacity(0.1),
                                    Color(0xFF065F46).withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.pest_control,
                                size: 48,
                                color: Color(0xFF0F766E).withOpacity(0.6),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0F766E).withOpacity(0.1),
                                Color(0xFF065F46).withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.pest_control,
                            size: 48,
                            color: Color(0xFF0F766E).withOpacity(0.6),
                          ),
                        ),
                ),
              ),

              // Service Details
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['service_name'] ?? "Unknown Service",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Sora',
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          service['description'] ??
                              "Professional service for your needs",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Sora',
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Book Now Button at the bottom
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF0F766E).withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "Book Now",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, double screenWidth) {
    final bool isActive = offer['status'] == 'Active';
    final String offerName = offer['offer_name'] ?? "Special Offer";
    final String couponNumber = offer['coupon_number'] ?? "";
    final String expiresOn = offer['expires_on'] ?? "";
    final String offerPercentage = offer['offer_percentage'] != null
        ? "${offer['offer_percentage']}%"
        : "";

    String formattedExpiry = "";
    if (expiresOn.isNotEmpty) {
      try {
        final DateTime expiryDate = DateTime.parse(expiresOn);
        formattedExpiry =
            "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
      } catch (e) {
        formattedExpiry = expiresOn;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              isActive ? Color(0xFF0F766E).withOpacity(0.2) : Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Color(0xFF0F766E).withOpacity(0.1)
                            : Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: isActive ? Color(0xFF0F766E) : Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Sora',
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          if (offerPercentage.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isActive
                                      ? [Color(0xFF0F766E), Color(0xFF065F46)]
                                      : [Color(0xFF6B7280), Color(0xFF4B5563)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$offerPercentage OFF",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Sora',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Details row
                if (couponNumber.isNotEmpty || formattedExpiry.isNotEmpty)
                  Row(
                    children: [
                      if (couponNumber.isNotEmpty) ...[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 14,
                                  color: Color(0xFF0F766E),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Code: ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Sora',
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    couponNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Sora',
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                      if (formattedExpiry.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Color(0xFFFEF3C7)
                                : Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? Color(0xFFFCD34D)
                                  : Color(0xFFFCA5A5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: isActive
                                    ? Color(0xFFD97706)
                                    : Color(0xFFDC2626),
                              ),
                              SizedBox(width: 4),
                              Text(
                                isActive ? "Till $formattedExpiry" : "Expired",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Sora',
                                  color: isActive
                                      ? Color(0xFFD97706)
                                      : Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                if (isActive) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle apply offer
                        print('Apply offer: $offerName');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Color(0xFF0F766E).withOpacity(0.3),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.redeem, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Apply Offer",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [Color(0xFF10B981), Color(0xFF059669)]
                      : [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Color(0xFF10B981) : Color(0xFFEF4444))
                        .withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 3),
                  Text(
                    isActive ? "ACTIVE" : "EXPIRED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Sora',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner image if available
          if (offer['offer_banner_location'] != null &&
              offer['offer_banner_location'].toString().isNotEmpty)
            Positioned(
              top: 16,
              right: 60,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    ip + offer['offer_banner_location'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_offer,
                        color: Color(0xFF0F766E),
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
