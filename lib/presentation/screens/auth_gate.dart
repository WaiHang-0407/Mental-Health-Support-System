import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_profile.dart';
import 'home.dart';
import 'login.dart';

class AuthGate extends StatefulWidget {
  AuthGate({super.key, AdminAuthController? authController})
      : authController = authController ?? AdminAuthController();

  final AdminAuthController authController;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<dynamic>? _authSubscription;
  AdminProfile? _adminProfile;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _authSubscription = widget.authController.authStateChanges.listen((_) {
      _loadSession();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    if (widget.authController.currentSession == null) {
      if (mounted) {
        setState(() {
          _adminProfile = null;
          _isCheckingSession = false;
        });
      }
      return;
    }

    final profile = await widget.authController.currentAdminProfile();
    if (!mounted) {
      return;
    }

    if (profile == null) {
      await widget.authController.signOut();
      return;
    }

    setState(() {
      _adminProfile = profile;
      _isCheckingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _adminProfile;
    if (profile == null) {
      return LoginPage(
        authController: widget.authController,
        onSignedIn: (profile) {
          setState(() {
            _adminProfile = profile;
          });
        },
      );
    }

    return HomePage(
      adminProfile: profile,
      onSignOut: widget.authController.signOut,
    );
  }
}
