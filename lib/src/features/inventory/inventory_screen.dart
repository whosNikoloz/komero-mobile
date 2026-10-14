import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/inventory.dart';
import '../../models/me.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../shell/app_shell.dart' show kNavClearance;
import '../dashboard/dashboard_screen.dart' show meProvider;
import 'scanner_screen.dart';
import 'stock_adjust_sheet.dart';
import 'transfer_screen.dart';

enum StockFilter { all, low, out }

// autoDispose so the filter, and the store-specific location id below,
// reset when the shell unmounts on sign-out — they must not carry over into
// the next store, whose locations are different rows entirely.
final stockFilterProvider = StateProvider.autoDispose((_) => StockFilter.all);

/// null = every location pooled, which is what the pre-locations API returns.
final selectedLocationProvider = StateProvider.autoDispose<String?>((_) => null);

final locationsProvider =
    FutureProvider((ref) => ref.watch(locationRepositoryProvider).list());

final stockListProvider = FutureProvider<List<ProductStock>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  final locationId = ref.watch(selectedLocationProvider);

  return switch (ref.watch(stockFilterProvider)) {
    StockFilter.all => repo.all(locationId: locationId),
    StockFilter.low => repo.lowStock(threshold: 10, locationId: locationId),
    StockFilter.out => repo.outOfStock(locationId: locationId),
  };
});

final stockSearchProvider = StateProvider.autoDispose<String>((_) => '');

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final stock = ref.watch(stockListProvider);
    final filter = ref.watch(stockFilterProvider);
    final query = ref.watch(stockSearchProvider).toLowerCase();
    final canManage = ref.watch(meProvider).value?.can(Perm.products) ?? false;

    return AppScaffold(
      title: l.inventory,
      actions: [
        IconButton(
          tooltip: l.scanBarcode,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            );
          },
          icon: const Icon(Icons.qr_code_scanner),
        ),
        IconButton(
          tooltip: l.transferStock,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransferScreen()),
          ),
          icon: const Icon(Icons.swap_horiz),
        ),
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => ref.read(stockSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in StockFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        StockFilter.all => l.allStock,
                        StockFilter.low => l.lowStock,
                        StockFilter.out => l.outOfStock,
                      }),
                      selected: filter == f,
                      showCheckmark: false,
                      onSelected: (_) =>
                          ref.read(stockFilterProvider.notifier).state = f,
                    ),
                  ),
                const _LocationPicker(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(stockListProvider);
                await ref.read(stockListProvider.future);
              },
              child: AsyncView(
                value: stock,
                onRetry: () => ref.invalidate(stockListProvider),
                data: (list) {
                  final filtered = query.isEmpty
                      ? list
                      : list
                          .where((s) =>
                              s.productName.toLowerCase().contains(query))
                          .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      message: l.noResults,
                      icon: Icons.inventory_2_outlined,
                    );
                  }

                  return ListView.separated(
                    // Full-width rows with a hairline between them, not a
                    // stack of cards: a stock list is a table of numbers and
                    // reads like one.
                    padding: const EdgeInsets.only(bottom: kNavClearance),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      color: context.c.border,
                    ),
                    itemBuilder: (_, i) => _StockRow(
                      stock: filtered[i],
                      enabled: canManage,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPicker extends ConsumerWidget {
  const _LocationPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final locations = ref.watch(locationsProvider).value;
    final selected = ref.watch(selectedLocationProvider);

    // Single-location tenants do not need the control at all.
    if (locations == null || locations.length < 2) return const SizedBox.shrink();

    final current =
        locations.where((loc) => loc.id == selected).firstOrNull;

    return PopupMenuButton<String?>(
      onSelected: (v) => ref.read(selectedLocationProvider.notifier).state = v,
      itemBuilder: (_) => [
        PopupMenuItem(value: null, child: Text(l.allLocations)),
        for (final loc in locations)
          PopupMenuItem(
            value: loc.id,
            child: Row(
              children: [
                Text(loc.name),
                if (loc.isWebSource) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.language, size: 14, color: context.c.textMuted),
                ],
              ],
            ),
          ),
      ],
      child: Chip(
        avatar: const Icon(Icons.warehouse_outlined, size: 16),
        label: Text(current?.name ?? l.allLocations),
      ),
    );
  }
}

/// One product's stock as a single line of table: name and where it sits on
/// the left, the available count on the right, coloured only when the number
/// is the problem.
///
/// The count carries the state on its own. The earlier row wrapped each item
/// in a card, painted a coloured bar down its side and stacked three sizes of
/// grey text under the name — four signals for one number.
class _StockRow extends ConsumerWidget {
  const _StockRow({required this.stock, required this.enabled});

  final ProductStock stock;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;

    final isOut = stock.availableQuantity <= 0;
    final isLow = !isOut && stock.availableQuantity <= 10;
    final colour = isOut ? c.error : (isLow ? c.warning : c.text);

    // On hand is only worth a line of its own when it differs from available,
    // which is exactly when something is reserved.
    final detail = [
      if (stock.reservedQuantity > 0)
        '${l.onHand} ${stock.quantity} · ${l.reserved} ${stock.reservedQuantity}',
      if (stock.locationName != null) stock.locationName!,
    ].join('  ·  ');

    return InkWell(
      onTap: enabled
          ? () => showStockAdjustSheet(
                context,
                productId: stock.productId,
                productName: stock.productName,
                currentQuantity: stock.quantity,
                locationId: stock.locationId ?? ref.read(selectedLocationProvider),
              )
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, enabled ? 8 : 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: c.text,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.2, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stock.availableQuantity}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: colour,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOut ? l.outOfStock : (isLow ? l.lowStock : l.available),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: isOut || isLow ? FontWeight.w600 : FontWeight.w400,
                    color: isOut || isLow ? colour : c.textMuted,
                  ),
                ),
              ],
            ),
            if (enabled) Icon(Icons.chevron_right, size: 18, color: c.textDisabled),
          ],
        ),
      ),
    );
  }
}
