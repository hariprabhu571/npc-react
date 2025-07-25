import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Urls.dart';
import 'add_offers_page.dart';

class OfferDetailsPage extends StatefulWidget {
  @override
  _OfferDetailsPageState createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  List<Map<String, dynamic>> allOffers = [];
  List<Map<String, dynamic>> filteredOffers = [];
  String filterStatus = "All"; // "All", "Active", "Expired"
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchOffers();

    // Add listener for search functionality
    searchController.addListener(() {
      applyFilters();
    });
  }

  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('Session-ID');
  }

  Future<void> fetchOffers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final sessionId = await getSessionId();
      if (sessionId == null) {
        throw Exception("Session ID not found");
      }

      final response = await http.get(
        Uri.parse(ip+'fetch_all_offers.php'),
        headers: {
          'Session-ID': sessionId,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            if (data.containsKey('offers')) {
              allOffers = List<Map<String, dynamic>>.from(data['offers'].map((offer) {
                return {
                  'offer_id': offer['offer_id'],
                  'offerName': offer['offer_name'],
                  'couponNumber': offer['coupon_number'],
                  'status': offer['status'],
                  'startDate': offer['offer_starts_on'],
                  'endDate': offer['expires_on'],
                  'percent': '${offer['offer_percentage']}% off',
                  'banner': offer['offer_banner_location'],
                };
              }));
              applyFilters();
            } else {
              allOffers = [];
              filteredOffers = [];
            }
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load offers';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteOffer(String offerId) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A9589),
          ),
        );
      },
    );

    try {
      final sessionId = await getSessionId();
      if (sessionId == null) {
        throw Exception("Session ID not found");
      }

      final response = await http.get(
        Uri.parse(ip+'delete_offers.php?offer_id=$offerId'),
        headers: {
          'Session-ID': sessionId,
        },
      ).timeout(Duration(seconds: 10));

      // Close the loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Offer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the offers list
          fetchOffers();
        } else {
          showErrorDialog(data['message'] ?? 'Failed to delete offer');
        }
      } else {
        showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Close the loading dialog if still open
      Navigator.pop(context);
      showErrorDialog('Network error: $e');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteConfirmationDialog(String offerId, String offerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Offer'),
          content: Text('Are you sure you want to delete "$offerName"?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteOffer(offerId);
              },
            ),
          ],
        );
      },
    );
  }

  void applyFilters() {
    setState(() {
      String searchTerm = searchController.text.toLowerCase();

      filteredOffers = allOffers.where((offer) {
        // Apply status filter
        bool statusMatches = filterStatus == "All" ||
            offer['status'] == filterStatus;

        // Apply search filter
        bool searchMatches = searchTerm.isEmpty ||
            offer['offerName'].toLowerCase().contains(searchTerm) ||
            offer['couponNumber'].toLowerCase().contains(searchTerm);

        return statusMatches && searchMatches;
      }).toList();
    });
  }

  void showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'sora',
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'sora',
                  fontWeight: FontWeight.w600,
                ),
              ),
              RadioListTile<String>(
                title: Text('All Offers', style: TextStyle(fontFamily: 'sora')),
                value: 'All',
                groupValue: filterStatus,
                activeColor: Color(0xFF4A9589),
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    filterStatus = value!;
                    applyFilters();
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Active Only', style: TextStyle(fontFamily: 'sora')),
                value: 'Active',
                groupValue: filterStatus,
                activeColor: Color(0xFF4A9589),
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    filterStatus = value!;
                    applyFilters();
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Expired Only', style: TextStyle(fontFamily: 'sora')),
                value: 'Expired',
                groupValue: filterStatus,
                activeColor: Color(0xFF4A9589),
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    filterStatus = value!;
                    applyFilters();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
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
            icon: Icon(CupertinoIcons.back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 0.0),
            child: Row(
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
                          fontFamily: 'sora',
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.filter_list, color: Color(0xFF4A9589)),
                  onPressed: showFilterOptions,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Offers Placed',
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontFamily: 'sora',
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
                        return OfferDetailsBottomSheet(
                          onOfferAdded: () {
                            fetchOffers(); // Refresh the offers list when a new offer is added
                          },
                        );
                      },
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
            if (filterStatus != "All")
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFEAF3EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Status: $filterStatus',
                            style: TextStyle(
                              fontFamily: 'sora',
                              fontSize: 12,
                              color: Color(0xFF4A9589),
                            ),
                          ),
                          SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                filterStatus = "All";
                                applyFilters();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF4A9589),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4A9589),
                ),
              )
                  : errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        fontFamily: 'sora',
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchOffers,
                      child: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A9589),
                      ),
                    ),
                  ],
                ),
              )
                  : filteredOffers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: Colors.grey,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No offers found',
                      style: TextStyle(
                        fontFamily: 'sora',
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchOffers,
                color: Color(0xFF4A9589),
                child: ListView.builder(
                  itemCount: filteredOffers.length,
                  itemBuilder: (context, index) {
                    final offer = filteredOffers[index];
                    return Dismissible(
                      key: Key(offer['offer_id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        showDeleteConfirmationDialog(offer['offer_id'], offer['offerName']);
                        return false; // Don't dismiss yet, wait for confirmation
                      },
                      child: buildOfferCard(
                        context: context,
                        offer_id: offer['offer_id'],
                        offerName: offer['offerName'],
                        couponNumber: offer['couponNumber'],
                        status: offer['status'],
                        startDate: offer['startDate'],
                        endDate: offer['endDate'],
                        percent: offer['percent'],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOfferCard({
    required BuildContext context,
    required String offer_id,
    required String offerName,
    required String couponNumber,
    required String status,
    required String startDate,
    required String endDate,
    required String percent,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7.0),
      ),
      elevation: 0,
      color: Color(0xFFEAF3EC),
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offer Name',
                    style: TextStyle(
                      color: Color(0xFF2A3C66),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                  Text(
                    offerName,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.037,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Coupon Number',
                    style: TextStyle(
                      color: Color(0xFF2A3C66),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                  Text(
                    couponNumber,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.028,
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      showDeleteConfirmationDialog(offer_id, offerName);
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'sora',
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: status == 'Active' ? 120 : 120,
                    decoration: BoxDecoration(
                      color: status == 'Active'
                          ? Color(0xFF4A9589)
                          : Color(0xFFE57373),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 17, vertical: 3),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'sora',
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Offer Starts On',
                    style: TextStyle(
                      color: Color(0xFF2A3C66),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    startDate,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.028,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Expires On',
                    style: TextStyle(
                      color: Color(0xFF2A3C66),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    endDate,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.028,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Offer Percent',
                    style: TextStyle(
                      color: Color(0xFF2A3C66),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    percent,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontFamily: 'sora',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.028,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}