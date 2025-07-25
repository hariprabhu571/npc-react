import 'package:flutter/material.dart';

class ViewSpaceDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Image
            Image.asset(
              'assets/images/appartment.png', // Replace with your image asset path
              height: 200,
              fit: BoxFit.cover,
            ),

            // "Why Choose Us" Section
            Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              color: Colors.green[50],
              child: Column(
                children: [
                  Text(
                    "WHY CHOOSE US",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Protecting your space, Defending your peace. The Best Pest Control, Guaranteed to Please",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // "Our Service Includes" Section
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Our Service Includes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Detailed Inspection"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Chemical application on all holes"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("White cement application"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Chemical application on all wooden surfaces"),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Excludes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Removal and restocking of objects"),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Please provide a stool/ladder if required"),
                    ],
                  ),
                ],
              ),
            ),

            // Frequently Asked Questions Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Frequently Asked Questions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ExpansionTile(
                    title: Text("How frequently should I inspect my home for termites?"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("It is recommended to inspect your home annually."),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text("What are the signs of termite infestation?"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            "Some signs include hollow-sounding wood, mud tubes, and discarded wings."),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text("Will the professional follow all safety measures?"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Yes, all professionals are trained to follow strict safety measures."),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rating Section
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "4.82",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow),
                      SizedBox(width: 8),
                      Text("14K Reviews"),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      buildRatingRow(5, 14000),
                      buildRatingRow(4, 412),
                      buildRatingRow(3, 186),
                      buildRatingRow(2, 110),
                      buildRatingRow(1, 256),
                    ],
                  ),
                ],
              ),
            ),

            // All Reviews Section
            ReviewsSection(),
          ],
        ),
      ),
    );
  }

  Widget buildRatingRow(int star, int count) {
    return Row(
      children: [
        Text("$star"),
        Icon(Icons.star, color: Colors.yellow, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: count / 14000,
            backgroundColor: Colors.grey[300],
            color: Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Text("$count"),
      ],
    );
  }
}

class ReviewsSection extends StatefulWidget {
  @override
  _ReviewsSectionState createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final List<Map<String, String>> reviews = [
    {"name": "Deepika Patel", "date": "October 9, 2024", "rating": "3.9", "comment": "The service was very good, highly recommended."},
    {"name": "Rahul Sharma", "date": "October 8, 2024", "rating": "4.5", "comment": "Great service and professional staff."},
    {"name": "Anjali Mehta", "date": "October 7, 2024", "rating": "5.0", "comment": "Highly satisfied with the pest control."},
  ];

  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "All Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...reviews
              .take(showAll ? reviews.length : 1)
              .map((review) => buildReviewCard(review))
              .toList(),
          TextButton(
            onPressed: () {
              setState(() {
                showAll = !showAll;
              });
            },
            child: Text(showAll ? "Show Less" : "Show More"),
          ),
        ],
      ),
    );
  }

  Widget buildReviewCard(Map<String, String> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white, // Set background color to white
      child: ListTile(
        title: Text(review["name"]!),
        subtitle: Text(
          "${review["date"]}\n${review["comment"]}",
          style: TextStyle(color: Colors.black), // Optional for better readability
        ),
        trailing: Text(
          review["rating"]!,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // Optional for better styling
        ),
      ),
    );
  }

}