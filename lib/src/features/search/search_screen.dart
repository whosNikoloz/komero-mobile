import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../widgets/common.dart';
import '../inventory/scanner_screen.dart';
import '../orders/order_detail_screen.dart';
import '../products/product_edit_screen.dart';
import '../shell/app_shell.dart' show navIndexProvider;
import '../store/content_screens.dart';
import '../store/promotions_screen.dart';

/// What the search box currently holds, debounced by the field itself.
final searchQueryProvider = StateProvider.autoDispose((_) => '');

/// Which scope chip is on. [SearchScope.all] shows every section at once.
final searchScopeProvider = StateProvider.autoDispose((_) => SearchScope.all);

enum SearchScope { all, products, orders, pages }

/// The orders a text query is matched against. The backend has no order
/// search, so one page is pulled and filtered on the client — enough to find
/// what an operator was just looking at, which is what this box is for.
///
/// ponytail: first 50 orders only; move to a server-side endpoint if operators
/// start searching for older ones.
final _ordersPoolProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(orderRepositoryProvider).list(pageSize: 50),
);

final _productHitsProvider = FutureProvider.autoDispose((ref) async {
  final q = ref.watch(searchQueryProvider).trim();

  if (q.isEmpty) return const <Product>[];

  return ref.watch(productRepositoryProvider).search(q, pageSize: 20);
});

final _orderHitsProvider = FutureProvider.autoDispose((ref) async {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (q.isEmpty) return const <OrderSummary>[];

  final page = await ref.watch(_ordersPoolProvider.future);

  return page.data
      .where((o) =>
          o.id.toLowerCase().contains(q) ||
          (o.customerName ?? '').toLowerCase().contains(q))
      .take(20)
      .toList();
});

/// Recent queries, newest first. Device-local, like every other preference.
class RecentSearches extends Notifier<List<String>> {
  static const _key = 'komero_recent_searches';
  static const _max = 8;

  @override
  List<String> build() {
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      state = p.getStringList(_key) ?? const [];
    });

    return const [];
  }

  Future<void> add(String term) async {
    final t = term.trim();

    if (t.isEmpty) return;

    state = [t, ...state.where((e) => e.toLowerCase() != t.toLowerCase())]
        .take(_max)
        .toList();
    (await SharedPreferences.getInstance()).setStringList(_key, state);
  }

  Future<void> clear() async {
    state = const [];
    (await SharedPreferences.getInstance()).remove(_key);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);

/// Global search: one box over everything an operator can reach. Full screen
/// rather than a field inside a tab, because the point is to leave wherever
/// you are and land somewhere else.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Typing fires a request per keystroke otherwise. A quarter second is below
  /// what reads as lag and above the gap between two keys.
  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = value;
    ref.read(recentSearchesProvider.notifier).add(value);
  }

  void _run(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _submit(term);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final query = ref.watch(searchQueryProvider).trim();
    final scope = ref.watch(searchScopeProvider);
    final products = ref.watch(_productHitsProvider);
    final orders = ref.watch(_orderHitsProvider);
    final pages = _destinations(context, ref)
        .where((d) =>
            query.isNotEmpty &&
            d.label.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final counts = {
      SearchScope.products: products.value?.length,
      SearchScope.orders: orders.value?.length,
      SearchScope.pages: pages.length,
    };

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    label: l.cancel,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SearchField(
                      controller: _controller,
                      onChanged: _onChanged,
                      onSubmitted: _submit,
                      onClear: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
                  ),
                ],
              ),
            ),
            _ScopeBar(scope: scope, counts: counts),
            const SizedBox(height: 10),
            // The results live on their own rounded surface, so the list reads
            // as a sheet under the controls rather than as more of the header.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: query.isEmpty
                    ? _RecentList(onPick: _run)
                    : _Results(
                        scope: scope,
                        products: products,
                        orders: orders,
                        pages: pages,
                        onOpen: () => _submit(_controller.text),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The box itself: search glyph, the query, and the scanner on the right —
/// scanning a barcode is a way of searching for a product, so it lives here
/// rather than in the nav.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final hasText = controller.text.isNotEmpty;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.inputBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: c.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: TextStyle(fontSize: 15, color: c.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
                hintText: l.search,
                hintStyle: TextStyle(fontSize: 15, color: c.textMuted),
              ),
            ),
          ),
          if (hasText)
            _FieldAction(
              icon: Icons.cancel,
              label: l.clearRecent,
              onTap: onClear,
            )
          else
            _FieldAction(
              icon: Icons.qr_code_scanner_rounded,
              label: l.scanBarcode,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FieldAction extends StatelessWidget {
  const _FieldAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: context.c.textMuted),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.inputBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: c.text),
        ),
      ),
    );
  }
}

/// All / Products / Orders / Navigation, each carrying its hit count once a
/// query has run. Scrolls sideways: the labels are long in Georgian.
class _ScopeBar extends ConsumerWidget {
  const _ScopeBar({required this.scope, required this.counts});

  final SearchScope scope;
  final Map<SearchScope, int?> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;

