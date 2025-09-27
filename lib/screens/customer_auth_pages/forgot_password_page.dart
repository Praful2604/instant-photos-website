import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _isLoading = false);
      _showAlertDialog('Error', 'Please enter your email.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() => _isLoading = false);
      _showAlertDialog(
        'Password Reset',
        'A password reset link has been sent to your email.',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showAlertDialog('Error', 'An error occurred. Please try again later.');
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF512DA8), Color(0xFF673AB7), Color(0xFF311B92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                      position: _slide,
                      child: Container(
                        width: isWideScreen ? 500 : double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Lottie.asset(
                                  'assets/forgotpassword.json',
                                  height: 180,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your email to receive reset instructions',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(),
                                const SizedBox(height: 24),
                                _buildResetButton(),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Back to Login',
                                    style: GoogleFonts.poppins(
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        )
            : Text(
          'Send Reset Link',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
