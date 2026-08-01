import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'home_page.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final String memberId;

  const BusinessDetailsScreen({super.key, required this.memberId});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final businessNameController = TextEditingController();

  final ownerNameController = TextEditingController();

  final contactController = TextEditingController();

  final emailController = TextEditingController();

  final websiteController = TextEditingController();

  final addressController = TextEditingController();

  final districtController = TextEditingController();

  final pincodeController = TextEditingController();

  final descriptionController = TextEditingController();

  final otherIndustryController = TextEditingController();

  String? selectedIndustry;
  String? selectedDistrict;

  Uint8List? pdfBytes;
  Uint8List? imageBytes;

  String? pdfName;
  String? imageName;

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

  final List<String> districts = [
    'Bagalkote',
    'Ballari',
    'Belagavi',
    'Bengaluru Rural',
    'Bengaluru Urban',
    'Bidar',
    'Chamarajanagar',
    'Chikkaballapur',
    'Chikkamagaluru',
    'Chitradurga',
    'Dakshina Kannada',
    'Davanagere',
    'Dharwad',
    'Gadag',
    'Hassan',
    'Haveri',
    'Kalaburagi',
    'Kodagu',
    'Kolar',
    'Koppal',
    'Mandya',
    'Mysuru',
    'Raichur',
    'Ramanagara',
    'Shivamogga',
    'Tumakuru',
    'Udupi',
    'Uttara Kannada',
    'Vijayapura',
    'Vijayanagara',
    'Yadgir',
  ];

  Future<void> pickPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        pdfBytes = result.files.single.bytes;

        pdfName = result.files.single.name;
      });
    }
  }

  /// Picks a visiting card image from the gallery and compresses it
  /// before storing it in [imageBytes], so uploads are smaller and faster.
  Future<void> pickVisitingCard() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final Uint8List originalBytes = await image.readAsBytes();

    final Uint8List compressedBytes =
        await FlutterImageCompress.compressWithList(originalBytes, quality: 70);

    setState(() {
      imageBytes = compressedBytes;
      imageName = image.name;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image compressed successfully")),
      );
    }
  }

  Future<void> saveBusiness() async {
    if (businessNameController.text.trim().isEmpty ||
        ownerNameController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        selectedIndustry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? companyProfileUrl;
      String? visitingCardUrl;

      final memberId = widget.memberId;

      if (pdfBytes != null) {
        final pdfRef = FirebaseStorage.instance.ref().child(
          'company_profiles/$memberId/profile.pdf',
        );

        await pdfRef.putData(pdfBytes!);

        companyProfileUrl = await pdfRef.getDownloadURL();
      }

      /// imageBytes now contains the compressed image, so this upload
      /// is unchanged but automatically smaller and faster.
      if (imageBytes != null) {
        final imageRef = FirebaseStorage.instance.ref().child(
          'visiting_cards/$memberId/visiting_card.jpg',
        );

        await imageRef.putData(imageBytes!);

        visitingCardUrl = await imageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(memberId)
          .set({
            'memberId': memberId,
            'businessName': businessNameController.text.trim(),
            'ownerName': ownerNameController.text.trim(),
            'contactNumber': contactController.text.trim(),
            'email': emailController.text.trim(),
            'website': websiteController.text.trim(),
            'address': addressController.text.trim(),
            'district': districtController.text.trim(),
            'pincode': pincodeController.text.trim(),
            'industryType': selectedIndustry,
            'customIndustry': otherIndustryController.text.trim(),
            'description': descriptionController.text.trim(),
            'companyProfileUrl': companyProfileUrl ?? '',
            'visitingCardUrl': visitingCardUrl ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Business Details Saved')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(memberId: memberId)),
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

  @override
  void dispose() {
    businessNameController.dispose();
    ownerNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    websiteController.dispose();
    addressController.dispose();
    districtController.dispose();
    pincodeController.dispose();
    descriptionController.dispose();
    otherIndustryController.dispose();
    super.dispose();
  }

  Widget sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget textField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: !isLoading,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget uploadTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Business Details"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---- Basic Info ----
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader("Basic Information", Icons.business),
                  textField(
                    businessNameController,
                    "Business Name",
                    icon: Icons.storefront,
                  ),
                  textField(
                    ownerNameController,
                    "Owner Name",
                    icon: Icons.person,
                  ),
                  textField(
                    contactController,
                    "Contact Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  textField(
                    emailController,
                    "Email Address",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  textField(websiteController, "Website", icon: Icons.language),
                ],
              ),
            ),

            /// ---- Location ----
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader("Location Details", Icons.location_on),
                  textField(
                    addressController,
                    "Address",
                    icon: Icons.home,
                    maxLines: 2,
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedDistrict,
                      isExpanded: true,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                selectedDistrict = value;
                                districtController.text = value ?? '';
                              });
                            },
                      decoration: InputDecoration(
                        labelText: 'District',
                        prefixIcon: const Icon(Icons.map, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.indigo,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: districts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                    ),
                  ),

                  textField(
                    pincodeController,
                    "Pincode",
                    icon: Icons.location_on,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            /// ---- Industry ----
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader("Industry Type", Icons.factory),

                  DropdownButtonFormField<String>(
                    initialValue: selectedIndustry,
                    isExpanded: true,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              selectedIndustry = value;
                            });
                          },
                    decoration: InputDecoration(
                      labelText: 'Industry Type',
                      prefixIcon: const Icon(Icons.category, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: industries
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),

                  if (selectedIndustry == 'Other') ...[
                    const SizedBox(height: 15),
                    textField(
                      otherIndustryController,
                      'Enter Your Industry Type',
                      icon: Icons.edit,
                    ),
                  ],

                  const SizedBox(height: 5),

                  textField(
                    descriptionController,
                    "Product & Service Description",
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            /// ---- Documents ----
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader("Documents", Icons.folder_open),

                  uploadTile(
                    icon: Icons.picture_as_pdf,
                    label: pdfName ?? "Upload Company Profile PDF",
                    color: Colors.redAccent,
                    onTap: pickPdf,
                  ),

                  const SizedBox(height: 12),

                  uploadTile(
                    icon: Icons.photo,
                    label: imageName ?? "Upload Visiting Card",
                    color: Colors.blue,
                    onTap: pickVisitingCard,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : saveBusiness,
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "SAVE & CONTINUE",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
