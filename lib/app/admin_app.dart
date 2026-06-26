import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../presentation/screens/auth_gate.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindly Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F7A64),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: kIsWeb ? AuthGate() : const _WebOnlyScreen(),
    );
  }
}

class _WebOnlyScreen extends StatelessWidget {
  const _WebOnlyScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Mindly Admin is configured for web only.'),
      ),
    );
  }
}
