import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_model.dart';
import '../data/approved_member_ids.dart';

enum MemberValidationStatus {
  success,
  invalidMemberId,
  notRegistered,
  phoneMismatch,
  inactive,
  duplicateRecords,
}

class MemberValidationResult {
  final MemberValidationStatus status;

  /// Firestore document ID of the matched member (the registered phone
  /// number in your structure). Needed by the login screen to open
  /// DashboardPage(memberId: ...). Only set when [status] is success.
  final String? documentId;

  /// Full member document data. Only set when [status] is success.
  final Map<String, dynamic>? memberData;

  MemberValidationResult({
    required this.status,
    this.documentId,
    this.memberData,
  });

  bool get isValid => status == MemberValidationStatus.success;

  /// Member's name, if present on the document.
  String? get memberName => memberData?['name']?.toString();
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing registration method - preserved.
  // New members are saved as active by default; if member.toMap() already
  // contains an 'active' value, that value wins.
  Future<void> registerMember(MemberModel member) async {
    await _firestore.collection('members').doc(member.phone).set({
      'active': true,
      ...member.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Existing phone-based lookup - preserved.
  Future<DocumentSnapshot<Map<String, dynamic>>> getMember(String phone) async {
    return await _firestore.collection('members').doc(phone).get();
  }

  // Normalize Indian phone numbers for comparison.
  String normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  // Validate Member ID, registered phone and account status.
  // Does NOT send an OTP - call this first, send the OTP only on success.
  Future<MemberValidationResult> validateMemberForLogin({
    required String memberId,
    required String phone,
  }) async {
    final id = memberId.trim();
    final enteredPhone = normalizePhone(phone);

    // 1. Check approved Member ID list.
    if (!ApprovedMemberIds.isApproved(id)) {
      return MemberValidationResult(
        status: MemberValidationStatus.invalidMemberId,
      );
    }

    // 2. Validate phone number format.
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(enteredPhone)) {
      return MemberValidationResult(
        status: MemberValidationStatus.phoneMismatch,
      );
    }

    // 3. Find member using membershipNumber.
    final query = await _firestore
        .collection('members')
        .where('membershipNumber', isEqualTo: id)
        .limit(2)
        .get();

    if (query.docs.isEmpty) {
      return MemberValidationResult(
        status: MemberValidationStatus.notRegistered,
      );
    }

    // 4. Reject duplicate membership records.
    if (query.docs.length > 1) {
      return MemberValidationResult(
        status: MemberValidationStatus.duplicateRecords,
      );
    }

    final memberDoc = query.docs.first;
    final memberData = memberDoc.data();

    // 5. Verify registered phone number.
    final registeredPhone =
        normalizePhone(memberData['phone']?.toString() ?? '');

    if (registeredPhone != enteredPhone) {
      return MemberValidationResult(
        status: MemberValidationStatus.phoneMismatch,
      );
    }

    // 6. Verify active account.
    // Missing or non-true active values are rejected.
    if (memberData['active'] != true) {
      return MemberValidationResult(
        status: MemberValidationStatus.inactive,
      );
    }

    // 7. All checks passed.
    return MemberValidationResult(
      status: MemberValidationStatus.success,
      documentId: memberDoc.id,
      memberData: memberData,
    );
  }
}