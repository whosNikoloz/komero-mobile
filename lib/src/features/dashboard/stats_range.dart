import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/tokens.dart';
import '../../l10n_ext.dart';

/// The period every analytics number on Home and in Behaviour is read over.
///
/// One range object rather than a `days` int, because a custom range has no
/// day count that round-trips: the API wants two dates and the chip row wants
/// to know which preset is lit.
@immutable
class StatsRange {
  const StatsRange._(this.preset, this.from, this.to);

  /// A preset counted back from today, today included — 7 days means today
  /// and the six before it, which is what an operator means by "this week".
  factory StatsRange.preset(RangePreset preset) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    return StatsRange._(
      preset,
      end.subtract(Duration(days: preset.days - 1)),
      end,
    );
  }

  factory StatsRange.custom(DateTime from, DateTime to) =>
      StatsRange._(RangePreset.custom, from, to);

  final RangePreset preset;
  final DateTime from;
  final DateTime to;

  /// Whole days covered, today included. Used to size the previous period.
  int get days => to.difference(from).inDays + 1;

  String label(BuildContext context) {
    final l = context.l;

    return switch (preset) {
      RangePreset.today => l.today,
      RangePreset.days7 => l.rangeDays(7),
      RangePreset.days30 => l.rangeDays(30),
      RangePreset.days90 => l.rangeDays(90),
      RangePreset.custom =>
        '${shortDay(from, context)} – ${shortDay(to, context)}',
    };
  }

  static String shortDay(DateTime d, BuildContext context) =>
      MaterialLocalizations.of(context).formatShortDate(d);

  @override
  bool operator ==(Object other) =>
      other is StatsRange &&
      other.preset == preset &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(preset, from, to);
}

enum RangePreset {
  today(1),
  days7(7),
  days30(30),
  days90(90),
  custom(0);

  const RangePreset(this.days);

  final int days;
}

/// Shared by Home and the Behaviour screen, so moving the period in one place
/// moves it in both and the two can never show different weeks.
final statsRangeProvider =
    StateProvider((_) => StatsRange.preset(RangePreset.days30));

/// The period chips. Horizontally scrollable: five options do not fit a phone
/// at a tappable size, and a wrapping row would push the numbers down a line.
class RangeChips extends ConsumerWidget {
  const RangeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final range = ref.watch(statsRangeProvider);

    Future<void> pickCustom() async {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3),
        lastDate: now,
        initialDateRange: DateTimeRange(start: range.from, end: range.to),
      );

      if (picked == null) return;

      ref.read(statsRangeProvider.notifier).state =
          StatsRange.custom(picked.start, picked.end);
    }

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in RangePreset.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: p == RangePreset.custom
                    ? (range.preset == p ? range.label(context) : l.customRange)
                    : StatsRange.preset(p).label(context),
                icon: p == RangePreset.custom ? Icons.date_range_outlined : null,
                selected: range.preset == p,
                onTap: () {
                  if (p == RangePreset.custom) {
                    pickCustom();

                    return;
                  }

                  ref.read(statsRangeProvider.notifier).state =
                      StatsRange.preset(p);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? c.primaryForeground : c.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.primaryForeground : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
