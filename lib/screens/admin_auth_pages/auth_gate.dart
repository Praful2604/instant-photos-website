import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:major_project_website/screens/admin_auth_pages/admin_login_page.dart';
import 'package:major_project_website/screens/admin_pages/admin_dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool> _isApprovedPhotographer(User user) async {
    final query = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  void _signOutAndShowSnackbar() {
    FirebaseAuth.instance.signOut();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Your account is not registered as a photographer.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const AdminLoginPage();
        }

        return FutureBuilder<bool>(
          future: _isApprovedPhotographer(snapshot.data!),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (authSnap.data != true) {
              _signOutAndShowSnackbar();
              return const AdminLoginPage();
            }

            return const AdminDashboardPage();
          },
        );
      },
    );
  }
}
