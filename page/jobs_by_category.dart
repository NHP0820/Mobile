// lib/page/jobs_by_category.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// your existing model + detail page
import 'package:assignment29/class/job.dart';
import 'job_detail.dart';

class JobsByCategoryPage extends StatefulWidget {
  final String category;
  final int limit;

  const JobsByCategoryPage({
    super.key,
    required this.category,
    this.limit = 200,
  });

  @override
  State<JobsByCategoryPage> createState() => _JobsByCategoryPageState();
}

class _JobsByCategoryPageState extends State<JobsByCategoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final col = FirebaseFirestore.instance.collection('jobs');
    if (uid == null) {
      return col.where('assignedMechanic', isEqualTo: '__no_user__');
    }
    return col.where('assignedMechanic', isEqualTo: uid).limit(200);
  }

  // ---- helpers copied to match JobList behavior ----
  String _norm(String s) => s.trim().toLowerCase();

  bool _matchesSearch(Job j, String q) {
    if (q.trim().isEmpty) return true;
    final tokens = q.toLowerCase().replaceAll('#', '').trim().split(RegExp(r'\s+'));
    final haystack = [
      j.jobId,
      j.category,
      j.vehicle,
      j.jobDescription,
    ].map((v) => v.toLowerCase().replaceAll('#', '')).join(' ');
    return tokens.every((t) => haystack.contains(t));
  }

  // Category check: prefer exact category match (case-insensitive).
  // If your data sometimes writes the category in other fields, you can
  // loosen this by checking description etc. too.
  bool _inCategory(Job j) {
    return _norm(j.category) == _norm(widget.category);
  }

  // Same palette as your JobListPage
  Color _statusColor(String s) {
    switch (_norm(s)) {
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
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by Job ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: Column(
        children: [
          topBar,
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No jobs in "${widget.category}".'),
                  );
                }

                List<_Row> rows = docs
                    .map((d) => _Row(d.reference, Job.fromDoc(d)))
                    .toList();

                // 1) Only this category
                rows = rows.where((r) => _inCategory(r.job)).toList();

                // 2) Only pending
                rows = rows
                    .where((r) => _norm(r.job.status) == 'pending')
                    .toList();

                // 3) Search
                final q = _searchCtrl.text.trim();
                rows = rows.where((r) => _matchesSearch(r.job, q)).toList();

                if (rows.isEmpty) {
                  return Center(
                    child: Text('No pending jobs found for "${widget.category}".'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    final j = row.job;
                    return _JobCard(
                      job: j,
                      statusColor: _statusColor(j.status),
                      onView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetail(
                              job: j,
                              docPath: row.ref.path,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// helper pairing doc ref + model
class _Row {
  final DocumentReference<Map<String, dynamic>> ref;
  final Job job;
  _Row(this.ref, this.job);
}

/// The same card style as JobList (_JobCard)
class _JobCard extends StatelessWidget {
  final Job job;
  final Color statusColor;
  final VoidCallback onView;

  const _JobCard({
    required this.job,
    required this.statusColor,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x1A000000),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.jobId,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.category,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.jobDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    job.vehicle,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // right column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 34,
                  child: FilledButton.tonal(
                    onPressed: onView,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View'),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Status', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  job.status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
