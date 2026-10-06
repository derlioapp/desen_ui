import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 5);

/// A full app in [strings]' language (Turkish by default).
Widget _app(
  Widget child, {
  DsLocalizations strings = const DsLocalizationsTr(),
  Size? size,
  double textScale = 1,
}) => DsApp(
  theme: DsThemeData(),
  themeMode: DsThemeMode.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(size: size, textScaler: TextScaler.linear(textScale)),
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

class _Single extends StatefulWidget {
  const _Single({this.initial, this.firstDate, this.inField = false});

  final DateTime? initial;
  final DateTime? firstDate;
  final bool inField;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  late DateTime? value = widget.initial;
  final reported = <DateTime?>[];

  @override
  Widget build(BuildContext context) {
    final picker = DsDatePicker(
      value: value,
      currentDate: _today,
      firstDate: widget.firstDate,
      semanticLabel: widget.inField ? null : 'Tarih',
      onChanged: (d) => setState(() {
        value = d;
        reported.add(d);
      }),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.inField)
          DsField(label: const Text('Teslim tarihi'), child: picker)
        else
          picker,
        const DsTextField(semanticLabel: 'Sonraki'),
      ],
    );
  }
}

class _Range extends StatefulWidget {
  const _Range({this.months});

  final int? months;

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  DsDateRange? value;
  final reported = <DsDateRange?>[];

  @override
  Widget build(BuildContext context) => DsDateRangePicker(
    value: value,
    currentDate: _today,
    months: widget.months,
    semanticLabel: 'Konaklama',
    onChanged: (r) => setState(() {
      value = r;
      reported.add(r);
    }),
  );
}

Finder _field() => find.byType(EditableText).first;
Finder _button() => find.bySemanticsLabel('Tarih seç');

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(_field());

