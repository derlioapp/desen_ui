import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../foundation/case.dart';
import '../../l10n/localizations.dart';
import '../../l10n/strings/en.dart';
import '../time/time_of_day.dart';
import 'date_math.dart';

/// Shows and reads dates and times by a CLDR-style pattern, with the month
/// and weekday names of a [DsLocalizations], without a dependency on
/// `intl`.
///
/// | Letters | Meaning | Example |
/// |---|---|---|
/// | `y`, `yy` | Year, at least four digits (`0476`); `yy` its last two | 2026, 26 |
/// | `M`, `MM` | Month number | 5, 05 |
/// | `MMM` | Short month name in a date | Eki, Oct |
/// | `MMMM` | Month name in a date | Ekim, октября |
/// | `LLLL` | Month name on its own (a header) | Ekim, Октябрь |
/// | `d`, `dd` | Day of the month | 5, 05 |
/// | `EEE`, `EEEE` | Short and full weekday | Pt, Pazartesi |
/// | `H`, `HH` | Hour, 0–23 | 9, 09 |
/// | `h` | Hour, 1–12 | 9 |
/// | `m`, `mm` | Minute | 5, 05 |
/// | `s`, `ss` | Second | 7, 07 |
/// | `a` | AM or PM, as the language writes it | ÖS, PM |
/// | `'text'` | Literal text; `''` is a quote | |
///
/// Any other character is written as is. Digits are Latin.
///
/// ```dart
/// const DsDateFormat('dd.MM.y').format(DateTime(2026, 10, 5)); // 05.10.2026
/// const DsDateFormat('dd.MM.y').tryParse('5/10/26'); // 2026-10-05
/// ```
///
/// Reading is lenient ([tryParse]): any run of non-digits separates the
/// numbers, so `05.10.2026`, `5/10/2026`, `5-10-2026` and `5 10 2026` all
/// read the same in a day-first pattern; a month may be typed as its name
/// or short name; other scripts' digits are read too.
@immutable
class DsDateFormat {
  /// Creates a format for [pattern], naming months and weekdays and the
  /// AM/PM marks from [strings].
  const DsDateFormat(this.pattern, {this.strings = const DsLocalizationsEn()});

  /// The pattern, in the letters listed on the class.
  final String pattern;

  /// The month and weekday names and the AM/PM marks.
  final DsLocalizations strings;

  /// [date] in this format.
  String format(DateTime date) {
    final out = StringBuffer();
    for (final token in _tokens(pattern)) {
      out.write(switch (token) {
        _Literal(:final text) => text,
        _Field(:final letter, :final count) => _field(letter, count, date),
      });
    }
    return out.toString();
  }

  /// [time] in this format (its time fields; a date field shows 1 January
  /// 2000).
  String formatTime(DsTime time) =>
      format(DateTime(2000, 1, 1, time.hour, time.minute, time.second));

  String _field(String letter, int count, DateTime d) {
    String pad(int v, int width) => v.toString().padLeft(width, '0');
    return switch (letter) {
      'y' when count == 2 => pad(d.year % 100, 2),
      // At least four digits, so a year before 1000 reads back as itself
      // (`0050`, not a two-digit `50`).
      'y' => d.year < 0 ? '${d.year}' : pad(d.year, math.max(count, 4)),
      'M' || 'L' when count >= 4 =>
        letter == 'L'
            ? strings.monthName(d.month)
            : strings.monthNameInDate(d.month),
      'M' || 'L' when count == 3 => strings.monthAbbr(d.month),
      'M' || 'L' => pad(d.month, count),
      'd' => pad(d.day, count),
      'E' when count >= 4 => strings.weekdayName(d.weekday),
      'E' => strings.weekdayAbbr(d.weekday),
      'H' => pad(d.hour, count),
      'h' => pad(d.hour % 12 == 0 ? 12 : d.hour % 12, count),
      'm' => pad(d.minute, count),
      's' => pad(d.second, count),
      'a' => d.hour < 12 ? strings.am : strings.pm,
      _ => letter * count,
    };
  }

  /// The date order of this pattern: 'y', 'M' and 'd' as they come.
  List<String> get _order => [
    for (final token in _tokens(pattern))
      if (token case _Field(:final letter))
        if (letter == 'y' || letter == 'd')
          letter
        else if (letter == 'M' || letter == 'L')
          'M',
  ];

