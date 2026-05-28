import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/router/app_router.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;
  bool _routerReady = false;
  String? _pendingResetRoute;

  Future<void> init() async {
    if (_initialized || _subscription != null || kIsWeb) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DEEP_LINK] Failed to get initial link: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object err) {
        debugPrint('[DEEP_LINK] Link stream error: $err');
      },
    );
  }

  String? consumePendingResetRoute() {
    final route = _pendingResetRoute;
    _pendingResetRoute = null;
    return route;
  }

  void openPendingResetRouteIfAny() {
    _routerReady = true;
    final route = consumePendingResetRoute();
    if (route == null) return;
    appRouter.go(route);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'laporfsm') return;

    final target = uri.host.isNotEmpty
        ? '/${uri.host}${uri.path}'
        : uri.path.isNotEmpty
        ? uri.path
        : '/';

    if (target == '/reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];
      if (token == null || email == null) return;

      final encodedToken = Uri.encodeQueryComponent(token);
      final encodedEmail = Uri.encodeQueryComponent(email);
      final route = '/reset-password?token=$encodedToken&email=$encodedEmail';
      _pendingResetRoute = route;
      if (_routerReady) {
        appRouter.go(route);
        _pendingResetRoute = null;
      }
      return;
    }

    if (target == '/login') {
      appRouter.go('/login');
    }
  }
}
