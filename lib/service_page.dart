import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Urls.dart';
import 'add_new_service.dart';
import 'old_service_form.dart';

class ServicesPage extends StatefulWidget {
  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchServices();
    searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchServices() async {

    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("Session-ID");
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session Expired. Please log in again."), backgroundColor: Colors.red),
      );
      return;
    }
    Map<String, String> headers = {"Session-ID": sessionId, "Content-Type": "application/json"};

    final String url = ip+"fetch_services.php"; // Update with actual URL
    final response = await http.get(Uri.parse(url),headers:headers );
    //print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData["status"] == "success") {
        setState(() {
          services = List<Map<String, dynamic>>.from(responseData["services"]);
          filteredServices = services;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _filterServices() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredServices = services.where((service) {
        return service['service_name'].toLowerCase().contains(query) ||
            service['description'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A9589).withOpacity(0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4A9589)),
                      hintText: 'Search here',
                      hintStyle: TextStyle(
                        fontFamily: 'sora',
                        fontSize: 14,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontFamily: 'sora',
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewServiceForm()),
                    );
                  },
                  child: Text(
                    '+ Add',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A9589),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A9589),
                  ),
                ),
              )
            else if (hasError)
              Expanded(
                child: Center(
                  child: Text(
                    'Failed to load services',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.red,
                    ),
                  ),
                ),
              )
            else if (filteredServices.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No services found',
                      style:
                      TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return buildServiceCard(
                        context,
                        service['service_name'],
                        service['created_at'],
                        service['description'],
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget buildServiceCard(
      BuildContext context, String title, String lastUpdated, String description) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 0,
      color: Color(0xFF4A9589).withOpacity(0.09),
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: screenWidth * 0.00),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 10,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFF2A3C66),
            fontFamily: 'sora',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.043,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Last updated: $lastUpdated',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'sora',
                fontSize: screenWidth * 0.03,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontFamily: 'sora',
                fontSize: screenWidth * 0.03,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Color(0xFF4A9589), size: screenWidth * 0.06),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceTypeManager(
                serviceName: title,
                isEditing: true,

              ),
            ),
          );
        },
      ),
    );
  }
}
