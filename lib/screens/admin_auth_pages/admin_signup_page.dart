import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({Key? key}) : super(key: key);

  @override
  State<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _photographyNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signUpAdmin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final photographyName = _photographyNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() {
        _errorMessage = "Phone number must be exactly 10 digits.";
        _isLoading = false;
      });
      return;
    }

    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception('Signup failed.');

      // Save user metadata in Firestore 'admins' collection
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email,
        'name': name,
        'photography_name': photographyName,
        'phone': phone,
        'role': 'admin',
        'created_at': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin account created. Please verify your email.")),
      );
      Navigator.pop(context); // Navigate back to login screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Signup failed.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _photographyNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/admin_login_page.json',
                      height: 120,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Admin Signup',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Your Name', Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _photographyNameController, 'Photography Name', Icons.camera_alt),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      'Phone Number',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password', Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUpAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign Up as Admin', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}
