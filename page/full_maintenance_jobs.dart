import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment29/class/job.dart';
import 'job_detail.dart';

class FullMaintenancePage extends StatefulWidget {
  const FullMaintenancePage({super.key});

  @override
  State<FullMaintenancePage> createState() => _FullMaintenancePageState();
}

class _FullMaintenancePageState extends State<FullMaintenancePage> {
  final TextEditingController _search = TextEditingController();
  bool _isAdmin = false;
  bool _checkingClaims = true;

  @override
  void initState() {
    super.initState();
    _checkAdminClaim();
  }

  Future<void> _checkAdminClaim() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isAdmin = false;
          _checkingClaims = false;
        });
        return;
      }
      final token = await user.getIdTokenResult(true);
      final isAdmin = (token.claims?['admin'] == true);
      setState(() {
        _isAdmin = isAdmin;
        _checkingClaims = false;
      });
    } catch (_) {
      setState(() {
        _isAdmin = false;
        _checkingClaims = false;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    final col = FirebaseFirestore.instance.collection('jobs');
    if (_isAdmin) return col.limit(300);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return col.where('assignedMechanic', isEqualTo: '__no_user__').limit(1);
    }
    return col.where('assignedMechanic', isEqualTo: uid).limit(300);
  }

  String _shortId(String id, {int max = 8}) {
    if (id.isEmpty) return 'Unknown';
    final end = id.length < max ? id.length : max;
    final core = id.substring(0, end);
    return id.length > max ? '$core...' : core;
  }

  bool _isFullMaintenance(Map<String, dynamic> d) {
    final cat = (d['category'] ?? '').toString().toLowerCase().trim();
    return cat == 'full maintenance';
  }

  bool _isPending(Map<String, dynamic> d) {
    return (d['status'] ?? '').toString().toLowerCase().trim() == 'pending';
  }

  bool _matchesJobId(Map<String, dynamic> d, String needle) {
    final n = needle.trim().toLowerCase();
    if (n.isEmpty) return true;
    final jobId = (d['jobId'] ?? '').toString().toLowerCase();
    final fallback = (d['id'] ?? '').toString().toLowerCase();
    return jobId.contains(n) || fallback.contains(n);
  }

  String _fmtDate(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Maintenance'),
        actions: [
          if (_checkingClaims)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(_isAdmin ? 'Admin' : 'Mechanic'),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by jobId',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting || _checkingClaims) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final docs = [...(snap.data?.docs ?? [])];
                docs.sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  final da = (ta is Timestamp) ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final db = (tb is Timestamp) ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return db.compareTo(da);
                });

                final needle = _search.text;
                final filtered = docs
                    .where((d) => _isFullMaintenance(d.data()))
                    .where((d) => _isPending(d.data()))
                    .where((d) => _matchesJobId(d.data(), needle))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No pending “Full Maintenance” jobs found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data();

                    final jobId = ((data['jobId'] ?? doc.id) as Object).toString();
                    final vehicle = (data['vehicle'] ?? '').toString();
                    final desc = (data['jobDescription'] ?? '').toString();
                    final createdAt = data['createdAt'];
                    final price = (data['price']?.toString() ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () {
                          final job = Job.fromDoc(doc);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetail(
                                job: job,
                                docPath: doc.reference.path,
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
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (desc.isNotEmpty) Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.tag, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('ID: ${_shortId(jobId)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Spacer(),
                                  if (price.isNotEmpty) ...[
                                    const Icon(Icons.payments, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(price, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 12),
                                  ],
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(_fmtDate(createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
          ),
        ],
      ),
    );
  }
}
