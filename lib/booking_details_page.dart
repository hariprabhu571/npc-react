import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Urls.dart';

class BookingHistoryPage extends StatefulWidget {
  @override
  _BookingHistoryPageState createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  String errorMessage = '';

  Map<String, dynamic>? userBookings;
  List<dynamic> activeBookings = [];
  List<dynamic> completedBookings = [];
  List<dynamic> cancelledBookings = [];

  static String baseUrl = '$ip'; // Using your Urls.dart

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('Session-ID');

      if (sessionId == null || sessionId.isEmpty) {
        setState(() {
          errorMessage = 'No active session found. Please login again.';
          isLoading = false;
        });
        return;
      }

      print('🔍 Fetching bookings for session: $sessionId');

      final response = await http.get(
        Uri.parse('$baseUrl/user-bookings.php?session_id=$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // Check if response contains error
          if (data['error'] != null) {
            setState(() {
              errorMessage = data['error'];
              isLoading = false;
            });
            return;
          }

          setState(() {
            userBookings = data;
            activeBookings = List.from(data['bookings']?['active'] ?? []);
            completedBookings = List.from(data['bookings']?['completed'] ?? []);
            cancelledBookings = List.from(data['bookings']?['cancelled'] ?? []);
            isLoading = false;
          });

          print('✅ Bookings loaded successfully:');
          print('   Active: ${activeBookings.length}');
          print('   Completed: ${completedBookings.length}');
          print('   Cancelled: ${cancelledBookings.length}');

        } catch (e) {
          print('❌ JSON Parse Error: $e');
          setState(() {
            errorMessage = 'Failed to parse server response';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Network Error: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('Session-ID');

      if (sessionId == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user-bookings.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'session_id': sessionId,
          'action': 'cancel',
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['error']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          fetchUserBookings(); // Refresh the data
        }
      } else {
        final responseData = json.decode(response.body);
        String errorMessage = 'Failed to cancel booking: ${response.statusCode}';

        if (responseData['error'] != null) {
          errorMessage = responseData['error'];

          // Show additional details if available
          if (responseData['message'] != null) {
            errorMessage += '\n${responseData['message']}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Booking History',
          style: TextStyle(
            fontFamily: 'sora',
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),

        bottom: userBookings != null
            ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Active (${activeBookings.length})'),
              Tab(text: 'Completed (${completedBookings.length})'),
              Tab(text: 'Cancelled (${cancelledBookings.length})'),
            ],
          ),
        )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchUserBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          // User Summary Card
          _buildSummaryCard(),

          // Address Section
          _buildAddressSection(),

          // Bookings Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(activeBookings, 'active'),
                _buildBookingsList(completedBookings, 'completed'),
                _buildBookingsList(cancelledBookings, 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (userBookings == null) return const SizedBox.shrink();

    final summary = userBookings!['summary'] ?? {};
    final user = userBookings!['user'] ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user['name'] ?? 'User'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Bookings',
                  '${summary['total_bookings'] ?? 0}',
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Spent',
                  '₹${summary['total_spent'] ?? 0}',
                  Icons.payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    if (userBookings == null) return const SizedBox.shrink();

    final user = userBookings!['user'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user['address']?.toString().trim().isNotEmpty == true
                      ? user['address']
                      : 'No address provided',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              // IconButton(
              //   icon: const Icon(Icons.edit, size: 20),
              //   onPressed: () {
              //     // TODO: Navigate to edit address page
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<dynamic> bookings, String type) {
    if (bookings.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (type) {
        case 'active':
          emptyIcon = Icons.schedule;
          emptyMessage = 'Your Pending, Confirmed and In-Progress bookings will appear here';
          break;
        case 'completed':
          emptyIcon = Icons.check_circle;
          emptyMessage = 'Your Completed services will appear here';
          break;
        case 'cancelled':
          emptyIcon = Icons.cancel;
          emptyMessage = 'Your Cancelled bookings will appear here';
          break;
        default:
          emptyIcon = Icons.list;
          emptyMessage = 'No bookings found';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchUserBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];

          // Check if this booking can be cancelled based on API response
          final canCancel = booking['can_cancel'] == true;

          return ProfessionalBookingCard(
            booking: booking,
            onCancel: canCancel ? () => _showCancelDialog(booking) : null,
            onViewDetails: () => _showBookingDetails(booking),
          );
        },
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    final status = booking['status']?.toString().toLowerCase() ?? '';
    final serviceName = booking['service_name']?.toString() ?? 'this booking';

    // Double-check that cancellation is allowed
    if (!['pending', 'confirmed', 'in_progress'].contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot cancel ${status.toUpperCase()} bookings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Cancel Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel "$serviceName"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will change the status to "Rejected" and cannot be undone.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cancelBooking(booking['booking_id'].toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingDetailsSheet(booking: booking),
    );
  }

  // Keep all your existing helper methods (_buildSectionTitle, _buildInfoCard, etc.)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Item Total', '₹${booking['item_total'] ?? 0}', false),
          _buildPaymentRow('Taxes & Fees', '₹${booking['taxes'] ?? 0}', false),
          const Divider(height: 24, thickness: 2),
          _buildPaymentRow('Total Amount', '₹${booking['total_amount'] ?? 0}', true),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep your existing ProfessionalBookingCard and BookingDetailsSheet classes exactly as they are
class ProfessionalBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;

  const ProfessionalBookingCard({
    Key? key,
    required this.booking,
    this.onCancel,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString().toLowerCase() ?? 'unknown';

    // Safe color parsing with fallback
    Color statusColor;
    try {
      final colorString = booking['status_color']?.toString() ?? '#9E9E9E';
      statusColor = Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      statusColor = Colors.grey; // Fallback color
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${booking['booking_id'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: booking['service_image'] != null &&
                      booking['service_image'].toString().isNotEmpty
                      ? Image.network(
                    booking['service_image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.home_repair_service, color: Colors.grey),
                  ),
                ),

                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['service_name']?.toString() ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildDetailRow('Space:', booking['space_type']?.toString() ?? 'N/A'),
                      _buildDetailRow('Service Date:', booking['service_date_formatted']?.toString() ?? 'N/A'),
                      _buildDetailRow('Item Total:', '₹${booking['item_total'] ?? 0}'),
                      _buildDetailRow('Taxes:', '₹${booking['taxes'] ?? 0}'),

                      const Divider(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${booking['total_amount'] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
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

          // Action Buttons
          if (onCancel != null || onViewDetails != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (onViewDetails != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        child: const Text('View Details'),
                      ),
                    ),
                  if (onCancel != null && onViewDetails != null)
                    const SizedBox(width: 12),
                  if (onCancel != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Keep your existing BookingDetailsSheet class exactly as it is
class BookingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsSheet({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking['service_name']?.toString() ?? 'Service Details',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Service Image
                      if (booking['service_image'] != null &&
                          booking['service_image'].toString().isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(booking['service_image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Booking Information
                      _buildSectionTitle('Booking Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow('Booking ID', '#${booking['booking_id'] ?? 'N/A'}'),
                        _buildInfoRow('Status', booking['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
                        _buildInfoRow('Booking Date', booking['booking_date_formatted']?.toString() ?? 'N/A'),
                        _buildInfoRow('Service Date', booking['service_date_formatted']?.toString() ?? 'N/A'),
                        _buildInfoRow('Space Type', booking['space_type']?.toString() ?? 'N/A'),
                      ]),

                      const SizedBox(height: 24),

                      // Service Details
                      _buildSectionTitle('Service Details'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow('Service', booking['service_name']?.toString() ?? 'N/A'),
                        _buildInfoRow('Category', booking['category']?.toString() ?? 'Home Service'),
                        if (booking['service_description'] != null &&
                            booking['service_description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking['service_description'].toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // Address Information
                      _buildSectionTitle('Service Address'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking['address']?.toString() ?? 'No address provided',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        if (booking['special_instructions'] != null &&
                            booking['special_instructions'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Special Instructions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking['special_instructions'].toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // Payment Breakdown
                      _buildSectionTitle('Payment Breakdown'),
                      const SizedBox(height: 12),
                      _buildPaymentCard(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _buildPaymentRowForSheet('Item Total', '₹${booking['item_total'] ?? 0}', false),
          _buildPaymentRowForSheet('Taxes & Fees', '₹${booking['taxes'] ?? 0}', false),
          const Divider(height: 24, thickness: 2),
          _buildPaymentRowForSheet('Total Amount', '₹${booking['total_amount'] ?? 0}', true),
        ],
      ),
    );
  }

  Widget _buildPaymentRowForSheet(String label, String amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}