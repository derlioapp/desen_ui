import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regressions from the blind audit (phase B): DsSlider.
void main() {
  Widget slider({
    required double value,
    required ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeStart,
    ValueChanged<double>? onChangeEnd,
    double min = 0,
    double max = 1,
  }) => DsSlider(
    value: value,
    min: min,
    max: max,
    onChanged: onChanged,
    onChangeStart: onChangeStart,
    onChangeEnd: onChangeEnd,
  );

  test('the thumb is the switch knob, with no outline added', () {
    for (final brightness in Brightness.values) {
      for (final contrast in DsContrast.values) {
        final t = DsThemeData(brightness: brightness, contrast: contrast);
        final s = DsSlider.defaultStyle(t);
        final reason = '${brightness.name} ${contrast.name}';
        expect(s.thumbColor, t.colors.knob, reason: reason);
        expect(s.thumbShadows, t.shadows.knob, reason: reason);
        expect(s.thumbBorderColor!.a, 0, reason: reason);
        // The knob shadow keeps a white thumb visible on a white surface.
        expect(t.shadows.knob, isNotEmpty, reason: reason);
      }
    }
  });

  testWidgets('takes its style width under an unbounded width (B5)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [slider(value: .5, onChanged: (_) {})],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DsSlider)).width, 160);
  });

  testWidgets('a quick click reports the new value to onChangeEnd (B6)', (
    tester,
  ) async {
    var value = 0.0;
    final starts = <double>[], ends = <double>[];
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) => slider(
              value: value,
              onChanged: (v) => setState(() => value = v),
              onChangeStart: starts.add,
              onChangeEnd: ends.add,
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsSlider));
    await tester.tapAt(Offset(box.left + box.width * .75, box.center.dy));
    await tester.pumpAndSettle();
    expect(value, closeTo(.75, .03));
    expect(starts, [0.0]);
    expect(ends.single, closeTo(.75, .03));
  });

  testWidgets('press, hold, then drag: one start, one end (B7)', (
    tester,
  ) async {
    var value = .5;
    var starts = 0, ends = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) => slider(
              value: value,
              onChanged: (v) => setState(() => value = v),
              onChangeStart: (_) => starts++,
              onChangeEnd: (_) => ends++,
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsSlider));
    final g = await tester.startGesture(
      Offset(box.left + box.width * .25, box.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 5; i++) {
      await g.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect((starts, ends), (1, 1));
  });

  testWidgets('disabled mid-drag does not stay grabbing (B8)', (tester) async {
    var value = .5;
    var enabled = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return slider(
                value: value,
                onChanged: enabled ? (v) => setState(() => value = v) : null,
              );
            },
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsSlider));
    final mouse = await tester.startGesture(
      box.center,
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(40, 0));
    await tester.pump();
    setOuter(() => enabled = false);
    await tester.pump();
    await mouse.up();
    await tester.pump();
    setOuter(() => enabled = true);
    await tester.pump();
    await mouse.moveBy(const Offset(1, 0));
    await tester.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );
    await mouse.removePointer();
  });

  testWidgets('NaN and an empty range do not crash (B9)', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 200,
          child: Column(
            children: [
              slider(value: double.nan, onChanged: (_) {}),
              slider(value: 5, min: 5, max: 5, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // The empty range cannot change: no adjust actions.
    final data = tester
        .getSemantics(find.byType(DsSlider).last)
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.increase), isFalse);
  });

  group('divisions report grid values without float dust', () {
    Future<List<double>> stepRight(
      WidgetTester tester, {
      required double min,
      required double max,
      required int divisions,
    }) async {
      final seen = <double>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = min;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: StatefulBuilder(
              builder: (context, set) => DsSlider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                focusNode: node,
                onChanged: (v) => set(() {
                  value = v;
                  seen.add(v);
                }),
              ),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      for (var i = 0; i < divisions; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      return seen;
    }

    testWidgets('0 to 1 in tenths', (tester) async {
      final seen = await stepRight(tester, min: 0, max: 1, divisions: 10);
      expect(seen, [.1, .2, .3, .4, .5, .6, .7, .8, .9, 1.0]);
    });

    testWidgets('an offset range: 0.1 to 0.7 in six steps', (tester) async {
      final seen = await stepRight(tester, min: .1, max: .7, divisions: 6);
      expect(seen, [.2, .3, .4, .5, .6, .7]);
    });

    testWidgets('whole steps stay whole', (tester) async {
      final seen = await stepRight(tester, min: -3, max: 3, divisions: 6);
      expect(seen, [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0]);
    });
  });
}
