import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../../l10n/strings/en.dart';
import '../text_field/typed_field.dart';
import 'date_format.dart';

/// The calendar conventions of a locale: the words (from
/// [DsLocalizations]), the first day of the week (from the region,
/// [dsFirstDayOfWeek]), the 12- or 24-hour clock (from the language and
/// region, [dsUses24HourClock]), and the date and time formats. What the
/// calendar and the date and time pickers read.
///
/// ```dart
/// final locale = DsDateLocale.of(context);
/// locale.shortDate.format(DateTime(2026, 10, 5)); // '05.10.2026' (tr)
/// locale.firstDayOfWeek; // DateTime.monday (tr)
/// ```
@immutable
class DsDateLocale {
  /// Creates calendar conventions from their parts.
  const DsDateLocale({
    required this.strings,
    required this.firstDayOfWeek,
    required this.uses24HourClock,
    required this.datePattern,
    required this.dateHint,
    this.mediumDatePattern,
    this.fullDatePattern,
  });

  /// The conventions for [locale], naming months and weekdays in
  /// [strings]. Every numeric convention comes from [locale], whatever
  /// strings are bundled for it (CLDR):
  ///
  /// - the first day of the week from its region (or, without one, the
  ///   language's usual region: US for English, Egypt for Arabic, Taiwan
  ///   for Traditional Chinese, Poland for Polish);
  /// - the clock from its language and region ([dsUses24HourClock]), so
  ///   Canadian French reads 14:30 and Canadian English 2:30 PM;
  /// - the numeric date pattern ([dsDatePattern]): the order of day, month
  ///   and year and their separators, so Polish reads `4.03.2026`, Dutch
  ///   `4-03-2026`, Swedish `2026-03-04` and British English `04/03/2026`
  ///   even with English month names.
  ///
  /// When [strings] are in [locale]'s language and say how that language
  /// writes a date, their pattern (with the region's variant, e.g. `en_GB`
  /// or `fr_CA`) and hint are used; otherwise the hint is built from the
  /// pattern in [strings]' hint letters ("DD.MM.YYYY").
  ///
  /// The medium and full dates are [strings]' patterns, or the variant
  /// CLDR gives [strings]' language in [locale]'s region: British,
  /// Australian or Indian English read `4 Mar 2026` and
  /// `Wednesday, 4 March 2026`, European Portuguese `4/03/2026`, Swiss
  /// French `mercredi, 4 mars 2026`.
  factory DsDateLocale.resolve(Locale locale, DsLocalizations strings) {
    final language = locale.languageCode;
    final own = strings.localeName.split('_').first == language;
    // Strings that extend English without their own pattern say nothing
    // about how their language writes a date.
    const en = DsLocalizationsEn();
    final saysPattern =
        own && (language == 'en' || strings.datePattern != en.datePattern);
    final regional = _regionalPattern(locale);
    String pattern;
    String hint;
    if (saysPattern && regional == null) {
      pattern = strings.datePattern;
      hint = strings.dateHint;
    } else {
      pattern = regional ?? dsDatePattern(locale);
      hint = _hintFor(pattern, strings);
    }
    final (medium, full) = _regionalLongDates(
      strings.localeName.split('_').first,
      _regionOf(locale),
    );
    return DsDateLocale(
      strings: strings,
      firstDayOfWeek: dsFirstDayOfWeek(locale),
      uses24HourClock: dsUses24HourClock(locale),
      datePattern: pattern,
      dateHint: hint,
      mediumDatePattern: medium,
      fullDatePattern: full,
    );
  }

  /// The conventions where [context] is: the words of
  /// [DsLocalizations.of], the numbers of [localeOf]. Without an app (no
  /// `Localizations`), US English.
  static DsDateLocale of(BuildContext context) {
    final strings = DsLocalizations.of(context);
    return DsDateLocale.resolve(localeOf(context, strings), strings);
  }

