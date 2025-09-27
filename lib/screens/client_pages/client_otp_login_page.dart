import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientOtpLoginPage extends StatefulWidget {
  @override
  _ClientOtpLoginPageState createState() => _ClientOtpLoginPageState();
}

class _ClientOtpLoginPageState extends State<ClientOtpLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController(text: "+91");
  final TextEditingController _otpController = TextEditingController();

  bool _codeSent = false;
  String? _verificationId;
  bool _isLoading = false;

  void _sendOtp() async {
    String phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnackBar("Enter a valid phone number");
      return;
    }

    setState(() => _isLoading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        _navigateToDashboard();
      },
      verificationFailed: (e) {
        _showSnackBar("Verification failed: ${e.message}");
        setState(() => _isLoading = false);
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _codeSent = true;
          _verificationId = verificationId;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
      },
    );
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar("Enter 6-digit OTP");
      return;
    }
    if (_verificationId == null) {
      _showSnackBar("Send OTP first");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        ),
      );
      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      _showSnackBar("OTP Verification failed: ${e.message}");
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/clientDashboard');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add your brand image or a general illustration (e.g. assets/otp_illustration.png)
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/otp_illustration.png', // You can use your own asset here
                      height: 100,
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Client Login",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2575FC),
                        fontFamily: 'Montserrat', // Add custom font if you wish
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Verify your phone number for secure access.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 32),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF2575FC)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_codeSent)
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Enter OTP",
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF2575FC)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                        onPressed: _codeSent ? _verifyOtp : _sendOtp,
                        icon: Icon(_codeSent ? Icons.check_circle : Icons.send),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2575FC),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          elevation: 4,
                        ),
                        label: Text(_codeSent ? "Verify OTP" : "Send OTP"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