  /// The date [text] holds, or null when it is not one (an impossible day
  /// such as 31.02, or not three parts). It never throws.
  ///
  /// The numbers are read in this pattern's order (day, month, year for
  /// `dd.MM.y`; month, day, year for `M/d/y`). A month typed as a name or
  /// a short name (`5 Eki 2026`, `Oct 5 2026`) takes the month's place
  /// whatever its position. A year of three or four digits is read as
  /// written (`0476` and `476` are 476); one of exactly two digits is in
  /// this century unless that is more than 20 years after [today]'s year
  /// (`26` is 2026, `99` 1999). A year of one digit, of more than four, or
  /// 0 is not read. Without a year, the year is [today]'s (`5.10`).
  /// [today] defaults to now.
  DateTime? tryParse(String text, {DateTime? today}) {
    final normalized = _normalize(text);
    final numbers = [
      for (final m in _digits.allMatches(normalized)) m.group(0)!,
    ];
    final words = [
      for (final m in _letters.allMatches(normalized)) m.group(0)!,
    ];
    var order = _order;
    if (order.length != 3) order = const ['y', 'M', 'd'];
    int? month;
    for (final word in words) {
      final found = _monthOf(word);
      if (found != null) {
        month = found;
        break;
      }
    }
    final fields = [
      for (final f in order)
        if (f != 'M' || month == null) f,
    ];
    final values = <String, String>{};
    if (numbers.length == fields.length) {
      for (var i = 0; i < fields.length; i++) {
        values[fields[i]] = numbers[i];
      }
    } else if (numbers.length == fields.length - 1) {
      // No year: this year.
      final noYear = fields.where((f) => f != 'y').toList();
      for (var i = 0; i < noYear.length; i++) {
        values[noYear[i]] = numbers[i];
      }
    } else {
      return null;
    }
    final now = today ?? DateTime.now();
    final yearText = values['y'];
    int year;
    if (yearText == null) {
      year = now.year;
    } else if (yearText.length == 2) {
      year = 2000 + int.parse(yearText);
      if (year > now.year + 20) year -= 100;
    } else if (yearText.length == 3 || yearText.length == 4) {
      year = int.parse(yearText);
      if (year < 1) return null;
    } else {
      return null;
    }
    month ??= _small(values['M']);
    final day = _small(values['d']);
    if (month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1) return null;
    if (day > DsDateUtils.daysInMonth(year, month)) return null;
    return DateTime(year, month, day);
  }

  /// The month a typed word names: a full or short month name (in a date
  /// or on its own), case and dots ignored, or at least three letters of
  /// one.
  int? _monthOf(String word) {
    final w = dsFoldCase(word.replaceAll('.', ''));
    if (w.isEmpty) return null;
    for (var m = 1; m <= 12; m++) {
      for (final name in [
        strings.monthName(m),
        strings.monthNameInDate(m),
        strings.monthAbbr(m),
      ]) {
        final n = dsFoldCase(name.replaceAll('.', ''));
        if (n == w || (w.length >= 3 && n.startsWith(w))) return m;
      }
    }
    return null;
  }

