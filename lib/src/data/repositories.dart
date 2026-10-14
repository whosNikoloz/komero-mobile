import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_client.dart';
import '../models/inventory.dart';
import '../models/me.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/stats.dart';

// ─────────────────────────────────────────────────────────────── auth

class AuthRepository {
  AuthRepository(this._api);

  final KomeroApi _api;

  /// `POST /User/login` — the unified operator + customer login. The store is
  /// resolved from `X-Client-Domain`, so the domain must be set on the session
  /// before this call.
  Future<({String token, String email, String role})> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      'User/login',
      body: {'email': email, 'password': password},
    );

    final token = res['token'];

    if (token is! String || token.isEmpty) {
      throw ApiException(401, 'Login did not return a token');
    }

    return (
      token: token,
      email: '${res['email'] ?? email}',
      role: '${res['role'] ?? ''}',
    );
  }

  Future<Me> me() async =>
      Me.fromJson(await _api.get<Map<String, dynamic>>('User/me'));

  Future<void> forgotPassword(String email) =>
      _api.post<void>('User/forgot-password', body: {'email': email});
}

final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(apiProvider)));

// ─────────────────────────────────────────────────────────── analytics

class StatsRepository {
  StatsRepository(this._api);

  final KomeroApi _api;

  Future<SummaryStats> summary() async =>
      SummaryStats.fromJson(await _api.get<Map<String, dynamic>>('api/statistics/summary'));

  Future<DashboardStats> dashboard({DateTime? from, DateTime? to}) async =>
      DashboardStats.fromJson(
        await _api.get<Map<String, dynamic>>(
          'api/statistics/dashboard',
          query: {
            if (from != null) 'startDate': _d(from),
            if (to != null) 'endDate': _d(to),
          },
        ),
      );

  /// Live traffic + conversion funnel.
  Future<BehaviorOverview> behavior({DateTime? from, DateTime? to}) async =>
      BehaviorOverview.fromJson(
        await _api.get<Map<String, dynamic>>(
          'api/admin/behavior/overview',
          query: {
            if (from != null) 'from': _d(from),
            if (to != null) 'to': _d(to),
          },
        ),
      );

  Future<List<SourceRow>> sources({DateTime? from, DateTime? to}) async {
    final res = await _api.get<List<dynamic>>(
      'api/admin/behavior/sources',
      query: {
        if (from != null) 'from': _d(from),
        if (to != null) 'to': _d(to),
      },
    );

    return res
        .map((e) => SourceRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static String _d(DateTime v) => v.toIso8601String().split('T').first;
}

final statsRepositoryProvider =
    Provider((ref) => StatsRepository(ref.watch(apiProvider)));

// ────────────────────────────────────────────────────────────── orders

class OrderRepository {
  OrderRepository(this._api);

  final KomeroApi _api;

  Future<Paged<OrderSummary>> list({
    int page = 1,
    int pageSize = 20,
    OrderChannel? channel,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      'Order/get-all-orders',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (channel != null) 'channel': channel.wire,
      },
    );

    return Paged.fromJson(_camel(res), OrderSummary.fromJson);
  }

  Future<OrderDetail> byId(String id) async => OrderDetail.fromJson(
        _camel(await _api.get<Map<String, dynamic>>('Order/get-order-by-$id')),
      );

  /// `PUT Order/update-order-status`. The body is PascalCase — the backend does
  /// not camel-case this one. Fulfilment is this call with
  /// `status: shipped` + a tracking number.
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
    String? description,
    String? trackingNumber,
    DateTime? estimatedDelivery,
  }) =>
      _api.put<void>(
        'Order/update-order-status',
        body: {
          'OrderId': orderId,
          'Status': status.wire,
          'Description': description,
          'TrackingNumber': trackingNumber,
          'EstimatedDelivery': estimatedDelivery?.toIso8601String(),
        },
      );

  Future<void> cancel({
    required String orderId,
    required String userId,
    required String reason,
  }) =>
      _api.post<void>(
        'Order/cancel-order-$orderId',
        query: {'userId': userId, 'reason': reason},
      );

  /// The backend answers some order routes in PascalCase. Only the top level
  /// and the known nested lists need normalising for our parsers.
  static Map<String, dynamic> _camel(Map<String, dynamic> src) {
    Object? walk(Object? v) {
      if (v is Map) {
        return {
          for (final e in v.entries)
            _lowerFirst('${e.key}'): walk(e.value),
        };
      }
      if (v is List) return v.map(walk).toList();

      return v;
    }

    return walk(src) as Map<String, dynamic>;
  }

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

