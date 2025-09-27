import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project_website/screens/landing_page_screens/qr_page/qr_scanner_page.dart';

import '../admin_auth_pages/admin_login_page.dart';
import '../customer_auth_pages/customer_login_page.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textAnimation;
  late Animation<double> _imageAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _textAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));

    _imageAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    List<Color>? gradientColors,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ??
                [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        return Container(
          height: isMobile ? null : 700,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 20
                : isTablet
                    ? 40
                    : 60,
            vertical: isMobile ? 40 : 0,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isMobile
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _imageAnimation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/herosection.png',
                            fit: BoxFit.cover,
                            height: 250,
                          ),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _textAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Capture Your Perfect Moments',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                  blurRadius: 12,
                                  color: Colors.black54,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Professional Photography Services with AI-Powered Solutions',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              buildGradientButton(
                                text: 'Get Started',
                                icon: Icons.arrow_forward,
                                onPressed: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //       builder: (context) => QRScannerPage()),
                                  // );
                                },
                                gradientColors: [
                                  const Color(0xFFFF416C),
                                  const Color(0xFFFF4B2B)
                                ],
                              ),
                              buildGradientButton(
                                text: 'Login',
                                icon: Icons.login,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerLoginPage()),
                                  );
                                },
                                gradientColors: [
                                  const Color(0xFF00C6FF),
                                  const Color(0xFF0072FF)
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            child: buildGradientButton(
                              text: 'Photography Account',
                              icon: Icons.business,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AdminLoginPage()),
                                );
                              },
                              gradientColors: [
                                const Color(0xFF8E2DE2),
                                const Color(0xFF4A00E0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text Section
                    Expanded(
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capture Your Perfect Moments',
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 12,
                                    color: Colors.black54,
                                    offset: Offset(2, 2),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Professional Photography Services with AI-Powered Solutions',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                buildGradientButton(
                                  text: 'Get Started',
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => QRScannerPage()),
                                    );
                                  },
                                  gradientColors: [
                                    const Color(0xFFFF416C),
                                    const Color(0xFFFF4B2B)
                                  ],
                                ),
                                const SizedBox(width: 20),
                                buildGradientButton(
                                  text: 'Login',
                                  icon: Icons.login,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CustomerLoginPage()),
                                    );
                                  },
                                  gradientColors: [
                                    const Color(0xFF00C6FF),
                                    const Color(0xFF0072FF)
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            buildGradientButton(
                              text: 'Login as Photography Account',
                              icon: Icons.business,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AdminLoginPage()),
                                );
                              },
                              gradientColors: [
                                const Color(0xFF8E2DE2),
                                const Color(0xFF4A00E0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Image Section
                    Expanded(
                      child: FadeTransition(
                        opacity: _imageAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/herosection.png',
                              fit: BoxFit.cover,
                              height: 500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
