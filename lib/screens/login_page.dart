import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/approved_member_ids.dart';
import 'home_page.dart';
import 'notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController memberIdController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;

  String? verificationId;

  // Captured when OTP is requested, so later steps never depend on
  // whatever is currently typed in the fields.
  String? _memberId;
  String? _phone;

  // --------------------------------------------------
  // PHONE NUMBER HELPERS
  // --------------------------------------------------

  String getCleanPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      cleanPhone = cleanPhone.substring(2);
    }

    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = cleanPhone.substring(1);
    }

    return cleanPhone;
  }

  String getFirebasePhoneNumber(String phone) {
    return '+91${getCleanPhoneNumber(phone)}';
  }

  bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(getCleanPhoneNumber(phone));
  }

  // --------------------------------------------------
  // STEP 1: VALIDATE MEMBER ID (approved list) + PHONE FORMAT
  // --------------------------------------------------

  Future<void> login() async {
    final memberId = memberIdController.text.trim();
    final enteredPhone = phoneController.text.trim();

    if (memberId.isEmpty) {
      showMessage("Enter your Member ID");
      return;
    }

    if (!ApprovedMemberIds.isApproved(memberId)) {
      showMessage("Invalid Member ID. You are not authorized to login.");
      return;
    }

    if (enteredPhone.isEmpty) {
      showMessage("Enter your phone number");
      return;
    }

    if (!isValidPhoneNumber(enteredPhone)) {
      showMessage("Enter a valid 10-digit Indian phone number");
      return;
    }

    _memberId = memberId;
    _phone = getCleanPhoneNumber(enteredPhone);

    setState(() => isLoading = true);

    await sendOtp(_phone!);
  }

  // --------------------------------------------------
  // STEP 2: SEND OTP
  // --------------------------------------------------

  Future<void> sendOtp(String phone) async {
    final firebasePhone = getFirebasePhoneNumber(phone);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: firebasePhone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);

            if (!mounted) return;

            await _routeAfterOtpVerified();
          } catch (e) {
            if (!mounted) return;

            setState(() => isLoading = false);
            showMessage("Automatic verification failed: $e");
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('FIREBASE PHONE AUTH ERROR');
          debugPrint('ERROR CODE: ${e.code}');
          debugPrint('ERROR MESSAGE: ${e.message}');

          if (!mounted) return;

          setState(() => isLoading = false);
          showMessage('${e.code}: ${e.message}');
        },

        codeSent: (String newVerificationId, int? resendToken) {
          if (!mounted) return;

          verificationId = newVerificationId;

          setState(() {
            isLoading = false;
            otpSent = true;
          });

          showMessage("OTP sent to +91 $phone");
        },

        codeAutoRetrievalTimeout: (String newVerificationId) {
          verificationId = newVerificationId;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('OTP SEND ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage("Unable to send OTP: $e");
    }
  }

  // --------------------------------------------------
  // STEP 3: VERIFY OTP
  // --------------------------------------------------

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      showMessage("Enter OTP");
      return;
    }

    if (otp.length != 6) {
      showMessage("Enter the 6-digit OTP");
      return;
    }

    if (verificationId == null) {
      showMessage("OTP session expired. Please request OTP again.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      await _routeAfterOtpVerified();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      String message = "Invalid OTP";

      if (e.code == 'invalid-verification-code') {
        message = "Incorrect OTP. Please check and try again.";
      } else if (e.code == 'session-expired') {
        message = "OTP expired. Please request a new OTP.";
      } else if (e.message != null) {
        message = e.message!;
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage("OTP verification failed: $e");
    }
  }

  // --------------------------------------------------
  // STEP 4: FIND MEMBER USING MEMBER ID
  // --------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>?> findMemberById(
    String memberId,
  ) async {
    final members = FirebaseFirestore.instance.collection('members');

    // Registration saves "memberId"; existing records may use
    // "membershipNumber". Search both and merge by document ID.
    final memberIdQuery =
        await members.where('memberId', isEqualTo: memberId).limit(2).get();

    final membershipNumberQuery = await members
        .where('membershipNumber', isEqualTo: memberId)
        .limit(2)
        .get();

    final Map<String, DocumentSnapshot<Map<String, dynamic>>> matches = {};

    for (final doc in memberIdQuery.docs) {
      matches[doc.id] = doc;
    }

    for (final doc in membershipNumberQuery.docs) {
      matches[doc.id] = doc;
    }

    if (matches.isEmpty) return null;

    if (matches.length > 1) {
      throw Exception("Multiple member records found for this Member ID.");
    }

    return matches.values.first;
  }

  // --------------------------------------------------
  // Sign out, reset to the first step and show a reason.
  // Used for every post-OTP rejection so an unauthorized
  // session is never left open.
  // --------------------------------------------------

  Future<void> _rejectLogin(String message) async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      otpSent = false;
      verificationId = null;
      otpController.clear();
    });

    showMessage(message);
  }

  // --------------------------------------------------
  // STEP 5: CHECK MEMBER RECORD AFTER OTP
  // --------------------------------------------------

  Future<void> _routeAfterOtpVerified() async {
    try {
      final memberId = _memberId ?? memberIdController.text.trim();

      if (!ApprovedMemberIds.isApproved(memberId)) {
        await _rejectLogin("Invalid Member ID.");
        return;
      }

      final member = await findMemberById(memberId);

      if (!mounted) return;

      if (member == null) {
        await _rejectLogin(
          "Member record not found. Please contact the administrator.",
        );
        return;
      }

      final memberData = member.data();

      if (memberData == null) {
        await _rejectLogin("Unable to load member details.");
        return;
      }

      // The phone that just passed OTP must be the phone registered for
      // this Member ID. Without this check, anyone who knows an approved
      // Member ID could log in as that member using their own phone.
      final verifiedPhone = getCleanPhoneNumber(
        FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
      );

      final registeredPhone = getCleanPhoneNumber(
        (memberData['phone'] ?? member.id).toString(),
      );

      if (verifiedPhone.isEmpty || verifiedPhone != registeredPhone) {
        await _rejectLogin(
          "This phone number does not match the one registered for this Member ID.",
        );
        return;
      }

      if (memberData['active'] != true) {
        await _rejectLogin(
          "Your membership is inactive. Please contact the administrator.",
        );
        return;
      }

      await loginAfterOtp(member.id);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage("Login error: $e");
    }
  }

  // --------------------------------------------------
  // STEP 6: OPEN DASHBOARD
  // --------------------------------------------------

  Future<void> loginAfterOtp(String firestoreDocumentId) async {
    try {
      await NotificationService.initialize(firestoreDocumentId);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(memberId: firestoreDocumentId),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage("Login successful, but dashboard could not open: $e");
    }
  }

  // --------------------------------------------------
  // RESEND OTP
  // --------------------------------------------------

  Future<void> resendOtp() async {
    final phone = _phone;

    if (phone == null || !isValidPhoneNumber(phone)) {
      changePhoneNumber();
      showMessage("Please enter your details again.");
      return;
    }

    setState(() {
      isLoading = true;
      otpController.clear();
    });

    await sendOtp(phone);
  }

  // --------------------------------------------------
  // CHANGE DETAILS
  // --------------------------------------------------

  void changePhoneNumber() {
    setState(() {
      otpSent = false;
      verificationId = null;
      otpController.clear();
      isLoading = false;
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  void dispose() {
    memberIdController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Member Login"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Container(
                  height: 140,
                  width: 140,
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
                      'assets/images/logo.jpeg',
                      height: 120,
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

                const SizedBox(height: 25),

                const Text(
                  "123 App",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (!otpSent) ...[
                          const Text(
                            "Member Login",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Enter your Member ID and registered phone number",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 25),
                          TextField(
                            controller: memberIdController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: "Member ID",
                              hintText: "Enter your Member ID",
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: "Registered Phone Number",
                              hintText: "Enter 10-digit phone number",
                              prefixIcon: const Icon(Icons.phone),
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          _primaryButton(label: "SEND OTP", onPressed: login),
                        ] else ...[
                          const Icon(
                            Icons.verified_user,
                            size: 55,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "OTP Verification",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter the OTP sent to\n+91 ${_phone ?? ''}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 25),
                          TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !isLoading,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              labelText: "Enter OTP",
                              hintText: "------",
                              counterText: "",
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          _primaryButton(
                            label: "VERIFY & CONTINUE",
                            onPressed: verifyOtp,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed:
                                    isLoading ? null : changePhoneNumber,
                                child: const Text("Change Details"),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: isLoading ? null : resendOtp,
                                child: const Text("Resend OTP"),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Welcome to 123 App Member Portal",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}