import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:major_project_website/screens/client_pages/client_otp_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../landing_page_screens/home_page.dart';
import 'customer_signup_page.dart';


class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});
  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;
  late Animation<double> _blur;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.elasticOut)),
    );
    _blur = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showErrorDialog("Please enter email and password.");
        return;
      }

      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        _showErrorDialog("Please verify your email before logging in.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', 'customer');

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed: ";
      if (e.code == "user-not-found") message += "No user found for that email.";
      else if (e.code == "wrong-password") message += "Wrong password provided.";
      else message += e.message ?? "Unknown error.";
      _showErrorDialog(message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF1A237E)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                      position: _slide,
                      child: Container(
                        width: isWideScreen ? 500 : double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white.withOpacity(0.1),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: _blur.value, sigmaY: _blur.value),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/lock.gif', height: 120, fit: BoxFit.contain),
                                  const SizedBox(height: 16),
                                  Text('Welcome Back!',
                                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Login to continue your journey',
                                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                                  const SizedBox(height: 32),
                                  _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      obscureText: !_isPasswordVisible,
                                      suffixIcon: IconButton(
                                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.white70),
                                        onPressed: () {
                                          setState(() => _isPasswordVisible = !_isPasswordVisible);
                                        },
                                      )),
                                  const SizedBox(height: 24),
                                  _buildLoginButton(),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('New here? ', style: GoogleFonts.poppins(color: Colors.white70)),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => const CustomerSignUpPage()),
                                          );
                                        },
                                        child: Text('Create Account',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // GestureDetector(
                                  //   onTap: () {
                                  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ClientOtpLoginPage()));
                                  //   },
                                  //   child: Text('Client Login',
                                  //     style: GoogleFonts.poppins(
                                  //       color: Colors.white,
                                  //       fontWeight: FontWeight.bold,
                                  //       decoration: TextDecoration.underline,
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                                    },
                                    child: Text('Go to Home',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, required String label, required IconData icon,
    bool obscureText = false, Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        hintText: label,
        hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white)
          : Text('Login',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
