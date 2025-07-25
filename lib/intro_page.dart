import 'package:flutter/material.dart';
import 'package:npc/login_page.dart';
import 'sign_up_page.dart';


class IntroPage extends StatefulWidget {
  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  final List<Map<String, String>> _pages = [
    {
      "title": "Exceptional Customer Service",
      "description": "We are always looking for ways to improve and hone our customer experience skills.",
      "image": "assets/images/customer_service.png"
    },
    {
      "title": "Immediate, Same-Day Service",
      "description": "Get a pest professional out fast with our same-day appointments.",
      "image": "assets/images/same_day_service.png"
    },
    {
      "title": "Contact Us for a Free Estimate",
      "description": "We make it easy to get started with a completely free quote.",
      "image": "assets/images/free_estimate.png"
    },
  ];

  void _onPageTapped() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Handle navigation after the last page
      print("Navigate to main screen");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final page = _pages[index];
          return GestureDetector(
            onTap: _onPageTapped,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Image.asset(
                  page["image"]!,
                  height: 200,
                ),
                SizedBox(height: 20),
                Text(
                  page["title"]!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: "Sora",
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    page["description"]!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: "Sora",
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (dotIndex) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == dotIndex ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == dotIndex
                            ? Color(0xFF4A9589)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 80),
                if (index == _pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 100.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A9589),
                            fixedSize: Size(140, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              fontFamily: "Sora",
                              color:Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A9589),
                            fixedSize: Size(140, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: Text(
                            "Log in",
                            style: TextStyle(
                              fontFamily: "Sora",
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(height: 80),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _currentPage < _pages.length - 1
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
          onPressed: () => _onPageTapped(),
          child: Text(
            "Skip",
            style: TextStyle(
              fontFamily: "Sora",
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}