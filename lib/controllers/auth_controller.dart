// controllers/auth_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/patient_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../presentation/screens/home_patient.dart';
import '../presentation/screens/profile_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final UserRepository _userRepo = UserRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final supabase = Supabase.instance.client;

  StreamSubscription? _authSubscription;

  void listenToAuthChanges() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) async {
        try {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          debugPrint("=== Auth event: $event ===");
          if (event != AuthChangeEvent.signedIn) return;
          if (session == null) {
            debugPrint("Session is null, skipping");
            return;
          }

          final user = session.user;
          debugPrint("Signed in UID: ${user.id}");
          debugPrint("Access token present: ${session.accessToken.isNotEmpty}");

          // Step 1: insert into users
          final userInsertError = await _userRepo.insertUserIfNotExists(user.id);
          if (userInsertError != null) {
            debugPrint("USERS INSERT FAILED: $userInsertError");
            return; // stop here, patients has FK dependency
          }

          // Step 2: insert into patients
          final patientInsertError = await _patientRepo.insertPatientIfNotExists(user.id);
          if (patientInsertError != null) {
            debugPrint("PATIENTS INSERT FAILED: $patientInsertError");
          }

          // Step 3: check name and route
          final isEmpty = await _patientRepo.isNameEmpty(user.id);
          debugPrint("Is name empty: $isEmpty");

          await cancelAuthListener();

          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  isEmpty ? const NameQuery() : const HomePatientPage(),
            ),
          );
        } catch (e, stack) {
          debugPrint("Auth listener error: $e");
          debugPrint("$stack");
        }
      },
      onError: (e) => debugPrint("Auth stream error: $e"),
    );
  }

  Future<void> cancelAuthListener() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  Future<void> loginWithGoogle() async => await _authService.signInWithGoogle();
  Future<void> loginWithFacebook() async => await _authService.signInWithFacebook();
}