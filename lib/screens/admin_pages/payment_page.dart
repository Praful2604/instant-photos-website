import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_web/razorpay_web.dart';

class PaymentPage extends StatefulWidget {
  final String planName;
  final String planLabel;
  final String price;
  final int amount;
  final int events;
  final List<Color> gradient;

  const PaymentPage({
    super.key,
    required this.planName,
    required this.planLabel,
    required this.price,
    required this.amount,
    required this.events,
    required this.gradient,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _db = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  bool _isPaying = false;
  bool _paymentDone = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _attachListeners();
  }

  void _attachListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openCheckout() {
    // Clear and re-attach to avoid stale listeners on web
    _razorpay.clear();
    _attachListeners();

    final options = {
      'key': 'rzp_test_ShNSVuxMDhN16N',
      'amount': widget.amount,
      'name': 'Instant Photos',
      'description': '${widget.planName} Plan – ${widget.planLabel}',
      'prefill': {'email': _user.email ?? ''},
      'theme': {'color': '#7F00FF'},
    };

    // Open FIRST (must be direct from user gesture), then update state
    _razorpay.open(options, context: context);
    setState(() => _isPaying = true);
  }

  void _onSuccess(PaymentSuccessResponse response) async {
    final docRef = _db.collection('subscriptions').doc(_user.email);
    final doc = await docRef.get();
    final currentQuota = (doc.data()?['total_quota'] ?? 2) as int;

    // Update subscription quota
    await docRef.set({
      'email': _user.email,
      'total_quota': currentQuota + widget.events,
      'last_payment_id': response.paymentId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save full payment details to payments collection
    await _db.collection('payments').add({
      'email': _user.email,
      'payment_id': response.paymentId,
      'order_id': response.orderId,
      'signature': response.signature,
      'plan_name': widget.planName,
      'plan_label': widget.planLabel,
      'events_added': widget.events,
      'amount': widget.amount,
      'amount_display': widget.price,
      'currency': 'INR',
      'status': 'success',
      'paid_at': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _isPaying = false;
        _paymentDone = true;
      });
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isPaying = false);
    _showSnackbar('Payment failed: ${response.message}', isError: true);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isPaying = false);
    _showSnackbar('External wallet: ${response.walletName}');
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _paymentDone ? _successView() : _checkoutView(),
        ),
      ),
    );
  }

  Widget _checkoutView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: widget.gradient),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 52),
                const SizedBox(height: 12),
                Text(widget.planName,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                Text(widget.planLabel,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 20),
                const Divider(color: Colors.white30),
                const SizedBox(height: 16),
                _infoRow('Events Added', '+${widget.events} events'),
                const SizedBox(height: 10),
                _infoRow('Amount', widget.price, valueLarge: true),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Account',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 14)),
                    Flexible(
                      child: Text(_user.email ?? '',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isPaying ? null : _openCheckout,
              icon: _isPaying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.payment_rounded, color: Colors.white),
              label: Text(
                _isPaying ? 'Opening Payment...' : 'Pay ${widget.price}',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gradient.first,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Secured by Razorpay',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text('256-bit SSL encrypted',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool valueLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: valueLarge ? 22 : 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _successView() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            Text('Payment Successful!',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              '${widget.events} event${widget.events > 1 ? 's' : ''} added to your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Back to Dashboard',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
