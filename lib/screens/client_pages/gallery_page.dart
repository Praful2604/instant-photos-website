import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPage extends StatefulWidget {
  final String qrCode;
  const GalleryPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }


  Future<void> fetchImagesFromStorage() async {
    final ref = FirebaseStorage.instance.ref('event-images/${widget.qrCode}');
    final result = await ref.listAll();
    final urls = await Future.wait(result.items.map((itemRef) => itemRef.getDownloadURL()));
    setState(() {
      imageUrls = urls;
      isLoading = false;
    });
  }

  Future<void> fetchImages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('event_images')
        .where('qr_code', isEqualTo: widget.qrCode)
        .orderBy('uploaded_at', descending: true)
        .get();

    setState(() {
      imageUrls = snapshot.docs.map((doc) => doc['url'] as String).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (imageUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: const Center(child: Text('No images available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: imageUrls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: imageUrls,
                    initialIndex: index,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
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

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int currentIndex;

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(widget.imageUrls[currentIndex]),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 32),
                onPressed: currentIndex > 0 ? goToPrevious : null,
              ),
            ),
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 32),
                onPressed: currentIndex < widget.imageUrls.length - 1 ? goToNext : null,
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
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
