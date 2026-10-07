import 'package:flutter/widgets.dart';

import 'strings/all.dart';

part 'strings/keys.dart';

/// Every string Desen shows or announces. Components never
/// hold a literal; they read it from [DsLocalizations.of].
///
/// 13 languages ship with the library (see `tool/gen_l10n.py`). Each one
/// extends the English strings, so a key a language does not translate
/// falls back to English instead of failing. Regional variants extend their
/// language and override only what differs: Traditional Chinese
/// (`zh_Hant`, also used for Taiwan, Hong Kong and Macau) and European
/// Portuguese (`pt_PT`; plain `pt` is Brazilian). Add or override a
/// language or a variant with [DsLocalizationScope]:
///
/// ```dart
/// class Greek extends DsLocalizationsEn {
///   const Greek();
///   @override
///   String get localeName => 'el';
///   @override
///   String get close => 'Κλείσιμο'; // the rest stays English
/// }
///
/// DsLocalizationScope(overrides: const {'el': Greek()}, child: app)
/// ```
///
/// The app must resolve to that language too: `DsApp(locale:
/// const Locale('el'))`, or the locale listed in `supportedLocales`.
///
/// To customize strings, extend [DsLocalizationsEn] or another bundled
/// language, as above. Implementing this interface directly may break when
/// a release adds strings.
abstract class DsLocalizations with _DsStrings {
  /// Creates strings.
  const DsLocalizations();

  /// The locale key these strings are for ('en', 'tr', 'zh_Hant'…), as in
  /// [dsBundledLocalizations].
  String get localeName;

  /// The strings for [context]. In order:
  /// 1. [DsLocalizationScope.localizations], when set;
  /// 2. the strings for the app's locale (`Localizations.localeOf`), from
  ///    the scope's [DsLocalizationScope.overrides] or the bundled ones,
  ///    most specific match first ([resolve]);
  /// 3. English.
  ///
  /// Never throws: an unknown language or a missing app root gives English.
  static DsLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DsLocalizationScope>();
    if (scope?.localizations case final forced?) return forced;
    return resolve(
      Localizations.maybeLocaleOf(context),
      overrides: scope?.overrides ?? const {},
    );
  }

  /// Every locale with bundled strings, English first. It is the default
  /// for `DsApp.supportedLocales`, so an app's locale resolves to Desen's
  /// strings without listing them (Flutter falls back to the first
  /// supported locale otherwise).
  static final List<Locale> supportedLocales = List.unmodifiable([
    for (final key in dsBundledLocalizations.keys) _localeOf(key),
  ]);

  static Locale _localeOf(String key) {
    final parts = key.split('_');
    if (parts.length == 1) return Locale(parts.first);
    // A four-letter subtag is a script (ISO 15924), else a region.
    return parts[1].length == 4
        ? Locale.fromSubtags(languageCode: parts.first, scriptCode: parts[1])
        : Locale(parts.first, parts[1]);
  }

  /// The strings for [locale]: the first of [lookupKeys] found in
  /// [overrides] or, failing that, in [dsBundledLocalizations]; English when
  /// none is found or [locale] is null.
  ///
  /// A more specific bundled match wins over a less specific override: with
  /// an override for 'zh' only, a zh_TW locale still gets the bundled
  /// Traditional Chinese. Override 'zh_Hant' as well to replace it.
  static DsLocalizations resolve(
    Locale? locale, {
    Map<String, DsLocalizations> overrides = const {},
  }) {
    if (locale == null) return const DsLocalizationsEn();
    for (final key in lookupKeys(locale)) {
      if (overrides[key] ?? dsBundledLocalizations[key] case final found?) {
        return found;
      }
    }
    return const DsLocalizationsEn();
  }

  /// The keys tried for [locale], most specific first:
  /// `language_Script_REGION`, `language_Script`, `language_REGION`,
  /// `language`. Keys are written like `Locale.toString()`.
  ///
  /// A locale without a script takes the one its region implies where the
  /// difference matters for Desen's strings: Chinese in Taiwan, Hong Kong
  /// and Macau is Traditional (`zh_TW` tries `zh_Hant_TW`, `zh_Hant`,
  /// `zh_TW`, `zh`).
  static List<String> lookupKeys(Locale locale) {
    final language = locale.languageCode;
    final region = _nonEmpty(locale.countryCode);
    final script =
        _nonEmpty(locale.scriptCode) ??
        (region == null ? null : _impliedScripts['${language}_$region']);
    return [
      if (script != null && region != null) '${language}_${script}_$region',
      if (script != null) '${language}_$script',
      if (region != null) '${language}_$region',
      language,
    ];
  }

  static String? _nonEmpty(String? s) => s == null || s.isEmpty ? null : s;

  /// Scripts implied by a region when a locale names none (CLDR likely
  /// subtags), for the languages whose bundled strings differ by script.
  static const _impliedScripts = {
    'zh_TW': 'Hant',
    'zh_HK': 'Hant',
    'zh_MO': 'Hant',
  };
}

/// Adds, overrides or forces the strings Desen uses below it.
class DsLocalizationScope extends InheritedWidget {
  /// Creates a localization scope.
  const DsLocalizationScope({
    super.key,
    this.overrides = const {},
    this.localizations,
    required super.child,
  });

  /// Strings by locale key, written like `Locale.toString()`: a language
  /// ('el'), or a language with a script and/or region ('pt_BR',
  /// 'zh_Hant', 'sr_Latn_RS'). Looked up with the bundled strings, most
  /// specific key first ([DsLocalizations.resolve]); at the same key they
  /// win over the bundled ones.
  final Map<String, DsLocalizations> overrides;

  /// Strings to use regardless of the app's language.
  final DsLocalizations? localizations;

  @override
  bool updateShouldNotify(DsLocalizationScope oldWidget) =>
      oldWidget.overrides != overrides ||
      oldWidget.localizations != localizations;
}
