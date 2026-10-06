import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Three focus looks, by what the control is:
/// - text-like fields (text, search, number, time, select) show focus as
///   one line, their edge turned 2px in the focus color, with no ring;
/// - bordered, unfilled controls (secondary button, unselected chip) get
///   the tight ring, a 2px line on the edge that covers their border;
/// - filled controls (primary and danger buttons, selected chip, checked
///   checkbox and radio, switch) keep the gapped ring, which reads against
///   their fill.
void main() {
  final theme = DsThemeData();
  final k = theme.colors;

  Widget app(Widget child, {DsThemeData? data}) => DsApp(
    theme: data ?? theme,
    themeMode: DsThemeMode.light,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );

  /// The first decorated box under [of]: the control's well or visual.
  AnimatedContainer box(WidgetTester tester, Type of) =>
      tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(of),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
  DsBoxDecoration deco(WidgetTester tester, Type of) =>
      box(tester, of).decoration! as DsBoxDecoration;
  List<DsShadow> foreground(WidgetTester tester, Type of) =>
      (box(tester, of).foregroundDecoration as DsBoxDecoration?)?.shadows ??
      const [];

  /// The painted inner edge: the crisp inset ring.
  DsShadow? edge(DsBoxDecoration d) =>
      d.shadows.where((x) => x.inset && x.color.a > 0).firstOrNull;

  /// Focuses [node] as from the keyboard.
  Future<void> keyboardFocus(WidgetTester tester, FocusNode node) async {
    useTraditionalHighlights();
    node.requestFocus();
    // Any key marks keyboard modality (DsFocusVisibility).
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
  }

  group('text-like fields: one 2px focus line, no ring', () {
    void expectFocusLine(DsBoxDecoration d, List<DsShadow> fg) {
      final e = edge(d)!;
      expect(e.color, k.focus);
      expect(e.spread, 2);
      // Nothing else circles the field: no outline, no outer ring.
      expect(d.shadows.where((x) => x.isOutline), isEmpty);
      expect(fg, isEmpty);
    }

    final fields = <String, (Widget Function(FocusNode), Type)>{
      'text field': ((n) => DsTextField(focusNode: n), DsTextField),
      'search field': ((n) => DsSearchField(focusNode: n), DsTextField),
      'number field': (
        (n) => DsNumberField(value: 3, focusNode: n, onChanged: (_) {}),
        DsTextField,
      ),
      'time field': (
        (n) => DsTimePicker(
          value: const DsTime(9, 30),
          focusNode: n,
          onChanged: (_) {},
        ),
        DsTextField,
      ),
      'select': (
        (n) => DsSelect<int>(
          value: 1,
          focusNode: n,
          options: const [DsSelectOption(value: 1, label: 'Bir')],
          onChanged: (_) {},
        ),
        DsSelect<int>,
      ),
    };
    for (final MapEntry(key: name, value: (build, type)) in fields.entries) {
      testWidgets('$name, keyboard focus', (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(app(build(node)));
        expect(edge(deco(tester, type))!.spread, 1);
        await keyboardFocus(tester, node);
        expectFocusLine(deco(tester, type), foreground(tester, type));
      });
    }

    testWidgets('a focused field with an error shows focus; the icon keeps '
        'the error', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsField(
            errorText: 'Geçersiz.',
            child: DsTextField(focusNode: node, initialValue: 'x'),
          ),
        ),
      );
      final danger = edge(deco(tester, DsTextField))!.color;
      expect(danger, isNot(k.focus));
      await keyboardFocus(tester, node);
      expectFocusLine(
        deco(tester, DsTextField),
        foreground(tester, DsTextField),
      );
      final icon = tester.widget<DsIcon>(
        find.descendant(
          of: find.byType(DsTextField),
          matching: find.byWidgetPredicate(
            (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
          ),
        ),
      );
      expect(icon.color, danger);
    });

    for (final (name, build, type) in [
      ('text field', (FocusNode n) => DsTextField(focusNode: n), DsTextField),
      (
        'select',
        (FocusNode n) => DsSelect<int>(
          value: 1,
          focusNode: n,
          options: const [DsSelectOption(value: 1, label: 'Bir')],
          onChanged: (_) {},
        ),
        DsSelect<int>,
      ),
    ]) {
      testWidgets('hover on a focused $name keeps the focus line', (
        tester,
      ) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(app(build(node)));
        await keyboardFocus(tester, node);
        await hover(tester, find.byType(type));
        await tester.pumpAndSettle();
        final e = edge(deco(tester, type))!;
        expect(e.color, k.focus);
        expect(e.spread, 2);
      });
    }
  });

  group('bordered, unfilled controls: the tight ring', () {
    test('the tight ring is a 2px focus line centered on the edge', () {
      for (final contrast in DsContrast.values) {
        for (final brightness in Brightness.values) {
          final t = DsThemeData(contrast: contrast, brightness: brightness);
          final ring = t.shadows.focusTight.single;
          expect(ring.color, t.colors.focus);
          expect(ring.isOutline, isTrue);
          expect(ring.spread, 2);
          // From 1px inside the box to 1px outside: it covers a 1px border
          // drawn on either side of the edge, with no gap.
          expect(ring.gap, -1);
        }
      }
    });

    testWidgets('secondary button', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsButton(
            variant: DsButtonVariant.secondary,
            focusNode: node,
            onPressed: () {},
            child: const Text('Vazgeç'),
          ),
        ),
      );
      expect(foreground(tester, DsButton), isEmpty);
      await keyboardFocus(tester, node);
      expect(foreground(tester, DsButton), theme.shadows.focusTight);
      // The border stays underneath; the ring covers it.
      expect(deco(tester, DsButton).shadows.first.color, k.borderControl);
    });

    testWidgets('unselected chip', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsChip(
            label: const Text('Çip'),
            selected: false,
            focusNode: node,
            onChanged: (_) {},
          ),
        ),
      );
      await keyboardFocus(tester, node);
      expect(foreground(tester, DsChip), theme.shadows.focusTight);
    });
  });

  group('filled controls: the gapped ring', () {
    for (final variant in [DsButtonVariant.primary, DsButtonVariant.danger]) {
      testWidgets('${variant.name} button', (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          app(
            DsButton(
              variant: variant,
              focusNode: node,
              onPressed: () {},
              child: const Text('Kaydet'),
            ),
          ),
        );
        await keyboardFocus(tester, node);
        expect(foreground(tester, DsButton), theme.shadows.focusOffset);
        expect(theme.shadows.focusOffset.single.gap, greaterThan(0));
      });
    }

    testWidgets('selected chip', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsChip(
            label: const Text('Çip'),
            selected: true,
            focusNode: node,
            onChanged: (_) {},
          ),
        ),
      );
      await keyboardFocus(tester, node);
      expect(foreground(tester, DsChip), theme.shadows.focusOffset);
    });

    test('checkbox, radio and switch', () {
      const on = {WidgetState.focused, WidgetState.selected};
      expect(
        DsCheckboxStyle.resolveLayers([
          DsCheckbox.defaultStyle(theme),
        ], on).focusShadows,
        theme.shadows.focusOffset,
      );
      expect(
        DsRadioStyle.resolveLayers([
          DsRadio.defaultStyle(theme),
        ], on).focusShadows,
        theme.shadows.focusOffset,
      );
      expect(
        DsSwitchStyle.resolveLayers([
          DsSwitch.defaultStyle(theme),
        ], on).focusShadows,
        theme.shadows.focusOffset,
      );
    });
  });

  group('the focusTight token', () {
    test('follows focusOffset unless set', () {
      final s = theme.shadows;
      const red = Color(0xFFFF0000);
      final moved = s.copyWith(
        focusOffset: const [DsShadow.outline(red, width: 3, gap: 1)],
      );
      expect(moved.focusTight, const [
        DsShadow.outline(red, width: 3, gap: -1.5),
      ]);
      const own = [DsShadow.innerRing(red, width: 2)];
      final set = s.copyWith(focusTight: own);
      expect(set.focusTight, own);
      expect(set.copyWith(focusOffset: const []).focusTight, own);
      expect(set == s, isFalse);
      expect(set.hashCode == s.hashCode, isFalse);
    });

    testWidgets('a theme can restyle it', (tester) async {
      final own = [DsShadow.innerRing(k.focus, width: 2)];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsButton(
            variant: DsButtonVariant.secondary,
            focusNode: node,
            onPressed: () {},
            child: const Text('Vazgeç'),
          ),
          data: DsThemeData(
            adjustShadows: (s, k, b) => s.copyWith(focusTight: own),
          ),
        ),
      );
      await keyboardFocus(tester, node);
      expect(foreground(tester, DsButton), own);
    });
  });
}
