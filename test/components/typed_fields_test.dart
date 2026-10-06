// Regression tests for the typed fields (date, range, time, number):
// parsing never throws, years round-trip, no phantom changes, invalid
// input has text, numbers round before they clamp.
import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsData, SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app in US English (unless [locale] says otherwise).
Widget _app(Widget child, {Locale locale = const Locale('en', 'US')}) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: locale,
  // An app in a language Desen has no strings for lists it.
  supportedLocales: [locale, ...DsLocalizations.supportedLocales],
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(padding: const EdgeInsets.all(8), child: child),
  ),
);

/// Holds a value and logs what the field reports.
class _Holder<T> extends StatefulWidget {
  const _Holder({super.key, required this.initial, required this.builder});

  final T initial;
  final Widget Function(
    T value,
    ValueChanged<T> set,
    ValueChanged<DsInputIssue?> invalid,
  )
  builder;

  @override
  State<_Holder<T>> createState() => _HolderState<T>();
}

class _HolderState<T> extends State<_Holder<T>> {
  late T value = widget.initial;
  final log = <T>[];
  final issues = <DsInputIssue?>[];

  void set(T v) => setState(() {
    value = v;
    log.add(v);
  });

  void invalid(DsInputIssue? issue) => setState(() => issues.add(issue));

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 300, child: widget.builder(value, set, invalid)),
      DsButton(onPressed: () {}, child: const Text('next')),
    ],
  );
}

Future<GlobalKey<_HolderState<T>>> _pump<T>(
  WidgetTester tester,
  T initial,
  Widget Function(
    T value,
    ValueChanged<T> set,
    ValueChanged<DsInputIssue?> invalid,
  )
  builder, {
  Locale locale = const Locale('en', 'US'),
}) async {
  final key = GlobalKey<_HolderState<T>>();
  await tester.pumpWidget(
    _app(
      _Holder<T>(key: key, initial: initial, builder: builder),
      locale: locale,
    ),
  );
  return key;
}

Finder get _editable => find.byType(EditableText);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(_editable).controller.text;

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_editable, text);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Widget _date(
  DateTime? v,
  ValueChanged<DateTime?> set,
  ValueChanged<DsInputIssue?> invalid,
) => DsDatePicker(
  value: v,
  onChanged: set,
  onInputIssueChanged: invalid,
  currentDate: DateTime(2026, 10, 5),
);

