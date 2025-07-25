import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:npc/Urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class OfferDetailsBottomSheet extends StatefulWidget {
  final Function? onOfferAdded;

  const OfferDetailsBottomSheet({Key? key, this.onOfferAdded}) : super(key: key);

  @override
  _OfferDetailsBottomSheetState createState() =>
      _OfferDetailsBottomSheetState();
}

class _OfferDetailsBottomSheetState extends State<OfferDetailsBottomSheet> {
  final TextEditingController _offerNameController = TextEditingController();
  final TextEditingController _couponNumberController = TextEditingController();
  final TextEditingController _offerStartDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _offerPercentController = TextEditingController();
  String? _offerBannerFileName;
  String? _base64OfferBanner;
  bool _isLoading = false;

  // Focus nodes for form fields
  final FocusNode _offerNameFocus = FocusNode();
  final FocusNode _couponNumberFocus = FocusNode();
  final FocusNode _startDateFocus = FocusNode();
  final FocusNode _expiryDateFocus = FocusNode();
  final FocusNode _percentFocus = FocusNode();

  Future<void> _pickOfferBanner() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
        withData: true, // Get file bytes
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          _offerBannerFileName = file.name;
          // Convert file bytes to base64
          if (file.bytes != null) {
            _base64OfferBanner = base64Encode(file.bytes!);
          } else if (file.path != null) {
            // For platforms where bytes might not be available directly
            final bytes = File(file.path!).readAsBytesSync();
            _base64OfferBanner = base64Encode(bytes);
          }
        });
        print("Selected Offer Banner File: $_offerBannerFileName");
      } else {
        print("No file selected");
      }
    } catch (e) {
      print("Error picking Offer Banner: $e");
      _showErrorSnackBar("Error selecting file: ${e.toString()}");
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 1095)), // 3 years ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF37786D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format date as YYYY-MM-DD for API
      final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = formattedDate;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  bool _validateInputs() {
    if (_offerNameController.text.isEmpty) {
      _showErrorSnackBar("Please enter offer name");
      _offerNameFocus.requestFocus();
      return false;
    }

    if (_couponNumberController.text.isEmpty) {
      _showErrorSnackBar("Please enter coupon number");
      _couponNumberFocus.requestFocus();
      return false;
    }

    if (_offerStartDateController.text.isEmpty) {
      _showErrorSnackBar("Please select start date");
      _startDateFocus.requestFocus();
      return false;
    }

    if (_expiryDateController.text.isEmpty) {
      _showErrorSnackBar("Please select expiry date");
      _expiryDateFocus.requestFocus();
      return false;
    }

    if (_offerPercentController.text.isEmpty) {
      _showErrorSnackBar("Please enter offer percentage");
      _percentFocus.requestFocus();
      return false;
    }

    // Check if percentage is a valid number
    try {
      double percent = double.parse(_offerPercentController.text);
      if (percent <= 0 || percent > 100) {
        _showErrorSnackBar("Percentage must be between 0 and 100");
        _percentFocus.requestFocus();
        return false;
      }
    } catch (e) {
      _showErrorSnackBar("Please enter a valid percentage");
      _percentFocus.requestFocus();
      return false;
    }

    if (_base64OfferBanner == null) {
      _showErrorSnackBar("Please upload an offer banner");
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    // Get session ID from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("Session-ID")?.trim();

    if (sessionId == null || sessionId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Session expired. Please login again.");
      return;
    }

    try {
      // Prepare request data
      Map<String, dynamic> requestData = {
        "offer_name": _offerNameController.text,
        "coupon_number": _couponNumberController.text,
        "offer_starts_on": _offerStartDateController.text,
        "expires_on": _expiryDateController.text,
        "offer_percentage": double.parse(_offerPercentController.text),
        "offer_banner": _base64OfferBanner,
      };

      // Set headers with session ID
      Map<String, String> headers = {
        "Session-ID": sessionId,
        "Content-Type": "application/json",
        "Accept": "application/json"
      };

      // Make POST request
      final response = await http.post(
        Uri.parse(ip+'add_offers.php'),
        headers: headers,
        body: jsonEncode(requestData),
      );
      print(response.body);

      // Process response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          _showSuccessSnackBar(responseData['message'] ?? "Offer added successfully!");
          // Call the callback if provided
          if (widget.onOfferAdded != null) {
            widget.onOfferAdded!();
          }
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          _showErrorSnackBar(responseData['message'] ?? "Failed to add offer.");
        }
      } else {
        _showErrorSnackBar("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    _offerNameController.dispose();
    _couponNumberController.dispose();
    _offerStartDateController.dispose();
    _expiryDateController.dispose();
    _offerPercentController.dispose();

    _offerNameFocus.dispose();
    _couponNumberFocus.dispose();
    _startDateFocus.dispose();
    _expiryDateFocus.dispose();
    _percentFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (_, controller) => Material(  // Add this Material widget
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'sora',
                            color: _isLoading ? Colors.grey : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Add A New Offer \nDetails',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'sora',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37786D),
                          ),
                        ),
                      ),
                      SizedBox(width: 60),
                    ],
                  ),
                  SizedBox(height: 25),
                  _buildLabeledTextField(
                      'Offer Name',
                      _offerNameController,
                      'New Offer',
                      focusNode: _offerNameFocus
                  ),
                  SizedBox(height: 20),
                  _buildLabeledTextField(
                      'Coupon Number',
                      _couponNumberController,
                      'AS34ejJ@qw',
                      focusNode: _couponNumberFocus
                  ),
                  SizedBox(height: 20),
                  _buildDateField(
                      'Offer Starts On',
                      _offerStartDateController,
                      'YYYY-MM-DD',
                      _startDateFocus
                  ),
                  SizedBox(height: 20),
                  _buildDateField(
                      'Expires On',
                      _expiryDateController,
                      'YYYY-MM-DD',
                      _expiryDateFocus
                  ),
                  SizedBox(height: 20),
                  _buildLabeledTextField(
                      'Offer Percent',
                      _offerPercentController,
                      '%',
                      keyboardType: TextInputType.number,
                      focusNode: _percentFocus
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Offer Banner',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'sora',
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: _isLoading ? null : _pickOfferBanner,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF37786D).withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF37786D).withOpacity(0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_upload, color: Color(0xFF37786D), size: 40),
                          SizedBox(height: 8),
                          Text(
                            _offerBannerFileName ??
                                'Choose file to Upload Jpg, Png, or Pdf',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'sora',
                              color: _offerBannerFileName == null
                                  ? Colors.black.withOpacity(0.5)
                                  : Color(0xFF37786D),
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 35),
                  Center(
                    child: SizedBox(
                      width: 210,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Color(0xFF37786D).withOpacity(0.6) : Color(0xFF37786D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                        )
                            : Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'sora',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
              // Full-screen loading overlay (only visible when isLoading is true)
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label,
      TextEditingController controller,
      String hint,
      {
        TextInputType keyboardType = TextInputType.text,
        bool isMultiline = false,
        FocusNode? focusNode,
      }
      ) {
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
            focusNode: focusNode,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                fontFamily: 'sora',
                color: Colors.grey.withOpacity(0.3),
              ),
              border: InputBorder.none,
            ),
            keyboardType: keyboardType,
            maxLines: isMultiline ? 4 : 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label,
      TextEditingController controller,
      String hint,
      FocusNode focusNode,
      ) {
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
        GestureDetector(
          onTap: _isLoading ? null : () => _selectDate(context, controller),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: false, // Disable direct editing
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontFamily: 'sora',
                  color: Colors.grey.withOpacity(0.3),
                ),
                border: InputBorder.none,
                suffixIcon: Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF37786D),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}