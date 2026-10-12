import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode and app language. Per-device preferences, so SharedPreferences
/// is the right home — nothing here needs to reach the server.
class PrefsController extends Notifier<AppPrefs> {
  static const _kTheme = 'komero_theme_mode';
  static const _kLocale = 'komero_locale';

  @override
  AppPrefs build() {
    Future.microtask(_load);

    return const AppPrefs();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    state = AppPrefs(
      themeMode: _themeFromName(p.getString(_kTheme)),
      // null locale = follow the device, which is what most operators want.
      localeCode: p.getString(_kLocale),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    (await SharedPreferences.getInstance()).setString(_kTheme, mode.name);
  }

  Future<void> setLocale(String? code) async {
    state = AppPrefs(themeMode: state.themeMode, localeCode: code);

    final p = await SharedPreferences.getInstance();

    if (code == null) {
      await p.remove(_kLocale);
    } else {
      await p.setString(_kLocale, code);
    }
  }

  static ThemeMode _themeFromName(String? name) => switch (name) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

@immutable
class AppPrefs {
  const AppPrefs({this.themeMode = ThemeMode.system, this.localeCode});

  final ThemeMode themeMode;

  /// `en` | `ka` | `ru`, or null to follow the device.
  final String? localeCode;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppPrefs copyWith({ThemeMode? themeMode, String? localeCode}) => AppPrefs(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
      );
}

final prefsProvider = NotifierProvider<PrefsController, AppPrefs>(PrefsController.new);

/// The three languages the storefront and admin ship with (commerce/i18n.config.ts).
const kSupportedLocales = [Locale('en'), Locale('ka'), Locale('ru')];

/// Each language in its own script - an operator looking for Georgian scans
/// for its own name, not for "Georgian".
const kLanguageNames = {'en': 'English', 'ka': 'ქართული', 'ru': 'Русский'};

/// Regional-indicator flag emoji. Android (Noto Color Emoji) and iOS both
/// render these natively, so there is no flag asset to ship, scale or theme.
const kLanguageFlags = {
  'en': '\u{1F1EC}\u{1F1E7}',
  'ka': '\u{1F1EC}\u{1F1EA}',
  'ru': '\u{1F1F7}\u{1F1FA}',
};
