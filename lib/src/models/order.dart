/// Mirrors `DomainLayer.Common.Enums.OrderStatus` — integer on the wire.
enum OrderStatus {
  pending(0),
  paid(1),
  processing(2),
  shipped(3),
  delivered(4),
  cancelled(5),
  refunded(6);

  const OrderStatus(this.wire);

  final int wire;

  /// The wire carries either the integer or the C# enum's name — the order
  /// list and the live event stream disagree about which, and the web admin
  /// normalises both (`normalizeStatus` in `commerce/components/admin/order/
  /// orders-table.tsx`). Parsing only the integer is why every order read as
  /// pending: `int.tryParse('Delivered')` is null, and null matched nothing.
  static OrderStatus fromWire(Object? v) {
    if (v is OrderStatus) return v;

    final i = v is int ? v : int.tryParse('$v');

    if (i != null) {
      return OrderStatus.values.firstWhere(
        (s) => s.wire == i,
        orElse: () => OrderStatus.pending,
      );
    }

    final name = '$v'.trim().toLowerCase();

    return OrderStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == name,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Which sales channel the order came from.
enum OrderChannel {
  webShop(1),
  b2b(2),

  /// Recorded at a Komero POS till — its status changes only via till returns,
  /// so the app never offers status edits on these.
  pos(3);

  const OrderChannel(this.wire);

  final int wire;

  /// Integer or enum name, for the same reason as [OrderStatus.fromWire].
  static OrderChannel? fromWire(Object? v) {
    if (v == null) return null;

    if (v is OrderChannel) return v;

    final i = v is int ? v : int.tryParse('$v');

    if (i != null) {
      for (final c in OrderChannel.values) {
        if (c.wire == i) return c;
      }

      return null;
    }

    final name = '$v'.trim().toLowerCase();

    for (final c in OrderChannel.values) {
      if (c.name.toLowerCase() == name) return c;
    }

    return null;
  }
}

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.total,
    this.subtotal = 0,
    this.tax = 0,
    this.shippingCost = 0,
    this.discount = 0,
    this.channel,
    this.customerName,
    this.coverImage,
    this.isGuestOrder = false,
  });

  final String id;
  final DateTime? date;
  final OrderStatus status;
  final int items;
  final num total;
  final num subtotal;
  final num tax;
  final num shippingCost;
  final num discount;
  final OrderChannel? channel;
  final String? customerName;
  final String? coverImage;
  final bool isGuestOrder;

  bool get isPos => channel == OrderChannel.pos;

  factory OrderSummary.fromJson(Map<String, dynamic> j) {
    final images = j['images'] as List?;

    return OrderSummary(
      id: '${j['id']}',
      date: DateTime.tryParse('${j['date']}'),
      status: OrderStatus.fromWire(j['status']),
      items: (j['items'] ?? 0) is int
          ? j['items'] as int
          : int.tryParse('${j['items']}') ?? 0,
      total: (j['total'] ?? 0) as num,
      subtotal: (j['subtotal'] ?? 0) as num,
      tax: (j['tax'] ?? 0) as num,
      shippingCost: (j['shippingCost'] ?? 0) as num,
      discount: (j['discount'] ?? 0) as num,
      channel: OrderChannel.fromWire(j['channel']),
      customerName: j['customerName'] as String?,
      coverImage: images == null || images.isEmpty
          ? null
          // Order images are objects with `imagePath`, never bare strings.
          : '${(images.first as Map)['imagePath']}',
      isGuestOrder: j['isGuestOrder'] == true,
    );
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.productId,
    this.sku,
    this.image,
  });

  final String id;
  final String name;
  final num price;
  final int quantity;
  final String? productId;
  final String? sku;
  final String? image;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        price: (j['price'] ?? 0) as num,
        quantity: (j['quantity'] ?? 0) is int
            ? j['quantity'] as int
            : int.tryParse('${j['quantity']}') ?? 0,
        productId: j['productId'] as String?,
        sku: j['sku'] as String?,
        image: j['image'] as String?,
      );
}

