import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin_pages/admin_dashboard_page.dart';
import 'admin_signup_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _showPassword = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[!@#\$&*~.,;?]').hasMatch(password);
  }

  Future<void> _loginAdmin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
        _isLoading = false;
      });
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters with uppercase, lowercase, number, and special character.';
        _isLoading = false;
      });
      return;
    }

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user == null) {
        setState(() {
          _errorMessage = 'Invalid credentials. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Check if user document exists in Firestore admins collection
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        setState(() {
          _errorMessage = 'Access denied. Not an admin account.';
          _isLoading = false;
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Welcome, Admin!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Lottie.asset('assets/admin_login_page.json'),
                  ),
                  const Text(
                    "Admin Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    controller: _emailController,
                    hintText: "Email",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 10),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminSignupPage()),
                          );
                        },
                        child: const Text(
                          "         Don't have an account? Sign Up",
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.purpleAccent,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white70),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.purpleAccent,
        decoration: InputDecoration(
          icon: const Icon(Icons.lock_outline, color: Colors.white70),
          hintText: "Password",
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
        ),
      ),
    );
  }
}
