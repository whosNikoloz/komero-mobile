import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:komero_mobile/l10n/app_localizations.dart';
import 'package:komero_mobile/src/core/prefs.dart';
import 'package:komero_mobile/src/core/theme/app_theme.dart';
import 'package:komero_mobile/src/widgets/language_picker.dart';

void main() {
  // Every supported locale must have a name and a flag, or the picker renders
  // a blank row for one of them.
  test('every supported locale has a name and a flag', () {
    for (final locale in kSupportedLocales) {
      final code = locale.languageCode;

      expect(kLanguageNames[code], isNotNull, reason: 'no name for $code');
      expect(kLanguageFlags[code], isNotNull, reason: 'no flag for $code');
      // A regional-indicator pair is two code points, four UTF-16 units.
      expect(kLanguageFlags[code]!.runes.length, 2, reason: 'bad flag for $code');
    }
  });

  testWidgets('picker opens and lists System plus every language',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: komeroLightTheme,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(body: Center(child: LanguageButton())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();

    for (final locale in kSupportedLocales) {
      expect(find.text(kLanguageNames[locale.languageCode]!), findsOneWidget);
    }
  });
}
