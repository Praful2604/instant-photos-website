import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/landing_page_screens/home_page.dart';
import '../screens/admin_auth_pages/admin_login_page.dart';
import '../screens/admin_auth_pages/admin_signup_page.dart';
import '../screens/admin_pages/admin_dashboard_page.dart';
import '../screens/customer_auth_pages/customer_login_page.dart';
import '../screens/customer_auth_pages/customer_signup_page.dart';
import '../screens/client_pages/client_otp_login_page.dart';
import '../screens/client_pages/gallery_page.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin/signup',
        builder: (context, state) => const AdminSignupPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/customer/login',
        builder: (context, state) => const CustomerLoginPage(),
      ),
      GoRoute(
        path: '/customer/signup',
        builder: (context, state) => const CustomerSignUpPage(),
      ),
      GoRoute(
        path: '/client/otp',
        builder: (context, state) => ClientOtpLoginPage(),
      ),
      GoRoute(
        path: '/client/gallery/:qrCode',
        builder: (context, state) => GalleryPage(
          qrCode: state.pathParameters['qrCode'] ?? '',
        ),
      ),
    ],
  );
}
