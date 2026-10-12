import 'package:flutter_test/flutter_test.dart';

import 'package:komero_mobile/src/widgets/common.dart';

void main() {
  group('absoluteImageUrl', () {
    // The catalog hands out http:// URLs on img.komero.ge. Android blocks
    // cleartext, so every product renders a placeholder unless we upgrade the
    // scheme. This is the regression that test exists for.
    test('upgrades http to https', () {
      expect(
        absoluteImageUrl('http://img.komero.ge/images//products/a/b.webp'),
        'https://img.komero.ge/images//products/a/b.webp',
      );
    });

    test('leaves https alone', () {
      expect(
        absoluteImageUrl('https://img.komero.ge/x.webp'),
        'https://img.komero.ge/x.webp',
      );
    });

    test('resolves a storage-relative path against the API base', () {
      final url = absoluteImageUrl('/assets/products/x.png');

      expect(url, startsWith('https://'));
      expect(url, endsWith('/assets/products/x.png'));
      expect(url, isNot(contains('//assets')));
    });

    test('is null for nothing to show', () {
      expect(absoluteImageUrl(null), isNull);
      expect(absoluteImageUrl(''), isNull);
      expect(absoluteImageUrl('   '), isNull);
    });
  });
}
