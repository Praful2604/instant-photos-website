import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  final String qrCode;
  const GalleryPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> imageUrls = [];
  Set<String> favoritePaths = {};
  bool isLoading = true;

  final proxyBaseUrl =
      'https://us-central1-instant-photos-9a258.cloudfunctions.net/proxyImage';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchImagesFromStorage();
    listenToFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String proxyImageUrl(String path) => '$proxyBaseUrl?path=$path';

  /// 🔹 Listen for Firestore updates in real-time
  void listenToFavorites() {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.qrCode)
        .collection('imgs')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        favoritePaths =
            snapshot.docs.map((doc) => doc['path'] as String).toSet();
      });
    });
  }

  /// 🔹 Fetch all images from Firebase Storage (read-only)
  Future<void> fetchImagesFromStorage() async {
    try {
      final ref = FirebaseStorage.instance.ref('event-images/${widget.qrCode}');
      final result = await ref.listAll();
      setState(() {
        imageUrls =
            result.items.map((item) => proxyImageUrl(item.fullPath)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching images: $e');
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Add or remove image from favorites
  Future<void> toggleFavorite(String fullPath) async {
    final imgsCollection = FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.qrCode)
        .collection('imgs');

    final imageName = fullPath.split('/').last;
    final docRef = imgsCollection.doc(imageName);
    final isFavorite = favoritePaths.contains(fullPath);

    if (isFavorite) {
      await docRef.delete();
    } else {
      await docRef.set({
        'path': fullPath,
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String extractFullPath(String proxyUrl) =>
      Uri.parse(proxyUrl).queryParameters['path'] ?? '';

  List<String> get favoriteImageUrls => imageUrls
      .where((url) => favoritePaths.contains(extractFullPath(url)))
      .toList();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'All Photos'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildGridView(imageUrls),
          buildGridView(favoriteImageUrls, favoritesOnly: true),
        ],
      ),
    );
  }

  /// 🔹 Builds a grid of all or favorite photos
  Widget buildGridView(List<String> urls, {bool favoritesOnly = false}) {
    if (urls.isEmpty) {
      return Center(
        child: Text(
          favoritesOnly ? 'No favorite photos yet.' : 'No photos available.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final proxyUrl = urls[index];
          final fullPath = extractFullPath(proxyUrl);
          final isFavorite = favoritePaths.contains(fullPath);

          return Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrls: favoritesOnly ? favoriteImageUrls : imageUrls,
                      initialIndex: index,
                      favoritePaths: favoritePaths,
                      onToggleFavorite: (path) async {
                        await toggleFavorite(path);
                        setState(() {}); // Refresh grid immediately
                      },
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
                top: 6,
                right: 6,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    await toggleFavorite(fullPath);
                    setState(() {}); // Refresh UI immediately
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 🔹 Full-screen image viewer with favorite toggle
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
      setState(() => currentIndex++);
    }
  }

  void goToPrevious() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
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
                  loadingBuilder: (context, child, progress) =>
                  progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
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
                onPressed: () async {
                  await widget.onToggleFavorite(fullPath);
                  setState(() {}); // Refresh favorite icon state
                },
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon:
                const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 30),
                onPressed: goToPrevious,
              ),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 30),
                onPressed: goToNext,
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
