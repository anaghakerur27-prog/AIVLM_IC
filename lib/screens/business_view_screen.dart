import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessViewScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final String memberId;

  const BusinessViewScreen({
    super.key,
    required this.businessData,
    required this.memberId,
  });

  @override
  State<BusinessViewScreen> createState() => _BusinessViewScreenState();
}

class _BusinessViewScreenState extends State<BusinessViewScreen> {
  bool isLoading = false;

  Future<void> saveInterest() async {
    setState(() {
      isLoading = true;
    });

    try {
      String businessId = widget.businessData['memberId'];

      /// Prevent duplicate interests
      final existing = await FirebaseFirestore.instance
          .collection('interests')
          .where('senderId', isEqualTo: widget.memberId)
          .where('businessId', isEqualTo: businessId)
          .get();

      if (!mounted) return;

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Already marked as Interested")),
        );

        return;
      }

      String interestId = FirebaseFirestore.instance
          .collection('interests')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('interests')
          .doc(interestId)
          .set({
            'senderId': widget.memberId,
            'receiverId': businessId,
            'businessId': businessId,
            'status': 'Interested',
            'createdAt': FieldValue.serverTimestamp(),
          });

      /// Notification

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Interest Sent Successfully")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> makeCall(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');

    final bool canLaunch = await canLaunchUrl(uri);

    if (!mounted) return;

    if (canLaunch) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open dialer")));
    }
  }

  Future<void> sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');

    final bool canLaunch = await canLaunchUrl(uri);

    if (!mounted) return;

    if (canLaunch) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open email app")));
    }
  }

  Future<void> openWebsite(String website) async {
    String url = website;

    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    final Uri uri = Uri.parse(url);

    final bool canLaunch = await canLaunchUrl(uri);

    if (!mounted) return;

    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open website")));
    }
  }

  Future<void> openPdf(String pdfUrl) async {
    final Uri uri = Uri.parse(pdfUrl);

    final bool canLaunch = await canLaunchUrl(uri);

    if (!mounted) return;

    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    String phone = widget.businessData['contactNumber'] ?? '';

    String email = widget.businessData['email'] ?? '';

    String website = widget.businessData['website'] ?? '';

    String pdfUrl = widget.businessData['companyProfileUrl'] ?? '';

    String imageUrl = widget.businessData['visitingCardUrl'] ?? '';

    String industry = widget.businessData['industryType'] ?? '';

    if (industry == 'Other') {
      industry = widget.businessData['customIndustry'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Business Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        widget.businessData['businessName'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    infoTile(
                      Icons.person,
                      "Owner Name",
                      widget.businessData['ownerName'],
                    ),

                    infoTile(Icons.phone, "Contact Number", phone),

                    infoTile(Icons.email, "Email", email),

                    infoTile(Icons.language, "Website", website),

                    infoTile(
                      Icons.home,
                      "Address",
                      widget.businessData['address'],
                    ),

                    infoTile(
                      Icons.location_city,
                      "District",
                      widget.businessData['district'],
                    ),

                    infoTile(
                      Icons.location_on,
                      "Pincode",
                      widget.businessData['pincode'],
                    ),

                    infoTile(Icons.business, "Industry", industry),

                    const SizedBox(height: 20),

                    const Text(
                      "Product & Services",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(widget.businessData['description'] ?? ''),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pdfUrl.isEmpty ? null : () => openPdf(pdfUrl),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Open Company Profile"),
              ),
            ),

            const SizedBox(height: 20),

            imageUrl.isEmpty
                ? const Text("No Visiting Card Uploaded")
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),

            const SizedBox(height: 30),

            const Text(
              "Direct Contact",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: phone.isEmpty ? null : () => makeCall(phone),
                  icon: const Icon(Icons.phone),
                  label: const Text("Call"),
                ),

                ElevatedButton.icon(
                  onPressed: email.isEmpty ? null : () => sendEmail(email),
                  icon: const Icon(Icons.email),
                  label: const Text("Email"),
                ),

                ElevatedButton.icon(
                  onPressed: website.isEmpty
                      ? null
                      : () => openWebsite(website),
                  icon: const Icon(Icons.language),
                  label: const Text("Website"),
                ),
              ],
            ),

            const SizedBox(height: 35),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: isLoading ? null : saveInterest,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text("Interested"),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Not Interested"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoTile(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 15),
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
