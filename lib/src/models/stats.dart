/// `GET api/statistics/summary` — the four headline tiles.
class SummaryStats {
  SummaryStats({
    required this.revenue,
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalProducts,
  });

  final Metric revenue;
  final Metric totalOrders;
  final Metric totalCustomers;
  final Metric totalProducts;

  factory SummaryStats.fromJson(Map<String, dynamic> j) => SummaryStats(
        revenue: Metric.fromJson(j['revenue']),
        totalOrders: Metric.fromJson(j['totalOrders']),
        totalCustomers: Metric.fromJson(j['totalCustomers']),
        totalProducts: Metric.fromJson(j['totalProducts']),
      );
}

class Metric {
  Metric({
    required this.value,
    required this.previous,
    required this.changePercentage,
  });

  final num value;
  final num previous;
  final num changePercentage;

  factory Metric.fromJson(dynamic j) {
    if (j is! Map) return Metric(value: 0, previous: 0, changePercentage: 0);

    return Metric(
      value: (j['value'] ?? 0) as num,
      previous: (j['previousMonthValue'] ?? 0) as num,
      changePercentage: (j['changePercentage'] ?? 0) as num,
    );
  }
}

/// `GET api/statistics/dashboard?startDate&endDate`
class DashboardStats {
  DashboardStats({
    required this.revenue,
    required this.orders,
    required this.salesOverTime,
    required this.topSellingProducts,
    required this.inventory,
  });

  final RevenueStats revenue;
  final OrderStats orders;
  final List<SalesPoint> salesOverTime;
  final List<TopProduct> topSellingProducts;
  final InventoryStats inventory;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        revenue: RevenueStats.fromJson(j['revenue'] ?? const {}),
        orders: OrderStats.fromJson(j['orders'] ?? const {}),
        salesOverTime: ((j['salesOverTime'] ?? const []) as List)
            .map((e) => SalesPoint.fromJson(e as Map))
            .toList(),
        topSellingProducts: ((j['topSellingProducts'] ?? const []) as List)
            .map((e) => TopProduct.fromJson(e as Map))
            .toList(),
        inventory: InventoryStats.fromJson(j['inventory'] ?? const {}),
      );
}

class RevenueStats {
  RevenueStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.averageOrderValue,
  });

  final num total;
  final num today;
  final num thisWeek;
  final num thisMonth;
  final num averageOrderValue;

  factory RevenueStats.fromJson(Map j) => RevenueStats(
        total: (j['totalRevenue'] ?? 0) as num,
        today: (j['revenueToday'] ?? 0) as num,
        thisWeek: (j['revenueThisWeek'] ?? 0) as num,
        thisMonth: (j['revenueThisMonth'] ?? 0) as num,
        averageOrderValue: (j['averageOrderValue'] ?? 0) as num,
      );
}

class OrderStats {
  OrderStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.statusBreakdown,
  });

  final num total;
  final num today;
  final num thisWeek;
  final num thisMonth;
  final List<StatusCount> statusBreakdown;

  factory OrderStats.fromJson(Map j) => OrderStats(
        total: (j['totalOrders'] ?? 0) as num,
        today: (j['ordersToday'] ?? 0) as num,
        thisWeek: (j['ordersThisWeek'] ?? 0) as num,
        thisMonth: (j['ordersThisMonth'] ?? 0) as num,
        statusBreakdown: ((j['statusBreakdown'] ?? const []) as List)
            .map((e) => StatusCount.fromJson(e as Map))
            .toList(),
      );
}

class StatusCount {
  StatusCount({
    required this.status,
    required this.count,
    required this.percentage,
  });

  final String status;
  final num count;
  final num percentage;

  factory StatusCount.fromJson(Map j) => StatusCount(
        status: '${j['status'] ?? ''}',
        count: (j['count'] ?? 0) as num,
        percentage: (j['percentage'] ?? 0) as num,
      );
}

class SalesPoint {
  SalesPoint({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  final DateTime date;
  final num revenue;
  final num orderCount;

  factory SalesPoint.fromJson(Map j) => SalesPoint(
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
        revenue: (j['revenue'] ?? 0) as num,
        orderCount: (j['orderCount'] ?? 0) as num,
      );
}

class TopProduct {
  TopProduct({
    required this.productId,
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  final String productId;
  final String name;
  final num unitsSold;
  final num revenue;

  factory TopProduct.fromJson(Map j) => TopProduct(
        productId: '${j['productId']}',
        name: '${j['productName'] ?? ''}',
        unitsSold: (j['totalUnitsSold'] ?? 0) as num,
        revenue: (j['totalRevenue'] ?? 0) as num,
      );
}

class InventoryStats {
  InventoryStats({required this.lowStockCount, required this.outOfStockCount});

  final num lowStockCount;
  final num outOfStockCount;

  factory InventoryStats.fromJson(Map j) => InventoryStats(
        lowStockCount: (j['lowStockCount'] ?? j['lowStockProducts'] ?? 0) as num,
        outOfStockCount:
            (j['outOfStockCount'] ?? j['outOfStockProducts'] ?? 0) as num,
      );
}

/// `GET api/admin/behavior/overview` — live traffic and the conversion funnel.
class BehaviorOverview {
  BehaviorOverview({
    required this.sessions,
    required this.productViewSessions,
    required this.cartSessions,
    required this.checkoutSessions,
    required this.purchaseSessions,
    required this.activeNow,
    required this.searches,
    required this.wishlists,
    required this.contactClicks,
  });

  final num sessions;
  final num productViewSessions;
  final num cartSessions;
  final num checkoutSessions;
  final num purchaseSessions;

  /// Visitors on the storefront right now.
  final num activeNow;
  final num searches;
  final num wishlists;
  final num contactClicks;

  /// Sessions that ended in a purchase, as a percentage.
  double get conversionRate =>
      sessions == 0 ? 0 : (purchaseSessions / sessions) * 100;

  factory BehaviorOverview.fromJson(Map<String, dynamic> j) => BehaviorOverview(
        sessions: (j['sessions'] ?? 0) as num,
        productViewSessions: (j['productViewSessions'] ?? 0) as num,
        cartSessions: (j['cartSessions'] ?? 0) as num,
        checkoutSessions: (j['checkoutSessions'] ?? 0) as num,
        purchaseSessions: (j['purchaseSessions'] ?? 0) as num,
        activeNow: (j['activeNow'] ?? 0) as num,
        searches: (j['searches'] ?? 0) as num,
        wishlists: (j['wishlists'] ?? 0) as num,
        contactClicks: (j['contactClicks'] ?? 0) as num,
      );
}

/// `GET api/admin/behavior/sources` — channel / referrer performance.
class SourceRow {
  SourceRow({
    required this.source,
    required this.sessions,
    required this.purchases,
  });

  final String source;
  final num sessions;
  final num purchases;

  factory SourceRow.fromJson(Map<String, dynamic> j) => SourceRow(
        source: '${j['source'] ?? j['name'] ?? 'direct'}',
        sessions: (j['sessions'] ?? 0) as num,
        purchases: (j['purchaseSessions'] ?? j['purchases'] ?? 0) as num,
      );
}
