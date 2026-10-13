import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/core/net/api_client.dart';
import 'src/core/prefs.dart';
import 'src/core/session.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/welcome_screen.dart';
import 'src/features/shell/app_shell.dart';
import 'src/widgets/branding.dart';

void main() {
  runApp(const ProviderScope(child: KomeroApp()));
}

/// Needed to reach the navigator from the session listener below, which runs
/// above any route's context.
final _navigatorKey = GlobalKey<NavigatorState>();

class KomeroApp extends ConsumerWidget {
  const KomeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final session = ref.watch(sessionProvider);

    // Every cached page of store data hangs off apiProvider — the repositories
    // watch it, and the screens' providers watch the repositories. Dropping it
    // when the token or the store changes therefore drops the whole tree in one
    // call, so signing out of one store and into another never shows the first
    // store's products, orders or stock. Doing it here rather than in
    // SessionController covers all three ways a session ends: sign-in,
    // sign-out, and a 401 from the interceptor.
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.token == next.token && prev?.domain == next.domain) return;

      ref.invalidate(apiProvider);

      // `home` below swaps with the session, but only the bottom of the stack
      // is `home` — anything pushed on top of it stays put. Signing in from
      // the pushed login screen would leave that screen covering the app, and
      // a 401 while an order was open would leave that order covering the
      // welcome screen. Clearing to the root is what makes the swap visible.
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        _ => const WelcomeScreen(),
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
