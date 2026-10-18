import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komero_mobile/src/widgets/pull_to_preview.dart';

/// The two platform shapes of the pull gesture, plus the release signal. iOS
/// got this wrong twice: it reports no overscroll, and its lift-off is only
/// visible as a notification carrying no drag details.
void main() {
  testWidgets('pull gesture', (tester) async {
    // Scroll notifications demand a real BuildContext, hence the pumped widget.
    late BuildContext ctx;
    await tester.pumpWidget(
      Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    );

    ScrollMetrics metrics(double pixels) => FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 1000,
          pixels: pixels,
          viewportDimension: 600,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1,
        );

    final drag = DragUpdateDetails(globalPosition: Offset.zero);

    ScrollUpdateNotification update(double pixels, {bool dragging = true}) =>
        ScrollUpdateNotification(
          metrics: metrics(pixels),
          context: ctx,
          dragDetails: dragging ? drag : null,
        );

    OverscrollNotification over(double amount) => OverscrollNotification(
          metrics: metrics(0),
          context: ctx,
          overscroll: amount,
          dragDetails: drag,
        );

    // iOS: the offset simply goes negative, and the list already moved itself.
    var s = pullStep(update(-30), 0);
    expect(s.pull, 30);
    expect(s.bouncing, isTrue);
    expect(s.release, isFalse);

    // Android: overscroll accumulates and the content needs translating.
    s = pullStep(over(-30), 10);
    expect(s.pull, 40);
    expect(s.bouncing, isFalse);

    // Lift-off past the threshold opens the preview, and clears the pull.
    s = pullStep(update(-80, dragging: false), pullThreshold + 1);
    expect(s.release, isTrue);
    expect(s.open, isTrue);
    expect(s.pull, 0);

    // Lift-off short of it opens nothing.
    s = pullStep(update(0, dragging: false), pullThreshold - 1);
    expect(s.release, isTrue);
    expect(s.open, isFalse);

    // Scrolling the list down is not a pull.
    s = pullStep(update(120), 0);
    expect(s.pull, 0);
    expect(s.release, isFalse);

    // Settling with no pull behind it does nothing at all.
    s = pullStep(update(0, dragging: false), 0);
    expect(s.release, isFalse);
    expect(s.open, isFalse);
  });
}
