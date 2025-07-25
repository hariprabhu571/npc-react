import 'package:flutter/material.dart';

class SlotBookingPage extends StatefulWidget {
  @override
  _SlotBookingPageState createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  int selectedDate = 17; // Default selected date
  String selectedSlot = "9:00am"; // Default selected slot

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Summary",
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Section
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Icon(Icons.home, color: Colors.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Home - Dno:34,3rd cross, shanthi nagar...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Professional Arrival Text
            Text(
              "When should the professional arrive?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Your service will take approx. 1hr",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 20),

            // Date Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDateBox("Sun", 17),
                _buildDateBox("Mon", 18),
                _buildDateBox("Tue", 19),
                _buildDateBox("Wed", 20),
              ],
            ),
            SizedBox(height: 30),

            // Slot Selection Title
            Text(
              "Select slot for service",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15),

            // Time Slot Grid
            Expanded(
              child: GridView.builder(
                itemCount: 9,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, index) {
                  List<String> timeSlots = [
                    "9:00am",
                    "10:00am",
                    "11:00am",
                    "12:00pm",
                    "01:00pm",
                    "02:00pm",
                    "03:00pm",
                    "04:00pm",
                    "05:00pm"
                  ];
                  return _buildTimeSlot(timeSlots[index]);
                },
              ),
            ),

            // Proceed Button
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Slot Selected\nDate: $selectedDate | Slot: $selectedSlot"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A9589),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Proceed",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Date Box Widget
  Widget _buildDateBox(String day, int date) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
        });
      },
      child: Container(
        width: 78,
        height: 74,
        decoration: BoxDecoration(
          color: selectedDate == date ? Color(0xFF4A9589) : Color(0xFFECECEC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: selectedDate == date ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "$date",
              style: TextStyle(
                color: selectedDate == date ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time Slot Widget
  Widget _buildTimeSlot(String time) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSlot = time;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
          selectedSlot == time ? Color(0xFF4A9589) : Color(0xFFECECEC),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: TextStyle(
            color: selectedSlot == time ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
