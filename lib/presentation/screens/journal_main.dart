import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class JournalMainPage extends StatelessWidget {
  const JournalMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();

                // Redirect to login page after logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
        body: const Center(
          child: Text(
            "Journal main page",
            style: TextStyle(color: Colors.white), // contrast with dark gradient
          ),
        ),
      ),
    );
  }
}
