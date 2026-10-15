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
import '../shell/app_shell.dart' show kNavClearance;
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
      onTitleTap: showCatalogSwitcher,
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
                    // Full-width rows, hairline between: a catalog is a list,
                    // not a feed of cards.
                    padding: const EdgeInsets.only(bottom: kNavClearance),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      color: c.border,
                    ),
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

/// One product as a 40dp thumbnail and two lines. Half the height of the card
/// it replaced: the name gets one line instead of two, price and SKU share the
/// second, and stock sits at the right edge where it can be scanned down the
/// column.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.enabled});

  final Product product;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;
    final onSale = product.discountPrice != null && product.discountPrice! > 0;

    final inactive = !product.isActive;
    final out = product.status == StockStatus.outOfStock;

    return InkWell(
      onTap: enabled
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(productId: product.id),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            EntityThumb(path: product.coverImage, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Price cluster and SKU both shrink before anything clips:
                  // a sale price, its struck-through original and a long SKU
                  // together overflowed a 360dp row.
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          money(
                            onSale ? product.discountPrice! : product.price,
                            locale: tag,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: c.text,
                          ),
                        ),
                      ),
                      if (onSale) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            money(product.price, locale: tag),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
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
                            style: TextStyle(fontSize: 11, height: 1.2, color: c.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Only the states worth acting on get words. A product that is
            // live and in stock is the normal case, so it says nothing and
            // just shows what is on hand.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: inactive || out
                  ? _Tag(
                      label: inactive ? l.visibility : l.outOfStock,
                      color: inactive ? c.textMuted : c.error,
                    )
                  : Text(
                      product.stockQuantity == null ? '' : '${product.stockQuantity}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
            ),
          ],
        ),
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

/// The sections behind the Products title — a menu that drops from the title
/// itself rather than a sheet from the bottom, because the title is what it
/// belongs to. Products is listed but inert: it says where you are, the way
/// the web admin's catalog menu does.
Future<void> showCatalogSwitcher(BuildContext titleContext) async {
  final l = titleContext.l;
  final c = titleContext.c;
  final box = titleContext.findRenderObject() as RenderBox?;
  final overlay =
      Navigator.of(titleContext).overlay!.context.findRenderObject() as RenderBox;

  if (box == null) return;

  // Anchored to the title's left edge and hung just under it.
  final origin = box.localToGlobal(Offset(0, box.size.height + 6), ancestor: overlay);

  final kind = await showMenu<CatalogKind>(
    context: titleContext,
    color: c.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: c.border),
    ),
    position: RelativeRect.fromLTRB(
      origin.dx,
      origin.dy,
      overlay.size.width - origin.dx - 240,
      0,
    ),
    constraints: const BoxConstraints(minWidth: 220),
    items: [
      PopupMenuItem(
        enabled: false,
        height: 44,
        child: _MenuRow(
          icon: Icons.inventory_2_outlined,
          label: l.navProducts,
          selected: true,
        ),
      ),
      for (final kind in CatalogKind.values)
        PopupMenuItem(
          value: kind,
          height: 44,
          child: _MenuRow(icon: kind.icon, label: kind.title(l)),
        ),
    ],
  );

  if (kind == null || !titleContext.mounted) return;

  await Navigator.of(titleContext).push(
    MaterialPageRoute(builder: (_) => CatalogScreen(kind: kind)),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tint = selected ? c.primary : c.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 19, color: tint),
        const SizedBox(width: 12),
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
        if (selected) Icon(Icons.check_rounded, size: 18, color: c.primary),
      ],
    );
  }
}
