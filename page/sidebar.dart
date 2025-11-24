// lib/page/sidebar.dart
import 'dart:convert'; // for base64Decode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage; // for gs://
import 'package:flutter/material.dart';

import 'jobs_by_category.dart';
import 'profile.dart';
import 'login.dart';
import 'jobList.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    String initial() {
      final base = (user?.displayName ?? user?.email ?? 'U').trim();
      return base.isNotEmpty ? base[0].toUpperCase() : 'U';
    }

    return Drawer(
      width: 300,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(.06),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: _SmartAvatar(user: user, fallbackText: initial()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            user?.displayName ?? (user?.email ?? 'Guest'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context), // close drawer
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            _NavTile(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _NavTile(
              icon: Icons.assignment,
              label: 'Jobs Today',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JobListPage(title: 'Jobs Today'),
                  ),
                );
              },
            ),

            _CategoriesSection(uid: uid),

            const SizedBox(height: 12),
            const Divider(height: 1),

            _NavTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),

            _NavTile(
              icon: Icons.logout,
              label: 'Logout',
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  final String? uid;
  const _CategoriesSection({Key? key, this.uid}) : super(key: key);

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(.06),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: const Text(
            'Categories',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more_rounded),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: (() {
                Query<Map<String, dynamic>> q =
                FirebaseFirestore.instance.collection('jobs');

                // Scope to this mechanic only
                final uid = widget.uid;
                if (uid != null) {
                  q = q.where('assignedMechanic', isEqualTo: uid);
                } else {
                  // If no user, ensure zero results
                  q = q.where('assignedMechanic', isEqualTo: '__no_user__');
                }

                return q.snapshots();
              })(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
                  ) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Failed to load categories\n${snap.error}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                final allDocs = snap.data?.docs ?? [];

                final pendingDocs = allDocs.where((d) {
                  final s = (d.data()['status'] as String?)
                      ?.trim()
                      .toLowerCase() ??
                      '';
                  return s == 'pending';
                }).toList();

                if (pendingDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No pending jobs.'),
                  );
                }

                // Group counts by category (pending only, for this user)
                final Map<String, int> counts = {};
                for (final d in pendingDocs) {
                  final c = (d.data()['category'] as String?)?.trim();
                  final key = (c == null || c.isEmpty) ? 'Uncategorized' : c;
                  counts.update(key, (v) => v + 1, ifAbsent: () => 1);
                }

                final items = counts.entries.toList()
                  ..sort((a, b) =>
                      a.key.toLowerCase().compareTo(b.key.toLowerCase()));

                return Column(
                  children: List.generate(items.length, (i) {
                    final e = items[i];
                    final color =
                        Colors.primaries[i % Colors.primaries.length].shade400;
                    return _CategoryRow(
                      label: e.key,
                      count: e.value, // pending count for THIS user
                      dotColor: color,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JobsByCategoryPage(category: e.key),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final int count;
  final Color dotColor;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.label,
    required this.count,
    required this.dotColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                  Theme.of(context).colorScheme.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(.05),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: fg, fontSize: 15)),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartAvatar extends StatelessWidget {
  final User? user;
  final String fallbackText;
  const _SmartAvatar({required this.user, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Colors.indigo.shade200,
        child: Text(
          fallbackText,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final fsPhoto = (data?['photoURL'] as String?)?.trim();
        final authPhoto = user!.photoURL?.trim();
        final src =
        (fsPhoto != null && fsPhoto.isNotEmpty) ? fsPhoto : (authPhoto ?? '');

        // gs:// -> resolve to HTTPS download URL
        if (src.startsWith('gs://')) {
          return FutureBuilder<String>(
            future: FirebaseStorage.instance.refFromURL(src).getDownloadURL(),
            builder: (context, s) {
              final https = s.data;
              final provider =
              (https != null && https.isNotEmpty) ? NetworkImage(https) : null;
              return _avatar(provider);
            },
          );
        }

        ImageProvider? provider;
        if (src.startsWith('data:image')) {
          try {
            final b64 = src.split(',').last;
            provider = MemoryImage(base64Decode(b64));
          } catch (e) {
            debugPrint('Avatar data: decode error: $e');
          }
        } else if (src.startsWith('http')) {
          provider = NetworkImage(src);
        } else if (src.isNotEmpty) {
          // raw base64 without data: prefix
          try {
            provider = MemoryImage(base64Decode(src));
          } catch (e) {
            debugPrint('Avatar raw base64 decode error: $e');
          }
        }

        return _avatar(provider, fallback: fallbackText);
      },
    );
  }

  Widget _avatar(ImageProvider? provider, {String? fallback}) {
    return CircleAvatar(
      radius: 26,
      backgroundImage: provider,
      backgroundColor: Colors.indigo.shade200,
      child: provider == null && fallback != null
          ? Text(
        fallback,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      )
          : null,
    );
  }
}
