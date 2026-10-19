import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/stats.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import 'stats_range.dart';

/// Everything on this screen is read over the shared period, so each provider
/// watches the range and nothing has to be invalidated by hand when it moves.
final behaviorOverviewProvider = FutureProvider((ref) {
  final r = ref.watch(statsRangeProvider);

  return ref.watch(statsRepositoryProvider).behavior(from: r.from, to: r.to);
});

final sourcesProvider = FutureProvider((ref) {
  final r = ref.watch(statsRangeProvider);

  return ref.watch(statsRepositoryProvider).sources(from: r.from, to: r.to);
});

final searchTermsProvider = FutureProvider((ref) {
  final r = ref.watch(statsRepositoryProvider);
  final range = ref.watch(statsRangeProvider);

  return r.searches(from: range.from, to: range.to, limit: 20);
});

/// Which column the product list is ranked on. Views answers "what are they
/// looking at"; low cart rate answers "what are they looking at and not
/// buying" — the two questions an operator actually asks of this table.
final productSortProvider = StateProvider((_) => BehaviorSort.views);

final productBehaviorProvider = FutureProvider((ref) {
  final repo = ref.watch(statsRepositoryProvider);
  final range = ref.watch(statsRangeProvider);
  final sort = ref.watch(productSortProvider);

  return repo.productBehavior(
    from: range.from,
    to: range.to,
    sort: sort,
    limit: 15,
  );
});

final abandonedProvider = FutureProvider((ref) {
  final repo = ref.watch(statsRepositoryProvider);
  final range = ref.watch(statsRangeProvider);

  return repo.abandonedCheckouts(from: range.from, to: range.to, pageSize: 15);
});

