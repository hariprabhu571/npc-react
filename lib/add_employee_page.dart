import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'Urls.dart';

class EmployeeDetailsBottomSheet extends StatefulWidget {
  @override
  _EmployeeDetailsBottomSheetState createState() => _EmployeeDetailsBottomSheetState();
}

class _EmployeeDetailsBottomSheetState extends State<EmployeeDetailsBottomSheet> {
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _idProofFileName;
  String? _idProofBase64;

  Future<void> _pickIDProof() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        File file = File(result.files.single.path!);
        List<int> imageBytes = await file.readAsBytes();
        setState(() {
          _idProofFileName = result.files.single.name;
          _idProofBase64 = base64Encode(imageBytes);
        });
      }
    } catch (e) {
      print("Error picking ID Proof: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_employeeNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _serviceTypeController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _idProofBase64 == null ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all the fields and upload ID proof."), backgroundColor: Colors.red),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("Session-ID");

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session Expired. Please log in again."), backgroundColor: Colors.red),
      );
      return;
    }

    Map<String, String> headers = {"Session-ID": sessionId, "Content-Type": "application/json"};

    print(headers);
    Map<String, dynamic> body = {
      "employee_name": _employeeNameController.text,
      "phone_number": _phoneController.text,
      "service_type": _serviceTypeController.text,
      "address": _addressController.text,
      "id_proof": _idProofBase64,
      "email": _emailController.text,
      "password": _passwordController.text
    };

    try {
      var response = await http.post(
        Uri.parse(ip+"add_technician.php"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Employee added successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add employee."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: ListView(controller: controller, children: [
          Center(child: Container(width: 50, height: 5, margin: EdgeInsets.only(top: 5), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.5)))),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 14))),
              Expanded(child: Text('Employee Details Form', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37786D)))),
              SizedBox(width: 60),
            ],
          ),
          SizedBox(height: 25),
          _buildLabeledTextField('Employee Name', _employeeNameController),
          _buildLabeledTextField('Phone No', _phoneController, keyboardType: TextInputType.phone),
          _buildLabeledTextField('Service Type', _serviceTypeController),
          _buildLabeledTextField('Address', _addressController, isMultiline: true),
          _buildLabeledTextField('Email', _emailController),
          _buildLabeledTextField('Password', _passwordController, obscureText: true),
          SizedBox(height: 20),
          Text('ID Proof', style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6))),
          SizedBox(height: 4),
          GestureDetector(
            onTap: _pickIDProof,
            child: Container(padding: EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Color(0xFF37786D).withOpacity(0.22), borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFF37786D).withOpacity(0.5))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.file_upload, color: Color(0xFF37786D), size: 40),
                  SizedBox(height: 8),
                  Text(_idProofFileName ?? 'Choose file to Upload', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5))),
                ])),
          ),
          SizedBox(height: 35),
          Center(child: SizedBox(width: 210, height: 40, child: ElevatedButton(onPressed: _submitForm, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF37786D)), child: Text('Submit', style: TextStyle(color: Colors.white))))),
          SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label,
      TextEditingController controller, {
        String hint = '',
        TextInputType keyboardType = TextInputType.text,
        bool isMultiline = false,
        bool obscureText = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'sora',
            color: Colors.black.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
            ),
            keyboardType: keyboardType,
            maxLines: isMultiline ? 4 : 1,
          ),
        ),
      ],
    );
  }

}
