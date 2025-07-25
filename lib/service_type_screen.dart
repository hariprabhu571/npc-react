import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Urls.dart';

class ServiceTypeScreen extends StatefulWidget {
  final String serviceName;
  final bool isEditing;
  final String? serviceId;

  const ServiceTypeScreen({
    Key? key,
    required this.serviceName,
    this.isEditing = false,
    this.serviceId,
  }) : super(key: key);

  @override
  _ServiceTypeScreenState createState() => _ServiceTypeScreenState();
}

class _ServiceTypeScreenState extends State<ServiceTypeScreen> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.serviceId != null) {
      _fetchServiceTypeDetails();
    }
  }

  Future<void> _fetchServiceTypeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      if (sessionId == null) {
        setState(() {
          _errorMessage = "Session ID not found. Please login again.";
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$ip/get_service_type_details.php?service_id=${widget.serviceId}'),
        headers: {
          'Session-ID': sessionId,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          _typeController.text = responseData['service_type_name'];
          _priceController.text = responseData['price'].toString();
        } else {
          setState(() {
            _errorMessage = responseData['message'];
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to fetch data: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitServiceType() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString("Session-ID");

      if (sessionId == null) {
        _showErrorSnackBar("Session ID not found. Please login again.");
        return;
      }

      final Map<String, dynamic> requestBody = {
        "service_name": widget.serviceName,
        "service_type_name": _typeController.text.trim(),
        "price": _priceController.text.trim(),
      };

      final Uri url = widget.isEditing
          ? Uri.parse('$ip/update_service_type.php')
          : Uri.parse('$ip/add_service_type.php');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Session-ID': sessionId,
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 'success') {
        _showSuccessSnackBar(widget.isEditing
            ? "Service type updated successfully!"
            : "Service type added successfully!");
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar("Failed: ${responseData['message']}");
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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Edit Service Type" : "Add Service Type"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: "Service Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitServiceType,
              child: Text(widget.isEditing ? "Update" : "Add"),
            ),
          ],
        ),
      ),
    );
  }
}
