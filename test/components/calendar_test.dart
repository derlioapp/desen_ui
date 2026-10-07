import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

final _today = DateTime(2026, 10, 5);

/// The weekday headers in column order, as drawn.
List<String> _headers(WidgetTester tester, DsLocalizations l10n) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .toList();
  final abbrs = {for (var w = 1; w <= 7; w++) l10n.weekdayAbbr(w)};
  return texts.where(abbrs.contains).take(7).toList();
}

/// Wraps [child] in the language [strings] and the app [locale].
Widget _localized(
  Widget child, {
  DsLocalizations? strings,
  Locale? locale,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  DsThemeData? theme,
}) {
  if (strings != null) {
    child = DsLocalizationScope(localizations: strings, child: child);
  }
  if (locale != null) {
    child = Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: child,
    );
  }
  return host(child, direction: direction, textScale: textScale, theme: theme);
}

/// A full app (Tab traversal and the default shortcuts) in Turkish.
Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    DsApp(
      theme: DsThemeData(),
      themeMode: DsThemeMode.light,
      home: Directionality(
        textDirection: direction,
        child: DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: Center(child: child),
        ),
      ),
    );

/// Tabs until a day has focus.
Future<void> _tabToDays(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final label = FocusManager.instance.primaryFocus?.debugLabel ?? '';
    if (label.startsWith('DsCalendar day')) return;
  }
  fail('no day took focus');
}

/// A calendar holding its own value, Turkish by default.
class _Single extends StatefulWidget {
  const _Single({
    this.initial,
    this.firstDate,
    this.lastDate,
    this.predicate,
    this.onChanged,
  });

  final DateTime? initial;
  final DateTime? firstDate, lastDate;
  final bool Function(DateTime)? predicate;
  final ValueChanged<DateTime>? onChanged;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  late DateTime? value = widget.initial;

  @override
  Widget build(BuildContext context) => DsCalendar(
    value: value,
    currentDate: _today,
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    selectableDayPredicate: widget.predicate,
    onChanged: (d) {
      setState(() => value = d);
      widget.onChanged?.call(d);
    },
  );
}

class _Range extends StatefulWidget {
  const _Range({this.months = 1});

  final int months;

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  DsDateRange? range;
  final reported = <DsDateRange>[];

  @override
  Widget build(BuildContext context) => DsRangeCalendar(
    value: range,
    months: widget.months,
    currentDate: _today,
    onChanged: (r) => setState(() {
      range = r;
      reported.add(r);
    }),
  );
}

