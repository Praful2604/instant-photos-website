//To view all photos for admin


import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ViewAllPhotos extends StatefulWidget {
  final String qrCode;
  const ViewAllPhotos({super.key, required this.qrCode});

  @override
  State<ViewAllPhotos> createState() => _ViewAllPhotosState();
}

class _ViewAllPhotosState extends State<ViewAllPhotos> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final ref = _storage.ref('event-images/${widget.qrCode}');
      final result = await ref.listAll();

      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );

      setState(() {
        _imageUrls = urls;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Photos – ${widget.qrCode}",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageUrls.isEmpty
          ? const Center(
        child: Text(
          "No photos found for this QR code",
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullImageView(
                    imageUrls: _imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },

            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}



class FullImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullImageView({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<FullImageView> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${_currentIndex + 1} / ${widget.imageUrls.length}",
        ),
      ),
      body: Stack(
        children: [
          // Swipe detection
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _nextImage(); // swipe left
              } else if (details.primaryVelocity! > 0) {
                _previousImage(); // swipe right
              }
            },
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[_currentIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Previous button
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
              onPressed: _currentIndex > 0 ? _previousImage : null,
            ),
          ),

          // Next button
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white),
              onPressed:
              _currentIndex < widget.imageUrls.length - 1 ? _nextImage : null,
            ),
          ),
        ],
      ),
    );
  }
}

