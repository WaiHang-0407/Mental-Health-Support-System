import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class HomePatientPage extends StatelessWidget {
  const HomePatientPage({super.key});

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
        bottomNavigationBar: BottomNavBar(currentIndex: 0), // 👈 0 = Home
        body: const Center(
          child: Text(
            "Home patient main page",
            style: TextStyle(color: Colors.white), 
          ),
        ),
      ),
    );
  }
}
