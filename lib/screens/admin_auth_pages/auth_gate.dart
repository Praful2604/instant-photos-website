import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:major_project_website/screens/admin_auth_pages/admin_login_page.dart';
import 'package:major_project_website/screens/admin_pages/admin_dashboard_page.dart';
import '../admin_pages/my_events_page.dart';
import '../landing_page_screens/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Wait for Firebase to restore session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!snapshot.hasData) {
          return const AdminLoginPage(); // your login / landing page
        }

        // ✅ Logged in
        return  AdminDashboardPage();
      },
    );
  }
}
