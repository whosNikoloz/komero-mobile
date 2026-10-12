import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs.dart';
import '../core/theme/tokens.dart';
import '../l10n_ext.dart';
import 'sheet.dart';

/// Theme mode as a sheet, matching the language picker. A segmented control
/// could not hold "სისტემის" or "Системная" beside an icon at phone width.
Future<void> showThemeSheet(BuildContext context, WidgetRef ref) {
  final l = context.l;

  return showKomeroSheet<void>(
    context,
    title: l.appearance,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(prefsProvider).themeMode;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (mode, icon, label) in [
              (ThemeMode.system, Icons.brightness_auto_outlined, l.themeSystem),
              (ThemeMode.light, Icons.light_mode_outlined, l.themeLight),
              (ThemeMode.dark, Icons.dark_mode_outlined, l.themeDark),
            ])
              _ThemeRow(
                icon: icon,
                label: label,
                selected: selected == mode,
                onTap: () {
                  ref.read(prefsProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    ),
  );
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
              Icon(icon, size: 22, color: selected ? c.primary : c.textSecondary),
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
