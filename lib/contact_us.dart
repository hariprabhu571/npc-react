import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Notifications.dart';
import 'Urls.dart';
// Import your notification service here
// import 'notification_service.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String selectedSubject = '';
  bool isLoading = false;
  bool isLoadingQueries = false;
  String? sessionId;

  List<Map<String, dynamic>> userQueries = [];
  Map<String, dynamic>? userProfile;

  final List<String> subjects = [
    'General Inquiry',
    'Billing Inquiry',
    'Technical Support',
    'Feedback'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
    // Remove separate notification service initialization since it's handled automatically now
  }

  @override
  void dispose() {
    _tabController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getSessionId();
    await _fetchUserProfile();
    await _fetchUserQueries();
  }

  Future<void> _getSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('Session-ID');
  }

  Future<void> _fetchUserProfile() async {
    if (sessionId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$ip/user_profile.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userProfile = data['data'];
            // Pre-fill form with user data
            emailController.text = userProfile?['email_id'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchUserQueries() async {
    if (sessionId == null) return;

    setState(() {
      isLoadingQueries = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$ip/user_contact_queries.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      print('Queries Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userQueries = List<Map<String, dynamic>>.from(data['queries'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error fetching queries: $e');
    } finally {
      setState(() {
        isLoadingQueries = false;
      });
    }
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedSubject.isEmpty) {
      _showError('Please select a subject');
      return;
    }
    if (sessionId == null) {
      _showError('Session expired. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$ip/submit_contact_query.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'subject': selectedSubject,
          'message': messageController.text,
        }),
      );

      print('Submit Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Print admin FCM tokens for debugging
          if (data['admin_fcm_tokens'] != null && data['admin_fcm_tokens'].isNotEmpty) {
            print('🎯 CONTACT FORM SUBMISSION SUCCESSFUL');
            print('═══════════════════════════════════════');
            print('📋 Query Details:');
            print('   🆔 Query ID: ${data['data']['query_id']}');
            print('   👤 Customer: ${data['data']['customer_name']}');
            print('   📧 Email: ${emailController.text}');
            print('   📞 Phone: ${phoneController.text}');
            print('   📝 Subject: ${data['data']['subject']}');
            print('   ⏰ Submitted: ${data['data']['submitted_at']}');
            print('');
            print('🔔 Admin Notification Details:');
            print('   📊 Total Admin Tokens: ${data['admin_token_count']}');

            List<dynamic> tokens = data['admin_fcm_tokens'];
            for (int i = 0; i < tokens.length; i++) {
              var admin = tokens[i];
              print('   👤 Admin ${i + 1}:');
              print('      🆔 ID: ${admin['admin_id']}');
              print('      📧 Email: ${admin['admin_email']}');
              print('      🎯 FCM Token: ${admin['fcm_token'].substring(0, 30)}...');
            }

            print('');
            print('🚀 Sending notifications to all admins...');
            print('═══════════════════════════════════════');

            // Send notifications to all admin FCM tokens
            await _sendNotificationsToAdmins(tokens, data);

          } else {
            print('❌ No admin FCM tokens received in response');
          }

          _showSuccess('Your message has been submitted successfully!');
          _clearForm();
          await _fetchUserQueries(); // Refresh queries
          _tabController.animateTo(1); // Switch to queries tab
        } else {
          _showError(data['message'] ?? 'Failed to submit message');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting form: $e');
      _showError('Network error. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendNotificationsToAdmins(List<dynamic> tokens, Map<String, dynamic> responseData) async {
    try {
      String customerName = '${firstNameController.text} ${lastNameController.text}';
      String subject = selectedSubject;
      String message = messageController.text;
      String queryId = responseData['data']['query_id'].toString();

      print('📤 Preparing notification data:');
      print('   👤 Customer: $customerName');
      print('   📝 Subject: $subject');
      print('   💬 Message Length: ${message.length} characters');
      print('   🆔 Query ID: $queryId');
      print('');

      // Send contact query notification using NotificationService
      await NotificationService.sendContactQueryNotification(
        fcmTokens: tokens,
        customerName: customerName,
        subject: subject,
        message: message,
        queryId: queryId,
      );

      print('');
      print('✅ Notification sending process completed successfully!');

    } catch (e) {
      print('❌ Error sending notifications: $e');
    }
  }

  void _clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    messageController.clear();
    setState(() {
      selectedSubject = '';
    });
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/npc_logo.png',
              height: 30,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF4A9589),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF4A9589),
          labelStyle: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Contact Us'),
            Tab(text: 'My Queries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactForm(),
          _buildQueriesTab(),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A9589).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent,
                        size: 40,
                        color: Color(0xFF4A9589),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                        color: Color(0xFF2A3C66),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Any question or remarks?\nJust write us a message!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Sora',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Form Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: firstNameController,
                      label: 'First Name',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: lastNameController,
                      label: 'Last Name',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Phone number is required';
                  if (value!.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Subject Selection
              Text(
                'Select Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sora',
                  color: Color(0xFF2A3C66),
                ),
              ),
              SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((subject) {
                  bool isSelected = selectedSubject == subject;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSubject = subject;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF4A9589) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? Color(0xFF4A9589) : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),

              // Message Field
              TextFormField(
                controller: messageController,
                maxLines: 5,
                validator: (value) => value?.isEmpty ?? true ? 'Message is required' : null,
                decoration: InputDecoration(
                  labelText: 'Write your message...',
                  labelStyle: TextStyle(fontFamily: 'Sora', color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF4A9589), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitContactForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A9589),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Send Message',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Contact Information
              _buildContactInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Sora', color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A9589), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF4A9589),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A9589).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Sora',
            ),
          ),
          SizedBox(height: 24),

          _buildContactItem(Icons.phone, '+91-8637454428'),
          SizedBox(height: 16),
          _buildContactItem(Icons.email, 'ashikali613@gmail.com'),
          SizedBox(height: 16),
          _buildContactItem(
            Icons.location_on,
            'NPC PVT LTD, NO. 158, Murugan Kovil Street,\nVanashakthi Nagar, Kolather, Chennai - 99.',
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Sora',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueriesTab() {
    return isLoadingQueries
        ? Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
      ),
    )
        : userQueries.isEmpty
        ? _buildEmptyQueriesState()
        : RefreshIndicator(
      onRefresh: _fetchUserQueries,
      color: Color(0xFF4A9589),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: userQueries.length,
        itemBuilder: (context, index) {
          return _buildQueryCard(userQueries[index]);
        },
      ),
    );
  }

  Widget _buildEmptyQueriesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No queries yet',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your submitted queries will appear here',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard(Map<String, dynamic> query) {
    bool hasResponse = query['admin_response'] != null && query['admin_response'].toString().isNotEmpty;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A9589).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    query['subject'] ?? 'General',
                    style: TextStyle(
                      color: Color(0xFF4A9589),
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasResponse ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasResponse ? 'Answered' : 'Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Sora',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            Text(
              'Your Message:',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A3C66),
              ),
            ),
            SizedBox(height: 4),
            Text(
              query['message'] ?? '',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),

            if (hasResponse) ...[
              SizedBox(height: 16),
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
                        Icon(Icons.admin_panel_settings, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Admin Response:',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      query['admin_response'],
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.green[700],
                        height: 1.4,
                      ),
                    ),
                    if (query['response_date'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Responded on: ${query['response_date_formatted'] ?? query['response_date']}',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 12),
            Text(
              'Submitted: ${query['created_at_formatted'] ?? query['created_at']}',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}