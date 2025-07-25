import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:npc/Urls.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class NewServiceForm extends StatefulWidget {
  @override
  _NewServiceFormState createState() => _NewServiceFormState();
}

class _NewServiceFormState extends State<NewServiceForm> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> addService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get session ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      if (sessionId == null) {
        _showErrorSnackBar("Session ID not found. Please login again.");
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(ip + 'add_service.php'));

      // Add session ID header
      request.headers['Session-ID'] = sessionId;

      // Add text fields
      request.fields['service_name'] = _serviceNameController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();

      // Add image file if selected
      if (_imageFile != null) {
        var fileName = path.basename(_imageFile!.path);
        var multipartFile = await http.MultipartFile.fromPath(
            'service_image',
            _imageFile!.path,
            filename: fileName
        );
        request.files.add(multipartFile);
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(response.body);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          // Success case
          _showSuccessSnackBar("Service added successfully!");
          _serviceNameController.clear();
          _descriptionController.clear();
          setState(() {
            _imageFile = null;
          });
        } else {
          // Error from server
          _showErrorSnackBar("Failed to add service: ${jsonResponse['message']}");
        }
      } else {
        // Error case
        _showErrorSnackBar("Failed to add service: ${response.body}");
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        // Simple top position without complex calculations
        margin: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        // Simple top position without complex calculations
        margin: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add New Service", style: TextStyle(fontFamily: 'sora')),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Service Name Input
                Text(
                  'Service Name:',
                  style: TextStyle(fontSize: 14, fontFamily: 'sora'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Service Name',
                    hintStyle: TextStyle(fontFamily: 'sora', color: Color(0xFF000000).withOpacity(0.2), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Description Input
                Text(
                  'Description:',
                  style: TextStyle(fontSize: 14, fontFamily: 'sora'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter Service Description',
                    hintStyle: TextStyle(fontFamily: 'sora', color: Color(0xFF000000).withOpacity(0.2), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image Upload Section
                Text(
                  'Service Image:',
                  style: TextStyle(fontSize: 14, fontFamily: 'sora'),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageFile = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          child: Text(
                            'Select Image',
                            style: TextStyle(fontFamily: 'sora', color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : addService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontFamily: 'sora', color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}