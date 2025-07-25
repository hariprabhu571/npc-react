import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:npc/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_details_page.dart';
import 'service_page.dart';
import 'offer_details_page.dart';
import 'employee_page.dart';
import 'sign_up_page.dart';



class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFFFFF),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
          top: width * 0.18,
          bottom: width * 0.05,
          right: width * 0.05,
          left: width * 0.05,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with Welcome Text and Profile Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome to \nNPC Admin',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                    ),
                  ),Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: Colors.white, // Set the background color to white
                    ),
                    child: PopupMenuButton(
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: Colors.black,
                        size: 50,
                      ),
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            value: 'logout',
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 16,
                                color: Color(0xFF086D21), // Set the text color to #086D21
                              ),
                            ),
                          ),
                        ];
                      },
                      onSelected: (value) async {
                        if (value == 'logout') {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.remove('Session-ID');
                          _logout(context);
                        }
                      },
                    ),
                  ),

                ],
              ),
              SizedBox(height: 18),
              // Highlight Box
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.2,
                padding: EdgeInsets.only(top: 50, bottom: 10, left: 16, right: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A9589), Color(0xFF0C111D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WOW!!!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sora',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Today we got extra 10 orders......',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 26),
              // Management Records Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Management Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sora',
                    ),
                  ),
                  const SizedBox(height: 15),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                        padding: EdgeInsets.zero,
                        children: [
                          ManagementCard(
                            title: "Order Details",
                            description: "View",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AdminOrderPage()),
                              );
                            },
                          ),
                          ManagementCard(
                            title: "Employee Details",
                            description: "View",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EmployeeProfilesPage()),
                              );
                            },
                          ),
                          ManagementCard(
                            title: "Service Details",
                            description: "View",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ServicesPage()),
                              );
                            },
                          ),
                          ManagementCard(
                            title: "Offer \nDetails",
                            description: "View",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => OfferDetailsPage()),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    ); // Example navigation
  }
}


class ManagementCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  ManagementCard({required this.title, required this.description,required this.onPressed,});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A9589), Color(0xFF0C111D)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Icon at the top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.open_in_new, color: Colors.white, size: 30),
            ),

            // Title text
            Positioned(
              top: 40, // Adjust the top position for the title
              left: 0,
              right: 0, // Allow text to take up the full width
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sora',
                ),
                softWrap: true, // Enable text wrapping
                overflow: TextOverflow.visible, // Ensure overflow is visible
              ),
            ),
        // "View" button at the bottom
            Positioned(
              bottom: 10, // Distance from the bottom
              left: 0,
              right: 0,
              child: Center(
                child:// Dynamic width

                SizedBox(
                width: 120,
                child: OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            ),
            ),
          ],
        ),
      ),
    );
  }
}


