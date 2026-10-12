import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../l10n_ext.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l.navInventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell),
            label: l.navProducts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
