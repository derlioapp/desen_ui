import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsStepper at its edges: unbounded limits, a fractional step on an int
/// stepper, and a narrow parent with large text.
void main() {
  Finder button(DsIconData data) =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == data);

  group('unbounded limits', () {
    testWidgets('an int stepper with max: double.infinity builds and steps', (
      tester,
    ) async {
      final seen = <int>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = 98;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsStepper(
              value: value,
              max: double.infinity,
              focusNode: node,
              onChanged: (v) => set(() {
                value = v;
                seen.add(v);
              }),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(button(DsIcons.plus));
      await tester.pump();
      await tester.tap(button(DsIcons.plus));
      await tester.pump();
      expect(seen, [99, 100]);
      expect(find.text('100'), findsOneWidget);
      node.requestFocus();
      await tester.pump();
      // No last value to jump to.
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(seen.last, 100);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(seen.last, 0);
    });

    testWidgets('an int stepper unbounded both ways', (tester) async {
      final seen = <int>[];
      var value = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsStepper(
              value: value,
              min: double.negativeInfinity,
              max: double.infinity,
              onChanged: (v) => set(() {
                value = v;
                seen.add(v);
              }),
            ),
          ),
        ),
      );
      await tester.tap(button(DsIcons.minus));
      await tester.pump();
      expect(seen, [-1]);
    });

    testWidgets('a double stepper reserves no width for an unbounded limit', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsStepper(
            value: 2.5,
            min: double.negativeInfinity,
            max: double.infinity,
            step: .5,
            semanticLabel: 'Weight',
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Infinity'), findsNothing);
      expect(find.textContaining('∞'), findsNothing);
      // The digits come from the step, not from the unbounded min.
      expect(find.text('2.5'), findsOneWidget);
      final data = tester
          .getSemantics(find.byType(DsStepper<double>))
          .getSemanticsData();
      expect(data.increasedValue, '3.0');
      expect(data.decreasedValue, '2.0');
      final unbounded = tester.getSize(find.byType(DsStepper<double>)).width;
      await tester.pumpWidget(
        host(
          DsStepper(value: 2.5, min: 0, max: 5, step: .5, onChanged: (_) {}),
        ),
      );
      expect(
        unbounded,
        lessThanOrEqualTo(tester.getSize(find.byType(DsStepper<double>)).width),
      );
      handle.dispose();
    });
  });

  testWidgets('an int stepper with a fractional step still steps both ways', (
    tester,
  ) async {
    final seen = <int>[];
    var value = 3;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => DsStepper(
            value: value,
            max: 10,
            step: .5,
            onChanged: (v) => set(() {
              value = v;
              seen.add(v);
            }),
          ),
        ),
      ),
    );
    await tester.tap(button(DsIcons.minus));
    await tester.pump();
    await tester.tap(button(DsIcons.minus));
    await tester.pump();
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen, [2, 1, 2]);
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('200px wide at text scale $scale: no overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          textScale: scale,
          SizedBox(
            width: 200,
            child: DsStepper(
              value: .3,
              min: -1,
              max: 1,
              step: .1,
              unit: 'kg',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(DsStepper<double>)).width, 200);
      expect(find.text('0.3'), findsOneWidget);
      // The number stays whole inside the stepper.
      final stepper = tester.getRect(find.byType(DsStepper<double>));
      final number = tester.getRect(find.text('0.3'));
      expect(number.left, greaterThanOrEqualTo(stepper.left));
      expect(number.right, lessThanOrEqualTo(stepper.right));
    });
  }
}
