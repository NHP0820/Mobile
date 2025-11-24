// lib/services/job_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../class/job.dart';

abstract class IJobRepository {
  Future<void> saveSignatureAndMarkFinished({
    required String jobId,
    required Uint8List signaturePngBytes,
  });

  Future<void> sendCompletedEmail({
    required String jobId,
    required String toEmail,
  });

  Future<Job?> getById(String jobId);

  Stream<List<Job>> streamCompletedUnsigned();
  Stream<List<Job>> streamFinished();
}

class JobRepository implements IJobRepository {
  final FirebaseFirestore _db;
  final String collectionPath;

  JobRepository({
    FirebaseFirestore? firestore,
    this.collectionPath = 'jobs',
  }) : _db = firestore ?? FirebaseFirestore.instance;



  CollectionReference<Map<String, dynamic>> get _jobs =>
      _db.collection(collectionPath);

  @override
  Future<void> saveSignatureAndMarkFinished({
    required String jobId,
    required Uint8List signaturePngBytes,
  }) async {
    final base64Sig = base64Encode(signaturePngBytes);

    await _jobs.doc(jobId).update({
      'signature': base64Sig,
      'status': 'Finished',
      'finishedAt': FieldValue.serverTimestamp(),
    });
  }
  @override
  Future<void> sendCompletedEmail({
    required String jobId,
    required String toEmail,
  }) async {
    final email = _sanitizeEmail(toEmail);
    if (email.isEmpty || !_isValidEmail(email)) {
      throw ArgumentError('Invalid email: [$email]');
    }

    // read job
    final snap = await _jobs.doc(jobId).get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Job not found: $jobId');
    }
    final job = Job.fromDoc(snap);

    // persist email
    await _jobs.doc(jobId).update({
      'notifyEmail': email,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // send email
    await _sendEmail(
      toEmail: email,
      subject: '[Greenstem] Job ${job.jobId} Completed',
      body:
      'Hello,\n\nYour vehicle ${job.vehicle} (Job ${job.jobId}) has been completed.\nPlease visit our workshop to sign and collect your car.\n\nThank you,\nGreenstem Workshop',
    );
  }

  @override
  Future<Job?> getById(String jobId) async {
    final snap = await _jobs.doc(jobId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Job.fromDoc(snap);
  }

  @override
  Stream<List<Job>> streamCompletedUnsigned() {
    return _jobs
        .where('status', whereIn: ['Completed', 'completed'])
        .snapshots()
        .map((qs) {
      final list = qs.docs.map((d) => Job.fromDoc(d)).where((j) {
        return j.signatureBytes == null || j.signatureBytes!.isEmpty;
      }).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      return list;
    });
  }

  @override
  Stream<List<Job>> streamFinished() {
    return _jobs
        .where('status', whereIn: ['Finished', 'finished'])
        .snapshots()
        .map((qs) {
      final list = qs.docs.map((d) => Job.fromDoc(d)).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      return list;
    });
  }

  /// Mailgun
  Future<void> _sendEmail({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    const mailgunApiKey = '5f5fe6ddef8e24cbdc496b81d4ece139-fbceb7cb-b8ba9585';
    const mailgunDomain = 'sandbox31a97746422c45e7830fcd149d2e2256.mailgun.org';

    final url = Uri.parse('https://api.mailgun.net/v3/$mailgunDomain/messages');
    final basic = base64Encode(utf8.encode('api:$mailgunApiKey'));

    final client = http.Client();
    try {
      print('Mailgun POST to [$toEmail] using domain [$mailgunDomain]');

      final resp = await client
          .post(
        url,
        headers: {
          'Authorization': 'Basic $basic',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'from': 'Greenstem <no-reply@$mailgunDomain>',
          'to': toEmail,
          'subject': subject,
          'text': body,
        },
      )
          .timeout(const Duration(seconds: 20)); // <-- hard timeout

      print('Mailgun response: ${resp.statusCode} - ${resp.body}');
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw StateError('Mailgun failed: ${resp.statusCode} - ${resp.body}');
      }
    } on TimeoutException {
      throw StateError('Mailgun request timed out after 20s.');
    } on SocketException catch (e) {
      throw StateError('Network error (SocketException): $e');
    } on HandshakeException catch (e) {
      throw StateError('TLS handshake error: $e');
    } on http.ClientException catch (e) {
      throw StateError('HTTP client error: $e');
    } finally {
      client.close();
    }
  }

}

bool _isValidEmail(String email) {
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return re.hasMatch(email);
}

String _sanitizeEmail(String raw) {
  var s = raw.trim();
  s = s.replaceAll('\r', '').replaceAll('\n', '').replaceAll('\t', '');
  // If user pasted "Name <addr@example.com>"
  final m = RegExp(r'<\s*([^>]+)\s*>').firstMatch(s);
  if (m != null) s = m.group(1)!.trim();
  // Remove trailing commas/semicolons
  s = s.replaceAll(RegExp(r'[;,]+$'), '');
  return s;
}
