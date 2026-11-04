import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'non_business_profile_screen.dart';

/// Routes a member to the profile UI for their Firestore userType.
/// memberId is the Firestore document ID (cleaned phone number), not
/// necessarily the human-readable membership number.
class MemberProfileRouter extends StatefulWidget {
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

  @override
  void didUpdateWidget(covariant MemberProfileRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) {
      _memberFuture = _fetchMember();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchMember() =>
      FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .get();

  void _reload() {
    if (mounted) setState(() => _memberFuture = _fetchMember());
  }

  String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value == null ? '' : value.toString().trim();
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
          );
        }

        final data = doc.data() ?? <String, dynamic>{};
        final type = _string(data, 'userType').toLowerCase();

        if (type == 'business') {
          return ProfileScreen(
            key: ValueKey('business-${widget.memberId}'),
            profile: _businessProfile(widget.memberId, data),
            onSave: _saveBusinessProfile,
          );
        }

        return NonBusinessProfileScreen(
          key: ValueKey('$type-${widget.memberId}'),
          memberId: widget.memberId,
          initialData: data,
          categoryLabel: type == 'student' ? 'Student' : 'Non-Business',
          onSaved: _reload,
        );
      },
    );
  }

  MemberProfile _businessProfile(
    String documentId,
    Map<String, dynamic> data,
  ) {
    String s(String key) => _string(data, key);
    final phone = s('phone').isNotEmpty ? s('phone') : documentId;
    final membership = s('membershipNumber').isNotEmpty
        ? s('membershipNumber')
        : s('memberId');

    return MemberProfile(
      memberName: s('name'),
      membershipNumber: membership,
      phoneNumber: phone,
      businessName: s('businessName'),
      ownerName: s('ownerName').isNotEmpty ? s('ownerName') : s('name'),
      contactNumber:
          s('contactNumber').isNotEmpty ? s('contactNumber') : phone,
      email: s('email'),
      website: s('website'),
      address: s('address'),
      district: s('district'),
      pincode: s('pincode'),
      industryType: s('industryType'),
      productServiceDescription: s('productServiceDescription'),
      companyProfilePdfPath: s('companyProfilePdfPath').isNotEmpty
          ? s('companyProfilePdfPath')
          : null,
      visitingCardImagePath: s('visitingCardImagePath').isNotEmpty
          ? s('visitingCardImagePath')
          : null,
    );
  }

  Future<String?> _uploadLocalFile({
    required String? path,
    required String storagePath,
    required String contentType,
  }) async {
    if (path == null || path.trim().isEmpty) return path;
    final value = path.trim();

    // Existing Storage download URL: don't upload it again.
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }

    final file = File(value);
    if (!await file.exists()) {
      throw Exception(
        'Selected file is no longer available. Please select it again.',
      );
    }

    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> _saveBusinessProfile(MemberProfile updated) async {
    final pdfUrl = await _uploadLocalFile(
      path: updated.companyProfilePdfPath,
      storagePath: 'members/${widget.memberId}/profile/company_profile.pdf',
      contentType: 'application/pdf',
    );

    final cardUrl = await _uploadLocalFile(
      path: updated.visitingCardImagePath,
      storagePath: 'members/${widget.memberId}/profile/visiting_card',
      contentType: 'image/jpeg',
    );

    // Do not change document ID, registered phone, or membership number.
    // merge:true preserves all other fields already stored on this member.
    await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .set({
      'name': updated.memberName,
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
      if (pdfUrl != null && pdfUrl.isNotEmpty)
        'companyProfilePdfPath': pdfUrl,
      if (cardUrl != null && cardUrl.isNotEmpty)
        'visitingCardImagePath': cardUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // The screen now holds permanent URLs instead of temporary device paths.
    updated.companyProfilePdfPath = pdfUrl;
    updated.visitingCardImagePath = cardUrl;
  }
}