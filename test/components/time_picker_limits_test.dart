import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// firstTime / lastTime (office hours, "not before now") and the optional
// seconds column.

Widget _app(
  Widget child, {
  DsLocalizations strings = const DsLocalizationsTr(),
  Locale? locale,
}) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: locale,
  home: DsLocalizationScope(
    localizations: strings,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  ),
);

class _Picker extends StatefulWidget {
  const _Picker({
    this.initial,
    this.firstTime = const DsTime(9, 0),
    this.lastTime = const DsTime(18, 0),
    this.showSeconds = false,
    this.secondStep = 1,
    this.use24HourClock,
  });

  final DsTime? initial;
  final DsTime? firstTime;
  final DsTime? lastTime;
  final bool showSeconds;
  final int secondStep;
  final bool? use24HourClock;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late DsTime? value = widget.initial;
  final reported = <DsTime?>[];
  final issues = <DsInputIssue?>[];

  @override
  Widget build(BuildContext context) => DsField(
    label: const Text('Başlangıç'),
    child: DsTimePicker(
      value: value,
      minuteStep: 15,
      firstTime: widget.firstTime,
      lastTime: widget.lastTime,
      showSeconds: widget.showSeconds,
      secondStep: widget.secondStep,
      use24HourClock: widget.use24HourClock,
      onInputIssueChanged: issues.add,
      onChanged: (t) => setState(() {
        value = t;
        reported.add(t);
      }),
    ),
  );
}

Finder _field() => find.byType(EditableText).first;
String _text(WidgetTester tester) =>
    tester.widget<EditableText>(_field()).controller.text;

Future<_PickerState> _pump(
  WidgetTester tester,
  _Picker picker, {
  bool english = false,
  bool arabic = false,
}) async {
  await tester.pumpWidget(
    english
        ? _app(
            picker,
            strings: const DsLocalizationsEn(),
            locale: const Locale('en', 'US'),
          )
        : arabic
        ? _app(
            picker,
            strings: const DsLocalizationsAr(),
            locale: const Locale('ar'),
          )
        : _app(picker),
  );
  return tester.state<_PickerState>(find.byType(_Picker));
}

