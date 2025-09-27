// lib/sections/footer_section.dart
/*
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  Widget _footerLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Applying a linear gradient background to the footer
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1c3b69), Color(0xFF0a1f35)], // Deep blues
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      width: double.infinity, // Ensure it spans the entire width
      child: Column(
        children: [
          // Footer links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 10,
            children: [
              _footerLink('Privacy Policy'),
              _footerLink('Terms of Service'),
              _footerLink('Support'),
              _footerLink('Contact Us'),
            ],
          ),
          const SizedBox(height: 30),

          // Social media icons
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _socialIcon(FontAwesomeIcons.whatsapp, Colors.green, onTap: () {
                // WhatsApp link (open in web version)
              }),
              _socialIcon(FontAwesomeIcons.facebookF, Colors.blue, onTap: () {
                // Facebook page
              }),
              _socialIcon(FontAwesomeIcons.instagram, Colors.purple, onTap: () {
                // Instagram page
              }),
            ],
          ),
          const SizedBox(height: 30),

          // Footer text
          const Text(
            '© 2025 Instant Photos. All rights reserved.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
*/



import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  Widget _footerLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _socialLottie(String asset, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Lottie.asset(asset, repeat: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1c3b69), Color(0xFF0a1f35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      width: double.infinity,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 10,
            children: [
              _footerLink('Privacy Policy'),
              _footerLink('Terms of Service'),
              _footerLink('Support'),
              _footerLink('Contact Us'),
            ],
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _socialLottie('assets/whatsapp.json', onTap: () {
                // WhatsApp link
              }),
              _socialLottie('assets/facebook.json', onTap: () {
                // Facebook link
              }),
              _socialLottie('assets/instagram.json', onTap: () {
                // Instagram link
              }),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            '© 2025 Instant Photos. All rights reserved.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}