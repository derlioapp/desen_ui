import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How a [DsNumberFormat] shows and reads numbers: fixed fraction digits,
/// optional thousands grouping and the locale's separators, without a
/// dependency on `intl`.
///
/// Separators left null come from the locale ([forLocale], which
/// `DsNumberField` calls with the app's locale): Turkish and German write
/// `12.500,75`, English `12,500.75`, French `12 500,75`.
///
/// ```dart
/// const DsNumberFormat(decimals: 2, grouping: true)
///     .forLocale(const Locale('tr'))
///     .format(12500.5); // '12.500,50'
/// ```
@immutable
class DsNumberFormat {
  /// Creates a number format.
  const DsNumberFormat({
    this.decimals = 0,
    this.grouping = false,
    this.decimalSeparator,
    this.groupSeparator,
  }) : assert(decimals >= 0 && decimals <= maxDecimals),
       assert(
         decimalSeparator == null || decimalSeparator != groupSeparator,
         'The decimal and group separators must differ.',
       );

  /// The most fraction digits a format shows: 20, the most a double's
  /// fixed notation writes. A format asking for more shows 20 (and fails an
  /// assertion in debug builds).
  static const int maxDecimals = 20;

  /// Fraction digits: always shown, and the most that can be typed. 0 makes
  /// whole numbers; at most [maxDecimals].
  final int decimals;

  /// Whether thousands are grouped (`12.500`). Typed group separators are
  /// accepted where they group thousands ([readings] tells how a typed `.`
  /// or `,` is read).
  final bool grouping;

  /// Separates the fraction; null takes the locale's. Differs from
  /// [groupSeparator].
  final String? decimalSeparator;

  /// Separates thousands when [grouping]; null takes the locale's. Differs
  /// from [decimalSeparator].
  final String? groupSeparator;

  /// This format with the separators [locale] uses wherever none is set.
  /// Where the locale's would equal the one that is set (a `,` decimal
  /// separator with English's `,` group), the locale's other separator is
  /// taken instead (`.`), so a number reads back as it was shown.
  DsNumberFormat forLocale(Locale locale) {
    final (localeDecimal, localeGroup) = dsNumberSeparators(locale);
    var decimal = decimalSeparator ?? localeDecimal;
    var group = groupSeparator ?? localeGroup;
    if (decimal == group) {
      if (decimalSeparator == null) {
        decimal = localeGroup;
      } else {
        group = localeDecimal;
      }
    }
    return DsNumberFormat(
      decimals: decimals,
      grouping: grouping,
      decimalSeparator: decimal,
      groupSeparator: group,
    );
  }

  // English's, unless the other separator is set to it.
  String get _decimal =>
      decimalSeparator ?? (groupSeparator == '.' ? ',' : '.');
  String get _group => groupSeparator ?? (decimalSeparator == ',' ? '.' : ',');

  /// [decimals], held to 0–[maxDecimals].
  int get _digits => decimals.clamp(0, maxDecimals);

  /// Whether the group separator is a key a keypad offers for the decimal
  /// point, so a typed one may mean either.
  bool get _keypadGroup => grouping && (_group == '.' || _group == ',');