  /// The locale whose conventions apply where [context] is: the app's
  /// locale, which carries the region, unless [strings] were chosen in
  /// another bundled language (a `DsLocalizationScope` forcing Turkish in
  /// an English app); then the strings' own ('tr', 'pt_PT', 'zh_Hant').
  /// An app in a language without bundled strings (Polish, Dutch) keeps
  /// its locale while the words fall back to English.
  static Locale localeOf(BuildContext context, DsLocalizations strings) =>
      dsConventionsLocale(context, strings);

  /// Month and weekday names, AM/PM and the other patterns.
  final DsLocalizations strings;

  /// The first column of a calendar week: [DateTime.monday] …
  /// [DateTime.sunday].
  final int firstDayOfWeek;

  /// Whether times read 14:30 rather than 2:30 PM.
  final bool uses24HourClock;

  /// The numeric date pattern a date field shows and reads.
  final String datePattern;

  /// The placeholder of an empty date field ("GG.AA.YYYY").
  final String dateHint;

  /// The pattern of [mediumDate]; null takes [strings]'
  /// [DsLocalizations.dateMediumPattern].
  final String? mediumDatePattern;

  /// The pattern of [fullDate]; null takes [strings]'
  /// [DsLocalizations.dateFullPattern].
  final String? fullDatePattern;

  /// The numeric date a date field shows and reads: `05.10.2026`.
  DsDateFormat get shortDate => DsDateFormat(datePattern, strings: strings);

  /// A date with a short month name (CLDR's `yMMMd`): `5 Eki 2026`;
  /// `Oct 5, 2026` in the US, `5 Oct 2026` in Britain.
  DsDateFormat get mediumDate => DsDateFormat(
    mediumDatePattern ?? strings.dateMediumPattern,
    strings: strings,
  );

  /// A date as screen readers hear it (CLDR's full date):
  /// `5 Ekim 2026 Pazartesi`; `Monday, 5 October 2026` in Britain.
  DsDateFormat get fullDate => DsDateFormat(
    fullDatePattern ?? strings.dateFullPattern,
    strings: strings,
  );

  /// A calendar header: `Ekim 2026`.
  DsDateFormat get monthYear =>
      DsDateFormat(strings.monthYearPattern, strings: strings);

  /// A time of day: `14:30`, or `2:30 PM` on a 12-hour clock.
  DsDateFormat get time => timeFormat(use24HourClock: uses24HourClock);

  /// A time of day on the given clock, with [seconds] (`14:30:05`,
  /// `2:30:05 PM`) or without.
  ///
  /// Every bundled language writes the seconds after the minutes with a
  /// colon (CLDR's medium time), so they are added to the short pattern.
  DsDateFormat timeFormat({
    required bool use24HourClock,
    bool seconds = false,
  }) {
    final pattern = use24HourClock ? 'HH:mm' : strings.timePattern12;
    return DsDateFormat(
      seconds ? pattern.replaceFirst('mm', 'mm:ss') : pattern,
      strings: strings,
    );
  }

  /// The weekdays in calendar column order, from [firstDayOfWeek].
  List<int> get weekdays => [
    for (var i = 0; i < 7; i++) (firstDayOfWeek - 1 + i) % 7 + 1,
  ];

  @override
  bool operator ==(Object other) =>
      other is DsDateLocale &&
      identical(other.strings, strings) &&
      other.firstDayOfWeek == firstDayOfWeek &&
      other.uses24HourClock == uses24HourClock &&
      other.datePattern == datePattern &&
      other.dateHint == dateHint &&
      other.mediumDatePattern == mediumDatePattern &&
      other.fullDatePattern == fullDatePattern;

  @override
  int get hashCode => Object.hash(
    identityHashCode(strings),
    firstDayOfWeek,
    uses24HourClock,
    datePattern,
    dateHint,
    mediumDatePattern,
    fullDatePattern,
  );
}

