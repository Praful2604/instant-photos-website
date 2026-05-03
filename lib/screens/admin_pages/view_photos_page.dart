import 'dart:convert';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:html' as html;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewPhotosPage extends StatefulWidget {
  const ViewPhotosPage({Key? key}) : super(key: key);

  @override
  State<ViewPhotosPage> createState() => _ViewPhotosPageState();
}

class _ViewPhotosPageState extends State<ViewPhotosPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController qrController = TextEditingController();

  bool isCheckingQr = false;
  bool? isQrValid;
  bool isMatching = false;

  List<String> matchedImageUrls = [];

  final String backendBaseUrl = "http://localhost:5000";

  late AnimationController _fabController;

  // CAMERA (WEB)
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  bool isCameraStarted = false;

  @override
  void initState() {
    super.initState();

    _fabController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    // Register camera view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'camera-video',
          (int viewId) => _videoElement!,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ---------------- START CAMERA ----------------
  Future<void> startCamera() async {
    final stream = await html.window.navigator.mediaDevices!
        .getUserMedia({'video': {'facingMode': 'user'}});

    _videoElement = html.VideoElement()
      ..srcObject = stream
      ..autoplay = true
      ..style.objectFit = 'contain';

    _canvasElement = html.CanvasElement();

    setState(() => isCameraStarted = true);
  }

  // ---------------- CHECK QR ----------------
  Future<void> checkQrValidity() async {
    final code = qrController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      isCheckingQr = true;
      isQrValid = null;
      matchedImageUrls.clear();
    });

    try {
      final res = await http.get(
        Uri.parse("$backendBaseUrl/check-qr?qr_code=$code"),
      );

      final data = json.decode(res.body);

      setState(() {
        isQrValid = data["valid"] == true;
      });

      if (isQrValid == true) {
        await startCamera();
      }
    } catch (e) {
      setState(() => isQrValid = false);
    } finally {
      setState(() => isCheckingQr = false);
    }
  }

  // ---------------- CAPTURE & MATCH ----------------
  Future<void> captureAndMatchFace() async {
    if (_videoElement == null) return;

    setState(() {
      isMatching = true;
      matchedImageUrls.clear();
    });

    try {
      _canvasElement!
        ..width = _videoElement!.videoWidth
        ..height = _videoElement!.videoHeight;

      final ctx = _canvasElement!.context2D;
      ctx.drawImage(_videoElement!, 0, 0);

      final blob = await _canvasElement!.toBlob('image/jpeg');

      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob!);
      await reader.onLoad.first;

      final bytes = reader.result as List<int>;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$backendBaseUrl/face-match"),
      );

      request.fields["qr_code"] = qrController.text.trim();

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: "selfie.jpg",
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          matchedImageUrls = List<String>.from(json.decode(body));
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(body)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isMatching = false);
    }
  }

  // ---------------- DOWNLOAD ----------------
  Future<void> downloadAllImages() async {
    if (matchedImageUrls.isEmpty) return;

    final archive = Archive();

    for (int i = 0; i < matchedImageUrls.length; i++) {
      final res = await http.get(Uri.parse(matchedImageUrls[i]));
      if (res.statusCode == 200) {
        archive.addFile(ArchiveFile(
          'photo_${i + 1}.jpg',
          res.bodyBytes.length,
          res.bodyBytes,
        ));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) return;

    final blob = html.Blob([zipBytes], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', '${qrController.text}.zip')
      ..click();

    html.Url.revokeObjectUrl(url);
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
      title: const Text("Your Event Photos"),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (matchedImageUrls.isNotEmpty)
          TextButton.icon(
            onPressed: downloadAllImages,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text("Download All",
                style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3a7bd5), Color(0xFF00d2ff)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGlassCard(),
            const SizedBox(height: 20),

            if (isQrValid == true && isCameraStarted)
              _buildCameraPreview(),

            const SizedBox(height: 10),

            Expanded(child: _buildImageGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              TextField(
                controller: qrController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Enter Event Code",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: isCheckingQr ? null : checkQrValidity,
                child: isCheckingQr
                    ? const CircularProgressIndicator()
                    : const Text("Verify Event"),
              ),
              const SizedBox(height: 10),
              if (isQrValid != null)
                Text(
                  isQrValid! ? "Event Verified ✅" : "Invalid Code ❌",
                  style: TextStyle(
                    color: isQrValid! ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white54),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: HtmlElementView(viewType: 'camera-video'),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (isMatching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (matchedImageUrls.isEmpty) {
      return const Center(
        child: Text(
          "Your photos will appear here 📸",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
      ),
      itemCount: matchedImageUrls.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          matchedImageUrls[i],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAnimatedFab() {
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.1).animate(_fabController),
      child: FloatingActionButton.extended(
        onPressed: isMatching ? null : captureAndMatchFace,
        label: const Text("Find My Photos"),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }
}