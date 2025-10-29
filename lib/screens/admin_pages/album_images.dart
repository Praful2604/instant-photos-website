import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlbumImages extends StatefulWidget {
  final String qrCode;
  const AlbumImages({Key? key, required this.qrCode, required String eventName}) : super(key: key);

  @override
  State<AlbumImages> createState() => _AlbumImagesPageState();
}

class _AlbumImagesPageState extends State<AlbumImages> {
  Set<String> favoritePaths = {};
  bool isLoading = true;

  final proxyBaseUrl =
      'https://us-central1-instant-photos-9a258.cloudfunctions.net/proxyImage';

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  /// 🔹 Listen to Firestore favorites in real-time
  void fetchFavorites() {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.qrCode)
        .collection('imgs')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        favoritePaths =
            snapshot.docs.map((doc) => doc['path'] as String).toSet();
        isLoading = false;
      });
    });
  }

  String proxyImageUrl(String path) => '$proxyBaseUrl?path=$path';

  /// 🔹 Toggle favorite status
  Future<void> toggleFavorite(String fullPath) async {
    final docRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.qrCode)
        .collection('imgs')
        .doc(fullPath.split('/').last);

    if (favoritePaths.contains(fullPath)) {
      await docRef.delete();
    } else {
      await docRef.set({
        'path': fullPath,
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Album Images')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (favoritePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Album Images')),
        body: const Center(
          child: Text('No favorite photos yet.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Album Images')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: favoritePaths.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final fullPath = favoritePaths.elementAt(index);
            final proxyUrl = proxyImageUrl(fullPath);
            final isFavorite = favoritePaths.contains(fullPath);

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    proxyUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.error)),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      await toggleFavorite(fullPath);
                      setState(() {}); // Refresh UI
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
