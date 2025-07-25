import 'package:flutter/material.dart';
import 'package:npc/Urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_employee_page.dart';

class EmployeeProfilesPage extends StatefulWidget {
  @override
  _EmployeeProfilesPageState createState() => _EmployeeProfilesPageState();
}

class _EmployeeProfilesPageState extends State<EmployeeProfilesPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  bool isLoading = true;
  String errorMessage = '';
  String sortOrder = 'default'; // 'default', 'asc', 'desc'

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    // Add listener to search controller to filter results on text change
    searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed
    searchController.removeListener(_filterEmployees);
    searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    final query = searchController.text.toLowerCase();

    setState(() {
      // If search field is empty, show all employees (with current sort)
      if (query.isEmpty) {
        filteredEmployees = List.from(employees);
      } else {
        // Filter employees based on search query across multiple fields
        filteredEmployees = employees.where((employee) {
          return employee['name']?.toLowerCase().contains(query) == true ||
              employee['mobile']?.toLowerCase().contains(query) == true ||
              employee['email']?.toLowerCase().contains(query) == true ||
              employee['serviceType']?.toLowerCase().contains(query) == true ||
              employee['address']?.toLowerCase().contains(query) == true;
        }).toList();
      }

      // Apply current sort order to filtered results
      _applySorting();
    });
  }

  void _applySorting() {
    if (sortOrder == 'asc') {
      filteredEmployees.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (sortOrder == 'desc') {
      filteredEmployees.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
    }
    // 'default' order doesn't need sorting as it uses the original order
  }

  void _changeSortOrder(String newOrder) {
    setState(() {
      sortOrder = newOrder;
      _applySorting();
    });
  }

  Future<void> fetchEmployees() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? sessionId = prefs.getString("Session-ID")?.trim();

    if (sessionId == null || sessionId.trim().isEmpty) {
      print("Session ID is null or empty, stopping request.");
      return; // Stop execution if session ID is invalid
    }

    Map<String, String> headers = {
      "Session-ID": sessionId ?? "", // Default to empty string
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    try {
      print("Final Headers: $headers");
      final response = await http.post(
        Uri.parse(ip+'get_technicians.php'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> techniciansList = responseData['data'];

          setState(() {
            employees = techniciansList.map((tech) => {
              'id': tech['technician_id'],
              'name': tech['employee_name'],
              'mobile': tech['phone_number'],
              'address': tech['address'],
              'email': tech['email'],
              'serviceType': tech['service_type'],
              'idProof': tech['id_proof'],
            }).toList();

            // Initialize filtered list with all employees
            filteredEmployees = List.from(employees);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load employees: ${responseData['message'] ?? 'Unknown error'}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load employees. Server responded with code ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect to server: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: screenHeight * 0.05,
                  decoration: BoxDecoration(
                    color: Color(0xFFEAF3EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Color(0xFF4A9589)),
                      hintText: 'Search here',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Color(0xFF4A9589), size: 18),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _showFilterOptionsDialog(context);
                },
                child: Icon(Icons.filter_list, color: Color(0xFF4A9589)),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee Profiles',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    if (sortOrder != 'default')
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          sortOrder == 'asc' ? 'A-Z' : 'Z-A',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Color(0xFF4A9589),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (BuildContext context) {
                            return EmployeeDetailsBottomSheet();
                          },
                        );
                      },
                      child: Text(
                        '+ Add',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
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
            else if (errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchEmployees,
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A9589),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredEmployees.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No matching employees found',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              searchController.clear();
                            },
                            child: Text('Clear search'),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF4A9589),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = filteredEmployees[index];
                      return EmployeeCard(
                        employee: employee,
                        onResetPassword: () {
                          _showResetPasswordDialog(context, employee['id']);
                        },
                        onCallTap: () {
                          _makePhoneCall(employee['mobile']);
                        },
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sort Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.sort,
                  color: sortOrder == 'default' ? Color(0xFF4A9589) : Colors.grey,
                ),
                title: Text('Default order'),
                selected: sortOrder == 'default',
                onTap: () {
                  Navigator.pop(context);
                  _changeSortOrder('default');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.arrow_upward,
                  color: sortOrder == 'asc' ? Color(0xFF4A9589) : Colors.grey,
                ),
                title: Text('Name (A to Z)'),
                selected: sortOrder == 'asc',
                onTap: () {
                  Navigator.pop(context);
                  _changeSortOrder('asc');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.arrow_downward,
                  color: sortOrder == 'desc' ? Color(0xFF4A9589) : Colors.grey,
                ),
                title: Text('Name (Z to A)'),
                selected: sortOrder == 'desc',
                onTap: () {
                  Navigator.pop(context);
                  _changeSortOrder('desc');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: sanitizedNumber);

    print('Trying to call: $sanitizedNumber'); // Log for debugging

    if (await canLaunchUrl(phoneUri)) {
      print('Launching: $phoneUri'); // Log successful launch
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch: $phoneUri'); // Log failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to make a call to $sanitizedNumber')),
      );
    }
  }

  void _showResetPasswordDialog(BuildContext context, String employeeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_reset, size: 40, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                'Are you sure you want to reset the password for this employee? The new password will be set to "12345".',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Reset', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetPassword(context, employeeId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword(BuildContext context, String employeeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("Session-ID");
    final url = Uri.parse(ip+'reset_password.php');
    final headers = {
      'Content-Type': 'application/json',
      'Session-ID': sessionId.toString(),
    };
    final body = jsonEncode({
      'technician_id': employeeId,
      'newpassword': '12345',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message']),
          backgroundColor: responseData['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onResetPassword;
  final VoidCallback onCallTap;
  final double screenWidth;
  final double screenHeight;

  const EmployeeCard({
    required this.employee,
    required this.onResetPassword,
    required this.onCallTap,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive font sizes and spacing
    final double titleFontSize = screenWidth * 0.035;
    final double valueFontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.04;
    final double cardPadding = screenWidth * 0.04;
    final double spacingBetween = screenHeight * 0.008;

    // Determine if the screen is very narrow (extra small device)
    bool isVeryNarrow = screenWidth < 320;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color(0xFFEAF3EC),
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: isVeryNarrow
            ? _buildNarrowLayout(titleFontSize, valueFontSize, iconSize, spacingBetween)
            : _buildRegularLayout(titleFontSize, valueFontSize, iconSize, spacingBetween),
      ),
    );
  }

  Widget _buildRegularLayout(double titleFontSize, double valueFontSize, double iconSize, double spacingBetween) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleValue('Employee Name', employee['name'], titleFontSize, valueFontSize),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: buildTitleValue('Mobile No', employee['mobile'], titleFontSize, valueFontSize),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A3C66),
                          ),
                        ),
                        SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: onResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A9589),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size(10, 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: valueFontSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              buildTitleValue('Address', employee['address'], titleFontSize, valueFontSize),
              Text(
                employee['email'],
                style: TextStyle(
                  fontSize: valueFontSize,
                  color: Color(0xFF64748B),
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFDFE9E5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/dummy.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: spacingBetween),
              buildTitleValue('Service Type', employee['serviceType'], titleFontSize, valueFontSize),
              SizedBox(height: spacingBetween),
              GestureDetector(
                onTap: onCallTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Color(0xFF4A9589), size: iconSize),
                    SizedBox(width: 5),
                    Text(
                      'Call service',
                      style: TextStyle(
                        fontSize: valueFontSize,
                        color: Color(0xFF4A9589),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(double titleFontSize, double valueFontSize, double iconSize, double spacingBetween) {
    // For very narrow screens, stack everything vertically
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee image and service type in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color(0xFFDFE9E5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/dummy.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: buildTitleValue('Service Type', employee['serviceType'], titleFontSize, valueFontSize),
            ),
          ],
        ),
        SizedBox(height: spacingBetween),

        // Basic info
        buildTitleValue('Employee Name', employee['name'], titleFontSize, valueFontSize),
        buildTitleValue('Mobile No', employee['mobile'], titleFontSize, valueFontSize),
        buildTitleValue('Address', employee['address'], titleFontSize, valueFontSize),

        // Password reset button
        Padding(
          padding: EdgeInsets.symmetric(vertical: spacingBetween),
          child: Row(
            children: [
              Text(
                'Password',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A3C66),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: onResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A9589),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(10, 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: valueFontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Email
        Text(
          employee['email'],
          style: TextStyle(
            fontSize: valueFontSize,
            color: Color(0xFF64748B),
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),

        // Call button
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: spacingBetween * 2),
            child: GestureDetector(
              onTap: onCallTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, color: Color(0xFF4A9589), size: iconSize),
                  SizedBox(width: 5),
                  Text(
                    'Call service',
                    style: TextStyle(
                      fontSize: valueFontSize,
                      color: Color(0xFF4A9589),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTitleValue(String title, String value, double titleSize, double valueSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A3C66),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              color: Color(0xFF64748B),
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}