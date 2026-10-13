import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed-in operator + the store they are operating.
@immutable
class Session {
  const Session({this.token, this.domain, this.email, this.restored = false});

  /// Operator JWT from `POST /User/login`. Long-lived (≈1 year) and has no
  /// refresh token, so a 401 means log in again.
  final String? token;

  /// Bare store host, e.g. `wonder.ge` — no scheme, no trailing slash. This is
  /// the tenant selector; it is NOT in the token.
  final String? domain;
  final String? email;

  /// False until secure storage has been read, so the UI can hold the splash
  /// instead of flashing the login screen on every cold start.
  final bool restored;

  bool get isAuthenticated => token != null && domain != null;

  Session copyWith({
    String? token,
    String? domain,
    String? email,
    bool? restored,
    bool clear = false,
  }) {
    if (clear) return Session(domain: domain ?? this.domain, restored: true);

    return Session(
      token: token ?? this.token,
      domain: domain ?? this.domain,
      email: email ?? this.email,
      restored: restored ?? this.restored,
    );
  }
}

class SessionController extends Notifier<Session> {
  static const _kToken = 'komero_operator_token';
  static const _kDomain = 'komero_store_domain';
  static const _kEmail = 'komero_operator_email';
  static const _kPassword = 'komero_operator_password';

  // v11+ encrypts on Android by default; only the iOS accessibility class is
  // worth stating — the token must survive a reboot before first unlock being
  // irrelevant, but must not leave the device in an iCloud backup.
  final _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Session build() {
    // Fire-and-forget restore; `restored` flips when it lands.
    Future.microtask(_restore);

    return const Session();
  }

  /// Read synchronously by the Dio interceptor on every request.
  String? get token => state.token;
  String? get domain => state.domain;

  Future<void> _restore() async {
    try {
      final token = await _secure.read(key: _kToken);
      final prefs = await SharedPreferences.getInstance();

      state = Session(
        token: token,
        // The domain is not a secret and the login screen pre-fills it, so it
        // lives in prefs — surviving a token wipe.
        domain: prefs.getString(_kDomain),
        email: prefs.getString(_kEmail),
        restored: true,
      );
    } catch (_) {
      // Keystore unavailable (rooted device, restored backup) — start clean.
      state = const Session(restored: true);
    }
  }

  /// Sets the store before credentials are checked — the login request itself
  /// is tenant-scoped by `X-Client-Domain`, so the domain has to be on the
  /// session first. Deliberately does not set a token, so the app does not
  /// treat a half-finished login as a session.
  Future<void> setDomain(String domain) async {
    final normalized = normalizeDomain(domain);

    state = state.copyWith(domain: normalized, restored: true);
    (await SharedPreferences.getInstance()).setString(_kDomain, normalized);
  }

  /// The saved password, for pre-filling the sign-in form. Kept in secure
  /// storage — the keychain on iOS, the encrypted keystore on Android — so it
  /// is no more exposed than the token itself, and only when the operator
  /// asked for it to be remembered.
  Future<String?> rememberedPassword() async {
    try {
      return await _secure.read(key: _kPassword);
    } catch (_) {
      return null;
    }
  }

  Future<void> setRememberedPassword(String? password) async {
    try {
      if (password == null || password.isEmpty) {
        await _secure.delete(key: _kPassword);
      } else {
        await _secure.write(key: _kPassword, value: password);
      }
    } catch (_) {
      // A device with no usable keystore simply does not remember it; that is
      // not a reason to fail a sign-in that otherwise worked.
    }
  }

  Future<void> signIn({
    required String token,
    required String domain,
    required String email,
  }) async {
    final normalized = normalizeDomain(domain);

    await _secure.write(key: _kToken, value: token);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kDomain, normalized);
    await prefs.setString(_kEmail, email);

    state = Session(token: token, domain: normalized, email: email, restored: true);
  }

  Future<void> signOut() async {
    await _secure.delete(key: _kToken);
    state = state.copyWith(clear: true);
  }

  /// Called by the API interceptor on a 401. Keeps the domain so the login
  /// screen stays pre-filled.
  void onUnauthorized() {
    _secure.delete(key: _kToken);
    state = state.copyWith(clear: true);
  }

  /// `https://Wonder.GE/` → `wonder.ge`. The backend matches the bare host.
  static String normalizeDomain(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'^https?://'), '')
      .replaceAll(RegExp(r'/+$'), '')
      .split('/')
      .first;
}

final sessionProvider = NotifierProvider<SessionController, Session>(SessionController.new);
