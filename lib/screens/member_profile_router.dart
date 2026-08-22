import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Adjust this import to match the actual filename in your project —
// it's the file that defines `ProfileScreen` and `MemberProfile`
// (the business profile screen you already have).
import 'profile_screen.dart';

import 'non_business_profile_screen.dart';

/// Drop this into the Profile tab of home_page.dart instead of a
/// hardcoded ProfileScreen(). It looks up the member's userType in
/// Firestore and renders the right profile screen for them:
///
///   business               -> ProfileScreen (existing, full business form)
///   non_business / student -> NonBusinessProfileScreen (simple form)
///
/// Usage (inside DashboardPage / home_page.dart):
///   MemberProfileRouter(memberId: widget.memberId)
class MemberProfileRouter extends StatefulWidget {
  /// The Firestore doc id used everywhere else in the app — the cleaned
  /// 10-digit phone number (see LoginPage.getCleanPhoneNumber and
  /// RegisterScreen's `.doc(phone)` calls).
  final String memberId;

  const MemberProfileRouter({super.key, required this.memberId});

  @override
  State<MemberProfileRouter> createState() => _MemberProfileRouterState();
}

class _MemberProfileRouterState extends State<MemberProfileRouter> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _memberFuture;

  @override
  void initState() {
    super.initState();
    _memberFuture = _fetchMember();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchMember() {
    return FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .get();
  }

  void _reload() {
    setState(() {
      _memberFuture = _fetchMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _memberFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load profile: ${snapshot.error}'),
              ),
            ),
          );
        }

        final doc = snapshot.data;

        if (doc == null || !doc.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No profile found for this member.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = doc.data() ?? <String, dynamic>{};
        final userType = (data['userType'] as String?) ?? 'non_business';

        if (userType == 'business') {
          return ProfileScreen(
            profile: _mapToBusinessProfile(widget.memberId, data),
            onSave: _saveBusinessProfile,
          );
        }

        return NonBusinessProfileScreen(
          memberId: widget.memberId,
          initialData: data,
          categoryLabel: userType == 'student' ? 'Student' : 'Non-Business',
          onSaved: _reload,
        );
      },
    );
  }

  /// Maps whatever is stored in Firestore for a business member onto the
  /// existing MemberProfile model used by ProfileScreen.
  ///
  /// Your current RegisterScreen only ever saves name / phone / memberId /
  /// userType for business members — fields like businessName, ownerName,
  /// website, district, industryType, and productServiceDescription aren't
  /// collected anywhere yet. They come through as empty strings below so
  /// the form still renders correctly; wire up a "Business Details" step
  /// (at registration or later) to actually populate them, and this
  /// mapping will pick them up automatically since it reads by key.
  MemberProfile _mapToBusinessProfile(
    String memberId,
    Map<String, dynamic> data,
  ) {
    String s(String key) => (data[key] as String?)?.trim() ?? '';
    final phone = s('phone').isNotEmpty ? s('phone') : memberId;

    return MemberProfile(
      memberName: s('name'),
      membershipNumber: s('memberId'),
      phoneNumber: phone,
      businessName: s('businessName'),
      ownerName: s('ownerName').isNotEmpty ? s('ownerName') : s('name'),
      contactNumber: s('contactNumber').isNotEmpty ? s('contactNumber') : phone,
      email: s('email'),
      website: s('website'),
      address: s('address'),
      district: s('district'),
      pincode: s('pincode'),
      industryType: s('industryType'),
      productServiceDescription: s('productServiceDescription'),
      companyProfilePdfPath: data['companyProfilePdfPath'] as String?,
      visitingCardImagePath: data['visitingCardImagePath'] as String?,
    );
  }

  Future<void> _saveBusinessProfile(MemberProfile updated) async {
    await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .set({
      'name': updated.memberName,
      'memberId': updated.membershipNumber,
      'phone': updated.phoneNumber,
      'businessName': updated.businessName,
      'ownerName': updated.ownerName,
      'contactNumber': updated.contactNumber,
      'email': updated.email,
      'website': updated.website,
      'address': updated.address,
      'district': updated.district,
      'pincode': updated.pincode,
      'industryType': updated.industryType,
      'productServiceDescription': updated.productServiceDescription,
      if (updated.companyProfilePdfPath != null)
        'companyProfilePdfPath': updated.companyProfilePdfPath,
      if (updated.visitingCardImagePath != null)
        'visitingCardImagePath': updated.visitingCardImagePath,
    }, SetOptions(merge: true));
  }
}
