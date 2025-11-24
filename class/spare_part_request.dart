import 'package:cloud_firestore/cloud_firestore.dart';

class SparePart {
  final String partName;
  final int quantity;
  final String notes;

  SparePart({
    required this.partName,
    required this.quantity,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'partName': partName,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      partName: map['partName'] ?? '',
      quantity: map['quantity'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }
}

class SparePartRequest {
  final String requestId;
  final String userId;
  final List<SparePart> parts;
  final DateTime date;
  final String status;
  final String? notes;

  SparePartRequest({
    required this.requestId,
    required this.userId,
    required this.parts,
    required this.date,
    required this.status,
    this.notes,
  });

  String get displayRequestId {
    final dateStr = date.toIso8601String().substring(0, 10).replaceAll('-', '');
    final timeStr = date.toIso8601String().substring(11, 19).replaceAll(':', '');
    return 'REQ-$dateStr-$timeStr';
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'userId': userId,
      'parts': parts.map((part) => part.toMap()).toList(),
      'date': Timestamp.fromDate(date),
      'status': status,
      'notes': notes,
    };
  }

  factory SparePartRequest.fromMap(Map<String, dynamic> map, String docId) {
    return SparePartRequest(
      requestId: docId,
      userId: map['userId'] ?? '',
      parts: (map['parts'] as List<dynamic>?)
          ?.map((part) => SparePart.fromMap(part))
          .toList() ?? [],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'Pending',
      notes: map['notes'],
    );
  }

  SparePartRequest copyWith({
    String? requestId,
    String? userId,
    List<SparePart>? parts,
    DateTime? date,
    String? status,
    String? notes,
  }) {
    return SparePartRequest(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      parts: parts ?? this.parts,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
