import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Gives the widgets layer the text direction of the app's language:
/// right to left for Arabic, Persian, Hebrew, Urdu and the other RTL
/// scripts, left to right otherwise.
///
/// Flutter's own default is left to right for every language; without
/// this, an Arabic app needs `flutter_localizations` just for the
/// direction. `DsApp` adds it after your own delegates, so a
/// `GlobalWidgetsLocalizations.delegate` you pass still wins. Add it
/// yourself under a plain `WidgetsApp`.
class DsWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const DsWidgetsLocalizations._(this.textDirection);

  @override
  final TextDirection textDirection;

  /// Languages written right to left (ISO 639-1 and -3 codes).
  static const rtlLanguages = {
    'ar', 'ckb', 'dv', 'fa', 'he', 'iw', 'ps', 'sd', 'ug', 'ur', 'yi', //
  };

  /// The direction for [locale].
  static TextDirection directionOf(Locale locale) =>
      rtlLanguages.contains(locale.languageCode)
      ? TextDirection.rtl
      : TextDirection.ltr;

  /// Supports every locale.
  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _Delegate();
}

class _Delegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => SynchronousFuture(
    DsWidgetsLocalizations._(DsWidgetsLocalizations.directionOf(locale)),
  );

  @override
  bool shouldReload(_Delegate old) => false;
}
