// lib/page/job_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- add this
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../class/job.dart';
import '../tracker/job_tracker_page.dart';
import '../tracker/customerVehicle.dart';

class JobDetail extends StatefulWidget {
  final Job job;
  final String docPath; // exact Firestore path

  const JobDetail({super.key, required this.job, required this.docPath});

  @override
  State<JobDetail> createState() => _JobDetailState();
}

class _JobDetailState extends State<JobDetail> {
  late final DocumentReference<Map<String, dynamic>> _ref =
  FirebaseFirestore.instance.doc(widget.docPath);

  // local fallback before first snapshot arrives
  late String jobStatus =
  widget.job.status.isNotEmpty ? widget.job.status : 'pending';

  Stream<String> _statusStream() => _ref.snapshots().map(
        (s) => ((s.data()?['status'] as String?) ?? jobStatus)
        .toLowerCase()
        .trim(),
  );

  Future<void> _updateStatus(String newStatus) async {
    await _ref.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => jobStatus = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $newStatus')),
    );
  }

  Future<void> _acceptAndGo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    try {
      // Write status + assign the current user
      await _ref.update({
        'status': 'accepted',
        'assignedMechanic': user.uid,
        'assignedMechanicName': user.displayName ?? user.email ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => jobStatus = 'accepted');

      // Build a Job instance reflecting the assignment
      final acceptedJob = Job(
        jobId: widget.job.jobId,
        customerId: widget.job.customerId,
        customerName: widget.job.customerName,
        customerPhone: widget.job.customerPhone,
        assignedMechanic: user.uid,
        category: widget.job.category,
        jobDescription: widget.job.jobDescription,
        status: 'accepted',
        vehicle: widget.job.vehicle,
        serviceHistory: List<String>.from(widget.job.serviceHistory),
        createdAt: widget.job.createdAt,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerVehicle(job: acceptedJob)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    }
  }

  Future<void> _startJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    // Ensure we have an assignee when moving to in-progress
    await _ref.update({
      'status': 'in progress',
      if ((widget.job.assignedMechanic).isEmpty) 'assignedMechanic': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => jobStatus = 'in progress');

    final startedJob = Job(
      jobId: widget.job.jobId,
      customerId: widget.job.customerId,
      customerName: widget.job.customerName,
      customerPhone: widget.job.customerPhone,
      assignedMechanic: widget.job.assignedMechanic.isEmpty
          ? user.uid
          : widget.job.assignedMechanic,
      category: widget.job.category,
      jobDescription: widget.job.jobDescription,
      status: 'in progress',
      vehicle: widget.job.vehicle,
      serviceHistory: List<String>.from(widget.job.serviceHistory),
      createdAt: widget.job.createdAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerVehicle(job: startedJob)),
    );
  }

  Future<void> _declineWithReason() async {
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline job'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Reason (required)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Submit')),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason.')),
      );
      return;
    }

    try {
      await _ref.update({
        'status': 'cancelled',
        'declineReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => jobStatus = 'cancelled');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job declined.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
    }
  }

  Future<void> _goToTracker() async {
    try {
      final snap = await _ref.get();
      final data = snap.data() ?? <String, dynamic>{};
      data['jobId'] ??= widget.job.jobId;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobTrackerPage(jobDetails: data)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Open tracker failed: $e')));
    }
  }

  String _fmt(DateTime? dt) =>
      dt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(dt);

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: Text('Job Id: ${job.jobId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<String>(
                  stream: _statusStream(),
                  builder: (context, ss) {
                    final liveStatus = (ss.data ?? jobStatus).toLowerCase();
                    final tint = _statusColor(liveStatus);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: tint.withOpacity(.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            liveStatus,
                            style: TextStyle(color: tint, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _kv('Customer ID', job.customerId),
                        _kv('Customer Name', (job.customerName ?? '').trim()),
                        _kv('Customer Phone', (job.customerPhone ?? '').trim()),
                        _kv('Assigned Mechanic', job.assignedMechanic),
                        _kv('Vehicle', job.vehicle),
                        _kv('Category', job.category),
                        _kv('Job Description', job.jobDescription),
                        _kv('Created At', _fmt(job.createdAt)),

                        if (liveStatus == 'cancelled') _declineReasonTile(),

                        if (liveStatus == 'pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _fullButton(
                                  label: 'Accept',
                                  icon: Icons.check_circle_outline,
                                  onPressed: _acceptAndGo,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _fullButton(
                                  label: 'Decline',
                                  icon: Icons.cancel_outlined,
                                  onPressed: _declineWithReason,
                                  filled: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (liveStatus == 'accepted') ...[
                          const SizedBox(height: 16),
                          _fullButton(
                            label: 'Start Your Job',
                            icon: Icons.play_arrow,
                            onPressed: _startJob,
                          ),
                        ],
                        if (liveStatus == 'in progress' ||
                            liveStatus == 'completed' ||
                            liveStatus == 'paused' ||
                            liveStatus == 'running') ...[
                          const SizedBox(height: 16),
                          _fullButton(
                            label: 'Go to Job Tracker',
                            icon: Icons.play_arrow,
                            onPressed: _goToTracker,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _declineReasonTile() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _ref.get(),
      builder: (context, snap) {
        final reason = snap.data?.data()?['declineReason'] as String? ?? '—';
        return _kv('Decline Reason', reason);
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(v.isEmpty ? '—' : v,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _fullButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool filled = true,
  }) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    return filled
        ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style)
        : FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icon), label: Text(label), style: style);
  }
}
