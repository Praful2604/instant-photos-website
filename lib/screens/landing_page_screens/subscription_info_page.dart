import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriptionInfoPage extends StatelessWidget {
  const SubscriptionInfoPage({super.key});

  final List<Map<String, dynamic>> plans = const [
    {
      'name': 'Starter',
      'price': '₹150',
      'per': '/event',
      'features': [
        'Add 1 event to your quota',
        'QR code generation',
        'Photo uploads',
        'Client gallery access',
      ],
      'recommended': false,
    },
    {
      'name': 'Pro',
      'price': '₹500',
      'per': '/5 events',
      'features': [
        'Add 5 events to your quota',
        'Everything in Starter',
        'Priority support',
        'Best value',
      ],
      'recommended': true,
    },
    {
      'name': 'Elite',
      'price': '₹900',
      'per': '/10 events',
      'features': [
        'Add 10 events to your quota',
        'Everything in Pro',
        'Bulk event management',
        'Best for studios',
      ],
      'recommended': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      // 🔥 Background like your image
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F7FA),
            Color(0xFFE4EAF0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 50),

              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: plans.map((plan) {
                  return _planCard(plan);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Text(
          "Flexible Pricing Plans",
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Choose a plan that fits your photography business",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final isRecommended = plan['recommended'] as bool;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],

        border: Border.all(
          color: isRecommended ? Colors.purple : Colors.transparent,
          width: 2,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + badge
          Row(
            children: [
              Text(
                plan['name'],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "POPULAR",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ]
            ],
          ),

          const SizedBox(height: 12),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan['price'],
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                plan['per'],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Features
          ...List.generate(plan['features'].length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan['features'][index],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isRecommended ? Colors.purple : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Choose Plan",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}