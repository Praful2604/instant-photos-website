import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  final String qrCode;
  const GalleryPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with TickerProviderStateMixin {
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

  Future<void> fetchImagesFromStorage() async {
    try {
      final ref =
      FirebaseStorage.instance.ref('event-images/${widget.qrCode}');
      final result = await ref.listAll();
      setState(() {
        imageUrls =
            result.items.map((i) => proxyImageUrl(i.fullPath)).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleFavorite(String fullPath) async {
    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.qrCode)
        .collection('imgs');

    final name = fullPath.split('/').last;
    final doc = ref.doc(name);

    if (favoritePaths.contains(fullPath)) {
      await doc.delete();
    } else {
      await doc.set({
        'path': fullPath,
        'time': FieldValue.serverTimestamp(),
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Gallery"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(icon: Icon(Icons.photo), text: "All Photos"),
            Tab(icon: Icon(Icons.favorite), text: "Favorites"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildGrid(imageUrls),
          buildGrid(favoriteImageUrls, favoritesOnly: true),
        ],
      ),
    );
  }

  Widget buildGrid(List<String> urls, {bool favoritesOnly = false}) {
    if (urls.isEmpty) {
      return Center(
        child: Text(
          favoritesOnly ? "No favorites yet ❤️" : "No photos found 📸",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final proxyUrl = urls[index];
          final fullPath = extractFullPath(proxyUrl);
          final isFav = favoritePaths.contains(fullPath);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  imageUrls: favoritesOnly ? favoriteImageUrls : imageUrls,
                  initialIndex: index,
                  favoritePaths: favoritePaths,
                  onToggleFavorite: toggleFavorite,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      proxyUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          await toggleFavorite(fullPath);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Set<String> favoritePaths;
  final Function(String) onToggleFavorite;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.favoritePaths,
    required this.onToggleFavorite,
  });

  @override
  State<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<FullScreenImageViewer> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  String extractPath(String url) =>
      Uri.parse(url).queryParameters['path'] ?? '';

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrls[index];
    final path = extractPath(url);
    final isFav = widget.favoritePaths.contains(path);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close,
                  color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
                size: 30,
              ),
              onPressed: () async {
                await widget.onToggleFavorite(path);
                setState(() {});
              },
            ),
          ),
          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height / 2,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white),
              onPressed: index > 0
                  ? () => setState(() => index--)
                  : null,
            ),
          ),
          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height / 2,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white),
              onPressed: index < widget.imageUrls.length - 1
                  ? () => setState(() => index++)
                  : null,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "${index + 1} / ${widget.imageUrls.length}",
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
