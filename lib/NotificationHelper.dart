import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:npc/Urls.dart';

class NotificationHelper {
  // Manager's FCM token (should be stored in database or config)
  static const String MANAGER_FCM_TOKEN = "manager_fcm_token_here"; // Replace with actual manager token

  // Send notification request to manager
  static Future<bool> sendNotificationRequest({
    required String title,
    required String message,
    required String targetUserType, // 'user', 'technician', 'admin'
    String priority = 'normal', // 'low', 'normal', 'high', 'critical'
    String? senderInfo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('Session-ID');
      String? currentUserRole = prefs.getString('role');

      // Get current user info for sender details
      if (senderInfo == null && currentUserRole != null) {
        senderInfo = '$currentUserRole User';
      }

      // Prepare notification request data
      Map<String, dynamic> requestData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'target_user_type': targetUserType,
        'priority': priority,
        'timestamp': DateTime.now().toIso8601String(),
        'sender_info': senderInfo ?? 'Unknown',
        'data': additionalData ?? {},
      };

      // Send to manager via FCM
      bool fcmSent = await _sendFCMToManager(requestData);

      // Also log the request in database for backup
      bool dbLogged = await _logNotificationRequest(requestData);

      return fcmSent && dbLogged;
    } catch (e) {
      print('Error sending notification request: $e');
      return false;
    }
  }

  // Send FCM message to manager
  static Future<bool> _sendFCMToManager(Map<String, dynamic> requestData) async {
    try {
      // Get access token for Firebase
      String accessToken = await _getFirebaseAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final body = jsonEncode({
        'message': {
          'token': MANAGER_FCM_TOKEN,
          'data': requestData.map((key, value) => MapEntry(key, value.toString())),
          'notification': {
            'title': 'New Notification Request',
            'body': 'Request: ${requestData['title']}',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': 'manager_requests',
            },
          },
        },
      });

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/npc-pest/messages:send'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending FCM to manager: $e');
      return false;
    }
  }

  // Log notification request in database
  static Future<bool> _logNotificationRequest(Map<String, dynamic> requestData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('Session-ID');

      final response = await http.post(
        Uri.parse('${ip}log_notification_request.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId ?? '',
        },
        body: jsonEncode({
          'action': 'log_request',
          'request_data': requestData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error logging notification request: $e');
      return false;
    }
  }

  // Get Firebase access token
  static Future<String> _getFirebaseAccessToken() async {
    // Using the same service account as in the manager screen
    // This should be moved to a separate service class for better organization

    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "npc-pest",
      "private_key_id": "32ed9d3434809749be5e38e4643b146be5fa4344",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCc1ZpIKhFHx3sB\n24zuKKPy16ecAlaka3/PZ7X27GnLELjnyFsJz2gHxCql2zyusKtsrIg+37H0eX1B\nmzmuUJgMl6iXZQZbTrv+ReaFfBBgInZzHK2FGf2TzJOYP3Ra3cYiuM2sUNW/Iwmx\nSpLjPyS3pxV+tCigJKoLZuara6L3iwR2hodjIDHXFBYHVmb5pa857uaCzFVf3X/M\nV3i+9eAeup3Evb9By73edGZchxhENP8SSiSQU6YF59oUmESiqwu54Hi43k2NrBa6\njSI7iZ1OYRxdMrlp31knZU42KduKoHk0oi7Q+AS8Z6lNIHBO7Z2T6mOlTt2cGSrl\njCzKUOVrAgMBAAECggEAAgY7zTBZgsBeLbYJYlgLyz31hLvD6rAo1raVwbJARhmU\nKDCDBFBmWDPvAeofh4x7xkbxERzYrZIBuTI4HOtaKditci7SBuB1Nw1i2ViLJeAO\nduKt9DxnQyEzQUdyPs4DGWWipku/lVKLnCzEef2qRlsL1NPYy1Gcmm9hg01jXuMM\ncVtmpiZIut3Bpo6+1maJF8+t+M1NztSVssOmIA95EU8qUau+5fzyCCzCZpQidUst\nvelTdyZGxOxOvB4ftwDHVPEn5rOUygvRLS49zSxAAy8OwtSooaiyfpkBng1JAubi\nAtw0goyLoaR0Ackk8DeDAi7tXHiT7uxfZKsr4C/GwQKBgQDaMfbXgynurkT7Tg4b\nDWYtYFMVxDF+JAewRmyOeSlpTiy2RQgnIqkY3EoNCQgRN2pNj1HD+XDE9AuGGppQ\nkxfXbFBt46EgFLGEk2jkW1hCoTA7xJODNUm0QqFFfX8BDTGZxgCLZFQt7dUm7PIg\nclFXxIsV1M9VPVY1lCpvmAAbywKBgQC4Afvc8IKl+usdm8LVnvcNlR7fVaA4SkQK\nPmRxK3O1dGpCl8iamZV/WmLt3FrXOLZ/7FWE7H3fYT4KbParz4xCSP33jfO/IEnK\nxK8tOOTNlyXQK/HOQuUSirvSQQTmrZsy/RqN5VNDHTrgZb7RoF4eg55LmUxz03XJ\nEz31Ewpo4QKBgQDN4GkFbihJojtKV5rtoZXwaLvchNMiL0Ll630QbXhKeU2s6bPI\noWamI2znocbv37a42esPm7Pw0khxT3adYj0TsYquNSLZz0y0SBanqRy9ObP2IQQC\nwGv73wamN8R3LIjJjE8FNzRKZedCJD5NqS/hPXzyq2q6Bfbq9ROZWfV4QwKBgF4u\nZcOINtbNv1nAR9EfNER3dv3IzeEB4iF8Hdzu6KKPm3PKTJsU0TgGA2zLxJM0K/T9\n+ie3BBY5p4+ehgMakCe9RIBY39GLrTljwmXbIQE5w9jxJSr1glojOE89iEypvy4x\n7k2Ce0N2ypPgf/K7qnDj3TnElSUTrs3kU2oE/OcBAoGBALOx5rCW2NXIj9moAFU3\n7Fbgp/rFqB0rWEgltJJwoV1qaYXXELHIRQO9EbzPirkQBiAcfVLzViKDUqdvC8V3\nQfnENFFKKlyAT99L2I1YMtClgGuKaZF6xU/J5B07p8x7ZoApB6PBJ8uZtQ0nPl9f\nNr0tpan3MU/1/VRBqxvF5OS/\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@npc-pest.iam.gserviceaccount.com",
      "client_id": "117164826011024162817",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40npc-pest.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    // For production, consider using a server-side endpoint to get tokens
    // to avoid exposing service account credentials in the app

    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': _createJWT(serviceAccountJson),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
      throw Exception('Failed to get access token');
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  // Create JWT for OAuth2
  static String _createJWT(Map<String, dynamic> serviceAccount) {
    // This is a simplified version. For production, use proper JWT library
    // or handle this server-side
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'iss': serviceAccount['client_email'],
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': now + 3600,
      'iat': now,
    };

    // Note: This is a placeholder. In production, implement proper JWT signing
    // or use a server-side service for security
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  // Predefined notification templates for common scenarios
  static Future<bool> sendOrderCompletedNotification({
    required String orderId,
    required String customerName,
  }) async {
    return await sendNotificationRequest(
      title: 'Order Completed',
      message: 'Order #$orderId for $customerName has been completed successfully.',
      targetUserType: 'user',
      priority: 'normal',
      additionalData: {
        'order_id': orderId,
        'customer_name': customerName,
        'action_type': 'order_completed',
      },
    );
  }

  static Future<bool> sendTechnicianAssignedNotification({
    required String orderId,
    required String technicianName,
  }) async {
    return await sendNotificationRequest(
      title: 'Technician Assigned',
      message: 'Technician $technicianName has been assigned to order #$orderId.',
      targetUserType: 'user',
      priority: 'normal',
      additionalData: {
        'order_id': orderId,
        'technician_name': technicianName,
        'action_type': 'technician_assigned',
      },
    );
  }

  static Future<bool> sendEmergencyAlert({
    required String message,
    String targetUserType = 'all',
  }) async {
    return await sendNotificationRequest(
      title: 'Emergency Alert',
      message: message,
      targetUserType: targetUserType,
      priority: 'critical',
      additionalData: {
        'action_type': 'emergency_alert',
        'requires_immediate_attention': true,
      },
    );
  }

  static Future<bool> sendMaintenanceNotification({
    required String scheduledTime,
    required String duration,
  }) async {
    return await sendNotificationRequest(
      title: 'Scheduled Maintenance',
      message: 'System maintenance scheduled for $scheduledTime (Duration: $duration).',
      targetUserType: 'all',
      priority: 'high',
      additionalData: {
        'scheduled_time': scheduledTime,
        'duration': duration,
        'action_type': 'maintenance_notification',
      },
    );
  }

  static Future<bool> sendNewOrderAlert({
    required String orderId,
    required String customerName,
    required String serviceType,
  }) async {
    return await sendNotificationRequest(
      title: 'New Order Received',
      message: 'New $serviceType order #$orderId from $customerName requires attention.',
      targetUserType: 'technician',
      priority: 'high',
      additionalData: {
        'order_id': orderId,
        'customer_name': customerName,
        'service_type': serviceType,
        'action_type': 'new_order',
      },
    );
  }

  static Future<bool> sendPaymentReceivedNotification({
    required String orderId,
    required String amount,
    required String customerName,
  }) async {
    return await sendNotificationRequest(
      title: 'Payment Received',
      message: 'Payment of ₹$amount received for order #$orderId from $customerName.',
      targetUserType: 'admin',
      priority: 'normal',
      additionalData: {
        'order_id': orderId,
        'amount': amount,
        'customer_name': customerName,
        'action_type': 'payment_received',
      },
    );
  }

  // Get manager FCM token from database
  static Future<String?> getManagerFCMToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('Session-ID');

      final response = await http.post(
        Uri.parse('${ip}get_fcm_token.php'),
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId ?? '',
        },
        body: jsonEncode({
          'action': 'get_manager_token',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data']['fcm_token'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting manager FCM token: $e');
      return null;
    }
  }
}

// Example usage in other screens:
/*
// From order completion screen:
await NotificationHelper.sendOrderCompletedNotification(
  orderId: "ORD123",
  customerName: "John Doe",
);

// From technician assignment screen:
await NotificationHelper.sendTechnicianAssignedNotification(
  orderId: "ORD123",
  technicianName: "Mike Smith",
);

// From emergency situations:
await NotificationHelper.sendEmergencyAlert(
  message: "System malfunction detected in area 5",
  targetUserType: "technician",
);

// Custom notification:
await NotificationHelper.sendNotificationRequest(
  title: "Custom Title",
  message: "Custom message",
  targetUserType: "user",
  priority: "high",
  additionalData: {"custom_key": "custom_value"},
);
*/