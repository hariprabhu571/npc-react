import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:npc/Urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this import
import 'AdminScreen/HomePageAdmin.dart';
import 'sign_up_page.dart';
import 'dart:convert';
import 'admin_home_page.dart';
import 'new_orders_technician.dart';
import 'user_home_page.dart';
import 'main_navigation_bar.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  DateTime? lastPressed;
  bool _isObscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _fcmToken; // Add FCM token variable
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'User'; // Default role
  final List<String> _roles = ['User', 'Admin', 'Technician'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF4A9589),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _initializeFCM(); // Initialize FCM token
  }

  // Initialize FCM and get token
  Future<void> _initializeFCM() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');

        // Get the token
        String? token = await messaging.getToken();
        setState(() {
          _fcmToken = token;
        });
        print('FCM Token: $token');

        // Listen for token refresh
        messaging.onTokenRefresh.listen((String token) {
          setState(() {
            _fcmToken = token;
          });
          print('FCM Token refreshed: $token');
        });
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  Future<void> _login() async {
    if (_mobileController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields',
            style: TextStyle(fontFamily: 'sora'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Define API endpoint based on selected role
      String apiUrl = "";

      if (_selectedRole == 'Admin') {
        apiUrl = ip + 'adminlogin.php';
      } else if (_selectedRole == 'Technician') {
        apiUrl = ip + 'technicianlogin.php';
      } else {
        apiUrl = ip + 'userlogin.php';
      }

      // Prepare the request body with actual FCM token
      Map<String, dynamic> requestBody = {
        "email": _mobileController.text.trim(),
        "password": _passwordController.text,
        "fcm_token": _fcmToken ?? "no_token_available", // Use actual FCM token
      };

      print('Login request: $requestBody');

      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Process the response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login response: $data');

        if (data['status'] == 'success') {
          print("Login Success: $data");

          // Get session ID
          String sessionId = data['sessionid'];
          String sessiondate = data['session_expiry'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_expiry', sessiondate);

          // Store FCM token in SharedPreferences
          if (_fcmToken != null) {
            await prefs.setString('fcm_token', _fcmToken!);
          }

          // Navigate to the correct screen based on role
          if (_selectedRole == 'Admin') {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('role', 'Admin');
            await prefs.setString('Session-ID', sessionId);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePageAdmin()),
                  (route) => false,
            );
          } else if (_selectedRole == 'Technician') {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('role', 'Technician');
            await prefs.setString('Session-ID', sessionId);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => TechnicianOrdersPage()),
                  (route) => false,
            );
          } else {
            print("User login successful");
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('role', 'User');
            await prefs.setString('Session-ID', sessionId);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,
            );
          }
        } else {
          // Show error message for invalid credentials
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? 'Login failed. Please check your credentials.',
                style: TextStyle(fontFamily: 'sora'),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message for server errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error: ${response.statusCode}',
              style: TextStyle(fontFamily: 'sora'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message for network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection error: ${e.toString()}',
            style: TextStyle(fontFamily: 'sora'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Changed to true for better keyboard handling
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background
            Container(
              width: double.infinity,
              height: screenHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A9589), Color(0xFF0C111D)],
                ),
              ),
            ),
            // PNG image overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/images/Star.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Responsive content with SingleChildScrollView
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: <Widget>[
                      // Top section with logo and title
                      Container(
                        height: screenHeight * (isTablet ? 0.35 : 0.3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.05),
                            Image.asset(
                              'assets/images/npc_logo.png',
                              height: isTablet ? 100 : 80,
                              width: isTablet ? 220 : 180,
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: Text(
                                'Get Started now',
                                style: TextStyle(
                                  fontSize: isTablet ? 36 : 30,
                                  fontFamily: 'sora',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'log in to explore NPC',
                              style: TextStyle(
                                color: Colors.white70.withOpacity(0.8),
                                fontSize: isTablet ? 14 : 11,
                                fontFamily: 'sora',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom section with form
                      Expanded(
                        child: Container(
                          width: screenWidth * (isTablet ? 0.7 : 0.90),
                          margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? screenWidth * 0.15 : screenWidth * 0.05,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 40 : 30,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // Role Selection Dropdown
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRole,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF33497B)),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: isTablet ? 16 : 14,
                                      fontFamily: 'sora',
                                    ),
                                    hint: Text("Select Role"),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedRole = newValue!;
                                      });
                                    },
                                    items: _roles.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 16 : 12),
                              buildTextField('User ID', false, _mobileController, isNumber: false),
                              SizedBox(height: isTablet ? 16 : 12),
                              buildTextField('Password', true, _passwordController),
                              SizedBox(height: isTablet ? 12 : 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // FCM Token status indicator (for debugging)
                                  if (_fcmToken != null)
                                    Icon(
                                      Icons.notifications_active,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  // TextButton(
                                  //   onPressed: () => print("forgot password"),
                                  //   child: Text(
                                  //     'Forgot Password?',
                                  //     style: TextStyle(
                                  //       color: Color(0xFF2A544E),
                                  //       fontSize: isTablet ? 14 : 12,
                                  //       fontFamily: 'sora',
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              SizedBox(height: isTablet ? 20 : 15),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, isTablet ? 60 : 50),
                                  backgroundColor: Color(0xFF4A9589),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontFamily: 'sora',
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text('Log In'),
                              ),
                              SizedBox(height: isTablet ? 30 : 20),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 60.0 : 45.0,
                                  vertical: 0.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Create an Account?",
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        fontFamily: 'sora',
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => SignUpScreen()),
                                        );
                                      },
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          fontFamily: 'sora',
                                          color: Color(0xFF2A544E),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, bool isPassword, TextEditingController controller, {bool isNumber = false}) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: TextStyle(
        fontSize: isTablet ? 16 : 14,
        fontFamily: 'sora',
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontFamily: 'sora',
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
            size: isTablet ? 24 : 20,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Color(0xFF33497B),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTablet ? 20 : 16,
        ),
      ),
    );
  }
}