import 'package:flutter/material.dart';
import 'package:major_project_website/screens/admin_pages/add_photos_page.dart';
import 'package:major_project_website/screens/admin_pages/album_images.dart';
import 'package:major_project_website/screens/admin_pages/client_details_Page.dart';
import 'package:major_project_website/screens/admin_pages/view_photos_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  void _getUserEmail() {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _userEmail = user.email!;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No user logged in"), backgroundColor: Colors.red),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    if (_userEmail == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('email', isEqualTo: _userEmail)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  Future<void> _deleteEvent(String qrCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('qr_code', isEqualTo: qrCode)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Event deleted successfully"),
            backgroundColor: Colors.red),
      );

      setState(() {}); // Refresh the list after deletion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error deleting event: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareEventLink(String qrCode, String eventName) async {
    final link =
        'https://instantphotoss.netlify.app/event-images?qrCode=$qrCode&eventName=${Uri.encodeComponent(eventName)}';

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/whatsapp.png',
                  width: 24,
                  height: 24,
                  color: Colors.green,
                ),
                title: const Text('Share via WhatsApp'),
                onTap: () async {
                  Navigator.pop(context);
                  final whatsappUrl =
                      'whatsapp://send?text=${Uri.encodeComponent('Check out photos from "$eventName": $link')}';
                  try {
                    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                      await launchUrl(Uri.parse(whatsappUrl));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp not installed')),
                      );
                      await Share.share(
                          'Check out photos from "$eventName": $link',
                          subject: 'Photos from $eventName');
                    }
                  } catch (e) {
                    debugPrint('Error sharing via WhatsApp: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.purple),
                title: const Text('Share via Other Apps'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share('Check out photos from "$eventName": $link',
                      subject: 'Photos from $eventName');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String qrCode, String eventName) {
    return Wrap(
      spacing: 10,
      alignment: WrapAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddPhotosPage(qrCode: qrCode)),
            );
          },
          icon: const Icon(Icons.add_a_photo, color: Colors.green),
          tooltip: "Add Photo",
        ),
        IconButton(
          onPressed: () {
            // Add your navigation or logic here
          },
          icon: const Icon(Icons.view_in_ar, color: Colors.blue),
          tooltip: "Add 3D Album Photos",
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumImages(qrCode: qrCode, eventName: '',),
                ));
          },
          icon: const Icon(Icons.photo_library, color: Colors.orange),
          tooltip: "View 3D Album",
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPhotosPage(qrCode: qrCode, eventName: '',),
                ));
          },
          icon: const Icon(Icons.panorama, color: Colors.orange),
          tooltip: "View Event Images",
        ),
        IconButton(
          onPressed: () {
            // Add your navigation or logic here
          },
          icon: const Icon(Icons.favorite, color: Colors.red),
          tooltip: "Favorite Photos",
        ),
        IconButton(
          onPressed: () {
            // Add your navigation or logic here
          },
          icon: const Icon(Icons.image, color: Colors.blueAccent),
          tooltip: "All Event Photos",
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClientDetailsPage(qrCode: qrCode, eventName: eventName),
                ));
          },
          icon: const Icon(Icons.details, color: Colors.blue),
          tooltip: " Client Details ",
        ),
        IconButton(
          onPressed: () => _shareEventLink(qrCode, eventName),
          icon: const Icon(Icons.share, color: Colors.blue),
          tooltip: "Share Event Link",
        ),
        IconButton(
          onPressed: () => _deleteEvent(qrCode),
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: "Delete Event",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userEmail == null) {
      // Show loading or message while fetching user email
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Events"),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No events found."));
          }

          final events = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final String name = event['name'] ?? '';
              final String qrCode = event['qr_code'] ?? '';

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  return Card(
                    elevation: 5,
                    margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          QrImageView(
                            data: qrCode,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Code: $qrCode",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 10),
                          _buildActionButtons(qrCode, name),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          QrImageView(
                            data: qrCode,
                            size: 120,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Code: $qrCode",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 10),
                                _buildActionButtons(qrCode, name),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
