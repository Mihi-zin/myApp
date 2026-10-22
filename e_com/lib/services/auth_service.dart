import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up (Email, Password, Role)
  // Sign Up Method
  Future<User?> signUp({
    required String email,
    required String password,
    required String role,
    required String name, // Can be full name or company name
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Save user details in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'role': role, // 'intern' or 'company'
          'name': name, // Holds username for intern, company name for company
          'createdAt': Timestamp.now(),
        });
      }

      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Get User Role from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') ?? 'intern';
      }
      return 'intern';
    } catch (e) {
      return 'intern';
    }
  }

  // 4. Reset Password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 5. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}