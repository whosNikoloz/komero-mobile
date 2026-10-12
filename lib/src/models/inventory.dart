/// `GET Stock/get-all-stocks` and friends.
class ProductStock {
  ProductStock({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    this.lastUpdated,
    this.locationId,
    this.locationName,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final DateTime? lastUpdated;

  /// Absent on pre-locations responses.
  final String? locationId;
  final String? locationName;

  factory ProductStock.fromJson(Map<String, dynamic> j) => ProductStock(
        id: '${j['id']}',
        productId: '${j['productId']}',
        productName: '${j['productName'] ?? ''}',
        quantity: _int(j['quantity']),
        reservedQuantity: _int(j['reservedQuantity']),
        availableQuantity: _int(j['availableQuantity']),
        lastUpdated: DateTime.tryParse('${j['lastUpdated']}'),
        locationId: j['locationId'] as String?,
        locationName: j['locationName'] as String?,
      );
}

enum StockLocationKind {
  warehouse(1),
  store(2);

  const StockLocationKind(this.wire);

  final int wire;

  static StockLocationKind fromWire(Object? v) {
    final i = v is int ? v : int.tryParse('$v');

    return i == 2 ? StockLocationKind.store : StockLocationKind.warehouse;
  }
}

/// Seeded in every tenant DB; holds all stock that predates locations.
const kMainWarehouseId = '5d0c2a1e-0000-4000-8000-000000000001';

class StockLocation {
  StockLocation({
    required this.id,
    required this.name,
    required this.kind,
    required this.isWebSource,
    required this.isActive,
    required this.productCount,
    required this.totalQuantity,
    required this.totalReserved,
  });

  final String id;
  final String name;
  final StockLocationKind kind;

  /// The one location the web shop shows, reserves and sells from.
  final bool isWebSource;
  final bool isActive;
  final int productCount;
  final int totalQuantity;
  final int totalReserved;

  factory StockLocation.fromJson(Map<String, dynamic> j) => StockLocation(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        kind: StockLocationKind.fromWire(j['kind']),
        isWebSource: j['isWebSource'] == true,
        isActive: j['isActive'] == true,
        productCount: _int(j['productCount']),
        totalQuantity: _int(j['totalQuantity']),
        totalReserved: _int(j['totalReserved']),
      );
}

class ProductLocationStock {
  ProductLocationStock({
    required this.locationId,
    required this.locationName,
    required this.kind,
    required this.isWebSource,
    required this.hasRow,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
  });

  final String locationId;
  final String locationName;
  final StockLocationKind kind;
  final bool isWebSource;

  /// false: this location never held the product (every number is 0).
  final bool hasRow;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;

  factory ProductLocationStock.fromJson(Map<String, dynamic> j) =>
      ProductLocationStock(
        locationId: '${j['locationId']}',
        locationName: '${j['locationName'] ?? ''}',
        kind: StockLocationKind.fromWire(j['kind']),
        isWebSource: j['isWebSource'] == true,
        hasRow: j['hasRow'] == true,
        quantity: _int(j['quantity']),
        reservedQuantity: _int(j['reservedQuantity']),
        availableQuantity: _int(j['availableQuantity']),
      );
}

/// `POST api/admin/stock-transfers` — 1-500 lines, each quantity > 0.
class StockTransferRequest {
  StockTransferRequest({
    required this.fromLocationId,
    required this.toLocationId,
    required this.lines,
    this.note,
  });

  final String fromLocationId;
  final String toLocationId;
  final List<({String productId, int quantity})> lines;
  final String? note;

  Map<String, dynamic> toJson() => {
        'fromLocationId': fromLocationId,
        'toLocationId': toLocationId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'lines': lines
            .map((l) => {'productId': l.productId, 'quantity': l.quantity})
            .toList(),
      };
}

enum BarcodeSymbology {
  ean13(1),
  ean8(2),
  upcA(3),
  itf14(4),
  code128(5),
  code39(6),
  qrCode(7);

  const BarcodeSymbology(this.wire);

  final int wire;
}

/// `GET Product/barcode/{code}` — what the camera scan resolves to.
class BarcodeLookup {
  BarcodeLookup({
    required this.productId,
    required this.name,
    required this.sku,
    required this.price,
    required this.stockAmount,
    required this.packQuantity,
    required this.matchedBy,
    this.discountPrice,
    this.coverImage,
    this.isActive,
    this.variant = const [],
  });

  final String productId;
  final String name;
  final String sku;
  final num price;
  final int stockAmount;

  /// A scanned case barcode can stand for N units.
  final int packQuantity;

  /// `barcode` or `sku`.
  final String matchedBy;
  final num? discountPrice;
  final String? coverImage;
  final bool? isActive;
  final List<String> variant;

  factory BarcodeLookup.fromJson(Map<String, dynamic> j) => BarcodeLookup(
        productId: '${j['productId']}',
        name: '${j['name'] ?? ''}',
        sku: '${j['sku'] ?? ''}',
        price: (j['price'] ?? 0) as num,
        stockAmount: _int(j['stockAmount']),
        packQuantity: _int(j['packQuantity'], fallback: 1),
        matchedBy: '${j['matchedBy'] ?? 'barcode'}',
        discountPrice: j['discountPrice'] as num?,
        coverImage: j['coverImage'] as String?,
        isActive: j['isActive'] as bool?,
        variant:
            (j['variant'] as List?)?.map((e) => '$e').toList() ?? const [],
      );
}

int _int(Object? v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.round();

  return int.tryParse('$v') ?? fallback;
}
