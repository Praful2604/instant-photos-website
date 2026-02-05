
import 'package:flutter/material.dart';


import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class EAlbumSection extends StatelessWidget {
  const EAlbumSection({super.key});

  // Define the URL for your demo album
  final String demoAlbumUrl = 'https://flipbook-eight-nu.vercel.app/album/277461';

  // Function to launch the URL
  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // Default for non-web platforms
      webOnlyWindowName: '_self', // This is the key for opening in the same tab on web
    )) {
      // ... rest of your error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F7), // light teal background
            borderRadius: BorderRadius.circular(40),
          ),
          child: isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/ealbum.png',
                fit: BoxFit.contain,
                height: 200,
              ),
              const SizedBox(height: 24),
              _buildContent(context, isMobile),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Image
              Expanded(
                flex: 4,
                child: Image.asset(
                  'assets/ealbum.png',
                  fit: BoxFit.contain,
                  height: 250,
                ),
              ),

              const SizedBox(width: 40),

              // Right Content
              Expanded(
                flex: 6,
                child: _buildContent(context, isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment:
      isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'e-Album',
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B4000), // brown
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Offer your clients modern e-Albums with physical album, perfect for sharing your work globally',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 24),

        // Feature 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.preview, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clients can review the e-Album and request changes before final printing',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Feature 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.share_outlined, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sharing this e-Album showcases the quality of your work to a larger audience',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Button
        Align(
          alignment: isMobile ? Alignment.center : Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () {
              // Call the new _launchUrl function with the context and URL
              _launchUrl(context, demoAlbumUrl);
            },
            icon: const Icon(Icons.photo_album_outlined),
            label: const Text('View Demo Album!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
