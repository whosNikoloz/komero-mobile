import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:komero_mobile/l10n/app_localizations.dart';
import 'package:komero_mobile/src/core/prefs.dart';
import 'package:komero_mobile/src/core/theme/app_theme.dart';
import 'package:komero_mobile/src/data/branding.dart';
import 'package:komero_mobile/src/features/orders/order_detail_screen.dart';
import 'package:komero_mobile/src/features/dashboard/dashboard_screen.dart'
    show meProvider;
import 'package:komero_mobile/src/features/auth/login_screen.dart';
import 'package:komero_mobile/src/features/inventory/inventory_screen.dart';
import 'package:komero_mobile/src/features/products/products_screen.dart';
import 'package:komero_mobile/src/features/settings/settings_screen.dart';
import 'package:komero_mobile/src/models/inventory.dart';
import 'package:komero_mobile/src/models/me.dart';
import 'package:komero_mobile/src/models/order.dart';
import 'package:komero_mobile/src/models/product.dart';

/// Pumps real screens with canned data. Catches the layout faults that only
/// appear once a screen actually renders — the kind `flutter analyze` cannot
/// see and that otherwise surface as a wall of RenderBox assertions on device.
/// The app chrome a screen needs to render: theme, Georgian locale, l10n.
/// Callers wrap it in their own ProviderScope so the override list keeps its
/// inferred type (`Override` is not exported from flutter_riverpod).
Widget _app(Widget child) {
  return MaterialApp(
      theme: komeroLightTheme,
      locale: const Locale('ka'),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
  );
}

OrderDetail _order({double? lat, double? lng}) => OrderDetail(
      id: '019fccc4-4233-7766-9c7f-deb282b3beba',
      date: DateTime(2026, 10, 1, 14, 30),
      status: OrderStatus.paid,
      items: 2,
      total: 255,
      subtotal: 245,
      tax: 0,
      shippingCost: 10,
      discount: 0,
      channel: OrderChannel.webShop,
      customerName: 'ნიკოლოზ ქობაიძე',
      orderNumber: '1042',
      currency: 'GEL',
      shippingAddress: 'თბილისი, ჭავჭავაძის გამზირი 37',
      shippingLatitude: lat,
      shippingLongitude: lng,
      orderItems: [
        OrderItem(id: '1', name: 'COURAGE GRAPHIC T-SHIRT', price: 145, quantity: 1, sku: 'PAR-PRA-001'),
        OrderItem(id: '2', name: 'FADED SKINNY JEANS', price: 100, quantity: 1, sku: 'FOR-GUC-002'),
      ],
      customer: OrderCustomer(
        firstName: 'ნიკოლოზ',
        lastName: 'ქობაიძე',
        email: 'demo@komero.ge',
        phoneNumber: '+995555123456',
      ),
    );

final _me = Me(
  userId: 'u1',
  email: 'demo@komero.ge',
  username: 'demo',
  globalRole: 'Client',
  isPlatformAdmin: false,
  tenant: TenantMembership(tenantId: 't1', role: 'Owner', permissions: const []),
);

void main() {
  // A phone, not the 800x600 test default — overflows show up at real widths.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('order detail renders with a map pin', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          storeBrandingProvider.overrideWith((ref) async => null),
          orderDetailProvider('x').overrideWith(
            (ref) async => _order(lat: 41.7151, lng: 44.7717),
          ),
        ],
        child: _app(const OrderDetailScreen(orderId: 'x')),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('1042'), findsWidgets);
  });

  testWidgets('order detail renders without a map pin', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          storeBrandingProvider.overrideWith((ref) async => null),
          orderDetailProvider('y').overrideWith((ref) async => _order()),
        ],
        child: _app(const OrderDetailScreen(orderId: 'y')),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('products list renders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          productListProvider.overrideWith((ref) async => [
                Product(
                  id: 'p1',
                  name: 'COURAGE GRAPHIC T-SHIRT',
                  price: 145,
                  discountPrice: 99,
                  status: StockStatus.inStock,
                  condition: ProductCondition.isNew,
                  sku: 'PAR-PRA-001',
                  stockQuantity: 94,
                ),
                Product(
                  id: 'p2',
                  name: 'ძალიან გრძელი ქართული პროდუქტის სახელი რომელიც ორ ხაზზე გადადის',
                  price: 210,
                  status: StockStatus.outOfStock,
                  condition: ProductCondition.isNew,
                ),
              ]),
        ],
        child: _app(const ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('products list chrome renders with no rows', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          productListProvider.overrideWith((ref) async => <Product>[]),
        ],
        child: _app(const ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory list renders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          locationsProvider.overrideWith((ref) async => <StockLocation>[]),
          stockListProvider.overrideWith((ref) async => [
                ProductStock(
                  id: 's1',
                  productId: 'p1',
                  productName: 'COURAGE GRAPHIC T-SHIRT',
                  quantity: 94,
                  reservedQuantity: 2,
                  availableQuantity: 92,
                ),
                ProductStock(
                  id: 's2',
                  productId: 'p2',
                  productName: 'ამოწურული პროდუქტი',
                  quantity: 0,
                  reservedQuantity: 0,
                  availableQuantity: 0,
                ),
              ]),
        ],
        child: _app(const InventoryScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('settings renders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _me),
          storeBrandingProvider.overrideWith(
            (ref) async => const StoreBranding(name: 'Shoper'),
          ),
        ],
        child: _app(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('login renders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: _app(const LoginScreen())),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
