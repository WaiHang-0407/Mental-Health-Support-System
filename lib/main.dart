import 'package:flutter/material.dart';
import 'services/payment_deep_link_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final PaymentDeepLinkService paymentDeepLinkService = PaymentDeepLinkService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(Mindly());
  await paymentDeepLinkService.start(navigatorKey);
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
