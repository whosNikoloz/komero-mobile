import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../shell/app_shell.dart' show kNavClearance;
import '../../widgets/language_picker.dart';
import '../../widgets/theme_picker.dart';
import '../../widgets/sheet.dart';
import '../dashboard/dashboard_screen.dart' show meProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final prefs = ref.watch(prefsProvider);
    final session = ref.watch(sessionProvider);
    final me = ref.watch(meProvider).value;
    final push = ref.watch(pushServiceProvider).value;
    final branding = ref.watch(storeBrandingProvider).value;
    final pushOn = push?.firebaseReady == true;

    return AppScaffold(
      title: l.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, kNavClearance),
        children: [
          // The system settings app opens on who you are, not on a header —
          // the store is the account here, so it gets the hero and everything
          // else is grouped rows under it.
          _AccountHeader(
            branding: branding,
            name: branding?.displayName.isNotEmpty == true
                ? branding!.displayName
                : (session.domain ?? '—'),
            domain: session.domain ?? '',
          ),
          const SizedBox(height: 22),
          _Group(
            children: [
              _Row(
                label: l.email,
                value: me?.displayName ?? session.email ?? '—',
              ),
              if (me?.tenant != null)
                _Row(
                  label: l.role,
                  trailing: _Badge(
                    me!.tenant!.role == 'Owner' ? l.roleOwner : l.roleMember,
                  ),
                ),
            ],
          ),
          _GroupHeader(l.storeContent),
          _Group(
            children: [
              // The parts of the web admin an operator adds to rather than
              // configures. The catalog itself lives behind the Products
              // title; these have no tab of their own.
              _Row(
                icon: Icons.local_offer_rounded,
                label: l.promotions,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PromotionsScreen()),
                ),
              ),
              _Row(
                icon: Icons.article_rounded,
                label: l.blog,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlogScreen()),
                ),
              ),
              _Row(
                icon: Icons.help_rounded,
                label: l.faqs,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqsScreen()),
                ),
              ),
            ],
          ),
          _GroupHeader(l.appearance),
          _Group(
            children: [
              // Theme and language as tappable rows that open a sheet —
              // same pattern as every other setting, and it keeps the long
              // Georgian labels on one line instead of inside a segment.
              _Row(
                icon: switch (prefs.themeMode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                },
                label: l.appearance,
                value: switch (prefs.themeMode) {
                  ThemeMode.system => l.themeSystem,
                  ThemeMode.light => l.themeLight,
                  ThemeMode.dark => l.themeDark,
                },
                onTap: () => showThemeSheet(context, ref),
              ),
              _Row(
                leading: LanguageFlag(localeCode: prefs.localeCode, size: 18),
                label: l.language,
                value: prefs.localeCode == null
                    ? l.themeSystem
                    : kLanguageNames[prefs.localeCode]!,
                onTap: () => showLanguageSheet(context, ref),
              ),
              _Row(
                icon: pushOn
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_rounded,
                label: l.notifications,
                value: pushOn ? l.notifyNewOrders : l.pushUnavailable,
              ),
            ],
          ),
          const SizedBox(height: 30),
          _Group(
            children: [
              _Row(
                label: l.signOut,
                destructive: true,
                onTap: () async {
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
              ),
            ],
          ),
          const SizedBox(height: 28),
          const KomeroByline(),
        ],
      ),
    );
  }
}

/// The store, large: logo, name, domain. Opens the page on identity rather
/// than on a list.
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.branding,
    required this.name,
    required this.domain,
  });

  final StoreBranding? branding;
  final String name;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: c.border),
          ),
          child: StoreLogo(branding: branding, size: 64),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: c.text,
          ),
        ),
        if (domain.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            domain,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: c.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Small caps label above a group — the grouped-list header.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 26, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: context.c.textMuted,
        ),
      ),
    );
  }
}

/// A rounded card holding rows, hairline-separated and inset the way a system
/// settings list separates them.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: c.border, indent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One settings line: tinted icon tile, label, current value, chevron. With no
/// [onTap] it is a read-only line — same metrics, no chevron.
class _Row extends StatelessWidget {
  const _Row({
    this.icon,
    this.leading,
    required this.label,
    this.value = '',
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;

  /// The current setting, shown on the right. Empty for a row that is purely a
  /// way into another screen.
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Sign-out and friends: label in the error colour, no chevron.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final art = leading != null
        ? _Tile(child: leading!)
        : (icon != null ? _Tile(icon: icon) : null);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          if (art != null) ...[art, const SizedBox(width: 12)],
          // Label and value in one spaceBetween row — not a Spacer plus a
          // Flexible, which splits the free space between them and leaves
          // each row's value ending somewhere different. spaceBetween also
          // lets the label keep its natural width instead of being capped at
          // half the row, which matters for the long Georgian labels.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: destructive ? FontWeight.w600 : FontWeight.w500,
                      color: destructive ? c.error : c.text,
                    ),
                  ),
                ),
                if (trailing != null || value.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: trailing ??
                        Text(
                          value,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: c.textMuted),
                        ),
                  ),
                ],
              ],
            ),
          ),
          // A row without a chevron still draws one, invisibly: same glyph,
          // same metrics, so every value in the group ends on one line.
          if (!destructive) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: onTap == null ? Colors.transparent : c.textDisabled,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: () {
        // The row looks like a system one; give it the system's feedback too.
        HapticFeedback.selectionClick();
        onTap!();
      },
      highlightColor: c.surfaceHover,
      child: row,
    );
  }
}

/// The rounded tinted square a settings row carries instead of a bare icon.
/// One tint for every row — the icon says which setting, not which category —
/// and one size, so a flag and a glyph sit on the same column.
class _Tile extends StatelessWidget {
  const _Tile({this.icon, this.child});

  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child ?? Icon(icon, size: 16, color: c.primary),
    );
  }
}

/// Role: a pill rather than plain grey text, because it is a state and not a
/// value you could edit.
class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.primary,
        ),
      ),
    );
  }
}