void main() {
  group('parsing never throws', () {
    for (final year in ['300000', '99999999999999999999']) {
      testWidgets('date: a $year year on Enter, blur and popup', (
        tester,
      ) async {
        final key = await _pump<DateTime?>(tester, null, _date);
        await tester.tap(_editable);
        await _type(tester, '1/1/$year');
        await _enter(tester);
        expect(tester.takeException(), isNull);
        expect(key.currentState!.value, isNull);
        expect(key.currentState!.issues.last?.kind, DsInputIssueKind.invalid);
        await _type(tester, '1/2/$year');
        await _blur(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(_editable);
        await _type(tester, '1/3/$year');
        await tester.tap(find.bySemanticsLabel('Choose date'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(DsCalendar), findsOneWidget);
      });
    }

    testWidgets('range: a 20-digit year', (tester) async {
      final key = await _pump<DsDateRange?>(
        tester,
        null,
        (v, set, invalid) => DsDateRangePicker(
          value: v,
          onChanged: set,
          onInputIssueChanged: invalid,
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '1/1/2026 – 1/2/99999999999999999999');
      await _enter(tester);
      expect(tester.takeException(), isNull);
      expect(key.currentState!.issues.last?.kind, DsInputIssueKind.invalid);
    });

    testWidgets('time: a 20-digit hour while typing and on commit', (
      tester,
    ) async {
      final key = await _pump<DsTime?>(
        tester,
        null,
        (v, set, invalid) => DsTimePicker(
          value: v,
          onChanged: set,
          onInputIssueChanged: invalid,
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '99999999999999999999:30');
      expect(tester.takeException(), isNull);
      await _enter(tester);
      expect(tester.takeException(), isNull);
      expect(key.currentState!.value, isNull);
      expect(
        key.currentState!.issues.last?.message,
        'Enter a time such as 2:30 PM.',
      );
    });

    test('DsDateFormat and tryParseTime are bounded', () {
      const f = DsDateFormat('M/d/y');
      expect(f.tryParse('1/1/300000'), isNull);
      expect(f.tryParse('1/1/99999999999999999999'), isNull);
      expect(f.tryParse('99999999999999999999/1/2026'), isNull);
      expect(f.tryParse('1/1/0'), isNull);
      expect(f.tryParse('1/1/0000'), isNull);
      expect(f.tryParseTime('99999999999999999999:30'), isNull);
      expect(f.tryParseTime('14:99999999999999999999'), isNull);
      expect(f.tryParseTime('123:30'), isNull);
    });
  });

  group('years before 1000 round-trip', () {
    test('a year shows with four digits and reads back as itself', () {
      const f = DsDateFormat('M/d/y');
      final today = DateTime(2026, 10, 5);
      for (final year in [1, 9, 50, 99, 476, 999, 1000, 2026, 9999]) {
        final d = DateTime(year, 6, 15);
        expect(f.tryParse(f.format(d), today: today), d, reason: '$year');
      }
      expect(f.format(DateTime(50, 6, 15)), '6/15/0050');
      expect(f.tryParse('9/4/476', today: today), DateTime(476, 9, 4));
      expect(f.tryParse('1/1/0099', today: today), DateTime(99));
      // Exactly two digits: the two-digit window.
      expect(f.tryParse('1/1/99', today: today), DateTime(1999));
      expect(f.tryParse('1/1/26', today: today), DateTime(2026));
      // One digit is not a year.
      expect(f.tryParse('1/1/6', today: today), isNull);
    });

    for (final (typed, year) in [('1/1/0099', 99), ('9/4/0476', 476)]) {
      testWidgets('typed $typed survives leaving the field twice', (
        tester,
      ) async {
        final key = await _pump<DateTime?>(tester, null, _date);
        await tester.tap(_editable);
        await _type(tester, typed);
        await _enter(tester);
        final day = DateTime(
          year,
          typed.startsWith('1/') ? 1 : 9,
          year == 99 ? 1 : 4,
        );
        expect(key.currentState!.value, day);
        await _blur(tester);
        await tester.tap(_editable);
        await tester.pumpAndSettle();
        await _blur(tester);
        expect(key.currentState!.value, day);
        expect(key.currentState!.log, [day]);
      });
    }

    testWidgets('a year-50 value is not changed by tabbing through', (
      tester,
    ) async {
      final key = await _pump<DateTime?>(tester, DateTime(50, 6, 15), _date);
      expect(_text(tester), '6/15/0050');
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(key.currentState!.log, isEmpty);
    });
  });

  group('no phantom changes', () {
    testWidgets('date: focus and blur without an edit report nothing, and '
        'the time of day stays', (tester) async {
      final value = DateTime(2026, 10, 5, 14, 30);
      final key = await _pump<DateTime?>(tester, value, _date);
      await tester.tap(_editable);
      await tester.pumpAndSettle();
      await _blur(tester);
      await tester.tap(_editable);
      await _enter(tester);
      // Opening and closing the popup is no edit either.
      await tester.tap(find.bySemanticsLabel('Choose date'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(key.currentState!.log, isEmpty);
      expect(key.currentState!.value, value);
    });

    testWidgets('date: typing or choosing a day keeps the time of day', (
      tester,
    ) async {
      final key = await _pump<DateTime?>(
        tester,
        DateTime(2026, 10, 5, 14, 30, 15),
        _date,
      );
      await tester.tap(_editable);
      await _type(tester, '10/7/2026');
      expect(key.currentState!.value, DateTime(2026, 10, 7, 14, 30, 15));
      // The same day typed again is no change.
      await _type(tester, '10/07/2026');
      await _enter(tester);
      expect(key.currentState!.log, [DateTime(2026, 10, 7, 14, 30, 15)]);
      await tester.tap(find.bySemanticsLabel('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(key.currentState!.value, DateTime(2026, 10, 9, 14, 30, 15));
    });

    testWidgets('date: a UTC value stays UTC', (tester) async {
      final key = await _pump<DateTime?>(
        tester,
        DateTime.utc(2026, 10, 5, 8),
        _date,
      );
      await tester.tap(_editable);
      await _type(tester, '10/6/2026');
      expect(key.currentState!.value, DateTime.utc(2026, 10, 6, 8));
    });

    testWidgets('time: focus and blur without an edit report nothing', (
      tester,
    ) async {
      final key = await _pump<DsTime?>(
        tester,
        const DsTime(9, 7),
        (v, set, invalid) => DsTimePicker(value: v, onChanged: set),
      );
      await tester.tap(_editable);
      await tester.pumpAndSettle();
      await _blur(tester);
      expect(key.currentState!.log, isEmpty);
    });

    testWidgets('number: an out-of-range value from the app is not clamped '
        'by focus alone', (tester) async {
      final key = await _pump<num?>(
        tester,
        50,
        (v, set, invalid) => DsNumberField(value: v, max: 10, onChanged: set),
      );
      await tester.tap(_editable);
      await tester.pumpAndSettle();
      await _blur(tester);
      expect(key.currentState!.log, isEmpty);
      expect(_text(tester), '50');
    });
  });

  group('invalid input has text (WCAG 3.3.1)', () {
    testWidgets('date in a DsField: the field shows the message; empty and '
        'invalid differ', (tester) async {
      final key = await _pump<DateTime?>(
        tester,
        DateTime(2026, 1, 1),
        (v, set, invalid) => DsField(
          label: const Text('Birthday'),
          child: DsDatePicker(
            value: v,
            onChanged: set,
            onInputIssueChanged: invalid,
            currentDate: DateTime(2026, 10, 5),
          ),
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '02/31/2026');
      await _blur(tester);
      expect(key.currentState!.value, isNull);
      expect(key.currentState!.issues, [
        const DsInputIssue(
          DsInputIssueKind.invalid,
          'Enter a date as MM/DD/YYYY.',
        ),
      ]);
      expect(
        find.textContaining('Enter a date as MM/DD/YYYY.', findRichText: true),
        findsOneWidget,
      );
      // Typing clears it; an empty field is no issue.
      await tester.tap(_editable);
      await _type(tester, '');
      await _blur(tester);
      expect(key.currentState!.issues.last, isNull);
      expect(key.currentState!.value, isNull);
      expect(
        find.textContaining('Enter a date', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('the app\'s error wins over the field\'s own message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: DsField(
              label: const Text('Qty'),
              errorText: 'Required by policy.',
              child: DsNumberField(value: null, onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '-');
      await _blur(tester);
      expect(
        find.textContaining('Required by policy.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Enter a number.', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('the message is announced and marks the field invalid', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final data = (message! as Map)['data'] as Map;
            announced.add('${data['message']}');
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(supportsAnnounce: true),
            child: SizedBox(
              width: 300,
              child: DsField(
                label: const Text('Start'),
                child: DsTimePicker(value: null, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '25:00');
      await _blur(tester);
      expect(announced.single, contains('Enter a time such as 2:30 PM.'));
      handle.dispose();
    });

    testWidgets('date range of days: before first, after last, unavailable', (
      tester,
    ) async {
      final key = await _pump<DateTime?>(
        tester,
        null,
        (v, set, invalid) => DsDatePicker(
          value: v,
          onChanged: set,
          onInputIssueChanged: invalid,
          firstDate: DateTime(2026, 10, 1),
          lastDate: DateTime(2026, 10, 31),
          selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
        ),
      );
      await tester.tap(_editable);
      Future<DsInputIssue?> commit(String text) async {
        await _type(tester, text);
        await _enter(tester);
        return key.currentState!.issues.last;
      }

      expect(
        await commit('9/30/2026'),
        const DsInputIssue(
          DsInputIssueKind.belowMin,
          'Enter a date on or after 10/1/2026.',
        ),
      );
      expect((await commit('11/1/2026'))?.kind, DsInputIssueKind.aboveMax);
      expect((await commit('10/4/2026'))?.kind, DsInputIssueKind.unavailable);
      expect(await commit('10/5/2026'), isNull);
      expect(key.currentState!.value, DateTime(2026, 10, 5));
    });

    test('messages are translated in every bundled language', () {
      final en = const DsLocalizationsEn();
      for (final strings in dsBundledLocalizations.values) {
        if (strings.localeName == 'en') continue;
        expect(
          strings.invalidNumber,
          isNot(en.invalidNumber),
          reason: strings.localeName,
        );
        expect(
          strings.invalidDate('X'),
          isNot(en.invalidDate('X')),
          reason: strings.localeName,
        );
        expect(strings.numberTooLarge('9'), contains('9'));
        expect(strings.dateTooEarly('D'), contains('D'));
      }
    });
  });

  group('number: rounds, then clamps', () {
    testWidgets('End never reports more than max', (tester) async {
      final key = await _pump<num?>(
        tester,
        1,
        (v, set, invalid) =>
            DsNumberField(value: v, min: 0, max: 2.5, onChanged: set),
      );
      await tester.tap(_editable);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(key.currentState!.value, 2);
      expect(_text(tester), '2');
      // Up at the last whole number below max stays at it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(key.currentState!.value, 2);
    });

    testWidgets('an over-max commit lands on the largest shown number', (
      tester,
    ) async {
      final key = await _pump<num?>(
        tester,
        1,
        (v, set, invalid) => DsNumberField(
          value: v,
          min: 0,
          max: 9.99,
          format: const DsNumberFormat(decimals: 1),
          onChanged: set,
          onInputIssueChanged: invalid,
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '50');
      expect(
        key.currentState!.issues.last,
        const DsInputIssue(DsInputIssueKind.aboveMax, 'Enter 9.9 or less.'),
      );
      await _enter(tester);
      expect(key.currentState!.value, 9.9);
      expect(_text(tester), '9.9');
      expect(key.currentState!.issues.last, isNull);
    });

    testWidgets('min rounds up: 0.25 with one digit is 0.3', (tester) async {
      final key = await _pump<num?>(
        tester,
        null,
        (v, set, invalid) => DsNumberField(
          value: v,
          min: 0.25,
          format: const DsNumberFormat(decimals: 1),
          onChanged: set,
        ),
      );
      await tester.tap(_editable);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(key.currentState!.value, 0.3);
    });

    testWidgets('step 0.1 stays on the grid over the range', (tester) async {
      final key = await _pump<num?>(
        tester,
        0,
        (v, set, invalid) => DsNumberField(
          value: v,
          min: 0,
          max: 1,
          step: 0.1,
          format: const DsNumberFormat(decimals: 1),
          onChanged: set,
        ),
      );
      await tester.tap(_editable);
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      }
      await tester.pump();
      expect(key.currentState!.value, 1.0);
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pump();
      expect(key.currentState!.value, 0.0);
    });

    testWidgets('20 digits: the value and the text agree', (tester) async {
      // Past 2^53 - 1 a double would change the number, so since b26a803
      // the typed text is kept and flagged instead of reported as 1e20.
      final key = await _pump<num?>(
        tester,
        null,
        (v, set, invalid) => DsNumberField(
          value: v,
          onChanged: set,
          onInputIssueChanged: invalid,
        ),
      );
      await tester.tap(_editable);
      await _type(tester, '99999999999999999999');
      await _enter(tester);
      expect(key.currentState!.value, isNull);
      expect(key.currentState!.log.where((v) => v != null), isEmpty);
      expect(_text(tester), '99999999999999999999');
      expect(key.currentState!.issues.last?.kind, DsInputIssueKind.aboveMax);
    });

    testWidgets('22 digits: no exponent, still steppable', (tester) async {
      // Typing 22 digits is flagged past the exact limit (b26a803); a value
      // that large from outside still shows in plain digits and steps.
      final key = await _pump<num?>(
        tester,
        1e21,
        (v, set, invalid) => DsNumberField(
          value: v,
          format: const DsNumberFormat(decimals: 1),
          onChanged: set,
          onInputIssueChanged: invalid,
        ),
      );
      expect(_text(tester), '1000000000000000000000.0');
      await tester.tap(_editable);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(key.currentState!.value, greaterThanOrEqualTo(1e21));
      expect(_text(tester), isNot(contains('e')));
      await _type(tester, '1000000000000000000000');
      await _enter(tester);
      expect(_text(tester), '1000000000000000000000');
      expect(key.currentState!.issues.last?.kind, DsInputIssueKind.aboveMax);
    });

    testWidgets('a NaN value shows an empty field', (tester) async {
      await _pump<num?>(
        tester,
        double.nan,
        (v, set, invalid) => DsNumberField(value: v, onChanged: set),
      );
      expect(_text(tester), '');
    });

    testWidgets('German grouping and decimals', (tester) async {
      final key = await _pump<num?>(
        tester,
        null,
        (v, set, invalid) => DsNumberField(
          value: v,
          format: const DsNumberFormat(decimals: 2, grouping: true),
          onChanged: set,
        ),
        locale: const Locale('de'),
      );
      await tester.tap(_editable);
      await _type(tester, '1.234,5');
      await _enter(tester);
      expect(key.currentState!.value, 1234.5);
      expect(_text(tester), '1.234,50');
    });

    testWidgets('Polish separators without Polish strings', (tester) async {
      await _pump<num?>(
        tester,
        1234.5,
        (v, set, invalid) => DsNumberField(
          value: v,
          format: const DsNumberFormat(decimals: 1),
          onChanged: set,
        ),
        locale: const Locale('pl', 'PL'),
      );
      expect(_text(tester), '1234,5');
    });
  });

  group('search field and IME', () {
    testWidgets('Escape while composing does not clear the query', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'tokyo ');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(width: 300, child: DsSearchField(controller: controller)),
        ),
      );
      await tester.tap(_editable);
      await tester.pumpAndSettle();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'tokyo かん',
          selection: TextSelection.collapsed(offset: 8),
          composing: TextRange(start: 6, end: 8),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.text, startsWith('tokyo'));
      // Composed text: Escape clears again.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'tokyo 漢',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
    });
  });

  group('trigger buttons read expanded', () {
    for (final (name, label, picker) in [
      (
        'date',
        'Choose date',
        DsDatePicker(value: null, onChanged: (_) {}) as Widget,
      ),
      (
        'range',
        'Choose date',
        DsDateRangePicker(value: null, onChanged: (_) {}),
      ),
      ('time', 'Choose time', DsTimePicker(value: null, onChanged: (_) {})),
    ]) {
      testWidgets('$name: collapsed, then expanded, one node', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(SizedBox(width: 300, child: picker)));
        // The node a screen reader lands on: the button, with its label.
        SemanticsData data() {
          final found = <SemanticsData>[];
          void walk(SemanticsNode node) {
            final d = node.getSemanticsData();
            if (!node.isMergedIntoParent &&
                d.label == label &&
                d.flagsCollection.isButton) {
              found.add(d);
            }
            node.visitChildren((child) {
              walk(child);
              return true;
            });
          }

          walk(
            tester
                .binding
                .renderViews
                .first
                .owner!
                .semanticsOwner!
                .rootSemanticsNode!,
          );
          return found.single;
        }

        expect(data().flagsCollection.isExpanded, Tristate.isFalse);
        expect(data().flagsCollection.isButton, isTrue);
        await tester.tap(find.byType(DsButton).first);
        await tester.pumpAndSettle();
        expect(data().flagsCollection.isExpanded, Tristate.isTrue);
        expect(data().label, label);
        handle.dispose();
      });
    }
  });

  group('narrow and churn', () {
    for (final width in [120.0, 160.0, 200.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('date picker with an error at ${width}px x$scale', (
          tester,
        ) async {
          await tester.pumpWidget(
            _app(
              MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: SizedBox(
                  width: width,
                  child: DsDatePicker(
                    value: DateTime(2024, 2, 29),
                    error: true,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('a value set from outside drops the issue and says so', (
      tester,
    ) async {
      final key = await _pump<DateTime?>(tester, null, _date);
      await tester.tap(_editable);
      await _type(tester, 'nope');
      await _enter(tester);
      expect(key.currentState!.issues.last?.kind, DsInputIssueKind.invalid);
      key.currentState!.set(DateTime(2026, 10, 9));
      await tester.pumpAndSettle();
      expect(_text(tester), '10/9/2026');
      expect(key.currentState!.issues.last, isNull);
    });

    testWidgets('focus nodes swap while focused', (tester) async {
      final a = FocusNode(), b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      FocusNode? node = a;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DsDatePicker(
                      value: null,
                      focusNode: node,
                      onChanged: (_) {},
                    ),
                    DsTimePicker(
                      value: null,
                      focusNode: node == a ? null : a,
                      onChanged: (_) {},
                    ),
                    DsNumberField(
                      value: 1,
                      focusNode: node == b ? b : null,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      a.requestFocus();
      await tester.pump();
      set(() => node = b);
      await tester.pump();
      set(() => node = null);
      await tester.pump();
      expect(tester.takeException(), isNull);
      // ignore: invalid_use_of_protected_member
      expect(b.hasListeners, isFalse);
    });
  });
}
