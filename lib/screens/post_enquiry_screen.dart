import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostEnquiryScreen extends StatefulWidget {
  final String memberId;

  const PostEnquiryScreen({super.key, required this.memberId});

  @override
  State<PostEnquiryScreen> createState() => _PostEnquiryScreenState();
}

class _PostEnquiryScreenState extends State<PostEnquiryScreen> {
  final enquiryController = TextEditingController();

  final otherIndustryController = TextEditingController();

  String? selectedIndustry;

  bool isLoading = false;

  final List<String> industries = [
    'Manufacturing',
    'Automobile & Auto Components',
    'Engineering & Fabrication',
    'Foundries & Castings',
    'Textile & Garments',
    'Food Processing & Beverages',
    'Pharmaceuticals',
    'Chemicals & Paints',
    'Plastics & Polymers',
    'Rubber Products',
    'Electrical & Electronics',
    'IT Hardware & Electronics Manufacturing',
    'Aerospace & Defence',
    'Machine Tools',
    'Packaging Industry',
    'Printing & Packaging',
    'Paper & Paper Products',
    'Steel & Metal Processing',
    'Aluminium & Copper Industries',
    'Cement & Building Materials',
    'Ceramic & Tiles',
    'Glass Manufacturing',
    'Warehouses & Logistics Parks',
    'Cold Storage Facilities',
    'Hotels & Resorts',
    'Hospitals & Healthcare',
    'Educational Institutions',
    'Shopping Malls & Retail Chains',
    'Apartment Complexes & Gated Communities',
    'Commercial Office Buildings',
    'Data Centres',
    'Agriculture Processing Units',
    'Dairy & Poultry Farms',
    'Rice, Flour & Oil Mills',
    'Breweries & Distilleries',
    'Renewable Energy Equipment Manufacturers',
    'MSMEs & Industrial Estates',
    'Other',
  ];

  Future<void> submitEnquiry() async {
    if (selectedIndustry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Industry")));
      return;
    }

    if (selectedIndustry == 'Other' &&
        otherIndustryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter Industry")));
      return;
    }

    if (enquiryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter enquiry description")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String enquiryId = FirebaseFirestore.instance
          .collection('enquiries')
          .doc()
          .id;

      String customIndustry = selectedIndustry == 'Other'
          ? otherIndustryController.text.trim()
          : '';

      await FirebaseFirestore.instance
          .collection('enquiries')
          .doc(enquiryId)
          .set({
            'enquiryId': enquiryId,
            'memberId': widget.memberId,
            'industryType': selectedIndustry,
            'customIndustry': customIndustry,
            'enquiryDescription': enquiryController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      //--------------------------------------------------
      // Find matching businesses
      //--------------------------------------------------

      QuerySnapshot<Map<String, dynamic>> businessSnapshot;

      if (selectedIndustry == 'Other') {
        businessSnapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .where('customIndustry', isEqualTo: customIndustry)
            .get();
      } else {
        businessSnapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .where('industryType', isEqualTo: selectedIndustry)
            .get();
      }

      //--------------------------------------------------
      // Create notification for every matching business
      //--------------------------------------------------

      for (var business in businessSnapshot.docs) {
        final businessData = business.data();

        String notificationId = FirebaseFirestore.instance
            .collection('notifications')
            .doc()
            .id;

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .set({
              'notificationId': notificationId,

              'senderId': widget.memberId,

              'receiverId': businessData['memberId'],

              'title': 'New Enquiry',

              'message': 'A new enquiry matches your business category.',

              'type': 'enquiry',

              'isRead': false,

              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enquiry Posted Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    enquiryController.dispose();
    otherIndustryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Enquiry")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedIndustry,
              decoration: const InputDecoration(
                labelText: "Industry",
                border: OutlineInputBorder(),
              ),
              items: industries
                  .map(
                    (industry) => DropdownMenuItem(
                      value: industry,
                      child: Text(industry),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedIndustry = value;
                });
              },
            ),

            const SizedBox(height: 20),

            if (selectedIndustry == 'Other')
              Column(
                children: [
                  TextField(
                    controller: otherIndustryController,
                    decoration: const InputDecoration(
                      labelText: "Enter Industry Type",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            TextField(
              controller: enquiryController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Enquiry Description",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitEnquiry,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
