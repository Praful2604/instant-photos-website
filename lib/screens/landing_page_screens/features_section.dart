import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              //child: FaIcon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Empower Your Photography Business',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Trusted Solution for Seamless Customer Management',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              /*_buildFeatureCard(
                icon: FontAwesomeIcons.robot,
                title: 'AI Photo Selection',
                description:
                'Advanced AI-powered photo selection and enhancement for professional results.',
              ),
              /*_buildFeatureCard(
                icon: FontAwesomeIcons.mobileScreen,
                title: 'Mobile App',
                description:
                    'Custom branded mobile app for your photography business.',
              ),*/
              _buildFeatureCard(
                icon: FontAwesomeIcons.images,
                title: 'Digital Albums',
                description:
                'Create and share beautiful digital photo albums with background music.',
              ),
              _buildFeatureCard(
                icon: FontAwesomeIcons.video,
                title: 'Video Sharing',
                description:
                'Secure video sharing and live streaming capabilities.',
              ),
              _buildFeatureCard(
                icon: FontAwesomeIcons.qrcode,
                title: 'QR Code Sharing',
                description: 'Instant photo sharing with QR code scanning.',
              ),
              _buildFeatureCard(
                icon: FontAwesomeIcons.cloudArrowUp,
                title: 'Unlimited Storage',
                description: 'Store unlimited photos and videos in the cloud.',
              ),
              _buildFeatureCard(
                icon: FontAwesomeIcons.calendarCheck,
                title: 'Event Booking',
                description:
                'Simplify the booking process for your clients effortlessly.',
              ),*/
            ],
          ),
        ],
      ),
    );
  }
}