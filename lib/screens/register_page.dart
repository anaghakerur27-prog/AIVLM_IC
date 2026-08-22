import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Shared
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // Business only
  final TextEditingController memberIdController = TextEditingController();

  // Non-business / Student only
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool otpSent = false;
  bool phoneVerified = false;
  bool isSendingOtp = false;
  bool isVerifying = false;
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
    phoneController.text = widget.phone;
  }

  /// STEP 1: Send OTP to the phone number entered
  Future<void> sendOtp() async {
    String phone = phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showMessage("Enter a valid phone number");
      return;
    }

    // Adjust country code prefix as needed for your user base.
    final String formattedPhone =
        phone.startsWith('+') ? phone : '+91$phone';

    setState(() => isSendingOtp = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          await _confirmCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          setState(() => isSendingOtp = false);
          _showMessage("OTP failed: ${e.message}");
        },

        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            otpSent = true;
            isSendingOtp = false;
          });
          _showMessage("OTP sent to $formattedPhone");
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => isSendingOtp = false);
      _showMessage("Error sending OTP: $e");
    }
  }

  /// STEP 2: Verify the OTP entered
  Future<void> verifyOtp() async {
    String otp = otpController.text.trim();

    if (_verificationId == null) {
      _showMessage("Please request an OTP first");
      return;
    }

    if (otp.isEmpty || otp.length < 6) {
      _showMessage("Enter the 6-digit OTP");
      return;
    }

    setState(() => isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _confirmCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => isVerifying = false);
      _showMessage("Invalid OTP: ${e.message}");
    } catch (e) {
      setState(() => isVerifying = false);
      _showMessage("Error: $e");
    }
  }

  Future<void> _confirmCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        phoneVerified = true;
        isSendingOtp = false;
        isVerifying = false;
      });

      _showMessage("Phone number verified");
    } on FirebaseAuthException catch (e) {
      _showMessage("Verification failed: ${e.message}");
      setState(() {
        isSendingOtp = false;
        isVerifying = false;
      });
    }
  }

  /// STEP 3: Save member to Firestore once phone is verified.
  /// Business: Name + Phone + Member ID.
  /// Non-Business / Student: Name + Email + Phone + Address + Pincode.
  /// Both always save userType.
  Future<void> registerMember() async {
    if (!phoneVerified) {
      _showMessage("Please verify your phone number first");
      return;
    }

    if (!agreedToTerms) {
      _showMessage("Please agree to the Terms & Conditions to continue");
      return;
    }

    String name = nameController.text.trim();
    String phone = phoneController.text.trim();

    if (isBusiness) {
      String memberId = memberIdController.text.trim();

      if (name.isEmpty || memberId.isEmpty || phone.isEmpty) {
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
          'memberId': memberId,
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
      String pincode = pincodeController.text.trim();

      if (name.isEmpty ||
          phone.isEmpty ||
          email.isEmpty ||
          address.isEmpty ||
          pincode.isEmpty) {
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
          'pincode': pincode,
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
    memberIdController.dispose();
    emailController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// Business registration fields: Name + Phone + Member ID + OTP
  /// (Name and Phone are rendered by the shared section above this;
  /// this widget only adds the Member ID field.)
  Widget businessFields(bool fieldsLocked) {
    return Column(
      children: [
        TextField(
          controller: memberIdController,
          enabled: !fieldsLocked,
          decoration: InputDecoration(
            labelText: "Member ID",
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Non-Business / Student registration fields:
  /// Name + Email + Phone + Address + Pincode + OTP
  /// (Name and Phone are rendered by the shared section above this;
  /// this widget adds Email, Address, and Pincode.)
  Widget personalFields(bool fieldsLocked) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !fieldsLocked,
          decoration: InputDecoration(
            labelText: "Email ID",
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: addressController,
          maxLines: 3,
          enabled: !fieldsLocked,
          decoration: InputDecoration(
            labelText: "Address",
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          enabled: !fieldsLocked,
          decoration: InputDecoration(
            labelText: "Pincode",
            prefixIcon: const Icon(Icons.pin_drop),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        const SizedBox(height: 10),
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
                    TextField(
                      controller: nameController,
                      enabled: !fieldsLocked,
                      decoration: InputDecoration(
                        labelText: "Name",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// PHONE NUMBER — editable until verified
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !otpSent && !phoneVerified,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: phoneVerified
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Category-specific fields
                    if (isBusiness)
                      businessFields(fieldsLocked)
                    else
                      personalFields(fieldsLocked),

                    /// SEND OTP
                    if (!otpSent && !phoneVerified)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSendingOtp ? null : sendOtp,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isSendingOtp
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "SEND OTP",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                    /// ENTER + VERIFY OTP
                    if (otpSent && !phoneVerified) ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: "Enter OTP",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isVerifying ? null : verifyOtp,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isVerifying
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "VERIFY OTP",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: isSendingOtp
                            ? null
                            : () {
                                setState(() {
                                  otpSent = false;
                                  otpController.clear();
                                });
                              },
                        child: const Text("Change phone number / Resend"),
                      ),
                    ],

                    /// VERIFIED CONFIRMATION
                    if (phoneVerified) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Phone number verified",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// TERMS & CONDITIONS
                    termsAndConditionsRow(fieldsLocked),

                    /// REGISTER — only enabled after phone verification
                    /// and agreeing to the Terms & Conditions
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            (isRegistering || !phoneVerified || !agreedToTerms)
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