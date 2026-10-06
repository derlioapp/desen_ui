import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// How DsNumberFormat and DsNumberField read what is typed: a keypad "."
/// where "." also groups thousands, text that reads two ways, a grouped
/// number pasted into an ungrouped field, numbers a double cannot hold
/// exactly, and values a format cannot show.
void main() {
  const de = Locale('de');
  const en = Locale('en');

  DsNumberFormat fmt(Locale locale, {int decimals = 2, bool grouping = true}) =>
      DsNumberFormat(decimals: decimals, grouping: grouping).forLocale(locale);

  group('readings', () {
    test('a "." where "." groups is a group where it can be one', () {
      final f = fmt(de);
      expect(f.tryParse('1.234'), 1234, reason: 'three digits: not 2 decimals');
      expect(f.tryParse('1.234.567'), 1234567);
      expect(f.tryParse('1.234,5'), 1234.5);
      expect(f.tryParse('-12.500,75'), -12500.75);
    });

    test('and the decimal point where only that fits (keypad)', () {
      final f = fmt(de);
      expect(f.tryParse('12.5'), 12.5);
      expect(f.tryParse('12.50'), 12.5);
      expect(f.tryParse('12.'), 12);
      expect(f.tryParse('.5'), .5);
      expect(f.tryParse('-12.5'), -12.5);
      expect(fmt(de, decimals: 3).tryParse('1234.567'), 1234.567);
      expect(fmt(de, decimals: 3).tryParse('0.123'), .123);
    });

    test('text it can be neither in is not a number', () {
      final f = fmt(de);
      expect(f.readings('1.23.4'), isEmpty);
      expect(f.readings('12.5,3'), isEmpty);
      expect(f.readings('12.5555'), isEmpty);
      expect(f.readings('0.123'), isEmpty, reason: 'a leading zero group');
      expect(fmt(de, decimals: 0).readings('1.5'), isEmpty);
      expect(fmt(de, decimals: 0).tryParse('1.500'), 1500);
    });

    test('text it can be either in gives both readings, never a guess', () {
      final f = fmt(de, decimals: 3);
      expect(f.readings('1.234'), [1234, 1.234]);
      expect(f.tryParse('1.234'), isNull);
      expect(f.tryParse('1.234,0'), 1234);
      expect(f.tryParse('1,234'), 1.234);
      expect(f.readings('0.000'), [0], reason: 'a leading zero: no group');
    });

    test('the same rule for "," where "," groups', () {
      final f = fmt(en);
      expect(f.tryParse('12,5'), 12.5);
      expect(f.tryParse('1,234'), 1234);
      expect(f.tryParse('1,234.5'), 1234.5);
      expect(fmt(en, decimals: 3).readings('1,234'), [1234, 1.234]);
    });

    test('other group separators are skipped wherever they stand', () {
      final fr = fmt(const Locale('fr'));
      expect(fr.tryParse('12 500,5'), 12500.5);
      expect(fr.tryParse('12.5'), 12.5);
      final ch = fmt(const Locale('de', 'CH'));
      expect(ch.tryParse('12’500.5'), 12500.5);
    });

    test('every formatted number reads back as itself', () {
      for (final locale in [de, en, const Locale('tr'), const Locale('fr')]) {
        for (final decimals in [0, 2, 3]) {
          final f = fmt(locale, decimals: decimals);
          for (final v in [0, 7, 999, 1000, 1234, 12500, 1234567, -98765]) {
            expect(f.tryParse(f.format(v)), v, reason: '$locale $decimals $v');
          }
        }
      }
    });
  });

  group('format', () {
    test('non-finite values: ∞ and -∞, NaN empty', () {
      final f = fmt(en);
      expect(f.format(double.infinity), '∞');
      expect(f.format(double.negativeInfinity), '-∞');
      expect(f.format(double.nan), '');
      expect(f.tryParse(f.format(double.infinity)), isNull);
    });

    test('more than maxDecimals fails an assertion', () {
      DsNumberFormat make(int decimals) => DsNumberFormat(decimals: decimals);
      expect(DsNumberFormat.maxDecimals, 20);
      expect(() => make(21), throwsAssertionError);
      expect(make(20).format(1), '1.${'0' * 20}');
    });
  });

  group('field', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required Locale locale,
      required DsNumberFormat format,
      required List<num?> values,
      List<DsInputIssue?>? issues,
      num? min,
      num? max,
    }) async {
      num? value;
      await tester.pumpWidget(
        DsApp(
          locale: locale,
          home: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) => DsNumberField(
                  value: value,
                  min: min,
                  max: max,
                  format: format,
                  onInputIssueChanged: issues?.add,
                  onChanged: (v) => setState(() {
                    value = v;
                    values.add(v);
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
    }

    String text(WidgetTester tester) =>
        tester.widget<EditableText>(find.byType(EditableText)).controller.text;

    /// Types [chars] one by one, through the field's formatter.
    Future<void> typeChars(WidgetTester tester, String chars) async {
      for (final c in chars.split('')) {
        final now = text(tester);
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: now + c,
            selection: TextSelection.collapsed(offset: now.length + 1),
          ),
        );
        await tester.pump();
      }
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    testWidgets('German grouped field: a keypad "." is the decimal point', (
      tester,
    ) async {
      final values = <num?>[];
      await pumpField(
        tester,
        locale: de,
        format: const DsNumberFormat(decimals: 2, grouping: true),
        values: values,
      );
      await typeChars(tester, '12.5');
      expect(values.last, 12.5);
      await submit(tester);
      expect(values.last, 12.5);
      expect(text(tester), '12,50');
    });

    testWidgets('German grouped field: "1.234" with three decimals is '
        'flagged with both readings, not guessed', (tester) async {
      final values = <num?>[];
      final issues = <DsInputIssue?>[];
      await pumpField(
        tester,
        locale: de,
        format: const DsNumberFormat(decimals: 3, grouping: true),
        values: values,
        issues: issues,
      );
      await typeChars(tester, '1.234');
      expect(values.last, isNull, reason: 'no value while it reads two ways');
      await submit(tester);
      expect(values.last, isNull);
      expect(text(tester), '1.234', reason: 'kept to be fixed');
      expect(issues.last?.kind, DsInputIssueKind.invalid);
      expect(issues.last?.message, contains('1.234,000'));
      expect(issues.last?.message, contains('1,234'));
      // Saying which one fixes it.
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await typeChars(tester, ',0');
      await submit(tester);
      expect(values.last, 1234.0);
      expect(issues.last, isNull);
    });

    testWidgets('German grouped field: a misplaced "." is not a number', (
      tester,
    ) async {
      final values = <num?>[];
      final issues = <DsInputIssue?>[];
      await pumpField(
        tester,
        locale: de,
        format: const DsNumberFormat(decimals: 2, grouping: true),
        values: values,
        issues: issues,
      );
      await typeChars(tester, '1.23.4');
      await submit(tester);
      expect(values.last, isNull);
      expect(text(tester), '1.23.4');
      expect(issues.last?.kind, DsInputIssueKind.invalid);
    });

    testWidgets('a grouped number pasted into an ungrouped German field', (
      tester,
    ) async {
      final values = <num?>[];
      await pumpField(
        tester,
        locale: de,
        format: const DsNumberFormat(decimals: 2),
        values: values,
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1.234,56',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      await tester.pump();
      expect(text(tester), '1234,56');
      await submit(tester);
      expect(values.last, 1234.56);
    });

    testWidgets('a grouped number pasted into an ungrouped English field', (
      tester,
    ) async {
      final values = <num?>[];
      await pumpField(
        tester,
        locale: en,
        format: const DsNumberFormat(decimals: 2),
        values: values,
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1,234.56',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      await tester.pump();
      expect(text(tester), '1234.56');
    });

    testWidgets('an integer past 2^53 is flagged, not changed', (
      tester,
    ) async {
      final values = <num?>[];
      final issues = <DsInputIssue?>[];
      await pumpField(
        tester,
        locale: en,
        format: const DsNumberFormat(),
        values: values,
        issues: issues,
      );
      await tester.enterText(find.byType(EditableText), '12345678901234567');
      await tester.pump();
      expect(issues.last?.kind, DsInputIssueKind.aboveMax);
      await submit(tester);
      expect(text(tester), '12345678901234567', reason: 'kept as typed');
      expect(values.where((v) => v != null), isEmpty);
      expect(issues.last?.kind, DsInputIssueKind.aboveMax);
      expect(issues.last?.message, contains('9007199254740991'));
    });

    testWidgets('the largest exact integer is taken as typed', (tester) async {
      final values = <num?>[];
      await pumpField(
        tester,
        locale: en,
        format: const DsNumberFormat(),
        values: values,
      );
      await tester.enterText(find.byType(EditableText), '9007199254740991');
      await submit(tester);
      expect(values.last, 9007199254740991);
      expect(text(tester), '9007199254740991');
    });

    testWidgets('a negative integer past -(2^53 - 1) is flagged', (
      tester,
    ) async {
      final issues = <DsInputIssue?>[];
      await pumpField(
        tester,
        locale: en,
        format: const DsNumberFormat(),
        values: [],
        issues: issues,
      );
      await tester.enterText(find.byType(EditableText), '-90071992547409920');
      await submit(tester);
      expect(issues.last?.kind, DsInputIssueKind.belowMin);
    });

    testWidgets('a max under the limit still clamps on commit', (
      tester,
    ) async {
      final values = <num?>[];
      await pumpField(
        tester,
        locale: en,
        format: const DsNumberFormat(),
        values: values,
        max: 300,
      );
      await tester.enterText(find.byType(EditableText), '12345678901234567');
      await submit(tester);
      expect(values.last, 300);
    });
  });
}
