import 'dart:ui' show Locale;

import '../../l10n/localizations.dart';
import '../number_field/number_format.dart';

/// [bytes] as people read a file size, the local way: "840 KB", "2,4 MB"
/// in Turkish, "2.4 MB" in English, "2,4 Mo" in French.
///
/// Units step by 1000 (kilobyte = 1000 bytes), as macOS, iOS and the SI
/// units have it. Bytes and kilobytes are whole numbers; megabytes and up
/// keep one decimal, dropped when it is zero ("10 MB"). The decimal
/// separator follows [locale] (as `DsNumberFormat` does) and the unit
/// names come from [strings] (`DsLocalizations.fileSizeUnit`), by default
/// the bundled strings for [locale]. A no-break space joins number and
/// unit.
String dsFormatFileSize(
  int bytes, {
  required Locale locale,
  DsLocalizations? strings,
}) {
  final (number, power) = _parts(bytes, locale);
  final unit = (strings ?? DsLocalizations.resolve(locale)).fileSizeUnit(power);
  return '$number\u00A0$unit';
}

/// "2,4 / 3,1 MB": [loaded] of [total], with the unit written once when
/// both share it ("840 KB / 3,1 MB" otherwise). See [dsFormatFileSize].
String dsFormatFileProgress(
  int loaded,
  int total, {
  required Locale locale,
  DsLocalizations? strings,
}) {
  final l10n = strings ?? DsLocalizations.resolve(locale);
  final (a, pa) = _parts(loaded, locale);
  final (b, pb) = _parts(total, locale);
  if (pa == pb) {
    return l10n.fileProgress(a, '$b\u00A0${l10n.fileSizeUnit(pb)}');
  }
  return l10n.fileProgress(
    '$a\u00A0${l10n.fileSizeUnit(pa)}',
    '$b\u00A0${l10n.fileSizeUnit(pb)}',
  );
}

/// The largest unit a size fits in, from bytes (0) to terabytes (4).
const _maxPower = 4;
const _step = 1000;

(String, int) _parts(int bytes, Locale locale) {
  final size = bytes < 0 ? 0 : bytes;
  var power = 0;
  var scale = 1;
  // Step up while the size rounds to 1000 or more in this unit.
  while (power < _maxPower && _round(size / scale, power) >= _step) {
    power++;
    scale *= _step;
  }
  final value = _round(size / scale, power);
  final decimals = power >= 2 && value != value.roundToDouble() ? 1 : 0;
  final text = DsNumberFormat(decimals: decimals)
      .forLocale(locale)
      .format(value);
  return (text, power);
}

/// [value] rounded as it is shown in [power]'s unit.
double _round(double value, int power) =>
    power >= 2 ? (value * 10).roundToDouble() / 10 : value.roundToDouble();
