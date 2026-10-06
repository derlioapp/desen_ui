// Numeric date conventions come from the locale's region and
// language (CLDR), whatever strings are bundled; formats round-trip.
import 'dart:math';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DsDateLocale> _localeIn(WidgetTester tester, Locale locale) async {
  late DsDateLocale found;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          found = DsDateLocale.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return found;
}

void main() {
  final march4 = DateTime(2026, 3, 4);
  // locale: pattern, first day, 24-hour, March 4 shown, hint.
  final cases = {
    const Locale('pl', 'PL'): (
      'd.MM.y',
      DateTime.monday,
      true,
      '4.03.2026',
      'DD.MM.YYYY',
    ),
    const Locale('nl', 'NL'): (
      'd-M-y',
      DateTime.monday,
      true,
      '4-3-2026',
      'DD-MM-YYYY',
    ),
    const Locale('sv', 'SE'): (
      'y-MM-dd',
      DateTime.monday,
      true,
      '2026-03-04',
      'YYYY-MM-DD',
    ),
    const Locale('en', 'GB'): (
      'dd/MM/y',
      DateTime.monday,
      true,
      '04/03/2026',
      'DD/MM/YYYY',
    ),
    const Locale('en', 'US'): (
      'M/d/y',
      DateTime.sunday,
      false,
      '3/4/2026',
      'MM/DD/YYYY',
    ),
    const Locale('de', 'CH'): (
      'dd.MM.y',
      DateTime.monday,
      true,
      '04.03.2026',
      'TT.MM.JJJJ',
    ),
    const Locale('ja', 'JP'): (
      'y/MM/dd',
      DateTime.sunday,
      true,
      '2026/03/04',
      'YYYY/MM/DD',
    ),
    const Locale('zh', 'CN'): (
      'y/M/d',
      DateTime.monday,
      true,
      '2026/3/4',
      'YYYY/MM/DD',
    ),
  };

  group('conventions by locale', () {
    for (final MapEntry(key: locale, value: c) in cases.entries) {
      testWidgets('$locale', (tester) async {
        final d = await _localeIn(tester, locale);
        final (pattern, firstDay, uses24, shown, hint) = c;
        expect(d.datePattern, pattern);
        expect(d.firstDayOfWeek, firstDay);
        expect(d.uses24HourClock, uses24);
        expect(d.shortDate.format(march4), shown);
        expect(d.dateHint, hint);
        expect(d.shortDate.tryParse(shown), march4);
      });
    }

    test('dsDatePattern: region, then language, then ISO', () {
      expect(dsDatePattern(const Locale('fr', 'CA')), 'y-MM-dd');
      expect(dsDatePattern(const Locale('en', 'ZA')), 'y/MM/dd');
      expect(dsDatePattern(const Locale('en', 'AU')), 'dd/MM/y');
      expect(dsDatePattern(const Locale('en', 'PH')), 'M/d/y');
      expect(dsDatePattern(const Locale('nl', 'BE')), 'd/M/y');
      expect(dsDatePattern(const Locale('hu')), 'y. MM. dd.');
      expect(dsDatePattern(const Locale('xx')), 'y-MM-dd');
    });

    test('a regional variant of a bundled language keeps its words', () {
      final fr = DsDateLocale.resolve(
        const Locale('fr', 'CA'),
        const DsLocalizationsFr(),
      );
      expect(fr.datePattern, 'y-MM-dd');
      expect(fr.dateHint, 'AAAA-MM-JJ');
      final tr = DsDateLocale.resolve(
        const Locale('tr', 'TR'),
        const DsLocalizationsTr(),
      );
      expect(tr.datePattern, 'dd.MM.y');
      expect(tr.dateHint, 'GG.AA.YYYY');
    });

    test('strings for an unbundled language that leave the English '
        'pattern do not make it month-first', () {
      final d = DsDateLocale.resolve(
        const Locale('pl', 'PL'),
        const _PolishWords(),
      );
      expect(d.datePattern, 'd.MM.y');
    });

    testWidgets('a forced bundled language keeps its own conventions', (
      tester,
    ) async {
      late DsDateLocale d;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en', 'US'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: DsLocalizationScope(
            localizations: const DsLocalizationsTr(),
            child: Builder(
              builder: (context) {
                d = DsDateLocale.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(d.datePattern, 'dd.MM.y');
      expect(d.firstDayOfWeek, DateTime.monday);
      expect(d.uses24HourClock, isTrue);
    });

    testWidgets('a Polish app: 3/4/2026 typed is 3 April, weeks start '
        'Monday, 24-hour clock', (tester) async {
      DateTime? value;
      const pl = Locale('pl', 'PL');
      await tester.pumpWidget(
        DsApp(
          theme: DsThemeData(),
          locale: pl,
          supportedLocales: const [pl, Locale('en')],
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsDatePicker(value: null, onChanged: (d) => value = d),
                  DsTimePicker(value: const DsTime(15, 5), onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('15:05'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, '3/4/2026');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(value, DateTime(2026, 4, 3));
      expect(find.text('3.04.2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Choose date').first);
      await tester.pumpAndSettle();
      final calendar = tester.widget<DsCalendar>(find.byType(DsCalendar));
      expect(calendar.value, DateTime(2026, 4, 3));
      // The first column is Monday ("Mo" in the English words).
      final mo = tester.getTopLeft(find.text('Mo'));
      final su = tester.getTopLeft(find.text('Su'));
      expect(mo.dx, lessThan(su.dx));
    });
  });

  // Expected values from CLDR 47 (ICU 77), Wednesday 4 March 2026:
  // - clock: the hour cycle of the locale's time format (timeFormats/short);
  // - short: the numeric date, CLDR yMd or the short date format with a
  //   four-digit year (de, ja and en_IN pad the day and month);
  // - medium: availableFormats/yMMMd;
  // - full: dateFormats/full.
  final cldr = <Locale, (bool, String, String, String)>{
    const Locale('en', 'US'): (
      false,
      '3/4/2026',
      'Mar 4, 2026',
      'Wednesday, March 4, 2026',
    ),
    const Locale('en', 'GB'): (
      true,
      '04/03/2026',
      '4 Mar 2026',
      'Wednesday, 4 March 2026',
    ),
    const Locale('en', 'AU'): (
      false,
      '04/03/2026',
      '4 Mar 2026',
      'Wednesday, 4 March 2026',
    ),
    const Locale('en', 'CA'): (
      false,
      '2026-03-04',
      'Mar 4, 2026',
      'Wednesday, March 4, 2026',
    ),
    const Locale('en', 'IN'): (
      false,
      '04/03/2026',
      '4 Mar 2026',
      'Wednesday, 4 March 2026',
    ),
    const Locale('fr', 'FR'): (
      true,
      '04/03/2026',
      '4 mars 2026',
      'mercredi 4 mars 2026',
    ),
    const Locale('fr', 'CA'): (
      true,
      '2026-03-04',
      '4 mars 2026',
      'mercredi 4 mars 2026',
    ),
    const Locale('de', 'DE'): (
      true,
      '04.03.2026',
      '4. März 2026',
      'Mittwoch, 4. März 2026',
    ),
    const Locale('de', 'AT'): (
      true,
      '04.03.2026',
      '4. März 2026',
      'Mittwoch, 4. März 2026',
    ),
    const Locale('de', 'CH'): (
      true,
      '04.03.2026',
      '4. März 2026',
      'Mittwoch, 4. März 2026',
    ),
    const Locale('es', 'ES'): (
      true,
      '4/3/2026',
      '4 mar 2026',
      'miércoles, 4 de marzo de 2026',
    ),
    const Locale('es', 'MX'): (
      false,
      '4/3/2026',
      '4 mar 2026',
      'miércoles, 4 de marzo de 2026',
    ),
    const Locale('pt', 'BR'): (
      true,
      '04/03/2026',
      '4 de mar. de 2026',
      'quarta-feira, 4 de março de 2026',
    ),
    const Locale('pt', 'PT'): (
      true,
      '04/03/2026',
      '4/03/2026',
      'quarta-feira, 4 de março de 2026',
    ),
    const Locale('it', 'IT'): (
      true,
      '04/03/2026',
      '4 mar 2026',
      'mercoledì 4 marzo 2026',
    ),
    const Locale('ru'): (
      true,
      '04.03.2026',
      '4 мар. 2026 г.',
      'среда, 4 марта 2026 г.',
    ),
    const Locale('ar'): (
      false,
      '4‏/3‏/2026',
      '4 مارس 2026',
      'الأربعاء، 4 مارس 2026',
    ),
    const Locale('hi'): (
      false,
      '4/3/2026',
      '4 मार्च 2026',
      'बुधवार, 4 मार्च 2026',
    ),
    const Locale('ja'): (true, '2026/03/04', '2026年3月4日', '2026年3月4日水曜日'),
    const Locale('ko'): (
      false,
      '2026. 3. 4.',
      '2026년 3월 4일',
      '2026년 3월 4일 수요일',
    ),
    const Locale('zh'): (true, '2026/3/4', '2026年3月4日', '2026年3月4日星期三'),
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'): (
      false,
      '2026/3/4',
      '2026年3月4日',
      '2026年3月4日 星期三',
    ),
    const Locale('tr'): (
      true,
      '04.03.2026',
      '4 Mar 2026',
      '4 Mart 2026 Çarşamba',
    ),
  };

  group('CLDR clock and dates', () {
    for (final MapEntry(key: locale, value: c) in cldr.entries) {
      test('$locale', () {
        final d = DsDateLocale.resolve(locale, DsLocalizations.resolve(locale));
        final (uses24, short, medium, full) = c;
        expect(dsUses24HourClock(locale), uses24, reason: 'clock');
        expect(d.uses24HourClock, uses24, reason: 'clock');
        expect(d.shortDate.format(march4), short, reason: 'short');
        expect(d.mediumDate.format(march4), medium, reason: 'medium');
        expect(d.fullDate.format(march4), full, reason: 'full');
      });
    }

    test('the clock goes by language and region (CLDR 47)', () {
      final clocks = {
        const Locale('en', 'IE'): true,
        const Locale('en', 'DE'): true,
        const Locale('en', 'PH'): false,
        const Locale('fr', 'CH'): true,
        const Locale('fr', 'TN'): false,
        const Locale('es', 'US'): false,
        const Locale('es', 'AR'): false,
        const Locale('ar', 'MA'): true,
        const Locale('ar', 'SA'): false,
        const Locale('ko', 'CN'): true,
        const Locale('pt', 'MO'): false,
        const Locale('tr', 'CY'): false,
        const Locale('zh', 'TW'): false,
        const Locale('zh', 'SG'): false,
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        ): false,
        // A language Desen has no words for: the region's hour cycle.
        const Locale('pl', 'PL'): true,
        const Locale('ta', 'IN'): false,
      };
      for (final MapEntry(key: locale, value: uses24) in clocks.entries) {
        expect(dsUses24HourClock(locale), uses24, reason: '$locale');
      }
    });

    test('regional medium and full dates (CLDR 47)', () {
      String medium(Locale l) => DsDateLocale.resolve(
        l,
        DsLocalizations.resolve(l),
      ).mediumDate.format(march4);
      String full(Locale l) => DsDateLocale.resolve(
        l,
        DsLocalizations.resolve(l),
      ).fullDate.format(march4);
      expect(medium(const Locale('en', 'ZA')), '04 Mar 2026');
      expect(full(const Locale('en', 'ZA')), 'Wednesday, 04 March 2026');
      expect(full(const Locale('en', 'IE')), 'Wednesday 4 March 2026');
      expect(medium(const Locale('en', 'PH')), 'Mar 4, 2026');
      expect(full(const Locale('fr', 'CH')), 'mercredi, 4 mars 2026');
      expect(medium(const Locale('es', 'AR')), '4 de mar de 2026');
      expect(full(const Locale('zh', 'TW')), '2026年3月4日 星期三');
      expect(full(const Locale('zh', 'HK')), '2026年3月4日星期三');
      // English words in a Polish app read day first, as en_001.
      expect(medium(const Locale('pl', 'PL')), '4 Mar 2026');
    });
  });

  group('round trips', () {
    const langs = [
      'en', 'tr', 'de', 'fr', 'es', 'it', 'pt', 'ru', 'ar', 'hi', 'ja', 'ko', //
      'zh',
    ];
    final locales = [
      for (final l in langs) Locale(l),
      ...cases.keys,
      ...cldr.keys,
      const Locale('en', 'ZW'),
      const Locale('es', 'DO'),
    ];

    test('dates in years 1..9999, short and medium, every locale', () {
      final rnd = Random(1);
      final failures = <String>[];
      for (final locale in locales) {
        final strings = DsLocalizations.resolve(locale);
        final d = DsDateLocale.resolve(locale, strings);
        for (var i = 0; i < 200; i++) {
          final year = i < 40 ? 1 + rnd.nextInt(999) : 1 + rnd.nextInt(9999);
          final date = DateTime(year, 1 + rnd.nextInt(12), 1 + rnd.nextInt(28));
          for (final f in [d.shortDate, d.mediumDate]) {
            final s = f.format(date);
            final back = f.tryParse(s, today: DateTime(2026, 10, 5));
            if (back != date) failures.add('$locale ${f.pattern}: $s -> $back');
          }
        }
      }
      expect(failures.take(10), isEmpty, reason: '${failures.length}');
    });

    test('times on both clocks, every locale', () {
      final failures = <String>[];
      for (final locale in locales) {
        final d = DsDateLocale.resolve(locale, DsLocalizations.resolve(locale));
        for (final use24 in [true, false]) {
          final f = d.timeFormat(use24HourClock: use24);
          for (var h = 0; h < 24; h++) {
            for (final m in [0, 7, 30, 59]) {
              final t = DsTime(h, m);
              final back = f.tryParseTime(f.formatTime(t));
              if (back != t) failures.add('$locale $use24 $t -> $back');
            }
          }
        }
      }
      expect(failures.take(10), isEmpty, reason: '${failures.length}');
    });

    test('grouped numbers, every locale and a few regions', () {
      final rnd = Random(2);
      final failures = <String>[];
      for (final locale in [
        ...locales,
        const Locale('fr', 'CA'),
        const Locale('pt', 'PT'),
      ]) {
        final f = const DsNumberFormat(
          decimals: 2,
          grouping: true,
        ).forLocale(locale);
        for (var i = 0; i < 200; i++) {
          final v = ((rnd.nextDouble() - .5) * 1e11).round() / 100;
          final back = f.tryParse(f.format(v));
          if (back != v) failures.add('$locale: $v -> $back');
        }
      }
      expect(failures.take(10), isEmpty, reason: '${failures.length}');
    });
  });
}

/// An app's own Polish words that extend English and leave its patterns.
class _PolishWords extends DsLocalizationsEn {
  const _PolishWords();

  @override
  String get localeName => 'pl';

  @override
  String get today => 'Dzisiaj';
}