final orderRepositoryProvider =
    Provider((ref) => OrderRepository(ref.watch(apiProvider)));

// ─────────────────────────────────────────────────────────── inventory

class StockRepository {
  StockRepository(this._api);

  final KomeroApi _api;

  Future<List<ProductStock>> all({String? locationId}) =>
      _stocks('Stock/get-all-stocks', locationId);

  Future<List<ProductStock>> lowStock({
    int threshold = 10,
    String? locationId,
  }) =>
      _stocks('Stock/low-stock/$threshold', locationId);

  Future<List<ProductStock>> outOfStock({String? locationId}) =>
      _stocks('Stock/out-of-stock', locationId);

  Future<ProductStock> forProduct(String productId, {String? locationId}) async =>
      ProductStock.fromJson(
        await _api.get<Map<String, dynamic>>(
          'Stock/get-stock/$productId',
          query: _loc(locationId),
        ),
      );

  /// Sets the exact on-hand quantity. Body is a bare number, not an object.
  Future<void> setQuantity(String productId, int quantity, {String? locationId}) =>
      _api.put<void>(
        'Stock/update-stock/$productId',
        body: quantity,
        query: _loc(locationId),
      );

  Future<void> addQuantity(String productId, int delta, {String? locationId}) =>
      _api.post<void>(
        'Stock/add-stock/$productId',
        body: delta,
        query: _loc(locationId),
      );

  Future<void> removeQuantity(String productId, int delta, {String? locationId}) =>
      _api.post<void>(
        'Stock/remove-stock/$productId',
        body: delta,
        query: _loc(locationId),
      );

