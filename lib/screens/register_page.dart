import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'terms_and_conditions_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phone;
  final String memberType; // "business" | "non_business" | "student"

  const RegisterScreen({
    super.key,
    required this.phone,
    required this.memberType,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Shared across all categories
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Business only — mirrors the fields in the Business ProfileScreen
  final TextEditingController memberIdController = TextEditingController();
  final TextEditingController businessNameController =
      TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController contactNumberController =
      TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController industryTypeController =
      TextEditingController();
  final TextEditingController productServiceController =
      TextEditingController();

  bool isRegistering = false;

  // Terms & Conditions
  bool agreedToTerms = false;

  bool get isBusiness => widget.memberType == "business";

  String get categoryLabel {
    switch (widget.memberType) {
      case "business":
        return "Business";
      case "non_business":
        return "Non-Business";
      case "student":
        return "Student";
      default:
        return "Member";
    }
  }

  @override
  void initState() {
    super.initState();
    // The phone number was already verified via OTP on the login screen,
    // so it's just displayed here — never edited or re-verified.
    phoneController.text = widget.phone;
  }

  /// Save the member to Firestore. No OTP step here — the phone number
  /// was already verified via OTP on the login screen.
  ///   Business: Name + Phone + Member ID + full business details.
  ///   Non-Business / Student: Name + Phone + Address + Email.
  /// Both always save userType and agreedToTerms.
  Future<void> registerMember() async {
    if (!agreedToTerms) {
      _showMessage("Please agree to the Terms & Conditions to continue");
      return;
    }

    String name = nameController.text.trim();
    String phone = phoneController.text.trim();

    if (isBusiness) {
      String memberId = memberIdController.text.trim();
      String businessName = businessNameController.text.trim();
      String ownerName = ownerNameController.text.trim();
      String contactNumber = contactNumberController.text.trim();
      String email = emailController.text.trim();
      String website = websiteController.text.trim();
      String address = addressController.text.trim();
      String district = districtController.text.trim();
      String pincode = pincodeController.text.trim();
      String industryType = industryTypeController.text.trim();
      String productServiceDescription = productServiceController.text
          .trim();

      if (name.isEmpty ||
          memberId.isEmpty ||
          phone.isEmpty ||
          businessName.isEmpty ||
          ownerName.isEmpty ||
          contactNumber.isEmpty ||
          email.isEmpty ||
          address.isEmpty ||
          district.isEmpty ||
          pincode.isEmpty ||
          industryType.isEmpty) {
        _showMessage('Please fill all required fields');
        return;
      }

      setState(() => isRegistering = true);

      try {
        await FirebaseFirestore.instance
            .collection('members')
            .doc(phone)
            .set({
          'name': name,
          'phone': phone,
          'memberId': memberId,
          'businessName': businessName,
          'ownerName': ownerName,
          'contactNumber': contactNumber,
          'email': email,
          'website': website,
          'address': address,
          'district': district,
          'pincode': pincode,
          'industryType': industryType,
          'productServiceDescription': productServiceDescription,
          'userType': widget.memberType,
          'agreedToTerms': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(memberId: phone)),
        );
      } catch (e) {
        _showMessage('Error : $e');
      } finally {
        if (mounted) {
          setState(() => isRegistering = false);
        }
      }
    } else {
      String email = emailController.text.trim();
      String address = addressController.text.trim();

      if (name.isEmpty || phone.isEmpty || email.isEmpty || address.isEmpty) {
        _showMessage('Please fill all fields');
        return;
      }

      setState(() => isRegistering = true);

      try {
        await FirebaseFirestore.instance
            .collection('members')
            .doc(phone)
            .set({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'userType': widget.memberType,
          'agreedToTerms': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(memberId: phone)),
        );
      } catch (e) {
        _showMessage('Error : $e');
      } finally {
        if (mounted) {
          setState(() => isRegistering = false);
        }
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    memberIdController.dispose();
    businessNameController.dispose();
    ownerNameController.dispose();
    contactNumberController.dispose();
    websiteController.dispose();
    districtController.dispose();
    pincodeController.dispose();
    industryTypeController.dispose();
    productServiceController.dispose();
    super.dispose();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool fieldsLocked = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: !fieldsLocked,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  /// Business registration fields: everything the Business ProfileScreen
  /// shows, minus document uploads (Company Profile PDF / Visiting Card)
  /// — those can be added afterwards from the Profile tab, which already
  /// supports uploading them.
  Widget businessFields(bool fieldsLocked) {
    return Column(
      children: [
        _field(
          controller: memberIdController,
          label: "Member ID",
          icon: Icons.badge,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: businessNameController,
          label: "Business Name",
          icon: Icons.storefront,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: ownerNameController,
          label: "Owner Name",
          icon: Icons.person_outline,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: contactNumberController,
          label: "Contact Number",
          icon: Icons.call,
          keyboardType: TextInputType.phone,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: emailController,
          label: "Email",
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: websiteController,
          label: "Website (optional)",
          icon: Icons.language,
          keyboardType: TextInputType.url,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: addressController,
          label: "Address",
          icon: Icons.location_on,
          maxLines: 2,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: districtController,
          label: "District",
          icon: Icons.map,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: pincodeController,
          label: "Pincode",
          icon: Icons.pin_drop,
          keyboardType: TextInputType.number,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: industryTypeController,
          label: "Industry Type",
          icon: Icons.factory,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: productServiceController,
          label: "Product & Service Description (optional)",
          icon: Icons.inventory_2,
          maxLines: 3,
          fieldsLocked: fieldsLocked,
        ),
      ],
    );
  }

  /// Non-Business / Student registration fields:
  /// Name + Phone + Address + Email only.
  /// (Name and Phone are rendered by the shared section above this;
  /// this widget adds Address and Email.)
  Widget personalFields(bool fieldsLocked) {
    return Column(
      children: [
        _field(
          controller: emailController,
          label: "Email",
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          fieldsLocked: fieldsLocked,
        ),
        _field(
          controller: addressController,
          label: "Address",
          icon: Icons.location_on,
          maxLines: 3,
          fieldsLocked: fieldsLocked,
        ),
      ],
    );
  }

  /// Terms & Conditions checkbox row, with a tappable link that opens
  /// the full Terms & Conditions screen.
  Widget termsAndConditionsRow(bool fieldsLocked) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: agreedToTerms,
            onChanged: fieldsLocked
                ? null
                : (value) {
                    setState(() {
                      agreedToTerms = value ?? false;
                    });
                  },
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("I agree to the "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool fieldsLocked = isRegistering;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text("$categoryLabel Registration"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// LOGO
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 10),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_balance,
                      size: 60,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    /// NAME — always visible
                    _field(
                      controller: nameController,
                      label: "Name",
                      icon: Icons.person,
                      fieldsLocked: fieldsLocked,
                    ),

                    /// PHONE NUMBER — already verified via OTP on the
                    /// login screen, so it's shown locked here with a
                    /// verified badge and is never editable.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: const Icon(Icons.phone),
                          suffixIcon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                    ),

                    /// Category-specific fields
                    if (isBusiness)
                      businessFields(fieldsLocked)
                    else
                      personalFields(fieldsLocked),

                    /// TERMS & CONDITIONS
                    termsAndConditionsRow(fieldsLocked),

                    /// REGISTER — enabled once Terms & Conditions are
                    /// accepted. Phone is already verified via the login
                    /// OTP step, so no further verification is needed
                    /// here.
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (isRegistering || !agreedToTerms)
                            ? null
                            : registerMember,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isRegistering
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "REGISTER",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}