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
  }) : assert(decimals >= 0);

  /// Fraction digits: always shown, and the most that can be typed. 0 makes
  /// whole numbers.
  final int decimals;

  /// Whether thousands are grouped (`12.500`). Typed group separators are
  /// accepted and ignored.
  final bool grouping;

  /// Separates the fraction; null takes the locale's.
  final String? decimalSeparator;

  /// Separates thousands when [grouping]; null takes the locale's.
  final String? groupSeparator;

  /// This format with the separators [locale] uses wherever none is set.
  DsNumberFormat forLocale(Locale locale) {
    final (decimal, group) = dsNumberSeparators(locale);
    return DsNumberFormat(
      decimals: decimals,
      grouping: grouping,
      decimalSeparator: decimalSeparator ?? decimal,
      groupSeparator: groupSeparator ?? group,
    );
  }

  String get _decimal => decimalSeparator ?? '.';
  String get _group => groupSeparator ?? ',';

  /// [value] rounded to [decimals] fraction digits, e.g. `-12.500,50`.
  /// Negative zero is shown as zero.
  String format(num value) {
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
    if (value is double && value.isFinite && value.abs() >= 1e21) {
      final whole = BigInt.from(value).toString();
      return decimals == 0 ? whole : '$whole.${'0' * decimals}';
    }
    return value.toStringAsFixed(decimals);
  }

  /// The number [text] holds, or null when it is empty or not a number
  /// ("-", ","). Group separators are skipped; other scripts' digits
  /// (Arabic-Indic, full-width) and the minus sign (−) are read too.
  double? tryParse(String text) {
    var s = _normalize(text).trim();
    if (grouping) {
      s = s.replaceAll(_group, '');
      if (_isSpace(_group)) s = s.replaceAll(_spaces, '');
    }
    s = s.replaceAll(_decimal, '.');
    if (!_number.hasMatch(s)) return null;
    final v = double.tryParse(s);
    return v == null || !v.isFinite ? null : v;
  }

  /// A formatter for a text field that lets through only what can become
  /// a number in this format: digits, one leading minus when [signed], one
  /// decimal separator when [decimals] > 0 (and no more fraction digits
  /// than that), and group separators when [grouping]. Either `.` or `,`
  /// typed where a decimal separator can go becomes this format's one, so
  /// a keypad's key works in every locale; so do other scripts' digits.
  /// Anything else (a letter, a pasted sentence) leaves the text as it was.
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

  bool _canBecomeNumber(String text, {required bool signed}) {
    final group = grouping ? RegExp.escape(_group) : '';
    final fraction = decimals > 0
        ? '(?:${RegExp.escape(_decimal)}[0-9]{0,$decimals})?'
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
    final text = format._mapSeparators(_normalize(newValue.text));
    // Mapping is one character for one only when no character was outside
    // the basic plane; otherwise the selection is placed at the end.
    if (!format._canBecomeNumber(text, signed: signed)) return oldValue;
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