/// The first day of the week in [locale]'s region, from CLDR's week data:
/// [DateTime.sunday] in the US, Canada, Brazil, Japan, Korea, Taiwan,
/// India and others; [DateTime.saturday] in Egypt and much of the Middle
/// East; [DateTime.monday] elsewhere (Turkey, Europe, Russia, China).
/// Without a region, the language's usual one (`en` → US, `ar` → Egypt,
/// `zh_Hant` → Taiwan).
int dsFirstDayOfWeek(Locale locale) {
  final region = _regionOf(locale);
  if (_saturdayFirst.contains(region)) return DateTime.saturday;
  if (_sundayFirst.contains(region)) return DateTime.sunday;
  if (region == 'MV') return DateTime.friday;
  return DateTime.monday;
}

/// Whether [locale] reads time on a 24-hour clock: the clock of its CLDR
/// time format, which depends on the language and the region together.
/// English is 12-hour in the US, Canada, Australia and India and 24-hour
/// in Britain, Ireland and most of Europe; French is 24-hour in France and
/// Canada; Spanish 24-hour in Spain and 12-hour in Mexico and most of
/// Latin America; Arabic 12-hour except in Morocco; Korean, Hindi and
/// Traditional Chinese 12-hour; Turkish, German, Japanese, Portuguese and
/// Simplified Chinese 24-hour. Without a region, the language's usual
/// one. A language Desen has no words for takes its region's preferred
/// hour cycle (CLDR timeData): 24-hour in Poland, the Netherlands, Sweden.
bool dsUses24HourClock(Locale locale) {
  final language = locale.languageCode;
  final region = _regionOf(locale);
  final script = locale.scriptCode;
  if (language == 'zh' &&
      (script == 'Hant' || (script == null && region == 'TW'))) {
    return false;
  }
  if (_clocks[language] case (final default24, final others)) {
    return others.contains(region) != default24;
  }
  return !_twelveHour.contains(region);
}

/// The numeric date pattern [locale] writes, in [DsDateFormat] letters,
/// from CLDR (the `yMd` skeleton, with a four-digit year): `M/d/y` in the
/// US, `dd/MM/y` in Britain, `d.MM.y` in Poland, `dd-MM-y` in the
/// Netherlands, `y-MM-dd` in Sweden and Canada, `y/M/d` in Japan and
/// China. Looked up by language and region (`en_GB`, `fr_CA`, `de_CH`),
/// then by language; a language not listed takes ISO `y-MM-dd`, which no
/// one misreads.
String dsDatePattern(Locale locale) =>
    _regionalPattern(locale) ?? _datePatterns[locale.languageCode] ?? 'y-MM-dd';

String? _regionalPattern(Locale locale) {
  final language = locale.languageCode;
  final region = _regionOf(locale);
  if (_regionalPatterns['${language}_$region'] case final p?) return p;
  // English outside the US and its territories writes the day first.
  if (language == 'en' && region != '001' && !_usDateRegions.contains(region)) {
    return 'dd/MM/y';
  }
  return null;
}

/// The hint of [pattern] ("DD.MM.YYYY"), in the letters [strings]' own
/// hint uses for day, month and year ("GG.AA.YYYY" in Turkish), else
/// English's.
String _hintFor(String pattern, DsLocalizations strings) {
  var letters = const {'d': 'DD', 'M': 'MM', 'y': 'YYYY'};
  final runs = [
    for (final m in RegExp(
      r'[^\s\d.,/\-–:\u200E\u200F]+',
    ).allMatches(strings.dateHint))
      m.group(0)!,
  ];
  final order = [
    for (final m in RegExp(
      '[yMd]+',
    ).allMatches(strings.datePattern.replaceAll(RegExp("'[^']*'"), '')))
      m.group(0)![0],
  ];
  if (runs.length == 3 && order.length == 3 && order.toSet().length == 3) {
    letters = {for (var i = 0; i < 3; i++) order[i]: runs[i]};
  }
  final out = StringBuffer();
  final quoted = RegExp("'([^']*)'");
  var rest = pattern;
  while (rest.isNotEmpty) {
    if (quoted.matchAsPrefix(rest) case final m?) {
      out.write(m.group(1));
      rest = rest.substring(m.end);
      continue;
    }
    final c = rest[0];
    if (letters[c] case final word?) {
      out.write(word);
      rest = rest.replaceFirst(RegExp('^$c+'), '');
    } else {
      out.write(c);
      rest = rest.substring(1);
    }
  }
  return out.toString();
}

