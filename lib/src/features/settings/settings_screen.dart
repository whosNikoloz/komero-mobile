import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/prefs.dart';
import '../../core/session.dart';
import '../../core/theme/tokens.dart';
import '../../l10n_ext.dart';
import '../../data/branding.dart';
import '../../widgets/app_scaffold.dart';
import '../store/content_screens.dart';
import '../store/promotions_screen.dart';
import '../../widgets/branding.dart';
import '../../widgets/common.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/theme_picker.dart';
import '../../widgets/sheet.dart';
import '../dashboard/dashboard_screen.dart' show meProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = context.c;
    final prefs = ref.watch(prefsProvider);
    final session = ref.watch(sessionProvider);
    final me = ref.watch(meProvider).value;
    final push = ref.watch(pushServiceProvider).value;
    final branding = ref.watch(storeBrandingProvider).value;

    return AppScaffold(
      title: l.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SectionTitle(l.account),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StoreLogo(branding: branding, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branding?.displayName.isNotEmpty == true
                                ? branding!.displayName
                                : (session.domain ?? '—'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                          Text(
                            session.domain ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: c.border),
                _InfoRow(label: l.email, value: me?.displayName ?? session.email ?? '—'),
                if (me?.tenant != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l.role,
                    value: me!.tenant!.role == 'Owner' ? l.roleOwner : l.roleMember,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(l.storeContent),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // The parts of the web admin an operator adds to rather than
                // configures. The catalog itself lives behind the Products
                // title; these have no tab of their own.
                _SettingRow(
                  icon: Icons.local_offer_outlined,
                  label: l.promotions,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PromotionsScreen()),
                  ),
                ),
                Divider(height: 1, color: c.border, indent: 52),
                _SettingRow(
                  icon: Icons.article_outlined,
                  label: l.blog,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BlogScreen()),
                  ),
                ),
                Divider(height: 1, color: c.border, indent: 52),
                _SettingRow(
                  icon: Icons.help_outline,
                  label: l.faqs,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FaqsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(l.appearance),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Theme and language as tappable rows that open a sheet —
                // same pattern as every other setting, and it keeps the long
                // Georgian labels on one line instead of inside a segment.
                _SettingRow(
                  icon: switch (prefs.themeMode) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  },
                  label: l.appearance,
                  value: switch (prefs.themeMode) {
                    ThemeMode.system => l.themeSystem,
                    ThemeMode.light => l.themeLight,
                    ThemeMode.dark => l.themeDark,
                  },
                  onTap: () => showThemeSheet(context, ref),
                ),
                Divider(height: 1, color: c.border, indent: 52),
                _SettingRow(
                  leading: LanguageFlag(localeCode: prefs.localeCode, size: 20),
                  label: l.language,
                  value: prefs.localeCode == null
                      ? l.themeSystem
                      : kLanguageNames[prefs.localeCode]!,
                  onTap: () => showLanguageSheet(context, ref),
                ),
                Divider(height: 1, color: c.border, indent: 52),
                _SettingRow(
                  icon: push?.firebaseReady == true
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  label: l.notifications,
                  value: push?.firebaseReady == true
                      ? l.notifyNewOrders
                      : l.pushUnavailable,
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await confirmSheet(
                context,
                title: l.signOutConfirm,
                confirmLabel: l.signOut,
                destructive: true,
              );

              if (!confirmed) return;

              await push?.unregisterDevice();
              await ref.read(sessionProvider.notifier).signOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: c.error,
              side: BorderSide(color: c.error.withValues(alpha: 0.4)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l.signOut),
          ),
          const SizedBox(height: 28),
          const KomeroByline(),
        ],
      ),
    );
  }
}

/// One settings line: icon, label, current value, chevron. Compact enough that
/// the whole page fits a phone without scrolling past the account card.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    this.icon,
    this.leading,
    required this.label,
    this.value = '',
    required this.onTap,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;

  /// The current setting, shown on the right. Empty for a row that is purely a
  /// way into another screen.
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: leading ?? Icon(icon, size: 20, color: c.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: c.text),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: c.textDisabled),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: c.textMuted)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.text),
          ),
        ),
      ],
    );
  }
}
