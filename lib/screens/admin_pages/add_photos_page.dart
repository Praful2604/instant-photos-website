import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pool/pool.dart'; // Add this to pubspec.yaml

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

  // Progress tracking
  int _totalToUpload = 0;
  int _completedUploads = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Limits simultaneous uploads to 5 at a time
  final _uploadPool = Pool(5);

  @override
  void initState() {
    super.initState();
    _loadUploadedImages();
  }

  /// COMPRESSION LOGIC: Shrinks 30MB to ~1-2MB
  Future<Uint8List?> _compressImage(PlatformFile file) async {
    try {
      Uint8List bytes = file.bytes ?? await io.File(file.path!).readAsBytes();

      return await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1920, // Full HD Height
        minWidth: 1080,  // Full HD Width
        quality: 80,     // 80% is the "sweet spot" for quality vs size
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint("Compression failed for ${file.name}: $e");
      return null;
    }
  }

  Future<void> _loadUploadedImages() async {
    try {
      final result = await _storage.ref('event-images/${widget.qrCode}').listAll();
      final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));
      setState(() => _uploadedImageUrls = urls);
    } catch (e) {
      debugPrint('Error loading images: $e');
    }
  }

  Future<void> pickImages() async {
    if (!kIsWeb && await Permission.storage.request().isDenied) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true, // Crucial for Web & Compression
    );

    if (result != null) {
      setState(() => _selectedFiles = result.files);
    }
  }

  /// THE CORE UPLOAD LOGIC
  Future<void> uploadImages() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _totalToUpload = _selectedFiles.length;
      _completedUploads = 0;
    });

    final user = _auth.currentUser;
    List<Future> uploadTasks = [];

    for (var file in _selectedFiles) {
      // We use the 'pool' to wrap each upload task
      uploadTasks.add(_uploadPool.withResource(() async {
        try {
          // 1. Compress
          final compressedBytes = await _compressImage(file);
          if (compressedBytes == null) return;

          // 2. Upload to Storage (Using same location as before)
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
          final filePath = "event-images/${widget.qrCode}/$fileName";
          final ref = _storage.ref(filePath);

          await ref.putData(
              compressedBytes,
              SettableMetadata(contentType: 'image/jpeg')
          );

          final publicUrl = await ref.getDownloadURL();

          // 3. Save to Firestore
          if (user != null) {
            await _firestore.collection('event_images').add({
              'url': publicUrl,
              'qr_code': widget.qrCode,
              'uploaded_by': user.uid,
              'uploaded_at': FieldValue.serverTimestamp(),
            });
          }

          setState(() {
            _completedUploads++;
            _uploadedImageUrls.add(publicUrl);
          });
        } catch (e) {
          debugPrint("Failed to upload ${file.name}: $e");
        }
      }));
    }

    // Wait for all 700 (queued 5 at a time) to finish
    await Future.wait(uploadTasks);

    setState(() {
      _isUploading = false;
      _selectedFiles.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All uploads complete!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalToUpload > 0 ? _completedUploads / _totalToUpload : 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Photos (Bulk)"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (_isUploading) ...[
              LinearProgressIndicator(value: progress),
              Text("Uploading $_completedUploads of $_totalToUpload photos..."),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _isUploading ? null : pickImages, child: const Text("Select Images")),
                ElevatedButton(
                  onPressed: _isUploading || _selectedFiles.isEmpty ? null : uploadImages,
                  child: const Text("Start Bulk Upload"),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                itemCount: _uploadedImageUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemBuilder: (context, index) => Image.network(_uploadedImageUrls[index], fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}