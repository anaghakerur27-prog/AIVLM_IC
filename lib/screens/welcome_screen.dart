import 'package:flutter/material.dart';

import 'register_page.dart';

class WelcomeScreen extends StatelessWidget {
  final String phone;

  const WelcomeScreen({super.key, required this.phone});

  void openRegister(BuildContext context, String memberType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(phone: phone, memberType: memberType),
      ),
    );
  }

  /// Category button — filled (primary) or outlined style.
  Widget categoryButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Select Category"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  /// LOGO
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance,
                            size: 70,
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// APP NAME
                  const Text(
                    "AIVLM-I&C",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "ALL INDIA VEERA SHAIVA\nLINGAYAT MAHASABHA\nINDUSTRY & COMMERCE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "You're not registered yet.\nPlease select your category to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 40),

                  /// BUSINESS
                  categoryButton(
                    context: context,
                    title: "BUSINESS",
                    icon: Icons.business,
                    filled: true,
                    onPressed: () {
                      openRegister(context, "business");
                    },
                  ),

                  const SizedBox(height: 16),

                  /// NON-BUSINESS
                  categoryButton(
                    context: context,
                    title: "NON-BUSINESS",
                    icon: Icons.person,
                    filled: false,
                    onPressed: () {
                      openRegister(context, "non_business");
                    },
                  ),

                  const SizedBox(height: 16),

                  /// STUDENT
                  categoryButton(
                    context: context,
                    title: "STUDENT",
                    icon: Icons.school,
                    filled: false,
                    onPressed: () {
                      openRegister(context, "student");
                    },
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "Welcome to AIVLM-I&C Member Portal",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}