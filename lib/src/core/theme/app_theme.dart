import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds a ThemeData whose every colour comes from [KomeroColors], so light
/// and dark are the same code path with a different token set.
ThemeData komeroTheme(KomeroColors c, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.primaryForeground,
    secondary: c.accent,
    onSecondary: c.primaryForeground,
    error: c.error,
    onError: c.primaryForeground,
    surface: c.card,
    onSurface: c.text,
    surfaceContainerHighest: c.surfaceHover,
    outline: c.border,
    outlineVariant: c.borderStrong,
  );

  const radius = 12.0;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.surface,
    canvasColor: c.surface,
    dividerColor: c.border,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: c.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      shape: Border(bottom: BorderSide(color: c.border)),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSecondary,
      textColor: c.text,
      subtitleTextStyle: TextStyle(color: c.textSecondary, fontSize: 13),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.textSecondary),
    // The platform's own UI face: Roboto on Android, SF on iOS. Both ship
    // full Georgian coverage, so ქართული, Latin, digits and ₾ all render
    // without bundling or downloading anything.
    //
    // Deliberately not google_fonts: its generated font table is a ~1.5 MB
    // single library that the IDE's analysis server chokes on (`GoogleFonts`
    // resolves as InvalidType while `flutter analyze` passes), and it fetches
    // the face over the network on first launch. If the two platforms ever
    // need to look identical, bundle the Noto Sans Georgian TTFs as assets
    // instead of taking that package back.
    textTheme: Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          bodySmall: TextStyle(color: c.textSecondary, fontSize: 12),
          labelSmall: TextStyle(color: c.textMuted, fontSize: 11),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.inputBackground,
      hintStyle: TextStyle(color: c.textMuted),
      labelStyle: TextStyle(color: c.textSecondary),
      prefixIconColor: c.textMuted,
      suffixIconColor: c.textMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius - 2),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius - 2),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius - 2),
        borderSide: BorderSide(color: c.focusRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius - 2),
        borderSide: BorderSide(color: c.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius - 2),
        borderSide: BorderSide(color: c.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.primaryForeground,
        disabledBackgroundColor: c.textDisabled,
        // Height floor only — a Size.fromHeight minimum is Size(infinity, h),
        // which asserts the moment a button sits in a Row. Callers that want
        // full width stretch it (Column stretch, SizedBox, Expanded).
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 2)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.borderStrong),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 2)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.primary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.primary.withValues(alpha: 0.14),
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.textSecondary),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? c.primary : c.textMuted,
          size: 24,
        ),
      ),
    ),
    // Sheets are the app's only modal surface (see widgets/sheet.dart) — no
    // centre dialogs, because on a phone they sit under the thumb's reach and
    // behind the keyboard.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.overlay.withValues(alpha: 0.5),
      elevation: 0,
      showDragHandle: false, // the sheet draws its own, above its title
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 2)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      side: BorderSide(color: c.border),
      labelStyle: TextStyle(color: c.textSecondary, fontSize: 12),
      selectedColor: c.primary.withValues(alpha: 0.14),
      secondaryLabelStyle: TextStyle(color: c.primary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.overlay,
      contentTextStyle: TextStyle(color: c.onOverlay),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 2)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.surfaceHover,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primaryForeground : c.card,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceHover,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.border),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary.withValues(alpha: 0.12) : c.card,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.primary,
      unselectedLabelColor: c.textMuted,
      indicatorColor: c.primary,
      dividerColor: c.border,
    ),
  );
}

ThemeData get komeroLightTheme => komeroTheme(KomeroColors.light, Brightness.light);
ThemeData get komeroDarkTheme => komeroTheme(KomeroColors.dark, Brightness.dark);
