import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatisticsService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // TOTAL MEMBERS
  // ----------------------------------------------------------

  Future<int> getTotalMembers() async {
    final snapshot = await _firestore
        .collection('members')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // BUSINESS MEMBERS
  // ----------------------------------------------------------

  Future<int> getBusinessMembers() async {
    final snapshot = await _firestore
        .collection('members')
        .where('userType', isEqualTo: 'business')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // NON-BUSINESS MEMBERS
  // ----------------------------------------------------------

  Future<int> getNonBusinessMembers() async {
    final snapshot = await _firestore
        .collection('members')
        .where('userType', isEqualTo: 'non_business')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // STUDENTS
  // ----------------------------------------------------------

  Future<int> getStudents() async {
    final snapshot = await _firestore
        .collection('members')
        .where('userType', isEqualTo: 'student')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // TOTAL BUSINESSES
  // ----------------------------------------------------------

  Future<int> getTotalBusinesses() async {
    final snapshot = await _firestore
        .collection('businesses')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // PENDING BUSINESSES
  // ----------------------------------------------------------

  Future<int> getPendingBusinesses() async {
    final snapshot = await _firestore
        .collection('businesses')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // TOTAL ENQUIRIES
  // ----------------------------------------------------------

  Future<int> getTotalEnquiries() async {
    final snapshot = await _firestore
        .collection('enquiries')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // TOTAL INTERESTS
  // ----------------------------------------------------------

  Future<int> getTotalInterests() async {
    final snapshot = await _firestore
        .collection('interests')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ----------------------------------------------------------
  // TODAY'S REGISTRATIONS
  // ----------------------------------------------------------

  Future<int> getTodayRegistrations() async {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    final snapshot = await _firestore
        .collection('members')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(startOfDay),
        )
        .where(
          'createdAt',
          isLessThan:
              Timestamp.fromDate(endOfDay),
        )
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}