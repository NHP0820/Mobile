import 'package:assignment29/page/add_job_page.dart';
import 'package:assignment29/page/login.dart';
import 'package:assignment29/page/signup.dart';
import 'package:assignment29/services/job_notification_service.dart';
import 'package:assignment29/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'page/dashboard.dart';
import 'package:assignment29/tracker//signature.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await JobNotificationService.start();
  runApp(const GreenstemApp());
}

class GreenstemApp extends StatelessWidget {
  const GreenstemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenstem Workshop',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.hasData ? const Dashboard() : const LoginPage();
        },
      ),
      routes: {
        SignUpPage.route: (_) => const SignUpPage(),
        '/dashboard': (_) => const Dashboard(),
        '/signature': (_) => const SignaturePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
