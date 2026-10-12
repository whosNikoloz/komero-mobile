import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/core/prefs.dart';
import 'src/core/session.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/shell/app_shell.dart';
import 'src/widgets/branding.dart';

void main() {
  runApp(const ProviderScope(child: KomeroApp()));
}

class KomeroApp extends ConsumerWidget {
  const KomeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Komero',
      debugShowCheckedModeBanner: false,
      theme: komeroLightTheme,
      darkTheme: komeroDarkTheme,
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (session) {
        // Hold the splash until secure storage has been read, so a signed-in
        // operator never sees the login screen flash past on a cold start.
        Session(restored: false) => const _Splash(),
        Session(isAuthenticated: true) => const AppShell(),
        _ => const LoginScreen(),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KomeroLogo(size: 72),
            SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