/// The full-date label of the focused day.
String? _focusedLabel(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final node = tester.getSemantics(
    find
        .ancestor(
          of: find.byWidget(context.widget),
          matching: find.byType(Semantics),
        )
        .first,
  );
  return node.label;
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

/// The range band boxes drawn (rangeColor fills).
int _bandCount(WidgetTester tester, Color band) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where((b) => (b.decoration as DsBoxDecoration?)?.color == band)
    .length;

void main() {
  const tr = DsLocalizationsTr();

  group('first day of the week', () {
    test('follows the region (CLDR)', () {
      expect(dsFirstDayOfWeek(const Locale('tr')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('de')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('fr')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('ru')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('en', 'US')), DateTime.sunday);
      expect(dsFirstDayOfWeek(const Locale('en')), DateTime.sunday);
      expect(dsFirstDayOfWeek(const Locale('en', 'GB')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('ja')), DateTime.sunday);
      expect(dsFirstDayOfWeek(const Locale('ko')), DateTime.sunday);
      expect(dsFirstDayOfWeek(const Locale('ar')), DateTime.saturday);
      expect(dsFirstDayOfWeek(const Locale('zh')), DateTime.monday);
      expect(dsFirstDayOfWeek(const Locale('pt')), DateTime.sunday);
      expect(
        dsFirstDayOfWeek(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        DateTime.sunday,
      );
    });

    testWidgets('tr starts on Monday', (tester) async {
      await tester.pumpWidget(_localized(const _Single(), strings: tr));
      expect(_headers(tester, tr), ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz']);
      expect(find.text('Ekim 2026'), findsOneWidget);
    });

    testWidgets('en_US starts on Sunday', (tester) async {
      const en = DsLocalizationsEn();
      await tester.pumpWidget(
        _localized(
          const _Single(),
          strings: en,
          locale: const Locale('en', 'US'),
        ),
      );
      expect(_headers(tester, en), ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']);
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('ar starts on Saturday, right to left', (tester) async {
      const ar = DsLocalizationsAr();
      await tester.pumpWidget(
        _localized(const _Single(), strings: ar, direction: TextDirection.rtl),
      );
      final headers = _headers(tester, ar);
      expect(headers.first, ar.weekdayAbbr(DateTime.saturday));
      expect(headers.last, ar.weekdayAbbr(DateTime.friday));
      // Saturday is the rightmost column.
      final sat = tester.getCenter(find.text(headers.first));
      final fri = tester.getCenter(find.text(headers.last));
      expect(sat.dx, greaterThan(fri.dx));
    });

    testWidgets('the first of the month sits under its weekday', (
      tester,
    ) async {
      await tester.pumpWidget(_localized(const _Single(), strings: tr));
      // 1 October 2026 is a Thursday: the fourth column from Monday.
      final first = tester.getCenter(find.text('1'));
      final thursday = tester.getCenter(find.text('Pe'));
      expect(first.dx, moreOrLessEquals(thursday.dx));
    });

    test('every language names months and weekdays', () {
      for (final l10n in dsBundledLocalizations.values) {
        for (var m = 1; m <= 12; m++) {
          expect(l10n.monthName(m), isNotEmpty);
          expect(l10n.monthNameInDate(m), isNotEmpty);
          expect(l10n.monthAbbr(m), isNotEmpty);
        }
        for (var w = 1; w <= 7; w++) {
          expect(l10n.weekdayName(w), isNotEmpty);
          expect(l10n.weekdayAbbr(w), isNotEmpty);
        }
        final format = DsDateFormat(l10n.datePattern, strings: l10n);
        final date = DateTime(2026, 10, 5);
        expect(
          format.tryParse(format.format(date)),
          date,
          reason: l10n.localeName,
        );
      }
    });
  });

  testWidgets('works without DsScope or DsApp', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      host(
        DsCalendar(
          value: null,
          currentDate: _today,
          onChanged: (d) => chosen = d,
        ),
      ),
    );
    await tester.tap(find.text('14'));
    expect(chosen, DateTime(2026, 10, 14));
    expect(tester.takeException(), isNull);
  });

  group('keyboard grid', () {
    Future<void> enter(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(_app(child));
      await _tabToDays(tester);
    }

    testWidgets('one Tab stop that lands on the chosen day', (tester) async {
      await enter(tester, _Single(initial: DateTime(2026, 10, 14)));
      expect(_focusedLabel(tester), '14 Ekim 2026 Çarşamba');
      // The days are one stop: Shift+Tab goes back to the month buttons,
      // Tab from them lands on the same day again.
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_focusedLabel(tester), 'Sonraki ay');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_focusedLabel(tester), startsWith('15 Ekim'));
    });

    testWidgets('lands on today without a chosen day', (tester) async {
      await enter(tester, const _Single());
      expect(_focusedLabel(tester), '5 Ekim 2026 Pazartesi, Bugün');
    });

    testWidgets('arrows move by day and week', (tester) async {
      await enter(tester, _Single(initial: DateTime(2026, 10, 14)));
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(tester), startsWith('15 Ekim'));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedLabel(tester), startsWith('22 Ekim'));
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(tester), startsWith('21 Ekim'));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedLabel(tester), startsWith('14 Ekim'));
    });

    testWidgets('Home and End go to the week ends (Monday first)', (
      tester,
    ) async {
      await enter(tester, _Single(initial: DateTime(2026, 10, 14)));
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedLabel(tester), '12 Ekim 2026 Pazartesi');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedLabel(tester), '18 Ekim 2026 Pazar');
    });

    testWidgets('Page Up/Down change the month, with Shift the year', (
      tester,
    ) async {
      await enter(tester, _Single(initial: DateTime(2026, 10, 31)));
      await _key(tester, LogicalKeyboardKey.pageDown);
      // 31 October + a month: the last day of November.
      expect(_focusedLabel(tester), startsWith('30 Kasım 2026'));
      expect(find.text('Kasım 2026'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.pageUp);
      expect(_focusedLabel(tester), startsWith('30 Ekim 2026'));
      await _key(tester, LogicalKeyboardKey.pageDown, shift: true);
      expect(_focusedLabel(tester), startsWith('30 Ekim 2027'));
      expect(find.text('Ekim 2027'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.pageUp, shift: true);
      expect(_focusedLabel(tester), startsWith('30 Ekim 2026'));
    });

    testWidgets('arrows past the month turn the page', (tester) async {
      await enter(tester, _Single(initial: DateTime(2026, 10, 31)));
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(tester), startsWith('1 Kasım 2026'));
      expect(find.text('Kasım 2026'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(find.text('Ekim 2026'), findsOneWidget);
    });

    testWidgets('right to left mirrors Left and Right', (tester) async {
      await tester.pumpWidget(
        _app(
          _Single(initial: DateTime(2026, 10, 14)),
          direction: TextDirection.rtl,
        ),
      );
      await _tabToDays(tester);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedLabel(tester), startsWith('15 Ekim'));
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(tester), startsWith('13 Ekim'));
    });

    testWidgets('Enter and Space choose the focused day', (tester) async {
      final chosen = <DateTime>[];
      await enter(
        tester,
        _Single(initial: DateTime(2026, 10, 14), onChanged: chosen.add),
      );
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chosen, [DateTime(2026, 10, 15)]);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      // Space chooses on release.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(chosen, hasLength(1));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(chosen.last, DateTime(2026, 10, 16));
    });
  });

  group('disabled days', () {
    testWidgets('predicate, first and last date', (tester) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _localized(
          _Single(
            firstDate: DateTime(2026, 10, 3),
            lastDate: DateTime(2026, 10, 28),
            predicate: (d) => d.weekday != DateTime.sunday,
            onChanged: chosen.add,
          ),
          strings: tr,
        ),
      );
      await tester.tap(find.text('2')); // before firstDate
      await tester.tap(find.text('11')); // a Sunday
      await tester.tap(find.text('29')); // after lastDate
      await tester.pump();
      expect(chosen, isEmpty);
      await tester.tap(find.text('12'));
      expect(chosen, [DateTime(2026, 10, 12)]);

      final sunday = tester.getSemantics(
        find.bySemanticsLabel('11 Ekim 2026 Pazar'),
      );
      expect(sunday.flagsCollection.isEnabled, Tristate.isFalse);
      // The month buttons stop at the bounds.
      final prev = find.bySemanticsLabel('Önceki ay');
      expect(
        tester.getSemantics(prev).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
    });

    testWidgets('the keyboard moves over them; Enter does nothing', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _app(
          _Single(
            initial: DateTime(2026, 10, 10),
            predicate: (d) => d.weekday != DateTime.sunday,
            onChanged: chosen.add,
          ),
        ),
      );
      await _tabToDays(tester);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedLabel(tester), '11 Ekim 2026 Pazar');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chosen, isEmpty);
    });

    testWidgets('a disabled calendar chooses nothing', (tester) async {
      await tester.pumpWidget(
        host(DsCalendar(value: null, currentDate: _today, onChanged: null)),
      );
      final day = tester.getSemantics(
        find.bySemanticsLabel(RegExp('October 14,')),
      );
      expect(day.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('a disabled calendar is no Tab stop and turns no pages', (
      tester,
    ) async {
      final turned = <DateTime>[];
      await tester.pumpWidget(
        _app(
          DsCalendar(
            value: null,
            currentDate: _today,
            onMonthChanged: turned.add,
            onChanged: null,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel ?? '',
        isNot(startsWith('DsCalendar day')),
      );
      await _key(tester, LogicalKeyboardKey.pageDown);
      expect(find.text('Ekim 2026'), findsOneWidget);
      expect(turned, isEmpty);
    });
  });

  group('pages', () {
    testWidgets('an outside day after the last month turns one page', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1200, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DateTime? value;
      final turned = <DateTime>[];
      await tester.pumpWidget(
        _localized(
          StatefulBuilder(
            builder: (context, setState) => DsCalendar(
              value: value,
              months: 2,
              showOutsideDays: true,
              initialMonth: DateTime(2026, 10),
              currentDate: _today,
              onMonthChanged: turned.add,
              onChanged: (d) => setState(() => value = d),
            ),
          ),
          strings: tr,
        ),
      );
      // October | November; November's last row holds 1–5 December.
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();
      expect(value, DateTime(2026, 12, 5));
      expect(turned, [DateTime(2026, 11)]);
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(find.text('Aralık 2026'), findsOneWidget);
    });

    testWidgets('a page turned by a new value is reported', (tester) async {
      final turned = <DateTime>[];
      late StateSetter set;
      DateTime? value = _today;
      await tester.pumpWidget(
        _localized(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return DsCalendar(
                value: value,
                currentDate: _today,
                onMonthChanged: turned.add,
                onChanged: (d) => setState(() => value = d),
              );
            },
          ),
          strings: tr,
        ),
      );
      set(() => value = DateTime(2027, 3, 3));
      await tester.pumpAndSettle();
      expect(find.text('Mart 2027'), findsOneWidget);
      expect(turned, [DateTime(2027, 3)]);
    });
  });

  group('range', () {
    testWidgets('start, preview under the pointer, end', (tester) async {
      final band = DsThemeData().colors.accentTint;
      await tester.pumpWidget(_localized(const _Range(), strings: tr));
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(state.reported.single, DsDateRange(start: DateTime(2026, 10, 12)));
      expect(_bandCount(tester, band), 0);
      await hover(tester, find.text('16'));
      // 12 to 16 previewed: five days in the band.
      expect(_bandCount(tester, band), 5);
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(
        state.reported.last,
        DsDateRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 16)),
      );
      expect(_bandCount(tester, band), 5);
      expect(
        find.bySemanticsLabel('12 Ekim 2026 Pazartesi, Başlangıç tarihi'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('14 Ekim 2026 Çarşamba, Aralıkta'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('16 Ekim 2026 Cuma, Bitiş tarihi'),
        findsOneWidget,
      );
    });

    testWidgets('an end before the start swaps them; a third choice '
        'starts over', (tester) async {
      await tester.pumpWidget(_localized(const _Range(), strings: tr));
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(find.text('20'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      expect(
        state.reported.last,
        DsDateRange(start: DateTime(2026, 10, 8), end: DateTime(2026, 10, 20)),
      );
      await tester.tap(find.text('25'));
      await tester.pump();
      expect(state.reported.last, DsDateRange(start: DateTime(2026, 10, 25)));
    });

    test('a range takes its ends by date and keeps a UTC start UTC', () {
      final utc = DsDateRange(
        start: DateTime.utc(2026, 10, 5, 22),
        end: DateTime.utc(2026, 10, 6, 1),
      );
      expect(utc.start, DateTime.utc(2026, 10, 5));
      expect(utc.end, DateTime.utc(2026, 10, 6));
      expect(utc.contains(DateTime(2026, 10, 6, 23)), isTrue);
      expect(utc.contains(DateTime(2026, 10, 7)), isFalse);
      // The end follows the start's kind: the day its date reads.
      final local = DsDateRange(
        start: DateTime(2026, 10, 5),
        end: DateTime.utc(2026, 10, 5),
      );
      expect(local.end, DateTime(2026, 10, 5));
    });

    test('a one-day range with a UTC end is valid west of UTC', () {
      // Fails only where midnight UTC is the day before: run with
      // TZ=America/New_York.
      final range = DsDateRange(
        start: DateTime(2026, 10, 5),
        end: DateTime.utc(2026, 10, 5),
      );
      expect(range.end, DateTime(2026, 10, 5));
    }, skip: !_today.timeZoneOffset.isNegative);

    testWidgets('a UTC range stays UTC and bands its own days', (tester) async {
      final band = DsThemeData().colors.accentTint;
      var range = DsDateRange(start: DateTime.utc(2026, 10, 12));
      await tester.pumpWidget(
        _localized(
          StatefulBuilder(
            builder: (context, setState) => DsRangeCalendar(
              value: range,
              currentDate: _today,
              onChanged: (r) => setState(() => range = r),
            ),
          ),
          strings: tr,
        ),
      );
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(
        range,
        DsDateRange(
          start: DateTime.utc(2026, 10, 12),
          end: DateTime.utc(2026, 10, 16),
        ),
      );
      expect(_bandCount(tester, band), 5);
    });

    testWidgets('the keyboard previews too', (tester) async {
      final band = DsThemeData().colors.accentTint;
      await tester.pumpWidget(_app(const _Range()));
      await _tabToDays(tester);
      await _key(tester, LogicalKeyboardKey.enter); // starts at today, 5
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_bandCount(tester, band), 3);
    });

    testWidgets('two months side by side', (tester) async {
      tester.view
        ..physicalSize = const Size(1200, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_localized(const _Range(months: 2), strings: tr));
      expect(find.text('Ekim 2026'), findsOneWidget);
      expect(find.text('Kasım 2026'), findsOneWidget);
      // One pair of month buttons, after the last month.
      expect(find.bySemanticsLabel('Sonraki ay'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sonraki ay'));
      await tester.pumpAndSettle();
      expect(find.text('Kasım 2026'), findsOneWidget);
      expect(find.text('Aralık 2026'), findsOneWidget);
    });
  });

  test('days stay readable on the range band (AA), today too', () {
    for (final seed in const [
      DsSeed.blue,
      DsSeed.navy,
      DsSeed.graphite,
      DsSeed.oxblood,
      DsSeed.forest,
      DsSeed.indigo,
    ]) {
      for (final brightness in Brightness.values) {
        final theme = DsThemeData(seed: seed, brightness: brightness);
        final k = theme.colors;
        final band = DsColorUtils.flatten(k.accentTint, k.overlay);
        for (final ink in [k.text, k.accentText]) {
          expect(
            DsColorUtils.contrastRatio(ink, band),
            greaterThanOrEqualTo(4.5),
            reason: '$seed $brightness',
          );
        }
      }
    }
  });

  group('semantics', () {
    testWidgets('days read their full date; chosen and today', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _localized(_Single(initial: DateTime(2026, 10, 14)), strings: tr),
      );
      final chosen = tester.getSemantics(
        find.bySemanticsLabel('14 Ekim 2026 Çarşamba'),
      );
      expect(chosen.flagsCollection.isSelected, Tristate.isTrue);
      expect(chosen.flagsCollection.isButton, isTrue);
      expect(
        find.bySemanticsLabel('5 Ekim 2026 Pazartesi, Bugün'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('English reads the US way', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsCalendar(
            value: DateTime(2026, 10, 14),
            currentDate: _today,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Wednesday, October 14, 2026'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the month title is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_localized(const _Single(), strings: tr));
      await tester.tap(find.bySemanticsLabel('Sonraki ay'));
      await tester.pumpAndSettle();
      final title = tester.getSemantics(find.text('Kasım 2026'));
      expect(title.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('motion', () {
    /// The largest sideways shift of the month grids mid-turn.
    Future<double> midTurnShift(WidgetTester tester, DsThemeData theme) async {
      await tester.pumpWidget(
        _localized(const _Single(), strings: tr, theme: theme),
      );
      await tester.tap(find.bySemanticsLabel('Sonraki ay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      var shift = 0.0;
      for (final t in tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(DsCalendar),
          matching: find.byType(Transform),
        ),
      )) {
        final dx = t.transform.getTranslation().x.abs();
        if (dx > shift) shift = dx;
      }
      await tester.pumpAndSettle();
      return shift;
    }

    testWidgets('a new month slides in', (tester) async {
      expect(await midTurnShift(tester, DsThemeData()), greaterThan(1));
    });

    testWidgets('reduced motion: it only fades', (tester) async {
      final theme = DsThemeData();
      final reduced = theme.copyWith(
        motion: theme.motion.copyWith(reduced: true),
      );
      expect(await midTurnShift(tester, reduced), 0);
      expect(find.text('Kasım 2026'), findsOneWidget);
    });
  });

  group('size', () {
    testWidgets('days are the density day size with tap areas around', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localized(
          const _Single(),
          strings: tr,
          theme: DsThemeData(density: DsDensity.touch),
        ),
      );
      final day = find.ancestor(
        of: find.text('14'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(day), const Size(38, 38));
      // Neighbours sit a tap target apart.
      final a = tester.getCenter(find.text('14'));
      final b = tester.getCenter(find.text('15'));
      expect(b.dx - a.dx, greaterThanOrEqualTo(44));
    });

    testWidgets('text scale 2.0: days grow, nothing overflows', (tester) async {
      tester.view.physicalSize = const Size(358, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _localized(const _Range(), strings: tr, textScale: 2),
      );
      expect(tester.takeException(), isNull);
      final day = find.ancestor(
        of: find.text('14'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(day).width, greaterThan(32));
      expect(tester.getSize(find.byType(DsRangeCalendar)).width, lessThan(358));
    });
  });

  group('day marks', () {
    /// The drawn day box holding the number [day].
    DsBoxDecoration box(WidgetTester tester, String day) =>
        tester
                .widget<AnimatedContainer>(
                  find.ancestor(
                    of: find.text(day),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as DsBoxDecoration;

    Color? ink(WidgetTester tester, String day) =>
        tester.widget<Text>(find.text(day)).style?.color;

    List<Color> rings(DsBoxDecoration d) => [
      for (final s in d.shadows)
        if (s.inset) s.color,
    ];

    for (final selection in DsSelectionStyle.values) {
      testWidgets('the chosen day is solid under ${selection.name}', (
        tester,
      ) async {
        final theme = DsThemeData(selectionStyle: selection);
        final k = theme.colors;
        await tester.pumpWidget(
          _localized(
            theme: theme,
            DsCalendar(
              value: DateTime(2026, 10, 12),
              currentDate: _today,
              onChanged: (_) {},
            ),
          ),
        );
        expect(box(tester, '12').color, k.accent);
        expect(ink(tester, '12'), k.onAccent);
        // Hover takes the accent hover step, as on a checked box.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.text('12')));
        await tester.pumpAndSettle();
        expect(box(tester, '12').color, k.accentHover);
      });

      testWidgets('both range ends are solid under ${selection.name}', (
        tester,
      ) async {
        final theme = DsThemeData(selectionStyle: selection);
        final k = theme.colors;
        await tester.pumpWidget(
          _localized(
            theme: theme,
            DsRangeCalendar(
              value: DsDateRange(
                start: DateTime(2026, 10, 12),
                end: DateTime(2026, 10, 18),
              ),
              currentDate: _today,
              onChanged: (_) {},
            ),
          ),
        );
        for (final end in ['12', '18']) {
          expect(box(tester, end).color, k.accent, reason: end);
          expect(ink(tester, end), k.onAccent, reason: end);
        }
        // The days between stay on the band, unfilled.
        expect(box(tester, '15').color!.a, 0);
        expect(_bandCount(tester, k.accentTint), 7);
      });
    }

    testWidgets('a bright accent: dark label and the accent edge', (
      tester,
    ) async {
      final theme = DsThemeData(seed: DsSeed.color(const Color(0xFFFFC72C)));
      final k = theme.colors;
      expect(k.accentEdge.a, greaterThan(0));
      await tester.pumpWidget(
        _localized(
          theme: theme,
          DsRangeCalendar(
            value: DsDateRange(
              start: DateTime(2026, 10, 12),
              end: DateTime(2026, 10, 18),
            ),
            currentDate: _today,
            onChanged: (_) {},
          ),
        ),
      );
      for (final end in ['12', '18']) {
        expect(box(tester, end).color, k.accent);
        expect(ink(tester, end), k.onAccent);
        expect(rings(box(tester, end)), [k.accentEdge]);
      }
    });

    testWidgets('a near-status seed chooses in its accent, not the deep '
        'strong selection', (tester) async {
      for (final brightness in Brightness.values) {
        final theme = DsThemeData(
          seed: DsSeed.oxblood,
          brightness: brightness,
          selectionStyle: DsSelectionStyle.strong,
        );
        final k = theme.colors;
        // The strong selection is the brand's deep ink here.
        expect(k.selectionStrong, isNot(k.accent));
        await tester.pumpWidget(
          _localized(
            theme: theme,
            DsCalendar(
              value: DateTime(2026, 10, 12),
              currentDate: _today,
              onChanged: (_) {},
            ),
          ),
        );
        expect(box(tester, '12').color, k.accent, reason: brightness.name);
        expect(ink(tester, '12'), k.onAccent, reason: brightness.name);
      }
    });

    testWidgets('today: accent bold number inside a ring of its color', (
      tester,
    ) async {
      final theme = DsThemeData();
      final k = theme.colors;
      await tester.pumpWidget(
        _localized(
          theme: theme,
          DsCalendar(
            value: DateTime(2026, 10, 12),
            currentDate: _today,
            onChanged: (_) {},
          ),
        ),
      );
      expect(ink(tester, '5'), k.accentText);
      expect(
        tester.widget<Text>(find.text('5')).style?.fontWeight,
        FontWeight.w600,
      );
      expect(rings(box(tester, '5')), [k.accentText]);
      expect(box(tester, '5').color!.a, 0);
      // Not color alone: the ring stands 3:1 off the card and the popup.
      for (final bg in [k.surface, k.overlay, k.canvas]) {
        expect(
          DsColorUtils.contrastRatio(k.accentText, bg),
          greaterThanOrEqualTo(3),
        );
      }
      // Other days have no ring.
      expect(rings(box(tester, '6')), isEmpty);
    });

    testWidgets('a chosen today is only filled', (tester) async {
      final theme = DsThemeData();
      final k = theme.colors;
      await tester.pumpWidget(
        _localized(
          theme: theme,
          DsCalendar(value: _today, currentDate: _today, onChanged: (_) {}),
        ),
      );
      expect(box(tester, '5').color, k.accent);
      expect(ink(tester, '5'), k.onAccent);
      expect(rings(box(tester, '5')), isEmpty);
    });

    testWidgets('today on the range band keeps its ring', (tester) async {
      final theme = DsThemeData();
      final k = theme.colors;
      await tester.pumpWidget(
        _localized(
          theme: theme,
          DsRangeCalendar(
            value: DsDateRange(
              start: DateTime(2026, 10, 2),
              end: DateTime(2026, 10, 8),
            ),
            currentDate: _today,
            onChanged: (_) {},
          ),
        ),
      );
      expect(rings(box(tester, '5')), [k.accentText]);
      expect(ink(tester, '5'), k.accentText);
    });

    testWidgets('a disabled today keeps the strikethrough and no ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localized(
          theme: DsThemeData(),
          DsCalendar(
            value: null,
            currentDate: _today,
            firstDate: DateTime(2026, 10, 6),
            onChanged: (_) {},
          ),
        ),
      );
      expect(rings(box(tester, '5')), isEmpty);
      expect(
        tester.widget<Text>(find.text('5')).style?.decoration,
        TextDecoration.lineThrough,
      );
    });
  });

  // The band draws no line at any level; a style can still ask for one.
  group('range band edge', () {
    int edges(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where(
          (b) =>
              b.decoration is DsBoxDecoration &&
              (b.decoration as DsBoxDecoration).color == null &&
              (b.decoration as DsBoxDecoration).shadows.any((s) => s.inset),
        )
        .length;

    Widget range(DsThemeData theme, {DsCalendarStyle? style}) => _localized(
      theme: theme,
      DsRangeCalendar(
        value: DsDateRange(
          start: DateTime(2026, 10, 12),
          end: DateTime(2026, 10, 18),
        ),
        currentDate: _today,
        style: style,
        onChanged: (_) {},
      ),
    );

    for (final contrast in DsContrast.values) {
      testWidgets('none at ${contrast.name} contrast', (tester) async {
        final theme = DsThemeData(contrast: contrast);
        await tester.pumpWidget(range(theme));
        expect(DsCalendar.defaultStyle(theme).rangeEdgeColor!.a, 0);
        expect(edges(tester), 0);
      });
    }

    testWidgets('a style that sets one draws it along the band', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        range(
          theme,
          style: DsCalendarStyle(rangeEdgeColor: theme.colors.onSelection),
        ),
      );
      // One edge segment per banded day (12–18).
      expect(edges(tester), 7);
    });
  });
}
