import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

/// DsPressEffect: one switch for the press motion of a subtree.
void main() {
  final theme = DsThemeData();

  /// The press scale the [index]th spring-scaled box under [of] shows.
  double scaleUnder(WidgetTester tester, Finder of, [int index = 0]) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.descendant(of: of, matching: find.byType(DsSpringValue)),
              matching: find.byType(Transform),
            )
            .at(index),
      )
      .transform
      .storage[0];

  Widget button({DsButtonStyle? style}) =>
      DsButton(style: style, onPressed: () {}, child: const Text('Save'));

  group('of', () {
    testWidgets('is on without a scope, follows the nearest one', (
      tester,
    ) async {
      final seen = <bool>[];
      Widget probe() => Builder(
        builder: (context) {
          seen.add(DsPressEffect.of(context));
          return const SizedBox();
        },
      );
      await tester.pumpWidget(
        Column(
          children: [
            probe(),
            DsPressEffect(
              enabled: false,
              child: Column(
                children: [
                  probe(),
                  DsPressEffect(enabled: true, child: probe()),
                ],
              ),
            ),
          ],
        ),
      );
      expect(seen, [true, false, true]);
    });

    testWidgets('scaleOf passes the scale through only while on', (
      tester,
    ) async {
      late double on, off;
      await tester.pumpWidget(
        Column(
          children: [
            Builder(
              builder: (context) {
                on = DsPressEffect.scaleOf(context, .9);
                return const SizedBox();
              },
            ),
            DsPressEffect(
              enabled: false,
              child: Builder(
                builder: (context) {
                  off = DsPressEffect.scaleOf(context, .9);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );
      expect(on, .9);
      expect(off, 1);
    });

    test('notifies only when enabled changes', () {
      const a = DsPressEffect(enabled: true, child: SizedBox());
      const b = DsPressEffect(enabled: true, child: SizedBox());
      const c = DsPressEffect(enabled: false, child: SizedBox());
      expect(b.updateShouldNotify(a), isFalse);
      expect(c.updateShouldNotify(a), isTrue);
    });
  });

  group('buttons', () {
    testWidgets('off: a pressed button keeps its size, its colors still '
        'answer', (tester) async {
      await tester.pumpWidget(
        host(DsPressEffect(enabled: false, child: button()), theme: theme),
      );
      expect(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(DsSpringValue),
        ),
        findsNothing,
      );
      final size = buttonBoxSize(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DsButton)),
      );
      await tester.pumpAndSettle();
      expect(buttonBoxSize(tester), size);
      // The press color still shows: only the motion is gone.
      expect(buttonDecoration(tester).color, theme.colors.accentPress);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('off wins over a press scale set in a style', (tester) async {
      await tester.pumpWidget(
        host(
          DsPressEffect(
            enabled: false,
            child: button(style: const DsButtonStyle(pressScale: .8)),
          ),
          theme: theme,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(DsSpringValue),
        ),
        findsNothing,
      );
    });

    testWidgets('a nested scope turns the motion back on', (tester) async {
      await tester.pumpWidget(
        host(
          DsPressEffect(
            enabled: false,
            child: DsPressEffect(enabled: true, child: button()),
          ),
          theme: theme,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DsButton)),
      );
      await tester.pumpAndSettle();
      expect(
        scaleUnder(tester, find.byType(DsButton)),
        closeTo(theme.motion.pressScaleLarge, .001),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('on does not give a ghost button a motion it does not have', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DsPressEffect(
            enabled: true,
            child: DsButton(
              variant: .ghost,
              onPressed: () {},
              child: const Text('Ghost'),
            ),
          ),
          theme: theme,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(DsSpringValue),
        ),
        findsNothing,
      );
    });

    testWidgets('toggling the scope applies at once', (tester) async {
      Widget tree(bool on) => host(
        DsPressEffect(enabled: on, child: button()),
        theme: theme,
      );
      await tester.pumpWidget(tree(true));
      expect(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(DsSpringValue),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(tree(false));
      expect(
        find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(DsSpringValue),
        ),
        findsNothing,
      );
    });

    testWidgets('reduced motion still wins: on, the press does not animate', (
      tester,
    ) async {
      final reduced = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(
        host(DsPressEffect(enabled: true, child: button()), theme: reduced),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DsButton)),
      );
      // One frame: the scale is already at its end, with no spring between.
      await tester.pump();
      expect(
        scaleUnder(tester, find.byType(DsButton)),
        reduced.motion.pressScaleLarge,
      );
      await gesture.up();
      await tester.pump();
      expect(scaleUnder(tester, find.byType(DsButton)), 1);
    });
  });

  testWidgets('off: stepper buttons keep their size when pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsPressEffect(
          enabled: false,
          child: DsStepper(value: 5, onChanged: (_) {}),
        ),
        theme: theme,
      ),
    );
    final plus = find
        .descendant(
          of: find.byType(DsStepper<int>),
          matching: find.byType(DsPressable),
        )
        .last;
    final gesture = await tester.startGesture(tester.getCenter(plus));
    await tester.pumpAndSettle();
    final transforms = find.descendant(
      of: find.byType(DsStepper<int>),
      matching: find.byType(DsSpringValue),
    );
    for (var i = 0; i < transforms.evaluate().length; i++) {
      expect(scaleUnder(tester, find.byType(DsStepper<int>), i), 1);
    }
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('on: stepper buttons shrink while pressed', (tester) async {
    await tester.pumpWidget(
      host(DsStepper(value: 5, onChanged: (_) {}), theme: theme),
    );
    final plus = find
        .descendant(
          of: find.byType(DsStepper<int>),
          matching: find.byType(DsPressable),
        )
        .last;
    final gesture = await tester.startGesture(tester.getCenter(plus));
    await tester.pumpAndSettle();
    final springs = find
        .descendant(
          of: find.byType(DsStepper<int>),
          matching: find.byType(DsSpringValue),
        )
        .evaluate()
        .length;
    final scales = [
      for (var i = 0; i < springs; i++)
        scaleUnder(tester, find.byType(DsStepper<int>), i),
    ];
    expect(scales.any((s) => s < 1), isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
