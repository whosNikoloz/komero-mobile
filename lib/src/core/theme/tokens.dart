import 'package:flutter/material.dart';

/// Every reusable colour in the app lives here — nothing is hardcoded at the
/// call site. The 22 canonical slots are the same ones the web admin uses
/// (`commerce/styles/globals.css`), filled with the Komero brand scale from
/// the marketing site (`ecommerce-landing/app/globals.css`) so the app looks
/// like Komero rather than like a tenant's storefront theme.
///
/// Read them from a widget with `context.c` (see [KomeroColorsX]).
@immutable
class KomeroColors extends ThemeExtension<KomeroColors> {
  const KomeroColors({
    required this.primary,
    required this.primaryHover,
    required this.primaryForeground,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceHover,
    required this.card,
    required this.overlay,
    required this.onOverlay,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.inputBackground,
    required this.focusRing,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color primary;
  final Color primaryHover;
  final Color primaryForeground;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceHover;
  final Color card;
  final Color overlay;

  /// Text and icons drawn on top of [overlay] — scrims, tooltips, snackbars.
  /// Light in both themes, because the overlay is dark in both.
  final Color onOverlay;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color border;
  final Color borderStrong;
  final Color inputBackground;
  final Color focusRing;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// Light palette — the Komero landing's brand scale
  /// (`ecommerce-landing/app/globals.css`): brand-600 carries the primary
  /// action, brand-500 the accent, navy-950 the type, mint-600 success.
  static const light = KomeroColors(
    primary: Color(0xFF2D4EC4), // brand-600
    primaryHover: Color(0xFF5566FF), // brand-500
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE0E9FF), // brand-100
    accent: Color(0xFF5566FF), // brand-500
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC), // tech-slate
    surfaceHover: Color(0xFFF0F4FF), // brand-50
    card: Color(0xFFFFFFFF),
    overlay: Color(0xFF020617), // navy-950
    onOverlay: Color(0xFFFFFFFF),
    text: Color(0xFF020617), // navy-950
    textSecondary: Color(0xFF1E293B), // navy-800
    textMuted: Color(0xFF64748B),
    textDisabled: Color(0xFFCBD5E1),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC6D3FF), // brand-200
    inputBackground: Color(0xFFFFFFFF),
    focusRing: Color(0xFF5566FF), // brand-500
    success: Color(0xFF059669), // commerce-mint-600
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF2D4EC4),
  );

  /// Dark palette — the landing ships light-only, so this is its counterpart
  /// built from the same scale: navy-950/900/800 as the surface ramp, and the
  /// primary lifted to brand-400 because brand-600 fails contrast on navy.
  static const dark = KomeroColors(
    primary: Color(0xFF7D91FF), // brand-400
    primaryHover: Color(0xFFA4B6FF), // brand-300
    primaryForeground: Color(0xFF0F1A4D), // brand-950
    secondary: Color(0xFF1E293B), // navy-800
    accent: Color(0xFFA4B6FF), // brand-300
    background: Color(0xFF020617), // navy-950
    surface: Color(0xFF0F172A), // navy-900
    surfaceHover: Color(0xFF1E293B), // navy-800
    card: Color(0xFF0F172A), // navy-900
    overlay: Color(0xFF000000),
    onOverlay: Color(0xFFFFFFFF),
    text: Color(0xFFF0F4FF), // brand-50
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textDisabled: Color(0xFF475569),
    border: Color(0xFF1E293B), // navy-800
    borderStrong: Color(0xFF334155),
    inputBackground: Color(0xFF0F172A),
    focusRing: Color(0xFFA4B6FF), // brand-300
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF7D91FF),
  );

  @override
  KomeroColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primaryForeground,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceHover,
    Color? card,
    Color? overlay,
    Color? onOverlay,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? border,
    Color? borderStrong,
    Color? inputBackground,
    Color? focusRing,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return KomeroColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      card: card ?? this.card,
      overlay: overlay ?? this.overlay,
      onOverlay: onOverlay ?? this.onOverlay,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      inputBackground: inputBackground ?? this.inputBackground,
      focusRing: focusRing ?? this.focusRing,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  KomeroColors lerp(ThemeExtension<KomeroColors>? other, double t) {
    if (other is! KomeroColors) return this;

    return KomeroColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      card: Color.lerp(card, other.card, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      onOverlay: Color.lerp(onOverlay, other.onOverlay, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension KomeroColorsX on BuildContext {
  /// The active palette. `context.c.primary` instead of a literal.
  KomeroColors get c {
    final colors = Theme.of(this).extension<KomeroColors>();

    assert(
      colors != null,
      'No KomeroColors in the theme. Build ThemeData with komeroTheme() '
      '(see core/theme/app_theme.dart) — a bare ThemeData has no palette.',
    );

    // Falling back keeps a stray subtree (or a widget test that forgot the
    // theme) rendering in the right colours instead of crashing.
    return colors ?? KomeroColors.light;
  }
}
