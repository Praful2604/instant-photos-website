import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../customer_auth_pages/customer_login_page.dart';
import '../../admin_pages/view_photos_page.dart';
import '../home_page.dart';

class UserChoiceSelectionPage extends StatefulWidget {
  const UserChoiceSelectionPage({Key? key}) : super(key: key);

  @override
  State<UserChoiceSelectionPage> createState() =>
      _UserChoiceSelectionPageState();
}

class _UserChoiceSelectionPageState extends State<UserChoiceSelectionPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  late AnimationController _animationController;
  late Animation<double> _fadeScale;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeScale = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');

    setState(() {
      _isAuthenticated = user != null && userRole == 'customer';
      _isCheckingAuth = false;
    });
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return _buildBlockedView(context);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBackground(
        Center(
          child: ScaleTransition(
            scale: _fadeScale,
            child: _buildGlassCard(context),
          ),
        ),
      ),
    );
  }

  // ---------------- APP BAR ----------------
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome 👋'),
          Text(
            'Choose what you want to explore',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    );
  }

  // ---------------- COMMON BACKGROUND ----------------
  Widget _buildBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3a7bd5), Color(0xFF00d2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  // ---------------- MAIN CARD ----------------
  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                'Your Digital Memories',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 26),
              _gradientButton(
                title: 'View My Photos',
                icon: Icons.photo_library_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewPhotosPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _gradientButton(
                title: 'View Digital Album',
                icon: Icons.menu_book_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
                ),
                onPressed: () {
                  _openWebsite(
                    'https://flipbook-eight-nu.vercel.app/',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BUTTON ----------------
  Widget _gradientButton({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onPressed,
      child: Ink(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BLOCKED VIEW (MATCHING COLORS) ----------------
  Widget _buildBlockedView(BuildContext context) {
    return Scaffold(
      body: _buildBackground(
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 70, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Login Required',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please login to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerLoginPage(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Text(
                          'Go to Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
