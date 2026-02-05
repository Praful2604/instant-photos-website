import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewEventPage extends StatefulWidget {
  const NewEventPage({super.key});

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  final TextEditingController _eventNameController = TextEditingController();

  String? _qrCode; // numeric ID (123456)
  String? _qrUrl;  // https://instantphotos.com/123456

  bool _isQRGenerated = false;
  bool _showQR = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🌐 YOUR DOMAIN
  static const String baseUrl = "https://instantphotos.com";

  // ======================================================
  // 🔁 SHARED LOGIC — SINGLE SOURCE OF TRUTH
  // ======================================================
  String buildQrUrl(String qrId) {
    return "$baseUrl/$qrId";
  }

  // ======================================================
  // GENERATE QR
  // ======================================================
  void _generateQR() {
    final name = _eventNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event Name is required")),
      );
      return;
    }

    final randomId = (Random().nextInt(900000) + 100000).toString();

    setState(() {
      _qrCode = randomId;
      _qrUrl = buildQrUrl(randomId); // ✅ SHARED LOGIC
      _isQRGenerated = true;
      _showQR = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showQR = true);
    });
  }

  // ======================================================
  // SAVE EVENT
  // ======================================================
  Future<void> _saveEvent() async {
    if (_qrCode == null || _qrUrl == null) return;

    final user = _auth.currentUser;
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('events').add({
        'name': _eventNameController.text.trim(),
        'qr_code': _qrCode, // numeric
        'qr_url': _qrUrl,   // full URL
        'email': user?.email,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event saved successfully")),
      );

      setState(() {
        _eventNameController.clear();
        _qrCode = null;
        _qrUrl = null;
        _isQRGenerated = false;
        _showQR = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Event"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: "Event Name",
                prefixIcon: Icon(Icons.event),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text("Generate QR"),
              onPressed: _isQRGenerated ? null : _generateQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
            ),

            const SizedBox(height: 30),

            if (_isQRGenerated && !_showQR)
              Lottie.asset(
                'assets/generateqr.json',
                height: 200,
                repeat: false,
              ),

            if (_showQR && _qrUrl != null) ...[
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Scan This QR",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// ✅ QR STORES FULL URL
                      QrImageView(
                        data: _qrUrl!,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "QR ID: $_qrCode",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _qrUrl!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: const Text("Save Event"),
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
