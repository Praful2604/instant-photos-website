import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestimonialSection extends StatefulWidget {
  const TestimonialSection({super.key});

  @override
  State<TestimonialSection> createState() => _TestimonialSectionState();
}

class _TestimonialSectionState extends State<TestimonialSection> {
  bool _showHeading = false;
  bool _showSubtitle = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _showHeading = true);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() => _showSubtitle = true);
    });
  }

  Widget _buildTestimonialCard({
    required String name,
    required String feedback,
    required String imageUrl,
    required int rating,
    int delay = 0,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              feedback,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                    (index) => Icon(
                  Icons.star,
                  size: 18,
                  color: index < rating ? Colors.amber : Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '- $name',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xfffdfbfb), Color(0xffebedee)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          if (_showHeading)
            DefaultTextStyle(
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              child: Text(
                'What Our Clients Say',
              ),
            ),
          const SizedBox(height: 12),
          if (_showSubtitle)
            DefaultTextStyle(
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.black54,
              ),
              child: Text(
                'Real stories from real customers. See what they\'re saying!',
              ),
            ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildTestimonialCard(
                name: 'John Doe',
                feedback:
                'Instant Photos transformed how I manage my photography business. It’s amazing!',
                imageUrl: 'https://tse2.mm.bing.net/th?id=OIP.Zvs5IHgOO5kip7A32UwZJgHaHa&pid=Api&P=0&h=220',
                rating: 5,
                delay: 0,
              ),
              _buildTestimonialCard(
                name: 'Jane Smith',
                feedback:
                'The AI photo selection feature saved me hours. My clients are impressed!',
                imageUrl: 'https://tse2.mm.bing.net/th?id=OIP.Hu9ygjdD2cR9iEDlWwgj8AHaKc&pid=Api&P=0&h=220',
                rating: 4,
                delay: 200,
              ),
              _buildTestimonialCard(
                name: 'Emily Johnson',
                feedback:
                'The platform is intuitive and professional. I couldn’t be happier with the results!',
                imageUrl: 'https://tse2.mm.bing.net/th?id=OIP.UvpbLr323Tc9ukIL3PEEygHaHa&pid=Api&P=0&h=220',
                rating: 5,
                delay: 400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}