Future<void> _open(WidgetTester tester, {String label = 'Saat seç'}) async {
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field(), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

/// The item [label] in the column named [column].
Finder _item(String column, String label) => find.descendant(
  of: find.bySemanticsLabel(column),
  matching: find.text(label),
);

/// Whether the item [label] in [column] is drawn struck through.
bool _struck(WidgetTester tester, String column, String label) =>
    tester.widget<Text>(_item(column, label)).style?.decoration ==
    TextDecoration.lineThrough;

void main() {
  group('limits', () {
    testWidgets('hours outside the range show as unavailable and cannot be '
        'chosen', (tester) async {
      final state = await _pump(tester, const _Picker(initial: DsTime(10, 0)));
      await _open(tester);
      expect(_struck(tester, 'Saat', '08'), isTrue);
      expect(_struck(tester, 'Saat', '09'), isFalse);
      expect(_struck(tester, 'Saat', '10'), isFalse);
      await tester.tap(_item('Saat', '08'));
      await tester.pumpAndSettle();
      expect(state.reported, isEmpty);
      await tester.tap(_item('Saat', '09'));
      await tester.pumpAndSettle();
      expect(state.reported, [const DsTime(9, 0)]);
    });

    testWidgets('keys stop at the limits instead of wrapping into the '
        'unavailable hours', (tester) async {
      final state = await _pump(tester, const _Picker(initial: DsTime(18, 0)));
      await _open(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(state.reported, isEmpty);
      expect(_text(tester), '18:00');
      await _key(tester, LogicalKeyboardKey.home);
      expect(state.reported.last, const DsTime(9, 0));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(state.reported, [const DsTime(9, 0)]);
      await _key(tester, LogicalKeyboardKey.end);
      expect(state.reported.last, const DsTime(18, 0));
    });

    testWidgets('an hour moves the time into range; minutes before the '
        'first time are unavailable', (tester) async {
      final state = await _pump(
        tester,
        const _Picker(initial: DsTime(10, 15), firstTime: DsTime(9, 30)),
      );
      await _open(tester);
      await tester.tap(_item('Saat', '09'));
      await tester.pumpAndSettle();
      expect(state.reported.last, const DsTime(9, 30));
      expect(_struck(tester, 'Dakika', '15'), isTrue);
      expect(_struck(tester, 'Dakika', '30'), isFalse);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(state.reported, [const DsTime(9, 30)]);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(state.reported.last, const DsTime(9, 45));
    });

    testWidgets('screen readers: no step out of range; an out-of-range '
        'value reads as unavailable', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Picker(initial: DsTime(18, 0)));
      await _open(tester);
      var hours = tester.getSemantics(find.bySemanticsLabel('Saat'));
      expect(hours.increasedValue, isEmpty);
      expect(hours.decreasedValue, '17');

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const _Picker(initial: DsTime(8, 0)));
      await _open(tester);
      hours = tester.getSemantics(find.bySemanticsLabel('Saat'));
      expect(hours.value, '08, Seçilemez');
      expect(hours.increasedValue, '09');
      handle.dispose();
    });

    testWidgets('typed times outside the range get the field error', (
      tester,
    ) async {
      final state = await _pump(tester, const _Picker());
      await tester.enterText(_field(), '08:00');
      await tester.pump();
      expect(state.reported, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(state.issues.last?.kind, DsInputIssueKind.belowMin);
      expect(
        find.textContaining(
          '09:00 ya da sonraki bir saat girin.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      await _type(tester, '18:30');
      expect(state.issues.last?.kind, DsInputIssueKind.aboveMax);
      expect(
        find.textContaining(
          '18:00 ya da önceki bir saat girin.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(state.reported, isEmpty);
      await _type(tester, '12:00');
      expect(state.reported, [const DsTime(12, 0)]);
      expect(state.issues.last, isNull);
    });

    testWidgets('12-hour clock: a period with no time in range is '
        'unavailable', (tester) async {
      final state = await _pump(
        tester,
        const _Picker(
          initial: DsTime(14, 0),
          firstTime: DsTime(13, 0),
          lastTime: DsTime(18, 0),
        ),
        english: true,
      );
      await _open(tester, label: 'Choose time');
      expect(_struck(tester, 'AM/PM', 'AM'), isTrue);
      expect(_struck(tester, 'Hours', '12'), isTrue);
      expect(_struck(tester, 'Hours', '1'), isFalse);
      await tester.tap(_item('AM/PM', 'AM'));
      await tester.pumpAndSettle();
      expect(state.reported, isEmpty);
    });
  });

  group('seconds', () {
    test('DsTime holds seconds', () {
      expect(const DsTime(14, 30), const DsTime(14, 30, 0));
      expect(const DsTime(14, 30, 5), isNot(const DsTime(14, 30)));
      expect(const DsTime(14, 30, 5).compareTo(const DsTime(14, 30)), 1);
      expect(const DsTime(0, 1, 30).inSeconds, 90);
      expect(DsTime.fromSeconds(-60), const DsTime(23, 59));
      expect(const DsTime(14, 30, 5).toString(), 'DsTime(14:30:05)');
      expect(const DsTime(14, 30).toString(), 'DsTime(14:30)');
      expect(
        const DsTime(14, 30, 5).on(DateTime(2026, 10, 7)),
        DateTime(2026, 10, 7, 14, 30, 5),
      );
    });

    test('formats and reads seconds in every clock', () {
      const h24 = DsDateFormat('HH:mm:ss');
      const h12 = DsDateFormat('h:mm:ss a');
      expect(h24.formatTime(const DsTime(14, 30, 5)), '14:30:05');
      expect(h12.formatTime(const DsTime(14, 30, 5)), '2:30:05 PM');
      expect(h24.tryParseTime('14:30:05'), const DsTime(14, 30, 5));
      expect(h24.tryParseTime('143005'), const DsTime(14, 30, 5));
      expect(h24.tryParseTime('14:30'), const DsTime(14, 30));
      expect(h12.tryParseTime('2:30:05 pm'), const DsTime(14, 30, 5));
      expect(h24.tryParseTime('14:30:60'), isNull);
      // A pattern without seconds reads hours and minutes only.
      expect(const DsDateFormat('HH:mm').tryParseTime('14:30:05'), isNull);
      for (final (strings, pattern) in [
        (const DsLocalizationsKo() as DsLocalizations, 'a h:mm:ss'),
        (const DsLocalizationsJa(), 'ah:mm:ss'),
        (const DsLocalizationsEn(), 'h:mm:ss a'),
      ]) {
        final locale = DsDateLocale.resolve(const Locale('xx'), strings);
        expect(
          locale.timeFormat(use24HourClock: false, seconds: true).pattern,
          pattern,
        );
        expect(
          locale.timeFormat(use24HourClock: true, seconds: true).pattern,
          'HH:mm:ss',
        );
      }
    });

    testWidgets('a seconds column that wraps without carrying', (tester) async {
      final state = await _pump(
        tester,
        const _Picker(
          initial: DsTime(14, 30, 5),
          firstTime: null,
          lastTime: null,
          showSeconds: true,
        ),
      );
      expect(_text(tester), '14:30:05');
      await _open(tester);
      expect(tester.getSemantics(find.bySemanticsLabel('Saniye')).value, '05');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(state.reported.last, const DsTime(14, 30, 6));
      await _key(tester, LogicalKeyboardKey.end);
      expect(state.reported.last, const DsTime(14, 30, 59));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(state.reported.last, const DsTime(14, 30));
      expect(_text(tester), '14:30:00');
    });

    testWidgets('typing reads seconds once they are two digits', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const _Picker(firstTime: null, lastTime: null, showSeconds: true),
      );
      await tester.enterText(_field(), '14:30:1');
      await tester.pump();
      expect(state.reported, isEmpty);
      await tester.enterText(_field(), '14:30:15');
      await tester.pump();
      expect(state.reported, [const DsTime(14, 30, 15)]);
      await _type(tester, '9:05');
      expect(state.reported.last, const DsTime(9, 5));
      expect(_text(tester), '09:05:00');
    });

    testWidgets('secondStep lists the seconds in steps', (tester) async {
      await _pump(
        tester,
        const _Picker(
          initial: DsTime(14, 30),
          firstTime: null,
          lastTime: null,
          showSeconds: true,
          secondStep: 15,
        ),
      );
      await _open(tester);
      for (final s in ['00', '15', '30', '45']) {
        expect(_item('Saniye', s), findsOneWidget);
      }
      expect(_item('Saniye', '05'), findsNothing);
    });

    testWidgets('without seconds the picker works to the minute', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const _Picker(
          initial: DsTime(14, 30, 20),
          firstTime: DsTime(9, 0, 30),
          lastTime: null,
        ),
      );
      expect(_text(tester), '14:30');
      await _open(tester);
      expect(find.bySemanticsLabel('Saniye'), findsNothing);
      await tester.tap(_item('Dakika', '45'));
      await tester.pumpAndSettle();
      expect(state.reported.last, const DsTime(14, 45));
      // The limit's seconds are ignored: 09:00 can be chosen.
      await _key(tester, LogicalKeyboardKey.escape);
      await _type(tester, '09:00');
      expect(state.reported.last, const DsTime(9, 0));
    });

    testWidgets('with seconds the limits count to the second', (tester) async {
      await _pump(
        tester,
        const _Picker(
          initial: DsTime(9, 0, 45),
          firstTime: DsTime(9, 0, 30),
          showSeconds: true,
          secondStep: 15,
        ),
      );
      await _open(tester);
      expect(_struck(tester, 'Saniye', '15'), isTrue);
      expect(_struck(tester, 'Saniye', '30'), isFalse);
    });

    testWidgets('right to left: Left moves on to the seconds column', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const _Picker(
          initial: DsTime(14, 30, 5),
          firstTime: null,
          lastTime: null,
          showSeconds: true,
          use24HourClock: true,
        ),
        arabic: true,
      );
      await _open(tester, label: 'اختيار الوقت');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(state.reported.last, const DsTime(14, 30, 6));
      // The seconds column sits left of the minutes, as RTL reads.
      expect(
        tester.getCenter(find.bySemanticsLabel('الثواني')).dx,
        lessThan(tester.getCenter(find.bySemanticsLabel('الدقائق')).dx),
      );
    });
  });
}
