import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every animation is a spring.
void main() {
  group('DsSpring', () {
    const tone = DsMotion();

    test('a tone spring never overshoots (no flashing colors)', () {
      final curve = tone.toneCurve;
      var last = 0.0;
      for (var i = 1; i <= 100; i++) {
        final v = curve.transform(i / 100);
        expect(v, lessThanOrEqualTo(1.0 + 1e-9));
        expect(v, greaterThanOrEqualTo(last - 1e-9), reason: 'monotonic');
        last = v;
      }
    });

    // The movement spring overshoots its target by about 4%: enough to
    // feel alive, not enough to look like a cartoon bounce.
    test('a movement spring overshoots about 4% and settles', () {
      final curve = tone.moveCurve;
      final peak = [for (var i = 0; i <= 200; i++) curve.transform(i / 200)]
          .reduce((a, b) => a > b ? a : b);
      expect(peak, inInclusiveRange(1.03, 1.05));
      expect(curve.transform(1), 1);
    });

    test('settle durations stay in a UI range', () {
      expect(tone.toneDuration.inMilliseconds, inInclusiveRange(150, 350));
      expect(tone.moveDuration.inMilliseconds, inInclusiveRange(300, 800));
      expect(const DsMotion(reduced: true).moveDuration, Duration.zero);
    });
  });

  group('DsSpringValue', () {
    Widget host(
      double value, {
      DsSpring? spring = const DsSpring(
        duration: Duration(milliseconds: 380),
        bounce: .28,
      ),
    }) => Directionality(
      textDirection: TextDirection.ltr,
      child: DsSpringValue(
        value: value,
        spring: spring,
        builder: (context, v, _) => Text(v.toStringAsFixed(4)),
      ),
    );
    double shown(WidgetTester tester) =>
        double.parse(tester.widget<Text>(find.byType(Text)).data!);

    testWidgets('first build shows the value without animating', (
      tester,
    ) async {
      await tester.pumpWidget(host(1));
      expect(shown(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a reversed target keeps the velocity', (tester) async {
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 60));
      final before = shown(tester);
      // Reverse mid-flight: the value keeps moving forward for a moment
      // instead of turning back instantly.
      await tester.pumpWidget(host(0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(shown(tester), greaterThan(before));
      await tester.pumpAndSettle();
      expect(shown(tester), closeTo(0, .005));
    });

    testWidgets('a small move lands exactly on its target', (tester) async {
      await tester.pumpWidget(host(1));
      await tester.pumpWidget(host(.955)); // a press scale
      await tester.pumpAndSettle();
      expect(shown(tester), .955);
    });

    testWidgets('null spring (reduce motion) jumps', (tester) async {
      await tester.pumpWidget(host(0, spring: null));
      await tester.pumpWidget(host(1, spring: null));
      expect(shown(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  test('settle durations stay right past the cache bound', () {
    const probe = DsSpring(duration: Duration(milliseconds: 200));
    final expected = probe.settleDuration;
    for (var ms = 100; ms < 300; ms++) {
      DsSpring(duration: Duration(milliseconds: ms)).settleDuration;
    }
    expect(probe.settleDuration, expected);
  });
}
