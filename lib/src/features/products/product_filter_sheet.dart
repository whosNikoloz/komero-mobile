import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/product.dart';
import '../../widgets/sheet.dart';

final categoriesProvider =
    FutureProvider((ref) => ref.watch(productRepositoryProvider).categories());

final brandsProvider =
    FutureProvider((ref) => ref.watch(productRepositoryProvider).brands());

/// Opens the filter sheet and returns the filter the operator settled on, or
/// null if they backed out.
Future<ProductFilter?> showProductFilterSheet(
  BuildContext context, {
  required ProductFilter current,
}) {
  return showKomeroSheet<ProductFilter>(
    context,
    title: context.l.filters,
    builder: (_) => _FilterBody(initial: current),
  );
}

/// Holds the in-progress filter so the body and the pinned actions agree.
/// Scoped to one sheet via a ProviderScope override would be heavier than the
/// problem; a plain StatefulWidget that renders its own actions is enough.
class _FilterBody extends ConsumerStatefulWidget {
  const _FilterBody({required this.initial});

  final ProductFilter initial;

  @override
  ConsumerState<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends ConsumerState<_FilterBody> {
  late ProductFilter _draft = widget.initial;

  void _toggleCategory(String id) {
    final next = [..._draft.categoryIds];

    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _draft = _draft.copyWith(categoryIds: next));
  }

  void _toggleBrand(String id) {
    final next = [..._draft.brandIds];

    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _draft = _draft.copyWith(brandIds: next));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final brands = ref.watch(brandsProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          label: l.sortBy,
          child: RadioGroup<ProductSort>(
            groupValue: _draft.sort,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(sort: v)),
            child: Column(
            children: [
              for (final sort in ProductSort.values)
                RadioListTile<ProductSort>(
                  value: sort,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    switch (sort) {
                      ProductSort.nameAsc => l.sortNameAsc,
                      ProductSort.priceLow => l.sortPriceLow,
                      ProductSort.priceHigh => l.sortPriceHigh,
                      ProductSort.newest => l.sortNewest,
                    },
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
          ),
        ),
        if (categories.isNotEmpty)
          _Group(
            label: l.category,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  FilterChip(
                    label: Text(cat.name),
                    selected: _draft.categoryIds.contains(cat.id),
                    onSelected: (_) => _toggleCategory(cat.id),
                    showCheckmark: false,
                  ),
              ],
            ),
          ),
        if (brands.isNotEmpty)
          _Group(
            label: l.brand,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final brand in brands)
                  FilterChip(
                    label: Text(brand.name),
                    selected: _draft.brandIds.contains(brand.id),
                    onSelected: (_) => _toggleBrand(brand.id),
                    showCheckmark: false,
                  ),
              ],
            ),
          ),
        _Group(
          label: l.stockStatus,
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l.inStock),
                selected: _draft.stockStatus == StockStatus.inStock,
                showCheckmark: false,
                onSelected: (on) => setState(
                  () => _draft = on
                      ? _draft.copyWith(stockStatus: StockStatus.inStock)
                      : _draft.copyWith(clearStockStatus: true),
                ),
              ),
              FilterChip(
                label: Text(l.outOfStock),
                selected: _draft.stockStatus == StockStatus.outOfStock,
                showCheckmark: false,
                onSelected: (on) => setState(
                  () => _draft = on
                      ? _draft.copyWith(stockStatus: StockStatus.outOfStock)
                      : _draft.copyWith(clearStockStatus: true),
                ),
              ),
            ],
          ),
        ),
        _Group(
          label: l.promoFlags,
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text(l.onlyNewArrivals),
                selected: _draft.isNewArrival == true,
                showCheckmark: false,
                onSelected: (on) => setState(
                  () => _draft = on
                      ? _draft.copyWith(isNewArrival: true)
                      : _draft.copyWith(clearFlags: true),
                ),
              ),
              FilterChip(
                label: Text(l.onlyDiscounted),
                selected: _draft.isDiscounted == true,
                showCheckmark: false,
                onSelected: (on) => setState(
                  () => _draft = on
                      ? _draft.copyWith(isDiscounted: true)
                      : _draft.copyWith(clearFlags: true),
                ),
              ),
              FilterChip(
                label: Text(l.onlyLiquidated),
                selected: _draft.isLiquidated == true,
                showCheckmark: false,
                onSelected: (on) => setState(
                  () => _draft = on
                      ? _draft.copyWith(isLiquidated: true)
                      : _draft.copyWith(clearFlags: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.filterSearchNote,
          style: TextStyle(fontSize: 11, color: c.textMuted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _draft),
            child: Text(l.showResults),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(
              context,
              ProductFilter(sort: _draft.sort),
            ),
            child: Text(l.clearAll),
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: context.c.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
