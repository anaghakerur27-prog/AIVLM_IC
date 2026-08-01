import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationEnabled = true;

  Widget settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.blue,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "General",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            settingsTile(
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                goTo(const ChangePasswordScreen());
              },
            ),

            settingsTile(
              icon: Icons.notifications,
              title: "Notification Preferences",
              trailing: Switch(
                value: notificationEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationEnabled = value;
                  });
                },
              ),
              onTap: () {},
            ),

            const SizedBox(height: 25),

            const Text(
              "Information",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            settingsTile(
              icon: Icons.info,
              title: "About AIVLM-I&C",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("About"),
                    content: const Text(
                      "AIVLM-I&C\n\nALL INDIA VEERA SHAIVA LINGAYAT MAHASABHA\nIndustry & Commerce\n\nVersion 1.0.0",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),

            settingsTile(
              icon: Icons.support_agent,
              title: "Contact Support",
              onTap: () {
                goTo(const ContactSupportScreen());
              },
            ),

            settingsTile(
              icon: Icons.privacy_tip,
              title: "Privacy Policy",
              onTap: () {
                goTo(const PrivacyPolicyScreen());
              },
            ),

            settingsTile(
              icon: Icons.description,
              title: "Terms & Conditions",
              onTap: () {
                goTo(const TermsConditionsScreen());
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("No"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("LOGOUT", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Shared scaffold wrapper so every info/content page looks consistent.
class _InfoPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoPageScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

/// ---------------- Change Password ----------------
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: hook this up to your actual change-password API call.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoPageScaffold(
      title: "Change Password",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your current password";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: "New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return "Password must be at least 6 characters";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text(
                  "UPDATE PASSWORD",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Contact Support ----------------
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPageScaffold(
      title: "Contact Support",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Need help? Reach out to us through any of the channels below "
            "and our team will get back to you as soon as possible.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email"),
              subtitle: const Text("support@aivlmic.org"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Opening email app...")),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text("Phone"),
              subtitle: const Text("+91 98765 43210"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Opening dialer...")),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text("Office Address"),
              subtitle: const Text("AIVLM-I&C Head Office,\nKarnataka, India"),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Support Hours",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Monday - Saturday: 9:00 AM - 6:00 PM\nSunday: Closed",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Privacy Policy ----------------
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPageScaffold(
      title: "Privacy Policy",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PolicySection(
            heading: "1. Information We Collect",
            body:
                "We collect information you provide directly, such as your "
                "name, contact details, and membership information, as well "
                "as data generated through your use of the app.",
          ),
          _PolicySection(
            heading: "2. How We Use Your Information",
            body:
                "Your information is used to provide and improve our "
                "services, communicate updates, and maintain the security "
                "of your account.",
          ),
          _PolicySection(
            heading: "3. Data Sharing",
            body:
                "We do not sell your personal data. Information may be "
                "shared with trusted service providers only as needed to "
                "operate the app.",
          ),
          _PolicySection(
            heading: "4. Data Security",
            body:
                "We use reasonable technical and organizational measures to "
                "protect your data from unauthorized access, loss, or "
                "misuse.",
          ),
          _PolicySection(
            heading: "5. Your Rights",
            body:
                "You may request access to, correction of, or deletion of "
                "your personal data at any time by contacting our support "
                "team.",
          ),
          _PolicySection(
            heading: "6. Changes to This Policy",
            body:
                "This policy may be updated periodically. Continued use of "
                "the app after changes indicates your acceptance of the "
                "revised policy.",
          ),
        ],
      ),
    );
  }
}

/// ---------------- Terms & Conditions ----------------
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPageScaffold(
      title: "Terms & Conditions",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PolicySection(
            heading: "1. Acceptance of Terms",
            body:
                "By using this app, you agree to be bound by these Terms & "
                "Conditions. If you do not agree, please discontinue use of "
                "the app.",
          ),
          _PolicySection(
            heading: "2. Membership Use",
            body:
                "This app is intended for use by registered members of "
                "AIVLM-I&C. Accounts are personal and should not be shared "
                "with others.",
          ),
          _PolicySection(
            heading: "3. User Responsibilities",
            body:
                "You are responsible for maintaining the confidentiality of "
                "your login credentials and for all activity under your "
                "account.",
          ),
          _PolicySection(
            heading: "4. Prohibited Conduct",
            body:
                "You agree not to misuse the app, including attempting "
                "unauthorized access, distributing harmful content, or "
                "violating any applicable laws.",
          ),
          _PolicySection(
            heading: "5. Limitation of Liability",
            body:
                "The app is provided \"as is.\" We are not liable for any "
                "indirect or incidental damages arising from your use of "
                "the app.",
          ),
          _PolicySection(
            heading: "6. Contact",
            body:
                "For questions about these terms, please reach out via the "
                "Contact Support page within the app.",
          ),
        ],
      ),
    );
  }
}

/// Reusable heading + body block used by the Privacy Policy and
/// Terms & Conditions pages.
class _PolicySection extends StatelessWidget {
  final String heading;
  final String body;

  const _PolicySection({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
