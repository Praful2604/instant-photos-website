import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html; // for web

class UploadSelfiePage extends StatefulWidget {
  const UploadSelfiePage({Key? key, required String qrCode}) : super(key: key);

  @override
  State<UploadSelfiePage> createState() => _UploadSelfiePageState();
}

class _UploadSelfiePageState extends State<UploadSelfiePage> {
  Uint8List? _selfieBytes;
  bool _uploading = false;
  String? _uploadedUrl;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick image from camera or file picker (web/mobile)
  Future<void> _pickSelfie() async {
    Uint8List? bytes;
    String filename = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      bytes = reader.result as Uint8List;
      filename = file.name;
    } else {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked == null) return;
      final file = io.File(picked.path);
      bytes = await file.readAsBytes();
      filename = picked.name;
    }

    setState(() => _selfieBytes = bytes);
  }

  /// Upload the selfie to Firebase Storage
  Future<void> _uploadToFirebase() async {
    if (_selfieBytes == null) return;

    setState(() => _uploading = true);
    try {
      final path = 'selfies/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path);

      await ref.putData(_selfieBytes!, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection('selfies').add({
        'url': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _uploadedUrl = downloadUrl;
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selfie uploaded successfully!")),
      );
    } catch (e) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  /// Optional: Send selfie URL to backend (Flask server)
  Future<void> _sendToBackend() async {
    if (_uploadedUrl == null) return;

    try {
      final response = await http.post(
        Uri.parse('http:///10.158.10.8:5000/save-selfie'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selfie_url': _uploadedUrl}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selfie sent to backend successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backend error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending to backend: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Selfie"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F5F9),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _selfieBytes == null
                ? const CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Image.memory(
                _selfieBytes!,
                height: 160,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickSelfie,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture / Select Selfie"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            if (_selfieBytes != null)
              ElevatedButton.icon(
                onPressed: _uploading ? null : _uploadToFirebase,
                icon: const Icon(Icons.cloud_upload),
                label: Text(_uploading ? "Uploading..." : "Upload to Firebase"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            const SizedBox(height: 20),
            if (_uploadedUrl != null)
              Column(
                children: [
                  const Text(
                    "Uploaded successfully!",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedUrl!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _sendToBackend,
                    icon: const Icon(Icons.send),
                    label: const Text("Send to Backend"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
