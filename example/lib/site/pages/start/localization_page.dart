import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import '../../settings.dart';
import '../foundations/common.dart';

/// Bundled languages, overriding strings, dates from CLDR, RTL and
/// collation.
class LocalizationPage extends StatelessWidget {
  const LocalizationPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Get started',
    title: 'Localization',
    lead:
        'Every string Desen shows or announces ships in 13 languages. Dates, '
        'times and the first day of the week follow the locale\'s region, '
        'and lists sort the way a dictionary in that language would.',
    sections: [
      DocSection(
        title: 'Bundled languages',
        children: [
          const DocText(
            'English, Arabic, Chinese (Simplified), French, German, Hindi, '
            'Italian, Japanese, Korean, Portuguese (Brazil), Russian, Spanish '
            'and Turkish. Two regional variants extend their language and '
            'override only what differs: European Portuguese (`pt_PT`) and '
            'Traditional Chinese (`zh_Hant`, also chosen for Taiwan, Hong '
            'Kong and Macau). A language without strings falls back to '
            'English, key by key.',
          ),
          const DocText(
            'With `DsApp`, set `locale:` for a fixed language. To follow the '
            'device, list the languages your app is translated into in '
            '`supportedLocales` (or `DsLocalizations.supportedLocales` for '
            'every bundled one). Without either, the app stays in English, '
            'as Flutter\'s own app widgets do, so an untranslated app is not '
            'mirrored on an Arabic device. Under another app root, list the '
            'locales in its `supportedLocales`. Desen reads the app\'s locale '
            'and needs no delegate of its own.',
          ),
          Example(
            snippet: 'l10n-locale',
            padding: const EdgeInsets.all(24),
            child: const _LocaleDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Adding and overriding strings',
        children: [
          const DocText(
            'Each language extends the English strings, so a class that '
            'overrides a few getters is a complete language. '
            '`DsLocalizationScope` adds it below: `overrides` by locale key, '
            'looked up together with the bundled ones (the more specific key '
            'wins), or `localizations` to force one set whatever the app\'s '
            'language.',
          ),
          const CodeBlock(
            'class Greek extends DsLocalizationsEn {\n'
            '  const Greek();\n'
            '\n'
            '  @override\n'
            "  String get localeName => 'el';\n"
            '\n'
            '  @override\n'
            "  String get close => 'Κλείσιμο'; // the rest stays English\n"
            '}\n'
            '\n'
            "DsLocalizationScope(overrides: const {'el': Greek()}, child: app)",
          ),
          const DocText(
            'The app must also resolve to the new language: set '
            '`locale: const Locale(\'el\')`, or add it to '
            '`supportedLocales`, e.g. '
            '`[...DsLocalizations.supportedLocales, const Locale(\'el\')]`.',
          ),
          const DocText(
            'Overriding works the same way for a bundled language. Here the '
            'English select prompt says what to pick:',
          ),
          Example(
            snippet: 'l10n-override',
            child: Localizations.override(
              context: context,
              locale: const Locale('en'),
              child: const _OverrideDemo(),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Dates and times',
        children: [
          DocText(
            'The calendar, date picker and time picker take the words from '
            'the strings and every numeric convention from the locale\'s '
            'region, after CLDR: the first day of the week, the 12- or '
            '24-hour clock and the order of day, month and year. A locale '
            'without a region takes its language\'s usual one (US for '
            'English, Egypt for Arabic). A Polish app writes Polish dates '
            'with English month names until you add Polish strings.',
          ),
          _DateTable(),
          DocText(
            'Read the same conventions in your own widgets with '
            '`DsDateLocale.of(context)`: `firstDayOfWeek`, `uses24HourClock`, '
            'and formats such as `shortDate`, `mediumDate` and `time`. '
            '`DsTimePicker` takes `use24HourClock` to force a clock.',
          ),
        ],
      ),
      DocSection(
        title: 'Right to left',
        children: [
          const DocText(
            'Arabic is bundled, and every component lays out from '
            '`Directionality`. `DsApp` sets it from the locale: Arabic, '
            'Hebrew, Persian, Urdu and the other right-to-left languages lay '
            'out right to left with no extra package. Under a plain '
            '`WidgetsApp`, add `DsWidgetsLocalizations.delegate` to its '
            '`localizationsDelegates`; `MaterialApp` users with '
            '`flutter_localizations` already have it.',
          ),
          const CodeBlock(
            'DsApp(\n'
            "  locale: const Locale('ar'),\n"
            '  home: const HomePage(),\n'
            ')',
          ),
          DocText(
            'What flips and what does not is on [Accessibility]'
            '(/accessibility). Choose Arabic as the preview language in the '
            'settings to see every example on this site right to left.',
          ),
        ],
      ),
      DocSection(
        title: 'Sorting text',
        children: [
          const DocText(
            '`String.compareTo` sorts by code point: every capital before '
            'every small letter, and Ç, Ş or Ü after Z. `dsCompareText` '
            'sorts like a dictionary: case is ignored first, accented letters '
            'sort with their base letter, and in Turkish (and Azerbaijani) '
            'ç ğ ı ö ş ü are letters of their own, right after c g h o s u. '
            'It is right for Latin-script languages; other scripts compare '
            'by code point after case folding.',
          ),
          Example(
            snippet: 'l10n-sort',
            padding: const EdgeInsets.all(24),
            child: const _SortDemo(),
          ),
          const DocText(
            'To sort many strings, make one `DsCollationKey` per string and '
            'sort the keys, so each string is read once. For search and '
            'typeahead, `dsFoldCase` compares what someone typed with a '
            'label in another case: `ı` meets `I`, `ß` meets `SS`.',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'DsLocalizations.of',
              'DsLocalizations',
              'The strings for a context, English as the last resort.',
            ),
            (
              'DsLocalizations.supportedLocales',
              'List<Locale>',
              'Every bundled locale, English first.',
            ),
            (
              'DsLocalizationScope',
              'widget',
              '`overrides` by locale key, or `localizations` to force one '
                  'set.',
            ),
            (
              'DsDateLocale.of',
              'DsDateLocale',
              'First weekday, clock and date formats for a context.',
            ),
            ('dsCompareText', 'int', 'Dictionary order for a `language` code.'),
            ('DsCollationKey', 'class', 'A sort key, read once per string.'),
            ('dsFoldCase', 'String', 'Case folding for matching.'),
          ]),
        ],
      ),
    ],
  );
}

class _LocaleDemo extends StatefulWidget {
  const _LocaleDemo();

  @override
  State<_LocaleDemo> createState() => _LocaleDemoState();
}

class _LocaleDemoState extends State<_LocaleDemo> {
  String _key = 'de';
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final locale = previewLocaleOf(_key);
    return Column(
      spacing: 20,
      children: [
        SizedBox(
          width: 240,
          child: DsField(
            label: const Text('Language'),
            child: DsSelect<String>(
              value: _key,
              onChanged: (v) => setState(() => _key = v ?? _key),
              options: [
                for (final MapEntry(:key, :value) in previewLanguages.entries)
                  DsSelectOption(value: key, label: value),
              ],
            ),
          ),
        ),
        // #region l10n-locale
        Localizations.override(
          context: context,
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: DsCalendar(
              value: _day,
              onChanged: (d) => setState(() => _day = d),
            ),
          ),
        ),
        // #endregion
      ],
    );
  }
}

