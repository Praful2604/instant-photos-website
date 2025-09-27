import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ViewPhotosPage extends StatefulWidget {
  final String qrCode;
  const ViewPhotosPage({super.key, required this.qrCode, required eventName});

  @override
  State<ViewPhotosPage> createState() => _ViewPhotosPageState();
}

class _ViewPhotosPageState extends State<ViewPhotosPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<String> _imageUrls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _imageUrls.clear();
    });
    try {
      final ListResult result = await _storage.ref('event-images/${widget.qrCode}').listAll();

      final urls = await Future.wait(result.items.map((ref) async {
        try {
          final url = await ref.getDownloadURL();
          debugPrint('Fetched URL: $url');
          return url;
        } catch (e) {
          debugPrint('Failed to get download URL for ${ref.fullPath}: $e');
          return null;
        }
      }));

      // Remove null URLs
      final filteredUrls = urls.whereType<String>().toList();

      setState(() {
        _imageUrls = filteredUrls;
        _isLoading = false;
        _error = filteredUrls.isEmpty ? 'No accessible images found' : null;
      });
    } catch (e) {
      debugPrint('Error loading images: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load photos. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Uploaded Photos"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchImages,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchImages,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_imageUrls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 50, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No photos found for this QR code',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageItem(_imageUrls[index]);
      },
    );
  }

  Widget _buildImageItem(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image.network error loading $url: $error');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
