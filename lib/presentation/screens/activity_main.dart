import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class ActivityMainPage extends StatelessWidget {
  const ActivityMainPage({super.key});

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
        bottomNavigationBar: BottomNavBar(currentIndex: 3),
        body: const Center(
          child: Text(
            "Activity main page",
            style: TextStyle(color: Colors.white), // contrast with dark gradient
          ),
        ),
      ),
    );
  }
}
