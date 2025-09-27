import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For auth userId
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  final String qrCode;
  const GalleryPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> imageUrls = [];
  Set<String> favoritePaths = Set<String>();
  bool isLoading = true;

  final String proxyBaseUrl =
      'https://us-central1-instant-photos-9a258.cloudfunctions.net/proxyImage';

  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    userId = user.uid;
    fetchImagesFromStorage();
    listenToFavorites();
  }

  String proxyImageUrl(String path) {
    return '$proxyBaseUrl?path=$path';
  }

  void listenToFavorites() {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection(widget.qrCode)
        .snapshots()
        .listen((snapshot) {
      final favorites = snapshot.docs.map((doc) => doc.id).toSet();
      setState(() {
        favoritePaths = favorites;
      });
    }, onError: (e) {
      print('Error reading favorites from Firestore: $e');
    });
  }

  Future<void> fetchImagesFromStorage() async {
    try {
      final ref = FirebaseStorage.instance.ref('event-images/${widget.qrCode}');
      final result = await ref.listAll();

      final urls = result.items.map((itemRef) => proxyImageUrl(itemRef.fullPath)).toList();

      setState(() {
        imageUrls = urls;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  Future<void> toggleFavorite(String fullPath) async {
    final favDocRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection(widget.qrCode)
        .doc(fullPath);

    if (favoritePaths.contains(fullPath)) {
      // Unfavorite - delete doc
      await favDocRef.delete();
    } else {
      if (favoritePaths.length >= 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum of 500 favorite photos allowed')),
        );
        return;
      }
      // Favorite - add doc
      await favDocRef.set({'favoritedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Gallery')),
          body: const Center(child: CircularProgressIndicator()));
    }

    String extractFullPath(String proxyUrl) =>
        Uri.parse(proxyUrl).queryParameters['path'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: imageUrls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemBuilder: (context, index) {
            final proxyUrl = imageUrls[index];
            final fullPath = extractFullPath(proxyUrl);
            final isFavorite = favoritePaths.contains(fullPath);

            return Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrls: imageUrls,
                        initialIndex: index,
                        favoritePaths: favoritePaths,
                        onToggleFavorite: toggleFavorite,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      proxyUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.blue,
                    ),
                    onPressed: () => toggleFavorite(fullPath),
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

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Set<String> favoritePaths;
  final Function(String fullPath) onToggleFavorite;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
    required this.favoritePaths,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int currentIndex;

  String extractFullPath(String proxyUrl) =>
      Uri.parse(proxyUrl).queryParameters['path'] ?? '';

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void goToNext() {
    if (currentIndex < widget.imageUrls.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void goToPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final proxyUrl = widget.imageUrls[currentIndex];
    final fullPath = extractFullPath(proxyUrl);
    final isFavorite = widget.favoritePaths.contains(fullPath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  proxyUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 32),
                onPressed: currentIndex > 0 ? goToPrevious : null,
              ),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 32),
                onPressed:
                currentIndex < widget.imageUrls.length - 1 ? goToNext : null,
              ),
            ),
            Positioned(
              top: 30,
              left: 20,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  widget.onToggleFavorite(fullPath);
                  setState(() {});
                },
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon:
                const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
