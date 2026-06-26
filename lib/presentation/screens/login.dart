import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/gradient_background.dart';

// login_page.dart
class LoginPage extends StatefulWidget {
  // change to StatefulWidget
  final String? message;

  const LoginPage({super.key, this.message});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _authController.listenToAuthChanges();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.message!)),
        );
      });
    }
  }

  @override
  void dispose() {
    _authController.cancelAuthListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/dog.png', height: 120),
                const SizedBox(height: 40),

                const Text(
                  "Welcome to Mindly!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                const Text(
                  "You can log in via",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: () =>
                      _authController.loginWithGoogle(),
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text("Google"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(220, 50),
                  ),
                ),
                const SizedBox(height: 15),

                ElevatedButton.icon(
                  onPressed: () => _authController.loginWithFacebook(),
                  icon: Image.asset(
                    'assets/images/facebook.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text("Facebook"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(220, 50),
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
