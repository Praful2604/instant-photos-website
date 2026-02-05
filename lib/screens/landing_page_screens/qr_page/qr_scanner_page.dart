/*

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:major_project_website/screens/landing_page_screens/hero_section.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../customer_auth_pages/customer_login_page.dart';
import '../home_page.dart';
import 'user_choice_selection_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String result = "No QR code scanned yet";
  bool isScanning = false;
  final TextEditingController manualCodeController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? eventData;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  Future<void> _checkAuthentication() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');

    setState(() {
      _isAuthenticated = user != null && userRole == 'customer';
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController.dispose();
    manualCodeController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!mounted) return;
      final scannedCode = scanData.code?.trim() ?? "No data found";
      setState(() {
        result = scannedCode;
        eventData = null;
      });
      _fetchEventData(scannedCode, navigateOnMatch: true); // navigate if match
    });
  }

  void _switchToScanMode() {
    setState(() {
      isScanning = true;
      eventData = null;
    });
    controller?.resumeCamera();
  }

  void _switchToManualMode() {
    setState(() {
      isScanning = false;
      eventData = null;
    });
    controller?.pauseCamera();
  }

  void _submitManualCode() {
    final code = manualCodeController.text.trim();
    if (code.isNotEmpty) {
      setState(() {
        result = code;
        eventData = null;
      });
      _fetchEventData(code, navigateOnMatch: true); // navigate if match
    }
  }

  Future<void> _fetchEventData(String qrCode,
      {bool navigateOnMatch = false}) async {
    try {
      final cleanCode = qrCode.trim();
      final querySnapshot = await _firestore
          .collection('events')
          .where('qr_code', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            eventData = data;
          });
          // Navigate if a match is found and required
          if (navigateOnMatch) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChoiceSelectionPage(
                  initialQrCode: qrCode,
                  eventName: data['event_name'] ?? 'Event',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            eventData = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching event by QR code: $e');
      if (mounted) {
        setState(() {
          eventData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication first
    if (!_isAuthenticated) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFdbeafe), Color(0xFF60a5fa)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You need to login first to access the QR Scanner.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerLoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Go to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFdbeafe), Color(0xFF60a5fa)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animation.json',
                  height: screenHeight * 0.18,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _buildModeButton(
                        title: 'Scan QR Code',
                        selected: isScanning,
                        onPressed: _switchToScanMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _buildModeButton(
                        title: 'Enter Manually',
                        selected: !isScanning,
                        onPressed: _switchToManualMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isScanning)
                  Container(
                    height: screenHeight * 0.35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: QRView(
                        key: qrKey,
                        onQRViewCreated: _onQRViewCreated,
                        overlay: QrScannerOverlayShape(
                          borderColor: Colors.deepPurple,
                          borderRadius: 10,
                          borderLength: 20,
                          borderWidth: 8,
                          cutOutSize: screenWidth * 0.5,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: manualCodeController,
                        decoration: InputDecoration(
                          labelText: 'Enter QR Code',
                          hintText: 'Paste or type your code here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _submitManualCode,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Submit Code',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        const Text(
                          'Scanned Result:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          result,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (eventData != null) ...[
                          const Divider(),
                          Text(
                            'Event Name: ${eventData!['name'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),

                        ] else if (result != "No QR code scanned yet") ...[
                          const SizedBox(height: 10),
                          const Text(
                            'No event found for this QR code.',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (result != "No QR code scanned yet")
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        if (eventData != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChoiceSelectionPage(
                                initialQrCode: result,
                                eventName: eventData!['event_name'] ?? 'Event',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.2,
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'GO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.indigo : Colors.grey[400],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: selected ? 5 : 1,
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
*/