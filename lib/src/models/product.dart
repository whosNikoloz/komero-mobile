enum StockStatus {
  inStock(0),
  outOfStock(1);

  const StockStatus(this.wire);

  final int wire;

  static StockStatus fromWire(Object? v) {
    final i = v is int ? v : int.tryParse('$v');

    return i == 1 ? StockStatus.outOfStock : StockStatus.inStock;
  }
}

enum ProductCondition {
  isNew(0),
  used(1),
  likeNew(2);

  const ProductCondition(this.wire);

  final int wire;

  static ProductCondition fromWire(Object? v) {
    final i = v is int ? v : int.tryParse('$v');

    return ProductCondition.values.firstWhere(
      (c) => c.wire == i,
      orElse: () => ProductCondition.isNew,
    );
  }
}

/// Product images are `{ imagePath, isCover, ... }` objects — never bare
/// strings, whatever the web `ProductResponseModel` type suggests.
class ProductImage {
  ProductImage({
    required this.id,
    required this.productId,
    required this.imagePath,
    required this.isCover,
    required this.displayOrder,
  });

  final String id;
  final String productId;
  final String imagePath;
  final bool isCover;
  final int displayOrder;

  factory ProductImage.fromJson(Map<String, dynamic> j) => ProductImage(
        id: '${j['id']}',
        productId: '${j['productId']}',
        imagePath: '${j['imagePath'] ?? ''}',
        isCover: j['isCover'] == true,
        displayOrder: (j['displayOrder'] ?? 0) is int
            ? j['displayOrder'] as int
            : int.tryParse('${j['displayOrder']}') ?? 0,
      );
}

class NamedRef {
  NamedRef({required this.id, required this.name, this.parentId});

  final String id;
  final String name;

  /// Only categories carry one; it is what the picker builds its tree from.
  final String? parentId;

  factory NamedRef.fromJson(Map? j) => NamedRef(
        id: '${j?['id'] ?? ''}',
        name: '${j?['name'] ?? ''}',
        parentId: (j?['parentId'] as String?)?.isEmpty == true
            ? null
            : j?['parentId'] as String?,
      );
}

/// Depth-first order with each item's depth, so children read as indented
/// rows under their parent. Items whose parent is missing count as roots,
/// which also keeps a broken link from hiding them.
List<({T item, int depth})> orderAsTree<T>(
  List<T> items, {
  required String? Function(T) idOf,
  required String? Function(T) parentOf,
}) {
  final ids = {for (final item in items) idOf(item)};
  final byParent = <String?, List<T>>{};

  for (final item in items) {
    final parent = parentOf(item);
    byParent.putIfAbsent(ids.contains(parent) ? parent : null, () => []).add(item);
  }

  final out = <({T item, int depth})>[];

  void walk(String? parent, int depth) {
    for (final item in byParent[parent] ?? const []) {
      out.add((item: item, depth: depth));
      if (depth < 6) walk(idOf(item), depth + 1);
    }
  }

  walk(null, 0);

  return out;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.condition,
    this.sku,
    this.slug,
    this.discountPrice,
    this.description,
    this.shortDescription,
    this.images = const [],
    this.brand,
    this.category,
    this.isActive = true,
    this.isNewArrival = false,
    this.isLiquidated = false,
    this.isComingSoon = false,
    this.stockQuantity,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.gtin,
    this.mpn,
    this.isIndexable = true,
    this.canonicalOverride,
  });

  final String id;
  final String name;
  final num price;
  final StockStatus status;
  final ProductCondition condition;
  final String? sku;
  final String? slug;
  final num? discountPrice;
  final String? description;
  final String? shortDescription;
  final List<ProductImage> images;
  final NamedRef? brand;
  final NamedRef? category;
  final bool isActive;
  final bool isNewArrival;
  final bool isLiquidated;
  final bool isComingSoon;
  final int? stockQuantity;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final String? gtin;
  final String? mpn;
  final bool isIndexable;
  final String? canonicalOverride;

  String? get coverImage {
    if (images.isEmpty) return null;

    for (final i in images) {
      if (i.isCover) return i.imagePath;
    }

    return images.first.imagePath;
  }

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        price: (j['price'] ?? 0) as num,
        status: StockStatus.fromWire(j['status']),
        condition: ProductCondition.fromWire(j['condition']),
        sku: j['sku'] as String?,
        slug: j['slug'] as String?,
        discountPrice: j['discountPrice'] as num?,
        description: j['description'] as String?,
        shortDescription: j['shortDescription'] as String?,
        images: ((j['images'] ?? const []) as List)
            .whereType<Map>()
            .map((e) => ProductImage.fromJson(e.cast<String, dynamic>()))
            .toList(),
        brand: j['brand'] == null ? null : NamedRef.fromJson(j['brand'] as Map),
        category:
            j['category'] == null ? null : NamedRef.fromJson(j['category'] as Map),
        isActive: j['isActive'] != false,
        isNewArrival: j['isNewArrival'] == true,
        isLiquidated: j['isLiquidated'] == true,
        isComingSoon: j['isComingSoon'] == true,
        stockQuantity: j['stockQuantity'] as int?,
        metaTitle: j['metaTitle'] as String?,
        metaDescription: j['metaDescription'] as String?,
        metaKeywords: j['metaKeywords'] as String?,
        gtin: j['gtin'] as String?,
        mpn: j['mpn'] as String?,
        isIndexable: j['isIndexable'] != false,
        canonicalOverride: j['canonicalOverride'] as String?,
      );

  /// The write shape: `brandId`/`categoryId` instead of nested objects, and
  /// `productFacetValues` is required by the backend even when empty.
  Map<String, dynamic> toRequestJson({
    required String brandId,
    required String categoryId,
    int? initialStock,
  }) =>
      {
        'id': id,
        'name': name,
        if (sku != null) 'sku': sku,
        if (slug != null) 'slug': slug,
        'price': price,
        if (discountPrice != null) 'discountPrice': discountPrice,
        'status': status.wire,
        'condition': condition.wire,
        if (description != null) 'description': description,
        if (shortDescription != null) 'shortDescription': shortDescription,
        'brandId': brandId,
        'categoryId': categoryId,
        'isActive': isActive,
        'isNewArrival': isNewArrival,
        'isLiquidated': isLiquidated,
        'isComingSoon': isComingSoon,
        'productFacetValues': const [],
        'initialStock': ?initialStock,
        'stockQuantity': ?stockQuantity,
        // Sent even when empty: the update endpoint replaces the record, so a
        // field left out here is a field wiped on the storefront.
        'metaTitle': metaTitle ?? '',
        'metaDescription': metaDescription ?? '',
        'metaKeywords': metaKeywords ?? '',
        'gtin': gtin ?? '',
        'mpn': mpn ?? '',
        'isIndexable': isIndexable,
        'canonicalOverride': canonicalOverride ?? '',
      };
}

