import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmpoweringPhotographersSection extends StatelessWidget {
  const EmpoweringPhotographersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
            Colors.amber.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header Card with AI-generated photo
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade100,
                    Colors.purple.shade100,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empowering Photographers:',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Trusted Solution for Seamless Customer Management',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
                        height: 200,
                        width: 300,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: 300,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 300,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // App Description Section
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text(
                  'Instant Photos',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isMobile ? 32 : 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 0 : 80),
                  child: Text(
                    'The best Photo Sharing App for Photographers, offering AI-Powered Photo Sharing using QR Code Scanning, Photo Selection and many more unique features.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: isMobile ? 16 : 18,
                      color: Colors.blueGrey.shade800,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Feature Highlights with AI images
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 1 : 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,

                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String imageUrl,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}