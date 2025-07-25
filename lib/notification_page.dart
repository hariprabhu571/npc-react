import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Urls.dart'; // Make sure this contains your IP

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getSessionId();
    await _fetchNotifications();
  }

  Future<void> _getSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString('Session-ID');
  }

  Future<void> _fetchNotifications() async {
    if (sessionId == null) {
      _showError('Session not found. Please login again.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$ip/user_notifications.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
            isLoading = false;
          });
        } else {
          _showError(data['message'] ?? 'Failed to fetch notifications');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      _showError('Network error. Please check your connection.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (sessionId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$ip/mark_notification_read.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notification_id': notificationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Update local state
          setState(() {
            notifications = notifications.map((notification) {
              if (notification['id'].toString() == notificationId) {
                notification['is_read'] = true;
              }
              return notification;
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Icons.assignment;
      case 'reached':
        return Icons.location_on;
      case 'started':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Order Assigned';
      case 'reached':
        return 'Technician Arrived';
      case 'started':
        return 'Service Started';
      case 'completed':
        return 'Service Completed';
      default:
        return 'Status Update';
    }
  }

  String _formatTimeAgo(String timestamp) {
    try {
      DateTime notificationTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      Duration difference = now.difference(notificationTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    const String appBarTitle = "Notifications";
    const String noNotificationsMessage = "No notifications yet";
    const String description = "Your order updates and notifications will appear here.";
    const String notificationImagePath = 'assets/images/noti.png';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Container(
          padding: EdgeInsets.only(top: 20.0),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              appBarTitle,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            centerTitle: false,
            actions: notifications.isNotEmpty
                ? [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[600]),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _fetchNotifications();
                },
              ),
            ]
                : null,
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
              'Loading notifications...',
              style: TextStyle(
                fontFamily: 'Sora',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : notifications.isEmpty
          ? Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 90),
            Image.asset(
              notificationImagePath,
              width: 268.0,
              height: 268.0,
            ),
            SizedBox(height: 16),
            const Text(
              noNotificationsMessage,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            const Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: Color(0xFF4A9589),
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    bool isRead = notification['is_read'] == true || notification['is_read'] == 1;
    String status = notification['status'] ?? '';
    String notificationId = notification['id'].toString();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.grey[200]! : Color(0xFF4A9589).withOpacity(0.3),
            width: isRead ? 0.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(notificationId);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isRead ? Colors.white : Color(0xFF4A9589).withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getStatusDisplayText(status),
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isRead ? Colors.grey[800] : Color(0xFF2A3C66),
                                ),
                              ),
                              Row(
                                children: [
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4A9589),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatTimeAgo(notification['timestamp'] ?? ''),
                                    style: TextStyle(
                                      fontFamily: 'Sora',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Order #${notification['booking_id'] ?? 'N/A'}',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 12,
                              color: Color(0xFF4A9589),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  notification['message'] ?? 'Status update for your order',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    color: isRead ? Colors.grey[600] : Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                if (notification['technician_name'] != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Technician: ${notification['technician_name']}',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                if (notification['notes'] != null && notification['notes'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notification['notes'],
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}