  /// [value] rounded to [decimals] fraction digits, e.g. `-12.500,50`.
  /// Negative zero is shown as zero, an infinity as `∞` or `-∞`, and NaN
  /// as an empty string.
  String format(num value) {
    if (value.isNaN) return '';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
    var fixed = _fixed(value);
    var negative = fixed.startsWith('-');
    if (negative) fixed = fixed.substring(1);
    final dot = fixed.indexOf('.');
    var whole = dot < 0 ? fixed : fixed.substring(0, dot);
    final fraction = dot < 0 ? '' : fixed.substring(dot + 1);
    if (negative && RegExp(r'^[0.]*$').hasMatch(fixed)) negative = false;
    if (grouping && whole.length > 3) {
      final out = StringBuffer();
      for (var i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) out.write(_group);
        out.write(whole[i]);
      }
      whole = out.toString();
    }
    return [
      if (negative) '-',
      whole,
      if (fraction.isNotEmpty) ...[_decimal, fraction],
    ].join();
  }

  /// [value] with [decimals] fraction digits, in plain digits even past
  /// 1e21 (where `toStringAsFixed` writes an exponent).
  String _fixed(num value) {
    final digits = _digits;
    if (value is double && value.isFinite && value.abs() >= 1e21) {
      final whole = BigInt.from(value).toString();
      return digits == 0 ? whole : '$whole.${'0' * digits}';
    }
    return value.toStringAsFixed(digits);
  }

  /// The number [text] holds, or null when it is empty, not a number
  /// ("-", ",") or could be read two ways ([readings]). Group separators
  /// are skipped; other scripts' digits (Arabic-Indic, full-width) and the
  /// minus sign (−) are read too.
  double? tryParse(String text) {
    final all = readings(text);
    return all.length == 1 ? all.single : null;
  }

  /// Every number [text] can be read as: none when it is empty or not a
  /// number, one, or two when it is ambiguous. [tryParse] takes the one.
  ///
  /// With [grouping], a group separator that is `.` or `,` (the keys a
  /// keypad offers for the decimal point, whatever the locale) is read by
  /// where it stands:
  /// - It groups thousands where it can: the first group one to three
  ///   digits without a leading zero, every later one three
  ///   (`1.234.567`, `12.500,75` in German).
  /// - It is the decimal point where it can be: with [decimals] above 0,
  ///   alone, without a decimal separator, and followed by no more than
  ///   [decimals] digits (`12.5` and `12.` in German).
  /// - Where it can be either (`1.234` in German with three or more
  ///   [decimals]), both readings are returned, the grouped one first, so
  ///   the magnitude is never guessed. Where it can be neither (`1.23.4`,
  ///   `12.5,3`), none is.
  ///
  /// Other group separators (spaces, `’`) are skipped wherever they stand.
  List<double> readings(String text) {
    var s = _normalize(text).trim();
    if (_keypadGroup) {
      final sign = s.startsWith('-') ? '-' : '';
      final parts = s.substring(sign.length).split(_decimal);
      if (parts.length > 2) return const [];
      final fraction = parts.length == 2 ? '.${parts[1]}' : '';
      final groups = parts.first.split(_group);
      if (groups.length == 1) return _plain('$sign${parts.first}$fraction');
      final first = groups.first;
      final grouped =
          first.isNotEmpty &&
          first.length <= 3 &&
          !first.startsWith('0') &&
          groups.skip(1).every((g) => g.length == 3);
      final point =
          _digits > 0 &&
          groups.length == 2 &&
          fraction.isEmpty &&
          groups.last.length <= _digits;
      // A grouped reading is 1000 or more, a decimal one under 1000: two
      // readings always differ.
      return [
        if (grouped) ..._plain('$sign${groups.join()}$fraction'),
        if (point) ..._plain('$sign$first.${groups.last}'),
      ];
    }
    if (grouping) {
      s = s.replaceAll(_group, '');
      if (_isSpace(_group)) s = s.replaceAll(_spaces, '');
    }
    return _plain(s.replaceAll(_decimal, '.'));
  }

  /// The number [s] (digits, "-" and "." for the decimal point) is, as a
  /// list of one; empty when it is not a finite number.
  static List<double> _plain(String s) {
    if (!_number.hasMatch(s)) return const [];
    final v = double.tryParse(s);
    return v == null || !v.isFinite ? const [] : [v];
  }

  /// A formatter for a text field that lets through only what can become
  /// a number in this format: digits, one leading minus when [signed], one
  /// decimal separator when [decimals] > 0 (and no more fraction digits
  /// than that), and group separators when [grouping].
  ///
  /// Either `.` or `,` typed where a decimal separator can go becomes this
  /// format's one, so a keypad's key works in every locale; so do other
  /// scripts' digits. The one exception is the group separator of a
  /// grouped format (`.` in German): it stays as typed, and [readings]
  /// tells a group from a decimal point by where it stands. A number
  /// grouped the locale's way and pasted into an ungrouped format
  /// ("1.234,56" in German) is kept without its group separators
  /// ("1234,56"). Anything else (a letter, a pasted sentence) leaves the
  /// text as it was.
  TextInputFormatter inputFormatter({bool signed = true}) =>
      _NumberInputFormatter(this, signed: signed);

  String _mapSeparators(String text) {
    if (_decimal.length != 1 || _group.length != 1) return text;
    final out = StringBuffer();
    for (final c in text.split('')) {
      if (grouping && (c == _group || (_isSpace(_group) && _isSpace(c)))) {
        out.write(_group);
      } else if (decimals > 0 && (c == '.' || c == ',' || c == _decimal)) {
        out.write(_decimal);
      } else {
        out.write(c);
      }
    }
    return out.toString();
  }

  /// [text], a number grouped the way this format's locale groups
  /// ("1.234,56" in German), without its group separators; null when this
  /// format groups itself or [text] is not such a number.
  String? _ungrouped(String text) {
    if (grouping) return null;
    final grouped = DsNumberFormat(
      decimals: _digits,
      grouping: true,
      decimalSeparator: _decimal,
      groupSeparator: _group,
    );
    final read = grouped.readings(text);
    if (read.length != 1) return null;
    var out = text.replaceAll(_group, '');
    if (_isSpace(_group)) out = out.replaceAll(_spaces, '');
    final again = grouped.readings(out);
    return again.length == 1 && again.single == read.single ? out : null;
  }

  bool _canBecomeNumber(String text, {required bool signed}) {
    final group = grouping ? RegExp.escape(_group) : '';
    final digits = _digits;
    final fraction = digits > 0
        ? '(?:${RegExp.escape(_decimal)}[0-9]{0,$digits})?'
        : '';
    return RegExp('^${signed ? '-?' : ''}[0-9$group]*$fraction\$')
        .hasMatch(text);
  }

  @override
  bool operator ==(Object other) =>
      other is DsNumberFormat &&
      other.decimals == decimals &&
      other.grouping == grouping &&
      other.decimalSeparator == decimalSeparator &&
      other.groupSeparator == groupSeparator;

  @override
  int get hashCode =>
      Object.hash(decimals, grouping, decimalSeparator, groupSeparator);

  @override
  String toString() =>
      'DsNumberFormat(decimals: $decimals, grouping: $grouping, '
      'decimal: "$_decimal", group: "$_group")';
}

