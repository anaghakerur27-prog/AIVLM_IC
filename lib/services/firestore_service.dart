import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerMember(MemberModel member) async {
    await _firestore.collection('members').doc(member.phone).set({
      ...member.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getMember(String phone) async {
    return await _firestore.collection('members').doc(phone).get();
  }
}