void main() {
  group('DsDateFormat', () {
    const tr = DsDateFormat('dd.MM.y', strings: DsLocalizationsTr());
    const en = DsDateFormat('M/d/y');
    final oct5 = DateTime(2026, 10, 5);

    test('formats per locale', () {
      expect(tr.format(oct5), '05.10.2026');
      expect(en.format(oct5), '10/5/2026');
      const medium = DsDateFormat('d MMM y', strings: DsLocalizationsTr());
      expect(medium.format(oct5), '5 Eki 2026');
      const full = DsDateFormat('d MMMM y EEEE', strings: DsLocalizationsTr());
      expect(full.format(oct5), '5 Ekim 2026 Pazartesi');
      const ru = DsLocalizationsRu();
      expect(
        DsDateFormat(ru.dateFullPattern, strings: ru).format(oct5),
        'понедельник, 5 октября 2026 г.',
      );
      const es = DsLocalizationsEs();
      expect(
        DsDateFormat(es.monthYearPattern, strings: es).format(oct5),
        'Octubre de 2026',
      );
    });

    test('reads tr "05.10.2026" and en_US "10/5/2026"', () {
      expect(tr.tryParse('05.10.2026'), oct5);
      expect(en.tryParse('10/5/2026'), oct5);
    });

    test('is lenient about separators, digits and names', () {
      expect(tr.tryParse('5/10/2026'), oct5);
      expect(tr.tryParse('5-10-2026'), oct5);
      expect(tr.tryParse(' 5 10 2026 '), oct5);
      expect(tr.tryParse('5 Eki 2026'), oct5);
      expect(tr.tryParse('5 ekim 2026'), oct5);
      expect(tr.tryParse('٠٥.١٠.٢٠٢٦'), oct5);
      expect(en.tryParse('Oct 5 2026'), oct5);
      expect(tr.tryParse('05.10.26', today: _today), oct5);
      expect(tr.tryParse('5.10', today: _today), oct5);
    });

    test('refuses what is not a date', () {
      expect(tr.tryParse(''), isNull);
      expect(tr.tryParse('31.02.2026'), isNull);
      expect(tr.tryParse('05.13.2026'), isNull);
      expect(tr.tryParse('05.10.20261'), isNull);
      expect(tr.tryParse('05.10.2'), isNull);
      expect(tr.tryParse('dün'), isNull);
      expect(tr.tryParse('1.2.3.4'), isNull);
    });

    test('other orders: ja, ko, ar', () {
      const ja = DsLocalizationsJa();
      expect(
        DsDateFormat(ja.datePattern, strings: ja).format(oct5),
        '2026/10/05',
      );
      expect(
        DsDateFormat(ja.datePattern, strings: ja).tryParse('2026/10/5'),
        oct5,
      );
      const ko = DsLocalizationsKo();
      expect(
        DsDateFormat(ko.datePattern, strings: ko).format(oct5),
        '2026. 10. 5.',
      );
      const ar = DsLocalizationsAr();
      expect(
        DsDateFormat(ar.datePattern, strings: ar).tryParse('5/10/2026'),
        oct5,
      );
    });

    test('English outside the US writes the day first', () {
      const en = DsLocalizationsEn();
      expect(
        DsDateLocale.resolve(const Locale('en', 'US'), en).datePattern,
        'M/d/y',
      );
      expect(
        DsDateLocale.resolve(const Locale('en', 'GB'), en).datePattern,
        'dd/MM/y',
      );
      expect(
        DsDateLocale.resolve(const Locale('en', 'CA'), en).datePattern,
        'y-MM-dd',
      );
    });
  });

  group('DsDatePicker', () {
    testWidgets('shows the value in the language pattern', (tester) async {
      await tester.pumpWidget(_app(_Single(initial: DateTime(2026, 10, 14))));
      expect(_editable(tester).controller.text, '14.10.2026');
      final en = DsDatePicker(value: DateTime(2026, 10, 14), onChanged: (_) {});
      await tester.pumpWidget(_app(en, strings: const DsLocalizationsEn()));
      expect(_editable(tester).controller.text, '10/14/2026');
    });

    testWidgets('empty: the pattern to type is the placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Single()));
      expect(find.text('GG.AA.YYYY'), findsOneWidget);
    });

    testWidgets('typing reports once the year is typed; Enter reformats', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Single()));
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.enterText(_field(), '5.10.20');
      await tester.pump();
      expect(state.reported, isEmpty);
      await tester.enterText(_field(), '5.10.2026');
      await tester.pump();
      expect(state.reported, [DateTime(2026, 10, 5)]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(_editable(tester).controller.text, '05.10.2026');
    });

    testWidgets('text that is not a date keeps the error look', (tester) async {
      await tester.pumpWidget(_app(_Single(initial: DateTime(2026, 10, 14))));
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.enterText(_field(), '31.02.2026');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(state.reported.last, isNull);
      expect(_editable(tester).controller.text, '31.02.2026');
      expect(
        tester.widget<DsTextField>(find.byType(DsTextField).first).error,
        isTrue,
      );
    });

    testWidgets('a day before firstDate is refused', (tester) async {
      await tester.pumpWidget(_app(_Single(firstDate: DateTime(2026, 10, 10))));
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.enterText(_field(), '05.10.2026');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      // Still no value; the field shows the error look.
      expect(state.reported, isEmpty);
      expect(
        tester.widget<DsTextField>(find.byType(DsTextField).first).error,
        isTrue,
      );
    });

    testWidgets('the button opens the calendar; choosing closes it', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_Single(initial: DateTime(2026, 10, 14))));
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.tap(_button());
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsOneWidget);
      // Focus is on the chosen day.
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        contains('2026-10-14'),
      );
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing);
      expect(state.reported, [DateTime(2026, 10, 20)]);
      expect(_editable(tester).controller.text, '20.10.2026');
    });

    testWidgets('keyboard: open from the button, choose with Enter, focus '
        'returns to the button', (tester) async {
      await tester.pumpWidget(_app(_Single(initial: DateTime(2026, 10, 14))));
      final state = tester.state<_SingleState>(find.byType(_Single));
      // Field, then the button.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final button = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing);
      expect(state.reported, [DateTime(2026, 10, 21)]);
      expect(FocusManager.instance.primaryFocus, button);
    });

    testWidgets('Escape closes without a change; focus returns', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_Single(initial: DateTime(2026, 10, 14))));
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.tap(_field());
      await tester.pump();
      final field = FocusManager.instance.primaryFocus;
      // Alt+Down opens from the field.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing);
      expect(state.reported, isEmpty);
      expect(FocusManager.instance.primaryFocus, field);
    });

    testWidgets('in a DsField: named by the label, the button its own node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(_Single(initial: DateTime(2026, 10, 14), inField: true)),
      );
      final field = tester.getSemantics(_field());
      expect(field.label, contains('Teslim tarihi'));
      expect(field.value, '14.10.2026');
      final button = tester.getSemantics(_button());
      // One node: the button, read as collapsed while the calendar is shut.
      final data = button.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Tarih seç');
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('disabled: no typing, no calendar', (tester) async {
      await tester.pumpWidget(
        _app(DsDatePicker(value: DateTime(2026, 10, 14), onChanged: null)),
      );
      await tester.tap(_button());
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing);
      expect(_editable(tester).readOnly || !_isEnabled(tester), isTrue);
    });

    testWidgets('text scale 2.0 on a phone: nothing overflows', (tester) async {
      tester.view
        ..physicalSize = const Size(358, 760)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(_Single(initial: DateTime(2026, 10, 14)), textScale: 2),
      );
      await tester.tap(_button());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DsCalendar), findsOneWidget);
    });
  });

  group('DsDateRangePicker', () {
    testWidgets('choose start then end; the popup closes on the end', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Range(months: 1)));
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(_button());
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(state.reported, isEmpty);
      expect(find.byType(DsRangeCalendar), findsOneWidget);
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      expect(find.byType(DsRangeCalendar), findsNothing);
      expect(
        state.reported.single,
        DsDateRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 18)),
      );
      expect(_editable(tester).controller.text, '12.10.2026 – 18.10.2026');
    });

    testWidgets('closing after the start leaves the value', (tester) async {
      await tester.pumpWidget(_app(const _Range(months: 1)));
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(_button());
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(state.reported, isEmpty);
      expect(_editable(tester).controller.text, isEmpty);
    });

    testWidgets('empty: the two patterns, joined by an en dash', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Range()));
      expect(find.text('GG.AA.YYYY – GG.AA.YYYY'), findsOneWidget);
    });

    testWidgets('read-only: no calendar button; the text stays focusable', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _app(
          DsDateRangePicker(
            value: DsDateRange(
              start: DateTime(2026, 10, 12),
              end: DateTime(2026, 10, 18),
            ),
            onChanged: (_) {},
            semanticLabel: 'Konaklama',
            readOnly: true,
            focusNode: node,
          ),
        ),
      );
      expect(find.byType(DsButton), findsNothing);
      expect(_editable(tester).controller.text, '12.10.2026 – 18.10.2026');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      // Alt+Down opens nothing.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DsRangeCalendar), findsNothing);
    });

    testWidgets('typing a range, any dash or none', (tester) async {
      await tester.pumpWidget(_app(const _Range()));
      final state = tester.state<_RangeState>(find.byType(_Range));
      final expected = DsDateRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      );
      for (final text in [
        // En dash, as shown, with or without spaces.
        '12.10.2026 – 18.10.2026',
        '12.10.2026–18.10.2026',
        // Hyphen, with or without spaces.
        '12.10.2026 - 18.10.2026',
        '12.10.2026-18.10.2026',
        // Em dash, with or without spaces.
        '12.10.2026 — 18.10.2026',
        '12.10.2026—18.10.2026',
        // Nothing but the numbers.
        '12/10/2026 18/10/2026',
      ]) {
        await tester.enterText(_field(), '');
        await tester.enterText(_field(), text);
        await tester.pump();
        expect(state.reported.last, expected, reason: text);
      }
      // The end before the start is not a range.
      await tester.enterText(_field(), '18.10.2026 - 12.10.2026');
      await tester.pump();
      expect(state.reported.last, isNull);
    });

    testWidgets('two months in a wide window, one in a narrow one', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1000, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const _Range()));
      await tester.tap(_button());
      await tester.pumpAndSettle();
      expect(find.text('Kasım 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(400, 700);
      await tester.pumpWidget(_app(const _Range()));
      await tester.tap(_button());
      await tester.pumpAndSettle();
      expect(find.text('Ekim 2026'), findsOneWidget);
      expect(find.text('Kasım 2026'), findsNothing);
    });
  });

  testWidgets('works without DsScope or DsApp (R3): typing', (tester) async {
    DateTime? value;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DsDatePicker(value: null, onChanged: (d) => value = d),
          ),
        ),
      ),
    );
    await tester.enterText(_field(), '10/5/2026');
    await tester.pump();
    expect(value, DateTime(2026, 10, 5));
    expect(tester.takeException(), isNull);
  });
}

bool _isEnabled(WidgetTester tester) =>
    tester.widget<DsTextField>(find.byType(DsTextField).first).enabled;
