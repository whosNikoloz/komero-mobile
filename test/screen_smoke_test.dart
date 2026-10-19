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
import 'package:komero_mobile/src/features/dashboard/behavior_screen.dart';
import 'package:komero_mobile/src/features/auth/login_screen.dart';
import 'package:komero_mobile/src/features/auth/welcome_screen.dart';
import 'package:komero_mobile/src/features/inventory/inventory_screen.dart';
import 'package:komero_mobile/src/features/products/products_screen.dart';
import 'package:komero_mobile/src/features/settings/settings_screen.dart';
import 'package:komero_mobile/src/models/inventory.dart';
import 'package:komero_mobile/src/models/me.dart';
import 'package:komero_mobile/src/models/order.dart';
import 'package:komero_mobile/src/models/product.dart';
import 'package:komero_mobile/src/models/stats.dart';

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

  // The welcome carousel is a fixed-height mock, so it is exactly the kind of
  // layout a large system font breaks — which is how it first overflowed.
  // pumpAndSettle is out: the marquee ticker never stops.
  for (final scale in [1.0, 1.6, 2.4]) {
    testWidgets('welcome renders at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: _app(const WelcomeScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('customer behaviour renders every tab', (tester) async {
    final overview = BehaviorOverview.fromJson({
      'sessions': 420,
      'productViewSessions': 260,
      'cartSessions': 80,
      'checkoutSessions': 35,
      'purchaseSessions': 18,
      'activeNow': 3,
      'searches': 64,
      'wishlists': 12,
      'contactClicks': 9,
      'contactChannels': {'phone': 6, 'whatsapp': 3},
      'days': [
        for (var d = 1; d <= 10; d++)
          {'day': '2026-10-0$d', 'sessions': 40 + d, 'purchaseSessions': d},
      ],
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          behaviorOverviewProvider.overrideWith((ref) async => overview),
          sourcesProvider.overrideWith(
            (ref) async => [
              SourceRow.fromJson({
                'source': 'facebook',
                'sessions': 200,
                'purchaseSessions': 10,
              }),
            ],
          ),
          searchTermsProvider.overrideWith(
            (ref) async => [
              SearchTerm.fromJson({
                'term': 'ჩექმები',
                'searches': 14,
                'zeroResultSearches': 5,
              }),
            ],
          ),
          productBehaviorProvider.overrideWith(
            (ref) async => [
              ProductBehavior.fromJson({
                'productId': 'p1',
                'name': 'ზამთრის ქურთუკი',
                'views': 120,
                'cartAdds': 9,
                'unitsSold': 3,
                'cartRate': 7.5,
              }),
            ],
          ),
          abandonedProvider.overrideWith(
            (ref) async => Paged.fromJson({
              'total': 1,
              'data': [
                {
                  'sessionId': 's1',
                  'lastActivityAt': '2026-10-10T12:00:00Z',
                  'stepReached': 'payment',
                  'value': 180,
                  'items': [
                    {'productId': 'p1', 'quantity': 1, 'price': 180},
                  ],
                },
              ],
            }, AbandonedSession.fromJson),
          ),
        ],
        child: _app(const BehaviorScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // Each tab lays out on its own — an overflow only shows once it is built.
    for (final tab in [1, 2]) {
      await tester.tap(find.byType(Tab).at(tab));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });

}
