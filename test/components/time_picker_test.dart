import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(
  Widget child, {
  DsLocalizations strings = const DsLocalizationsTr(),
  Locale? locale,
  double textScale = 1,
}) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: DsLocalizationScope(
    localizations: strings,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  ),
);

class _Picker extends StatefulWidget {
  const _Picker({this.initial, this.use24HourClock});

  final DsTime? initial;
  final bool? use24HourClock;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late DsTime? value = widget.initial;
  final reported = <DsTime?>[];

  @override
  Widget build(BuildContext context) => DsField(
    label: const Text('Başlangıç'),
    child: DsTimePicker(
      value: value,
      minuteStep: 15,
      use24HourClock: widget.use24HourClock,
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

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Saat seç'));
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('clock data', () {
    test('12- or 24-hour by region (CLDR)', () {
      expect(dsUses24HourClock(const Locale('tr')), isTrue);
      expect(dsUses24HourClock(const Locale('de')), isTrue);
      expect(dsUses24HourClock(const Locale('ja')), isTrue);
      expect(dsUses24HourClock(const Locale('en')), isFalse);
      expect(dsUses24HourClock(const Locale('en', 'GB')), isTrue);
      expect(dsUses24HourClock(const Locale('ko')), isFalse);
      expect(dsUses24HourClock(const Locale('ar')), isFalse);
    });

    test('formats and reads times', () {
      const h24 = DsDateFormat('HH:mm', strings: DsLocalizationsTr());
      const h12 = DsDateFormat('h:mm a');
      const t = DsTime(14, 5);
      expect(h24.formatTime(t), '14:05');
      expect(h12.formatTime(t), '2:05 PM');
      expect(h12.formatTime(const DsTime(0, 30)), '12:30 AM');
      expect(
        const DsDateFormat(
          'a h:mm',
          strings: DsLocalizationsTr(),
        ).formatTime(t),
        'ÖS 2:05',
      );
      for (final text in ['14:05', '14.05', '1405', '2:05 pm', '2:05 PM']) {
        expect(h12.tryParseTime(text), t, reason: text);
      }
      expect(h12.tryParseTime('2p'), const DsTime(14, 0));
      expect(h12.tryParseTime('12 am'), const DsTime(0, 0));
      expect(h24.tryParseTime('ÖS 2:05'), t);
      expect(h24.tryParseTime('24:00'), isNull);
      expect(h24.tryParseTime('13:60'), isNull);
      expect(h24.tryParseTime('13 pm'), isNull);
      expect(h24.tryParseTime('öğlen'), isNull);
    });
  });

  testWidgets('24-hour columns: hours 00–23, minutes in steps', (tester) async {
    await tester.pumpWidget(_app(const _Picker(initial: DsTime(14, 30))));
    expect(_text(tester), '14:30');
    await _open(tester);
    final hours = tester.getSemantics(find.bySemanticsLabel('Saat'));
    expect(hours.value, '14');
    final minutes = tester.getSemantics(find.bySemanticsLabel('Dakika'));
    expect(minutes.value, '30');
    expect(find.text('45'), findsOneWidget);
    expect(find.text('35'), findsNothing);
    expect(find.text('ÖÖ'), findsNothing);
  });

  testWidgets('tapping an item changes the time at once, columns stay', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const _Picker(initial: DsTime(14, 30))));
    final state = tester.state<_PickerState>(find.byType(_Picker));
    await _open(tester);
    await tester.tap(find.text('45'));
    await tester.pumpAndSettle();
    expect(state.reported, [const DsTime(14, 45)]);
    expect(_text(tester), '14:45');
    expect(find.bySemanticsLabel('Dakika'), findsOneWidget);
  });

  testWidgets('keyboard: Up/Down in a column, Left/Right between, Enter '
      'closes', (tester) async {
    await tester.pumpWidget(_app(const _Picker(initial: DsTime(14, 30))));
    final state = tester.state<_PickerState>(find.byType(_Picker));
    await _open(tester);
    // Focus starts in the hour column.
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(state.reported.last, const DsTime(15, 30));
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(state.reported.last, const DsTime(15, 15));
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.home);
    expect(state.reported.last, const DsTime(0, 15));
    await _key(tester, LogicalKeyboardKey.end);
    expect(state.reported.last, const DsTime(23, 15));
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.bySemanticsLabel('Dakika'), findsNothing);
    expect(_text(tester), '23:15');
  });

  testWidgets('Escape restores the time the columns opened with', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const _Picker(initial: DsTime(14, 30))));
    final state = tester.state<_PickerState>(find.byType(_Picker));
    await _open(tester);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_text(tester), '16:30');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.bySemanticsLabel('Dakika'), findsNothing);
    expect(_text(tester), '14:30');
    expect(state.reported.last, const DsTime(14, 30));
  });

  testWidgets('12-hour clock: AM/PM column, hours 12 and 1–11', (tester) async {
    await tester.pumpWidget(
      _app(
        const _Picker(initial: DsTime(14, 30)),
        strings: const DsLocalizationsEn(),
        locale: const Locale('en', 'US'),
      ),
    );
    final state = tester.state<_PickerState>(find.byType(_Picker));
    expect(_text(tester), '2:30 PM');
    await tester.tap(find.bySemanticsLabel('Choose time'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Hours')).value, '2');
    expect(tester.getSemantics(find.bySemanticsLabel('AM/PM')).value, 'PM');
    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    expect(state.reported.last, const DsTime(2, 30));
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(state.reported.last, const DsTime(0, 30));
    expect(_text(tester), '12:30 AM');
  });

  testWidgets('use24HourClock overrides the region', (tester) async {
    await tester.pumpWidget(
      _app(const _Picker(initial: DsTime(14, 30), use24HourClock: false)),
    );
    expect(_text(tester), 'ÖS 2:30');
  });

  testWidgets('typing reports once the minutes are typed', (tester) async {
    await tester.pumpWidget(_app(const _Picker()));
    final state = tester.state<_PickerState>(find.byType(_Picker));
    await tester.enterText(_field(), '9');
    await tester.pump();
    expect(state.reported, isEmpty);
    await tester.enterText(_field(), '9.05');
    await tester.pump();
    expect(state.reported, [const DsTime(9, 5)]);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_text(tester), '09:05');
    await tester.enterText(_field(), 'öğlen');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(state.reported.last, isNull);
  });

  testWidgets('a column is one adjustable node', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const _Picker(initial: DsTime(14, 30))));
    await _open(tester);
    final hours = tester.getSemantics(find.bySemanticsLabel('Saat'));
    expect(hours.increasedValue, '15');
    expect(hours.decreasedValue, '13');
    tester.semantics.increase(find.semantics.byLabel('Saat'));
    await tester.pumpAndSettle();
    expect(_text(tester), '15:30');
    handle.dispose();
  });

  testWidgets('text scale 2.0: items grow, nothing overflows', (tester) async {
    await tester.pumpWidget(
      _app(const _Picker(initial: DsTime(14, 30)), textScale: 2),
    );
    await _open(tester);
    expect(tester.takeException(), isNull);
    final item = find.ancestor(
      of: find.text('14'),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(item).height, greaterThan(32));
  });

  testWidgets('works without DsScope or DsApp: typing', (tester) async {
    DsTime? value;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DsTimePicker(value: null, onChanged: (t) => value = t),
          ),
        ),
      ),
    );
    await tester.enterText(_field(), '2:30 pm');
    await tester.pump();
    expect(value, const DsTime(14, 30));
    expect(tester.takeException(), isNull);
  });
}
