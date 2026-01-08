import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  // Future<User?> signUpWithEmailPassword(
  //   String email,
  //   String password,
  //   String name,
  // ) async {
  //   try {
  //     UserCredential result = await _auth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     User? user = result.user;
  //     if (user != null) {
  //       await user.updateDisplayName(name);
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('userId', user.uid);
  //       // Save user data to Firestore, similar to sync_service
  //       await _firestore.collection('users').doc(user.uid).set({
  //         'uid': user.uid,
  //         'email': email,
  //         'name': name,
  //         'createdAt': FieldValue.serverTimestamp(),
  //       }, SetOptions(merge: true));
  //     }
  //     return user;
  //   } catch (e) {
  //     print('Sign up error: $e');
  //     return null;
  //   }
  // }

  static const String defaultEmail = 'khoerunnisautami22@gmail.com';
  static const String defaultPassword = 'admin123';

    // Sign in with default credentials
  Future<User?> signInDefault() async {
    return signInWithEmailPassword(defaultEmail, defaultPassword);
  }

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> seedDefaultUser() async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: defaultEmail,
        password: defaultPassword,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName("Admin");
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': defaultEmail,
          'name': "Admin",
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Seed user error (maybe already exists): $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

    // Get user ID from local storage
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}



