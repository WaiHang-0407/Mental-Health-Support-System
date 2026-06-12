// presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../repositories/patient_repository.dart';
import 'home_patient.dart';
import 'login.dart';
import 'profile_query.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _patientRepo = PatientRepository();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      final isEmpty = await _patientRepo.isNameEmpty(session.user.id);
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => isEmpty ? const NameQuery() : const HomePatientPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}