import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../presentation/screens/payment_result.dart';

class PaymentDeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink, navigatorKey);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleLink(uri, navigatorKey),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    final isSuccess = uri.scheme == 'io.supabase.flutter' &&
        uri.host == 'subscription-success';
    final isCancel = uri.scheme == 'io.supabase.flutter' &&
        uri.host == 'subscription-cancel';

    if (!isSuccess && !isCancel) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = navigatorKey.currentState;
      if (state == null) return;

      state.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PaymentResultPage(isSuccess: isSuccess),
        ),
        (route) => false,
      );
    });
  }
}
