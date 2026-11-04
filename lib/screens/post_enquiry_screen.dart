import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostEnquiryScreen extends StatefulWidget {
  final String memberId;

  const PostEnquiryScreen({super.key, required this.memberId});

  @override
  State<PostEnquiryScreen> createState() => _PostEnquiryScreenState();
}

class _PostEnquiryScreenState extends State<PostEnquiryScreen> {
  final titleController = TextEditingController();
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

  String _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _normaliseMemberType(dynamic value) {
    final type = (value ?? '').toString().toLowerCase().trim();

    if (type == 'business') return 'Business';
    if (type == 'student') return 'Student';
    if (type == 'non_business' ||
        type == 'non-business' ||
        type == 'nonbusiness') {
      return 'Non-Business';
    }

    return type.isEmpty ? 'Unknown' : type;
  }

  Future<void> submitEnquiry() async {
    if (selectedIndustry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Industry')),
      );
      return;
    }

    if (selectedIndustry == 'Other' &&
        otherIndustryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Industry')),
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter enquiry title')),
      );
      return;
    }

    if (enquiryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter enquiry description')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Get the member profile using the existing member document ID.
      final memberSnapshot = await firestore
          .collection('members')
          .doc(widget.memberId)
          .get();

      if (!memberSnapshot.exists) {
        throw Exception(
          'Member profile was not found. Please log in again.',
        );
      }

      final memberData = memberSnapshot.data() ?? {};

      if (memberData['active'] != true) {
        throw Exception('This member account is not active.');
      }

      final memberName = _firstValue(
        memberData,
        ['name', 'memberName', 'fullName'],
      );

      final memberNumber = _firstValue(
        memberData,
        ['membershipNumber', 'memberId'],
      );

      final memberPhone = _firstValue(
        memberData,
        ['phone', 'phoneNumber', 'mobile', 'mobileNumber', 'contactNumber'],
      );

      final memberEmail = _firstValue(
        memberData,
        ['email', 'emailId', 'mailId'],
      );

      final memberAddress = _firstValue(
        memberData,
        ['address', 'residentialAddress', 'businessAddress'],
      );

      final memberType = _normaliseMemberType(
        memberData['userType'] ?? memberData['memberType'],
      );

      final customIndustry = selectedIndustry == 'Other'
          ? otherIndustryController.text.trim()
          : '';

      final enquiryRef = firestore.collection('enquiries').doc();

      await enquiryRef.set({
        'enquiryId': enquiryRef.id,
        'memberId': widget.memberId,

        // Enquiry information
        'enquiryTitle': titleController.text.trim(),
        'enquiryDescription': enquiryController.text.trim(),
        'industryType': selectedIndustry,
        'customIndustry': customIndustry,

        // Poster information saved as a snapshot
        'postedByName': memberName,
        'postedByMemberNumber': memberNumber,
        'postedByPhone': memberPhone,
        'postedByEmail': memberEmail,
        'postedByAddress': memberAddress,
        'memberType': memberType,

        'createdAt': FieldValue.serverTimestamp(),
      });

      // Find businesses matching the selected industry.
      QuerySnapshot<Map<String, dynamic>> businessSnapshot;

      if (selectedIndustry == 'Other') {
        businessSnapshot = await firestore
            .collection('businesses')
            .where('customIndustry', isEqualTo: customIndustry)
            .get();
      } else {
        businessSnapshot = await firestore
            .collection('businesses')
            .where('industryType', isEqualTo: selectedIndustry)
            .get();
      }

      // Notify matching businesses.
      for (final business in businessSnapshot.docs) {
        final businessData = business.data();
        final receiverId = businessData['memberId']?.toString();

        if (receiverId == null || receiverId.isEmpty) {
          continue;
        }

        final notificationRef = firestore
            .collection('notifications')
            .doc();

        await notificationRef.set({
          'notificationId': notificationRef.id,
          'senderId': widget.memberId,
          'receiverId': receiverId,
          'title': 'New Enquiry',
          'message': 'A new enquiry matches your business category.',
          'type': 'enquiry',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry Posted Successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    enquiryController.dispose();
    otherIndustryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Enquiry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedIndustry,
              decoration: const InputDecoration(
                labelText: 'Industry',
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
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() => selectedIndustry = value);
                    },
            ),
            const SizedBox(height: 20),

            if (selectedIndustry == 'Other') ...[
              TextField(
                controller: otherIndustryController,
                decoration: const InputDecoration(
                  labelText: 'Enter Industry Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Enquiry Title',
                hintText: 'Enter a short title for your enquiry',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: enquiryController,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Enquiry Description',
                hintText: 'Describe your requirement',
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
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}