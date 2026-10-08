import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// Gives the widgets layer the text direction of the app's language:
/// right to left for Arabic, Persian, Hebrew, Urdu and the other RTL
/// scripts, left to right otherwise. It also gives Flutter's reorderable
/// lists their screen reader actions ("Move up", "Move to the end") in
/// the app's language, from Desen's bundled strings.
///
/// Flutter's own default is left to right for every language; without
/// this, an Arabic app needs `flutter_localizations` just for the
/// direction. `DsApp` adds it after your own delegates, so a
/// `GlobalWidgetsLocalizations.delegate` you pass still wins. Add it
/// yourself under a plain `WidgetsApp`.
class DsWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const DsWidgetsLocalizations._(this.textDirection, this._strings);

  @override
  final TextDirection textDirection;

  final DsLocalizations _strings;

  @override
  String get reorderItemUp => _strings.reorderItemUp;

  @override
  String get reorderItemDown => _strings.reorderItemDown;

  @override
  String get reorderItemLeft => _strings.reorderItemLeft;

  @override
  String get reorderItemRight => _strings.reorderItemRight;

  @override
  String get reorderItemToStart => _strings.reorderItemToStart;

  @override
  String get reorderItemToEnd => _strings.reorderItemToEnd;

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
    DsWidgetsLocalizations._(
      DsWidgetsLocalizations.directionOf(locale),
      DsLocalizations.resolve(locale),
    ),
  );

  @override
  bool shouldReload(_Delegate old) => false;
}
