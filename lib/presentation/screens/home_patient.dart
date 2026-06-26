import 'package:flutter/material.dart';

import '../../services/affirmation_selection_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import 'login.dart';

class HomePatientPage extends StatefulWidget {
  const HomePatientPage({super.key});

  @override
  State<HomePatientPage> createState() => _HomePatientPageState();
}

class _HomePatientPageState extends State<HomePatientPage> {
  late final Future<SelectedAffirmation?> _affirmationFuture;

  @override
  void initState() {
    super.initState();
    _affirmationFuture = AffirmationSelectionService().chooseForCurrentLogin();
  }

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

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 0),
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<SelectedAffirmation?>(
                    future: _affirmationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _AffirmationPanel(
                          child: SizedBox(
                            height: 96,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                      final selected = snapshot.data;
                      if (selected == null) return const SizedBox.shrink();

                      return _AffirmationPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _weatherLabel(selected),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selected.affirmation.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }

  String _weatherLabel(SelectedAffirmation selected) {
    final weather = selected.weather;
    if (weather == null) return 'Today';

    final temperature = weather.temperature;
    if (temperature == null) return weather.category;

    return '${weather.category} - ${temperature.round()} C';
  }
}

class _AffirmationPanel extends StatelessWidget {
  final Widget child;

  const _AffirmationPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}
