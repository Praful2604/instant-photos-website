
import 'package:flutter/material.dart';

class FAQSection extends StatelessWidget {
  const FAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.yellow[50],
      alignment: Alignment.center,
      child: const Text('FAQ Section', style: TextStyle(fontSize: 24)),
    );
  }
}
