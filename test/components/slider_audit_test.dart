import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regression tests for DsSlider.
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

  testWidgets('takes its style width under an unbounded width', (tester) async {
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

  testWidgets('a quick click reports the new value to onChangeEnd', (
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

  testWidgets('press, hold, then drag: one start, one end', (tester) async {
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

  testWidgets('disabled mid-drag does not stay grabbing', (tester) async {
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

  testWidgets('NaN and an empty range do not crash', (tester) async {
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

  group('keys and screen-reader steps', () {
    /// A slider that keeps its value, logging every callback in order.
    Future<FocusNode> pumpLogged(
      WidgetTester tester,
      List<String> log, {
      required double initial,
      double min = 0,
      double max = 1,
      int? divisions,
    }) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = initial;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, set) => DsSlider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                focusNode: node,
                semanticLabel: 'Zoom',
                onChangeStart: (v) => log.add('start $v'),
                onChangeEnd: (v) => log.add('end $v'),
                onChanged: (v) => set(() {
                  value = v;
                  log.add('change $v');
                }),
              ),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      return node;
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }

    testWidgets('each key step is a change with its own start and end', (
      tester,
    ) async {
      final log = <String>[];
      await pumpLogged(tester, log, initial: 2, max: 4, divisions: 4);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(log, ['start 2.0', 'change 3.0', 'end 3.0']);
      log.clear();
      await press(tester, LogicalKeyboardKey.end);
      expect(log, ['start 3.0', 'change 4.0', 'end 4.0']);
      log.clear();
      // At the end already: nothing changes, nothing is reported.
      await press(tester, LogicalKeyboardKey.end);
      expect(log, isEmpty);
    });

    testWidgets('a held key reports each repeat as its own change', (
      tester,
    ) async {
      final log = <String>[];
      await pumpLogged(tester, log, initial: 0, max: 10, divisions: 10);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, [
        'start 0.0',
        'change 1.0',
        'end 1.0',
        'start 1.0',
        'change 2.0',
        'end 2.0',
      ]);
    });

    testWidgets('each screen-reader step is a change with its own start '
        'and end', (tester) async {
      final semantics = tester.ensureSemantics();
      final log = <String>[];
      await pumpLogged(tester, log, initial: 2, max: 4, divisions: 4);
      final zoom = find.semantics.byLabel('Zoom');
      tester.semantics.performAction(zoom, SemanticsAction.increase);
      await tester.pump();
      expect(log, ['start 2.0', 'change 3.0', 'end 3.0']);
      log.clear();
      tester.semantics.performAction(zoom, SemanticsAction.decrease);
      await tester.pump();
      expect(log, ['start 3.0', 'change 2.0', 'end 2.0']);
      semantics.dispose();
    });

    testWidgets('Page Up and Page Down move at least one step', (tester) async {
      Future<List<double>> pages(
        double initial,
        int? divisions,
        List<LogicalKeyboardKey> keys, {
        double max = 1,
      }) async {
        final log = <String>[];
        await pumpLogged(
          tester,
          log,
          initial: initial,
          max: max,
          divisions: divisions,
        );
        final seen = <double>[];
        for (final key in keys) {
          log.clear();
          await press(tester, key);
          final change = log.where((e) => e.startsWith('change ')).toList();
          seen.add(
            change.isEmpty
                ? double.nan
                : double.parse(change.single.split(' ')[1]),
          );
        }
        return seen;
      }

      const up = LogicalKeyboardKey.pageUp, down = LogicalKeyboardKey.pageDown;
      // Two and four steps: a tenth of the range rounds to no step at all.
      expect(await pages(.5, 2, [up, down, down]), [1.0, .5, 0.0]);
      expect(await pages(.5, 4, [up, down]), [.75, .5]);
      expect(await pages(1, 5, [down, down]), [.8, .6]);
      // A tenth that falls between steps rounds away from the value.
      expect(await pages(0, 15, [up, down], max: 15), [2.0, 0.0]);
      // Ten or more steps, and continuous: a tenth, as before.
      expect(await pages(0, 20, [up], max: 20), [2.0]);
      expect(await pages(50, null, [up, down], max: 100), [60.0, 50.0]);
    });
  });
}
