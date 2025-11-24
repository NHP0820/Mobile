// lib/services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update user profile photo as base64
  static Future<void> updateProfilePhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Read the image file and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Create data URL format: data:image/jpeg;base64,<base64_string>
      final dataUrl = 'data:image/jpeg;base64,$base64String';

      // Update Firestore with base64 data
      await _firestore.collection('users').doc(user.uid).set({
        'photoURL': dataUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      throw Exception('Failed to update profile photo: $e');
    }
  }

  // Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile data
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('users').doc(user.uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
