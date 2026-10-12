import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../data/order_stream.dart';
import '../data/repositories.dart';
import 'net/api_client.dart';
import 'prefs.dart';
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

/// Tapped notifications, as order ids.
///
/// Top-level because the taps arrive from places that have no Riverpod ref:
/// the local-notifications callback registered during [PushService.init], and
/// FCM's cold-start [FirebaseMessaging.getInitialMessage]. A tap that lands
/// before the shell is listening (cold start) is held in [_pendingOrderTap]
/// rather than dropped.
final _orderTaps = StreamController<String>.broadcast();
String? _pendingOrderTap;

void _emitOrderTap(String? orderId) {
  if (orderId == null || orderId.isEmpty) return;

  if (_orderTaps.hasListener) {
    _orderTaps.add(orderId);
  } else {
    _pendingOrderTap = orderId;
  }
}

/// Order ids to navigate to. Watched by the shell, which owns the navigator.
final orderTapsProvider = StreamProvider<String>((ref) async* {
  final pending = _pendingOrderTap;

  _pendingOrderTap = null;

  if (pending != null) yield pending;

  yield* _orderTaps.stream;
});

/// The operator's strings, resolved without a BuildContext.
///
/// Notification copy is composed in the app, not on the server, so it follows
/// the language the operator picked rather than whatever the backend defaults
/// to. The one case the app cannot reach is a push that arrives while the app
/// is killed — the system draws that straight from the payload, so the backend
/// sends its own text there (see PUSH_NOTIFICATIONS_BACKEND_GUIDE.md).
final notifStringsProvider = FutureProvider<L>((ref) {
  final code = ref.watch(prefsProvider).localeCode;

  if (code != null) return L.delegate.load(Locale(code));

  // Following the device: fall back to English for anything we do not ship.
  final device = PlatformDispatcher.instance.locale;
  final supported = kSupportedLocales
      .any((l) => l.languageCode == device.languageCode);

  return L.delegate.load(supported ? Locale(device.languageCode) : const Locale('en'));
});

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

  /// The language the backend should write push text in — the app cannot
  /// compose it itself for a push that arrives while it is killed. Kept in
  /// sync with the operator's pick by [pushServiceProvider].
  String locale = 'en';

  /// False when no Firebase project is configured for this build — the app
  /// still runs and still alerts via the order stream.
  final bool firebaseReady;

  /// Must stay in sync with the manifest's
  /// `com.google.firebase.messaging.default_notification_*` meta-data — that
  /// is what the system uses when it draws a push with no Dart running.
  static const _accent = Color(0xFF2D4EC4); // brand-600, as in KomeroColors
  static const _icon = 'ic_notification'; // white silhouette of the K mark
  static const _ordersGroup = 'komero_orders';

  static const _ordersChannel = AndroidNotificationDetails(
    'komero_orders',
    'Orders',
    channelDescription: 'New orders, payments and status changes',
    importance: Importance.high,
    priority: Priority.high,
    icon: _icon,
    color: _accent,
    groupKey: _ordersGroup,
  );

  static const _stockChannel = AndroidNotificationDetails(
    'komero_stock',
    'Inventory',
    channelDescription: 'Low and out-of-stock warnings',
    importance: Importance.defaultImportance,
    icon: _icon,
    color: _accent,
  );

  static Future<PushService> init(KomeroApi api, SessionController session) async {
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      // The payload is the order id — see [showOrder].
      onDidReceiveNotificationResponse: (r) => _emitOrderTap(r.payload),
    );

    // Same tap, but it launched the app from cold rather than resuming it.
    final launch = await plugin.getNotificationAppLaunchDetails();

    if (launch?.didNotificationLaunchApp ?? false) {
      _emitOrderTap(launch!.notificationResponse?.payload);
    }

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

    // Tapping a push opens the order. `data.orderId` is the backend contract
    // (see PUSH_NOTIFICATIONS_BACKEND_GUIDE.md at the repo root).
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _emitOrderTap(m.data['orderId'] as String?),
    );

    // The app was killed and the tap started it.
    final initial = await FirebaseMessaging.instance.getInitialMessage();

    if (initial != null) _emitOrderTap(initial.data['orderId'] as String?);

    FirebaseMessaging.instance.onTokenRefresh.listen(registerDevice);

    final token = await FirebaseMessaging.instance.getToken();

    // Printed so a test push can be aimed at this device before the backend
    // registry exists. Debug builds only — a token is a send credential.
    assert(() {
      debugPrint('[push] device token: $token');
      return true;
    }());

    if (token != null) await registerDevice(token);
  }

  /// Hands this device's FCM token to the backend so it can target pushes at
  /// the operator for this store.
  ///
  /// The route is specced in `PUSH_NOTIFICATIONS_BACKEND_GUIDE.md` at the repo
  /// root; until the API ships it this call 404s and is swallowed, leaving
  /// background push dark while the in-app SSE alerts keep working.
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
          'locale': locale,
        },
      );
    } on ApiException catch (e) {
      debugPrint('[push] device registration unavailable (${e.status}): ${e.message}');
    }
  }

  /// Dropped on sign-out so the next operator on this phone is not pushed the
  /// previous one's orders.
  ///
  /// Both halves matter: the backend row has to go (the local delete can fail
  /// offline, and a stale row keeps receiving another store's orders), and so
  /// does the device token. Called while the session is still valid, so the
  /// DELETE still carries auth.
  Future<void> unregisterDevice() async {
    if (!firebaseReady) return;

    String? token;

    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // No token to report; still try the local delete below.
    }

    if (token != null && _session.token != null && _session.domain != null) {
      try {
        await _api.delete<void>('api/admin/devices/$token');
      } on ApiException catch (e) {
        debugPrint('[push] device unregister failed (${e.status}): ${e.message}');
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Nothing to do — the token is gone either way.
    }
  }

  Future<void> showOrder({
    required String title,
    required String body,
    String? orderId,
    String? storeName,
  }) =>
      _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _ordersChannel.channelId,
            _ordersChannel.channelName,
            channelDescription: _ordersChannel.channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
            color: _accent,
            groupKey: _ordersGroup,
            // Expands to the full line instead of truncating mid-total, and
            // puts the store above it so an operator running two shops can
            // tell them apart without opening the app.
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: storeName,
            ),
            subText: storeName,
            ticker: title,
          ),
          iOS: DarwinNotificationDetails(
            subtitle: storeName,
            // Groups the orders into one stack in Notification Centre.
            threadIdentifier: _ordersGroup,
            // An order is money waiting on a person; it earns the right to
            // break through Focus modes. Requires the Time Sensitive
            // entitlement on the Apple side.
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        // Read back on tap; mirrors the push's `data.orderId`.
        payload: orderId,
      );

  Future<void> showLowStock({required String title, required String body}) =>
      _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: _stockChannel,
          iOS: const DarwinNotificationDetails(
            threadIdentifier: 'komero_stock',
          ),
        ),
      );
}

