import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  /// Creates the Auth user AND upserts a Firestore profile at users/{uid}
  Future<void> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'email': cred.user!.email,
        'displayName': cred.user!.displayName ?? '',
        'photoURL': cred.user!.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  Future<void> reset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Exception _map(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return Exception('Invalid email.');
      case 'user-not-found':
      case 'wrong-password': return Exception('Incorrect email or password.');
      case 'email-already-in-use': return Exception('Email already in use.');
      case 'weak-password': return Exception('Weak password (min 6 chars).');
      case 'too-many-requests': return Exception('Too many attempts. Try later.');
      default: return Exception(e.message ?? 'Authentication error');
    }
  }
}