/// What shoppers did on the storefront, as opposed to what they bought: the
/// funnel and where it leaks, where the visits came from, what they searched
/// for, which products they looked at, and the checkouts they walked away
/// from. Home answers "how is the store doing"; this answers "why".
///
/// Three tabs rather than one long scroll. Stacked, the four lists ran to
/// several screens of scrolling and the funnel — the one thing that explains
/// all of them — was off screen by the time an operator reached the numbers
/// it explains. A tab is a phone's version of putting them side by side.
class BehaviorScreen extends ConsumerWidget {
  const BehaviorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;

    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: l.customerBehavior,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  const RangeChips(),
                  const SizedBox(height: 12),
                  // A segmented control, not Material's underlined tabs: it
                  // reads as a switch between three views of the same period
                  // rather than as three pages.
                  Container(
                    height: 34,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.surfaceHover,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: TabBar(
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      labelPadding: EdgeInsets.zero,
                      labelColor: c.text,
                      unselectedLabelColor: c.textMuted,
                      labelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(text: l.tabOverview),
                        Tab(text: l.tabTraffic),
                        Tab(text: l.tabCatalog),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [_OverviewTab(), _TrafficTab(), _CatalogTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pull-to-refresh over a tab's own scroll view. Each tab refreshes what it
/// shows: reloading four lists because the operator tugged at one of them is
/// four requests to answer one question.
class _Tab extends StatelessWidget {
  const _Tab({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: children,
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final overview = ref.watch(behaviorOverviewProvider);

    return _Tab(
      onRefresh: () async {
        ref.invalidate(behaviorOverviewProvider);
        await ref.read(behaviorOverviewProvider.future);
      },
      children: [
        AsyncView(
          value: overview,
          onRetry: () => ref.invalidate(behaviorOverviewProvider),
          loading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          ),
          data: (b) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatGrid(behavior: b),
              const SizedBox(height: 18),
              SectionTitle(l.funnel),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: FunnelBars(behavior: b),
              ),
              const SizedBox(height: 18),
              if (b.days.length > 1) ...[
                SectionTitle(l.visitsOverTime),
                Panel(
                  padding: const EdgeInsets.fromLTRB(6, 18, 14, 6),
                  child: SizedBox(height: 150, child: _VisitsChart(days: b.days)),
                ),
                const SizedBox(height: 18),
              ],
              if (b.contactClicks > 0) ...[
                SectionTitle(l.contactClicks),
                Panel(
                  padding: EdgeInsets.zero,
                  child: _ContactChannels(behavior: b),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TrafficTab extends ConsumerWidget {
  const _TrafficTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Tab(
      onRefresh: () async {
        ref.invalidate(sourcesProvider);
        ref.invalidate(searchTermsProvider);
        await ref.read(sourcesProvider.future);
      },
      children: const [_Sources(), _Searches()],
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Tab(
      onRefresh: () async {
        ref.invalidate(productBehaviorProvider);
        ref.invalidate(abandonedProvider);
        await ref.read(productBehaviorProvider.future);
      },
      children: const [_Products(), _Abandoned()],
    );
  }
}

/// Six numbers in one card, three to a row. They were two to a row in three
/// stacked rows, which pushed the funnel below the fold for the sake of white
/// space these figures do not need: each is a short number with a short label.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.behavior});

  final BehaviorOverview behavior;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;

    final cells = [
      (l.sessions, compactNumber(behavior.sessions, locale: tag), false),
      (
        l.conversionRate,
        '${behavior.conversionRate.toStringAsFixed(1)}%',
        false,
      ),
      (l.liveNow, compactNumber(behavior.activeNow, locale: tag), false),
      (
        l.cartAbandonment,
        '${behavior.cartAbandonRate.toStringAsFixed(0)}%',
        true,
      ),
      (
        l.checkoutAbandonment,
        '${behavior.checkoutAbandonRate.toStringAsFixed(0)}%',
        true,
      ),
      (l.searchesLabel, compactNumber(behavior.searches, locale: tag), false),
    ];

    Widget row(Iterable<(String, String, bool)> items) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value, warn) in items)
              Expanded(child: _Cell(label: label, value: value, warn: warn)),
          ],
        );

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        children: [
          row(cells.take(3)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1, thickness: 1, color: c.border),
          ),
          row(cells.skip(3)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: warn ? c.warning : c.text,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 2,
          style: TextStyle(fontSize: 10.5, height: 1.25, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Viewed → cart → checkout → purchased, each bar relative to total sessions,
/// with what was lost between one step and the next on the right.
///
/// Public, and shared with Home: the funnel reads the same in both places and
/// two copies of it would be two things to keep agreeing.
class FunnelBars extends StatelessWidget {
  const FunnelBars({super.key, required this.behavior, this.showDropOff = true});

  final BehaviorOverview behavior;
  final bool showDropOff;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final total = behavior.sessions == 0 ? 1 : behavior.sessions;

    final steps = [
      (l.sessions, behavior.sessions, c.textSecondary),
      (l.funnelViewed, behavior.productViewSessions, c.info),
      (l.funnelCart, behavior.cartSessions, c.primary),
      (l.funnelCheckout, behavior.checkoutSessions, c.warning),
      (l.funnelPurchased, behavior.purchaseSessions, c.success),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (label, value, color)) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 9),
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
                    // How many of the previous step's visitors stayed. The
                    // step that loses the most is the one worth fixing, and
                    // raw counts hide that whenever traffic is uneven.
                    if (showDropOff && i > 0)
                      Text(
                        _kept(steps[i - 1].$2, value),
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      compactNumber(value, locale: context.localeTag),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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

  static String _kept(num previous, num value) =>
      previous == 0 ? '—' : '${(value / previous * 100).toStringAsFixed(0)}%';
}

/// Visits and orders on the same axis, so a traffic spike that bought nothing
/// is visible as a gap rather than as a good day.
class _VisitsChart extends StatelessWidget {
  const _VisitsChart({required this.days});

  final List<FunnelDay> days;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final sessions = [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].sessions.toDouble()),
    ];
    final purchases = [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].purchaseSessions.toDouble()),
    ];

    final maxY = sessions.map((s) => s.y).reduce((a, b) => a > b ? a : b);

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
              reservedSize: 34,
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
              interval: (days.length / 5).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final i = value.round();

                if (i < 0 || i >= days.length) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${days[i].day.day}/${days[i].day.month}',
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
                    '${s.y.toInt()}',
                    TextStyle(color: c.onOverlay, fontSize: 12),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: sessions,
            isCurved: true,
            curveSmoothness: 0.25,
            color: c.info,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.info.withValues(alpha: 0.22),
                  c.info.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: purchases,
            isCurved: true,
            curveSmoothness: 0.25,
            color: c.success,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _ContactChannels extends StatelessWidget {
  const _ContactChannels({required this.behavior});

  final BehaviorOverview behavior;

  @override
  Widget build(BuildContext context) {
    final entries = behavior.contactChannels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return _Rows([
        _Row(label: context.l.contactClicks, value: '${behavior.contactClicks}'),
      ]);
    }

    return _Rows([
      for (final e in entries)
        _Row(label: _channelLabel(e.key), value: '${e.value}'),
    ]);
  }

  /// Channel names arrive as the wire's own words (phone, whatsapp, viber…).
  /// They are brand names, so they are capitalised rather than translated.
  static String _channelLabel(String key) =>
      key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
}

class _Sources extends ConsumerWidget {
  const _Sources();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final tag = context.localeTag;

    return _Section(
      title: l.trafficSources,
      value: ref.watch(sourcesProvider),
      onRetry: () => ref.invalidate(sourcesProvider),
      builder: (rows) => _Rows([
        for (final r in rows.take(8))
          _Row(
            label: r.source.isEmpty ? l.sourceDirect : r.source,
            value: compactNumber(r.sessions, locale: tag),
            sub: '${r.conversionRate.toStringAsFixed(1)}% · ${compactNumber(r.purchases, locale: tag)}',
          ),
      ]),
    );
  }
}

class _Searches extends ConsumerWidget {
  const _Searches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final tag = context.localeTag;

    return _Section(
      title: l.searchTerms,
      value: ref.watch(searchTermsProvider),
      onRetry: () => ref.invalidate(searchTermsProvider),
      builder: (terms) => _Rows([
        for (final t in terms)
          _Row(
            label: t.term,
            value: compactNumber(t.searches, locale: tag),
            // A term people search and the catalog cannot answer is a
            // shopping list the store did not know it had.
            sub: t.zeroResultSearches > 0
                ? l.noResultSearches(t.zeroResultSearches.toInt())
                : null,
            subIsWarning: t.zeroResultSearches > 0,
          ),
      ]),
    );
  }
}

class _Products extends ConsumerWidget {
  const _Products();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;
    final sort = ref.watch(productSortProvider);

    String sortLabel(BehaviorSort s) => switch (s) {
          BehaviorSort.views => l.sortMostViewed,
          BehaviorSort.cart => l.sortMostAddedToCart,
          BehaviorSort.wishlists => l.sortMostWishlisted,
          BehaviorSort.sold => l.sortBestSelling,
          BehaviorSort.lowCartRate => l.sortLowestCartRate,
        };

    return _Section(
      title: l.productInterest,
      trailing: PopupMenuButton<BehaviorSort>(
        initialValue: sort,
        onSelected: (s) => ref.read(productSortProvider.notifier).state = s,
        itemBuilder: (_) => [
          for (final s in BehaviorSort.values)
            PopupMenuItem(value: s, child: Text(sortLabel(s))),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sortLabel(sort),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: c.primary),
          ],
        ),
      ),
      value: ref.watch(productBehaviorProvider),
      onRetry: () => ref.invalidate(productBehaviorProvider),
      builder: (products) => _Rows([
        for (final p in products)
          _Row(
            leading: EntityThumb(path: p.image, size: 32),
            label: p.name,
            value: compactNumber(p.views, locale: tag),
            valueSub: l.viewsLabel,
            sub: '${l.cartAdds}: ${compactNumber(p.cartAdds, locale: tag)}'
                '${p.cartRate == null ? '' : ' · ${p.cartRate!.toStringAsFixed(0)}%'}'
                ' · ${l.sold}: ${compactNumber(p.unitsSold, locale: tag)}',
          ),
      ]),
    );
  }
}

