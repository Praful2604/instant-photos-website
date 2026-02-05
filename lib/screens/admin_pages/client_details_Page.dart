import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDetailsPage extends StatefulWidget {
  final String qrCode;
  final String eventName;

  const ClientDetailsPage({
    super.key,
    required this.qrCode,
    required this.eventName,
  });

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController =
      TextEditingController(text: '+91');

  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
  }

  Future<void> _loadSavedDetails() async {
    final doc =
        await _firestore.collection('client_details').doc(widget.qrCode).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _whatsappController.text = data['whatsapp'] ?? '+91';
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _saveClientDetails() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final whatsapp = _whatsappController.text.trim();

    if (name.isEmpty || email.isEmpty || whatsapp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await _firestore.collection('client_details').doc(widget.qrCode).set({
        'name': name,
        'email': email,
        'whatsapp': whatsapp,
        'eventName': widget.eventName,
        'qrCode': widget.qrCode,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client details saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.deepPurple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [

                Text(
                  widget.qrCode,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.eventName,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(
                  height: 20,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    double horizontalPadding;
                    if (constraints.maxWidth > 1000) {
                      horizontalPadding = 300;
                    } else if (constraints.maxWidth > 600) {
                      horizontalPadding = 150;
                    } else {
                      horizontalPadding = 20;
                    }
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          TextField(
                            enabled: _isEditing,
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Client Name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            enabled: _isEditing,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            enabled: _isEditing,
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'WhatsApp Number',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.phone_android),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 160,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isEditing) {
                                  _saveClientDetails();
                                } else {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                }
                              },
                              child: Text(_isEditing ? 'Save' : 'Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
