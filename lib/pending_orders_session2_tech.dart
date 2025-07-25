import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'completed_orders_tech.dart';

class PendingOrdersSession2Tech extends StatefulWidget {
  @override
  _PendingOrdersSession2TechState createState() => _PendingOrdersSession2TechState();
}

class _PendingOrdersSession2TechState extends State<PendingOrdersSession2Tech> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> orders = [
    {
      'name': 'Catherine Brown',
      'mobile': '+91 8940645820',
      'slotDate': '21/02/2025 - 8.00 AM',
      'address': 'DNo.3/42A, kovil street, Chettipedu, Chennai',
      'email': 'mike@yellowbasket.io',
      'paymentMode': 'Cash on Delivery',
    },
    {
      'name': 'Catherine Brown',
      'mobile': '+91 8940645820',
      'slotDate': '21/02/2025 - 8.00 AM',
      'address': 'DNo.3/42A, kovil street, Chettipedu, Chennai',
      'email': 'mike@yellowbasket.io',
      'paymentMode': 'Cash on Delivery',
    },
    // Add more orders as needed
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1), // Adjust height as needed
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
            padding: const EdgeInsets.only(top: 15.0, bottom: 0.0), // Add space above and below
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
                  onPressed: () {
                    // Add filter functionality
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Orders',
              style: TextStyle(
                fontSize: screenWidth * 0.048,
                fontFamily: 'sora',
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              'Session 2',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontFamily: 'sora',
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return buildOrderCard(
                    context,
                    order['name'],
                    order['mobile'],
                    order['slotDate'],
                    order['address'],
                    order['email'],
                    order['paymentMode'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderCard(
      BuildContext context,
      String name,
      String mobile,
      String slotDate,
      String address,
      String email,
      String paymentMode,
      ) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      color: Color(0xFF4A9589).withOpacity(0.09),
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.only(top:16.0,left:16,right:16,bottom:5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Name',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.037,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Mobile No',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        mobile,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Slot & Date',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      Text(
                        slotDate,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 15), // Add spacing between columns
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end, // Align to the right
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF2A3C66),size:20),
                          SizedBox(width: 1),
                          Text(
                            'Address',
                            style: TextStyle(
                              color: Color(0xFF2A3C66),
                              fontFamily: 'sora',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.032,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                      Text(
                        address,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      // SizedBox(height: 10),
                      Text(
                        email,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Payment Mode',
                        style: TextStyle(
                          color: Color(0xFF2A3C66),
                          fontFamily: 'sora',
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.032,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        paymentMode,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'sora',
                          // fontWeight: FontWeight.w/00,
                          fontSize: screenWidth * 0.028,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Accept Button
                SizedBox(
                  width: 150, // Fixed width for the Accept button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompletedOrdersTech(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 2), // Reduced internal padding
                      minimumSize: Size(40, 30), // Minimum size for height
                    ),
                    child: Text(
                      'Move to Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0AA048),
                        fontFamily: 'sora',
                      ),
                    ),
                  ),
                ),
                Spacer(),
                SizedBox(
                  width: 100, // Adjust width as needed
                  child: ElevatedButton(
                    onPressed: () {
                      // View Details action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Transparent background
                      elevation: 0, // Remove shadow/elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                      padding: EdgeInsets.symmetric(vertical: 4), // Reduced padding
                      minimumSize: Size(10, 30), // Minimum size for height
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center align icon and text
                      children: [
                        Icon(
                          Icons.remove_red_eye, // Eye icon
                          color: Color(0xFF2A3C66), // Icon color
                          size: 18, // Icon size
                        ),
                        SizedBox(width: 4), // Spacing between icon and text
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12, // Text size
                            color: Color(0xFF2A3C66), // Text color
                            fontFamily: 'sora',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
