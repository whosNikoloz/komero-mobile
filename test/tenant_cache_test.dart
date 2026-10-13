import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:komero_mobile/src/core/net/api_client.dart';
import 'package:komero_mobile/src/data/repositories.dart';

/// Signing out of one store and into another used to show the first store's
/// products, because every cached page lived on in the container. The fix is a
/// single `ref.invalidate(apiProvider)` in main.dart when the token or domain
/// changes — this asserts the cascade that makes one call enough.
void main() {
  test('invalidating apiProvider drops cached store data', () {
    var builds = 0;

    // Stands in for the real screen providers (products, orders, stock): they
    // all reach the network through a repository, which watches apiProvider.
    final storeData = Provider<int>((ref) {
      ref.watch(productRepositoryProvider);

      return ++builds;
    });

    final container = ProviderContainer();

    addTearDown(container.dispose);

    expect(container.read(storeData), 1);
    expect(container.read(storeData), 1, reason: 'cached while the store is the same');

    container.invalidate(apiProvider);

    expect(
      container.read(storeData),
      2,
      reason: 'the next store must refetch, not reuse the previous one',
    );
  });
}
