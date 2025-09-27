import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project_website/screens/client_pages/client_otp_login_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserChoiceSelectionPage extends StatelessWidget {
  final String initialQrCode;
  final String eventName;

  const UserChoiceSelectionPage({
    Key? key,
    required this.initialQrCode,
    required this.eventName,
  }) : super(key: key);

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
            Text(
              eventName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ClientOtpLoginPage()),);
            },
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
          const SizedBox(width: 10),
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
                Text(
                  initialQrCode,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  eventName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const SizedBox(height: 24),
                _buildChoiceButton(
                  context,
                  title: 'View My Photos',
                  icon: Icons.photo,
                  onPressed: () {
                    // Navigate to your SmartAlbumPage here with initialQrCode and eventName
                  },
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
