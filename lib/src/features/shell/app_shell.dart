import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/theme/tokens.dart';
import '../../l10n_ext.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../inventory/scanner_screen.dart';
import '../orders/order_detail_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom-nav shell. Each tab keeps its own scroll position and state via
/// IndexedStack, which is what makes the app feel native rather than like a
/// page router.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _goTo(int i) {
    if (i == _index) return;

    // The tick an iPhone gives when a selection moves — it is what makes
    // changing tab feel like moving a physical control rather than repainting
    // a screen. selectionClick, not an impact: this is a choice changing, not
    // something landing.
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    // Starting these here, once, keeps the alert wiring alive for the whole
    // signed-in session regardless of which tab is on screen.
    ref.watch(orderAlertsProvider);
    ref.watch(lowStockAlertProvider);

    // Tapping an order notification opens that order. The shell is the lowest
    // widget that is always mounted while signed in, so it owns this rather
    // than a global navigator key.
    ref.listen(orderTapsProvider, (_, next) {
      final orderId = next.value;

      if (orderId == null || !mounted) return;

      setState(() => _index = 1); // Land on Orders, so Back has somewhere to go.

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
      );
    });

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          OrdersScreen(),
          InventoryScreen(),
          ProductsScreen(),
          SettingsScreen(),
        ],
      ),
      // The nav sits in the bottom-nav slot rather than over the body, so
      // every tab's scroll view still ends above it without each screen
      // having to add bottom padding of its own.
      bottomNavigationBar: _FloatingNav(
        index: _index,
        onSelect: _goTo,
        // The scanner is the one action an operator fires over and over, and
        // it is not a destination — a detached button is where it belongs.
        onScan: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        items: [
          (icon: Icons.insights_outlined, selected: Icons.insights, label: l.navHome),
          (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: l.navOrders),
          (icon: Icons.inventory_2_outlined, selected: Icons.inventory_2, label: l.navInventory),
          (icon: Icons.sell_outlined, selected: Icons.sell, label: l.navProducts),
          (icon: Icons.settings_outlined, selected: Icons.settings, label: l.navSettings),
        ],
      ),
    );
  }
}

typedef _NavItem = ({IconData icon, IconData selected, String label});

/// Three detached groups rather than one bar: a round action on each side and
/// the destinations in a pill between them. It reads as a set of app controls
/// floating over the screen instead of as OS chrome, and the round buttons put
/// the two one-handed actions — scan, and the account — under the thumbs.
///
/// Labels are dropped for width, so each control carries its label as a
/// semantics label and a tooltip: the name must still reach a screen reader
/// and a long-press.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.index,
    required this.onSelect,
    required this.onScan,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;
  final List<_NavItem> items;

  /// The last destination is the account, which sits in its own circle on the
  /// right rather than inside the pill.
  static const _accountIndex = 4;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final account = items[_accountIndex];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            _Floating(
              width: _Floating.height,
              child: _IconTap(
                icon: Icons.qr_code_scanner,
                label: l.scanBarcode,
                onTap: onScan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Floating(
                child: Row(
                  children: [
                    for (final (i, item) in items.indexed)
                      if (i != _accountIndex)
                        Expanded(
                          child: _NavButton(
                            item: item,
                            isSelected: i == index,
                            onTap: () => onSelect(i),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Floating(
              width: _Floating.height,
              child: _IconTap(
                icon: index == _accountIndex ? account.selected : account.icon,
                label: account.label,
                isSelected: index == _accountIndex,
                onTap: () => onSelect(_accountIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The surface all three groups share — one place owns what floating looks
/// like, so the circles and the pill can never drift apart.
class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.width});

  final Widget child;
  final double? width;

  static const height = 58.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.overlay.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A bare icon inside one of the round buttons.
class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: 23,
              color: isSelected ? c.primary : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? c.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.selected : item.icon,
                size: 23,
                color: isSelected ? c.primary : c.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
