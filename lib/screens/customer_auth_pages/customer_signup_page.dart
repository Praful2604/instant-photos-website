import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerSignUpPage extends StatefulWidget {
  const CustomerSignUpPage({super.key});

  @override
  State<CustomerSignUpPage> createState() => _CustomerSignUpPageState();
}

class _CustomerSignUpPageState extends State<CustomerSignUpPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;
  late Animation<double> _blur;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isButtonPressed = false;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithFirebase() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user!.sendEmailVerification();

      // Store additional details in Firestore if needed, except password
      // (Since password should never be stored in Firestore)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Check your email to confirm.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Signup failed: ';
      if (e.code == 'weak-password') msg += 'Provided password is too weak.';
      else if (e.code == 'email-already-in-use') msg += 'Email is already in use.';
      else msg += e.message ?? 'Unknown error.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade800,
              Colors.purple.shade600,
              Colors.indigo.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: [
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: isWideScreen ? 500 : double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.all(32),
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
                                    filter: ImageFilter.blur(
                                      sigmaX: _blur.value,
                                      sigmaY: _blur.value,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Lottie.asset(
                                          'assets/signup.json',
                                          height: 120,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Create Account',
                                          style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 10,
                                                color: Colors.black.withOpacity(0.3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sign up to continue your journey',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        _buildTextField(
                                          controller: _nameController,
                                          label: 'Full Name',
                                          icon: Icons.person_outline,
                                          obscureText: false,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildTextField(
                                          controller: _emailController,
                                          label: 'Email',
                                          icon: Icons.email_outlined,
                                          obscureText: false,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildTextField(
                                          controller: _phoneController,
                                          label: 'Phone Number',
                                          icon: Icons.phone_outlined,
                                          obscureText: false,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          obscureText: !_isPasswordVisible,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: Colors.white70,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const SizedBox(height: 24),

                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          height: 50,
                                          width: _isButtonPressed ? 180 : 200,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(25),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.purpleAccent.shade400,
                                                Colors.deepPurpleAccent.shade400,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: _isButtonPressed ? [] : [
                                              BoxShadow(
                                                color: Colors.purpleAccent.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(25),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(25),
                                              onTapDown: (_) => setState(() => _isButtonPressed = true),
                                              onTapUp: (_) {
                                                setState(() => _isButtonPressed = false);
                                                _signUpWithFirebase(); // 👈 Call sign-up
                                              },
                                              onTapCancel: () => setState(() => _isButtonPressed = false),
                                              child: Center(
                                                child: _isLoading
                                                    ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                                    : Text(
                                                  'SIGN UP',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            'Back to Login',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.purpleAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
