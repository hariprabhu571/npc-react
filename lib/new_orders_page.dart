import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianOrdersPage extends StatefulWidget {
  @override
  _TechnicianOrdersPageState createState() => _TechnicianOrdersPageState();
}

class _TechnicianOrdersPageState extends State<TechnicianOrdersPage> with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  TabController? _tabController;

  List<Map<String, dynamic>> newOrders = [];
  List<Map<String, dynamic>> acceptedOrders = [];
  List<Map<String, dynamic>> completedOrders = [];

  List<Map<String, dynamic>> filteredNewOrders = [];
  List<Map<String, dynamic>> filteredAcceptedOrders = [];
  List<Map<String, dynamic>> filteredCompletedOrders = [];

  bool isLoading = true;
  String? technicianId;
  String? technicianName;

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
    await _getTechnicianId();
    await _fetchOrders();
  }

  Future<void> _getTechnicianId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    technicianId = prefs.getString('Technician-ID');
    technicianName = prefs.getString('Technician-Name');
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://yourapi.com/technician_orders.php'),
        headers: {
          'Technician-ID': technicianId ?? '',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['orders'] != null) {
          setState(() {
            newOrders = List<Map<String, dynamic>>.from(data['orders']['new'] ?? []);
            acceptedOrders = List<Map<String, dynamic>>.from(data['orders']['accepted'] ?? []);
            completedOrders = List<Map<String, dynamic>>.from(data['orders']['completed'] ?? []);

            filteredNewOrders = newOrders;
            filteredAcceptedOrders = acceptedOrders;
            filteredCompletedOrders = completedOrders;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print('No orders found: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterOrders() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredNewOrders = newOrders.where((order) {
        return (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();

      filteredAcceptedOrders = acceptedOrders.where((order) {
        return (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();

      filteredCompletedOrders = completedOrders.where((order) {
        return (order['customer_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['service_name']?.toLowerCase()?.contains(query) ?? false) ||
            (order['booking_id']?.toString()?.contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _acceptOrder(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('https://yourapi.com/technician_accept_order.php'),
        headers: {
          'Technician-ID': technicianId ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': bookingId,
          'action': 'accept',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchOrders(); // Refresh orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to accept order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('https://yourapi.com/technician_accept_order.php'),
        headers: {
          'Technician-ID': technicianId ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': bookingId,
          'action': 'reject',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          await _fetchOrders(); // Refresh orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to reject order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(String bookingId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://yourapi.com/technician_status_update.php'),
        headers: {
          'Technician-ID': technicianId ?? '',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': bookingId,
          'status': status,
          'notes': 'Status updated by technician',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $status'),
              backgroundColor: Color(0xFF4A9589),
            ),
          );
          await _fetchOrders(); // Refresh orders
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to update status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog(String bookingId, String currentStatus) {
    List<String> statusOptions = [];

    switch (currentStatus) {
      case 'assigned':
        statusOptions = ['reached'];
        break;
      case 'reached':
        statusOptions = ['started'];
        break;
      case 'started':
        statusOptions = ['completed'];
        break;
      default:
        statusOptions = [];
    }

    if (statusOptions.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Update Status',
            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOptions.map((status) => ListTile(
              title: Text(
                status.toUpperCase(),
                style: TextStyle(fontFamily: 'Sora'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _updateOrderStatus(bookingId, status);
              },
            )).toList(),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(fontFamily: 'Sora')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: screenHeight * 0.05,
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
                          fontFamily: 'sora',
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF4A9589)),
                  onPressed: _fetchOrders,
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
              Tab(text: 'New (${filteredNewOrders.length})'),
              Tab(text: 'Accepted (${filteredAcceptedOrders.length})'),
              Tab(text: 'Completed (${filteredCompletedOrders.length})'),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
        ),
      )
          : Column(
        children: [
          if (technicianName != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Welcome, $technicianName',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontFamily: 'sora',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(filteredNewOrders, 'new'),
                _buildOrderList(filteredAcceptedOrders, 'accepted'),
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
              Icons.work_outline,
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
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return buildOrderCard(context, orders[index], type);
        },
      ),
    );
  }

  Widget buildOrderCard(BuildContext context, Map<String, dynamic> order, String type) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      color: Color(0xFF4A9589).withOpacity(0.09),
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking ID and service name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['booking_id']}',
                  style: TextStyle(
                    color: Color(0xFF2A3C66),
                    fontFamily: 'sora',
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.038,
                  ),
                ),
                if (type == 'accepted' && order['technician_status'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['technician_status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['technician_status'].toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order['technician_status']),
                        fontFamily: 'sora',
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              order['service_name'] ?? 'Unknown Service',
              style: TextStyle(
                color: Color(0xFF4A9589),
                fontFamily: 'sora',
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Name',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        order['customer_name'] ?? 'Unknown',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.037,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Mobile No',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        order['customer_phone'] ?? 'N/A',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Slot & Date',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        '${order['service_date_formatted']} - ${order['time_slot'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF2A3C66), size: 20),
                          SizedBox(width: 1),
                          Text(
                            'Address',
                            style: TextStyle(
                              color: Color(0xFF2A3C66),
                              fontFamily: 'sora',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.032,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                      Text(
                        order['service_address'] ?? 'No address',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        order['customer_email'] ?? '',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        '₹${order['total_amount'] ?? '0'}',
                        style: TextStyle(
                          color: Color(0xFF4A9589),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildActionButtons(order, type),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order, String type) {
    switch (type) {
      case 'new':
        return Row(
          children: [
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order['booking_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 2),
                  minimumSize: Size(10, 30),
                ),
                child: Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0AA048),
                    fontFamily: 'sora',
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () => _rejectOrder(order['booking_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 2),
                  minimumSize: Size(10, 30),
                ),
                child: Text(
                  'Reject',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA0280A),
                    fontFamily: 'sora',
                  ),
                ),
              ),
            ),
            Spacer(),
            _buildViewDetailsButton(order),
          ],
        );

      case 'accepted':
        return Row(
          children: [
            if (order['technician_status'] != 'completed')
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => _showStatusUpdateDialog(
                    order['booking_id'],
                    order['technician_status'] ?? 'assigned',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A9589),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'sora',
                    ),
                  ),
                ),
              ),
            Spacer(),
            _buildViewDetailsButton(order),
          ],
        );

      default:
        return Row(
          children: [
            Spacer(),
            _buildViewDetailsButton(order),
          ],
        );
    }
  }

  Widget _buildViewDetailsButton(Map<String, dynamic> order) {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to order details page
          _showOrderDetails(order);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 4),
          minimumSize: Size(10, 30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye, color: Color(0xFF2A3C66), size: 18),
            SizedBox(width: 4),
            Text(
              'View Details',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2A3C66),
                fontFamily: 'sora',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Order Details',
            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Order ID', order['booking_id']),
                _buildDetailRow('Service', order['service_name']),
                _buildDetailRow('Customer', order['customer_name']),
                _buildDetailRow('Phone', order['customer_phone']),
                _buildDetailRow('Email', order['customer_email']),
                _buildDetailRow('Date', order['service_date_formatted']),
                _buildDetailRow('Time', order['time_slot']),
                _buildDetailRow('Address', order['service_address']),
                _buildDetailRow('Amount', '₹${order['total_amount']}'),
                if (order['special_notes'] != null && order['special_notes'].isNotEmpty)
                  _buildDetailRow('Notes', order['special_notes']),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(fontFamily: 'Sora')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'reached':
        return Colors.orange;
      case 'started':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}