class _Abandoned extends ConsumerWidget {
  const _Abandoned();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final tag = context.localeTag;

    String step(String wire) => switch (wire.toLowerCase()) {
          'opened' => l.stepOpened,
          'contact' => l.stepContact,
          'shipping' => l.stepShipping,
          'payment' => l.stepPayment,
          'submitted' => l.stepSubmitted,
          _ => wire,
        };

    return _Section(
      title: l.abandonedCheckouts,
      value: ref.watch(abandonedProvider),
      onRetry: () => ref.invalidate(abandonedProvider),
      isEmpty: (p) => p.data.isEmpty,
      builder: (paged) => _Rows([
        for (final a in paged.data)
          _Row(
            label: a.customerName ?? a.maskedEmail ?? l.guestShopper,
            value: money(a.value, locale: tag),
            sub: '${step(a.stepReached)} · ${shortDate(a.lastActivityAt, locale: tag)}',
          ),
      ]),
    );
  }
}

/// A titled block that handles its own loading, error and empty states — four
/// sections needed the same three branches, and spelling them out four times
/// is how they drift apart.
class _Section<T> extends StatelessWidget {
  const _Section({
    required this.title,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.trailing,
    this.isEmpty,
  });

  final String title;
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final Widget? trailing;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    final empty = value.value != null &&
        (isEmpty?.call(value.value as T) ??
            (value.value is List && (value.value as List).isEmpty));

    if (empty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title, trailing: trailing),
        Panel(
          padding: EdgeInsets.zero,
          child: value.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: ErrorState(error: e, onRetry: onRetry),
            ),
            data: builder,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(message: context.l.noResults),
      );
    }

    return Column(
      children: [
        for (final (i, r) in rows.indexed)
          _RowTile(row: r, isLast: i == rows.length - 1),
      ],
    );
  }
}

/// The data for one list line. A record rather than a widget would do, but a
/// class keeps the call sites named at the point they are read.
class _Row {
  const _Row({
    required this.label,
    required this.value,
    this.sub,
    this.valueSub,
    this.leading,
    this.subIsWarning = false,
  });

  final String label;
  final String value;
  final String? sub;
  final String? valueSub;
  final Widget? leading;
  final bool subIsWarning;
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.isLast});

  final _Row row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          if (row.leading != null) ...[row.leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
                if (row.sub case final sub?) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: row.subIsWarning ? c.warning : c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              if (row.valueSub case final s?)
                Text(s, style: TextStyle(fontSize: 10.5, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
