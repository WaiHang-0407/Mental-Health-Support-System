import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fahbbuodrfzmkavxukbp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhaGJidW9kcmZ6bWthdnh1a2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNjAzMDYsImV4cCI6MjA5NDkzNjMwNn0.BnjK50HbxpaY-cMyvSMBGtCZRuQSQxE6ZCTfHZuHXSI',
  );

  runApp(Mindly());
}

class Mindly extends StatelessWidget {
  const Mindly({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindly',
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
    );
  }
}
