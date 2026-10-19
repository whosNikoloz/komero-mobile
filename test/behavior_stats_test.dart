import 'package:flutter_test/flutter_test.dart';
import 'package:komero_mobile/src/features/dashboard/stats_range.dart';
import 'package:komero_mobile/src/models/stats.dart';

void main() {
  group('BehaviorOverview', () {
    BehaviorOverview overview(Map<String, dynamic> j) =>
        BehaviorOverview.fromJson(j);

    test('reads the funnel, the channels and the daily series', () {
      final b = overview({
        'sessions': 200,
        'productViewSessions': 120,
        'cartSessions': 40,
        'checkoutSessions': 20,
        'purchaseSessions': 10,
        'contactChannels': {'phone': 5, 'whatsapp': 2},
        'days': [
          {'day': '2026-10-01', 'sessions': 100, 'purchaseSessions': 4},
          {'day': '2026-10-02', 'sessions': 100, 'purchaseSessions': 6},
        ],
      });

      expect(b.conversionRate, 5);
      expect(b.cartAbandonRate, 50); // 40 carts, 20 reached checkout
      expect(b.checkoutAbandonRate, 50); // 20 checkouts, 10 orders
      expect(b.contactChannels['phone'], 5);
      expect(b.days, hasLength(2));
      expect(b.days.first.day.day, 1);
    });

    test('rates stay at zero rather than dividing by nothing', () {
      final b = overview(const {});

      expect(b.conversionRate, 0);
      expect(b.cartAbandonRate, 0);
      expect(b.checkoutAbandonRate, 0);
      expect(b.days, isEmpty);
    });
  });

  group('DashboardStats period totals', () {
    final stats = DashboardStats.fromJson({
      // All-time total — deliberately unrelated to the period below.
      'revenue': {'totalRevenue': 99999, 'averageOrderValue': 7},
      'salesOverTime': [
        {'date': '2026-10-01', 'revenue': 100, 'orderCount': 2},
        {'date': '2026-10-02', 'revenue': 50, 'orderCount': 3},
      ],
    });

    test('sum the daily series, not the lifetime figure', () {
      expect(stats.periodRevenue, 150);
      expect(stats.periodOrders, 5);
      expect(stats.periodAverageOrderValue, 30);
    });

    test('average falls back to the API figure with no orders', () {
      final empty = DashboardStats.fromJson({
        'revenue': {'averageOrderValue': 7},
      });

      expect(empty.periodRevenue, 0);
      expect(empty.periodAverageOrderValue, 7);
    });
  });

  group('StatsRange', () {
    test('a preset covers that many days, today included', () {
      expect(StatsRange.preset(RangePreset.today).days, 1);
      expect(StatsRange.preset(RangePreset.days7).days, 7);
      expect(StatsRange.preset(RangePreset.days90).days, 90);
    });

    test('a custom range keeps its own dates and compares by value', () {
      final a = StatsRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 10));
      final b = StatsRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 10));

      expect(a.days, 10);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(StatsRange.preset(RangePreset.days30)));
    });
  });
}
