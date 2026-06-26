// presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../repositories/patient_table_repository.dart';
import '../../repositories/users_table_repository.dart';
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
  final _usersTable = UsersTableRepository();

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
      return;
    }

    try {
      final isActive = await _usersTable.isUserActive(session.user.id);
      if (!isActive) {
        await _rejectSession(
          'Your account has been deactivated. Please contact support.',
        );
        return;
      }

      final isEmpty = await _patientRepo.isNameEmpty(session.user.id);
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => isEmpty ? const NameQuery() : const HomePatientPage(),
        ),
      );
    } catch (_) {
      await _rejectSession(
        'Unable to verify your account status. Please try again later.',
      );
    }
  }

  Future<void> _rejectSession(String message) async {
    await Supabase.instance.client.auth.signOut();
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginPage(message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