final _number = RegExp(r'^-?(?:[0-9]+\.?[0-9]*|\.[0-9]+)$');
final _spaces = RegExp('[   ]');
bool _isSpace(String c) => c == ' ' || c == ' ' || c == ' ';

/// Other scripts' digits to ASCII, minus signs to '-'; one character for
/// one, so a selection stays where it was.
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
    } else if (rune == 0x2212 || rune == 0xFF0D) {
      out.write('-');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

class _NumberInputFormatter extends TextInputFormatter {
  _NumberInputFormatter(this.format, {required this.signed});

  final DsNumberFormat format;
  final bool signed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalize(newValue.text);
    var text = format._mapSeparators(normalized);
    // Mapping is one character for one only when no character was outside
    // the basic plane; otherwise the selection is placed at the end.
    if (!format._canBecomeNumber(text, signed: signed)) {
      // A number grouped the locale's way, pasted: kept without its groups.
      final ungrouped = format._ungrouped(normalized);
      if (ungrouped == null ||
          !format._canBecomeNumber(ungrouped, signed: signed)) {
        return oldValue;
      }
      text = ungrouped;
    }
    if (text == newValue.text) return newValue;
    final same = text.length == newValue.text.length;
    return newValue.copyWith(
      text: text,
      selection: same
          ? newValue.selection
          : TextSelection.collapsed(offset: text.length),
      composing: same ? newValue.composing : TextRange.empty,
    );
  }
}

/// The decimal and group separators [locale] writes numbers with, from
/// CLDR, for Latin digits: `(',', '.')` for Turkish and German, `('.',
/// ',')` for English, `(',', ' ')` for French. Languages not listed
/// take the English pair.
(String decimal, String group) dsNumberSeparators(Locale locale) {
  final region = locale.countryCode;
  switch ((locale.languageCode, region)) {
    case ('de' || 'it', 'CH' || 'LI'):
      return ('.', '’');
    case ('es', 'MX' || 'US' || 'PR' || 'DO' || 'GT' || 'HN' || 'NI'):
    case ('es', 'PA' || 'SV' || 'PE' || '419'):
      return ('.', ',');
    case ('pt', 'PT' || 'AO' || 'MZ'):
      return (',', ' ');
    case ('fr', _):
      return (',', ' ');
    case ('de' || 'tr' || 'es' || 'it' || 'pt' || 'nl' || 'id' || 'da', _):
    case ('el' || 'ro' || 'hr' || 'sl' || 'sr' || 'bs' || 'vi' || 'ca', _):
    case ('gl' || 'eu' || 'is' || 'az', _):
      return (',', '.');
    case ('ru' || 'uk' || 'be' || 'pl' || 'cs' || 'sk' || 'bg' || 'hu', _):
    case ('sv' || 'fi' || 'nb' || 'no' || 'nn' || 'lt' || 'lv' || 'et', _):
    case ('kk' || 'ka' || 'hy' || 'uz' || 'ky' || 'mn' || 'sq' || 'af', _):
      return (',', ' ');
    default:
      return ('.', ',');
  }
}
