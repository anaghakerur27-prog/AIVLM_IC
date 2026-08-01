import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'business_view_screen.dart';

class BusinessListScreen extends StatelessWidget {
  final String memberId;
  final List<QueryDocumentSnapshot> businesses;

  const BusinessListScreen({
    super.key,
    required this.memberId,
    required this.businesses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Business Listing"), centerTitle: true),

      body: businesses.isEmpty
          ? const Center(
              child: Text(
                "No Businesses Found",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final data = businesses[index].data() as Map<String, dynamic>;

                String industry = data['industryType'] ?? '';

                if (industry == 'Other') {
                  industry = data['customIndustry'] ?? '';
                }

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['businessName'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        infoRow(Icons.person, "Owner", data['ownerName']),

                        infoRow(Icons.business, "Industry", industry),

                        infoRow(
                          Icons.location_on,
                          "District",
                          data['district'],
                        ),

                        infoRow(Icons.phone, "Contact", data['contactNumber']),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BusinessViewScreen(
                                    businessData: data,
                                    memberId: memberId,
                                  ),
                                ),
                              );
                            },
                            child: const Text("VIEW DETAILS"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget infoRow(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              "$title : ${value ?? ''}",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
