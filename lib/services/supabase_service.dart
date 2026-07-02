import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://fahbbuodrfzmkavxukbp.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhaGJidW9kcmZ6bWthdnh1a2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNjAzMDYsImV4cCI6MjA5NDkzNjMwNn0.BnjK50HbxpaY-cMyvSMBGtCZRuQSQxE6ZCTfHZuHXSI';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() {
    return Supabase.initialize(
      url: _url,
      publishableKey: _anonKey,
    );
  }
}
