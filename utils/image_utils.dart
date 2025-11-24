// lib/utils/image_utils.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUtils {
  static ImageProvider? getProfileImage(User? user) {
    if (user?.photoURL == null || user!.photoURL!.isEmpty) {
      return null;
    }
    
    final photoURL = user.photoURL!;
    
    // Check if it's a base64 data URL
    if (photoURL.startsWith('data:image/')) {
      try {
        // Extract base64 string from data URL
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }
    
    // If it's a regular URL, use NetworkImage
    return NetworkImage(photoURL);
  }
}
