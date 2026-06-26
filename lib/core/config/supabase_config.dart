import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://fahbbuodrfzmkavxukbp.supabase.co';
  static const publishableKey = 'sb_publishable_1nqFP75CtpvfXYGWvtLwIQ_Qv23grwL';

  static Future<void> initialize() {
    return Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
