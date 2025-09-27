import 'package:flutter/material.dart';

class KeyBenefitsSection extends StatelessWidget {
  const KeyBenefitsSection({super.key});

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + delay),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.teal.withOpacity(0.05)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 32, color: Colors.teal.shade700),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87, height: 1.5)),
                ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Colors.teal, Colors.cyan],
              ).createShader(bounds);
            },
            child: const Text(
              'Why Choose Instant Photos?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.flash_on,
                      title: 'Instant Delivery',
                      description: 'Photos are delivered to your clients immediately after the shoot.',
                      delay: 0,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.thumb_up,
                      title: 'Client Satisfaction',
                      description: 'Fast turnaround boosts client happiness and increases trust.',
                      delay: 200,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.mobile_friendly,
                      title: 'Mobile-Friendly Albums',
                      description: 'Share albums instantly via link or QR code — no apps needed.',
                      delay: 400,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.security,
                      title: 'Secure & Private',
                      description: 'All images are securely stored and only accessible by your clients.',
                      delay: 600,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.workspaces_outline,
                      title: 'Work Simplification',
                      description: 'No manual distribution or follow-up needed — everything is automated.',
                      delay: 800,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.schedule,
                      title: 'Saves Time',
                      description: 'Upload, send, and share within minutes — save hours of editing and delivery.',
                      delay: 1000,
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth / 2 - 30 : double.infinity,
                    child: _buildBenefit(
                      icon: Icons.attach_money,
                      title: 'Quick Money',
                      description: 'Deliver faster, get paid sooner — speed equals more jobs and income.',
                      delay: 1200,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}