import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The hour, minute and second columns wrap like the time wheels of iOS
// and Android: Down on the last item gives the first. A wrapping minute
// stays in its hour.

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
  const _Picker({required this.initial});

  final DsTime initial;

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
      onChanged: (t) => setState(() {
        value = t;
        reported.add(t);
      }),
    ),
  );
}

String _text(WidgetTester tester) => tester
    .widget<EditableText>(find.byType(EditableText).first)
    .controller
    .text;

Future<_PickerState> _openAt(
  WidgetTester tester,
  DsTime initial, {
  bool english = false,
}) async {
  await tester.pumpWidget(
    english
        ? _app(
            _Picker(initial: initial),
            strings: const DsLocalizationsEn(),
            locale: const Locale('en', 'US'),
          )
        : _app(_Picker(initial: initial)),
  );
  await tester.tap(find.bySemanticsLabel(english ? 'Choose time' : 'Saat seç'));
  await tester.pumpAndSettle();
  return tester.state<_PickerState>(find.byType(_Picker));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// The item [label] in the column named [column].
Finder _item(String column, String label) => find.descendant(
  of: find.bySemanticsLabel(column),
  matching: find.text(label),
);

void main() {
  testWidgets('hours wrap: Down on 23 gives 00, Up on 00 gives 23', (
    tester,
  ) async {
    final state = await _openAt(tester, const DsTime(23, 30));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(state.reported.last, const DsTime(0, 30));
    expect(_text(tester), '00:30');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(state.reported.last, const DsTime(23, 30));
  });

  testWidgets('minutes wrap without carrying into the hour', (tester) async {
    final state = await _openAt(tester, const DsTime(14, 45));
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    // Not 15:00: the hour stays, as on an iOS wheel.
    expect(state.reported.last, const DsTime(14, 0));
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(state.reported.last, const DsTime(14, 45));
  });

  testWidgets('12-hour clock: hours step through the day, the period '
      'follows (Down stays later)', (tester) async {
    final state = await _openAt(tester, const DsTime(11, 30), english: true);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(state.reported.last, const DsTime(12, 30));
    expect(_text(tester), '12:30 PM');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(state.reported.last, const DsTime(11, 30));
    expect(_text(tester), '11:30 AM');
  });

  testWidgets('12-hour clock: Down on 11 PM wraps to 12 AM', (tester) async {
    final state = await _openAt(tester, const DsTime(23, 30), english: true);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(state.reported.last, const DsTime(0, 30));
    expect(_text(tester), '12:30 AM');
  });

  testWidgets('screen reader increase and decrease wrap as the keys do', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _openAt(tester, const DsTime(23, 30));
    final hours = tester.getSemantics(find.bySemanticsLabel('Saat'));
    expect(hours.increasedValue, '00');
    tester.semantics.increase(find.semantics.byLabel('Saat'));
    await tester.pumpAndSettle();
    expect(_text(tester), '00:30');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Saat')).decreasedValue,
      '23',
    );
    tester.semantics.decrease(find.semantics.byLabel('Saat'));
    await tester.pumpAndSettle();
    expect(_text(tester), '23:30');
    handle.dispose();
  });

  testWidgets('a column longer than it shows scrolls round', (tester) async {
    await _openAt(tester, const DsTime(0, 30));
    // 23 sits above 00, as on a wheel.
    expect(_item('Saat', '23'), findsOneWidget);
    expect(
      tester.getCenter(_item('Saat', '23')).dy,
      lessThan(tester.getCenter(_item('Saat', '00')).dy),
    );
    // Scrolling up keeps going past the start of the day.
    await tester.drag(_item('Saat', '00'), const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(_item('Saat', '20').hitTestable(), findsOneWidget);
  });
}
