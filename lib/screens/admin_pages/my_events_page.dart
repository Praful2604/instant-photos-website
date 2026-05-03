import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project_website/screens/admin_pages/add_photos_page.dart';
import 'package:major_project_website/screens/admin_pages/digital_album_upload_page.dart';
import 'package:major_project_website/screens/admin_pages/client_details_Page.dart';
import 'package:major_project_website/screens/admin_pages/view_all_photos.dart';
import 'package:major_project_website/screens/client_pages/gallery_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userEmail;

  final Map<String, GlobalKey> _qrKeys = {};

  static const String baseQrUrl = "https://instantphotos.com";
  static const String albumBaseUrl =
      "https://flipbook-eight-nu.vercel.app/album/";

  String buildQrUrl(String qrCode) => "$baseQrUrl/$qrCode";

  void open3DAlbum(String qrCode) {
    final url = "$albumBaseUrl/$qrCode";
    html.window.open(url, '_blank');
  }

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  void _getUserEmail() {
    final user = _auth.currentUser;
    if (user?.email != null) {
      setState(() => _userEmail = user!.email);
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    if (_userEmail == null) return [];

    final snapshot = await _firestore
        .collection('events')
        .where('email', isEqualTo: _userEmail)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((e) => e.data()).toList();
  }

  Future<void> _downloadQr(String qrCode, String eventName) async {
    try {
      final key = _qrKeys[qrCode];
      if (key == null) return;

      final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      final blob = html.Blob([byteData!.buffer.asUint8List()]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", "${eventName}_QR.png")
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(String qrCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text(
          "Are you sure you want to delete this event?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteEvent(qrCode);
    }
  }

  Future<void> _deleteEvent(String qrCode) async {
    final snapshot = await _firestore
        .collection('events')
        .where('qr_code', isEqualTo: qrCode)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Event deleted", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );

    setState(() {});
  }

  Future<void> _shareEventLink(String qrCode, String eventName) async {
    Share.share(
      'Check out photos from "$eventName": ${buildQrUrl(qrCode)}',
    );
  }

  // ---------------- WHATSAPP SHARE (NEW, NO EXISTING CODE TOUCHED) ----------------
  Future<void> _shareOnWhatsApp(String qrCode, String eventName) async {
    final viewPhotosUrl = buildQrUrl(qrCode);
    final albumUrl = "$albumBaseUrl/$qrCode";

    final message = '''
📸 Event: $eventName

🔗 View Photos:
$viewPhotosUrl

📖 3D Album:
$albumUrl
''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = "https://wa.me/?text=$encodedMessage";

    html.window.open(whatsappUrl, '_blank');
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String qrCode, String eventName) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        _actionButton(
          icon: Icons.add_a_photo,
          label: "Add Photos",
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPhotosPage(qrCode: qrCode),
            ),
          ),
        ),
        _actionButton(
          icon: Icons.photo_library,
          label: "3D Album",
          gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          onTap: () => open3DAlbum(qrCode),
        ),
        _actionButton(
          icon: Icons.auto_stories_rounded,
          label: "Digital Album",
          gradient: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DigitalAlbumUploadPage(qrCode: qrCode, eventName: eventName),
            ),
          ),
        ),
        _actionButton(
          icon: Icons.panorama,
          label: "View Photos",
          gradient: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewAllPhotos(qrCode: qrCode),
            ),
          ),
        ),
        _actionButton(
          icon: Icons.details,
          label: "Client Info",
          gradient: [Color(0xFF203A43), Color(0xFF2C5364)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClientDetailsPage(qrCode: qrCode, eventName: eventName),
            ),
          ),
        ),
        _actionButton(
          icon: Icons.share,
          label: "Share",
          gradient: [Color(0xFF25D366), Color(0xFF128C7E)],
          onTap: () => _shareOnWhatsApp(qrCode, eventName),
        ),
        _actionButton(
          icon: Icons.favorite,
          label: "Favourite Photos",
          gradient: [Colors.redAccent, Colors.red],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GalleryPage(qrCode: qrCode, eventName: eventName),
            ),
          ),
        ),

        _actionButton(
          icon: Icons.download,
          label: "Download",
          gradient: [Colors.green, Colors.teal],
          onTap: () => _downloadQr(qrCode, eventName),
        ),

        // _actionButton(
        //   icon: Icons.delete,
        //   label: "Delete",
        //   gradient: [Colors.redAccent, Colors.red],
        //   onTap: () => _confirmDelete(qrCode),
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("My Events",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                "No events found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final name = event['name'] ?? '';
              final qrCode = event['qr_code'] ?? '';

              _qrKeys.putIfAbsent(qrCode, () => GlobalKey());

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16,
                        offset: Offset(0, 6))
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RepaintBoundary(
                      key: _qrKeys[qrCode],
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            QrImageView(
                              data: buildQrUrl(qrCode),
                              size: 140,
                            ),
                            const SizedBox(height: 6),
                            Text(qrCode),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    _buildActionButtons(qrCode, name),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
