import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:npc/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'AdminScreen/HomePageAdmin.dart';
import 'admin_home_page.dart';
import 'firebase_options.dart';
import 'intro_page.dart';
import 'login_page.dart';
import 'main_navigation_bar.dart';
import 'new_orders_technician.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialScreen = IntroPage(); // Default screen

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  // Determine which screen to show based on app state
  Future<void> _determineInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if this is the first time the app is being opened
    bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      // First time opening the app - show intro/onboarding
      _initialScreen = IntroPage();

      // Mark that the app has been opened before
      await prefs.setBool('is_first_time', false);
    } else {
      // Not first time - check for existing session
      await _checkExistingSession();
    }

    setState(() {});
  }

  // Check if valid session exists for returning users
  Future<void> _checkExistingSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('Session-ID');
    String? role = prefs.getString('role');
    String? sessionExpiry = prefs.getString('session_expiry');

    // If no session data exists, go to login
    if (sessionId == null || sessionId.isEmpty || role == null) {
      _initialScreen = LoginScreen();
      return;
    }

    // If session expiry is not set, consider session invalid
    if (sessionExpiry == null) {
      await _clearSessionData();
      _initialScreen = LoginScreen();
      return;
    }

    // Check if session has expired
    try {
      DateTime expiryDateTime = DateTime.parse(sessionExpiry);
      DateTime now = DateTime.now();

      if (now.isAfter(expiryDateTime)) {
        // Session expired - clear data and go to login
        await _clearSessionData();
        _initialScreen = LoginScreen();
      } else {
        // Valid session exists - navigate to appropriate screen based on role
        _initialScreen = _getScreenForRole(role);
      }
    } catch (e) {
      // Error parsing expiry date - clear session and go to login
      print('Error parsing session expiry: $e');
      await _clearSessionData();
      _initialScreen = LoginScreen();
    }
  }

  // Get the appropriate screen based on user role
  Widget _getScreenForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return HomePageAdmin();
      case 'technician':
        return TechnicianOrdersPage();
      case 'user':
      case 'customer':
        return MainPage();
      default:
      // Unknown role - go to login
        return LoginScreen();
    }
  }

  // Clear session data when session is invalid or expired
  Future<void> _clearSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('Session-ID');
    await prefs.remove('role');
    await prefs.remove('session_expiry');
    // Note: We don't remove 'is_first_time' as we want to remember this
  }

  // Optional: Method to reset app to first-time state (useful for testing)
  Future<void> _resetToFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This will clear everything including 'is_first_time'
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPC App',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: ConnectivityWrapper(child: _initialScreen),
    );
  }
}


class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  bool _isSnackbarVisible = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Initialize connectivity checking
  Future<void> _initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    _updateConnectionStatus(result);
  }

  // Update connection status based on connectivity result
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    // Check if the result isn't "none" (meaning we have some kind of connection)
    final hasConnection = result != ConnectivityResult.none;

    setState(() {
      _isConnected = hasConnection;
    });

    // Handle snackbar visibility
    if (!_isConnected && !_isSnackbarVisible) {
      _showNoInternetSnackbar();
    } else if (_isConnected && _isSnackbarVisible) {
      _showInternetRestoredSnackbar();
    }
  }

  // Show a persistent snackbar when internet is disconnected
  void _showNoInternetSnackbar() {
    if (!mounted) return;

    setState(() {
      _isSnackbarVisible = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "No Internet Connection",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(days: 1), // Persistent until dismissed or replaced
        behavior: SnackBarBehavior.fixed,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            setState(() {
              _isSnackbarVisible = false;
            });
          },
        ),
      ),
    ).closed.then((_) {
      if (mounted) {
        setState(() {
          _isSnackbarVisible = false;
        });
      }
    });
  }

  // Show a temporary snackbar when internet is restored
  void _showInternetRestoredSnackbar() {
    if (!mounted) return;

    // Hide the current "No Internet" snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _isSnackbarVisible = false;
    });

    // Show the "Internet Restored" snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              "Internet Connection Restored",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3), // Temporary
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      // Optional overlay indicator for offline status
      bottomNavigationBar: !_isConnected ?
      Container(
        height: 24,
        color: Colors.red.shade700,
        child: const Center(
          child: Text(
            'OFFLINE MODE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ) : null,
    );
  }
}