  Future<List<ProductStock>> _stocks(String path, String? locationId) async {
    final res = await _api.get<List<dynamic>>(path, query: _loc(locationId));

    return res
        .map((e) => ProductStock.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Map<String, dynamic>? _loc(String? id) =>
      id == null ? null : {'locationId': id};
}

final stockRepositoryProvider =
    Provider((ref) => StockRepository(ref.watch(apiProvider)));

/// Multi-location: locations, per-product breakdown and transfers.
/// Every route needs the `products.manage` permission.
class LocationRepository {
  LocationRepository(this._api);

  final KomeroApi _api;

  Future<List<StockLocation>> list() async {
    final res = await _api.get<List<dynamic>>('api/admin/stock-locations');

    return res
        .map((e) => StockLocation.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<ProductLocationStock>> forProduct(String productId) async {
    final res =
        await _api.get<List<dynamic>>('api/admin/stock-locations/products/$productId');

    return res
        .map((e) =>
            ProductLocationStock.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> transfer(StockTransferRequest body) =>
      _api.post<void>('api/admin/stock-transfers', body: body.toJson());
}

final locationRepositoryProvider =
    Provider((ref) => LocationRepository(ref.watch(apiProvider)));

// ──────────────────────────────────────────────────────────── barcodes

class BarcodeRepository {
  BarcodeRepository(this._api);

  final KomeroApi _api;

  /// Resolves a scanned code. Falls back to an SKU match — `matchedBy` says
  /// which, and `packQuantity` is how many units one scan represents.
  Future<BarcodeLookup> lookup(String code) async => BarcodeLookup.fromJson(
        await _api.get<Map<String, dynamic>>(
          'Product/barcode/${Uri.encodeComponent(code)}',
        ),
      );

  /// One-shot scan-and-adjust: `delta` is signed, so -1 counts an item out.
  Future<BarcodeLookup> adjustStock(String code, int delta) async =>
      BarcodeLookup.fromJson(
        await _api.post<Map<String, dynamic>>(
          'Product/barcode/${Uri.encodeComponent(code)}/stock',
          body: {'delta': delta},
        ),
      );

  Future<void> addBarcode(
    String productId, {
    required String value,
    BarcodeSymbology? symbology,
    int packQuantity = 1,
    bool isPrimary = false,
  }) =>
      _api.post<void>(
        'Product/$productId/barcodes',
        body: {
          'value': value,
          if (symbology != null) 'symbology': symbology.wire,
          'packQuantity': packQuantity,
          'isPrimary': isPrimary,
        },
      );
}

final barcodeRepositoryProvider =
    Provider((ref) => BarcodeRepository(ref.watch(apiProvider)));

// ──────────────────────────────────────────────────────────── catalog

class ProductRepository {
  ProductRepository(this._api);

  final KomeroApi _api;

  Future<List<Product>> page({
    int page = 1,
    int pageSize = 20,
    ProductSort sort = ProductSort.nameAsc,
  }) async {
    final res = await _api.get<dynamic>(
      'Product/get-all-products',
      query: {
        'page': page,
        'pageSize': pageSize,
        'sortColumn': sort.column,
        'sortOrder': sort.order,
      },
    );

    // The route answers a bare array on some tenants and a paged envelope on
    // others; accept both rather than guessing.
    return _unwrap(res);
  }

  Future<Product> byId(String id) async => Product.fromJson(
        await _api.get<Map<String, dynamic>>('Product/get-products-by-$id'),
      );

  Future<Product> bySku(String sku) async => Product.fromJson(
        await _api.get<Map<String, dynamic>>('Product/sku/$sku'),
      );

  Future<List<Product>> search(
    String term, {
    ProductSort sort = ProductSort.nameAsc,
    int pageSize = 50,
  }) async {
    final res = await _api.get<dynamic>(
      'Product/get-product-by-searching',
      query: {
        'searchTerm': term,
        'sortColumn': sort.column,
        'sortOrder': sort.order,
        'page': 1,
        'pageSize': pageSize,
      },
    );

    return _unwrap(res);
  }

  /// `POST Product/get-products-by-filtering` — category, brand, stock status
  /// and the promo flags. The filter travels in the body; paging and sorting
  /// in the query string.
  ///
  /// The endpoint takes no search term, so a text query combined with a filter
  /// is narrowed on the client (see [ProductRepository.browse]).
  Future<List<Product>> filter(
    ProductFilter filter, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _api.post<dynamic>(
      'Product/get-products-by-filtering',
      body: filter.toJson(),
      query: {
        'page': page,
        'pageSize': pageSize,
        'sortColumn': filter.sort.column,
        'sortOrder': filter.sort.order,
      },
    );

    return _unwrap(res);
  }

  /// The one call the product list makes, picking the endpoint that can
  /// actually answer the question being asked.
  Future<List<Product>> browse({
    String query = '',
    ProductFilter filter = const ProductFilter(),
  }) async {
    final term = query.trim();

    if (filter.isEmpty) {
      return term.length >= 2
          ? search(term, sort: filter.sort)
          : page(pageSize: 50, sort: filter.sort);
    }

    final filtered = await this.filter(filter);

    if (term.length < 2) return filtered;

    // No server-side way to combine the two, so the text narrows the filtered
    // page in memory. Good enough for a phone's page size; if a tenant's
    // catalog outgrows it, the endpoint needs a searchTerm.
    final needle = term.toLowerCase();

    return filtered
        .where((p) =>
            p.name.toLowerCase().contains(needle) ||
            (p.sku?.toLowerCase().contains(needle) ?? false))
        .toList();
  }

  static List<Product> _unwrap(dynamic res) {
    final list = res is List ? res : (res['data'] ?? res['items'] ?? const []);

    return (list as List)
        .map((e) => Product.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<String> create(Map<String, dynamic> body) async =>
      '${await _api.post<dynamic>('Product/add-product', body: body)}';

  Future<void> update(Map<String, dynamic> body) =>
      _api.put<void>('Product/update-product', body: body);

  /// `POST Product/images` — multipart with `id`, repeated `files`, and an
  /// optional `coverIndex`. This is what the web admin proxies to.
  Future<List<ProductImage>> uploadImages({
    required String productId,
    required List<MultipartFile> files,
    int? coverIndex,
  }) async {
    final form = FormData();

    form.fields.add(MapEntry('id', productId));

    if (coverIndex != null && coverIndex >= 0) {
      form.fields.add(MapEntry('coverIndex', '$coverIndex'));
    }

    for (final f in files) {
      form.files.add(MapEntry('files', f));
    }

    final res = await _api.post<List<dynamic>>('Product/images', body: form);

    return res
        .map((e) => ProductImage.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// `position` is the image's index, not its id.
  Future<void> setCoverImage(String productId, int position) =>
      _api.put<void>('Product/$productId/set-cover-image/$position');

  Future<List<NamedRef>> categories() async {
    final res = await _api.get<List<dynamic>>('Category/get-all-categories');

    return res.map((e) => NamedRef.fromJson(e as Map)).toList();
  }

  Future<List<NamedRef>> brands() async {
    final res = await _api.get<List<dynamic>>('Brand/get-all-brands');

    return res.map((e) => NamedRef.fromJson(e as Map)).toList();
  }
}

/// The catalog around the products: categories, brands and variant groups.
///
/// The update endpoints replace the whole record rather than patching it, so
/// every edit reads the current one first and sends it back changed — exactly
/// what the web admin does. Skipping that read would blank every field the
/// phone does not show.
class CatalogRepository {
  CatalogRepository(this._api);

  final KomeroApi _api;

  Future<Map<String, dynamic>> category(String id) =>
      _api.get<Map<String, dynamic>>('Category/get-category-by-$id');

  Future<void> saveCategory({
    String? id,
    required String name,
    String description = '',
    String? parentId,
  }) async {
    if (id == null) {
      await _api.post<dynamic>('Category/add-category', body: {
        'name': name,
        'description': description,
        'parentId': ?parentId,
        'images': <dynamic>[],
      });

      return;
    }

    final current = await category(id);

    await _api.put<void>('Category/update-category', body: {
      ...current,
      'id': id,
      'name': name,
      'description': description,
    });
  }

  /// Deletion is a PUT on this API, not a DELETE.
  Future<void> deleteCategory(String id) =>
      _api.put<void>('Category/delete-category-by-$id');

  Future<Map<String, dynamic>> brand(String id) =>
      _api.get<Map<String, dynamic>>('Brand/get-brand-by-$id');

  Future<void> saveBrand({
    String? id,
    required String name,
    String description = '',
    String origin = '',
  }) async {
    if (id == null) {
      await _api.post<dynamic>('Brand/add-brand', body: {
        'name': name,
        'origin': origin,
        'description': description,
        'images': <dynamic>[],
      });

      return;
    }

    final current = await brand(id);

    await _api.put<void>('Brand/update-brand', body: {
      ...current,
      'id': id,
      'name': name,
      'description': description,
      'origin': origin,
    });
  }

  Future<void> deleteBrand(String id) =>
      _api.put<void>('Brand/delete-brand-by-$id');

  Future<List<NamedRef>> productGroups() async {
    final res =
        await _api.get<List<dynamic>>('ProductGroup/get-all-product-groups');

    return res.map((e) => NamedRef.fromJson(e as Map)).toList();
  }

  Future<void> createProductGroup(String name) =>
      _api.post<dynamic>('ProductGroup/create-product-group', body: {'name': name});
}

// ─────────────────────────────────────────────────────────────── media

/// Uploads for anything that is not a product gallery photo — the pictures an
/// operator drops into a description.
///
/// `POST Image/upload`, multipart `files` plus an optional `folder`, same as
/// the web admin's `uploadImage` (`commerce/app/api/services/uploadService.ts`).
/// The response has been seen as a bare string, a list, and an object with
/// `url`, `path` or `data`, so all of those are unwrapped here rather than at
/// the call site.
class MediaRepository {
  MediaRepository(this._api);

  final KomeroApi _api;

  Future<String> upload(MultipartFile file, {String? folder}) async {
    final form = FormData();

    form.files.add(MapEntry('files', file));

    if (folder != null) form.fields.add(MapEntry('folder', folder));

    final res = await _api.post<dynamic>('Image/upload', body: form);
    final url = _url(res);

    if (url == null || url.isEmpty) {
      throw const FormatException('Upload returned no URL');
    }

    return url;
  }

  static String? _url(Object? res) {
    if (res is String) return res;

    if (res is List) return res.isEmpty ? null : _url(res.first);

    if (res is Map) {
      return _url(res['url'] ?? res['path'] ?? res['data']);
    }

    return null;
  }
}

final mediaRepositoryProvider =
    Provider((ref) => MediaRepository(ref.watch(apiProvider)));

final catalogRepositoryProvider =
    Provider((ref) => CatalogRepository(ref.watch(apiProvider)));

final productRepositoryProvider =
    Provider((ref) => ProductRepository(ref.watch(apiProvider)));
