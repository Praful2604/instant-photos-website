// lib/sections/call_to_action_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Text(
            'Ready to Start?',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: const Text('Contact Us'),
          ),
        ],
      ),
    );
  }
}