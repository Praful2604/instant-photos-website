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
  String? _qrData;
  String? _qrcode;
  bool _isQRGenerated = false;
  bool _showQR = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _generateQR() {
    final name = _eventNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event Name is required!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final randomId = Random().nextInt(900000) + 100000;

    setState(() {
      _qrcode = randomId.toString();
      _qrData = "Event: $name | ID: $_qrcode";
      _isQRGenerated = true;
      _showQR = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showQR = true;
        });
      }
    });
  }

  Future<void> _saveToFirestore() async {
    if (_qrData == null || _qrcode == null || _eventNameController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('events').add({
        'name': _eventNameController.text.trim(),
        'qr_code': _qrcode,
        'email': user?.email ?? 'unknown',
        'created_at': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Event saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _eventNameController.clear();
        _isQRGenerated = false;
        _showQR = false;
        _qrData = null;
        _qrcode = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving event: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double buttonHeight = screenWidth > 600 ? 50 : 45;
    double buttonWidth = screenWidth > 600 ? 200 : 150;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Event"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(
                    labelText: "Event Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('Generate QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: Size(buttonWidth, buttonHeight),
                ),
                onPressed: _isQRGenerated ? null : _generateQR,
              ),
            ),
            const SizedBox(height: 30),
            if (_isQRGenerated && !_showQR)
              Lottie.asset(
                'assets/generateqr.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
            if (_showQR && _qrData != null && _qrcode != null) ...[
              Card(
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Scan This QR",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "QR ID: $_qrcode",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    minimumSize: Size(buttonWidth, buttonHeight),
                  ),
                  onPressed: _isLoading ? null : _saveToFirestore,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
