import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Urls.dart';

class ProfileUpdateScreen extends StatefulWidget {
  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // Controllers for form fields
  final TextEditingController addressController = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // State variables
  String selectedCountry = "United States";
  String selectedGender = "Male";
  bool isLoading = true;
  bool isFormChanged = false;
  String? sessionId;
  String? profilePicPath;
  String? base64Image;
  File? _imageFile;

  // Original values to track changes
  Map<String, dynamic> originalValues = {};

  // Dropdown options
  final List<String> countryOptions = [

    "India",

  ];

  final List<String> genderOptions = ["Male", "Female", "Other"];

  @override
  void initState() {
    super.initState();
    _loadSessionId().then((_) {
      _fetchUserProfile();
    });
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sessionId = prefs.getString('Session-ID');
    });
  }

  // Helper method to normalize dropdown values
  String _normalizeDropdownValue(String value, List<String> options) {
    if (value.isEmpty) return options.first;

    // First try exact match
    if (options.contains(value)) {
      return value;
    }

    // Try case-insensitive match
    String lowerValue = value.toLowerCase();
    for (String option in options) {
      if (option.toLowerCase() == lowerValue) {
        return option;
      }
    }

    // Try partial match
    for (String option in options) {
      if (option.toLowerCase().contains(lowerValue) ||
          lowerValue.contains(option.toLowerCase())) {
        return option;
      }
    }

    // Return first option as fallback
    return options.first;
  }

  Future<void> _fetchUserProfile() async {
    if (sessionId == null) {
      _showErrorSnackbar('No session ID found. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$ip/getprofile.php'),
        headers: {
          'Session-ID': sessionId!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final user = data['data'];

          setState(() {
            // Set form values
            addressController.text = user['address1'] ?? '';
            address2Controller.text = user['address2'] ?? '';
            emailController.text = user['email_id'] ?? '';

            // Normalize dropdown values to match available options
            selectedGender = _normalizeDropdownValue(
                user['gender'] ?? 'Male',
                genderOptions
            );
            selectedCountry = _normalizeDropdownValue(
                user['country'] ?? 'United States',
                countryOptions
            );

            profilePicPath = user['profile_pic'];

            // print('Profile pic path: $ip$profilePicPath');

            // Store original values to track changes
            originalValues = {
              'address1': addressController.text,
              'address2': address2Controller.text,
              'email_id': emailController.text,
              'gender': selectedGender,
              'country': selectedCountry,
              'profile_pic': profilePicPath,
            };

            isLoading = false;
          });
        } else {
          _showErrorSnackbar(data['message'] ?? 'Failed to load profile');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        _showErrorSnackbar('Server error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Network error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _checkFormChanges() {
    if (originalValues.isEmpty) return;

    bool changed =
        addressController.text != originalValues['address1'] ||
            address2Controller.text != originalValues['address2'] ||
            emailController.text != originalValues['email_id'] ||
            selectedGender != originalValues['gender'] ||
            selectedCountry != originalValues['country'] ||
            _imageFile != null;

    setState(() {
      isFormChanged = changed;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        isFormChanged = true;
      });

      // Convert to base64
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }
  }

  Future<void> _updateUserDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Session Expired. Please log in again."), backgroundColor: Colors.red),
        );
        return;
      }

      // Prepare headers
      Map<String, String> headers = {
        "Session-ID": sessionId,
        "Content-Type": "application/json"
      };

      // Prepare data for user details update
      Map<String, dynamic> requestData = {
        "session_id": sessionId,
        "email_id": emailController.text,
        "address1": addressController.text,
        "address2": address2Controller.text,
        'gender': selectedGender,
        'country': selectedCountry,
      };

      print("Updating User Details: $requestData");

      final response = await http.post(
        Uri.parse('$ip/userupdate.php'),
        headers: headers,
        body: json.encode(requestData),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User details updated successfully'), backgroundColor: Colors.green),
        );

        // Update original values to reflect changes
        originalValues = {
          'address1': addressController.text,
          'address2': address2Controller.text,
          'email_id': emailController.text,
          'gender': selectedGender,
          'country': selectedCountry,
          'profile_pic': profilePicPath,
        };

        setState(() {
          isFormChanged = false;
        });

        _fetchUserProfile(); // Refresh user data
      } else {
        _showErrorSnackbar(data['message'] ?? 'Failed to update user details');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
      print('Update error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    if (_imageFile == null) {
      _showErrorSnackbar("No image selected");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Session Expired. Please log in again."), backgroundColor: Colors.red),
        );
        return;
      }

      // Convert image to Base64
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Prepare headers
      Map<String, String> headers = {
        "Session-ID": sessionId,
        "Content-Type": "application/json"
      };

      // Prepare data for profile picture update
      Map<String, dynamic> requestData = {
        "session_id": sessionId,
        "profile_pic": base64Image
      };

      print("Updating Profile Picture...");

      final response = await http.post(
        Uri.parse('$ip/update_profile_picture.php'),
        headers: headers,
        body: json.encode(requestData),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully'), backgroundColor: Colors.green),
        );

        setState(() {
          _imageFile = null;
          isFormChanged = false;
        });

        _fetchUserProfile(); // Refresh user data
      } else {
        _showErrorSnackbar(data['message'] ?? 'Failed to update profile picture');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isFormChanged)
            TextButton(
              onPressed: _updateUserDetails,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchUserProfile,
        color: Color(0xFF0F766E),
        child: isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F766E)),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            onChanged: _checkFormChanges,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF0F766E).withOpacity(0.2),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Color(0xFFF1F5F9),
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (profilePicPath != null && profilePicPath!.isNotEmpty
                                      ? NetworkImage('$ip/$profilePicPath')
                                      : null) as ImageProvider<Object>?,
                                  child: _imageFile == null &&
                                      (profilePicPath == null || profilePicPath!.isEmpty)
                                      ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF94A3B8),
                                  )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0F766E),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF0F766E).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tap to change profile picture',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        if (_imageFile != null) ...[
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateProfilePicture,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Update Picture'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Form Fields
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Email
                      _buildTextField(
                        "Email Address",
                        emailController,
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+").hasMatch(value)) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Address 1
                      _buildTextField(
                        "Address Line 1",
                        addressController,
                        Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Address is required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Address 2
                      _buildTextField(
                        "Address Line 2 (Optional)",
                        address2Controller,
                        Icons.location_city_outlined,
                      ),
                      SizedBox(height: 16),

                      // Dropdowns Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomDropdown(
                              "Country",
                              countryOptions,
                              selectedCountry,
                              Icons.public,
                                  (value) {
                                setState(() {
                                  selectedCountry = value!;
                                  _checkFormChanges();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildCustomDropdown(
                              "Gender",
                              genderOptions,
                              selectedGender,
                              Icons.person_outline,
                                  (value) {
                                setState(() {
                                  selectedGender = value!;
                                  _checkFormChanges();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Update Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isFormChanged ? _updateUserDetails : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F766E),
                      disabledBackgroundColor: Color(0xFF94A3B8),
                      foregroundColor: Colors.white,
                      elevation: isFormChanged ? 4 : 0,
                      shadowColor: Color(0xFF0F766E).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isFormChanged ? "UPDATE PROFILE" : "NO CHANGES",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF0F766E)),
        labelStyle: TextStyle(color: Color(0xFF6B7280)),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0F766E), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      onChanged: (value) {
        _checkFormChanges();
      },
    );
  }

  Widget _buildCustomDropdown(
      String label,
      List<String> items,
      String selectedValue,
      IconData icon,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: selectedValue,
            onChanged: onChanged,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Icon(icon, color: Color(0xFF0F766E), size: 18),
                    SizedBox(width: 12),
                    Text(
                      item,
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}