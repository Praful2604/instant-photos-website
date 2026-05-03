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
  // Store both the download URL and the storage Reference together
  List<({String url, Reference ref})> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final result = await _storage.ref('event-images/${widget.qrCode}').listAll();
      final photos = await Future.wait(
        result.items.map((ref) async => (url: await ref.getDownloadURL(), ref: ref)),
      );
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _photos[index].ref.delete();
      setState(() => _photos.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Photos – ${widget.qrCode}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7F00FF), Color(0xFFE100FF)]),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
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
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullImageView(
                            imageUrls: _photos.map((p) => p.url).toList(),
                            initialIndex: index,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _photos[index].url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                              },
                            ),
                            // Delete button overlay
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _deletePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
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

