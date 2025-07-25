import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotificationService {
  static Future<String> getAccessToken() async {
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

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    var client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    var credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();

    return credentials.accessToken.data;
  }
}

class NotificationService {
  static String? _serverKey;

  // Initialize the service with server key
  static Future<void> initialize() async {
    _serverKey = await PushNotificationService.getAccessToken();
  }

  // Send notification to multiple FCM tokens
  static Future<void> sendNotificationToTokens({
    required List<dynamic> fcmTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Ensure we have a server key, get it if we don't
    if (_serverKey == null || _serverKey!.isEmpty) {
      print('🔑 Server key not available, obtaining new access token...');
      try {
        _serverKey = await PushNotificationService.getAccessToken();
        print('✅ New access token obtained successfully');
      } catch (e) {
        print('❌ Failed to get access token: $e');
        return;
      }
    }

    if (_serverKey == null || _serverKey!.isEmpty) {
      print('❌ Server key still not available for sending notifications');
      return;
    }

    print('🔔 Starting notification sending process...');
    print('📤 Sending to ${fcmTokens.length} admin(s)');
    print('📋 Title: $title');
    print('📝 Body: $body');
    print('🔑 Using server key: ${_serverKey!.substring(0, 20)}...');
    print('');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_serverKey',
    };

    int successCount = 0;
    int failureCount = 0;

    for (int i = 0; i < fcmTokens.length; i++) {
      var admin = fcmTokens[i];
      String fcmToken = admin['fcm_token'];
      String adminEmail = admin['admin_email'];
      String adminId = admin['admin_id'].toString();

      print('📤 Sending notification ${i + 1}/${fcmTokens.length}');
      print('   👤 Admin: $adminEmail (ID: $adminId)');
      print('   🎯 Token: ${fcmToken.substring(0, 30)}...');

      // Prepare notification payload
      Map<String, dynamic> notification = {
        'title': title,
        'body': body,
      };

      // Add custom data if provided
      Map<String, dynamic> messagePayload = {
        'message': {
          'token': fcmToken,
          'notification': notification,
        }
      };

      if (data != null) {
        messagePayload['message']['data'] = data.map((key, value) => MapEntry(key, value.toString()));
      }

      final requestBody = jsonEncode(messagePayload);

      try {
        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/npc-pest/messages:send'),
          headers: headers,
          body: requestBody,
        );

        if (response.statusCode == 200) {
          successCount++;
          print('   ✅ SUCCESS - Notification sent successfully');
          print('   📊 Response: ${response.body}');
        } else {
          failureCount++;
          print('   ❌ FAILED - Status: ${response.statusCode}');
          print('   📊 Error: ${response.body}');
        }
      } catch (error) {
        failureCount++;
        print('   ❌ EXCEPTION - Error sending notification');
        print('   📊 Exception: $error');
      }

      print('   ─────────────────────────────────────');
    }

    print('');
    print('🎯 NOTIFICATION SUMMARY:');
    print('   ✅ Successful: $successCount');
    print('   ❌ Failed: $failureCount');
    print('   📊 Total: ${fcmTokens.length}');
    print('🔔 Notification sending process completed!');
    print('═══════════════════════════════════════');
  }

  // Send contact query notification specifically
  static Future<void> sendContactQueryNotification({
    required List<dynamic> fcmTokens,
    required String customerName,
    required String subject,
    required String message,
    required String queryId,
  }) async {
    String title = 'New Contact Query Received';
    String body = 'New $subject from $customerName';

    Map<String, dynamic> notificationData = {
      'type': 'contact_query',
      'query_id': queryId,
      'customer_name': customerName,
      'subject': subject,
      'message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await sendNotificationToTokens(
      fcmTokens: fcmTokens,
      title: title,
      body: body,
      data: notificationData,
    );
  }
}