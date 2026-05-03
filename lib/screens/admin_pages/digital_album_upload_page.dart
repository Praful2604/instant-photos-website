import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pool/pool.dart';

class DigitalAlbumUploadPage extends StatefulWidget {
  final String qrCode;
  final String eventName;

  const DigitalAlbumUploadPage({
    super.key,
    required this.qrCode,
    required this.eventName,
  });

  @override
  State<DigitalAlbumUploadPage> createState() => _DigitalAlbumUploadPageState();
}

class _DigitalAlbumUploadPageState extends State<DigitalAlbumUploadPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uploadPool = Pool(5);

  List<PlatformFile> _selectedFiles = [];
  List<({String url, Reference ref})> _uploadedPhotos = [];
  bool _isUploading = false;
  bool _isLoading = true;
  int _totalToUpload = 0;
  int _completedUploads = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }

  Future<void> _loadExistingPhotos() async {
    try {
      final result = await _storage
          .ref('digital-album-imgs/${widget.qrCode}')
          .listAll();
      final photos = await Future.wait(
        result.items.map((ref) async => (url: await ref.getDownloadURL(), ref: ref)),
      );
      setState(() {
        _uploadedPhotos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _compressImage(PlatformFile file) async {
    try {
      final bytes = file.bytes ?? await io.File(file.path!).readAsBytes();
      return await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 1920,
        minWidth: 1080,
        quality: 80,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint("Compression failed: $e");
      return null;
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null) setState(() => _selectedFiles = result.files);
  }

  Future<void> _uploadImages() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _totalToUpload = _selectedFiles.length;
      _completedUploads = 0;
    });

    final tasks = _selectedFiles.map((file) =>
      _uploadPool.withResource(() async {
        try {
          final compressed = await _compressImage(file);
          if (compressed == null) return;

          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final ref = _storage.ref('digital-album-imgs/${widget.qrCode}/$fileName');

          await ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();

          // Save to Firestore in same format as favorites
          await _firestore
              .collection('digital_album')
              .doc(widget.qrCode)
              .collection('imgs')
              .doc(fileName)
              .set({
            'path': 'digital-album-imgs/${widget.qrCode}/$fileName',
            'url': url,
            'time': FieldValue.serverTimestamp(),
          });

          setState(() {
            _completedUploads++;
            _uploadedPhotos.add((url: url, ref: ref));
          });
        } catch (e) {
          debugPrint('Upload failed: $e');
        }
      }),
    );

    await Future.wait(tasks);

    setState(() {
      _isUploading = false;
      _selectedFiles.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All photos uploaded!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from the digital album?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
      final ref = _uploadedPhotos[index].ref;
      // Delete from Storage
      await ref.delete();
      // Delete from Firestore using the file name as doc ID
      final fileName = ref.name;
      await _firestore
          .collection('digital_album')
          .doc(widget.qrCode)
          .collection('imgs')
          .doc(fileName)
          .delete();
      setState(() => _uploadedPhotos.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed'), backgroundColor: Colors.red),
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
    final progress = _totalToUpload > 0 ? _completedUploads / _totalToUpload : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Album', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Upload controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_isUploading) ...[
                        LinearProgressIndicator(value: progress, color: const Color(0xFFFF416C)),
                        const SizedBox(height: 6),
                        Text('Uploading $_completedUploads of $_totalToUpload...',
                            style: GoogleFonts.poppins(fontSize: 13)),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading ? null : _pickImages,
                              icon: const Icon(Icons.photo_library_rounded),
                              label: Text(
                                _selectedFiles.isEmpty
                                    ? 'Select Photos'
                                    : '${_selectedFiles.length} selected',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_isUploading || _selectedFiles.isEmpty) ? null : _uploadImages,
                              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                              label: Text('Upload', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF416C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploadedPhotos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_uploadedPhotos.length} photo${_uploadedPhotos.length == 1 ? '' : 's'} in album',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Photo grid
                Expanded(
                  child: _uploadedPhotos.isEmpty
                      ? Center(
                          child: Text('No photos yet. Add some!',
                              style: GoogleFonts.poppins(color: Colors.grey)),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: _uploadedPhotos.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(_uploadedPhotos[index].url, fit: BoxFit.cover),
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