/// How the product list is sorted. Maps to the `sortColumn`/`sortOrder` pair
/// the catalog endpoints take (see `mapSort` in commerce/productService.ts).
enum ProductSort {
  nameAsc('name', 'asc'),
  priceLow('price', 'asc'),
  priceHigh('price', 'desc'),
  newest('date', 'desc');

  const ProductSort(this.column, this.order);

  final String column;
  final String order;
}

/// Body of `POST Product/get-products-by-filtering` — the backend's FilterModel.
class ProductFilter {
  const ProductFilter({
    this.categoryIds = const [],
    this.brandIds = const [],
    this.stockStatus,
    this.isNewArrival,
    this.isDiscounted,
    this.isLiquidated,
    this.minPrice,
    this.maxPrice,
    this.sort = ProductSort.nameAsc,
  });

  final List<String> categoryIds;
  final List<String> brandIds;
  final StockStatus? stockStatus;
  final bool? isNewArrival;
  final bool? isDiscounted;
  final bool? isLiquidated;
  final num? minPrice;
  final num? maxPrice;
  final ProductSort sort;

  /// Sort alone is not a filter — it changes order, not membership, so it must
  /// not push the screen onto the filtering endpoint.
  bool get isEmpty =>
      categoryIds.isEmpty &&
      brandIds.isEmpty &&
      stockStatus == null &&
      isNewArrival == null &&
      isDiscounted == null &&
      isLiquidated == null &&
      minPrice == null &&
      maxPrice == null;

  /// What the "N filters" badge counts.
  int get activeCount => [
        categoryIds.isNotEmpty,
        brandIds.isNotEmpty,
        stockStatus != null,
        isNewArrival != null,
        isDiscounted != null,
        isLiquidated != null,
        minPrice != null || maxPrice != null,
      ].where((on) => on).length;

  ProductFilter copyWith({
    List<String>? categoryIds,
    List<String>? brandIds,
    StockStatus? stockStatus,
    bool? isNewArrival,
    bool? isDiscounted,
    bool? isLiquidated,
    num? minPrice,
    num? maxPrice,
    ProductSort? sort,
    bool clearStockStatus = false,
    bool clearFlags = false,
    bool clearPrice = false,
  }) =>
      ProductFilter(
        categoryIds: categoryIds ?? this.categoryIds,
        brandIds: brandIds ?? this.brandIds,
        stockStatus: clearStockStatus ? null : (stockStatus ?? this.stockStatus),
        isNewArrival: clearFlags ? null : (isNewArrival ?? this.isNewArrival),
        isDiscounted: clearFlags ? null : (isDiscounted ?? this.isDiscounted),
        isLiquidated: clearFlags ? null : (isLiquidated ?? this.isLiquidated),
        minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toJson() => {
        if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
        if (brandIds.isNotEmpty) 'brandIds': brandIds,
        if (stockStatus != null) 'stockStatus': stockStatus!.wire,
        if (isNewArrival != null) 'isNewArrival': isNewArrival,
        if (isDiscounted != null) 'isDiscounted': isDiscounted,
        if (isLiquidated != null) 'isLiquidated': isLiquidated,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
      };
}