  /// The time [text] holds, or null. Lenient: `14:30`, `14.30`, `1430`,
  /// `2:30 pm`, `2pm`, `ÖS 2:30`. The language's AM/PM marks are read
  /// (case, dots and spaces ignored), and so are `am`, `pm`, `a` and `p`.
  /// Without a mark the hour is 0–23; with one, 1–12.
  ///
  /// A pattern with seconds (`HH:mm:ss`) also reads them: `14:30:05`,
  /// `143005`; a time typed without them is on the minute. A pattern
  /// without seconds reads hours and minutes only.
  DsTime? tryParseTime(String text) {
    final normalized = _normalize(text);
    final numbers = [
      for (final m in _digits.allMatches(normalized)) m.group(0)!,
    ];
    final letters = dsFoldCase(
      normalized.replaceAll(RegExp(r'[\d\s.:,\-]'), ''),
    );
    bool? pm;
    if (letters.isNotEmpty) {
      String mark(String s) => dsFoldCase(s.replaceAll(RegExp(r'[\s.]'), ''));
      final am = mark(strings.am), pmMark = mark(strings.pm);
      if (letters == am || letters == 'am' || letters == 'a') {
        pm = false;
      } else if (letters == pmMark || letters == 'pm' || letters == 'p') {
        pm = true;
      } else {
        return null;
      }
    }
    final seconds = _hasSeconds;
    int? hour, minute, second = 0;
    if (numbers.length == 1) {
      final n = numbers.single;
      if (n.length <= 2) {
        hour = _small(n);
        minute = 0;
      } else if (n.length <= 4) {
        hour = _small(n.substring(0, n.length - 2));
        minute = _small(n.substring(n.length - 2));
      } else if (seconds && n.length <= 6) {
        hour = _small(n.substring(0, n.length - 4));
        minute = _small(n.substring(n.length - 4, n.length - 2));
        second = _small(n.substring(n.length - 2));
      }
    } else if (numbers.length == 2) {
      hour = _small(numbers[0]);
      minute = _small(numbers[1]);
    } else if (seconds && numbers.length == 3) {
      hour = _small(numbers[0]);
      minute = _small(numbers[1]);
      second = _small(numbers[2]);
    }
    if (hour == null || minute == null || second == null) return null;
    if (minute > 59 || second > 59) return null;
    if (pm != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (pm ? 12 : 0);
    } else if (hour > 23) {
      return null;
    }
    return DsTime(hour, minute, second);
  }

  /// Whether the pattern shows seconds.
  bool get _hasSeconds =>
      _tokens(pattern).any((token) => token is _Field && token.letter == 's');

  @override
  bool operator ==(Object other) =>
      other is DsDateFormat &&
      other.pattern == pattern &&
      identical(other.strings, strings);

  @override
  int get hashCode => Object.hash(pattern, identityHashCode(strings));

  @override
  String toString() => "DsDateFormat('$pattern', ${strings.localeName})";
}

sealed class _Token {
  const _Token();
}

class _Literal extends _Token {
  const _Literal(this.text);
  final String text;
}

class _Field extends _Token {
  const _Field(this.letter, this.count);
  final String letter;
  final int count;
}

final _tokenCache = <String, List<_Token>>{};

List<_Token> _tokens(String pattern) => _tokenCache[pattern] ??= () {
  final out = <_Token>[];
  final literal = StringBuffer();
  void flush() {
    if (literal.isEmpty) return;
    out.add(_Literal(literal.toString()));
    literal.clear();
  }

  var i = 0;
  while (i < pattern.length) {
    final c = pattern[i];
    if (c == "'") {
      // '' is a quote; 'text' is literal text.
      if (i + 1 < pattern.length && pattern[i + 1] == "'") {
        literal.write("'");
        i += 2;
        continue;
      }
      final end = pattern.indexOf("'", i + 1);
      literal.write(pattern.substring(i + 1, end < 0 ? pattern.length : end));
      i = end < 0 ? pattern.length : end + 1;
    } else if (_patternLetters.contains(c)) {
      var j = i;
      while (j < pattern.length && pattern[j] == c) {
        j++;
      }
      flush();
      out.add(_Field(c, j - i));
      i = j;
    } else {
      literal.write(c);
      i++;
    }
  }
  flush();
  return List<_Token>.unmodifiable(out);
}();

const _patternLetters = 'yMLdEHhmsa';

final _digits = RegExp(r'\d+');

/// [text] as a number of at most two digits (a day, month, hour, minute
/// or second), or null: longer text is never a valid field, and reading it
/// could overflow.
int? _small(String? text) =>
    text == null || text.isEmpty || text.length > 2 ? null : int.parse(text);
final _letters = RegExp(r'[^\d\s.,:;/\\\-–—_()]+');

/// Other scripts' digits to ASCII; bidirectional marks dropped.
String _normalize(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final digit = switch (rune) {
      >= 0x0660 && <= 0x0669 => rune - 0x0660, // Arabic-Indic
      >= 0x06F0 && <= 0x06F9 => rune - 0x06F0, // Extended Arabic-Indic
      >= 0x0966 && <= 0x096F => rune - 0x0966, // Devanagari
      >= 0xFF10 && <= 0xFF19 => rune - 0xFF10, // Full-width
      _ => null,
    };
    if (digit != null) {
      out.write(digit);
    } else if (rune == 0x200E || rune == 0x200F || rune == 0x061C) {
      // Left-to-right, right-to-left and Arabic letter marks.
      continue;
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}
