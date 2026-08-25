import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'welcome_screen.dart';
import 'home_page.dart';
import 'notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;

  String? verificationId;

  /// Converts the entered phone number into a clean 10-digit number.
  String getCleanPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // If user enters +91XXXXXXXXXX
    if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      cleanPhone = cleanPhone.substring(2);
    }

    // If user enters 0XXXXXXXXXX
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = cleanPhone.substring(1);
    }

    return cleanPhone;
  }

  /// Firebase Phone Authentication needs country code.
  String getFirebasePhoneNumber(String phone) {
    final cleanPhone = getCleanPhoneNumber(phone);
    return '+91$cleanPhone';
  }

  /// Check whether the phone number is valid.
  bool isValidPhoneNumber(String phone) {
    final cleanPhone = getCleanPhoneNumber(phone);

    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanPhone);
  }

  /// Main login function.
  ///
  /// Every phone number is verified via OTP first — whether the member
  /// is already registered or not. Once the OTP is confirmed,
  /// _routeAfterOtpVerified() decides where they go next.
  Future<void> login() async {
    final enteredPhone = phoneController.text.trim();

    if (enteredPhone.isEmpty) {
      showMessage("Enter phone number");
      return;
    }

    if (!isValidPhoneNumber(enteredPhone)) {
      showMessage("Enter a valid 10-digit Indian phone number");
      return;
    }

    final phone = getCleanPhoneNumber(enteredPhone);

    setState(() {
      isLoading = true;
    });

    await sendOtp(phone);
  }

  /// Send OTP using Firebase Phone Authentication.
  Future<void> sendOtp(String phone) async {
    final firebasePhone = getFirebasePhoneNumber(phone);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: firebasePhone,

        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          /*
           * Android can sometimes automatically detect the OTP.
           *
           * We still sign in automatically here, then run the same
           * routing decision as manual OTP entry.
           */
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);

            if (!mounted) return;

            await _routeAfterOtpVerified(phone);
          } catch (e) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });

              showMessage("Automatic verification failed: $e");
            }
          }
        },

        verificationFailed: (FirebaseAuthException e) {
  debugPrint('====================================');
  debugPrint('FIREBASE PHONE AUTH ERROR');
  debugPrint('ERROR CODE: ${e.code}');
  debugPrint('ERROR MESSAGE: ${e.message}');
  debugPrint('====================================');

  if (!mounted) return;

  setState(() {
    isLoading = false;
  });

  showMessage(
    '${e.code}: ${e.message}',
  );
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
  debugPrint('====================================');
  debugPrint('OTP SEND ERROR');
  debugPrint('ERROR: $e');
  debugPrint('STACK TRACE: $stackTrace');
  debugPrint('====================================');

  if (!mounted) return;

  setState(() {
    isLoading = false;
  });

  showMessage("Unable to send OTP: $e");
}
  }

  /// Verify OTP entered by the member.
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

    setState(() {
      isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      final phone = getCleanPhoneNumber(phoneController.text.trim());

      await _routeAfterOtpVerified(phone);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

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

      setState(() {
        isLoading = false;
      });

      showMessage("OTP verification failed: $e");
    }
  }

  /// Called once the phone number has been verified via OTP (either by
  /// auto-retrieval or manual entry). Looks up the member in Firestore
  /// and sends them to the right place:
  ///   - already registered  -> straight into the Dashboard
  ///   - not registered yet  -> WelcomeScreen to pick a category, then
  ///                            fill in their profile (no further OTP —
  ///                            the phone is already verified)
  Future<void> _routeAfterOtpVerified(String phone) async {
    try {
      final member = await FirebaseFirestore.instance
          .collection('members')
          .doc(phone)
          .get();

      if (!mounted) return;

      if (member.exists) {
        await loginAfterOtp(phone);
      } else {
        setState(() {
          isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(phone: phone),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage("Error: $e");
    }
  }

  /// Called for an already-registered member once OTP is verified.
  Future<void> loginAfterOtp(String phone) async {
    try {
      /*
       * Save / initialize notification service.
       */
      await NotificationService.initialize(phone);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            memberId: phone,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage("Login successful, but dashboard could not open: $e");
    }
  }

  /// Show snackbar.
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

  /// Resend OTP.
  Future<void> resendOtp() async {
    final phone = getCleanPhoneNumber(phoneController.text.trim());

    if (!isValidPhoneNumber(phone)) {
      showMessage("Invalid phone number");
      return;
    }

    setState(() {
      isLoading = true;
      otpController.clear();
    });

    await sendOtp(phone);
  }

  /// Go back from OTP screen to phone number screen.
  void changePhoneNumber() {
    setState(() {
      otpSent = false;
      verificationId = null;
      otpController.clear();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

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

                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------
                Container(
                  height: 140,
                  width: 140,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(15),

                    child: Image.asset(
                      'assets/images/logo.png',

                      height: 120,

                      fit: BoxFit.contain,

                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
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

                // ------------------------------------------------
                // APP NAME
                // ------------------------------------------------
                const Text(
                  "AIVLM-I&C",

                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "ALL INDIA VEERA SHAIVA\n"
                  "LINGAYAT MAHASABHA\n"
                  "INDUSTRY & COMMERCE",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // ------------------------------------------------
                // LOGIN / OTP CARD
                // ------------------------------------------------
                Card(
                  elevation: 6,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        // ====================================================
                        // PHONE NUMBER SCREEN
                        // ====================================================
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
                            "Enter your phone number",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 25),

                          TextField(
                            controller: phoneController,

                            keyboardType: TextInputType.phone,

                            maxLength: 10,

                            enabled: !isLoading,

                            decoration: InputDecoration(
                              labelText: "Phone Number",
                              hintText: "Enter 10-digit phone number",

                              prefixIcon: const Icon(
                                Icons.phone,
                              ),

                              counterText: "",

                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 55,

                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : login,

                              style:
                                  ElevatedButton.styleFrom(
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),

                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,

                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "CONTINUE",

                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ]

                        // ====================================================
                        // OTP SCREEN
                        // ====================================================
                        else ...[
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
                            "Enter the OTP sent to\n"
                            "+91 ${getCleanPhoneNumber(phoneController.text)}",

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 25),

                          TextField(
                            controller: otpController,

                            keyboardType:
                                TextInputType.number,

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

                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),

                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 55,

                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : verifyOtp,

                              style:
                                  ElevatedButton.styleFrom(
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),

                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,

                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "VERIFY & CONTINUE",

                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : changePhoneNumber,

                                child: const Text(
                                  "Change Number",
                                ),
                              ),

                              const SizedBox(width: 10),

                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : resendOtp,

                                child: const Text(
                                  "Resend OTP",
                                ),
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
                  "Welcome to AIVLM-I&C Member Portal",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}