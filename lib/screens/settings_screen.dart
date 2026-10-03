import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  /// The Firestore doc id (cleaned phone number) for the signed-in
  /// member — needed so "Delete Account" knows which document to remove.
  final String memberId;

  const SettingsScreen({super.key, required this.memberId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationEnabled = true;
  bool isDeletingAccount = false;

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

  /// Permanently deletes the member's account: their Firestore document
  /// and their Firebase Auth user. Both are removed — this cannot be
  /// undone, unlike Logout which just ends the current session.
  Future<void> _deleteAccount() async {
    setState(() => isDeletingAccount = true);

    try {
      // 1. Delete the member's data from Firestore.
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .delete();

      // 2. Delete the underlying Firebase Auth account itself, so the
      // phone number is no longer tied to any credential.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        // No signed-in Auth user to delete (e.g. session already
        // expired) — the Firestore document is gone either way, which
        // is what matters for "account deleted".
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isDeletingAccount = false);

      if (e.code == 'requires-recent-login') {
        // Firebase requires a recent sign-in before allowing account
        // deletion, for security. Since login here is OTP-based, the
        // simplest recovery is asking the user to log out and log back
        // in (which re-verifies via OTP) and then delete again.
        showMessage(
          'For security, please log out, log back in with OTP, then '
          'try deleting your account again.',
        );
      } else {
        showMessage('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isDeletingAccount = false);
      showMessage('Failed to delete account: $e');
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account and all your data. "
          "This action cannot be undone. Are you sure you want to "
          "continue?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
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
              title: "About 123 App",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("About"),
                    content: const Text(
                      "123 App\n\nIndustry & Commerce\n\nVersion 1.0.0",
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

            const SizedBox(height: 25),

            const Text(
              "Danger Zone",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            settingsTile(
              icon: Icons.delete_forever,
              title: "Delete Account",
              iconColor: Colors.red,
              trailing: isDeletingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: isDeletingAccount ? () {} : _confirmDeleteAccount,
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
              subtitle: const Text("support@123app.org"),
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
              subtitle: const Text("123 App Head Office,\nKarnataka, India"),
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
/// Full text, shown as-is rather than the earlier condensed 6-point
/// summary. App/organization name references updated to "123 App".
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _privacyText = '''
PRIVACY POLICY

123 App

Effective Date: [DD/MM/YYYY]
Last Updated: [DD/MM/YYYY]

This Privacy Policy explains how 123 App ("we", "us", or "our") collects, uses, stores, protects, and shares information when you access or use the 123 App mobile application ("Application", "App", or "Platform").

By downloading, registering, accessing, or using the Application, you acknowledge that you have read and understood this Privacy Policy. If you do not agree with this Privacy Policy, please discontinue use of the Application.

1. INFORMATION WE COLLECT

Depending on how you use the Application, we may collect the following information:

1.1 Registration and Account Information

When you create or access an account, we may collect:

Name
Mobile number
Email address
User type, such as Business, Non-Business, or Student
Membership or identification information, where applicable
OTP verification information
Account-related information

Your mobile number may be used to authenticate your account through a One-Time Password (OTP).

1.2 Business Information

Business Users may provide information including:

Business or company name
Owner or contact person's name
Business category and industry
Business address
District and pincode
Phone number and email address
Website information
Products and services
Business description
GST or other business-related information, where applicable
Business logo and photographs
Visiting card or business documents
Other information voluntarily submitted as part of a business profile

1.3 Non-Business and Student Information

Non-Business and Student Users may provide information such as:

Name
Mobile number
Email address
Address
Pincode
Other profile or contact information voluntarily provided through the Application

1.4 Requirements, Enquiries and User Content

When you submit a requirement, enquiry, business information, product/service information, photograph, document, or other content, we may collect and store the information contained in that submission.

Users should not submit passwords, OTPs, bank login credentials, ATM PINs, payment authentication codes, or other highly confidential security information through the Application.

1.5 Technical Information

We may also receive limited technical information necessary to operate and secure the Application, such as device information, application version, operating system information, crash information, network-related information, and security or diagnostic information.

2. HOW WE USE INFORMATION

We may use information collected through the Application for legitimate purposes, including:

Creating and managing User accounts.
Providing mobile-number and OTP authentication.
Providing Application features and services.
Displaying User profiles and business listings.
Helping Users discover businesses, products, services, and professionals.
Facilitating requirements, enquiries, and business connections.
Enabling communication between Users where the Application provides such functionality.
Providing customer support and responding to complaints.
Maintaining Application security and preventing fraud, abuse, and unauthorized access.
Detecting technical problems and improving Application performance.
Maintaining records necessary for legitimate operational, legal, regulatory, and security purposes.
Complying with applicable laws, regulations, legal requests, or lawful government authorities.
Protecting the rights, property, safety, and security of 123 App, its Users, and third parties.

We will use personal information only for purposes reasonably connected with the operation, administration, security, improvement, and legitimate use of the Application, subject to applicable law.

3. INFORMATION VISIBILITY AND SHARING

123 App is designed to facilitate business discovery, networking, requirements, enquiries, and communication.

Depending on the Application's functionality and the User's actions, certain information may be visible to other Users.

For example, a business profile may display business name, industry, products, services, address, contact information, or other information provided by the Business User.

Similarly, when a User voluntarily publishes a requirement containing contact information, that information may be made available to relevant Users or businesses who are permitted to view or respond to the requirement.

3.1 Third-Party Service Providers

We may use third-party service providers for services necessary to operate the Application, such as:

Authentication and OTP services
Cloud hosting and database services
File and image storage
Application infrastructure
Technical monitoring and diagnostics
Security and fraud prevention
Other services necessary for Application functionality

Such providers may process information on our behalf as necessary to provide their services, subject to applicable contractual, legal, and security requirements.

3.2 Legal Requirements

We may disclose information where reasonably necessary to:

Comply with applicable law or legal obligations.
Respond to valid legal requests.
Protect the safety and security of Users or third parties.
Investigate fraud, abuse, security incidents, or unlawful activity.
Protect the rights and property of 123 App.

We do not intend to sell Users' personal information as a commercial product.

4. USER RESPONSIBILITY

Users are responsible for ensuring that information submitted to the Application is accurate and appropriate.

If a User provides information belonging to another person, company, organization, or entity, the User should have the necessary authorization or legal basis to provide that information.

Users should carefully consider what personal, confidential, financial, or commercially sensitive information they publish.

In particular, Users should never publish OTPs, passwords, bank account login credentials, ATM PINs, card security codes, or payment authentication information through profiles, requirements, enquiries, or other Application features.

5. DATA SECURITY

123 App takes reasonable measures designed to protect information against unauthorized access, misuse, alteration, disclosure, loss, or destruction.

Security measures may include appropriate access controls, authentication mechanisms, restricted administrative access, secure data transmission where supported, and other technical and organizational safeguards appropriate to the nature of the information.

However, no electronic storage or transmission system can be guaranteed to be completely secure.

Users are responsible for protecting their registered mobile number, OTPs, authentication information, and access to their devices.

If you believe your account has been accessed without authorization or that your information may have been compromised, please contact 123 App as soon as reasonably possible.

6. DATA RETENTION

We may retain information for as long as reasonably necessary to:

Provide and maintain the Application.
Maintain User accounts and profiles.
Provide requested services.
Maintain business and operational records.
Resolve complaints and disputes.
Prevent fraud and misuse.
Maintain security records.
Comply with legal, regulatory, accounting, or other applicable obligations.

When information is no longer reasonably required, it may be deleted, anonymized, or securely disposed of, subject to applicable legal and operational requirements.

7. USER RIGHTS AND REQUESTS

Subject to applicable law, Users may contact 123 App regarding their personal information and may request assistance relating to:

Accessing information associated with their account.
Correcting inaccurate or outdated information.
Updating profile information.
Deleting or closing an account, where applicable.
Raising privacy-related concerns or complaints.

Some information may need to be retained where required for legal, security, fraud-prevention, dispute-resolution, or legitimate operational purposes.

Requests may be subject to reasonable verification to protect against unauthorized access to another person's information.

8. CHILDREN AND MINORS

The Application is intended for eligible Users who can lawfully use the services under applicable law.

Users should not provide personal information belonging to a child or minor without the necessary authorization or legal basis.

If 123 App becomes aware that personal information has been submitted in violation of applicable requirements relating to children or minors, appropriate steps may be taken to review and remove such information where required.

9. THIRD-PARTY LINKS AND SERVICES

The Application may contain links, references, advertisements, or integrations involving third-party websites, applications, services, or businesses.

123 App does not control the privacy practices of third parties.

When a User accesses a third-party website or service, that third party's privacy policy and terms may apply. Users should review the applicable privacy policies before providing personal information to third parties.

10. CHANGES TO THIS PRIVACY POLICY

123 App may update this Privacy Policy from time to time to reflect changes in the Application, technology, legal requirements, services, or privacy practices.

When appropriate, material changes may be communicated through the Application or other available communication channels.

The updated Privacy Policy will indicate the revised "Last Updated" date.

Continued use of the Application after an updated Privacy Policy becomes effective may constitute acknowledgement of the updated policy, to the extent permitted by applicable law.

11. GOVERNING LAW

This Privacy Policy shall be governed by and interpreted in accordance with the applicable laws of India.

Any disputes concerning this Privacy Policy shall be subject to the jurisdiction of the competent courts at [Bengaluru, Karnataka, India], subject to applicable law.

12. CONTACT & PRIVACY COMPLAINTS

If you have questions, requests, complaints, or concerns regarding this Privacy Policy or the handling of your personal information, you may contact:

Application:
123 App

Official Email:
[Insert Official Email Address]

Contact Number:
[Insert Official Contact Number]

Office / Registered Address:
[Insert Official Address]

13. USER ACKNOWLEDGEMENT

By registering, logging in, accessing, or continuing to use 123 App, you acknowledge that:

You have read and understood this Privacy Policy.
You understand the types of information that may be collected and used.
You understand that information voluntarily published through certain Application features may be visible to other Users.
You are responsible for the accuracy of information you provide.
You will not submit confidential authentication or financial security information through the Application.
You understand that third-party services may be used to support Application functionality.
You understand that your information may be retained where reasonably necessary for legitimate operational, security, legal, or regulatory purposes.
You may contact 123 App regarding privacy-related questions or concerns.

By continuing to use 123 App, you acknowledge that you have read, understood, and accepted this Privacy Policy.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _privacyText,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}

/// ---------------- Terms & Conditions ----------------
/// Full text, shown as-is rather than the earlier condensed 6-point
/// summary. App/organization name references updated to "123 App".
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String _termsText = '''
TERMS & CONDITIONS
123 App

Effective Date: [DD/MM/YYYY]
Last Updated: [DD/MM/YYYY]

These Terms & Conditions ("Terms") govern your access to and use of the 123 App mobile application ("Application", "App", or "Platform"), operated by 123 App ("we", "us", or "our").

By downloading, accessing, registering, logging into, browsing, or using the Application, you ("User", "you", or "your") acknowledge that you have read, understood, and agreed to these Terms & Conditions. If you do not agree with these Terms, you should not access or use the Application.

1. ACCEPTANCE OF TERMS & CONDITIONS

1.1
These Terms & Conditions constitute an agreement between the User and 123 App concerning the use of the Application. By registering for an account, logging in through the mobile number and OTP verification process, accessing any feature, creating a profile, listing a business, adding a product or service, posting a requirement, responding to a requirement, or otherwise using the Application, the User confirms their acceptance of these Terms.

1.2
These Terms apply to every person or entity accessing or using the Application, regardless of whether the person uses the Application for business, non-business, educational, professional, commercial, networking, or other legitimate purposes.

1.3
The Application may contain additional policies, notices, guidelines, rules, instructions, or terms applicable to specific features. Such provisions shall be considered part of these Terms when they are made available to the User.

1.4
Users are responsible for reviewing the Terms before using the Application. If a User does not agree with any provision, the User must discontinue use of the Application.

1.5
123 App reserves the right to modify, update, replace, add, or remove any portion of these Terms from time to time. Changes may be communicated through the Application or other appropriate means.

1.6
Where permitted by applicable law, continued use of the Application after revised Terms become effective will constitute the User's acceptance of the revised Terms.

1.7
These Terms should be read together with the Application's Privacy Policy and any other applicable policies published within the Application.

2. APPLICATION PURPOSE, USER ELIGIBILITY & REGISTRATION

2.1 Purpose of 123 App
123 App is a digital industry and commerce platform developed to facilitate business discovery, industry networking, product and service visibility, requirement sharing, professional interaction, and communication between users.

The Application is intended to bring together businesses and industries from different sectors and provide users with a common platform through which they may discover businesses, products, services, opportunities, requirements, and potential business connections.

The Application may be used by business owners, entrepreneurs, manufacturers, suppliers, distributors, service providers, professionals, companies, organizations, students, non-business users, customers, prospective customers, and other eligible users.

2.2
The Application is intended to facilitate connections and information sharing. Unless specifically stated otherwise, 123 App does not itself become a party to any agreement, contract, purchase, sale, service arrangement, employment arrangement, partnership, or other transaction entered into between Users.

2.3 User Eligibility
Users must provide information that is accurate and appropriate to their actual identity or the organization they are authorized to represent.

Where a User registers on behalf of a company, business, organization, institution, or other legal entity, the User represents that they have the authority to provide information and act on behalf of that entity.

2.4 Mobile Number Registration
The Application may require a User to register using a valid mobile number. The mobile number may be used for account creation, login, authentication, OTP verification, important service communications, security notifications, and other legitimate Application-related purposes.

2.5 OTP Verification
123 App may use a One-Time Password ("OTP") to verify access to the registered mobile number.

The User is responsible for ensuring that the mobile number provided during registration belongs to them or that they are authorized to use it. The User must not attempt to register or access an account using another person's mobile number without authorization.

OTP verification is an authentication mechanism and does not necessarily constitute verification of the User's identity, business ownership, financial position, professional qualifications, company registration, or legal status.

2.6 Account Security
The User is responsible for maintaining the security of their account and registered mobile number. The User must not share OTPs, authentication codes, passwords, or other account security information with unauthorized persons.

If the User believes that their account has been accessed without authorization, they should notify 123 App through the available support or contact mechanism as soon as reasonably possible.

2.7
123 App reserves the right to restrict, suspend, disable, or terminate an account where the information provided is false, misleading, unauthorized, fraudulent, unlawful, or otherwise inconsistent with these Terms.

3. BUSINESS, INDUSTRY, PRODUCT & SERVICE LISTINGS

3.1
123 App may provide listings and categories covering a broad range of industries, businesses, products, and services. The purpose of these listings is to help Users discover and connect with businesses and service providers relevant to their interests or requirements.

3.2
Eligible business Users may create a business profile or listing and may provide information such as business name, industry, business category, description, address, contact details, email address, products, services, photographs, logo, website information, and other relevant business information.

3.3
The User acknowledges that all information submitted in connection with a business, industry, product, or service listing is the responsibility of the User who submitted it.

The User must ensure that the information is accurate, complete, current, and not misleading. If any important information changes, the User should update the relevant information within the Application where such functionality is available.

3.4
A User must not claim ownership, authorization, certification, dealership, distributorship, professional qualification, industry affiliation, government approval, or other status unless the User is legally entitled to make such a claim.

3.5
Users listing products or services are responsible for ensuring that such products and services are legally permitted to be offered, advertised, promoted, sold, or provided under applicable laws and regulations.

3.6
Descriptions, specifications, photographs, prices, availability, delivery information, warranty claims, certifications, performance claims, and other representations relating to a product or service must be truthful and not intentionally misleading.

3.7
123 App may, where reasonably necessary, review, categorize, modify, restrict, hide, reject, or remove a business, product, or service listing if it appears to violate these Terms, applicable law, intellectual property rights, platform standards, or the rights of another person.

3.8
The presence of a business, product, service, or industry listing on 123 App does not, by itself, mean that 123 App has verified, approved, recommended, certified, endorsed, or guaranteed that business, product, or service.

3.9
Users should independently verify important business information before entering into any commercial or professional relationship with another User.

4. REQUIREMENTS, ENQUIRIES & USER-GENERATED CONTENT

4.1
123 App may allow Users to publish requirements or enquiries relating to products, services, suppliers, manufacturers, professionals, business opportunities, or other legitimate needs.

4.2
A User posting a requirement may voluntarily provide information necessary for another User to understand and respond to the requirement. Such information may include the User's name, mobile number, email address, company name, address, location, requirement details, product or service specifications, quantity, and other relevant information.

4.3
The User is solely responsible for the accuracy and legality of the requirement and information submitted with it. A User must not intentionally publish a fake, fraudulent, misleading, abusive, unlawful, or deceptive requirement.

4.4
Depending on the functionality of the Application, information contained in a requirement may be made available to relevant businesses, service providers, or other Users so that they can review the requirement and contact or respond to the User.

4.5
By voluntarily publishing contact information or other details as part of a requirement, the User acknowledges that such information may be visible to Users who are permitted to access that requirement.

4.6
Users should exercise caution when deciding what information to publish. Users should not publish passwords, OTPs, payment authentication codes, ATM PINs, bank login credentials, or other highly confidential security information in a requirement or public profile.

4.7
Users are responsible for all content they upload, submit, publish, or otherwise make available through the Application. This includes text, photographs, logos, videos, documents, product information, service information, business information, and requirements.

4.8
A User must ensure that submitted content does not violate any applicable law or infringe the copyright, trademark, privacy, confidentiality, contractual, or other legal rights of another person or organization.

4.9
123 App may remove, restrict, disable, or modify User-generated content where it reasonably believes that the content violates these Terms, applicable law, or the rights or safety of Users or third parties.

5. USER RESPONSIBILITIES & PROHIBITED ACTIVITIES

5.1
Every User is expected to use 123 App in a lawful, responsible, respectful, and honest manner. The Application must not be used for any purpose that violates applicable law or these Terms.

5.2
Users are responsible for the information they provide and must not knowingly provide false, inaccurate, incomplete, fraudulent, or misleading information.

5.3
Users must not impersonate or falsely represent another individual, company, organization, institution, brand, government authority, or other entity.

5.4
Users must not use another person's identity, mobile number, business information, account, photographs, documents, or other personal information without appropriate authorization.

5.5
The Application must not be used to conduct, facilitate, promote, or support unlawful activities, scams, fraudulent schemes, phishing, deceptive practices, harassment, threats, abuse, or activities intended to cause harm to another person.

5.6
Users must not upload or transmit viruses, malware, ransomware, malicious code, corrupted files, or other technologies intended to interfere with or damage the Application, devices, accounts, or information of another person.

5.7
Users must not attempt to obtain unauthorized access to another User's account, the Application's administrative systems, databases, servers, APIs, security systems, or other restricted areas.

5.8
Users must not interfere with the normal operation, performance, security, or availability of the Application.

5.9
Without prior authorization, Users must not use bots, automated systems, scripts, scraping tools, data-mining tools, or similar technologies to systematically collect, copy, extract, reproduce, or manipulate information available through the Application.

5.10
Users must not use contact information obtained through 123 App for unlawful purposes, harassment, spam, fraudulent activities, or excessive unsolicited communication.

5.11
Users must not upload or distribute content that is unlawful, defamatory, threatening, abusive, obscene, fraudulent, intentionally misleading, or otherwise prohibited under applicable law.

5.12
123 App may take appropriate action against Users who violate these requirements, including removal of content, restriction of features, suspension of accounts, or termination of access.

6. BUSINESS TRANSACTIONS, VERIFICATION & THIRD-PARTY INFORMATION

6.1
123 App is primarily a platform for discovery, networking, information sharing, and communication. The Application may help Users find businesses, industries, products, services, suppliers, customers, professionals, and other potential business connections.

6.2
Unless expressly stated otherwise, 123 App is not the seller, purchaser, manufacturer, supplier, distributor, service provider, agent, broker, representative, or contracting party for transactions between Users.

6.3
123 App does not guarantee that any User, business, company, product, service, requirement, offer, quotation, statement, or other information published on the Application is accurate, authentic, reliable, safe, lawful, financially sound, or suitable for a particular purpose.

6.4
Users are responsible for conducting their own due diligence before entering into a relationship or transaction with another User. Depending on the nature of the transaction, Users should consider independently verifying the identity of the other party, business registration, applicable licenses, certifications, product specifications, pricing, payment terms, delivery commitments, warranties, and other relevant information.

6.5
If two or more Users enter into a transaction after connecting through 123 App, the transaction is between those Users unless 123 App has expressly agreed in writing to participate as a party.

6.6
The parties to a transaction are responsible for agreeing upon and fulfilling their own commercial terms, including price, payment, delivery, quantity, quality, installation, warranty, return, refund, taxation, documentation, and other contractual obligations.

6.7
Any dispute concerning a transaction, product, service, payment, delivery, quality, warranty, representation, or business relationship should primarily be addressed between the parties involved, subject to applicable law.

6.8
123 App may provide access to or references to third-party websites, applications, businesses, services, advertisements, or other external resources. 123 App does not necessarily control or endorse such third-party resources.

6.9
Users access third-party services at their own risk and should review the terms, privacy policies, and other applicable conditions of the relevant third party.

7. PRIVACY, PERSONAL INFORMATION & DATA USAGE

7.1
123 App may collect, store, use, process, and otherwise handle information required to provide and operate the Application and its features.

7.2
Depending on the features used by a User, information may include registration and authentication information, name, mobile number, email address, business or company information, address, location information, product and service information, requirements, User-generated content, device information, technical information, and other information voluntarily provided by the User.

7.3
The collection and processing of personal information will be carried out in accordance with the Application's Privacy Policy and applicable law.

7.4
Information may be used for legitimate purposes connected with the operation and administration of the Application, including account authentication, OTP verification, providing Application functionality, displaying profiles and listings, facilitating requirements and enquiries, enabling User communication, customer support, security, fraud prevention, improving services, and complying with legal obligations.

7.5
Where the Application allows a User to publish information publicly or to relevant Users, the User understands that the information may be viewed by such Users. For example, when a User posts a requirement containing their contact details, those details may be made available to relevant businesses or Users who are permitted to respond to that requirement.

7.6
Users should carefully consider what personal, business, confidential, or commercially sensitive information they publish through the Application.

7.7
If a User submits information relating to another person or organization, the User is responsible for ensuring that they have the necessary authority or permission to provide that information where required by applicable law.

7.8
123 App may retain information for periods reasonably necessary for legitimate business, operational, security, legal, regulatory, dispute-resolution, or other lawful purposes, subject to applicable law and the Privacy Policy.

7.9
Users should review the Privacy Policy for detailed information regarding the types of information collected, purposes of processing, storage, sharing, security measures, retention, and applicable User rights.

8. INTELLECTUAL PROPERTY, USER CONTENT & APPLICATION RIGHTS

8.1
The 123 App Application, including its software, interface, design, layout, graphics, logos, trademarks, text, databases, functionality, and other original materials, may be protected by copyright, trademark, and other applicable intellectual property laws.

8.2
Except where expressly permitted by 123 App or applicable law, Users must not reproduce, copy, modify, distribute, publish, sell, license, reverse engineer, decompile, create derivative works from, or commercially exploit the Application or its proprietary components.

8.3
Users may submit business information, product descriptions, service information, photographs, logos, videos, documents, requirements, and other content through the Application.

8.4
Users retain ownership of intellectual property rights they lawfully own in the content they submit. However, by submitting such content, Users grant 123 App a non-exclusive, royalty-free, limited right to host, store, reproduce, display, format, communicate, and otherwise use the content to the extent reasonably necessary to operate, maintain, provide, improve, secure, and promote the Application and its services.

8.5
The User represents and warrants that they have the necessary ownership, authorization, license, consent, or other legal right to submit and use the content provided through the Application.

8.6
Users must not upload content that infringes the copyright, trademark, patent, trade secret, privacy rights, publicity rights, contractual rights, or other legal rights of any third party.

8.7
If 123 App receives a valid complaint, legal notice, rights-holder request, or other information indicating that User content may violate applicable law or third-party rights, 123 App may review and take appropriate action, including restricting or removing the content where appropriate.

8.8
Nothing in these Terms transfers ownership of a User's intellectual property to 123 App beyond the limited rights necessary to operate and provide the Application.

9. CONTENT MODERATION, ACCOUNT SUSPENSION, DISCLAIMER & LIABILITY

9.1 Content Moderation
123 App reserves the right to review, monitor where appropriate, restrict, hide, modify, disable, or remove User-generated content, profiles, listings, requirements, or other material where reasonably necessary to enforce these Terms, protect Users, maintain security, comply with applicable law, respond to lawful requests, or protect the rights and interests of 123 App or third parties.

9.2 Account Suspension or Termination
123 App may suspend, restrict, disable, or terminate a User's account or access to the Application where the User violates these Terms, provides materially false or misleading information, engages in fraudulent or unlawful conduct, misuses the Application, creates security risks, infringes third-party rights, or uses the Application in a manner that may cause harm to other Users or the Application.

Where reasonably practicable, 123 App may provide notice before taking such action. However, immediate restriction or termination may be necessary where required to protect Users, systems, legal rights, or comply with applicable law.

9.3 Application Availability
The Application may occasionally become unavailable or experience interruptions because of maintenance, software updates, server or hosting issues, internet connectivity problems, third-party service failures, security incidents, technical failures, or circumstances beyond the reasonable control of 123 App.

123 App does not guarantee that the Application will always be uninterrupted, completely error-free, continuously available, or free from technical defects.

9.4 User-Provided Information
123 App may display information submitted by Users. Because such information originates from Users, 123 App cannot guarantee that every listing, profile, requirement, product description, service description, business claim, or other User-generated information is accurate, complete, current, authentic, or reliable.

Users should independently verify important information before relying on it.

9.5 Limitation of Liability
To the maximum extent permitted by applicable law, 123 App, its authorized representatives, employees, officers, affiliates, and service providers shall not be responsible for indirect, incidental, special, consequential, or punitive losses arising from the use of, or inability to use, the Application.

This may include losses or disputes relating to User-generated information, products or services offered by Users, independent transactions, third-party conduct, fraudulent activities by other Users, loss of business opportunities, loss of revenue or profits, loss of data, technical interruptions, or third-party services, subject always to any liability that cannot legally be excluded or limited.

9.6
Users acknowledge that communication and transactions with other Users involve risks and that they are responsible for exercising appropriate judgment and due diligence.

9.7 Indemnification
To the extent permitted by applicable law, a User agrees to indemnify and hold harmless 123 App and its authorized representatives against claims, losses, damages, liabilities, costs, and expenses arising from the User's violation of these Terms, unlawful conduct, submitted content, infringement of third-party rights, or misuse of the Application.

9.8
Nothing in these Terms is intended to exclude or limit any right, remedy, or liability that cannot legally be excluded or limited under applicable law.

10. COMPLAINTS, CHANGES, GOVERNING LAW & CONTACT INFORMATION

10.1 Complaints and Reporting
Users may report suspected fraudulent activity, fake or misleading listings, inappropriate content, impersonation, intellectual property violations, harassment, misuse of the Application, or other violations through the complaint or support mechanism provided by 123 App.

10.2
When submitting a complaint, Users should provide sufficient information to enable 123 App to understand and review the issue. Supporting documents or evidence may be requested where appropriate.

10.3
123 App may review complaints and take action that it considers appropriate based on the circumstances, these Terms, applicable policies, and applicable law. 123 App does not guarantee a particular outcome for every complaint.

10.4 Changes to the Application
123 App may, from time to time, introduce new features, modify existing features, change categories, update functionality, suspend certain services, or discontinue features of the Application.

10.5
Users may be required to install Application updates to maintain access to certain features or services.

10.6
Where appropriate, 123 App may communicate material changes to the Terms or Application through the Application or other available communication channels.

10.7 Severability
If any provision of these Terms is determined by a competent authority or court to be invalid, unlawful, or unenforceable, that provision shall be interpreted or modified to the extent legally permissible, and the remaining provisions shall continue to remain in full force and effect.

10.8 Governing Law
These Terms shall be governed by and interpreted in accordance with the applicable laws of India.

10.9 Jurisdiction
Subject to applicable law, disputes arising from or relating to these Terms or the use of 123 App shall be subject to the jurisdiction of the competent courts at [Bengaluru, Karnataka, India], unless applicable law requires otherwise.

10.10 Contact Information
For questions, technical support, complaints, grievances, legal notices, or other matters concerning the Application or these Terms, Users may contact:

Application Name: 123 App
Official Email: [Insert Official Email Address]
Contact Number: [Insert Official Contact Number]
Office / Registered Address: [Insert Official Address]

10.11 User Acknowledgement
By clicking "I Agree", "Accept", registering an account, logging into the Application, accessing its features, or continuing to use 123 App, the User confirms that they:

1. Have read and understood these Terms & Conditions.
2. Agree to comply with these Terms and applicable laws.
3. Confirm that the information provided by them is accurate to the best of their knowledge.
4. Understand that information they voluntarily publish may be made available to other Users depending on the functionality of the Application.
5. Understand that interactions and transactions with other Users may involve independent risks.
6. Agree to use the Application responsibly, lawfully, and respectfully.
7. Agree to be bound by these Terms & Conditions and other applicable policies of 123 App.

By continuing to use 123 App, you acknowledge that you have read, understood, and accepted these Terms & Conditions.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _termsText,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}