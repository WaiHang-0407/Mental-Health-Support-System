import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum SubscriptionPaymentProvider {
  stripe,
  paypal,
}

class SubscriptionService {
  final SupabaseClient _supabase;

  SubscriptionService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<bool> hasActiveSubscription() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final data = await _supabase
        .from('subscriptions')
        .select('is_active, expires_at')
        .eq('patient_id', userId)
        .maybeSingle();

    if (data == null || data['is_active'] != true) return false;

    final expiresAt = data['expires_at'];
    if (expiresAt == null) return true;

    return DateTime.parse(expiresAt as String).isAfter(DateTime.now());
  }

  Future<void> startCheckout(SubscriptionPaymentProvider provider) async {
    final response = await _supabase.functions.invoke(
      'subscription-checkout',
      body: {'provider': provider.name},
    );

    final data = response.data;
    if (data is! Map || data['checkoutUrl'] is! String) {
      throw StateError('Checkout URL was not returned.');
    }

    final uri = Uri.parse(data['checkoutUrl'] as String);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StateError('Unable to open checkout.');
    }
  }
}
