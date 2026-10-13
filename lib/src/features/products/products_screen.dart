import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/me.dart';
import '../../models/product.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../../widgets/sheet.dart';
import '../dashboard/dashboard_screen.dart' show meProvider;
import 'catalog_screen.dart';
import 'product_edit_screen.dart';
import 'product_filter_sheet.dart';

// autoDispose: the filter holds the previous store's category and brand ids,
// which mean nothing in the next one. See the note in main.dart.
final productSearchProvider = StateProvider.autoDispose<String>((_) => '');

final productFilterProvider =
    StateProvider.autoDispose<ProductFilter>((_) => const ProductFilter());

final productListProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).browse(
        query: ref.watch(productSearchProvider),
        filter: ref.watch(productFilterProvider),
      );
});

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = context.c;
    final products = ref.watch(productListProvider);
    final filter = ref.watch(productFilterProvider);
    final canManage = ref.watch(meProvider).value?.can(Perm.products) ?? false;

    return AppScaffold(
      title: l.navProducts,
      // The title is the way into the rest of the catalog — categories, brands
      // and variant groups all hang off Products rather than earning tabs of
      // their own.
      onTitleTap: () => showCatalogSwitcher(context),
      actions: [
        if (canManage)
          IconButton(
            tooltip: l.addProduct,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductEditScreen()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        _FilterAction(filter: filter),
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) =>
                  ref.read(productSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          if (filter.activeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.activeFilters(filter.activeCount),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(productFilterProvider.notifier)
                        .state = ProductFilter(sort: filter.sort),
                    child: Text(l.clearAll),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(productListProvider);
                await ref.read(productListProvider.future);
              },
              child: AsyncView(
                value: products,
                onRetry: () => ref.invalidate(productListProvider),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      message: l.noResults,
                      icon: Icons.inventory_2_outlined,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ProductRow(
                      product: list[i],
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

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.enabled});

  final Product product;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final onSale = product.discountPrice != null && product.discountPrice! > 0;

    return Panel(
      padding: const EdgeInsets.all(12),
      onTap: enabled
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(productId: product.id),
                ),
              )
          : null,
      child: Row(
        children: [
          EntityThumb(path: product.coverImage, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                // Price cluster and SKU both shrink before anything clips:
                // a sale price, its struck-through original and a long SKU
                // together overflowed a 360dp row.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        onSale
                            ? money(product.discountPrice!, locale: context.localeTag)
                            : money(product.price, locale: context.localeTag),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                    ),
                    if (onSale) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          money(product.price, locale: context.localeTag),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                    if (product.sku != null) ...[
                      Text(
                        '  ·  ',
                        style: TextStyle(fontSize: 11, color: c.textDisabled),
                      ),
                      Flexible(
                        child: Text(
                          product.sku!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!product.isActive)
                _Tag(label: l.visibility, color: c.textMuted)
              else if (product.status == StockStatus.outOfStock)
                _Tag(label: l.outOfStock, color: c.error)
              else
                _Tag(label: l.inStock, color: c.success),
              if (product.stockQuantity != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${product.stockQuantity}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Same flat treatment as [StatusBadge] — dot plus label, no capsule.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

/// Filter button with a count badge — the only app-bar affordance, so the
/// screen stays one search field plus one control.
class _FilterAction extends ConsumerWidget {
  const _FilterAction({required this.filter});

  final ProductFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final count = filter.activeCount;

    return IconButton(
      tooltip: context.l.filters,
      onPressed: () async {
        final next = await showProductFilterSheet(context, current: filter);

        if (next != null) {
          ref.read(productFilterProvider.notifier).state = next;
        }
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: c.primary,
        textColor: c.primaryForeground,
        child: const Icon(Icons.tune),
      ),
    );
  }
}

/// The sections behind the Products title. Products itself is the one you are
/// on, so it is listed but inert — it is there to say where you are, the way
/// the web admin's catalog menu does.
Future<void> showCatalogSwitcher(BuildContext context) async {
  final l = context.l;
  final c = context.c;

  final kind = await showKomeroSheet<CatalogKind>(
    context,
    title: l.catalog,
    builder: (sheetContext) => Column(
      children: [
        ListTile(
          leading: Icon(Icons.inventory_2_outlined, color: c.primary),
          title: Text(
            l.navProducts,
            style: TextStyle(fontWeight: FontWeight.w600, color: c.primary),
          ),
          trailing: Icon(Icons.check, size: 20, color: c.primary),
          onTap: () => Navigator.of(sheetContext).pop(),
        ),
        for (final kind in CatalogKind.values)
          ListTile(
            leading: Icon(kind.icon),
            title: Text(kind.title(l)),
            onTap: () => Navigator.of(sheetContext).pop(kind),
          ),
      ],
    ),
  );

  if (kind == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CatalogScreen(kind: kind)),
  );
}
