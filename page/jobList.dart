import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../class/job.dart';
import 'job_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobListPage extends StatefulWidget {
  final String title;
  const JobListPage({super.key, required this.title});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  String _statusFilter = 'pending';
  String _sort = 'new';
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


  Color _statusColor(String s) {
    switch (s.trim().toLowerCase()) {
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

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet(
        initialStatus: _statusFilter.toLowerCase(),
        initialSort: _sort,
      ),
    );

    if (result != null) {
      setState(() {
        _statusFilter = result.status;
        _sort = result.sort;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    color: Colors.black.withOpacity(0.06),
                  ),
                ],
              ),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                  return const Center(child: Text('No jobs found.'));
                }

                List<_Row> rows = docs
                    .map((d) => _Row(d.reference, Job.fromDoc(d)))
                    .toList();

                String norm(String s) => s.trim().toLowerCase();

                final selected = norm(_statusFilter);
                if (selected != 'all') {
                  rows = rows
                      .where((r) => norm(r.job.status) == selected)
                      .toList();
                }

                // Search
                final q = _searchCtrl.text.trim();
                rows = rows.where((r) => _matchesSearch(r.job, q)).toList();

                // Sort by createdAt
                rows.sort((a, b) {
                  final ta = a.job.createdAt?.millisecondsSinceEpoch ?? -1;
                  final tb = b.job.createdAt?.millisecondsSinceEpoch ?? -1;
                  return _sort == 'new' ? tb.compareTo(ta) : ta.compareTo(tb);
                });

                if (rows.isEmpty) {
                  return const Center(child: Text('No matching jobs.'));
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

class _Row {
  final DocumentReference<Map<String, dynamic>> ref;
  final Job job;
  _Row(this.ref, this.job);
}

// ---------- Card ----------
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
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
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 34,
                  child: FilledButton.tonal(
                    onPressed: onView,
                    style: FilledButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View'),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Status',
                    style:
                    TextStyle(fontSize: 12, color: Colors.black54)),
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

// ---------- Bottom Sheet ----------
class _FilterResult {
  final String status; // 'pending' | 'in progress' | 'cancelled' | 'completed' | 'all'
  final String sort;   // 'new' | 'old'
  _FilterResult({required this.status, required this.sort});
}

class _FilterSheet extends StatefulWidget {
  final String initialStatus;
  final String initialSort;
  const _FilterSheet(
      {required this.initialStatus, required this.initialSort});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _status = widget.initialStatus.toLowerCase();
  late String _sort   = widget.initialSort;

  Widget _choice(String key, String label, {bool outlined = false}) {
    final selected = (key == _status) || (key == _sort);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (key == 'pending' ||
              key == 'in progress' ||
              key == 'accepted' ||
              key == 'cancelled' ||
              key == 'completed' ||
              key == 'all') {
            _status = key;
          } else if (key == 'new' || key == 'old') {
            _sort = key;
          }
        });
      },
      side: outlined ? const BorderSide() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Status',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choice('pending', 'Pending'),
                  _choice('in progress', 'In Progress'),
                  _choice('accepted', 'Accepted'),
                  _choice('cancelled', 'Cancelled'),
                  _choice('completed', 'Completed'),
                  _choice('all', 'All'),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort By',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _choice('new', 'Newest first', outlined: true),
                  _choice('old', 'Oldest first', outlined: true),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _FilterResult(status: _status, sort: _sort),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
