import 'package:flutter_test/flutter_test.dart';
import 'package:komero_mobile/src/models/order.dart';

void main() {
  test('order status parses the integer and the enum name', () {
    expect(OrderStatus.fromWire(4), OrderStatus.delivered);
    expect(OrderStatus.fromWire('4'), OrderStatus.delivered);
    // What the live stream sends, and what made every order read as pending.
    expect(OrderStatus.fromWire('Delivered'), OrderStatus.delivered);
    expect(OrderStatus.fromWire('shipped'), OrderStatus.shipped);
    expect(OrderStatus.fromWire('nonsense'), OrderStatus.pending);
    expect(OrderStatus.fromWire(null), OrderStatus.pending);
  });

  test('order channel parses the integer and the enum name', () {
    expect(OrderChannel.fromWire(3), OrderChannel.pos);
    expect(OrderChannel.fromWire('Pos'), OrderChannel.pos);
    expect(OrderChannel.fromWire('WebShop'), OrderChannel.webShop);
    expect(OrderChannel.fromWire('nonsense'), isNull);
    expect(OrderChannel.fromWire(null), isNull);
  });

  test('a summary keeps the status the payload named', () {
    final o = OrderSummary.fromJson({
      'id': 'a',
      'date': '2026-01-02T03:04:05Z',
      'status': 'Delivered',
      'items': 2,
      'total': 10,
      'channel': 'Pos',
    });

    expect(o.status, OrderStatus.delivered);
    expect(o.channel, OrderChannel.pos);
    expect(o.isPos, isTrue);
  });
  test('a detail parses its tracking history', () {
    final o = OrderDetail.fromJson({
      'id': 'a',
      'date': '2026-01-02T03:04:05Z',
      'status': 3,
      'items': 1,
      'total': 10,
      'trackingSteps': [
        {
          'status': 'Paid',
          'date': '2026-01-02T03:04:05Z',
          'completed': true,
          'description': '  ',
        },
        {'status': 3, 'date': '2026-01-03T00:00:00Z', 'completed': false,
         'description': 'handed to courier'},
      ],
    });

    expect(o.trackingSteps.map((s) => s.status),
        [OrderStatus.paid, OrderStatus.shipped]);
    expect(o.trackingSteps.first.description, isNull);
    expect(o.trackingSteps.last.description, 'handed to courier');
    expect(o.trackingSteps.last.completed, isFalse);
  });
}
