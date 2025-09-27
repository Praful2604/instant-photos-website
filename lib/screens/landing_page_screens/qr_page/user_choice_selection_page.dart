import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project_website/screens/client_pages/client_otp_login_page.dart';
import 'package:major_project_website/screens/client_pages/gallery_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_page.dart';

class UserChoiceSelectionPage extends StatefulWidget {
  final String initialQrCode;
  final String eventName;

  const UserChoiceSelectionPage({
    Key? key,
    required this.initialQrCode,
    required this.eventName,
  }) : super(key: key);

  @override
  State<UserChoiceSelectionPage> createState() => _UserChoiceSelectionPageState();
}

class _UserChoiceSelectionPageState extends State<UserChoiceSelectionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _checkClientAccess() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showAccessDeniedMessage("You need to login first.");
      return;
    }

    try {
      // Get client details for this QR code
      final clientDoc = await _firestore
          .collection('client_details')
          .doc(widget.initialQrCode)
          .get();

      if (clientDoc.exists) {
        final clientData = clientDoc.data()!;
        final storedEmail = clientData['email']?.toString().toLowerCase();
        final userEmail = user.email?.toLowerCase();

        if (storedEmail == userEmail) {
          // Email matches, navigate to gallery
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GalleryPage(qrCode: widget.initialQrCode),
            ),
          );
        } else {
          _showAccessDeniedMessage("You did not get access.");
        }
      } else {
        _showAccessDeniedMessage("No client details found for this QR code. Please contact the administrator.");
      }
    } catch (e) {
      debugPrint('Error checking client access: $e');
      _showAccessDeniedMessage("Unable to verify your access. Please try again later.");
    }
  }
  Future<void> _logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    }
  }
  void _showAccessDeniedMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Access Denied",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Option'),
            // Text(
            //   eventName,
            //   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            // ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: _checkClientAccess,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            child: const Text(
              'Login as Client',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 10,),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),

        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3a7bd5), Color(0xFF00d2ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 12),
                // Text(
                //   initialQrCode,
                //   style: const TextStyle(
                //       fontSize: 16,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.white),
                // ),
                // const SizedBox(height: 4),
                // Text(
                //   eventName,
                //   style: const TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.w600,
                //       color: Colors.white),
                // ),
                const SizedBox(height: 24),
                _buildChoiceButton(
                  context,
                  title: 'View My Photos',
                  icon: Icons.photo,
                  onPressed: _checkClientAccess,
                ),
                const SizedBox(height: 20),
                _buildChoiceButton(
                  context,
                  title: 'View Digital Album',
                  icon: Icons.photo_album_outlined,
                  onPressed: () {
                    // Navigate to your FlipBookPage here with initialQrCode and eventName
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: Colors.indigo.shade600,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
