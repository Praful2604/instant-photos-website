import 'package:flutter/material.dart';
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

class _ClientDetailsPageState extends State<ClientDetailsPage>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController =
  TextEditingController(text: '+91');

  bool _isEditing = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();

    // 🔥 Animation init
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 GRADIENT APPBAR
      appBar: AppBar(
        title: const Text(
          'Client Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
       // color: const Color(0xFF1A1A2E),

        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 750),
                margin: const EdgeInsets.all(20),

                // 🔥 GLASS CARD
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(30),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔥 TITLE
                      Text(
                        widget.qrCode,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        widget.eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 25),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 25),

                      // 🔥 INPUT FIELD BUILDER
                      _buildField(_nameController, 'Client Name', Icons.person),
                      const SizedBox(height: 18),
                      _buildField(_emailController, 'Email', Icons.email),
                      const SizedBox(height: 18),
                      _buildField(
                          _whatsappController, 'WhatsApp', Icons.phone),

                      const SizedBox(height: 30),

                      // 🔥 ANIMATED BUTTON
                      GestureDetector(
                        onTap: () {
                          if (_isEditing) {
                            _saveClientDetails();
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 220,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isEditing ? 'Save Details' : 'Edit Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 CUSTOM INPUT FIELD
  Widget _buildField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}