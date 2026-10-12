import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_stream.dart';
import '../data/repositories.dart';
import 'net/api_client.dart';
import 'session.dart';

/// Push notifications over Firebase Cloud Messaging, with
/// flutter_local_notifications doing the actual on-screen presentation (FCM
/// does not draw a banner for a foreground message on its own).
///
/// Two paths, deliberately:
///  * FCM — fires when the app is backgrounded or killed. Needs the backend to
///    know this device's token (see [PushService.registerDevice]).
///  * The SSE order stream — fires while the app is open. It is already there
///    for the live dashboard, costs nothing extra, and keeps alerts working on
///    builds with no Firebase project attached.
///
/// A message that arrives via both is shown once: FCM messages are ignored
/// while the app is in the foreground, because the stream already covered it.

/// Must be a top-level function — FCM runs it in its own isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // The system tray shows the notification payload itself; nothing to do here
  // beyond keeping the isolate alive for data-only messages.
}

class PushService {
  PushService(this._plugin, this._api, this._session, {required this.firebaseReady});

  final FlutterLocalNotificationsPlugin _plugin;
  final KomeroApi _api;
  final SessionController _session;

  /// False when no Firebase project is configured for this build — the app
  /// still runs and still alerts via the order stream.
  final bool firebaseReady;

  static const _ordersChannel = AndroidNotificationDetails(
    'komero_orders',
    'Orders',
    channelDescription: 'New orders, payments and status changes',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _stockChannel = AndroidNotificationDetails(
    'komero_stock',
    'Inventory',
    channelDescription: 'Low and out-of-stock warnings',
    importance: Importance.defaultImportance,
  );

  static Future<PushService> init(KomeroApi api, SessionController session) async {
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    var firebaseReady = false;

    try {
      // Reads google-services.json / GoogleService-Info.plist. Throws when the
      // platform config is missing, which is the normal state until the
      // Firebase project is created.
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      debugPrint('[push] Firebase not configured, falling back to SSE only: $e');
    }

    final service = PushService(
      plugin,
      api,
      session,
      firebaseReady: firebaseReady,
    );

    await service._requestPermission();

    if (firebaseReady) await service._attachFirebase();

    return service;
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    if (firebaseReady) {
      await FirebaseMessaging.instance.requestPermission();
    }
  }

  Future<void> _attachFirebase() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Foreground messages are swallowed on purpose — the SSE stream is already
    // showing these, and two banners for one order is worse than none.
    FirebaseMessaging.onMessage.listen((_) {});

    FirebaseMessaging.instance.onTokenRefresh.listen(registerDevice);

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) await registerDevice(token);
  }

  /// Hands this device's FCM token to the backend so it can target pushes at
  /// the operator for this store.
  ///
  /// TODO(backend): no such route exists yet. Nothing in commerce/ registers a
  /// device token, so until the API grows one (suggested:
  /// `POST api/admin/devices { token, platform }`, tenant-scoped by
  /// X-Client-Domain like every other admin route), this call 404s and is
  /// swallowed — background push stays dark while in-app alerts keep working.
  Future<void> registerDevice(String fcmToken) async {
    if (_session.token == null || _session.domain == null) return;

    try {
      await _api.post<void>(
        'api/admin/devices',
        body: {
          'token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
    } on ApiException catch (e) {
      debugPrint('[push] device registration unavailable (${e.status}): ${e.message}');
    }
  }

  /// Dropped on sign-out so the next operator on this phone is not pushed the
  /// previous one's orders.
  Future<void> unregisterDevice() async {
    if (!firebaseReady) return;

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Nothing to do — the token is gone either way.
    }
  }

  Future<void> showOrder({required String title, required String body}) =>
      _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _ordersChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );

  Future<void> showLowStock({required String title, required String body}) =>
      _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _stockChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
}

final pushServiceProvider = FutureProvider((ref) async {
  final service = await PushService.init(
    ref.watch(apiProvider),
    ref.watch(sessionProvider.notifier),
  );

  // Re-register whenever a different operator or store signs in.
  ref.listen(sessionProvider, (previous, next) {
    if (next.isAuthenticated && previous?.token != next.token) {
      FirebaseMessaging.instance.getToken().then((t) {
        if (t != null) service.registerDevice(t);
      }).catchError((_) {});
    }
  });

  return service;
});

/// Turns live order events into device notifications. Watched once by the shell.
final orderAlertsProvider = Provider<void>((ref) {
  final push = ref.watch(pushServiceProvider).value;

  if (push == null) return;

  ref.listen(orderEventsProvider, (_, next) {
    final event = next.value;

    if (event == null) return;

    // Only money arriving is worth buzzing a pocket for; status changes the
    // operator made themselves are not.
    if (event.eventType != 'Created' && event.eventType != 'Paid') return;

    push.showOrder(
      title: event.eventType == 'Paid' ? 'Payment received' : 'New order',
      body: '#${event.orderNumber} · ${event.total.toStringAsFixed(2)}'
          '${event.customerName == null ? '' : ' · ${event.customerName}'}',
    );
  });
});

/// One low-stock sweep per app start — catches the drift a live stream cannot,
/// since stock falls through orders rather than an event we subscribe to.
final lowStockAlertProvider = FutureProvider<int>((ref) async {
  final push = await ref.watch(pushServiceProvider.future);
  final low = await ref.watch(stockRepositoryProvider).lowStock(threshold: 5);

  if (low.isNotEmpty) {
    await push.showLowStock(
      title: 'Low stock',
      body: low.length == 1
          ? '${low.first.productName} is down to ${low.first.availableQuantity}'
          : '${low.length} products are running low',
    );
  }

  return low.length;
});
