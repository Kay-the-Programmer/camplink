import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/buyer/order_detail_screen.dart';
import 'notification_service.dart';
import 'order_service.dart';

/// Global messenger key so foreground pushes can be shown as snackbars from
/// anywhere, without a BuildContext.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Global navigator key so a tapped push (handled without a widget context)
/// can route to the relevant screen.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

/// Fetch an order by id and open its detail screen using the root navigator.
/// Best-effort: silently does nothing if the order can't be loaded.
Future<void> openOrderById(String orderId) async {
  if (orderId.isEmpty) return;
  final nav = rootNavigatorKey.currentState;
  if (nav == null) return;
  try {
    final order = await OrderService().fetchById(orderId);
    nav.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
  } catch (_) {
    // Order unavailable (deleted, or not ours) — ignore.
  }
}

/// Background/terminated handler. The OS already displays messages that carry a
/// notification payload, so nothing extra is needed for the basic case.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Thin wrapper around Firebase Cloud Messaging. Everything is best-effort and
/// degrades silently when Firebase isn't configured, so the app works either way.
class PushMessaging {
  static final NotificationService _notifs = NotificationService();
  static String? _token;
  static bool _started = false;
  static StreamSubscription<String>? _refreshSub;
  static StreamSubscription<RemoteMessage>? _messageSub;

  /// Initialise Firebase once at startup. No-op if Firebase isn't set up.
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    } catch (_) {
      // Firebase not configured for this platform — push stays off.
    }
  }

  /// Request permission, register the device token with the backend and wire up
  /// foreground handling. Call once the user is authenticated.
  static Future<void> start() async {
    if (_started) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        _token = token;
        await _notifs.registerToken(token);
      }
      _refreshSub = messaging.onTokenRefresh.listen((t) async {
        _token = t;
        try {
          await _notifs.registerToken(t);
        } catch (_) {}
      });
      _messageSub = FirebaseMessaging.onMessage.listen(_showForeground);

      // Tapping a push that opened/resumed the app routes to the order.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);

      _started = true;
    } catch (_) {
      // Firebase unavailable — ignore.
    }
  }

  /// Unregister this device's token and tear down listeners (e.g. on logout).
  static Future<void> stop() async {
    final t = _token;
    if (t != null) {
      try {
        await _notifs.unregisterToken(t);
      } catch (_) {}
    }
    await _refreshSub?.cancel();
    await _messageSub?.cancel();
    _refreshSub = null;
    _messageSub = null;
    _token = null;
    _started = false;
  }

  /// Route a tapped notification to its target. Order notifications carry the
  /// order id in the `refId` data field.
  static void _handleTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    final refId = message.data['refId'] ?? '';
    if (type.toString().startsWith('ORDER') && refId.toString().isNotEmpty) {
      openOrderById(refId.toString());
    }
  }

  static void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final text = (n.title != null && n.title!.isNotEmpty)
        ? '${n.title}: ${n.body ?? ''}'
        : (n.body ?? 'New notification');
    rootMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
  }
}