class OrderCustomer {
  OrderCustomer({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  String get fullName => '$firstName $lastName'.trim();

  factory OrderCustomer.fromJson(Map j) => OrderCustomer(
        firstName: '${j['firstName'] ?? ''}',
        lastName: '${j['lastName'] ?? ''}',
        email: '${j['email'] ?? ''}',
        phoneNumber: '${j['phoneNumber'] ?? ''}',
      );
}

class OrderDetail extends OrderSummary {
  OrderDetail({
    required super.id,
    required super.date,
    required super.status,
    required super.items,
    required super.total,
    super.subtotal,
    super.tax,
    super.shippingCost,
    super.discount,
    super.channel,
    super.customerName,
    super.coverImage,
    required this.orderItems,
    required this.shippingAddress,
    required this.currency,
    this.shippingLatitude,
    this.shippingLongitude,
    this.trackingNumber,
    this.estimatedDelivery,
    this.orderNumber,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentProvider,
    this.customer,
  });

  final List<OrderItem> orderItems;
  final String shippingAddress;

  /// Set when the shopper dropped a pin at checkout. Absent on orders placed
  /// with a typed address only.
  final double? shippingLatitude;
  final double? shippingLongitude;

  bool get hasPin => shippingLatitude != null && shippingLongitude != null;
  final String currency;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final String? orderNumber;

  /// `PartialReturned` / `Returned` read as partially refunded / refunded.
  final String? paymentStatus;
  final String? paymentMethod;
  final String? paymentProvider;
  final OrderCustomer? customer;

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final base = OrderSummary.fromJson(j);

    return OrderDetail(
      id: base.id,
      date: base.date,
      status: base.status,
      items: base.items,
      total: base.total,
      subtotal: base.subtotal,
      tax: base.tax,
      shippingCost: base.shippingCost,
      discount: base.discount,
      channel: base.channel,
      customerName: base.customerName,
      coverImage: base.coverImage,
      orderItems: ((j['orderItems'] ?? const []) as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingAddress: '${j['shippingAddress'] ?? ''}',
      currency: '${j['currency'] ?? 'GEL'}',
      shippingLatitude: (j['shippingLatitude'] as num?)?.toDouble(),
      shippingLongitude: (j['shippingLongitude'] as num?)?.toDouble(),
      trackingNumber: j['trackingNumber'] as String?,
      estimatedDelivery: DateTime.tryParse('${j['estimatedDelivery']}'),
      orderNumber: j['orderNumber'] as String?,
      paymentStatus: j['paymentStatus'] as String?,
      paymentMethod: j['paymentMethod'] as String?,
      paymentProvider: j['paymentProvider'] as String?,
      customer: j['user'] == null
          ? null
          : OrderCustomer.fromJson(j['user'] as Map),
    );
  }
}

class Paged<T> {
  Paged({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.data,
  });

  final int page;
  final int pageSize;
  final int total;
  final List<T> data;

  bool get hasMore => page * pageSize < total;

  factory Paged.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) item,
  ) =>
      Paged(
        page: (j['page'] ?? 1) as int,
        pageSize: (j['pageSize'] ?? 20) as int,
        total: (j['total'] ?? 0) as int,
        data: ((j['data'] ?? const []) as List)
            .map((e) => item(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Real-time order event off `GET /orders/stream` (SSE).
class OrderEvent {
  OrderEvent({
    required this.orderId,
    required this.orderNumber,
    required this.eventType,
    required this.currentStatus,
    required this.total,
    this.customerName,
  });

  final String orderId;
  final String orderNumber;

  /// `Created` | `StatusChanged` | `Cancelled` | `Paid` | `PaymentCallback`
  final String eventType;
  final OrderStatus currentStatus;
  final num total;
  final String? customerName;

  factory OrderEvent.fromJson(Map<String, dynamic> j) => OrderEvent(
        orderId: '${j['orderId']}',
        orderNumber: '${j['orderNumber'] ?? ''}',
        eventType: '${j['eventType'] ?? ''}',
        currentStatus: OrderStatus.fromWire(j['currentStatus']),
        total: (j['total'] ?? 0) as num,
        customerName: j['customerName'] as String?,
      );
}
