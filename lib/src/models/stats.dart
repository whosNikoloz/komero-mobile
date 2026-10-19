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

  /// Takings over the requested period. Summed from the daily series rather
  /// than read off `revenue.total`, which the API counts over the store's
  /// whole life — under a period header that number would be a lie.
  num get periodRevenue =>
      salesOverTime.fold<num>(0, (sum, d) => sum + d.revenue);

  num get periodOrders =>
      salesOverTime.fold<num>(0, (sum, d) => sum + d.orderCount);

  /// Average order value for the period, falling back to the API's own figure
  /// when the period has no orders to divide by.
  num get periodAverageOrderValue =>
      periodOrders == 0 ? revenue.averageOrderValue : periodRevenue / periodOrders;

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

/// One day of the funnel, from `days` on the behaviour overview.
class FunnelDay {
  FunnelDay({
    required this.day,
    required this.sessions,
    required this.productViewSessions,
    required this.cartSessions,
    required this.checkoutSessions,
    required this.purchaseSessions,
  });

  final DateTime day;
  final num sessions;
  final num productViewSessions;
  final num cartSessions;
  final num checkoutSessions;
  final num purchaseSessions;

  factory FunnelDay.fromJson(Map j) => FunnelDay(
        day: DateTime.tryParse('${j['day']}') ?? DateTime.now(),
        sessions: (j['sessions'] ?? 0) as num,
        productViewSessions: (j['productViewSessions'] ?? 0) as num,
        cartSessions: (j['cartSessions'] ?? 0) as num,
        checkoutSessions: (j['checkoutSessions'] ?? 0) as num,
        purchaseSessions: (j['purchaseSessions'] ?? 0) as num,
      );
}

/// `GET api/admin/behavior/overview` — live traffic and the conversion funnel.
class BehaviorOverview {
  BehaviorOverview({
    required this.sessions,
    required this.productViewSessions,
    required this.cartSessions,
    required this.cartViewSessions,
    required this.checkoutSessions,
    required this.purchaseSessions,
    required this.activeNow,
    required this.searches,
    required this.wishlists,
    required this.contactClicks,
    required this.contactChannels,
    required this.days,
  });

  final num sessions;
  final num productViewSessions;
  final num cartSessions;
  final num cartViewSessions;
  final num checkoutSessions;
  final num purchaseSessions;

  /// Visitors on the storefront right now.
  final num activeNow;
  final num searches;
  final num wishlists;
  final num contactClicks;

  /// Contact clicks by channel: phone, whatsapp, email, viber, telegram…
  final Map<String, num> contactChannels;

  /// The funnel day by day, for the traffic trend.
  final List<FunnelDay> days;

  /// Sessions that ended in a purchase, as a percentage.
  double get conversionRate =>
      sessions == 0 ? 0 : (purchaseSessions / sessions) * 100;

  /// Carts that never reached checkout, as a percentage of carts.
  double get cartAbandonRate => cartSessions == 0
      ? 0
      : ((cartSessions - checkoutSessions) / cartSessions) * 100;

  /// Checkouts that never became an order, as a percentage of checkouts.
  double get checkoutAbandonRate => checkoutSessions == 0
      ? 0
      : ((checkoutSessions - purchaseSessions) / checkoutSessions) * 100;

  factory BehaviorOverview.fromJson(Map<String, dynamic> j) => BehaviorOverview(
        sessions: (j['sessions'] ?? 0) as num,
        productViewSessions: (j['productViewSessions'] ?? 0) as num,
        cartSessions: (j['cartSessions'] ?? 0) as num,
        cartViewSessions: (j['cartViewSessions'] ?? 0) as num,
        checkoutSessions: (j['checkoutSessions'] ?? 0) as num,
        purchaseSessions: (j['purchaseSessions'] ?? 0) as num,
        activeNow: (j['activeNow'] ?? 0) as num,
        searches: (j['searches'] ?? 0) as num,
        wishlists: (j['wishlists'] ?? 0) as num,
        contactClicks: (j['contactClicks'] ?? 0) as num,
        contactChannels: {
          for (final e in ((j['contactChannels'] ?? const {}) as Map).entries)
            '${e.key}': (e.value ?? 0) as num,
        },
        days: ((j['days'] ?? const []) as List)
            .map((e) => FunnelDay.fromJson(e as Map))
            .toList(),
      );
}

