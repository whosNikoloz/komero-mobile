import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/tokens.dart';
import '../../l10n_ext.dart';
import '../../models/order.dart';
import '../../widgets/sheet.dart';

enum OrderDateRange {
  any,
  last7Days,
  last30Days;

  /// Oldest date an order may carry to pass this range.
  DateTime? get since => switch (this) {
        OrderDateRange.any => null,
        OrderDateRange.last7Days =>
          DateTime.now().subtract(const Duration(days: 7)),
        OrderDateRange.last30Days =>
          DateTime.now().subtract(const Duration(days: 30)),
      };
}

/// What the orders list is narrowed to.
///
/// Only `channel` is a server-side filter — `Order/get-all-orders` takes it as
/// a query parameter. Status and date have no equivalent on that endpoint, so
/// they narrow the loaded pages on the client; the sheet says so.
@immutable
class OrderFilter {
  const OrderFilter({
    this.channel,
    this.statuses = const {},
    this.dateRange = OrderDateRange.any,
  });

  final OrderChannel? channel;
  final Set<OrderStatus> statuses;
  final OrderDateRange dateRange;

  int get activeCount => [
        channel != null,
        statuses.isNotEmpty,
        dateRange != OrderDateRange.any,
      ].where((on) => on).length;

  /// True when the channel changed, which is the only part that needs a refetch.
  bool needsRefetch(OrderFilter other) => channel != other.channel;

  bool matches(OrderSummary order) {
    if (statuses.isNotEmpty && !statuses.contains(order.status)) return false;

    final since = dateRange.since;

    if (since != null) {
      final date = order.date;

      if (date == null || date.isBefore(since)) return false;
    }

    return true;
  }

  OrderFilter copyWith({
    OrderChannel? channel,
    Set<OrderStatus>? statuses,
    OrderDateRange? dateRange,
    bool clearChannel = false,
  }) =>
      OrderFilter(
        channel: clearChannel ? null : (channel ?? this.channel),
        statuses: statuses ?? this.statuses,
        dateRange: dateRange ?? this.dateRange,
      );
}

final orderFilterProvider =
    StateProvider.autoDispose<OrderFilter>((_) => const OrderFilter());

Future<OrderFilter?> showOrderFilterSheet(
  BuildContext context, {
  required OrderFilter current,
}) {
  return showKomeroSheet<OrderFilter>(
    context,
    title: context.l.orderFilters,
    builder: (_) => _OrderFilterBody(initial: current),
  );
}

class _OrderFilterBody extends StatefulWidget {
  const _OrderFilterBody({required this.initial});

  final OrderFilter initial;

  @override
  State<_OrderFilterBody> createState() => _OrderFilterBodyState();
}

class _OrderFilterBodyState extends State<_OrderFilterBody> {
  late OrderFilter _draft = widget.initial;

  void _toggleStatus(OrderStatus status) {
    final next = {..._draft.statuses};

    next.contains(status) ? next.remove(status) : next.add(status);
    setState(() => _draft = _draft.copyWith(statuses: next));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          label: l.status,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in OrderStatus.values)
                FilterChip(
                  label: Text(l.orderStatusLabel(status)),
                  selected: _draft.statuses.contains(status),
                  showCheckmark: false,
                  onSelected: (_) => _toggleStatus(status),
                ),
            ],
          ),
        ),
        _Group(
          label: l.channel,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.all),
                selected: _draft.channel == null,
                showCheckmark: false,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(clearChannel: true)),
              ),
              for (final channel in OrderChannel.values)
                ChoiceChip(
                  label: Text(l.orderChannelLabel(channel)),
                  selected: _draft.channel == channel,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(channel: channel)),
                ),
            ],
          ),
        ),
        _Group(
          label: l.dateRange,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in OrderDateRange.values)
                ChoiceChip(
                  label: Text(switch (range) {
                    OrderDateRange.any => l.anyDate,
                    OrderDateRange.last7Days => l.last7Days,
                    OrderDateRange.last30Days => l.last30Days,
                  }),
                  selected: _draft.dateRange == range,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(dateRange: range)),
                ),
            ],
          ),
        ),
        Text(
          l.orderFilterNote,
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
            onPressed: () => Navigator.pop(context, const OrderFilter()),
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
