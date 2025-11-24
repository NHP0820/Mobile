// lib/class/job.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String jobId;
  final String customerId;

  final String? customerName;
  final String? customerPhone;   

  final String assignedMechanic;
  final String category;
  final String jobDescription;
  final String status;
  final String vehicle;
  final List<String> serviceHistory;
  final DateTime? createdAt;
  final Uint8List? signatureBytes;
  final String? notifyEmail;

  const Job({
    required this.jobId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.assignedMechanic,
    required this.category,
    required this.jobDescription,
    required this.status,
    required this.vehicle,
    required this.serviceHistory,
    this.createdAt,
    this.signatureBytes,
    this.notifyEmail,
  });

  // convenience getters
  String get statusLower => status.toLowerCase();
  bool get isCompletedUnsigned =>
      statusLower == 'completed' && (signatureBytes == null || signatureBytes!.isEmpty);
  bool get isFinished => statusLower == 'finished';
  bool get isEmailEmpty => (notifyEmail == null || notifyEmail!.trim().isEmpty);
  String get emailLabel => isEmailEmpty ? 'none' : notifyEmail!.trim();

  /// Create from Firestore document
  factory Job.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    // signature: base64 or null
    Uint8List? sig;
    final sigRaw = d['signature'];
    if (sigRaw is String && sigRaw.isNotEmpty) {
      try {
        sig = base64Decode(sigRaw);
      } catch (_) {
        sig = null;
      }
    }

    return Job(
      jobId: (d['jobId'] ?? doc.id) as String,
      customerId: (d['customerId'] ?? '') as String,

      customerName: (d['customerName'] as String?)?.trim(),
      customerPhone: (d['customerPhone'] as String?)?.trim(),

      assignedMechanic: (d['assignedMechanic'] ?? '') as String,
      category: (d['category'] ?? '') as String,
      jobDescription: (d['jobDescription'] ?? '') as String,
      status: (d['status'] ?? '') as String,
      vehicle: (d['vehicle'] ?? '') as String,
      serviceHistory: (d['serviceHistory'] as List?)?.cast<String>() ?? const [],
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
      signatureBytes: sig,
      notifyEmail: (d['notifyEmail'] as String?)?.trim(),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    Uint8List? sig;
    final sigRaw = json['signature'];
    if (sigRaw is String && sigRaw.isNotEmpty) {
      try {
        sig = base64Decode(sigRaw);
      } catch (_) {
        sig = null;
      }
    }

    return Job(
      jobId: (json['jobId'] ?? '') as String,
      customerId: (json['customerId'] ?? '') as String,

      // NEW
      customerName: (json['customerName'] as String?)?.trim(),
      customerPhone: (json['customerPhone'] as String?)?.trim(),

      assignedMechanic: (json['assignedMechanic'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      jobDescription: (json['jobDescription'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      vehicle: (json['vehicle'] ?? '') as String,
      serviceHistory: (json['serviceHistory'] as List?)?.cast<String>() ?? const [],
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String && (json['createdAt'] as String).isNotEmpty)
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      signatureBytes: sig,
      notifyEmail: (json['notifyEmail'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'customerId': customerId,

      'customerName': customerName?.trim(),
      'customerPhone': customerPhone?.trim(),

      'assignedMechanic': assignedMechanic,
      'category': category,
      'jobDescription': jobDescription,
      'status': status,
      'vehicle': vehicle,
      'serviceHistory': serviceHistory,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'notifyEmail': notifyEmail?.trim(),
    };
  }

  Map<String, dynamic> toJsonWithoutNulls() {
    final m = <String, dynamic>{
      'jobId': jobId,
      'customerId': customerId,
      'assignedMechanic': assignedMechanic,
      'category': category,
      'jobDescription': jobDescription,
      'status': status,
      'vehicle': vehicle,
      'serviceHistory': serviceHistory,
    };

    // NEW
    if (customerName != null && customerName!.trim().isNotEmpty) {
      m['customerName'] = customerName!.trim();
    }
    if (customerPhone != null && customerPhone!.trim().isNotEmpty) {
      m['customerPhone'] = customerPhone!.trim();
    }

    if (createdAt != null) m['createdAt'] = Timestamp.fromDate(createdAt!);
    if (notifyEmail != null && notifyEmail!.trim().isNotEmpty) {
      m['notifyEmail'] = notifyEmail!.trim();
    }
    return m;
  }

  Job copyWith({
    String? jobId,
    String? customerId,
    String? customerName,   
    String? customerPhone, 
    String? assignedMechanic,
    String? category,
    String? jobDescription,
    String? status,
    String? vehicle,
    List<String>? serviceHistory,
    DateTime? createdAt,
    Uint8List? signatureBytes,
    String? notifyEmail,
  }) {
    return Job(
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      assignedMechanic: assignedMechanic ?? this.assignedMechanic,
      category: category ?? this.category,
      jobDescription: jobDescription ?? this.jobDescription,
      status: status ?? this.status,
      vehicle: vehicle ?? this.vehicle,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      createdAt: createdAt ?? this.createdAt,
      signatureBytes: signatureBytes ?? this.signatureBytes,
      notifyEmail: notifyEmail ?? this.notifyEmail,
    );
  }
}
