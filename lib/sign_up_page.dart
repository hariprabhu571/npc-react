import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:npc/Urls.dart';
import 'dart:convert';
import 'login_page.dart';
import 'package:flutter_svg/svg.dart';
import 'admin_home_page.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  DateTime? lastPressed;
  bool _isObscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
  }

  // Enhanced signup function with better error handling and validation
  Future<void> signUp() async {
    // Input validation
    String name = _emailController.text.trim();
    String mobile = _mobileController.text.trim();
    String password = _passwordController.text.trim();

    // Validate inputs
    if (name.isEmpty) {
      _showErrorSnackBar("Please enter your full name");
      return;
    }

    if (mobile.isEmpty) {
      _showErrorSnackBar("Please enter your mobile number");
      return;
    }

    if (mobile.length < 10) {
      _showErrorSnackBar("Please enter a valid mobile number (at least 10 digits)");
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar("Please enter a password");
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar("Password must be at least 6 characters long");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String apiUrl = ip + "usersignup.php";
      print("API URL: $apiUrl"); // Debug print

      // Prepare the data
      Map<String, String> requestData = {
        "customer_name": name,
        "mobile_number": mobile,
        "password": password,
      };

      print("Request Data: $requestData"); // Debug print

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestData),
      );

      print("Response Status Code: ${response.statusCode}"); // Debug print
      print("Response Body: ${response.body}"); // Debug print

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          print("Parsed Response: $responseData"); // Debug print

          if (responseData['status'] == "success") {
            _showSuccessSnackBar("Account created successfully!");

            // Navigate to login screen after a short delay
            await Future.delayed(Duration(seconds: 1));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            _showErrorSnackBar(responseData['message'] ?? "Signup failed. Please try again.");
          }
        } catch (e) {
          print("JSON Decode Error: $e"); // Debug print
          _showErrorSnackBar("Invalid response from server. Please try again.");
        }
      } else {
        _showErrorSnackBar("Server error (${response.statusCode}). Please try again later.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Network Error: $e"); // Debug print
      _showErrorSnackBar("Network error. Please check your connection and try again.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
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
            // Your content
            Column(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 30),
                      Image.asset(
                        'assets/images/npc_logo.png',
                        height: 80,
                        width: 180,
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(
                          'Get Started now',
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'sora',
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Sign Up to explore NPC',
                        style: TextStyle(
                            color: Colors.white70.withOpacity(0.8),
                            fontSize: 11,
                            fontFamily: 'sora'
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.90,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
                        buildTextField('Full Name', false, _emailController),
                        SizedBox(height: 10),
                        buildTextField('Mobile Number', false, _mobileController, isNumber: true),
                        SizedBox(height: 10),
                        buildTextField('Password', true, _passwordController),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : signUp, // Disable button when loading
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Color(0xFF4A9589),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Sign Up',
                            style: TextStyle(fontFamily: 'sora'),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Already an User?",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'sora',
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                  );
                                },
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'sora',
                                    color: Color(0xFF2A544E),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
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

  Widget buildTextField(String labelText, bool isPassword, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(fontSize: 14, fontFamily: 'sora'),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
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
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  SocialButton({required this.icon, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Color(0xFF33497B), size: 24),
      label: Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF33497B),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: Colors.grey.shade300),
        elevation: 0,
      ),
    );
  }
}