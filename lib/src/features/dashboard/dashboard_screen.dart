import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/order_stream.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/me.dart';
import '../../models/stats.dart';
import '../../widgets/branding.dart';
import '../../widgets/common.dart';

final meProvider = FutureProvider((ref) => ref.watch(authRepositoryProvider).me());

final summaryProvider =
    FutureProvider((ref) => ref.watch(statsRepositoryProvider).summary());

final dashboardProvider = FutureProvider((ref) {
  final now = DateTime.now();

  return ref.watch(statsRepositoryProvider).dashboard(
        from: now.subtract(const Duration(days: 29)),
        to: now,
      );
});

/// Live traffic. Polled rather than streamed: the behaviour API rebuilds today's
/// numbers when they are older than 60s, so asking more often just burns
/// battery for the same answer.
final behaviorProvider = StreamProvider((ref) async* {
  final repo = ref.watch(statsRepositoryProvider);
  final now = DateTime.now();

  while (true) {
    yield await repo.behavior(from: now.subtract(const Duration(days: 29)), to: now);
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: StoreIdentity(fallbackTitle: l.dashboard),
        actions: [
          const _LivePill(),
          const SizedBox(width: 12),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        summary.when(
          loading: () => const _TileGridSkeleton(),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(summaryProvider),
          ),
          data: (s) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatTile(
                label: l.revenue,
                value: money(s.revenue.value, locale: tag),
                deltaPercent: s.revenue.changePercentage,
                icon: Icons.payments_outlined,
              ),
              StatTile(
                label: l.orders,
                value: compactNumber(s.totalOrders.value, locale: tag),
                deltaPercent: s.totalOrders.changePercentage,
                icon: Icons.receipt_long_outlined,
              ),
              StatTile(
                label: l.customers,
                value: compactNumber(s.totalCustomers.value, locale: tag),
                deltaPercent: s.totalCustomers.changePercentage,
                icon: Icons.people_outline,
              ),
              StatTile(
                label: l.products,
                value: compactNumber(s.totalProducts.value, locale: tag),
                deltaPercent: s.totalProducts.changePercentage,
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        behavior.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (b) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(l.liveNow),
              Panel(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: l.conversionRate,
                            value: '${b.conversionRate.toStringAsFixed(1)}%',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: l.sessions,
                            value: compactNumber(b.sessions, locale: tag),
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: l.search,
                            value: compactNumber(b.searches, locale: tag),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Funnel(behavior: b),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
              if (d.inventory.lowStockCount > 0 || d.inventory.outOfStockCount > 0) ...[
                SectionTitle(l.needsAttention),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (d.inventory.outOfStockCount > 0)
                        _AlertRow(
                          icon: Icons.remove_shopping_cart_outlined,
                          color: context.c.error,
                          text: l.outOfStockCount(d.inventory.outOfStockCount.toInt()),
                        ),
                      if (d.inventory.lowStockCount > 0)
                        _AlertRow(
                          icon: Icons.warning_amber_outlined,
                          color: context.c.warning,
                          text: l.lowStockCount(d.inventory.lowStockCount.toInt()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SectionTitle(l.salesOverTime),
              Panel(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                child: SizedBox(
                  height: 180,
                  child: _SalesChart(points: d.salesOverTime),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: l.averageOrderValue,
                      value: money(d.revenue.averageOrderValue, locale: tag),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: l.today,
                      value: money(d.revenue.today, locale: tag),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                const SizedBox(height: 24),
              ],
              if (d.orders.statusBreakdown.isNotEmpty) ...[
                SectionTitle(l.orders),
                Panel(
                  child: Column(
                    children: [
                      for (final s in d.orders.statusBreakdown)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.status,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.c.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '${s.count}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.c.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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

/// Viewed → cart → checkout → purchased, each bar relative to total sessions.
class _Funnel extends StatelessWidget {
  const _Funnel({required this.behavior});

  final BehaviorOverview behavior;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final total = behavior.sessions == 0 ? 1 : behavior.sessions;

    final steps = [
      (l.funnelViewed, behavior.productViewSessions, c.info),
      (l.funnelCart, behavior.cartSessions, c.primary),
      (l.funnelCheckout, behavior.checkoutSessions, c.warning),
      (l.funnelPurchased, behavior.purchaseSessions, c.success),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value, color) in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (value / total).clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    backgroundColor: c.surfaceHover,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceHover,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
              ),
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _TileGridSkeleton extends StatelessWidget {
  const _TileGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.border),
          ),
        ),
      ),
    );
  }
}
