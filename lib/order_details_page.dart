import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Urls.dart';

class AdminOrderPage extends StatefulWidget {
  @override
  _AdminOrderPageState createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  List<Map<String, dynamic>> pendingOrders = [];
  List<Map<String, dynamic>> completedOrders = [];
  List<Map<String, dynamic>> acceptedOrders = [];
  List<Map<String, dynamic>> technicians = [];

  List<Map<String, dynamic>> filteredPendingOrders = [];
  List<Map<String, dynamic>> filteredCompletedOrders = [];
  List<Map<String, dynamic>> filteredAcceptedOrders = [];

  bool isLoading = true;
  String? sessionId;

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
    await _fetchTechnicians();
    await _fetchOrders();
  }

  Future<void> _getSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('Session-ID');
  }

  Future<void> _fetchTechnicians() async {
    try {
      final response = await http.get(
        Uri.parse('$ip/get_technicianss.php'),
        headers: {
          'Session-ID': sessionId ?? '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['technicians'] != null) {
          setState(() {
            technicians = List<Map<String, dynamic>>.from(data['technicians']);
          });
        } else {
          setState(() {
            technicians = [];
          });
          print('No technicians found or invalid response: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setState(() {
          technicians = [];
        });
        print('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        technicians = [];
      });
      print('Error fetching technicians: $e');
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$ip/admin_orders.php'),
        headers: {
          'Session-ID': sessionId ?? '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['orders'] != null) {
          setState(() {
            pendingOrders = List<Map<String, dynamic>>.from(data['orders']['pending'] ?? []);
            completedOrders = List<Map<String, dynamic>>.from(data['orders']['completed'] ?? []);
            acceptedOrders = List<Map<String, dynamic>>.from(data['orders']['accepted'] ?? []);

            filteredPendingOrders = pendingOrders;
            filteredCompletedOrders = completedOrders;
            filteredAcceptedOrders = acceptedOrders;
            isLoading = false;
          });
        } else {
          setState(() {
            pendingOrders = [];
            completedOrders = [];
            acceptedOrders = [];
            filteredPendingOrders = [];
            filteredCompletedOrders = [];
            filteredAcceptedOrders = [];
            isLoading = false;
          });
          print('No orders found or invalid response: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setState(() {
          pendingOrders = [];
          completedOrders = [];
          acceptedOrders = [];
          filteredPendingOrders = [];
          filteredCompletedOrders = [];
          filteredAcceptedOrders = [];
          isLoading = false;
        });
        print('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        pendingOrders = [];
        completedOrders = [];
        acceptedOrders = [];
        filteredPendingOrders = [];
        filteredCompletedOrders = [];
        filteredAcceptedOrders = [];
        isLoading = false;
      });
    }
  }

  void _filterOrders() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPendingOrders = pendingOrders.where((order) {
        return (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();

      filteredCompletedOrders = completedOrders.where((order) {
        return (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();

      filteredAcceptedOrders = acceptedOrders.where((order) {
        return (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _showTechnicianAssignDialog(Map<String, dynamic> order) async {
    // Check if technicians list is empty
    if (technicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No technicians available. Please add technicians first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Assign Technician',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order ID: ${order['booking_id']}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Service: ${order['service_name']}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Select Technician:',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  height: 200,
                  child: technicians.isEmpty
                      ? Center(
                    child: Text(
                      'No technicians available',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      final technician = technicians[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF4A9589),
                            child: Text(
                              (technician['employee_name'] ?? 'T')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            technician['employee_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            technician['phone_number'] ?? 'No phone',
                            style: TextStyle(fontFamily: 'Sora'),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _assignTechnician(
                              order['booking_id'].toString(),
                              technician['technician_id'].toString(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.grey[600],
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignTechnician(String bookingId, String technicianId) async {
    try {
      final response = await http.post(
        Uri.parse('$ip/assign_technicians.php'),
        headers: {
          'Session-ID': sessionId ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': bookingId,
          'technician_id': technicianId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Technician assigned successfully!'),
              backgroundColor: Color(0xFF4A9589),
            ),
          );
          await _fetchOrders(); // Refresh orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to assign technician'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error assigning technician: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning technician'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A9589).withOpacity(0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4A9589)),
                      hintText: 'Search orders...',
                      hintStyle: TextStyle(
                        fontFamily: 'sora',
                        fontSize: 14,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF4A9589),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF4A9589),
          labelStyle: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Pending (${filteredPendingOrders.length})'),
            Tab(text: 'Accepted (${filteredAcceptedOrders.length})'),
            Tab(text: 'Completed (${filteredCompletedOrders.length})'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(filteredPendingOrders, 'pending'),
          _buildOrderList(filteredAcceptedOrders, 'accepted'),
          _buildOrderList(filteredCompletedOrders, 'completed'),
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
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No ${type} orders found',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: Color(0xFF4A9589),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], type);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
    double screenWidth = MediaQuery.of(context).size.width;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (type) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['booking_id']}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2A3C66),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              order['service_name'] ?? 'Unknown Service',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  order['customer_name'] ?? 'Unknown Customer',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['service_address'] ?? 'No address provided',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${order['service_date']} • ${order['time_slot'] ?? 'No time specified'}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (order['assigned_technician_name'] != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4A9589).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build, size: 16, color: Color(0xFF4A9589)),
                    SizedBox(width: 4),
                    Text(
                      'Assigned: ${order['assigned_technician_name']}',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A9589),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order['total_amount'] ?? '0'}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A9589),
                  ),
                ),
                if (type == 'pending')
                  ElevatedButton(
                    onPressed: () => _showTechnicianAssignDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A9589),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Accept & Assign',
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
}