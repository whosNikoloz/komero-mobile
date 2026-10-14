import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/order_stream.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/order.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../shell/app_shell.dart' show kNavClearance;
import 'order_detail_screen.dart';
import 'order_filter.dart';

/// Paged order list that appends as the operator scrolls.
class OrdersController extends AsyncNotifier<List<OrderSummary>> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<OrderSummary>> build() async {
    _page = 1;

    final channel = ref.watch(orderFilterProvider).channel;
    final result =
        await ref.watch(orderRepositoryProvider).list(page: 1, channel: channel);

    _hasMore = result.hasMore;

    return result.data;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;

    _loadingMore = true;

    try {
      final result = await ref.read(orderRepositoryProvider).list(
            page: _page + 1,
            channel: ref.read(orderFilterProvider).channel,
          );

      _page++;
      _hasMore = result.hasMore;
      state = AsyncData([...(state.value ?? []), ...result.data]);
    } catch (_) {
      // Keep what is already on screen; the operator can pull to refresh.
    } finally {
      _loadingMore = false;
    }
  }
}

final ordersProvider =
    AsyncNotifierProvider<OrdersController, List<OrderSummary>>(OrdersController.new);

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        ref.read(ordersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final orders = ref.watch(ordersProvider);
    final filter = ref.watch(orderFilterProvider);

    // A live order event means the list on screen is stale.
    ref.listen(orderEventsProvider, (_, _) => ref.invalidate(ordersProvider));

    return AppScaffold(
      title: l.orders,
      actions: [
        IconButton(
          tooltip: l.orderFilters,
          onPressed: () async {
            final next = await showOrderFilterSheet(context, current: filter);

            if (next == null) return;

            ref.read(orderFilterProvider.notifier).state = next;

            // Only the channel is a server-side filter; the rest narrow what
            // is already loaded, so a refetch would be wasted work.
            if (filter.needsRefetch(next)) ref.invalidate(ordersProvider);
          },
          icon: Badge(
            isLabelVisible: filter.activeCount > 0,
            label: Text('${filter.activeCount}'),
            backgroundColor: context.c.primary,
            textColor: context.c.primaryForeground,
            child: const Icon(Icons.tune),
          ),
        ),
        const SizedBox(width: 8),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          await ref.read(ordersProvider.future);
        },
        child: AsyncView(
          value: orders,
          onRetry: () => ref.invalidate(ordersProvider),
          data: (all) {
            final list = all.where(filter.matches).toList();

            if (list.isEmpty) {
              return EmptyState(
                message: l.noResults,
                icon: Icons.receipt_long_outlined,
              );
            }

            return ListView.separated(
              controller: _scroll,
              // No side padding and no per-row card: the rows run the full
              // width of the sheet and a hairline separates them, which is how
              // a list of records reads on a phone. Boxing every order in its
              // own rounded panel made ten orders look like ten adverts.
              padding: const EdgeInsets.only(bottom: kNavClearance),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                color: context.c.border,
              ),
              itemBuilder: (context, i) {
                if (i == list.length) {
                  return ref.read(ordersProvider.notifier).hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 8);
                }

                return _OrderRow(order: list[i]);
              },
            );
          },
        ),
      ),
    );
  }
}

/// One order as two lines: who and how much on top, what and when below.
///
/// Deliberately without a thumbnail. Most orders have no usable cover image,
/// so the column became the same receipt glyph repeated down the screen — 48dp
/// of row height per order spent saying nothing. The money is the thing an
/// operator scans for, so it gets the right edge and the heaviest weight.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName?.isNotEmpty == true
                        ? order.customerName!
                        : l.guestOrder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${l.itemCount(order.items)}  ·  '
                    '${shortDate(order.date, locale: tag)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.2, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(order.total, locale: tag),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
