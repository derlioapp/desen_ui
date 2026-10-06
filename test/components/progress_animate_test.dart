import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// `animate: false` draws each value as given, so a value that follows a
/// scroll position does not trail behind it.
void main() {
  double fillFactor(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(
        find.descendant(
          of: find.byType(DsProgressBar),
          matching: find.byType(FractionallySizedBox),
        ),
      )
      .widthFactor!;

  Widget bar(double value, {required bool animate}) => SizedBox(
    width: 200,
    child: DsProgressBar(value: value, animate: animate),
  );

  testWidgets('by default a bar moves into place', (tester) async {
    await tester.pumpWidget(host(bar(.2, animate: true)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(bar(.8, animate: true)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(fillFactor(tester), lessThan(.8));
    await tester.pumpAndSettle();
    expect(fillFactor(tester), moreOrLessEquals(.8));
  });

  testWidgets('animate: false draws the bar at the new value at once', (
    tester,
  ) async {
    await tester.pumpWidget(host(bar(.2, animate: false)));
    expect(fillFactor(tester), .2);
    await tester.pumpWidget(host(bar(.8, animate: false)));
    expect(fillFactor(tester), .8);
    // Nothing is left to settle.
    expect(tester.hasRunningAnimations, isFalse);
    // Still clamped.
    await tester.pumpWidget(host(bar(1.4, animate: false)));
    expect(fillFactor(tester), 1);
  });

  testWidgets('animate: false leaves the ring nothing to animate', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DsProgressRing(value: .2, animate: false)),
    );
    await tester.pumpWidget(
      host(const DsProgressRing(value: .9, animate: false)),
    );
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      find.descendant(
        of: find.byType(DsProgressRing),
        matching: find.byWidgetPredicate((w) => w is TweenAnimationBuilder),
      ),
      findsNothing,
    );
  });

  testWidgets('animate: false keeps the value for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              child: DsProgressBar(value: .4, animate: false),
            ),
            DsProgressRing(value: .6, animate: false),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(DsProgressBar)),
      isSemantics(value: '40%'),
    );
    expect(
      tester.getSemantics(find.byType(DsProgressRing)),
      isSemantics(value: '60%'),
    );
    semantics.dispose();
  });

  testWidgets('the indeterminate sweep ignores animate', (tester) async {
    await tester.pumpWidget(
      host(const SizedBox(width: 200, child: DsProgressBar(animate: false))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
  });
}
