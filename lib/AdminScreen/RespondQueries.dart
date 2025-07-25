import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Urls.dart';

class RespondQueries extends StatefulWidget {
  const RespondQueries({Key? key}) : super(key: key);

  @override
  State<RespondQueries> createState() => _RespondQueriesState();
}

class _RespondQueriesState extends State<RespondQueries> with TickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> allQueries = [];
  List<Map<String, dynamic>> pendingQueries = [];
  List<Map<String, dynamic>> respondedQueries = [];

  bool isLoading = true;
  String? sessionId;
  Map<String, dynamic>? adminInfo;
  Map<String, int> statusCounts = {
    'pending': 0,
    'responded': 0,
    'closed': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getSessionId();
    await _fetchQueries();
  }

  Future<void> _getSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('Session-ID');
  }

  Future<void> _fetchQueries() async {
    if (sessionId == null) {
      _showError('Admin session not found. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$ip/admin_contact_queries.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      print('Admin Queries Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            allQueries = List<Map<String, dynamic>>.from(data['queries'] ?? []);
            adminInfo = data['admin'];
            statusCounts = Map<String, int>.from(data['status_counts'] ?? {});

            // Filter queries by status
            pendingQueries = allQueries.where((q) => q['status'] == 'pending').toList();
            respondedQueries = allQueries.where((q) => q['status'] == 'responded').toList();

            isLoading = false;
          });
        } else {
          _showError(data['message'] ?? 'Failed to fetch queries');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching queries: $e');
      _showError('Network error. Please check your connection.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showError('No phone number available');
      return;
    }

    // Clean the phone number (remove spaces, dashes, etc.)
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showError('Could not launch phone dialer');
      }
    } catch (e) {
      _showError('Error making phone call: $e');
    }
  }

  Future<void> _respondToQuery(Map<String, dynamic> query, String response) async {
    if (sessionId == null) return;

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
                  'Submitting response...',
                  style: TextStyle(fontFamily: 'Sora'),
                ),
              ],
            ),
          ),
        ),
      );

      final httpResponse = await http.post(
        Uri.parse('$ip/admin_contact_queries.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'query_id': query['id'],
          'response': response,
          'status': 'responded',
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (httpResponse.statusCode == 200) {
        final data = json.decode(httpResponse.body);
        if (data['status'] == 'success') {
          _showSuccess('Response submitted successfully!');
          await _fetchQueries(); // Refresh queries
        } else {
          _showError(data['message'] ?? 'Failed to submit response');
        }
      } else {
        _showError('Server error: ${httpResponse.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Error responding to query: $e');
      _showError('Network error. Please try again.');
    }
  }

  void _showResponseDialog(Map<String, dynamic> query) {
    final TextEditingController responseController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.reply, color: Color(0xFF4A9589)),
              SizedBox(width: 8),
              Text(
                'Respond to Query',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Query Details
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer: ${query['customer_name'] ?? query['first_name'] + ' ' + query['last_name']}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Subject: ${query['subject']}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            color: Color(0xFF4A9589),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          query['message'],
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Response Field
                  Text(
                    'Your Response:',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: responseController,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Response cannot be empty';
                      }
                      if (value.trim().length < 10) {
                        return 'Response must be at least 10 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Type your response here...',
                      hintStyle: TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF4A9589), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _respondToQuery(query, responseController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A9589),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Send Response',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showQueryDetails(Map<String, dynamic> query) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4A9589)),
              SizedBox(width: 8),
              Text(
                'Query Details',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Customer', query['customer_name'] ?? '${query['first_name']} ${query['last_name']}'),
                  _buildDetailRow('Email', query['email']),
                  _buildDetailRow('Phone', query['phone']),
                  _buildDetailRow('Subject', query['subject']),
                  _buildDetailRow('Submitted', query['created_at_formatted']),
                  SizedBox(height: 12),

                  Text(
                    'Message:',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      query['message'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),

                  if (query['admin_response'] != null && query['admin_response'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Admin Response:',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        query['admin_response'],
                        style: TextStyle(
                          fontFamily: 'Sora',
                          color: Colors.green[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (query['response_date_formatted'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Responded: ${query['response_date_formatted']}',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (query['status'] == 'pending')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showResponseDialog(query);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A9589),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Respond',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Sora')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Sora')),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Queries',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            if (adminInfo != null)
              Text(
                'Admin: ${adminInfo!['admin_name']}',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _fetchQueries,
            tooltip: 'Refresh',
          ),
        ],
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
            Tab(text: 'All (${allQueries.length})'),
            Tab(text: 'Pending (${statusCounts['pending'] ?? 0})'),
            Tab(text: 'Responded (${statusCounts['responded'] ?? 0})'),
          ],
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
              'Loading queries...',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildQueriesList(allQueries, 'all'),
          _buildQueriesList(pendingQueries, 'pending'),
          _buildQueriesList(respondedQueries, 'responded'),
        ],
      ),
    );
  }

  Widget _buildQueriesList(List<Map<String, dynamic>> queries, String type) {
    if (queries.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _fetchQueries,
      color: Color(0xFF4A9589),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: queries.length,
        itemBuilder: (context, index) {
          return _buildQueryCard(queries[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'pending':
        message = 'No pending queries';
        icon = Icons.inbox_outlined;
        break;
      case 'responded':
        message = 'No responded queries';
        icon = Icons.mark_email_read_outlined;
        break;
      default:
        message = 'No queries found';
        icon = Icons.question_answer_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard(Map<String, dynamic> query) {
    bool isPending = query['status'] == 'pending';
    bool hasResponse = query['admin_response'] != null && query['admin_response'].toString().isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Color(0xFF4A9589).withOpacity(0.3) : Colors.grey[200]!,
          width: isPending ? 1 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showQueryDetails(query),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          query['customer_name'] ?? '${query['first_name']} ${query['last_name']}',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2A3C66),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          query['email'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPending ? 'Pending' : 'Responded',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Sora',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        query['created_at_formatted'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF4A9589).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  query['subject'] ?? '',
                  style: TextStyle(
                    color: Color(0xFF4A9589),
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 12),

              Text(
                query['message'] ?? '',
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (hasResponse) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Admin Response:',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        query['admin_response'],
                        style: TextStyle(
                          fontFamily: 'Sora',
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Call button - only show for pending queries and if phone number exists
                  if (isPending && (query['phone'] != null && query['phone'].toString().isNotEmpty ||
                      query['mobile_number'] != null && query['mobile_number'].toString().isNotEmpty)) ...[
                    IconButton(
                      onPressed: () => _makePhoneCall(query['phone'] ?? query['mobile_number']),
                      icon: Icon(Icons.phone, size: 20, color: Colors.green),
                      tooltip: 'Call Customer',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],

                  TextButton.icon(
                    onPressed: () => _showQueryDetails(query),
                    icon: Icon(Icons.visibility, size: 16, color: Color(0xFF4A9589)),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Color(0xFF4A9589),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(query),
                      icon: Icon(Icons.reply, size: 16, color: Colors.white),
                      label: Text(
                        'Respond',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A9589),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}