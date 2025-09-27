
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class EAlbumPage extends StatelessWidget {
  const EAlbumPage({super.key});

  // Ensure these paths are correct and match your pubspec.yaml declaration
  final List<String> photos = const [
    'assets/ealbum/01.jpg',
    'assets/ealbum/02.jpg',
    'assets/ealbum/03.jpg',
    'assets/ealbum/04.jpg',
    'assets/ealbum/05.jpg',
    'assets/ealbum/06.jpg',
    'assets/ealbum/07.jpg',
    'assets/ealbum/08.jpg',
    'assets/ealbum/09.jpg',
    'assets/ealbum/10.jpg',
    'assets/ealbum/11.jpg',
    'assets/ealbum/12.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate itemCount correctly for pairs (ceil ensures last odd photo gets a page)
    final int pageCount = (photos.length / 2).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text("3D Flip Photo Album"),
        backgroundColor: Colors.black87,
      ),
      body: PageView.builder(
        itemCount: pageCount,
        itemBuilder: (context, index) {
          final int frontPhotoIndex = index * 2;
          final int backPhotoIndex = index * 2 + 1;

          final String frontPhotoPath = photos[frontPhotoIndex];
          // Check if there's a back photo, otherwise it's the last odd page
          final String? backPhotoPath =
          (backPhotoIndex < photos.length) ? photos[backPhotoIndex] : null;

          // Debugging: Print which paths are being used for each card
          if (kDebugMode) {
            print('Page ${index + 1}: Front: $frontPhotoPath, Back: ${backPhotoPath ?? 'N/A'}');
          }

          return Center(
            child: FlipCard(
              direction: FlipDirection.HORIZONTAL, // Or VERTICAL
              front: _buildPhotoCard(frontPhotoPath, isFront: true),
              back: backPhotoPath != null
                  ? _buildPhotoCard(backPhotoPath, isFront: false)
                  : _buildEmptyCard(), // Show empty card if no back photo
            ),
          );
        },
      ),
    );
  }

  // Refined Photo Card Widget
  Widget _buildPhotoCard(String assetPath, {required bool isFront}) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover, // Ensures image fills the card
          errorBuilder: (context, error, stackTrace) {
            // This will show if the image asset cannot be loaded
            if (kDebugMode) {
              print('Error loading image: $assetPath - $error');
            }
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.red),
                    Text('Failed to load image: ${assetPath.split('/').last}', textAlign: TextAlign.center,),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 10, // Consistent elevation
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_album_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("No more photos", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
