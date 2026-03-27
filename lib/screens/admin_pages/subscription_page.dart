import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _db = FirebaseFirestore.instance;

  int _currentEventCount = 0;
  int _eventQuota = 0;
  bool _loading = true;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Starter',
      'price': '₹150',
      'per': '/event',
      'events': 1,
      'amount': 15000,
      'label': '1 Event',
      'icon': Icons.bolt_rounded,
      'gradient': [Color(0xFF00C6FF), Color(0xFF0072FF)],
      'recommended': false,
      'features': [
        'Add 1 event to your quota',
        'QR code generation',
        'Photo uploads',
        'Client gallery access',
      ],
      'cta': 'Get Starter',
    },
    {
      'name': 'Pro',
      'price': '₹500',
      'per': '/5 events',
      'events': 5,
      'amount': 50000,
      'label': '5 Events',
      'icon': Icons.star_rounded,
      'gradient': [Color(0xFF7F00FF), Color(0xFFE100FF)],
      'recommended': true,
      'features': [
        'Add 5 events to your quota',
        'Everything in Starter, plus:',
        'Priority support',
        'Best value per event',
      ],
      'cta': 'Get Pro',
    },
    {
      'name': 'Elite',
      'price': '₹900',
      'per': '/10 events',
      'events': 10,
      'amount': 90000,
      'label': '10 Events',
      'icon': Icons.workspace_premium_rounded,
      'gradient': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      'recommended': false,
      'features': [
        'Add 10 events to your quota',
        'Everything in Pro, plus:',
        'Bulk event management',
        'Best for studios',
      ],
      'cta': 'Get Elite',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    final eventsSnap = await _db
        .collection('events')
        .where('email', isEqualTo: _user.email)
        .get();
    final quotaDoc =
        await _db.collection('subscriptions').doc(_user.email).get();
    setState(() {
      _currentEventCount = eventsSnap.docs.length;
      _eventQuota = (quotaDoc.data()?['total_quota'] ?? 2) as int;
      _loading = false;
    });
  }

  void _goToPayment(int planIndex) async {
    final plan = _plans[planIndex];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          planName: plan['name'] as String,
          planLabel: plan['label'] as String,
          price: plan['price'] as String,
          amount: plan['amount'] as int,
          events: plan['events'] as int,
          gradient: plan['gradient'] as List<Color>,
        ),
      ),
    );
    _loadQuota();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Pricing',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7F00FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Text('Subscription Plans',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Add more events to your photography account',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 28),
                      _quotaBar(),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Event Plans',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 14),
                      _plansRow(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _quotaBar() {
    final remaining = _eventQuota - _currentEventCount;
    final pct = _eventQuota == 0
        ? 0.0
        : (_currentEventCount / _eventQuota).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Event Quota',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text('$_currentEventCount / $_eventQuota events used',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              remaining > 0 ? '$remaining remaining' : 'Quota full',
              style: GoogleFonts.poppins(
                  color: remaining > 0 ? Colors.white : Colors.yellowAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plansRow() {
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _plans.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _planCard(i, _plans[i])),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _plans.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _planCard(i, _plans[i]),
        ],
      ],
    );
  }

  Widget _planCard(int index, Map<String, dynamic> plan) {
    final isRecommended = plan['recommended'] == true;
    final gradient = plan['gradient'] as List<Color>;
    final features = plan['features'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isRecommended
              ? gradient.first.withOpacity(0.4)
              : Colors.white12,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? gradient.first.withOpacity(0.15)
                : Colors.black45,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + name + badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(plan['icon'] as IconData,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(plan['name'] as String,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gradient.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: gradient.first.withOpacity(0.4)),
                  ),
                  child: Text('Recommended',
                      style: GoogleFonts.poppins(
                          color: gradient.first,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(plan['price'] as String,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(plan['per'] as String,
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 14),

          // Features
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16,
                    color: isRecommended ? gradient.first : Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => _goToPayment(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecommended
                    ? gradient.first
                    : const Color(0xFF0F3460),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(plan['cta'] as String,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
