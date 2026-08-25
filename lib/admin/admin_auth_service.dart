import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Firebase Authentication
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return 'Firebase did not return a user.';
      }

      print('ADMIN AUTH SUCCESS');
      print('UID: ${user.uid}');
      print('EMAIL: ${user.email}');

      // Step 2: Check admins/{UID}
      final DocumentSnapshot<Map<String, dynamic>> adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      print('ADMIN DOCUMENT EXISTS: ${adminDoc.exists}');

      if (!adminDoc.exists) {
        await _auth.signOut();

        return 'Admin document not found for UID: ${user.uid}';
      }

      final data = adminDoc.data();

      print('ADMIN DATA: $data');

      if (data == null) {
        await _auth.signOut();
        return 'Admin document is empty.';
      }

      final role = data['role']?.toString();
      final active = data['active'];

      print('ROLE: $role');
      print('ACTIVE: $active');

      if (role != 'admin') {
        await _auth.signOut();

        return 'Invalid admin role. Found role: $role';
      }

      if (active != true) {
        await _auth.signOut();

        return 'Admin account is inactive.';
      }

      print('ADMIN AUTHORIZATION SUCCESS');

      return null;
    } on FirebaseAuthException catch (e) {
      print('FIREBASE AUTH ERROR');
      print('CODE: ${e.code}');
      print('MESSAGE: ${e.message}');

      switch (e.code) {
        case 'invalid-credential':
          return 'Invalid email or password.';

        case 'invalid-email':
          return 'Invalid email address.';

        case 'user-not-found':
          return 'No Firebase Authentication user found with this email.';

        case 'wrong-password':
          return 'Incorrect password.';

        case 'user-disabled':
          return 'This Firebase user account is disabled.';

        case 'too-many-requests':
          return 'Too many login attempts. Try again later.';

        default:
          return 'Firebase Authentication error: ${e.code}';
      }
    } catch (e) {
      print('ADMIN LOGIN ERROR: $e');

      return 'Admin login error: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// The currently signed-in Firebase user, if any.
  /// Used by the dashboard app bar to show the admin's email.
  User? get currentUser => _auth.currentUser;
}