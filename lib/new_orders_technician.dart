import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Urls.dart';
import 'login_page.dart';

class TechnicianOrdersPage extends StatefulWidget {
  @override
  _TechnicianOrdersPageState createState() => _TechnicianOrdersPageState();
}

class _TechnicianOrdersPageState extends State<TechnicianOrdersPage> with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  List<Map<String, dynamic>> assignedOrders = [];
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> completedOrders = [];

  List<Map<String, dynamic>> filteredAssignedOrders = [];
  List<Map<String, dynamic>> filteredActiveOrders = [];
  List<Map<String, dynamic>> filteredCompletedOrders = [];

  bool isLoading = true;
  String? sessionId;
  Map<String, dynamic>? technicianInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    searchController.addListener(_filterOrders);
    _initializeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getSessionId();
    await _fetchTechnicianOrders();
  }

  Future<void> _getSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('Session-ID');
  }

  Future<void> _fetchTechnicianOrders() async {
    if (sessionId == null) {
      _showErrorAndRedirectToLogin('Session not found. Please login again.');
      return;
    }

    try {
      print('Making request to: $ip/technician_orders.php');
      print('Session ID: $sessionId');

      final response = await http.get(
        Uri.parse('$ip/technician_orders.php'),
        headers: {
          'Technician-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            technicianInfo = data['technician'];

            // Clear previous data
            assignedOrders.clear();
            activeOrders.clear();
            completedOrders.clear();

            // Categorize orders based on technician status
            for (var booking in (data['bookings'] ?? [])) {
              switch (booking['technician_status']?.toLowerCase()) {
                case 'assigned':
                  assignedOrders.add(booking);
                  break;
                case 'reached':
                case 'started':
                  activeOrders.add(booking);
                  break;
                case 'completed':
                  completedOrders.add(booking);
                  break;
                default:
                  assignedOrders.add(booking);
              }
            }

            // Apply current search filter
            _filterOrders();
            isLoading = false;
          });
        } else {
          _showErrorAndRedirectToLogin(data['message'] ?? 'Failed to fetch orders');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      _showError('Network error. Please check your connection.');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterOrders() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredAssignedOrders = assignedOrders.where((order) {
        return _orderMatchesQuery(order, query);
      }).toList();

      filteredActiveOrders = activeOrders.where((order) {
        return _orderMatchesQuery(order, query);
      }).toList();

      filteredCompletedOrders = completedOrders.where((order) {
        return _orderMatchesQuery(order, query);
      }).toList();
    });
  }

  bool _orderMatchesQuery(Map<String, dynamic> order, String query) {
    if (query.isEmpty) return true;

    return (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
        (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
        (order['booking_id']?.toString()?.contains(query) ?? false) ||
        (order['customer_phone']?.toLowerCase()?.contains(query) ?? false);
  }

  Future<void> _updateOrderStatus(String bookingId, String status, {String? notes}) async {
    if (sessionId == null) {
      _showErrorAndRedirectToLogin('Session expired. Please login again.');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
                ),
                SizedBox(height: 16),
                Text(
                  'Updating status...',
                  style: TextStyle(fontFamily: 'Sora'),
                ),
              ],
            ),
          ),
        ),
      );

      final response = await http.post(
        Uri.parse('$ip/technician_status_update.php'),
        headers: {
          'Technician-ID': sessionId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': bookingId,
          'status': status,
          'notes': notes ?? '',
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showSuccessMessage('Status updated successfully!');
          await _fetchTechnicianOrders(); // Refresh orders
        } else {
          _showError(data['message'] ?? 'Failed to update status');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Error updating status: $e');
      _showError('Network error. Please try again.');
    }
  }

  void _showStatusUpdateDialog(String bookingId, String currentStatus) {
    List<Map<String, String>> availableStatuses = _getAvailableStatuses(currentStatus);

    if (availableStatuses.isEmpty) {
      _showError('No status updates available for this order.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController notesController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Update Status',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order ID: $bookingId',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: TextStyle(fontFamily: 'Sora'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF4A9589)),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...availableStatuses.map((statusInfo) => ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(bookingId, statusInfo['value']!, notes: notesController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A9589),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                statusInfo['display']!,
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _getAvailableStatuses(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'assigned':
        return [{'value': 'reached', 'display': 'Mark as Reached'}];
      case 'reached':
        return [{'value': 'started', 'display': 'Start Work'}];
      case 'started':
        return [{'value': 'completed', 'display': 'Complete Job'}];
      default:
        return [];
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'Assigned';
      case 'reached': return 'Reached';
      case 'started': return 'In Progress';
      case 'completed': return 'Completed';
      default: return 'Unknown';
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Sora'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _openLocationInMap(String? address) async {
    if (address == null || address.isEmpty || address == 'No address provided') {
      _showError('No address available to open in map');
      return;
    }

    try {
      // Encode the address for URL
      final encodedAddress = Uri.encodeComponent(address);

      // Try Google Maps first (more commonly available)
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      final Uri googleMapsUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to device's default map app
        final fallbackUrl = 'geo:0,0?q=$encodedAddress';
        final Uri fallbackUri = Uri.parse(fallbackUrl);

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          _showError('No map application found on device');
        }
      }
    } catch (e) {
      print('Error opening map: $e');
      _showError('Error opening map: $e');
    }
  }
  Future<void> _performLogout() async {
    try {
      // Clear session data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('Session-ID');
      await prefs.remove('role');
      await prefs.remove('session_expiry');

      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );

      _showSuccessMessage('Logged out successfully');
    } catch (e) {
      _showError('Error during logout');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Sora'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Sora'),
        ),
        backgroundColor: Color(0xFF4A9589),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorAndRedirectToLogin(String message) {
    _showError(message);
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.12),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Color(0xFFEAF3EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search, color: Color(0xFF4A9589)),
                              hintText: 'Search orders...',
                              hintStyle: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 14,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      IconButton(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 24,
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Color(0xFF4A9589),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4A9589),
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Assigned (${filteredAssignedOrders.length})'),
              Tab(text: 'Active (${filteredActiveOrders.length})'),
              Tab(text: 'Completed (${filteredCompletedOrders.length})'),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading orders...',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          if (technicianInfo != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4A9589).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF4A9589).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF4A9589),
                    radius: 25,
                    child: Text(
                      (technicianInfo!['employee_name'] ?? 'T')[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${technicianInfo!['employee_name'] ?? 'Technician'}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Total Orders: ${assignedOrders.length + activeOrders.length + completedOrders.length}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A9589),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Online',
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(filteredAssignedOrders, 'assigned'),
                _buildOrderList(filteredActiveOrders, 'active'),
                _buildOrderList(filteredCompletedOrders, 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(type),
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No ${type} orders found',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(type),
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTechnicianOrders,
      color: Color(0xFF4A9589),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildTechnicianOrderCard(orders[index], type);
        },
      ),
    );
  }

  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'assigned': return Icons.assignment_outlined;
      case 'active': return Icons.build_outlined;
      case 'completed': return Icons.check_circle_outline;
      default: return Icons.assignment;
    }
  }

  String _getEmptyStateMessage(String type) {
    switch (type) {
      case 'assigned': return 'New orders will appear here when assigned to you';
      case 'active': return 'Orders you\'re currently working on will appear here';
      case 'completed': return 'Completed orders will appear here';
      default: return '';
    }
  }

  Widget _buildTechnicianOrderCard(Map<String, dynamic> order, String type) {
    double screenWidth = MediaQuery.of(context).size.width;

    String technicianStatus = order['technician_status']?.toLowerCase() ?? 'assigned';

    Color statusColor = _getStatusColor(technicianStatus);
    String statusText = _getStatusDisplayName(technicianStatus);
    IconData statusIcon = _getStatusIcon(technicianStatus);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      margin: EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['booking_id']}',
                  style: TextStyle(
                    color: Color(0xFF2A3C66),
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('Service', order['service_name'] ?? 'Unknown Service'),
                      SizedBox(height: 12),
                      _buildInfoSection('Customer', order['customer_name'] ?? 'Unknown Customer'),
                      SizedBox(height: 12),
                      _buildInfoSection('Phone', order['customer_phone'] ?? 'N/A'),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF4A9589), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Address',
                            style: TextStyle(
                              color: Color(0xFF2A3C66),
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (order['service_address'] != null &&
                              order['service_address'].toString().isNotEmpty &&
                              order['service_address'] != 'No address provided')
                            GestureDetector(
                              onTap: () => _openLocationInMap(order['service_address']),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4A9589),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF4A9589).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.navigation_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'open Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Sora',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        order['service_address'] ?? 'No address provided',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      _buildInfoSection('Date', order['service_date_formatted'] ?? 'N/A'),
                      SizedBox(height: 8),
                      _buildInfoSection('Time', order['time_slot'] ?? 'No time specified'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order['total_amount'] ?? '0'}',
                  style: TextStyle(
                    color: Color(0xFF4A9589),
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
                if (type != 'completed')
                  ElevatedButton(
                    onPressed: () => _showStatusUpdateDialog(
                      order['booking_id'].toString(),
                      technicianStatus,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A9589),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 2,
                    ),
                    child: Text(
                      _getNextActionText(technicianStatus),
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF2A3C66),
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'Sora',
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return Colors.blue;
      case 'reached': return Colors.orange;
      case 'started': return Colors.purple;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return Icons.assignment;
      case 'reached': return Icons.location_on;
      case 'started': return Icons.build;
      case 'completed': return Icons.check_circle;
      default: return Icons.help_outline;
    }
  }

  String _getNextActionText(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'assigned': return 'Mark Reached';
      case 'reached': return 'Start Work';
      case 'started': return 'Complete';
      default: return 'Update Status';
    }
  }
}