/// English strings with a more specific select prompt.
class ProductStrings extends DsLocalizationsEn {
  const ProductStrings();

  @override
  String get selectPlaceholder => 'Choose a project';

  @override
  String get selectNoResults => 'No projects match';
}

class _OverrideDemo extends StatefulWidget {
  const _OverrideDemo();

  @override
  State<_OverrideDemo> createState() => _OverrideDemoState();
}

class _OverrideDemoState extends State<_OverrideDemo> {
  String? _project;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    // #region l10n-override
    child: DsLocalizationScope(
      overrides: const {'en': ProductStrings()},
      child: DsSelect<String>(
        value: _project,
        onChanged: (v) => setState(() => _project = v),
        semanticLabel: 'Project',
        options: const [
          DsSelectOption(value: 'web', label: 'Website redesign'),
          DsSelectOption(value: 'app', label: 'Mobile app'),
          DsSelectOption(value: 'docs', label: 'Documentation'),
        ],
      ),
    ),
    // #endregion
  );
}

class _DateTable extends StatelessWidget {
  const _DateTable();

  static const _locales = [
    Locale('en', 'US'),
    Locale('en', 'GB'),
    Locale('fr', 'CA'),
    Locale('de', 'DE'),
    Locale('ko', 'KR'),
    Locale('pl', 'PL'),
    Locale('tr', 'TR'),
    Locale('ar', 'EG'),
    Locale('ja', 'JP'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final k = t.colors;
    final date = DateTime(2026, 3, 4);
    Text cell(String s) => Text(s, style: y.small.copyWith(color: k.text));
    return DocTable(
      columns: const ['Locale', 'Week starts', 'Date', 'Time'],
      flex: const [2, 3, 4, 2],
      rows: [
        for (final locale in _locales)
          () {
            final strings = DsLocalizations.resolve(locale);
            final l = DsDateLocale.resolve(locale, strings);
            final sunday = DateTime(2026, 3, 1);
            final first = sunday.add(Duration(days: l.firstDayOfWeek % 7));
            // Each value reads in its own direction.
            Widget own(Widget child) => Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              // Kept on the table's side, in an LTR table.
              child: Align(alignment: Alignment.centerLeft, child: child),
            );
            return <Widget>[
              Text(
                locale.toString(),
                style: y.mono(y.small).copyWith(color: k.text),
              ),
              own(cell(DsDateFormat('EEEE', strings: strings).format(first))),
              own(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    cell(l.shortDate.format(date)),
                    Caption(l.mediumDate.format(date)),
                  ],
                ),
              ),
              own(cell(l.time.formatTime(const DsTime(14, 30)))),
            ];
          }(),
      ],
    );
  }
}

class _SortDemo extends StatelessWidget {
  const _SortDemo();

  static const names = [
    'Zeynep',
    'çağla',
    'Cem',
    'Ümit',
    'ılgın',
    'İpek',
    'Irmak',
    'deniz',
    'Şule',
    'Selin',
    'Ömer',
    'Oğuz',
  ];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final y = t.typography;
    final k = t.colors;
    final byCodePoint = [...names]..sort();
    // #region l10n-sort
    final sorted = [...names]
      ..sort((a, b) => dsCompareText(a, b, language: 'tr'));
    // #endregion
    Widget column(String title, List<String> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: y.mono(y.caption).copyWith(color: k.textMuted)),
        const SizedBox(height: 4),
        for (final n in list) Text(n, style: y.small.copyWith(color: k.text)),
      ],
    );
    return Wrap(
      spacing: 56,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        column('compareTo', byCodePoint),
        column("dsCompareText, 'tr'", sorted),
      ],
    );
  }
}