/// The medium (`yMMMd`) and full date patterns CLDR gives [language] in
/// [region] where they differ from the language's own; null keeps the
/// [DsLocalizations] pattern. English outside the US, its territories,
/// the Philippines and Canada follows `en_001` (day first), as the short
/// date does.
(String?, String?) _regionalLongDates(String language, String region) {
  if (_longDates['${language}_$region'] case final p?) return p;
  if (language == 'en' && region != 'CA' && !_usDateRegions.contains(region)) {
    return const ('d MMM y', 'EEEE, d MMMM y');
  }
  return const (null, null);
}

/// [locale]'s region, or its language's usual one (CLDR likely subtags).
String _regionOf(Locale locale) {
  final region = locale.countryCode;
  if (region != null && region.isNotEmpty) return region;
  final language = locale.languageCode;
  if (language == 'zh' && locale.scriptCode == 'Hant') return 'TW';
  return _likelyRegion[language] ?? '001';
}

const _likelyRegion = {
  'ar': 'EG',
  'de': 'DE',
  'en': 'US',
  'es': 'ES',
  'fr': 'FR',
  'hi': 'IN',
  'it': 'IT',
  'ja': 'JP',
  'ko': 'KR',
  'pt': 'BR',
  'ru': 'RU',
  'tr': 'TR',
  'zh': 'CN',
  'he': 'IL',
  'fa': 'IR',
  'th': 'TH',
  'id': 'ID',
  'vi': 'VN',
  'pl': 'PL',
  'nl': 'NL',
  'sv': 'SE',
  'da': 'DK',
  'nb': 'NO',
  'no': 'NO',
  'nn': 'NO',
  'fi': 'FI',
  'cs': 'CZ',
  'sk': 'SK',
  'el': 'GR',
  'uk': 'UA',
  'ro': 'RO',
  'hu': 'HU',
  'bg': 'BG',
  'hr': 'HR',
  'sr': 'RS',
  'sl': 'SI',
  'lt': 'LT',
  'lv': 'LV',
  'et': 'EE',
  'ms': 'MY',
  'fil': 'PH',
  'bn': 'BD',
  'ur': 'PK',
  'sw': 'KE',
};

