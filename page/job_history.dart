// lib/page/job_history.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// your models/pages
import 'package:assignment29/class/job.dart';
import '../tracker/signature_capture_page.dart';

class JobHistoryPage extends StatefulWidget {
  const JobHistoryPage({super.key});

  @override
  State<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends State<JobHistoryPage> {
  // ---------- helpers ----------
  String _shortId(String id, {int max = 8}) {
    if (id.isEmpty) return 'Unknown';
    final end = id.length < max ? id.length : max;
    final core = id.substring(0, end);
    return id.length > max ? '$core...' : core;
  }

  String _fmtDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  bool _isFinished(Map<String, dynamic> data) {
    final s = (data['status'] ?? '').toString().toLowerCase().trim();
    return s == 'finished' || s == 'finish' || s == 'completed' || s == 'complete';
  }

  Uint8List? _decodeSignature(Map<String, dynamic> d) {
    final raw = (d['signatureBase64'] ?? d['signature'] ?? '').toString().trim();
    if (raw.isEmpty) return null;
    try {
      final pure = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(pure);
    } catch (_) {
      return null;
    }
  }

  Job _jobFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Job(
      jobId: ((d['jobId'] ?? doc.id) as Object).toString(),
      category: (d['category'] ?? '').toString(),
      vehicle: (d['vehicle'] ?? '').toString(),
      assignedMechanic: (d['assignedMechanic'] ?? d['assignToName'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      notifyEmail: (d['notifyEmail'] ?? d['customerEmail'] ?? '').toString(),
      signatureBytes: _decodeSignature(d),
      customerId: (d['customerId'] ?? '').toString(),
      customerName: (d['customerName'] ?? '').toString(),
      customerPhone: (d['customerPhone'] ?? '').toString(),
      jobDescription: (d['jobDescription'] ?? '').toString(),
      serviceHistory: List<String>.from((d['serviceHistory'] ?? []) as List? ?? const []),
      createdAt: (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : null,
    );
  }
  // ---------- /helpers ----------
  Query<Map<String, dynamic>> _query() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final col = FirebaseFirestore.instance.collection('jobs');

    // If not signed in, return an empty result safely.
    if (uid == null) {
      return col.where('assignedMechanic', isEqualTo: '__no_user__').limit(1);
    }

    // Only this mechanic’s jobs
    return col.where('assignedMechanic', isEqualTo: uid).limit(500);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Job History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Defensive: if not signed in, show nothing
          if (uid == null) {
            return const Center(child: Text('Please sign in to view your job history.'));
          }

          // Filter to this user's finished jobs (robust on casing)
          final all = snapshot.data?.docs ?? [];
          final finishDocs = all.where((d) {
            final data = d.data();
            final assigned = (data['assignedMechanic'] ?? '').toString();
            return assigned == uid && _isFinished(data);
          }).toList();

          // Sort by createdAt desc on the client (index-free)
          finishDocs.sort((a, b) {
            final ta = (a.data()['createdAt'] is Timestamp)
                ? (a.data()['createdAt'] as Timestamp).millisecondsSinceEpoch
                : -1;
            final tb = (b.data()['createdAt'] is Timestamp)
                ? (b.data()['createdAt'] as Timestamp).millisecondsSinceEpoch
                : -1;
            return tb.compareTo(ta);
          });

          if (finishDocs.isEmpty) {
            return const Center(child: Text('No finished jobs found.'));
          }

          return ListView.builder(
            itemCount: finishDocs.length,
            itemBuilder: (context, i) {
              final doc = finishDocs[i];
              final data = doc.data();

              final jobId = ((data['jobId'] ?? doc.id) as Object).toString();
              final vehicle = (data['vehicle'] ?? '').toString();
              final desc = (data['jobDescription'] ?? '').toString();
              final createdAt = data['createdAt'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    final job = _jobFromDoc(doc);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignatureCapturePage(
                          job: job,
                          readOnly: true,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vehicle.isEmpty ? 'Job ${_shortId(jobId)}' : vehicle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text('Finished',
                                  style: TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (desc.isNotEmpty)
                          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.tag, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Job ID: ${_shortId(jobId)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const Spacer(),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(_fmtDate(createdAt),
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
