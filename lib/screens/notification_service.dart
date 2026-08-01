import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Notification Service
  /// (No FCM used)
  static Future<void> initialize(String memberId) async {
    // Nothing to initialize.
  }

  /// Send Notification
  static Future<void> sendNotification({
    required String title,
    required String message,
    required String targetType,
    String industry = "",
    String district = "",
    String memberId = "",
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'targetType': targetType,
      'industry': industry,
      'district': district,
      'memberId': memberId,
      'createdBy': 'Admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get All Notifications
  static Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Notifications for All Members
  static Stream<QuerySnapshot<Map<String, dynamic>>>
  getAllMemberNotifications() {
    return _firestore
        .collection('notifications')
        .where('targetType', isEqualTo: 'All Members')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Notifications by Industry
  static Stream<QuerySnapshot<Map<String, dynamic>>> getIndustryNotifications(
    String industry,
  ) {
    return _firestore
        .collection('notifications')
        .where('targetType', isEqualTo: 'Industry')
        .where('industry', isEqualTo: industry)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Notifications by District
  static Stream<QuerySnapshot<Map<String, dynamic>>> getDistrictNotifications(
    String district,
  ) {
    return _firestore
        .collection('notifications')
        .where('targetType', isEqualTo: 'District')
        .where('district', isEqualTo: district)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Notifications for Individual Member
  static Stream<QuerySnapshot<Map<String, dynamic>>> getIndividualNotifications(
    String memberId,
  ) {
    return _firestore
        .collection('notifications')
        .where('targetType', isEqualTo: 'Individual Member')
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Delete Notification (Admin)
  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
