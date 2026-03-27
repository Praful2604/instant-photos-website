import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_page.dart';

class NewEventPage extends StatefulWidget {
  const NewEventPage({super.key});

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _eventNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _qrCode;
  String? _qrUrl;
  bool _isQRGenerated = false;
  bool _showQR = false;
  bool _isLoading = false;
  bool _isGenerating = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const String baseUrl = "https://instantphotos.com";

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _eventNameController.dispose();
    super.dispose();
  }

  String buildQrUrl(String qrId) => "$baseUrl/$qrId";

  Future<bool> _hasQuota() async {
    final email = _auth.currentUser?.email;
    if (email == null) return false;
    final eventsSnap = await _firestore
        .collection('events')
        .where('email', isEqualTo: email)
        .get();
    final subDoc =
        await _firestore.collection('subscriptions').doc(email).get();
    final totalQuota = (subDoc.data()?['total_quota'] ?? 2) as int;
    return eventsSnap.docs.length < totalQuota;
  }

  void _generateQR() async {
    final name = _eventNameController.text.trim();
    if (name.isEmpty) {
      _showSnack("Please enter an event name", isError: true);
      return;
    }

    setState(() => _isGenerating = true);
    final allowed = await _hasQuota();
    setState(() => _isGenerating = false);

    if (!allowed) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Event Limit Reached',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'You have used all your free events.\nUpgrade your plan to create more events.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionPage()));
              },
              child: const Text('View Plans',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final randomId = (Random().nextInt(900000) + 100000).toString();
    setState(() {
      _qrCode = randomId;
      _qrUrl = buildQrUrl(randomId);
      _isQRGenerated = true;
      _showQR = false;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showQR = true);
        _animController.forward(from: 0);
      }
    });
  }

  Future<void> _saveEvent() async {
    if (_qrCode == null || _qrUrl == null) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('events').add({
        'name': _eventNameController.text.trim(),
        'qr_code': _qrCode,
        'qr_url': _qrUrl,
        'email': _auth.currentUser?.email,
        'created_at': Timestamp.now(),
      });
      _showSnack("Event saved successfully!");
      setState(() {
        _eventNameController.clear();
        _qrCode = null;
        _qrUrl = null;
        _isQRGenerated = false;
        _showQR = false;
      });
      _animController.reset();
    } catch (e) {
      _showSnack("Error saving event: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Create Event',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _inputCard(),
                const SizedBox(height: 24),
                if (_isGenerating)
                  const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7F00FF))),
                if (_isQRGenerated && !_showQR && !_isGenerating)
                  Center(
                    child: Lottie.asset('assets/generateqr.json',
                        height: 180, repeat: false),
                  ),
                if (_showQR && _qrUrl != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _qrCard(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Details',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Enter a name and generate your QR code',
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _eventNameController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Riya & Arjun Wedding',
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
              prefixIcon:
                  const Icon(Icons.event_rounded, color: Color(0xFFE100FF)),
              filled: true,
              fillColor: const Color(0xFF0F3460),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF7F00FF), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  (_isQRGenerated || _isGenerating) ? null : _generateQR,
              icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
              label: Text('Generate QR Code',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F00FF),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7F00FF), Color(0xFFE100FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_eventNameController.text.trim(),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    Text('QR ID: $_qrCode',
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7F00FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: _qrUrl!,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // URL row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    color: Color(0xFFE100FF), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_qrUrl!,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrUrl!));
                    _showSnack('URL copied!');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveEvent,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded,
                      color: Colors.white),
              label: Text(_isLoading ? 'Saving...' : 'Save Event',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
