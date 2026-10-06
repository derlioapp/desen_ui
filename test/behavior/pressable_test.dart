import 'dart:ui' show SemanticsAction, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/behavior/focus_visibility_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

/// S-22 (keyboard activation) and S-23 (minimum tap target).
void main() {
  group('keyboard activation', () {
    late FocusNode node;
    late WidgetStatesController states;
    late int taps;

    setUp(() {
      node = FocusNode();
      states = WidgetStatesController();
      taps = 0;
    });
    tearDown(() {
      node.dispose();
      states.dispose();
    });

    Future<void> pump(WidgetTester tester, {Widget? inner}) async {
      await tester.pumpWidget(
        host(
          DsPressable(
            focusNode: node,
            statesController: states,
            onPressed: () => taps++,
            builder: (_, _, _) =>
                inner ?? const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
    }

    testWidgets('holding Enter fires once', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });

    testWidgets('Space presses on down and fires on release', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      expect(taps, 0);
      expect(states.value, contains(WidgetState.pressed));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(taps, 1);
      expect(states.value, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('losing focus mid-press cancels Space', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      node.unfocus();
      await tester.pump();
      expect(states.value, isNot(contains(WidgetState.pressed)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(taps, 0);
    });

    testWidgets('keys meant for a focused child are left alone', (
      tester,
    ) async {
      final inner = FocusNode();
      addTearDown(inner.dispose);
      await pump(
        tester,
        inner: Focus(focusNode: inner, child: const SizedBox(width: 40)),
      );
      inner.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 0);
    });
  });

  group('minimum tap target', () {
    Future<int> pumpTiny(
      WidgetTester tester, {
      DsDensity density = DsDensity.compact,
      double? minTapTarget,
    }) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          theme: DsThemeData(density: density, platform: TargetPlatform.macOS),
          DsPressable(
            key: const Key('p'),
            minTapTarget: minTapTarget,
            onPressed: () => taps++,
            builder: (_, _, _) =>
                const SizedBox(key: Key('visual'), width: 12, height: 12),
          ),
        ),
      );
      return taps;
    }

    // K-43: phones get 44px tap areas at either density; desktop 24 at
    // compact. Visuals never grow.
    for (final (density, platform, size) in [
      (DsDensity.compact, TargetPlatform.macOS, 24.0),
      (DsDensity.compact, TargetPlatform.windows, 24.0),
      (DsDensity.compact, TargetPlatform.iOS, 44.0),
      (DsDensity.compact, TargetPlatform.android, 44.0),
      (DsDensity.touch, TargetPlatform.macOS, 44.0),
    ]) {
      testWidgets('${density.name} on ${platform.name}: grows the hit area '
          'to $size', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          host(
            theme: DsThemeData(density: density, platform: platform),
            DsPressable(
              key: const Key('p'),
              onPressed: () => taps++,
              builder: (_, _, _) =>
                  const SizedBox(key: Key('visual'), width: 12, height: 12),
            ),
          ),
        );
        expect(tester.getSize(find.byKey(const Key('p'))), Size(size, size));
        expect(
          tester.getSize(find.byKey(const Key("visual"))),
          const Size(12, 12),
        );
        // A tap in the margin, outside the visual, still activates.
        final corner = tester.getTopLeft(find.byKey(const Key('p')));
        await tester.tapAt(corner + const Offset(1, 1));
        expect(taps, 1);
      });
    }

    testWidgets('0 opts out', (tester) async {
      await pumpTiny(tester, minTapTarget: 0);
      expect(tester.getSize(find.byKey(const Key('p'))), const Size(12, 12));
    });

    testWidgets('taps inside the visual land where the pointer is', (
      tester,
    ) async {
      final hits = <Offset>[];
      await tester.pumpWidget(
        host(
          theme: DsThemeData(density: DsDensity.touch),
          DsPressable(
            onPressed: () {},
            builder: (_, _, _) => Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => hits.add(e.localPosition),
              child: const SizedBox(key: Key('visual'), width: 30, height: 30),
            ),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byKey(const Key('visual')));
      await tester.tapAt(topLeft + const Offset(3, 4));
      expect(hits.single, const Offset(3, 4));
    });

    testWidgets('an unlabeled checkbox meets the target', (tester) async {
      await tester.pumpWidget(
        host(
          theme: DsThemeData(density: DsDensity.touch),
          DsCheckbox(value: false, onChanged: (_) {}),
        ),
      );
      final size = tester.getSize(find.byType(DsCheckbox));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  // eng L6: phones start without visible focus (no keyboard yet); desktop
  // starts with it, as a browser does.
  test('focus visibility starts by platform', () {
    expect(focusVisibleInitially(TargetPlatform.iOS), isFalse);
    expect(focusVisibleInitially(TargetPlatform.android), isFalse);
    expect(focusVisibleInitially(TargetPlatform.macOS), isTrue);
    expect(focusVisibleInitially(TargetPlatform.windows), isTrue);
    expect(focusVisibleInitially(TargetPlatform.linux), isTrue);
  });

  group('state contract', () {
    testWidgets('selected going back to null clears the state (eng L1)', (
      tester,
    ) async {
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      Widget tree(bool? selected) => host(
        DsPressable(
          onPressed: () {},
          selected: selected,
          statesController: states,
          builder: (_, _, _) => const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pumpWidget(tree(true));
      expect(states.value, contains(WidgetState.selected));
      await tester.pumpWidget(tree(null));
      expect(states.value, isNot(contains(WidgetState.selected)));
    });

    testWidgets('a long-press-only pressable is enabled (eng L2)', (
      tester,
    ) async {
      var long = 0;
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      await tester.pumpWidget(
        host(
          DsPressable(
            onPressed: null,
            onLongPress: () => long++,
            statesController: states,
            builder: (_, _, _) => const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      expect(states.value, isNot(contains(WidgetState.disabled)));
      await tester.longPress(find.byType(DsPressable));
      expect(long, 1);
      // A tap does nothing and does not throw.
      await tester.tap(find.byType(DsPressable));
    });

    testWidgets('busy keeps focus, ignores presses and says loading', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var taps = 0;
      Widget tree(bool busy) => host(
        DsPressable(
          focusNode: node,
          busy: busy,
          onPressed: () => taps++,
          builder: (_, _, _) => const SizedBox(width: 40, height: 40),
        ),
      );
      await tester.pumpWidget(tree(false));
      node.requestFocus();
      await tester.pump();
      await tester.pumpWidget(tree(true));
      expect(node.hasFocus, isTrue, reason: 'focus survives busy (B16)');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.byType(DsPressable));
      expect(taps, 0);
      final data = tester
          .getSemantics(find.byType(DsPressable))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.value, 'Loading');
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      await tester.pumpWidget(tree(false));
      expect(node.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  });
}
