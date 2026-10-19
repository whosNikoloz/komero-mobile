import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/order_stream.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/me.dart';
import '../../models/stats.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/branding.dart';
import '../../widgets/common.dart';
import '../inventory/inventory_screen.dart' show StockFilter, stockFilterProvider;
import '../shell/app_shell.dart' show kNavClearance, navIndexProvider;
import 'behavior_screen.dart';
import 'stats_range.dart';

final meProvider = FutureProvider((ref) => ref.watch(authRepositoryProvider).me());

final summaryProvider =
    FutureProvider((ref) => ref.watch(statsRepositoryProvider).summary());

final dashboardProvider = FutureProvider((ref) {
  final range = ref.watch(statsRangeProvider);

  return ref
      .watch(statsRepositoryProvider)
      .dashboard(from: range.from, to: range.to);
});

/// Live traffic. Polled rather than streamed: the behaviour API rebuilds today's
/// numbers when they are older than 60s, so asking more often just burns
/// battery for the same answer.
final behaviorProvider = StreamProvider((ref) async* {
  final repo = ref.watch(statsRepositoryProvider);
  final range = ref.watch(statsRangeProvider);

  while (true) {
    yield await repo.behavior(from: range.from, to: range.to);
    await Future<void>.delayed(const Duration(seconds: 60));
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final me = ref.watch(meProvider);

    // A new order should move the numbers without the operator pulling down.
    ref.listen(orderEventsProvider, (_, _) {
      ref.invalidate(summaryProvider);
      ref.invalidate(dashboardProvider);
    });

    return AppScaffold(
      centerTitle: true,
      titleWidget: StoreIdentity(fallbackTitle: l.dashboard, onDark: true),
      actions: [
        const _LivePill(),
        const SizedBox(width: 12),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(summaryProvider);
          ref.invalidate(dashboardProvider);
          ref.invalidate(behaviorProvider);
          await ref.read(summaryProvider.future);
        },
        child: AsyncView(
          value: me,
          onRetry: () => ref.invalidate(meProvider),
          data: (me) => me.can(Perm.analytics)
              ? const _DashboardBody()
              : EmptyState(message: l.permissionDenied, icon: Icons.lock_outline),
        ),
      ),
    );
  }
}

