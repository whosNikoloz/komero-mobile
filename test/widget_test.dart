import 'package:flutter_test/flutter_test.dart';

import 'package:komero_mobile/src/core/session.dart';

void main() {
  // The one piece of non-trivial logic outside the widget tree: the store
  // address the operator types has to become the bare host the backend matches
  // on, or every request lands on the wrong tenant (or none).
  group('normalizeDomain', () {
    test('strips scheme, trailing slash and case', () {
      expect(SessionController.normalizeDomain('https://Wonder.GE/'), 'wonder.ge');
      expect(SessionController.normalizeDomain('http://shop.example.com'),
          'shop.example.com');
    });

    test('keeps only the host when a path is pasted', () {
      expect(SessionController.normalizeDomain('wonder.ge/admin/orders'), 'wonder.ge');
    });

    test('tolerates padding and bare hosts', () {
      expect(SessionController.normalizeDomain('  wonder.ge  '), 'wonder.ge');
      expect(SessionController.normalizeDomain('localhost:3000'), 'localhost:3000');
    });
  });
}