    final labels = {
      SearchScope.all: l.all,
      SearchScope.products: l.products,
      SearchScope.orders: l.orders,
      SearchScope.pages: l.navigation,
    };

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final s in SearchScope.values) ...[
            _ScopeChip(
              label: labels[s]!,
              count: counts[s],
              isSelected: s == scope,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(searchScopeProvider.notifier).state = s;
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? c.primary : c.inputBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? c.primaryForeground : c.text,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? c.primaryForeground.withValues(alpha: 0.75)
                      : c.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What you searched for before, as tappable rows — an empty box is otherwise
/// a dead end.
class _RecentList extends ConsumerWidget {
  const _RecentList({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final recent = ref.watch(recentSearchesProvider);

    if (recent.isEmpty) {
      return EmptyState(
        message: l.noRecentSearches,
        icon: Icons.search_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.recentSearches.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: c.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                child: Text(l.clearRecent),
              ),
            ],
          ),
        ),
        for (final term in recent)
          ListTile(
            leading: Icon(Icons.history_rounded, color: c.textMuted),
            title: Text(term, style: TextStyle(fontSize: 15, color: c.text)),
            onTap: () => onPick(term),
          ),
      ],
    );
  }
}

/// The hits themselves, grouped by kind. Each section only appears when the
/// active scope asks for it and it actually found something.
class _Results extends StatelessWidget {
  const _Results({
    required this.scope,
    required this.products,
    required this.orders,
    required this.pages,
    required this.onOpen,
  });

  final SearchScope scope;
  final AsyncValue<List<Product>> products;
  final AsyncValue<List<OrderSummary>> orders;
  final List<_Destination> pages;
  final VoidCallback onOpen;

  bool _wants(SearchScope s) => scope == SearchScope.all || scope == s;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final productHits = products.value ?? const <Product>[];
    final orderHits = orders.value ?? const <OrderSummary>[];
    final busy = products.isLoading || orders.isLoading;

    final sections = <Widget>[
      if (_wants(SearchScope.products) && productHits.isNotEmpty) ...[
        _SectionLabel(l.products),
        for (final p in productHits)
          _Hit(
            leading: EntityThumb(path: p.coverImage, size: 40),
            title: p.name,
            subtitle: [
              money(
                p.discountPrice != null && p.discountPrice! > 0
                    ? p.discountPrice!
                    : p.price,
                locale: context.localeTag,
              ),
              if (p.sku?.isNotEmpty == true) p.sku!,
            ].join(' • '),
            onTap: () {
              onOpen();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(productId: p.id),
                ),
              );
            },
          ),
      ],
      if (_wants(SearchScope.orders) && orderHits.isNotEmpty) ...[
        _SectionLabel(l.orders),
        for (final o in orderHits)
          _Hit(
            leading: EntityThumb(
              path: o.coverImage,
              size: 40,
              icon: Icons.receipt_long_outlined,
            ),
            title: o.customerName?.isNotEmpty == true
                ? o.customerName!
                : '#${o.id}',
            subtitle: money(o.total, locale: context.localeTag),
            trailing: StatusBadge(o.status),
            onTap: () {
              onOpen();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderId: o.id),
                ),
              );
            },
          ),
      ],
      if (_wants(SearchScope.pages) && pages.isNotEmpty) ...[
        _SectionLabel(l.navigation),
        for (final d in pages)
          _Hit(
            leading: EntityThumb(size: 40, icon: d.icon),
            title: d.label,
            onTap: () {
              onOpen();
              d.go();
            },
          ),
      ],
    ];

    if (sections.isEmpty) {
      return busy
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(message: l.noResults, icon: Icons.search_off_rounded);
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: sections,
        ),
        if (busy) LinearProgressIndicator(minHeight: 2, backgroundColor: c.card),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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

/// One result line — same metrics whatever it points at, so a list mixing
/// products, orders and screens still scans as one column.
class _Hit extends StatelessWidget {
  const _Hit({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: c.text,
                    ),
                  ),
                  if (subtitle?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

typedef _Destination = ({String label, IconData icon, VoidCallback go});

/// The screens the box can jump to. A tab is reached by closing search and
/// switching the shell; anything without a tab is pushed in search's place.
List<_Destination> _destinations(BuildContext context, WidgetRef ref) {
  final l = context.l;

  void tab(int index) {
    ref.read(navIndexProvider.notifier).state = index;
    Navigator.of(context).pop();
  }

  void push(Widget screen) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  return [
    (icon: Icons.insights_outlined, label: l.navHome, go: () => tab(0)),
    (icon: Icons.receipt_long_outlined, label: l.navOrders, go: () => tab(1)),
    (icon: Icons.inventory_2_outlined, label: l.navInventory, go: () => tab(2)),
    (icon: Icons.sell_outlined, label: l.navProducts, go: () => tab(3)),
    (icon: Icons.settings_outlined, label: l.navSettings, go: () => tab(4)),
    (
      icon: Icons.local_offer_outlined,
      label: l.promotions,
      go: () => push(const PromotionsScreen())
    ),
    (
      icon: Icons.article_outlined,
      label: l.blog,
      go: () => push(const BlogScreen())
    ),
    (
      icon: Icons.help_outline,
      label: l.faqs,
      go: () => push(const FaqsScreen())
    ),
  ];
}
