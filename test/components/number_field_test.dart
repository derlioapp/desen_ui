import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsNumberField (concept card 39): typing and parsing per locale, commit
/// on blur and Enter, the WAI-ARIA spinbutton keys, the buttons with press
/// and hold, semantics, DsField, RTL and large text.
void main() {
  /// A number field holding its own value; [values] records every report.
  Widget numberApp({
    num? initial,
    num? min,
    num? max,
    num step = 1,
    DsNumberFormat format = const DsNumberFormat(),
    String? unit,
    String? prefix,
    Locale locale = const Locale('en'),
    List<num?>? values,
    bool readOnly = false,
    bool enabled = true,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    double width = 240,
    DsThemeData? theme,
    Widget Function(Widget field)? wrap,
    FocusNode? focusNode,
  }) {
    var value = initial;
    return DsApp(
      theme: theme ?? DsThemeData(platform: TargetPlatform.macOS),
      themeMode: DsThemeMode.light,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Center(
        child: SizedBox(
          width: width,
          child: StatefulBuilder(
            builder: (context, setState) {
              final field = DsNumberField(
                value: value,
                min: min,
                max: max,
                step: step,
                format: format,
                unit: unit,
                prefix: prefix,
                readOnly: readOnly,
                focusNode: focusNode,
                semanticLabel: 'Amount',
                onChanged: enabled
                    ? (v) => setState(() {
                        value = v;
                        values?.add(v);
                      })
                    : null,
              );
              return wrap == null ? field : wrap(field);
            },
          ),
        ),
      ),
    );
  }

  Finder editableFinder() => find.byType(EditableText);
  String text(WidgetTester tester) =>
      tester.widget<EditableText>(editableFinder()).controller.text;

  Future<void> focus(WidgetTester tester) async {
    await tester.tap(editableFinder());
    await tester.pump();
  }

  Future<void> blur(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  Finder minus() =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.minus);
  Finder plus() =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.plus);

  group('format', () {
    test('formats and parses with the locale separators', () {
      final tr = const DsNumberFormat(
        decimals: 2,
        grouping: true,
      ).forLocale(const Locale('tr'));
      expect(tr.format(12500.5), '12.500,50');
      expect(tr.format(-0.001), '0,00');
      expect(tr.format(-1234567), '-1.234.567,00');
      expect(tr.tryParse('12.500,5'), 12500.5);
      expect(tr.tryParse('-'), isNull);
      expect(tr.tryParse(','), isNull);
      expect(tr.tryParse(''), isNull);
      final en = const DsNumberFormat(decimals: 1)
          .forLocale(const Locale('en'));
      expect(en.format(72.25), anyOf('72.3', '72.2'));
      expect(en.tryParse('72.5'), 72.5);
      expect(en.tryParse('٧٢'), 72, reason: 'Arabic-Indic digits');
      expect(en.tryParse('−5'), -5, reason: 'minus sign');
      final fr = const DsNumberFormat(grouping: true)
          .forLocale(const Locale('fr'));
      expect(fr.format(12500), '12 500');
      expect(fr.tryParse('12 500'), 12500);
    });

    test('separators by locale and region', () {
      expect(dsNumberSeparators(const Locale('tr')), (',', '.'));
      expect(dsNumberSeparators(const Locale('de')), (',', '.'));
      expect(dsNumberSeparators(const Locale('de', 'CH')).$1, '.');
      expect(dsNumberSeparators(const Locale('en')), ('.', ','));
      expect(dsNumberSeparators(const Locale('es', 'MX')).$1, '.');
      expect(dsNumberSeparators(const Locale('ja')), ('.', ','));
      expect(dsNumberSeparators(const Locale('ru')).$1, ',');
    });
  });

  group('typing', () {
    testWidgets('Turkish takes "," and turns a typed "." into it', (
      tester,
    ) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(
          locale: const Locale('tr'),
          format: const DsNumberFormat(decimals: 2),
          values: values,
        ),
      );
      await focus(tester);
      await tester.enterText(editableFinder(), '12,5');
      expect(values.last, 12.5);
      await tester.enterText(editableFinder(), '7.25');
      expect(text(tester), '7,25');
      expect(values.last, 7.25);
      await blur(tester);
      expect(text(tester), '7,25');
    });

    testWidgets('German with grouping: "." groups, "," is the decimal', (
      tester,
    ) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(
          locale: const Locale('de'),
          format: const DsNumberFormat(decimals: 2, grouping: true),
          values: values,
        ),
      );
      await focus(tester);
      await tester.enterText(editableFinder(), '1.234,5');
      expect(values.last, 1234.5);
      await blur(tester);
      expect(text(tester), '1.234,50');
    });

    testWidgets('English takes "." and reformats on blur', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(format: const DsNumberFormat(decimals: 2), values: values),
      );
      await focus(tester);
      await tester.enterText(editableFinder(), '3.5');
      expect(values.last, 3.5);
      expect(text(tester), '3.5');
      await blur(tester);
      expect(text(tester), '3.50');
    });

    testWidgets('letters, a second separator and extra digits are refused', (
      tester,
    ) async {
      await tester.pumpWidget(
        numberApp(initial: 4, format: const DsNumberFormat(decimals: 1)),
      );
      await focus(tester);
      await tester.enterText(editableFinder(), '4.5');
      await tester.enterText(editableFinder(), '4.5a');
      expect(text(tester), '4.5');
      await tester.enterText(editableFinder(), '4.5.');
      expect(text(tester), '4.5');
      await tester.enterText(editableFinder(), '4.55');
      expect(text(tester), '4.5', reason: 'one fraction digit');
    });

    testWidgets('a minus only when min allows negatives', (tester) async {
      await tester.pumpWidget(numberApp(min: 0));
      await focus(tester);
      await tester.enterText(editableFinder(), '-3');
      expect(text(tester), '');
      await tester.pumpWidget(Container());
      await tester.pumpWidget(numberApp(min: -10));
      await focus(tester);
      await tester.enterText(editableFinder(), '-3');
      expect(text(tester), '-3');
    });

    testWidgets('whole numbers are reported as int', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(values: values));
      await focus(tester);
      await tester.enterText(editableFinder(), '42');
      expect(values.last, isA<int>());
      expect(values.last, 42);
    });

    testWidgets('blur clamps to the range and reports it', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(min: 1, max: 100, values: values));
      await focus(tester);
      await tester.enterText(editableFinder(), '250');
      // Out of range while typing: no number yet.
      expect(values, isEmpty);
      await blur(tester);
      expect(text(tester), '100');
      expect(values.last, 100);
    });

    testWidgets('Enter commits and keeps focus on desktop', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(
          max: 10,
          format: const DsNumberFormat(decimals: 1),
          values: values,
        ),
      );
      await focus(tester);
      await tester.enterText(editableFinder(), '12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(text(tester), '10.0');
      expect(values.last, 10.0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('not a number: kept with the error look, value null', (
      tester,
    ) async {
      final values = <num?>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(numberApp(initial: 5, min: -10, values: values));
      await focus(tester);
      await tester.enterText(editableFinder(), '-');
      await blur(tester);
      expect(text(tester), '-');
      expect(values.last, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
        ),
        findsOneWidget,
      );
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      // Typing again clears the error.
      await focus(tester);
      await tester.enterText(editableFinder(), '-4');
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
        ),
        findsNothing,
      );
      expect(values.last, -4);
      handle.dispose();
    });

    testWidgets('over max while typing shows the error at once', (
      tester,
    ) async {
      await tester.pumpWidget(numberApp(min: 10, max: 50));
      await focus(tester);
      // Under min but more digits can reach it: no error yet.
      await tester.enterText(editableFinder(), '5');
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
        ),
        findsNothing,
      );
      await tester.enterText(editableFinder(), '500');
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
        ),
        findsOneWidget,
      );
    });

    testWidgets('an outside value replaces the text', (tester) async {
      Widget build(num? v) => host(DsNumberField(value: v, onChanged: (_) {}));
      await tester.pumpWidget(build(3));
      expect(text(tester), '3');
      await tester.pumpWidget(build(9));
      expect(text(tester), '9');
      await tester.pumpWidget(build(null));
      expect(text(tester), '');
    });
  });

  group('keyboard', () {
    testWidgets('Up, Down, Page Up, Page Down, Home and End', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(initial: 50, min: 0, max: 100, values: values),
      );
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, 51);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(values.last, 49);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      expect(values.last, 59);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      expect(values.last, 49);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(values.last, 100);
      expect(text(tester), '100');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, 100, reason: 'clamped at max');
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      expect(values.last, 100);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(values.last, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(values.last, 0, reason: 'clamped at min');
      expect(text(tester), '0');
    });

    testWidgets('steps land on the grid; decimals stay clean', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(initial: 7, min: 0, step: 5, values: values),
      );
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, 10);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(values.last, 5);
      await tester.pumpWidget(Container());
      values.clear();
      await tester.pumpWidget(
        numberApp(
          initial: 0.2,
          step: 0.1,
          format: const DsNumberFormat(decimals: 1),
          values: values,
        ),
      );
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, 0.3);
      expect(text(tester), '0.3');
    });

    testWidgets('Home and End move the caret without a range', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(initial: 1234, values: values));
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(values, isEmpty);
    });

    testWidgets('an empty field steps to the value nearest 0', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(min: 3, max: 9, values: values));
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, 3);
    });

    testWidgets('the field is the one Tab stop; buttons take no focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        numberApp(
          initial: 1,
          focusNode: node,
          wrap: (field) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field,
              DsButton(onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<DsButton>(),
        isNotNull,
      );
      // A click on a button steps without moving focus.
      await tester.tap(plus());
      await tester.pump();
      expect(text(tester), '2');
      expect(node.hasFocus, isFalse);
    });

    testWidgets('read-only: no stepping, no step buttons', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(initial: 5, max: 9, readOnly: true, values: values),
      );
      await focus(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      // The step buttons edit the value, so a read-only field has none.
      expect(plus(), findsNothing);
      expect(minus(), findsNothing);
      expect(values, isEmpty);
      expect(text(tester), '5');
    });
  });

  group('buttons', () {
    testWidgets('a tap steps once; at a limit the button is inactive', (
      tester,
    ) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(initial: 8, max: 9, values: values));
      await tester.tap(plus());
      await tester.pump();
      expect(values, [9]);
      await tester.tap(plus());
      await tester.pump();
      expect(values, [9]);
      await tester.tap(minus());
      await tester.pump();
      expect(values, [9, 8]);
    });

    testWidgets('press and hold repeats, faster over time, and stops', (
      tester,
    ) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(initial: 0, values: values));
      final gesture = await tester.startGesture(tester.getCenter(plus()));
      await tester.pump();
      expect(values, [1], reason: 'steps on press');
      await tester.pump(const Duration(milliseconds: 400));
      expect(values.length, 1, reason: 'waits before repeating');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final afterFirstRepeats = values.length;
      expect(afterFirstRepeats, greaterThan(1));
      // Later, a second covers more steps than the first did.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final mid = values.length;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(values.length - mid, greaterThan(mid - afterFirstRepeats));
      await gesture.up();
      await tester.pump();
      final released = values.length;
      await tester.pump(const Duration(seconds: 1));
      expect(values.length, released, reason: 'stops on release');
      // Counting up from 0 by one each time.
      expect(values.last, released);
    });

    testWidgets('holding stops at the limit', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(numberApp(initial: 0, max: 3, values: values));
      final gesture = await tester.startGesture(tester.getCenter(plus()));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pump();
      expect(values, [1, 2, 3]);
    });

    testWidgets('tap targets meet the minimum and the field does not grow', (
      tester,
    ) async {
      await tester.pumpWidget(numberApp(initial: 1));
      final field = tester.getSize(find.byType(DsTextField));
      expect(field.height, 40);
      for (final f in [minus(), plus()]) {
        final box = find.ancestor(of: f, matching: find.byType(DsPressable));
        final size = tester.getSize(box);
        expect(size.width, greaterThanOrEqualTo(24));
        expect(size.height, greaterThanOrEqualTo(24));
      }
      await tester.pumpWidget(Container());
      await tester.pumpWidget(
        numberApp(initial: 1, theme: DsThemeData(platform: TargetPlatform.iOS)),
      );
      final touch = tester.getSize(
        find.ancestor(of: plus(), matching: find.byType(DsPressable)),
      );
      expect(touch.width, greaterThanOrEqualTo(44));
      expect(tester.getSize(find.byType(DsTextField)).height, 40);
    });

    testWidgets('RTL mirrors the buttons: plus at the far start edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        numberApp(initial: 1, direction: TextDirection.rtl),
      );
      final field = tester.getRect(find.byType(DsTextField));
      final p = tester.getCenter(plus()).dx;
      final m = tester.getCenter(minus()).dx;
      expect(p, lessThan(m));
      expect(p - field.left, lessThan(field.width / 4));
      final textX = tester.getCenter(editableFinder()).dx;
      expect(textX, greaterThan(m));
    });
  });

  group('semantics', () {
    testWidgets('value with the unit, next and previous values, actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final values = <num?>[];
      await tester.pumpWidget(
        numberApp(initial: 72, min: 0, max: 73, unit: 'kg', values: values),
      );
      var data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.value, '72 kg');
      expect(data.increasedValue, '73 kg');
      expect(data.decreasedValue, '71 kg');
      expect(data.label, contains('Amount'));
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      final node = find.semantics.byValue('72 kg');
      tester.semantics.performAction(node, SemanticsAction.increase);
      await tester.pump();
      expect(values.last, 73);
      data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.value, '73 kg');
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      tester.semantics.performAction(
        find.semantics.byValue('73 kg'),
        SemanticsAction.decrease,
      );
      await tester.pump();
      expect(values.last, 72);
      // The buttons are not separate nodes.
      expect(find.bySemanticsLabel('Increase'), findsNothing);
      handle.dispose();
    });

    testWidgets('a prefix leads the value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(numberApp(initial: 25, prefix: '%'));
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.value, '%25');
      handle.dispose();
    });

    testWidgets('disabled: no actions, not editable', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(numberApp(initial: 3, enabled: false));
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(plus(), warnIfMissed: false);
      await tester.pump();
      expect(text(tester), '3');
      handle.dispose();
    });
  });

  group('DsField', () {
    for (final unit in [null, 'kg']) {
      testWidgets('label, error and required (unit: $unit)', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          numberApp(
            initial: 7,
            unit: unit,
            wrap: (field) => DsField(
              label: const Text('Weight'),
              errorText: 'Too heavy',
              required: true,
              child: field,
            ),
          ),
        );
        final data = tester.getSemantics(editableFinder()).getSemanticsData();
        expect(data.label, contains('Weight'));
        expect(data.value, unit == null ? '7' : '7 kg');
        expect(data.validationResult, SemanticsValidationResult.invalid);
        expect(data.flagsCollection.isRequired, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        // The error look: a 2px edge and the icon.
        expect(
          find.byWidgetPredicate(
            (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
          ),
          findsNWidgets(2),
          reason: "the field's icon and the message's",
        );
        handle.dispose();
      });
    }
  });

  group('edges', () {
    testWidgets('works without DsScope or DsApp (R3)', (tester) async {
      num? value = 2;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 200,
              child: DsNumberField(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(editableFinder());
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 3);
      await tester.tap(plus());
      await tester.pump();
      expect(value, 4);
      expect(tester.takeException(), isNull);
    });

    testWidgets('text scale 2.0 at 358px: no overflow, buttons fill height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(358, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        numberApp(
          initial: 12500.5,
          format: const DsNumberFormat(decimals: 2, grouping: true),
          unit: '₺',
          locale: const Locale('tr'),
          textScale: 2,
          width: 326,
          theme: DsThemeData(platform: TargetPlatform.iOS),
        ),
      );
      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byType(DsTextField));
      final button = tester.getRect(
        find.ancestor(of: plus(), matching: find.byType(DsPressable)),
      );
      expect(field.height, greaterThan(40));
      expect(button.height, closeTo(field.height - 2, 0.01));
      expect(text(tester), '12.500,50');
    });

    testWidgets('in a Row it takes its default width', (tester) async {
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [DsNumberField(value: 1, onChanged: (_) {})],
          ),
        ),
      );
      expect(tester.getSize(find.byType(DsNumberField)).width, 200);
    });

    testWidgets('a button under the mouse takes the hover fill', (
      tester,
    ) async {
      useTraditionalHighlights();
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: DsNumberField(value: 1, onChanged: (_) {}),
          ),
          theme: theme,
        ),
      );
      Color? fill() =>
          (tester
                      .widget<AnimatedContainer>(
                        find.ancestor(
                          of: plus(),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as DsBoxDecoration)
              .color;
      expect(fill()!.a, 0);
      await hover(tester, plus());
      expect(fill(), theme.colors.hover);
    });

    testWidgets('style and theme reach the buttons', (tester) async {
      const red = Color(0xFFFF0000);
      await tester.pumpWidget(
        host(
          DsNumberFieldTheme(
            data: const DsNumberFieldThemeData(
              style: DsNumberFieldStyle(foreground: red),
            ),
            child: DsNumberField(value: 1, onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.widget<DsIcon>(plus()).color, red);
    });
  });
}
