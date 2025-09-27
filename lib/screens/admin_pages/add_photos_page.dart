import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPhotosPage extends StatefulWidget {
  final String qrCode;
  const AddPhotosPage({super.key, required this.qrCode});

  @override
  State<AddPhotosPage> createState() => _AddPhotosPageState();
}

class _AddPhotosPageState extends State<AddPhotosPage> {
  List<PlatformFile> _selectedFiles = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUploadedImages();
  }

  Future<void> _loadUploadedImages() async {
    try {
      final ListResult result = await _storage.ref('event-images/${widget.qrCode}').listAll();

      final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));

      setState(() {
        _uploadedImageUrls = urls;
      });
    } catch (e) {
      debugPrint('Error loading uploaded images: $e');
    }
  }

  Future<void> pickImages() async {
    if (!kIsWeb) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied to access storage")),
        );
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> removeUploadedImage(int index) async {
    try {
      final url = _uploadedImageUrls[index];
      final ref = _storage.refFromURL(url);

      await ref.delete();

      setState(() {
        _uploadedImageUrls.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting image: $e")),
      );
    }
  }

  Future<void> uploadImages() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select images first")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    List<String> newDownloadUrls = [];
    final user = _auth.currentUser;

    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      final filePath = "event-images/${widget.qrCode}/$fileName";

      try {
        final fileBytes = kIsWeb
            ? file.bytes!
            : await io.File(file.path!).readAsBytes();

        final ref = _storage.ref(filePath);
        final uploadTask = ref.putData(fileBytes);

        await uploadTask;

        final publicUrl = await ref.getDownloadURL();
        newDownloadUrls.add(publicUrl);

        // Optional: Save metadata to Firestore if you want
        if (user != null) {
          await _firestore.collection('event_images').add({
            'url': publicUrl,
            'qr_code': widget.qrCode,
            'uploaded_by': user.uid,
            'uploaded_at': DateTime.now(),
          });
        }

        setState(() {
          _uploadProgress = (i + 1) / _selectedFiles.length;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload ${file.name}: $e")),
        );
      }
    }

    if (newDownloadUrls.isNotEmpty) {
      setState(() {
        _uploadedImageUrls.addAll(newDownloadUrls);
        _selectedFiles.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Images uploaded successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }

    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Photos"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: pickImages,
                  child: const Text("Select Images"),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : uploadImages,
                  child: Text(_isUploading ? "Uploading..." : "Upload Images"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              Text("${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded"),
              const SizedBox(height: 10),
            ],
            if (_selectedFiles.isNotEmpty) ...[
              const Text(
                "Selected Images (Not Uploaded Yet)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: kIsWeb
                              ? Image.memory(file.bytes!, fit: BoxFit.cover)
                              : Image.file(io.File(file.path!), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 12,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_uploadedImageUrls.isNotEmpty) ...[
              const Text(
                "Uploaded Images",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _uploadedImageUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _uploadedImageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => removeUploadedImage(index),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 12,
                              child: Icon(Icons.delete, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (_selectedFiles.isEmpty && _uploadedImageUrls.isEmpty)
              const Center(child: Text("No images selected or uploaded yet")),
          ],
        ),
      ),
    );
  }
}