/// Visitors on the storefront right now, straight off the behaviour API.
class _LivePill extends ConsumerWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final active = ref.watch(behaviorProvider).value?.activeNow;

    if (active == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$active ${context.l.liveNow.toLowerCase()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home answers three questions, in this order: how is today going, what needs
/// me, and how is the month trending.
///
/// It used to open with a 2x2 grid of month-to-date totals — the slowest-moving
/// numbers in the app, each in an identical card with a decorative icon, none
/// of them anything an operator could act on. Today's takings lead now, the
/// work that is waiting comes second and routes to the tab that does it, and
/// the month is a list of labelled rows further down.
class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final tag = context.localeTag;
    final summary = ref.watch(summaryProvider);
    final dashboard = ref.watch(dashboardProvider);
    final behavior = ref.watch(behaviorProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, kNavClearance),
      children: [
        _TodayPanel(
          revenue: dashboard.value?.revenue.today,
          orders: dashboard.value?.orders.today,
          behavior: behavior.value,
        ),
        const SizedBox(height: 18),
        const RangeChips(),
        const SizedBox(height: 18),
        dashboard.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TaskList(stats: d),
              if (behavior.value case final b?) ...[
                _BehaviorCard(behavior: b),
                const SizedBox(height: 22),
              ],
              SectionTitle(ref.watch(statsRangeProvider).label(context)),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _MetricRow(
                      label: l.revenue,
                      value: money(d.periodRevenue, locale: tag),
                    ),
                    _MetricRow(
                      label: l.orders,
                      value: compactNumber(d.periodOrders, locale: tag),
                    ),
                    _MetricRow(
                      label: l.averageOrderValue,
                      value: money(d.periodAverageOrderValue, locale: tag),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionTitle(l.salesOverTime),
              Panel(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                child: SizedBox(
                  height: 180,
                  child: _SalesChart(points: d.salesOverTime),
                ),
              ),
              const SizedBox(height: 22),
              SectionTitle(l.last30Days),
              summary.when(
                loading: () => const _MetricsSkeleton(),
                error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(summaryProvider),
                ),
                // One panel of labelled rows rather than four identical tiles:
                // the labels line up, the deltas line up, and no number has to
                // carry a decorative icon to fill out a card.
                data: (s) => Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _MetricRow(
                        label: l.revenue,
                        value: money(s.revenue.value, locale: tag),
                        deltaPercent: s.revenue.changePercentage,
                      ),
                      _MetricRow(
                        label: l.orders,
                        value: compactNumber(s.totalOrders.value, locale: tag),
                        deltaPercent: s.totalOrders.changePercentage,
                      ),
                      _MetricRow(
                        label: l.customers,
                        value: compactNumber(s.totalCustomers.value, locale: tag),
                        deltaPercent: s.totalCustomers.changePercentage,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (d.topSellingProducts.isNotEmpty) ...[
                SectionTitle(l.topProducts),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < d.topSellingProducts.length.clamp(0, 5); i++)
                        _TopProductRow(
                          rank: i + 1,
                          product: d.topSellingProducts[i],
                          isLast: i == d.topSellingProducts.length.clamp(0, 5) - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],
              // The funnel is the slowest read on the screen, so it sits last.
              if (behavior.value case final b?) ...[
                SectionTitle(
                  l.funnel,
                  trailing: _BehaviorLink(label: l.viewAll),
                ),
                Panel(child: FunnelBars(behavior: b, showDropOff: false)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Today in the one place an operator looks first: money taken, orders placed,
/// and the live traffic that explains both.
class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.revenue,
    required this.orders,
    required this.behavior,
  });

  final num? revenue;
  final num? orders;
  final BehaviorOverview? behavior;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;
    final b = behavior;

    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.today,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          // An em dash until the figure lands, rather than a zero: a store
          // that has taken nothing today and a store whose numbers have not
          // arrived are different facts.
          Text(
            revenue == null ? '—' : money(revenue!, locale: tag),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -1,
              color: c.text,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.orders,
                  value: orders == null ? '—' : compactNumber(orders!, locale: tag),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: l.sessions,
                  value: b == null ? '—' : compactNumber(b.sessions, locale: tag),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: l.conversionRate,
                  value: b == null ? '—' : '${b.conversionRate.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What needs the operator, and the way to go and do it. Each row switches tab
/// and sets the filter that shows exactly the rows it counted, so the number on
/// Home and the list it opens can never disagree.
class _TaskList extends ConsumerWidget {
  const _TaskList({required this.stats});

  final DashboardStats stats;

  /// Everything before "shipped" is still work on someone's desk. Matched on
  /// the status name because the breakdown arrives as server-side strings; an
  /// unrecognised vocabulary counts zero and the row simply stays hidden.
  static const _openStatuses = {'pending', 'paid', 'processing'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;

    final out = stats.inventory.outOfStockCount.toInt();
    final low = stats.inventory.lowStockCount.toInt();

    final open = stats.orders.statusBreakdown
        .where((s) => _openStatuses.contains(s.status.toLowerCase()))
        .fold<num>(0, (sum, s) => sum + s.count)
        .toInt();

    if (out == 0 && low == 0 && open == 0) return const SizedBox.shrink();

    void toInventory(StockFilter filter) {
      ref.read(stockFilterProvider.notifier).state = filter;
      ref.read(navIndexProvider.notifier).state = 2;
    }

    final tasks = [
      if (open > 0)
        (
          icon: Icons.receipt_long_outlined,
          color: c.info,
          text: l.ordersToFulfil,
          count: open,
          onTap: () {
            ref.read(navIndexProvider.notifier).state = 1;
          },
        ),
      if (out > 0)
        (
          icon: Icons.remove_shopping_cart_outlined,
          color: c.error,
          text: l.outOfStock,
          count: out,
          onTap: () => toInventory(StockFilter.out),
        ),
      if (low > 0)
        (
          icon: Icons.warning_amber_outlined,
          color: c.warning,
          text: l.lowStock,
          count: low,
          onTap: () => toInventory(StockFilter.low),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.needsAttention),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, t) in tasks.indexed)
                _Task(
                  icon: t.icon,
                  color: t.color,
                  text: t.text,
                  count: t.count,
                  onTap: t.onTap,
                  isLast: i == tasks.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

class _Task extends StatelessWidget {
  const _Task({
    required this.icon,
    required this.color,
    required this.text,
    required this.count,
    required this.onTap,
    required this.isLast,
  });

  final IconData icon;
  final Color color;
  final String text;
  final int count;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.textDisabled),
          ],
        ),
      ),
    );
  }
}

/// One line of the month: what it is on the left, what it is worth on the
/// right, and how it moved underneath.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.deltaPercent,
    this.isLast = false,
  });

  final String label;
  final String value;
  final num? deltaPercent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final delta = deltaPercent;
    final up = (delta ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          if (delta != null && delta != 0) ...[
            const SizedBox(width: 8),
            // Fixed width, so every delta in the column starts at the same x
            // and the values above them stay in one line.
            SizedBox(
              width: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    up ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 13,
                    color: up ? c.success : c.error,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${delta.abs().toStringAsFixed(1)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: up ? c.success : c.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4 * 48,
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.border),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: c.textMuted),
          maxLines: 2,
        ),
      ],
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.points});

  final List<SalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (points.isEmpty) {
      return Center(
        child: Text(
          context.l.noResults,
          style: TextStyle(color: c.textMuted, fontSize: 13),
        ),
      );
    }

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].revenue.toDouble()),
    ];

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, _) => Text(
                compactNumber(value),
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // One label per ~5 days keeps the axis readable on a phone.
              interval: (points.length / 5).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final i = value.round();

                if (i < 0 || i >= points.length) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${points[i].date.day}/${points[i].date.month}',
                    style: TextStyle(fontSize: 10, color: c.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.overlay,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    money(s.y, locale: context.localeTag),
                    TextStyle(color: c.onOverlay, fontSize: 12),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: c.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.primary.withValues(alpha: 0.25),
                  c.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.rank,
    required this.product,
    required this.isLast,
  });

  final int rank;
  final TopProduct product;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textDisabled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l.unitsSold(product.unitsSold.toInt()),
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ],
            ),
          ),
          Text(
            money(product.revenue, locale: context.localeTag),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
          ),
        ],
      ),
    );
  }
}

/// The way into the full behaviour report, and the two numbers that make an
/// operator want to open it: the share of carts and of checkouts that were
/// walked away from. A plain "Customer behaviour ›" row sat at the foot of
/// Home and was never tapped — it said where it went, not why to go.
class _BehaviorCard extends StatelessWidget {
  const _BehaviorCard({required this.behavior});

  final BehaviorOverview behavior;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;

    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openBehavior(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.insights_outlined, size: 18, color: c.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.customerBehavior,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: c.textDisabled),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: l.cartAbandonment,
                      value: '${behavior.cartAbandonRate.toStringAsFixed(0)}%',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: l.checkoutAbandonment,
                      value:
                          '${behavior.checkoutAbandonRate.toStringAsFixed(0)}%',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: l.searchesLabel,
                      value: compactNumber(behavior.searches, locale: tag),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BehaviorLink extends StatelessWidget {
  const _BehaviorLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openBehavior(context),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.c.primary,
        ),
      ),
    );
  }
}

void openBehavior(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BehaviorScreen()),
    );
