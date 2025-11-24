// lib/services/spare_part_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../class/spare_part_request.dart';

class SparePartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all spare part requests for current user
  static Stream<List<SparePartRequest>> getUserSparePartRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => SparePartRequest.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by date in descending order (newest first)
      requests.sort((a, b) => b.date.compareTo(a.date));
      return requests;
    });
  }

  // Get spare part requests by status
  static Stream<List<SparePartRequest>> getSparePartRequestsByStatus(String status) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => SparePartRequest.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by date in descending order (newest first)
      requests.sort((a, b) => b.date.compareTo(a.date));
      return requests;
    });
  }

  // Create new spare part request
  static Future<String> createSparePartRequest(List<SparePart> parts, {String? notes}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('requests').doc();
    final request = SparePartRequest(
      requestId: docRef.id,
      userId: user.uid,
      parts: parts,
      date: DateTime.now(),
      status: 'Pending',
      notes: notes,
    );

    await docRef.set(request.toMap());
    return docRef.id;
  }

  // Update spare part request status
  static Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status,
    });
  }

  // Cancel spare part request
  static Future<void> cancelRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Cancelled',
    });
  }

  // Get spare part request by ID
  static Future<SparePartRequest?> getSparePartRequestById(String requestId) async {
    final doc = await _firestore.collection('requests').doc(requestId).get();
    if (doc.exists) {
      return SparePartRequest.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