// CLDR yMd (numeric date with a four-digit year) by language: the order of
// day, month and year and the separators. Regional differences below.
const _datePatterns = {
  'af': 'y-MM-dd', 'am': 'd/M/y', 'ar': 'd/M/y', 'az': 'dd.MM.y', //
  'be': 'd.M.y', 'bg': 'd.MM.y', 'bn': 'd/M/y', 'bs': 'd.M.y.', //
  'ca': 'd/M/y', 'cs': 'd. M. y', 'cy': 'd/M/y', 'da': 'd.M.y', //
  'de': 'd.M.y', 'el': 'd/M/y', 'en': 'M/d/y', 'es': 'd/M/y', //
  'et': 'd.M.y', 'eu': 'y/M/d', 'fa': 'y/M/d', 'fi': 'd.M.y', //
  'fil': 'M/d/y', 'fr': 'dd/MM/y', 'ga': 'd/M/y', 'gl': 'd/M/y', //
  'gu': 'd/M/y', 'he': 'd.M.y', 'hi': 'd/M/y', 'hr': 'dd. MM. y.', //
  'hu': 'y. MM. dd.', 'hy': 'dd.MM.y', 'id': 'd/M/y', 'is': 'd.M.y', //
  'it': 'd/M/y', 'ja': 'y/M/d', 'ka': 'dd.MM.y', 'kk': 'dd.MM.y', //
  'km': 'd/M/y', 'kn': 'd/M/y', 'ko': 'y. M. d.', 'ky': 'd/M/y', //
  'lo': 'd/M/y', 'lt': 'y-MM-dd', 'lv': 'd.MM.y.', 'mk': 'd.M.y', //
  'ml': 'd/M/y', 'mn': 'y.MM.dd', 'mr': 'd/M/y', 'ms': 'd/M/y', //
  'my': 'dd-MM-y', 'nb': 'd.M.y', 'ne': 'y-MM-dd', 'nl': 'd-M-y', //
  'nn': 'd.M.y', 'no': 'd.M.y', 'pa': 'd/M/y', 'pl': 'd.MM.y', //
  'pt': 'dd/MM/y', 'ro': 'dd.MM.y', 'ru': 'dd.MM.y', 'si': 'y-MM-dd', //
  'sk': 'd. M. y', 'sl': 'd. M. y', 'sq': 'd.M.y', 'sr': 'd.M.y.', //
  'sv': 'y-MM-dd', 'sw': 'd/M/y', 'ta': 'd/M/y', 'te': 'd/M/y', //
  'th': 'd/M/y', 'tr': 'dd.MM.y', 'uk': 'dd.MM.y', 'ur': 'd/M/y', //
  'uz': 'dd/MM/y', 'vi': 'd/M/y', 'zh': 'y/M/d', 'zu': 'M/d/y',
};

// CLDR's numeric date (yMd, or the short date with a four-digit year)
// where a region writes it differently from its language.
const _regionalPatterns = {
  'en_CA': 'y-MM-dd', 'en_ZA': 'y/MM/dd', 'en_SE': 'y-MM-dd', //
  'fr_CA': 'y-MM-dd', 'fr_CH': 'dd.MM.y', 'fr_BE': 'd/MM/y', //
  'nl_BE': 'd/M/y', 'it_CH': 'dd.MM.y', 'ms_SG': 'd/M/y', //
  'zh_HK': 'd/M/y', 'zh_MO': 'd/M/y', 'zh_SG': 'dd/MM/y', //
  'es_PA': 'MM/dd/y', 'es_PR': 'MM/dd/y', 'pt_PT': 'dd/MM/y',
};

// CLDR supplemental weekData, firstDay.
const _saturdayFirst = {
  'AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM', //
  'QA', 'SD', 'SY',
};
const _sundayFirst = {
  'AG', 'AS', 'BD', 'BR', 'BS', 'BT', 'BW', 'BZ', 'CA', 'CO', 'DM', 'DO', //
  'ET', 'GT', 'GU', 'HK', 'HN', 'ID', 'IL', 'IN', 'JM', 'JP', 'KE', 'KH', //
  'KR', 'LA', 'MH', 'MM', 'MO', 'MT', 'MX', 'MZ', 'NI', 'NP', 'PA', 'PE', //
  'PH', 'PK', 'PR', 'PT', 'PY', 'SA', 'SG', 'SV', 'TH', 'TT', 'TW', 'UM', //
  'US', 'VE', 'VI', 'WS', 'YE', 'ZA', 'ZW',
};

