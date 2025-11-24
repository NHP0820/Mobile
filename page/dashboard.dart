// lib/page/dashboard.dart
import 'dart:async';
import 'dart:convert';
import 'package:assignment29/page/spare_parts_listing.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment29/page/job_history.dart';
import 'package:assignment29/page/full_maintenance_jobs.dart';
// models
import '../class/job.dart';

// pages
import '../services/job_notification_service.dart';
import '../services/notification_service.dart';
import 'jobList.dart';
import 'job_detail.dart';
import 'profile.dart';

// tracker pages
import 'package:assignment29/tracker/active_timers_page.dart';
import 'package:assignment29/tracker/completed_jobs_page.dart';
import 'package:assignment29/tracker/signature.dart';

// sidebar
import 'sidebar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  late final PageController controller;
  int currentPage = 0;
  Timer? timer;

  final List<String> dashboardServices = const [
    'Jobs Today',
    'Completed',
    'Signature',
    'Active Timers',
    'Full Maintenance',
    'Job History',
  ];

  @override
  void initState() {
    super.initState();
    controller = PageController();

    NotificationService.initialize().then((_) {
      JobNotificationService.start();
    });

    // Carousel auto-slide
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!controller.hasClients) return;
      var nextPage = currentPage + 1;
      if (nextPage >= items.length) nextPage = 0;
      controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> items = [
    {
      'image': 'assets/image/home1.png',
      'title': 'Full Maintenance',
      'subtitle': 'Get 30% discount on full maintenance',
      'color': Colors.blue,
    },
    {
      'image': 'assets/image/home3.png',
      'title': 'Genuine Spare Parts',
      'subtitle': 'One year warranty on all spare parts',
      'color': Colors.orange,
    },
    {
      'image': 'assets/image/car_painting.jpg',
      'title': 'Car Painting',
      'subtitle': 'Get 30% discount on car painting',
      'color': Colors.green,
    },
    {
      'image': 'assets/image/car_shop.png',
      'title': 'Car Shop Service',
      'subtitle': 'Comprehensive car shop solutions for your needs',
      'color': Colors.blue,
    },
    {
      'image': 'assets/image/car_wheel.jpg',
      'title': 'Spare Parts',
      'subtitle': 'Genuine spare parts with warranty',
      'color': Colors.teal,
    },
    {
      'image': 'assets/image/car_repair.jpg',
      'title': 'Car Repair',
      'subtitle': 'Expert repairs and maintenance services',
      'color': Colors.orange,
    },
    {
      'image': 'assets/image/car_oil.jpg',
      'title': 'Oil Change',
      'subtitle': 'Quick oil change and filter replacement',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            backgroundColor: Colors.blue,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: const Text('Dashboard'),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: user != null
                      ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userData = snapshot.data?.data();
                      final photoURL = userData?['photoURL'] as String?;

                      // Handle base64 image data
                      ImageProvider<Object>? imageProvider;
                      if (photoURL != null && photoURL.isNotEmpty) {
                        if (photoURL.startsWith('data:image')) {
                          try {
                            final b64 = photoURL.split(',').last;
                            imageProvider = MemoryImage(
                              base64Decode(b64),
                            );
                          } catch (e) {
                            debugPrint('Error decoding base64 image: $e');
                            imageProvider = null;
                          }
                        } else if (photoURL.startsWith('http')) {
                          imageProvider = NetworkImage(photoURL);
                        }
                      }

                      return CircleAvatar(
                        radius: 18,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                        )
                            : null,
                        backgroundColor: Colors.indigo,
                      );
                    },
                  )
                      : const CircleAvatar(
                    radius: 18,
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),

          body: Column(
            children: [
              const SizedBox(height: 12),

              // ===== Carousel =====
              SizedBox(
                height: 180,
                child: PageView.builder(
                  itemCount: items.length,
                  controller: controller,
                  onPageChanged: (index) => setState(() => currentPage = index),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: currentPage == index ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (item['color'] as Color).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage(item['image'] as String),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.transparent,
                              (item['color'] as Color).withOpacity(0.8),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ===== Shortcuts =====
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        mainBarIcon(context, Icons.assignment, 'Jobs Today'),
                        mainBarIcon(context, Icons.check_circle, 'Completed'),
                        mainBarIcon(context, Icons.draw, 'Signature'),
                        mainBarIcon(context, Icons.timer, 'Active Timers'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MechanicServiceListPage(
                                serviceTitles: dashboardServices,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ===== Jobs streamed from Firestore (ONLY this mechanic) =====
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: user == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                      .collection('jobs')
                      .where('assignedMechanic', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (user == null) {
                      return const Center(child: Text('Please sign in.'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }

                    // Client-side filter to show only pending (case-insensitive)
                    final pendingDocs = (snap.data?.docs ?? []).where((d) {
                      final s = (d.data()['status'] ?? '').toString().trim().toLowerCase();
                      return s == 'pending';
                    }).toList();

                    // Sort by createdAt desc (client side to avoid composite index)
                    pendingDocs.sort((a, b) {
                      final ta = a.data()['createdAt'];
                      final tb = b.data()['createdAt'];
                      final da = (ta is Timestamp)
                          ? ta.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      final db = (tb is Timestamp)
                          ? tb.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      return db.compareTo(da);
                    });

                    if (pendingDocs.isEmpty) {
                      return const Center(child: Text('No pending jobs'));
                    }

                    return ListView.builder(
                      itemCount: pendingDocs.length,
                      itemBuilder: (context, index) {
                        final doc = pendingDocs[index];
                        final job = Job.fromDoc(doc);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              job.jobId.isEmpty ? 'Unknown Job' : job.jobId,
                            ),
                            subtitle: Text(
                              '${job.vehicle}\n${job.jobDescription}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.build),
                label: 'Spare Part',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            ],
            onTap: (index) {
              switch (index) {
                case 1: // Spare Part
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SparePartsListingPage(),
                    ),
                  );
                  break;
              } // Add other navigation logic as needed
            },
          ),
        );
      },
    );
  }

  // Shortcut tile
  Widget mainBarIcon(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        switch (label.toLowerCase()) {
          case 'signature':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignaturePage()),
            );
            break;
          case 'active timers':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActiveTimersPage()),
            );
            break;
          case 'completed':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompletedJobsPage()),
            );
            break;
          case 'jobs today':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobListPage(title: label)),
            );
            break;
          default:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobListPage(title: label)),
            );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, size: 28, color: Colors.blue),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// The “View All” grid page
class MechanicServiceListPage extends StatelessWidget {
  final List<String> serviceTitles;
  const MechanicServiceListPage({super.key, required this.serviceTitles});

  IconData iconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'jobs today':
        return Icons.assignment;
      case 'completed':
        return Icons.check_circle;
      case 'signature':
        return Icons.draw;
      case 'active timers':
        return Icons.timer;
      case 'job history':
        return Icons.history;
      case 'full maintenance':
        return Icons.car_repair;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Mechanic Services")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: serviceTitles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final title = serviceTitles[index];
            final icon = iconForTitle(title);
            return GestureDetector(
              onTap: () {
                switch (title.toLowerCase()) {
                  case 'signature':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignaturePage()),
                    );
                    break;
                  case 'active timers':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiveTimersPage(),
                      ),
                    );
                    break;
                  case 'completed':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompletedJobsPage(),
                      ),
                    );
                    break;
                  case 'job history':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobHistoryPage()),
                    );
                    break;
                  case 'full maintenance':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FullMaintenancePage(),
                      ),
                    );
                    break;
                  default:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobListPage(title: title),
                      ),
                    );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(icon, size: 30, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

