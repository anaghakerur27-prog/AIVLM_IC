
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

  const BusinessDetailsScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState
    extends State<BusinessDetailsScreen> {
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
  bool isCheckingAccess = true;
  bool isBusinessMember = false;

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

  @override
  void initState() {
    super.initState();
    verifyBusinessAccess();
  }

  // --------------------------------------------------
  // BUSINESS MEMBER ACCESS VERIFICATION
  // --------------------------------------------------

  Future<bool> hasBusinessAccess() async {
    final memberDoc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .get();

    if (!memberDoc.exists) {
      return false;
    }

    final data = memberDoc.data();

    if (data == null) {
      return false;
    }

    final userType = (data['userType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final isActive = data['active'] == true;

    return userType == 'business' && isActive;
  }

  Future<void> verifyBusinessAccess() async {
    try {
      final allowed = await hasBusinessAccess();

      if (!mounted) return;

      setState(() {
        isBusinessMember = allowed;
        isCheckingAccess = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isBusinessMember = false;
        isCheckingAccess = false;
      });
    }
  }

  // --------------------------------------------------
  // PDF UPLOAD
  // --------------------------------------------------

  Future<void> pickPdf() async {
    if (!isBusinessMember || isLoading) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.bytes != null) {
        if (!mounted) return;

        setState(() {
          pdfBytes = result.files.single.bytes;
          pdfName = result.files.single.name;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select PDF: $e'),
        ),
      );
    }
  }

  // --------------------------------------------------
  // VISITING CARD IMAGE UPLOAD
  // --------------------------------------------------

  Future<void> pickVisitingCard() async {
    if (!isBusinessMember || isLoading) return;

    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final Uint8List originalBytes = await image.readAsBytes();

      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 70,
      );

      if (!mounted) return;

      setState(() {
        imageBytes = compressedBytes;
        imageName = image.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image compressed successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select image: $e'),
        ),
      );
    }
  }

  // --------------------------------------------------
  // SAVE BUSINESS DETAILS
  // --------------------------------------------------

  Future<void> saveBusiness() async {
    if (isLoading) return;

    if (businessNameController.text.trim().isEmpty ||
        ownerNameController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        selectedIndustry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill required fields'),
        ),
      );
      return;
    }

    // Verify member role again before uploading or saving.
    bool allowed;

    try {
      allowed = await hasBusinessAccess();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to verify your account. Please try again.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    if (!allowed) {
      setState(() {
        isBusinessMember = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access denied. Only active Business members can save Business Details.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final memberId = widget.memberId;

      String? companyProfileUrl;
      String? visitingCardUrl;

      // Upload company profile PDF.
      if (pdfBytes != null) {
        final pdfRef = FirebaseStorage.instance
            .ref()
            .child('company_profiles/$memberId/profile.pdf');

        await pdfRef.putData(
          pdfBytes!,
          SettableMetadata(
            contentType: 'application/pdf',
          ),
        );

        companyProfileUrl = await pdfRef.getDownloadURL();
      }

      // Upload visiting card image.
      if (imageBytes != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('visiting_cards/$memberId/visiting_card.jpg');

        await imageRef.putData(
          imageBytes!,
          SettableMetadata(
            contentType: 'image/jpeg',
          ),
        );

        visitingCardUrl = await imageRef.getDownloadURL();
      }

      // Business document reference.
      final businessRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(memberId);

      // Read existing data to preserve previous URLs and createdAt.
      final existingBusiness = await businessRef.get();
      final existingData = existingBusiness.data();

      await businessRef.set(
        {
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

          // Preserve existing URLs if no new file is selected.
          'companyProfileUrl': companyProfileUrl ??
              existingData?['companyProfileUrl'] ??
              '',
          'visitingCardUrl': visitingCardUrl ??
              existingData?['visitingCardUrl'] ??
              '',

          // Preserve original creation date.
          'createdAt': existingData?['createdAt'] ??
              FieldValue.serverTimestamp(),

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business Details Saved Successfully'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            memberId: memberId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to save Business Details: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // DISPOSE CONTROLLERS
  // --------------------------------------------------

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

  // --------------------------------------------------
  // SECTION HEADER
  // --------------------------------------------------

  Widget sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
        top: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.indigo,
          ),
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

  // --------------------------------------------------
  // TEXT FIELD
  // --------------------------------------------------

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
          prefixIcon: icon != null
              ? Icon(icon, size: 20)
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.indigo,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION CARD
  // --------------------------------------------------

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

  // --------------------------------------------------
  // UPLOAD TILE
  // --------------------------------------------------

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
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ACCESS DENIED SCREEN
  // --------------------------------------------------

  Widget accessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 55,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Business Details is available only to active Business members.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BUSINESS DETAILS FORM
  // --------------------------------------------------

  Widget businessForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BASIC INFORMATION
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader(
                  'Basic Information',
                  Icons.business,
                ),
                textField(
                  businessNameController,
                  'Business Name',
                  icon: Icons.storefront,
                ),
                textField(
                  ownerNameController,
                  'Owner Name',
                  icon: Icons.person,
                ),
                textField(
                  contactController,
                  'Contact Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                textField(
                  emailController,
                  'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                textField(
                  websiteController,
                  'Website',
                  icon: Icons.language,
                ),
              ],
            ),
          ),

          // LOCATION DETAILS
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader(
                  'Location Details',
                  Icons.location_on,
                ),
                textField(
                  addressController,
                  'Address',
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
                      prefixIcon: const Icon(
                        Icons.map,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
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
                          (district) => DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          ),
                        )
                        .toList(),
                  ),
                ),
                textField(
                  pincodeController,
                  'Pincode',
                  icon: Icons.location_on,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),

          // INDUSTRY TYPE
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader(
                  'Industry Type',
                  Icons.factory,
                ),
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
                    prefixIcon: const Icon(
                      Icons.category,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
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
                      .map(
                        (industry) => DropdownMenuItem(
                          value: industry,
                          child: Text(industry),
                        ),
                      )
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
                  'Product & Service Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          // DOCUMENTS
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader(
                  'Documents',
                  Icons.folder_open,
                ),
                uploadTile(
                  icon: Icons.picture_as_pdf,
                  label: pdfName ?? 'Upload Company Profile PDF',
                  color: Colors.redAccent,
                  onTap: pickPdf,
                ),
                const SizedBox(height: 12),
                uploadTile(
                  icon: Icons.photo,
                  label: imageName ?? 'Upload Visiting Card',
                  color: Colors.blue,
                  onTap: pickVisitingCard,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // SAVE BUTTON
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
                      'SAVE & CONTINUE',
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
    );
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Business Details'),
        centerTitle: true,
      ),
      body: isCheckingAccess
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !isBusinessMember
              ? accessDeniedView()
              : businessForm(),
    );
  }
}
