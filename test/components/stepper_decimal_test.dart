import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsStepper with decimal values: the type follows the value, steps keep
/// to the grid without float dust, and the value is shown and announced
/// in the locale's format. Whole-number steppers keep reporting ints.
void main() {
  Finder button(DsIconData data) =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == data);

  /// A double stepper in an app with [locale], keeping its own value.
  Widget decimalApp({
    required double initial,
    required List<double> seen,
    num min = 0,
    num max = 5,
    num step = .5,
    DsNumberFormat? format,
    Locale locale = const Locale('en'),
  }) {
    var value = initial;
    return DsApp(
      locale: locale,
      home: Center(
        child: StatefulBuilder(
          builder: (context, set) => DsStepper(
            value: value,
            min: min,
            max: max,
            step: step,
            format: format,
            semanticLabel: 'Weight',
            onChanged: (v) => set(() {
              value = v;
              seen.add(v);
            }),
          ),
        ),
      ),
    );
  }

  testWidgets('the type follows the value: an int stepper reports ints', (
    tester,
  ) async {
    final seen = <Object>[];
    var value = 2;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => DsStepper(
            value: value,
            max: 4,
            onChanged: (v) => set(() {
              value = v;
              seen.add(v);
            }),
          ),
        ),
      ),
    );
    expect(find.byType(DsStepper<int>), findsOneWidget);
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen.single, isA<int>());
    expect(seen.single, 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a double stepper steps by its fraction and shows the step '
      'digits', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(decimalApp(initial: 2.5, seen: seen));
    expect(find.byType(DsStepper<double>), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen.last, 3.0);
    expect(find.text('3.0'), findsOneWidget, reason: 'digits stay fixed');
    await tester.tap(button(DsIcons.minus));
    await tester.pump();
    await tester.tap(button(DsIcons.minus));
    await tester.pump();
    expect(seen.last, 2.0);
  });

  testWidgets('float dust is rounded away', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      decimalApp(initial: .2, seen: seen, step: .1, max: 1),
    );
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen.last, .3, reason: '0.2 + 0.1 is 0.30000000000000004');
    for (var i = 0; i < 7; i++) {
      await tester.tap(button(DsIcons.plus));
      await tester.pump();
    }
    expect(seen.last, 1.0);
    await tester.pumpAndSettle();
    // The widest label also sizes the field, so it is drawn twice.
    expect(find.text('1.0'), findsWidgets);
  });

  testWidgets('limits keep a shown value: one with more digits than the '
      'stepper shows rounds inward', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      decimalApp(initial: 4, seen: seen, step: 1, max: 4.5),
    );
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen, isEmpty, reason: 'whole steps stop at 4, not 4.5 or 5');

    await tester.pumpWidget(
      decimalApp(
        initial: 9.8,
        seen: seen,
        step: .1,
        max: 9.99,
        format: const DsNumberFormat(decimals: 1),
      ),
    );
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen, [9.9]);
    await tester.tap(button(DsIcons.plus));
    await tester.pump();
    expect(seen, [9.9], reason: '9.99 at one digit is 9.9, not 10.0');
  });

  testWidgets('Turkish shows and announces a decimal comma', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      decimalApp(initial: 2.5, seen: [], locale: const Locale('tr')),
    );
    expect(find.text('2,5'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(DsStepper<double>)),
      isSemantics(
        label: 'Weight',
        value: '2,5',
        increasedValue: '3,0',
        decreasedValue: '2,0',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        isEnabled: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('format sets the digits and grouping', (tester) async {
    await tester.pumpWidget(
      decimalApp(
        initial: 1250,
        seen: [],
        min: 0,
        max: 10000,
        step: 250,
        format: const DsNumberFormat(decimals: 2, grouping: true),
        locale: const Locale('de'),
      ),
    );
    expect(find.text('1.250,00'), findsOneWidget);
  });

  testWidgets('keys step a double stepper; Home and End jump to the limits', (
    tester,
  ) async {
    final seen = <double>[];
    final node = FocusNode();
    addTearDown(node.dispose);
    var value = 1.5;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => DsStepper(
            value: value,
            min: .5,
            max: 3,
            step: .25,
            focusNode: node,
            onChanged: (v) => set(() {
              value = v;
              seen.add(v);
            }),
          ),
        ),
      ),
    );
    expect(find.text('1.50'), findsOneWidget, reason: '0.25 needs 2 digits');
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(seen.last, 1.75);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(seen.last, .5);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(seen.last, 3.0);
  });

  testWidgets('the slot holds the wider limit as shown, so the width does '
      'not jump', (tester) async {
    Future<double> widthAt(double v) async {
      await tester.pumpWidget(
        host(
          DsStepper(value: v, min: -10, max: 10, step: .5, onChanged: (_) {}),
        ),
      );
      return tester.getSize(find.byType(DsStepper<double>)).width;
    }

    final at0 = await widthAt(0);
    expect(await widthAt(-10), at0);
    expect(await widthAt(9.5), at0);
  });

  group('unit and prefix', () {
    Widget weight({
      double value = 2.5,
      TextDirection direction = TextDirection.ltr,
      bool enabled = true,
      DsThemeData? theme,
    }) => host(
      theme: theme,
      direction: direction,
      DsStepper(
        value: value,
        max: 10,
        step: .5,
        unit: 'kg',
        semanticLabel: 'Weight',
        onChanged: enabled ? (_) {} : null,
      ),
    );

    testWidgets('the unit follows the number and mirrors in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(weight());
      expect(
        tester.getCenter(find.text('kg')).dx,
        greaterThan(tester.getCenter(find.text('2.5')).dx),
      );
      await tester.pumpWidget(weight(direction: TextDirection.rtl));
      expect(
        tester.getCenter(find.text('kg')).dx,
        lessThan(tester.getCenter(find.text('2.5')).dx),
      );
    });

    testWidgets('read with the value and the next values, once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(weight());
      final data = tester
          .getSemantics(find.byType(DsStepper<double>))
          .getSemanticsData();
      expect(data.label, 'Weight');
      expect(data.value, '2.5 kg');
      expect(data.increasedValue, '3.0 kg');
      expect(data.decreasedValue, '2.0 kg');
      handle.dispose();
    });

    testWidgets('a prefix leads the number and is read before it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsStepper(
            value: 50,
            max: 100,
            step: 10,
            prefix: '%',
            semanticLabel: 'Opaklık',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getCenter(find.text('%')).dx,
        lessThan(tester.getCenter(find.text('50')).dx),
      );
      expect(
        tester
            .getSemantics(find.byType(DsStepper<int>))
            .getSemanticsData()
            .value,
        '%50',
      );
      handle.dispose();
    });

    testWidgets('the unit is quieter than the number and muted when '
        'disabled; the width does not jump', (tester) async {
      final theme = DsThemeData();
      Color unitColor() => tester
          .widget<RichText>(
            find.descendant(
              of: find.text('kg'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color!;
      await tester.pumpWidget(weight(theme: theme));
      expect(unitColor(), theme.colors.textMuted);
      final width = tester.getSize(find.byType(DsStepper<double>)).width;
      await tester.pumpWidget(weight(theme: theme, value: 10));
      expect(tester.getSize(find.byType(DsStepper<double>)).width, width);
      await tester.pumpWidget(weight(theme: theme, enabled: false));
      expect(unitColor(), theme.colors.onDisabled);
    });
  });
}