// CLDR yMMMd (medium) and full date patterns where a region writes them
// differently from its language; null keeps the language's. English
// regions not listed follow en_001, or en in the US group.
const _longDates = <String, (String?, String?)>{
  'en_IE': ('d MMM y', 'EEEE d MMMM y'),
  'en_MV': ('d MMM y', 'EEEE d MMMM y'),
  'en_MT': ('dd MMM y', 'EEEE, d MMMM y'),
  'en_BW': ('dd MMM y', 'EEEE, dd MMMM y'),
  'en_BZ': ('dd MMM y', 'EEEE, dd MMMM y'),
  'en_ZA': ('dd MMM y', 'EEEE, dd MMMM y'),
  'en_ZW': ('dd MMM, y', 'EEEE, dd MMMM y'),
  'es_AR': ("d 'de' MMM 'de' y", null),
  'es_CO': ("d 'de' MMM 'de' y", null),
  'es_DO': ("d MMM 'de' y", null),
  'es_HN': (null, "EEEE dd 'de' MMMM 'de' y"),
  'fr_CH': (null, 'EEEE, d MMMM y'),
  'it_CH': (null, 'EEEE, d MMMM y'),
  'pt_PT': ('d/MM/y', null), 'pt_AO': ('d/MM/y', null), //
  'pt_CH': ('d/MM/y', null), 'pt_CV': ('d/MM/y', null), //
  'pt_GQ': ('d/MM/y', null), 'pt_GW': ('d/MM/y', null), //
  'pt_LU': ('d/MM/y', null), 'pt_MO': ('d/MM/y', null), //
  'pt_MZ': ('d/MM/y', null), 'pt_ST': ('d/MM/y', null), //
  'pt_TL': ('d/MM/y', null),
  'zh_TW': (null, 'y年M月d日 EEEE'),
  'zh_HK': (null, 'y年M月d日EEEE'),
  'zh_MO': (null, 'y年M月d日EEEE'),
};

// The clock of the CLDR time format (timeFormats/short) of each language
// Desen has words for: (24-hour by default, the regions whose locale
// reads the other clock).
const _clocks = <String, (bool, Set<String>)>{
  'ar': (false, {'IL', 'KM', 'MA'}),
  'de': (true, {}),
  'en': (
    false,
    {
      '150', 'AI', 'AT', 'BE', 'BI', 'BW', 'BZ', 'CC', 'CH', 'CK', 'CM', //
      'CX', 'CZ', 'DE', 'DG', 'DK', 'ES', 'FI', 'FK', 'FR', 'GB', 'GG', //
      'GI', 'GS', 'HU', 'ID', 'IE', 'IL', 'IM', 'IO', 'IT', 'JE', 'KE', //
      'MG', 'MS', 'MT', 'MU', 'MV', 'NF', 'NG', 'NL', 'NO', 'NR', 'NU', //
      'PL', 'PN', 'PT', 'RO', 'RW', 'SC', 'SE', 'SH', 'SI', 'SK', 'SX', //
      'TK', 'TV', 'TZ', 'UG', 'ZA', 'ZW',
    },
  ),
  'es': (
    true,
    {
      '419', 'AR', 'BO', 'CL', 'CO', 'CR', 'CU', 'DO', 'EC', 'GT', 'HN', //
      'MX', 'NI', 'PA', 'PE', 'PH', 'PR', 'PY', 'SV', 'US', 'UY', 'VE',
    },
  ),
  'fr': (true, {'DJ', 'DZ', 'MR', 'SY', 'TD', 'TN', 'VU'}),
  'hi': (false, {}),
  'it': (true, {}),
  'ja': (true, {}),
  'ko': (false, {'CN'}),
  'pt': (true, {'MO'}),
  'ru': (true, {}),
  'tr': (true, {'CY'}),
  // Simplified; Traditional (and Taiwan) is 12-hour everywhere.
  'zh': (true, {'HK', 'MO', 'MY', 'SG'}),
};

// CLDR supplemental timeData: regions whose preferred hour cycle is h.
const _twelveHour = {
  'US', 'CA', 'AU', 'NZ', 'IN', 'PK', 'BD', 'PH', 'KR', 'TW', 'HK', 'MO', //
  'EG', 'SA', 'AE', 'JO', 'KW', 'QA', 'BH', 'OM', 'IQ', 'SY', 'LB', 'LY', //
  'SD', 'YE', 'DZ', 'MY', 'SG', 'CO', 'MX', 'SV', 'HN', 'NI', 'PR', 'VE', //
  'AS', 'GU', 'MP', 'UM', 'VI',
};

// Where English writes the month first (M/d/y).
const _usDateRegions = {'US', 'PR', 'UM', 'VI', 'AS', 'GU', 'MP', 'MH', 'PH'};
