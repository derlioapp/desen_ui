import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsRangeSlider: two thumbs on DsSlider's track.
void main() {
  // The default thumb is 20 wide; its center travels from 10 to width - 10.
  const thumb = 20.0;

  /// A range slider 420 wide that keeps its values, reported in [log].
  Widget harness({
    required DsRangeValues initial,
    List<DsRangeValues>? log,
    double min = 0,
    double max = 1,
    int? divisions,
    double minDistance = 0,
    bool enabled = true,
    TextDirection direction = TextDirection.ltr,
    DsThemeData? theme,
    List<DsRangeValues>? starts,
    List<DsRangeValues>? ends,
    String? label,
    String Function(double)? formatter,
    DsSliderStyle? style,
  }) {
    var values = initial;
    // Tab moves focus through the app's default shortcuts, as under any
    // WidgetsApp.
    return Shortcuts(
      shortcuts: WidgetsApp.defaultShortcuts,
      child: Actions(
        actions: WidgetsApp.defaultActions,
        // Focus starts in the page, so the first Tab has somewhere to go.
        child: FocusScope(
          autofocus: true,
          child: host(
            SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, set) => DsRangeSlider(
                  values: values,
                  min: min,
                  max: max,
                  divisions: divisions,
                  minDistance: minDistance,
                  semanticLabel: label,
                  semanticFormatter: formatter,
                  style: style,
                  onChangeStart: starts?.add,
                  onChangeEnd: ends?.add,
                  onChanged: enabled
                      ? (v) => set(() {
                          values = v;
                          log?.add(v);
                        })
                      : null,
                ),
              ),
            ),
            direction: direction,
            theme: theme,
          ),
        ),
      ),
    );
  }

  Rect box(WidgetTester tester) => tester.getRect(find.byType(DsRangeSlider));

  /// The point on the track at fraction [t] from the left edge.
  Offset at(WidgetTester tester, double t) {
    final r = box(tester);
    return Offset(r.left + thumb / 2 + t * (r.width - thumb), r.center.dy);
  }

  DsRangeValues last(List<DsRangeValues> log) => log.last;

  group('pointer', () {
    testWidgets('dragging a thumb moves only that thumb', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .2, end: .8), log: log),
      );
      await tester.dragFrom(at(tester, .2), const Offset(40, 0));
      await tester.pump();
      expect(last(log).start, closeTo(.2 + 40 / 400, .01));
      expect(last(log).end, .8);

      await tester.dragFrom(at(tester, .8), const Offset(-80, 0));
      await tester.pump();
      expect(last(log).end, closeTo(.6, .01));
      expect(last(log).start, closeTo(.3, .01));
    });

    testWidgets('pressing the track moves the nearer thumb', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .2, end: .8), log: log),
      );
      await tester.tapAt(at(tester, .05));
      await tester.pump();
      expect(last(log).start, closeTo(.05, .01));
      expect(last(log).end, .8);

      // Nearer the end thumb, inside the range.
      await tester.tapAt(at(tester, .6));
      await tester.pump();
      expect(last(log).end, closeTo(.6, .01));
      expect(last(log).start, closeTo(.05, .01));

      await tester.tapAt(at(tester, .95));
      await tester.pump();
      expect(last(log).end, closeTo(.95, .01));
    });

    testWidgets('the thumbs never cross', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .2, end: .5), log: log),
      );
      // Drag the start thumb far past the end thumb: it stops there.
      await tester.dragFrom(at(tester, .2), const Offset(300, 0));
      await tester.pump();
      expect(last(log), const DsRangeValues(start: .5, end: .5));

      // And the end thumb, pulled below the start, stops at it.
      log.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .4, end: .7), log: log),
      );
      await tester.dragFrom(at(tester, .7), const Offset(-300, 0));
      await tester.pump();
      expect(last(log), const DsRangeValues(start: .4, end: .4));
      for (final v in log) {
        expect(v.start <= v.end, isTrue, reason: '$v');
      }
    });

    testWidgets('on the same spot, the drag direction picks the thumb', (
      tester,
    ) async {
      for (final (dx, expected) in [
        (60.0, const DsRangeValues(start: .5, end: .65)),
        (-60.0, const DsRangeValues(start: .35, end: .5)),
      ]) {
        final log = <DsRangeValues>[];
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          harness(initial: const DsRangeValues(start: .5, end: .5), log: log),
        );
        await tester.dragFrom(at(tester, .5), Offset(dx, 0));
        await tester.pump();
        expect(last(log).start, closeTo(expected.start, .01), reason: '$dx');
        expect(last(log).end, closeTo(expected.end, .01), reason: '$dx');
      }
    });

    testWidgets('in RTL, the start thumb sits on the right', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .2, end: .8),
          log: log,
          direction: TextDirection.rtl,
        ),
      );
      // The start value .2 is drawn at .8 from the left.
      await tester.dragFrom(at(tester, .8), const Offset(40, 0));
      await tester.pump();
      expect(last(log).start, closeTo(.1, .01));
      expect(last(log).end, .8);

      // Both on one spot: dragging left (toward max in RTL) takes the end.
      log.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .5, end: .5),
          log: log,
          direction: TextDirection.rtl,
        ),
      );
      await tester.dragFrom(at(tester, .5), const Offset(-60, 0));
      await tester.pump();
      expect(last(log).start, .5);
      expect(last(log).end, closeTo(.65, .01));
    });

    testWidgets('one start and one end per gesture, with the new values', (
      tester,
    ) async {
      final starts = <DsRangeValues>[], ends = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .2, end: .8),
          starts: starts,
          ends: ends,
        ),
      );
      await tester.tapAt(at(tester, .1));
      await tester.pumpAndSettle();
      expect(starts, [const DsRangeValues(start: .2, end: .8)]);
      expect(ends.single.start, closeTo(.1, .01));

      final g = await tester.startGesture(at(tester, .8));
      await tester.pump(const Duration(milliseconds: 200));
      for (var i = 0; i < 5; i++) {
        await g.moveBy(const Offset(-10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect((starts.length, ends.length), (2, 2));
      expect(ends.last.end, closeTo(.8 - 50 / 400, .01));
    });
  });

  group('steps and distance', () {
    testWidgets('drags snap to the steps, without float dust', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 0, end: 1),
          log: log,
          divisions: 10,
        ),
      );
      await tester.dragFrom(at(tester, 0), const Offset(122, 0));
      await tester.pump();
      expect(last(log).start, .3);
      await tester.dragFrom(at(tester, 1), const Offset(-78, 0));
      await tester.pump();
      expect(last(log).end, .8);
    });

    testWidgets('minDistance keeps a gap, on the grid when stepped', (
      tester,
    ) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 10, end: 60),
          min: 0,
          max: 100,
          minDistance: 15,
          log: log,
        ),
      );
      await tester.dragFrom(at(tester, .1), const Offset(400, 0));
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 45, end: 60));

      log.clear();
      await tester.pumpWidget(const SizedBox());
      // Steps of 10 and a gap of 15: the end stops at the first step at
      // least 15 above the start.
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 20, end: 80),
          min: 0,
          max: 100,
          divisions: 10,
          minDistance: 15,
          log: log,
        ),
      );
      await tester.dragFrom(at(tester, .8), const Offset(-400, 0));
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 20, end: 40));
    });
  });

  group('keyboard', () {
    Future<void> focusThumb(WidgetTester tester, int index) async {
      // Tab from outside the slider: the start thumb comes first.
      for (var i = 0; i <= index; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
    }

    testWidgets('each thumb is its own focus stop, the start first', (
      tester,
    ) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 2, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          log: log,
        ),
      );
      await focusThumb(tester, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 3, end: 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 3, end: 7));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 3, end: 6));
    });

    testWidgets('Home and End stop at the other thumb', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 2, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          minDistance: 1,
          log: log,
        ),
      );
      await focusThumb(tester, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 5, end: 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 0, end: 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 0, end: 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 0, end: 10));
      // Arrows cannot push past the other thumb either.
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 0, end: 1));
    });

    testWidgets('Page Up and Page Down move a tenth', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 20, end: 80),
          min: 0,
          max: 100,
          log: log,
        ),
      );
      await focusThumb(tester, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 20, end: 90));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 20, end: 80));
    });

    testWidgets('Page Up and Page Down move at least one step', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 0, end: 1),
          divisions: 4,
          log: log,
        ),
      );
      await focusThumb(tester, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: .25, end: 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: .25, end: .75));
    });

    testWidgets('each key step is a change with its own start and end', (
      tester,
    ) async {
      final log = <DsRangeValues>[], starts = <DsRangeValues>[];
      final ends = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 2, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          log: log,
          starts: starts,
          ends: ends,
        ),
      );
      await focusThumb(tester, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(starts, const [
        DsRangeValues(start: 2, end: 6),
        DsRangeValues(start: 2, end: 7),
      ]);
      expect(ends, const [
        DsRangeValues(start: 2, end: 7),
        DsRangeValues(start: 2, end: 10),
      ]);
      // At the end already: nothing changes, nothing is reported.
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect((log.length, starts.length, ends.length), (2, 2, 2));
    });

    testWidgets('arrows mirror in RTL', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 2, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          log: log,
          direction: TextDirection.rtl,
        ),
      );
      await focusThumb(tester, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 3, end: 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 2, end: 6));
    });

    testWidgets('focus follows the thumb a drag takes', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 2, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          log: log,
        ),
      );
      await focusThumb(tester, 0);
      await tester.dragFrom(at(tester, .6), const Offset(40, 0));
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 2, end: 7));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 2, end: 8));
    });
  });

  group('screen readers', () {
    testWidgets('each thumb is its own named slider with its value', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 100, end: 400),
          min: 0,
          max: 500,
          divisions: 50,
          label: 'Price',
          formatter: (v) => '\$${v.round()}',
        ),
      );
      expect(
        node(find.semantics.byLabel('Price\nMinimum')),
        isSemantics(
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          label: 'Price\nMinimum',
          value: r'$100',
          increasedValue: r'$110',
          decreasedValue: r'$90',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        node(find.semantics.byLabel('Price\nMaximum')),
        isSemantics(
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          label: 'Price\nMaximum',
          value: r'$400',
          increasedValue: r'$410',
          decreasedValue: r'$390',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('without a label, each thumb says which end it is', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .25, end: .75)),
      );
      expect(node(find.semantics.byLabel('Minimum')).value, '25%');
      expect(node(find.semantics.byLabel('Maximum')).value, '75%');
      semantics.dispose();
    });

    testWidgets('increase and decrease stop at the other thumb', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 4, end: 5),
          min: 0,
          max: 10,
          divisions: 10,
          log: log,
        ),
      );
      final start = find.semantics.byLabel('Minimum');
      final end = find.semantics.byLabel('Maximum');
      tester.semantics.performAction(start, SemanticsAction.increase);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 5, end: 5));
      // Now touching: the start says it cannot go higher, and does not.
      expect(node(start).increasedValue, '50%');
      tester.semantics.performAction(start, SemanticsAction.increase);
      await tester.pump();
      expect(log, hasLength(1));
      expect(node(end).decreasedValue, '50%');
      tester.semantics.performAction(end, SemanticsAction.decrease);
      await tester.pump();
      expect(log, hasLength(1));
      tester.semantics.performAction(end, SemanticsAction.increase);
      await tester.pump();
      expect(last(log), const DsRangeValues(start: 5, end: 6));
      semantics.dispose();
    });

    testWidgets('each step is a change with its own start and end', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final starts = <DsRangeValues>[], ends = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: 4, end: 6),
          min: 0,
          max: 10,
          divisions: 10,
          starts: starts,
          ends: ends,
        ),
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Maximum'),
        SemanticsAction.increase,
      );
      await tester.pump();
      tester.semantics.performAction(
        find.semantics.byLabel('Minimum'),
        SemanticsAction.decrease,
      );
      await tester.pump();
      expect(starts, const [
        DsRangeValues(start: 4, end: 6),
        DsRangeValues(start: 4, end: 7),
      ]);
      expect(ends, const [
        DsRangeValues(start: 4, end: 7),
        DsRangeValues(start: 3, end: 7),
      ]);
      semantics.dispose();
    });

    testWidgets('the thumb names follow the app language', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('tr'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: harness(
            initial: const DsRangeValues(start: .2, end: .8),
            label: 'Fiyat',
          ),
        ),
      );
      expect(find.semantics.byLabel('Fiyat\nEn düşük'), findsOne);
      expect(find.semantics.byLabel('Fiyat\nEn yüksek'), findsOne);
      semantics.dispose();
    });
  });

  group('disabled', () {
    testWidgets('a null onChanged ignores pointer, keys and focus', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .2, end: .8),
          log: log,
          enabled: false,
        ),
      );
      await tester.dragFrom(at(tester, .2), const Offset(60, 0));
      await tester.tapAt(at(tester, .5));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, isEmpty);
      final data = node(find.semantics.byLabel('Minimum'));
      expect(
        data,
        isSemantics(
          isSlider: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Minimum',
          value: '20%',
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at(tester, .5));
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );
      semantics.dispose();
    });

    testWidgets('it takes the disabled look', (tester) async {
      final t = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .2, end: .8),
          enabled: false,
          theme: t,
        ),
      );
      final disabled = DsSlider.defaultStyle(t).disabled!;
      expect(thumbDecoration(tester, 0).color, disabled.thumbColor);
      expect(thumbDecoration(tester, 1).color, disabled.thumbColor);
      expect(find.byWidgetPredicate(isFill(disabled.fillColor!)), findsOne);
    });
  });

  group('look', () {
    testWidgets('the fill lies between the thumbs', (tester) async {
      final t = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .25, end: .75), theme: t),
      );
      final fill = tester.getRect(
        find.byWidgetPredicate(isFill(DsSlider.defaultStyle(t).fillColor!)),
      );
      expect(fill.left, moreOrLessEquals(at(tester, .25).dx));
      expect(fill.right, moreOrLessEquals(at(tester, .75).dx));
    });

    testWidgets('hover rings only the thumb a press would move', (
      tester,
    ) async {
      final t = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .2, end: .8), theme: t),
      );
      final ring = DsSlider.defaultStyle(t).hovered!.thumbBorderColor!;
      bool ringed(int i) =>
          thumbDecoration(tester, i).shadows.any((s) => s.color == ring);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(at(tester, .3));
      await tester.pump();
      expect((ringed(0), ringed(1)), (true, false));
      await mouse.moveTo(at(tester, .7));
      await tester.pump();
      expect((ringed(0), ringed(1)), (false, true));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.grab,
      );
    });

    testWidgets('the focus ring shows on the focused thumb only', (
      tester,
    ) async {
      useTraditionalHighlights();
      final t = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        harness(initial: const DsRangeValues(start: .2, end: .8), theme: t),
      );
      final focus = DsSlider.defaultStyle(t).focusShadows!;
      bool ringed(int i) =>
          focus.every((f) => thumbDecoration(tester, i).shadows.contains(f));
      expect((ringed(0), ringed(1)), (false, false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect((ringed(0), ringed(1)), (true, false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect((ringed(0), ringed(1)), (false, true));
    });

    testWidgets('the theme and the style restyle it, the style winning', (
      tester,
    ) async {
      const themed = Color(0xFF0B6E4F), own = Color(0xFFAA3355);
      await tester.pumpWidget(
        DsSliderTheme(
          data: const DsSliderThemeData(
            style: DsSliderStyle(fillColor: themed, thumbColor: themed),
          ),
          child: harness(
            initial: const DsRangeValues(start: .2, end: .8),
            style: const DsSliderStyle(thumbColor: own, thumbSize: 24),
          ),
        ),
      );
      expect(find.byWidgetPredicate(isFill(themed)), findsOne);
      for (final i in [0, 1]) {
        expect(thumbDecoration(tester, i).color, own);
        expect(tester.getSize(thumbFinder(i)), const Size(24, 24));
      }
    });

    testWidgets('on touch, a 44px band around a 20px thumb', (tester) async {
      final log = <DsRangeValues>[];
      await tester.pumpWidget(
        harness(
          initial: const DsRangeValues(start: .2, end: .8),
          log: log,
          theme: DsThemeData(
            platform: TargetPlatform.iOS,
            density: DsDensity.compact,
          ),
        ),
      );
      expect(box(tester).height, 44);
      expect(tester.getSize(thumbFinder(0)), const Size(20, 20));
      // A press 20px above the track's center still takes the thumb.
      await tester.dragFrom(
        at(tester, .2) + const Offset(0, -20),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(last(log).start, closeTo(.3, .01));
    });
  });

  testWidgets('odd values do not crash', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 200,
          child: Column(
            children: [
              DsRangeSlider(
                values: const DsRangeValues(start: double.nan, end: double.nan),
                onChanged: (_) {},
              ),
              DsRangeSlider(
                values: const DsRangeValues(start: -3, end: 7),
                onChanged: (_) {},
              ),
              DsRangeSlider(
                values: const DsRangeValues(start: 5, end: 5),
                min: 5,
                max: 5,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('takes the style width under an unbounded width', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsRangeSlider(
              values: const DsRangeValues(start: .2, end: .8),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(DsRangeSlider)).width, 160);
  });
}

/// The one semantics node [f] finds.
SemanticsNode node(SemanticsFinder f) => f.evaluate().single;

/// The painted thumb [i]: 0 start, 1 end.
Finder thumbFinder(int i) => find
    .descendant(of: find.byKey(ValueKey(i)), matching: find.byType(Container))
    .last;

DsBoxDecoration thumbDecoration(WidgetTester tester, int i) =>
    tester.widget<Container>(thumbFinder(i)).decoration! as DsBoxDecoration;

/// Matches the fill between the thumbs, painted in [color].
WidgetPredicate isFill(Color color) =>
    (w) => w is Container && w.color == color;
