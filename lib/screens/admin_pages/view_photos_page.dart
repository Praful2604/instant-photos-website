import 'dart:convert';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ViewPhotosPage extends StatefulWidget {
  const ViewPhotosPage({Key? key}) : super(key: key);

  @override
  State<ViewPhotosPage> createState() => _ViewPhotosPageState();
}

class _ViewPhotosPageState extends State<ViewPhotosPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker picker = ImagePicker();
  final TextEditingController qrController = TextEditingController();

  bool isCheckingQr = false;
  bool? isQrValid;
  bool isMatching = false;
  List<String> matchedImageUrls = [];

  final String backendBaseUrl = "http://127.0.0.1:8000";
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ---------------- DOWNLOAD ----------------
  void downloadImage(String url, String fileName) {
    if (kIsWeb) {
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
    }
  }

  void downloadAllImages() {
    for (int i = 0; i < matchedImageUrls.length; i++) {
      downloadImage(matchedImageUrls[i], "event_photo_${i + 1}.jpg");
    }
  }

  // ---------------- API ----------------
  Future<void> checkQrValidity() async {
    final code = qrController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      isCheckingQr = true;
      isQrValid = null;
      matchedImageUrls.clear();
    });

    try {
      final res =
      await http.get(Uri.parse("$backendBaseUrl/check-qr?qr_code=$code"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => isQrValid = data["valid"] == true);
      }
    } catch (_) {
      setState(() => isQrValid = false);
    } finally {
      setState(() => isCheckingQr = false);
    }
  }

  Future<void> pickAndMatchFace() async {
    final XFile? picked = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      isMatching = true;
      matchedImageUrls.clear();
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$backendBaseUrl/face-match"),
      );
      request.fields["qr_code"] = qrController.text.trim();
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await picked.readAsBytes(),
          filename: picked.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        setState(() {
          matchedImageUrls = List<String>.from(json.decode(body));
        });
      }
    } catch (_) {
    } finally {
      setState(() => isMatching = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBackground(),
      floatingActionButton:
      isQrValid == true ? _buildAnimatedFab() : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Your Event Photos",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (matchedImageUrls.isNotEmpty)
          TextButton.icon(
            onPressed: downloadAllImages,
            icon: const Icon(Icons.download, color: Colors.white),
            label:
            const Text("Download All", style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3a7bd5), Color(0xFF00d2ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGlassCard(),
            const SizedBox(height: 20),
            Expanded(child: _buildImageGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            children: [
              TextField(
                controller: qrController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Event Code",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                  const Icon(Icons.qr_code_rounded, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() => isQrValid = null),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isCheckingQr ? null : checkQrValidity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isCheckingQr
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text(
                    "Verify Event",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isQrValid == null
                    ? const SizedBox.shrink()
                    : Padding(
                  key: ValueKey(isQrValid),
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isQrValid!
                            ? Icons.verified_rounded
                            : Icons.error_outline,
                        color: isQrValid!
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isQrValid!
                            ? "Event Verified"
                            : "Invalid Event Code",
                        style: TextStyle(
                          color: isQrValid!
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (isMatching) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent));
    }

    if (matchedImageUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_library_outlined,
                size: 90, color: Colors.white30),
            SizedBox(height: 12),
            Text(
              "Your memories will appear here ✨",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: matchedImageUrls.length,
      itemBuilder: (_, i) => Hero(
        tag: "img_$i",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            matchedImageUrls[i],
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFab() {
    return ScaleTransition(
      scale: Tween(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: isMatching ? null : pickAndMatchFace,
        icon: const Icon(Icons.face_retouching_natural, color: Colors.black),
        label: const Text(
          "Find My Photos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