/// `GET api/admin/behavior/searches` — what shoppers typed into search.
class SearchTerm {
  SearchTerm({
    required this.term,
    required this.searches,
    required this.sessions,
    required this.zeroResultSearches,
  });

  final String term;
  final num searches;
  final num sessions;

  /// Searches that returned nothing: catalog gaps in the shopper's own words.
  final num zeroResultSearches;

  factory SearchTerm.fromJson(Map<String, dynamic> j) => SearchTerm(
        term: '${j['term'] ?? ''}',
        searches: (j['searches'] ?? 0) as num,
        sessions: (j['sessions'] ?? 0) as num,
        zeroResultSearches: (j['zeroResultSearches'] ?? 0) as num,
      );
}

/// `GET api/admin/behavior/products` — per-product interest, not just sales.
class ProductBehavior {
  ProductBehavior({
    required this.productId,
    required this.name,
    required this.image,
    required this.views,
    required this.cartAdds,
    required this.wishlists,
    required this.unitsSold,
    required this.cartRate,
    required this.purchaseRate,
  });

  final String productId;
  final String name;
  final String? image;
  final num views;
  final num cartAdds;
  final num wishlists;
  final num unitsSold;

  /// Views that turned into a cart add, and into an order, as percentages.
  final num? cartRate;
  final num? purchaseRate;

  factory ProductBehavior.fromJson(Map<String, dynamic> j) => ProductBehavior(
        productId: '${j['productId']}',
        name: '${j['name'] ?? ''}',
        image: j['image'] as String?,
        views: (j['views'] ?? 0) as num,
        cartAdds: (j['cartAdds'] ?? 0) as num,
        wishlists: (j['wishlists'] ?? 0) as num,
        unitsSold: (j['unitsSold'] ?? 0) as num,
        cartRate: j['cartRate'] as num?,
        purchaseRate: j['purchaseRate'] as num?,
      );
}

/// How a product list is ordered on `behavior/products`.
enum BehaviorSort {
  views('views'),
  cart('cart'),
  wishlists('wishlists'),
  sold('sold'),
  lowCartRate('low_cart_rate');

  const BehaviorSort(this.wire);

  final String wire;
}

/// `GET api/admin/behavior/abandoned-checkouts` — carts that got as far as
/// checkout and stopped, with how far they got and what they were worth.
class AbandonedSession {
  AbandonedSession({
    required this.sessionId,
    required this.lastActivityAt,
    required this.stepReached,
    required this.value,
    required this.itemCount,
    required this.customerName,
    required this.maskedEmail,
  });

  final String sessionId;
  final DateTime lastActivityAt;

  /// opened | contact | shipping | payment | submitted.
  final String stepReached;
  final num value;
  final int itemCount;
  final String? customerName;
  final String? maskedEmail;

  factory AbandonedSession.fromJson(Map<String, dynamic> j) => AbandonedSession(
        sessionId: '${j['sessionId']}',
        lastActivityAt: DateTime.tryParse('${j['lastActivityAt']}')?.toLocal() ??
            DateTime.now(),
        stepReached: '${j['stepReached'] ?? ''}',
        value: (j['value'] ?? 0) as num,
        itemCount: ((j['items'] ?? const []) as List).length,
        customerName: j['customerName'] as String?,
        maskedEmail: j['maskedEmail'] as String?,
      );
}

/// `GET api/admin/behavior/sources` — channel / referrer performance.
class SourceRow {
  SourceRow({
    required this.source,
    required this.sessions,
    required this.cartSessions,
    required this.purchases,
  });

  final String source;
  final num sessions;
  final num cartSessions;
  final num purchases;

  /// Visits from this source that ordered, as a percentage.
  double get conversionRate => sessions == 0 ? 0 : (purchases / sessions) * 100;

  factory SourceRow.fromJson(Map<String, dynamic> j) => SourceRow(
        source: '${j['source'] ?? j['name'] ?? 'direct'}',
        sessions: (j['sessions'] ?? 0) as num,
        cartSessions: (j['cartSessions'] ?? 0) as num,
        purchases: (j['purchaseSessions'] ?? j['purchases'] ?? 0) as num,
      );
}
