import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs.dart';
import '../core/theme/tokens.dart';
import '../l10n_ext.dart';
import 'sheet.dart';

/// A language's flag, sized to sit beside text.
///
/// Flag emoji carry their own colour, so they are exempt from the theme-token
/// rule the same way an external brand asset is.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.localeCode, this.size = 22});

  /// null renders the "follow the device" marker instead of a flag.
  final String? localeCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final flag = localeCode == null ? null : kLanguageFlags[localeCode];

    if (flag == null) {
      return Icon(
        Icons.phone_iphone_outlined,
        size: size,
        color: context.c.textSecondary,
      );
    }

    return Text(
      flag,
      style: TextStyle(fontSize: size, height: 1.2),
    );
  }
}

/// Compact flag + code control for an app bar or a form corner. Opens the
/// picker sheet.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final selected = ref.watch(prefsProvider).localeCode;

    // With no explicit choice the control shows what the device resolved to,
    // so it never reads as "no language".
    final shown = selected ?? Localizations.localeOf(context).languageCode;
    final code = kLanguageNames.containsKey(shown) ? shown : 'en';

    return InkWell(
      onTap: () => showLanguageSheet(context, ref),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageFlag(localeCode: code, size: 18),
            const SizedBox(width: 7),
            Text(
              code.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: c.textSecondary,
              ),
            ),
            Icon(Icons.expand_more, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// The picker itself — a bottom sheet, like every other modal in the app.
Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  final l = context.l;

  return showKomeroSheet<void>(
    context,
    title: l.language,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(prefsProvider).localeCode;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageRow(
              code: null,
              label: l.themeSystem,
              selected: selected == null,
              onTap: () {
                ref.read(prefsProvider.notifier).setLocale(null);
                Navigator.pop(context);
              },
            ),
            for (final locale in kSupportedLocales)
              _LanguageRow(
                code: locale.languageCode,
                label: kLanguageNames[locale.languageCode]!,
                selected: selected == locale.languageCode,
                onTap: () {
                  ref.read(prefsProvider.notifier).setLocale(locale.languageCode);
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    ),
  );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String? code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? c.primary.withValues(alpha: 0.1) : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: Row(
            children: [
              LanguageFlag(localeCode: code, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? c.primary : c.text,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 20, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}