final pushServiceProvider = FutureProvider((ref) async {
  final service = await PushService.init(
    ref.watch(apiProvider),
    ref.watch(sessionProvider.notifier),
  );

  // Re-register on a language change too, so the backend's push text follows
  // the operator rather than whatever they had picked at first sign-in.
  ref.listen(notifStringsProvider, (_, next) {
    final l = next.value;

    if (l == null || l.localeName == service.locale) return;

    service.locale = l.localeName;

    FirebaseMessaging.instance.getToken().then((t) {
      if (t != null) service.registerDevice(t);
    }).catchError((_) {});
  });

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
  final l = ref.watch(notifStringsProvider).value;

  if (push == null || l == null) return;

  ref.listen(orderEventsProvider, (_, next) {
    final event = next.value;

    if (event == null) return;

    // Only money arriving is worth buzzing a pocket for; status changes the
    // operator made themselves are not.
    if (event.eventType != 'Created' && event.eventType != 'Paid') return;

    final total = event.total.toStringAsFixed(2);
    final customer = event.customerName;

    push.showOrder(
      title: event.eventType == 'Paid'
          ? l.notifPaymentTitle
          : l.notifNewOrderTitle,
      body: customer == null
          ? l.notifOrderBody(event.orderNumber, total)
          : l.notifOrderBodyNamed(event.orderNumber, total, customer),
      orderId: event.orderId,
      storeName: ref.read(sessionProvider).domain,
    );
  });
});

/// One low-stock sweep per app start — catches the drift a live stream cannot,
/// since stock falls through orders rather than an event we subscribe to.
final lowStockAlertProvider = FutureProvider<int>((ref) async {
  final push = await ref.watch(pushServiceProvider.future);
  final l = await ref.watch(notifStringsProvider.future);
  final low = await ref.watch(stockRepositoryProvider).lowStock(threshold: 5);

  if (low.isNotEmpty) {
    await push.showLowStock(
      title: l.lowStock,
      body: low.length == 1
          ? l.notifLowStockOne(low.first.productName, low.first.availableQuantity)
          : l.notifLowStockMany(low.length),
    );
  }

  return low.length;
});
