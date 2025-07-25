import 'package:flutter/material.dart';
import 'package:npc/Urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserScreens/ChangePassword.dart';
import 'edit_profile.dart';
import 'login_page.dart';
import 'privacy_policy.dart';
import 'contact_us.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isPushNotificationEnabled = true;
  bool isDarkModeEnabled = false;

  // Profile data variables
  String userName = "Loading...";
  String profilePicUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('Session-ID');

      if (sessionId == null) {
        // Handle no session ID case
        setState(() {
          userName = "Guest User";
          isLoading = false;
        });
        return;
      }

      // Replace with your actual API endpoint
      final response = await http.get(
        Uri.parse('$ip/getprofile.php'), // Replace with your API URL
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            // Extract name from email or use a separate name field if available
            userName = _extractNameFromEmail(data['data']['email_id']);
            profilePicUrl = data['data']['profile_pic'] ?? "";
            isLoading = false;
          });
        } else {
          setState(() {
            userName = "User";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          userName = "User";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = "User";
        isLoading = false;
      });
      print('Error fetching profile: $e');
    }
  }

  String _extractNameFromEmail(String email) {
    // Extract name from email before @ symbol and capitalize
    String namePart = email.split('@')[0];
    return namePart.split('.').map((word) =>
    word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  Future<void> _clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('Session-ID'); // Clears the stored session ID
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          // White Background for All Content
          Positioned.fill(
            child: Container(
              color: Colors.grey.shade100,
            ),
          ),
          // Floating Green Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.30,
              color: Color(0xFF4A9589),
            ),
          ),
          // Main Content with Floating White Box
          Positioned(
            top: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).toInt()), // 10% opacity
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Row(
                        children: [
                          // Profile Picture with loading state
                          isLoading
                              ? CircleAvatar(
                            radius: screenWidth * 0.08,
                            backgroundColor: Colors.grey.shade300,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9589)),
                            ),
                          )
                              : CircleAvatar(
                            radius: screenWidth * 0.08,
                            backgroundImage: profilePicUrl.isNotEmpty
                                ? NetworkImage('$ip/'+profilePicUrl)
                                : AssetImage("assets/images/profile.png") as ImageProvider,
                            onBackgroundImageError: profilePicUrl.isNotEmpty
                                ? (exception, stackTrace) {
                              // Handle image loading error
                              print('Error loading profile image: $exception');
                            }
                                : null,
                            child: profilePicUrl.isEmpty
                                ? Icon(
                              Icons.person,
                              size: screenWidth * 0.08,
                              color: Colors.grey.shade600,
                            )
                                : null,
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          // User Name with loading state
                          Expanded(
                            child: isLoading
                                ? Container(
                              height: 20,
                              width: screenWidth * 0.3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                                : Text(
                              userName,
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.045,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Account Settings Section
                    _buildSectionHeader(
                        "Account Settings", screenWidth, screenHeight),
                    _buildSettingsTile("Edit profile", Icons.arrow_forward_ios,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileUpdateScreen(),
                            ),
                          ).then((_) {
                            // Refresh profile data when returning from edit profile
                            _fetchUserProfile();
                          });
                        }),
                    _buildSettingsTile(
                      "Change password",
                      Icons.arrow_forward_ios,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangePassword(),
                          ),
                        );
                      },
                    ),

                    // _buildToggleTile(
                    //   "Dark mode",
                    //   isDarkModeEnabled,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       isDarkModeEnabled = value;
                    //     });
                    //   },
                    // ),
                    SizedBox(height: screenHeight * 0.02),
                    // More Section
                    _buildSectionHeader("More", screenWidth, screenHeight),
                    _buildSettingsTile("Privacy Policy",
                        Icons.arrow_forward_ios, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivacyPolicyPage(),
                            ),
                          );
                        }),
                    _buildSettingsTile("Contact Us",
                        Icons.arrow_forward_ios, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactPage(),
                            ),
                          );
                        }),
                    _buildSettingsTile(
                      "Logout",
                      Icons.arrow_forward_ios,
                      onTap: () async {
                        _showLogoutDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Header Title Positioned on Top
          Positioned(
            top: screenHeight * 0.08,
            left: screenWidth * 0.05,
            child: Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 28),
                SizedBox(width: 2),
                Text(
                  "Settings",
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          // Handle Navigation
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.red.shade600,
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),

                // Message
                Text(
                  'Are you sure you want to logout from your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),

                    // Logout Button
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog first

                            // Show loading indicator
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4A9589),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Logging out...',
                                        style: TextStyle(
                                          fontFamily: 'Sora',
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            // Perform logout
                            await _performLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Add this method to handle the actual logout process:
  Future<void> _performLogout() async {
    try {
      // Clear session data
      await _clearSession();

      // Small delay to show loading
      await Future.delayed(Duration(milliseconds: 500));

      // Close loading dialog and navigate to login
      Navigator.of(context).pop(); // Close loading dialog

      // Navigate to login screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
            (route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged out successfully',
            style: TextStyle(fontFamily: 'Sora'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out. Please try again.',
            style: TextStyle(fontFamily: 'Sora'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Widget _buildSettingsTile(String title, IconData icon,
      {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      trailing: Icon(
        icon,
        color: Colors.grey,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
      String title, bool value, {required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      value: value,
      activeColor: Color(0xFF4A9589),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionHeader(
      String title, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.01,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}