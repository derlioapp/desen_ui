import 'dart:ui' show CheckedState, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 5b: selection controls (KALITE §3 B–H) and the generalized style
/// model (§4, K-05).
void main() {
  final light = DsThemeData();

  Future<void> focusAndKey(
    WidgetTester tester,
    Finder target,
    LogicalKeyboardKey key,
  ) async {
    Focus.of(tester.element(target)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  group('DsCheckbox', () {
    testWidgets('label tap toggles; Space toggles; semantics checked', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsCheckbox(
              value: value,
              onChanged: (v) => set(() => value = v!),
              label: const Text('Haftalık özet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Haftalık özet'));
      await tester.pump();
      expect(value, isTrue);
      expect(
        tester.getSemantics(find.byType(DsCheckbox)),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          label: 'Haftalık özet',
        ),
      );
      await focusAndKey(
        tester,
        find.text('Haftalık özet'),
        LogicalKeyboardKey.space,
      );
      expect(value, isFalse);
      semantics.dispose();
    });

    testWidgets('tristate cycles false → true → null → false', (tester) async {
      bool? value = false;
      final seen = <bool?>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsCheckbox(
              tristate: true,
              value: value,
              onChanged: (v) => set(() {
                value = v;
                seen.add(v);
              }),
            ),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(DsCheckbox));
        await tester.pump();
      }
      expect(seen, [true, null, false]);
    });

    testWidgets('disabled does not toggle and shows disabled colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const DsCheckbox(value: false, onChanged: null), theme: light),
      );
      await tester.tap(find.byType(DsCheckbox), warnIfMissed: false);
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((box.decoration! as DsBoxDecoration).color, light.colors.disabled);
    });

    testWidgets('error shows the error outline', (tester) async {
      await tester.pumpWidget(
        host(
          DsCheckbox(value: false, error: true, onChanged: (_) {}),
          theme: light,
        ),
      );
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (box.decoration! as DsBoxDecoration).shadows.first,
        DsShadow.innerRing(light.shadows.fieldError.first.color, width: 2),
      );
    });
  });

  group('DsRadio', () {
    testWidgets('selecting by label and arrow keys moving the selection', (
      tester,
    ) async {
      String? value = 'a';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsRadioGroup<String>(
              value: value,
              onChanged: (v) => set(() => value = v),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRadio(value: 'a', label: Text('A')),
                  DsRadio(value: 'b', label: Text('B')),
                  DsRadio(value: 'c', label: Text('C')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(value, 'b');
      await focusAndKey(tester, find.text('B'), LogicalKeyboardKey.arrowDown);
      expect(value, 'c');
    });

    testWidgets('works without Localizations on macOS (R3)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        host(
          DsRadioGroup<int>(
            value: 1,
            onChanged: (_) {},
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsRadio(value: 1, label: Text('Bir')),
                DsRadio(value: 2, label: Text('İki')),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('radios announce a mutually exclusive group', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsRadioGroup<int>(
            value: 1,
            onChanged: (_) {},
            child: const DsRadio(value: 1, label: Text('Bir')),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsRadio<int>)),
        isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
      );
      semantics.dispose();
    });
  });

  group('DsSwitch', () {
    testWidgets('row tap toggles and announces toggled', (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, set) => DsSwitch(
                value: on,
                onChanged: (v) => set(() => on = v),
                label: const Text('Odak modu'),
                description: const Text('Sessiz'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sessiz'));
      await tester.pump();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(DsSwitch)),
        isSemantics(hasToggledState: true, isToggled: true),
      );
      semantics.dispose();
    });

    testWidgets('off track is the 3:1 rail, on track the accent', (
      tester,
    ) async {
      Color track() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as DsBoxDecoration)
              .color!;
      await tester.pumpWidget(
        host(DsSwitch(value: false, onChanged: (_) {}), theme: light),
      );
      expect(track(), light.colors.rail);
      await tester.pumpWidget(
        host(DsSwitch(value: true, onChanged: (_) {}), theme: light),
      );
      expect(track(), light.colors.accent);
    });
  });

  group('DsChip', () {
    testWidgets('toggles and announces checked', (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsChip(
              label: const Text('Tasarım'),
              selected: on,
              onChanged: (v) => set(() => on = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsChip));
      await tester.pump();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(DsChip)),
        isSemantics(hasCheckedState: true, isChecked: true, label: 'Tasarım'),
      );
      semantics.dispose();
    });

    testWidgets('a checkbox, not a selected button (the web reads that as '
        'the current item)', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final on in [false, true]) {
        await tester.pumpWidget(
          host(
            DsChip(
              label: const Text('Tasarım'),
              selected: on,
              onChanged: (_) {},
            ),
          ),
        );
        final flags = tester
            .getSemantics(find.byType(DsChip))
            .getSemanticsData()
            .flagsCollection;
        expect(
          flags.isChecked,
          on ? CheckedState.isTrue : CheckedState.isFalse,
        );
        expect(flags.isSelected, Tristate.none);
        expect(flags.isButton, isFalse);
        expect(flags.isToggled, Tristate.none);
      }
      semantics.dispose();
    });
  });

  group('focus visibility (CSS :focus-visible)', () {
    setUp(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
    tearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('a click neither takes focus nor shows it', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var value = 'g';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => DsSegmentedControl<String>(
              focusNode: node,
              value: value,
              onChanged: (v) => set(() => value = v),
              segments: const [
                DsSegment(value: 'g', label: Text('Gün')),
                DsSegment(value: 'y', label: Text('Yıl')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Yıl'));
      await tester.pumpAndSettle();
      expect(value, 'y');
      expect(node.hasFocus, isFalse);
    });

    testWidgets('focus after a click stays hidden until a key is pressed', (
      tester,
    ) async {
      final states = WidgetStatesController();
      final node = FocusNode();
      addTearDown(states.dispose);
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsCheckbox(
                value: false,
                focusNode: node,
                statesController: states,
                onChanged: (_) {},
              ),
              DsCheckbox(value: false, onChanged: (_) {}),
            ],
          ),
        ),
      );
      // Focus placed after a mouse click (e.g. by app code) stays hidden.
      await tester.tap(find.byType(DsCheckbox).last);
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(states.value, isNot(contains(WidgetState.focused)));
      // Any key brings it back, as in a browser.
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        states.value,
        isNot(contains(WidgetState.focused)),
        reason: 'a lone modifier does not count',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(states.value, contains(WidgetState.focused));
    });
  });

  group('DsSegmentedControl', () {
    Widget control(String value, ValueChanged<String> onChanged) =>
        DsSegmentedControl<String>(
          value: value,
          onChanged: onChanged,
          semanticLabel: 'Aralık',
          segments: const [
            DsSegment(value: 'g', label: Text('Gün')),
            DsSegment(value: 'h', label: Text('Hafta')),
            DsSegment(value: 'a', label: Text('Ay'), enabled: false),
            DsSegment(value: 'y', label: Text('Yıl')),
          ],
        );

    testWidgets('the spring never pushes the thumb past the track ends', (
      tester,
    ) async {
      Future<void> check(String value) async {
        await tester.pumpWidget(host(control(value, (_) {})));
        final track = tester.getRect(find.byType(DsSegmentedControl<String>));
        // The track's box, then the thumb's.
        final thumb = find
            .descendant(
              of: find.byType(DsSegmentedControl<String>),
              matching: find.byType(DecoratedBox),
            )
            .at(1);
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          final r = tester.getRect(thumb);
          expect(r.left, greaterThanOrEqualTo(track.left + 3 - .01));
          expect(r.right, lessThanOrEqualTo(track.right - 3 + .01));
        }
      }

      await check('g');
      await check('y'); // animates to the last segment
      await check('g'); // and back to the first
    });

    testWidgets('keyboard focus outlines the thumb and leaves the track', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          DsSegmentedControl<String>(
            focusNode: node,
            value: 'g',
            onChanged: (_) {},
            segments: const [
              DsSegment(value: 'g', label: Text('Gün')),
              DsSegment(value: 'h', label: Text('Hafta')),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      final [track, thumb, ...] = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(DsSegmentedControl<String>),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<DsBoxDecoration>()
          .toList();
      expect(track.color, theme.colors.channel);
      expect(thumb.shadows, containsAll(theme.shadows.focusOffset));
    });

    testWidgets('tap, arrows (skipping disabled), Home and End', (
      tester,
    ) async {
      var value = 'g';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => control(value, (v) => set(() => value = v)),
          ),
        ),
      );
      await tester.tap(find.text('Hafta'));
      await tester.pump();
      expect(value, 'h');
      // A click selects but does not take focus (as in Safari and macOS);
      // the keyboard reaches the control with Tab.
      focusInside(tester, find.byType(DsSegmentedControl<String>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 'y', reason: 'Ay is disabled and skipped');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 'g');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 'y');
    });

    testWidgets('arrows mirror in RTL', (tester) async {
      var value = 'h';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (c, set) => control(value, (v) => set(() => value = v)),
          ),
          direction: TextDirection.rtl,
        ),
      );
      focusInside(tester, find.byType(DsSegmentedControl<String>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 'y', reason: 'left moves forward in RTL');
    });

    testWidgets('segments share the widest width', (tester) async {
      await tester.pumpWidget(host(control('g', (_) {})));
      final widths = [
        for (final l in ['Gün', 'Hafta', 'Yıl'])
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text(l),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .width,
      ];
      expect(widths.toSet().length, 1);
    });

    testWidgets('announces a radio group with a checked segment', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(control('h', (_) {})));
      expect(
        tester.getSemantics(find.text('Hafta')),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          isChecked: true,
          label: 'Hafta',
        ),
      );
      semantics.dispose();
    });
  });

  group('DsSlider', () {
    testWidgets('keyboard steps by division, Home/End, RTL mirrors', (
      tester,
    ) async {
      double value = 2;
      Widget slider(TextDirection d) => host(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (c, set) => DsSlider(
              value: value,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
        direction: d,
      );
      await tester.pumpWidget(slider(TextDirection.ltr));
      focusInside(tester, find.byType(DsSlider));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(value, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(value, 4);
      await tester.pumpWidget(slider(TextDirection.rtl));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 3, reason: 'right decreases in RTL');
    });

    testWidgets('dragging and tapping set the value', (tester) async {
      double value = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 220,
            child: StatefulBuilder(
              builder: (c, set) => DsSlider(
                value: value,
                onChanged: (v) => set(() => value = v),
              ),
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(DsSlider));
      await tester.tapAt(Offset(box.right - 10, box.center.dy));
      await tester.pump();
      expect(value, closeTo(1, 0.01));
      await tester.dragFrom(
        Offset(box.right - 10, box.center.dy),
        const Offset(-100, 0),
      );
      await tester.pump();
      expect(value, closeTo(0.5, 0.02));
    });

    testWidgets('screen readers get value and increase/decrease', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      double value = .5;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: StatefulBuilder(
              builder: (c, set) => DsSlider(
                value: value,
                semanticLabel: 'Ses',
                onChanged: (v) => set(() => value = v),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsSlider)),
        isSemantics(
          isSlider: true,
          label: 'Ses',
          value: '50%',
          hasIncreaseAction: true,
        ),
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Ses'),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(value, closeTo(.51, .001));
      semantics.dispose();
    });
  });

  group('style model (K-05) across components', () {
    test('structural styles resolve nested states: selected+hovered wins', () {
      const plainHover = Color(0xFF111111), selectedHover = Color(0xFF222222);
      const s = DsCheckboxStyle(
        hovered: DsCheckboxStyle(background: plainHover),
        selected: DsCheckboxStyle(
          hovered: DsCheckboxStyle(background: selectedHover),
        ),
      );
      expect(s.resolve({WidgetState.hovered}).background, plainHover);
      expect(
        s.resolve({WidgetState.hovered, WidgetState.selected}).background,
        selectedHover,
      );
    });

    testWidgets(
      'Ö2/Ö3: global defaults and a merged subtree via DsComponentThemes',
      (tester) async {
        await tester.pumpWidget(
          host(
            DsComponentThemes(
              themes: const [
                DsChipThemeData(style: DsChipStyle(height: 40)),
                DsCardThemeData(style: DsCardStyle(padding: EdgeInsets.all(4))),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsChip(
                    label: const Text('a'),
                    selected: false,
                    onChanged: (_) {},
                  ),
                  DsChipTheme(
                    data: const DsChipThemeData(
                      style: DsChipStyle(borderColor: Color(0xFF00AA00)),
                    ),
                    child: DsChip(
                      label: const Text('b'),
                      selected: false,
                      onChanged: (_) {},
                    ),
                  ),
                  const DsCard(child: SizedBox(width: 10, height: 10)),
                ],
              ),
            ),
            theme: light,
          ),
        );
        double chipHeight(int i) => tester
            .getSize(
              find.descendant(
                of: find.byType(DsChip).at(i),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .height;
        expect(chipHeight(0), 40);
        expect(chipHeight(1), 40, reason: 'inner theme kept the outer height');
        final inner =
            tester
                    .widget<AnimatedContainer>(
                      find.descendant(
                        of: find.byType(DsChip).at(1),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .decoration!
                as DsBoxDecoration;
        expect(
          inner.shadows.first,
          const DsShadow.innerRing(Color(0xFF00AA00)),
        );
        expect(
          tester.getSize(find.byType(DsCard)),
          const Size(18, 18),
          reason: '10 + 2×4',
        );
      },
    );

    testWidgets('Ö1: badge and alert take a per-instance style', (
      tester,
    ) async {
      const brand = Color(0xFF5500AA);
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBadge(
                label: Text('x'),
                style: DsBadgeStyle(background: brand),
              ),
              SizedBox(
                width: 200,
                child: DsAlert(
                  title: Text('y'),
                  style: DsAlertStyle(background: brand),
                ),
              ),
            ],
          ),
          theme: light,
        ),
      );
      final colors = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<DsBoxDecoration>()
          .map((d) => d.color)
          .toList();
      expect(colors.where((c) => c == brand).length, 2);
    });

    testWidgets('a theme variant per status applies only to that status', (
      tester,
    ) async {
      const special = Color(0xFFAA5500);
      await tester.pumpWidget(
        host(
          const DsBadgeTheme(
            data: DsBadgeThemeData(
              statuses: {DsStatus.warning: DsBadgeStyle(background: special)},
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsBadge(status: .warning, label: Text('w')),
                DsBadge(status: .info, label: Text('i')),
              ],
            ),
          ),
          theme: light,
        ),
      );
      Color? bg(int i) =>
          (tester
                      .widget<Container>(
                        find
                            .descendant(
                              of: find.byType(DsBadge).at(i),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as DsBoxDecoration)
              .color;
      expect(bg(0), special);
      expect(bg(1), light.colors.info.tint);
    });
  });

  testWidgets('selection controls work without a scope and at 2x text (R3)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              children: [
                DsCheckbox(
                  value: true,
                  onChanged: (_) {},
                  label: const Text('Onay'),
                ),
                DsRadioGroup<int>(
                  value: 1,
                  onChanged: (_) {},
                  child: const DsRadio(value: 1, label: Text('Radyo')),
                ),
                DsSwitch(
                  value: true,
                  onChanged: (_) {},
                  label: const Text('Anahtar'),
                ),
                DsChip(
                  label: const Text('Çip'),
                  selected: true,
                  onChanged: (_) {},
                ),
                DsSegmentedControl<int>(
                  value: 1,
                  onChanged: (_) {},
                  segments: const [
                    DsSegment(value: 1, label: Text('Bir')),
                    DsSegment(value: 2, label: Text('İki')),
                  ],
                ),
                DsSlider(value: .3, onChanged: (_) {}),
              ],
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}

/// Focuses the control found by [control], as Tab would in an app (the
/// minimal test host has no Tab shortcut).
void focusInside(WidgetTester tester, Finder control) => Focus.of(
  tester.element(
    find.descendant(of: control, matching: find.byType(GestureDetector)).first,
  ),
).requestFocus();
