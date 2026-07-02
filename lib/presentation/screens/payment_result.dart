import 'package:flutter/material.dart';

import '../../widgets/gradient_background.dart';
import 'chat_main.dart';
import 'home_patient.dart';

class PaymentResultPage extends StatelessWidget {
  final bool isSuccess;

  const PaymentResultPage({super.key, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final icon = isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined;
    final color = isSuccess ? Colors.greenAccent : Colors.redAccent;
    final title = isSuccess ? 'Payment Successful' : 'Payment Cancelled';
    final message = isSuccess
        ? 'Your Mindly Premium access is being activated.'
        : 'Your payment was not completed. You can try again anytime.';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, color: color, size: 84),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatMainPage()),
                    );
                  },
                  child: Text(isSuccess ? 'Continue to Chat' : 'Try Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePatientPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
