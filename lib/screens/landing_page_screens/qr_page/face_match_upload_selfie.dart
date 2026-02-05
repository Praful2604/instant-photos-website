import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:firebase_auth/firebase_auth.dart';

// Web-specific import, used only on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FaceMatchUploadPage extends StatefulWidget {
  final String qrCode;

  const FaceMatchUploadPage({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<FaceMatchUploadPage> createState() => _FaceMatchUploadPageState();
}

class _FaceMatchUploadPageState extends State<FaceMatchUploadPage> {
  Uint8List? _selfieBytes;
  bool _isUploading = false;
  List<String> _matchedUrls = [];
  bool _hasUploaded = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickSelfie() async {
    if (_hasUploaded) return; // Prevent recapture after upload

    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      setState(() => _selfieBytes = reader.result as Uint8List);
    } else {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _selfieBytes = bytes);
    }
  }

  Future<void> _uploadForFaceMatch() async {
    if (_selfieBytes == null) return;

    setState(() {
      _isUploading = true;
    });

    final uri = Uri.parse('http://127.0.0.1:5000/face-match'); // replace with your deployed Flask URL

    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
    final idToken = await user!.getIdToken(true);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['qr_code'] = widget.qrCode
      ..files.add(http.MultipartFile.fromBytes(
        'selfie',
        _selfieBytes!,
        filename: 'selfie.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        List<dynamic> urlsJson = jsonDecode(response.body);
        List<String> urls = urlsJson.map((e) => e.toString()).toList();

        setState(() {
          _matchedUrls = urls;
          _isUploading = false;
          _hasUploaded = true;
        });
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matching failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Selfie for Face Match')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 80),
                _selfieBytes != null
                    ? Image.memory(_selfieBytes!, width: 160, height: 160)
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Selfie"),
                  onPressed: _hasUploaded ? null : _pickSelfie,
                ),
                const SizedBox(height: 20),
                if (_selfieBytes != null && !_isUploading && !_hasUploaded)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.face),
                    label: const Text("Find My Photos"),
                    onPressed: _uploadForFaceMatch,
                  ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                if (_matchedUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        const Text(
                          "Matched Photos:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _matchedUrls.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_matchedUrls[index], fit: BoxFit.cover),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Show uploaded selfie thumbnail on top-left corner
          if (_hasUploaded && _selfieBytes != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selfieBytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
