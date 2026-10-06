import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Greek extends DsLocalizationsEn {
  const _Greek();

  @override
  String get close => 'Κλείσιμο';
}

/// KALITE K-51: localized strings.
void main() {
  Future<DsLocalizations> resolve(
    WidgetTester tester, {
    Locale? locale,
    Widget Function(Widget child)? wrap,
  }) async {
    late DsLocalizations result;
    Widget probe = Builder(
      builder: (context) {
        result = DsLocalizations.of(context);
        return const SizedBox();
      },
    );
    if (wrap != null) probe = wrap(probe);
    await tester.pumpWidget(
      locale == null
          ? probe
          : Localizations(
              locale: locale,
              delegates: const [DefaultWidgetsLocalizations.delegate],
              child: probe,
            ),
    );
    return result;
  }

  testWidgets('follows the app language; English without an app root', (
    tester,
  ) async {
    expect((await resolve(tester)).close, 'Close');
    expect((await resolve(tester, locale: const Locale('tr'))).close, 'Kapat');
    expect(
      (await resolve(tester, locale: const Locale('tr', 'TR'))).nextPage,
      'Sonraki sayfa',
    );
    expect(
      (await resolve(tester, locale: const Locale('xx'))).close,
      'Close',
      reason: 'unknown languages fall back to English',
    );
  });

  testWidgets('a scope adds a language; a partial one falls back per key', (
    tester,
  ) async {
    final greek = await resolve(
      tester,
      locale: const Locale('el'),
      wrap: (child) =>
          DsLocalizationScope(overrides: const {'el': _Greek()}, child: child),
    );
    expect(greek.close, 'Κλείσιμο');
    expect(greek.cancel, 'Cancel');
    final forced = await resolve(
      tester,
      locale: const Locale('de'),
      wrap: (child) => DsLocalizationScope(
        localizations: const DsLocalizationsTr(),
        child: child,
      ),
    );
    expect(forced.confirm, 'Onayla');
  });

  test('every bundled language translates every key', () {
    const en = DsLocalizationsEn();
    for (final MapEntry(key: code, value: l)
        in dsBundledLocalizations.entries) {
      expect(l.localeName, code);
      if (code == 'en') continue;
      for (final (name, value, english) in [
        ('close', l.close, en.close),
        ('cancel', l.cancel, en.cancel),
        ('confirm', l.confirm, en.confirm),
        ('previousPage', l.previousPage, en.previousPage),
        ('nextPage', l.nextPage, en.nextPage),
        ('selectNoResults', l.selectNoResults, en.selectNoResults),
        ('loading', l.loading, en.loading),
        ('moreCount', l.moreCount(3), en.moreCount(3)),
        ('page', l.page(2), en.page(2)),
        ('pageOf', l.pageOf(2, 9), en.pageOf(2, 9)),
        ('tabOf', l.tabOf(2, 4), en.tabOf(2, 4)),
        ('currentPage', l.currentPage, en.currentPage),
        ('pagination', l.pagination, en.pagination),
        ('breadcrumb', l.breadcrumb, en.breadcrumb),
        ('warning', l.warning, en.warning),
        ('success', l.success, en.success),
        ('selected', l.selected, en.selected),
        ('notification', l.notification, en.notification),
        ('dismissNotification', l.dismissNotification, en.dismissNotification),
        ('dialog', l.dialog, en.dialog),
        ('more', l.more, en.more),
        ('required', l.required, en.required),
        ('increase', l.increase, en.increase),
        ('decrease', l.decrease, en.decrease),
        ('clear', l.clear, en.clear),
        ('search', l.search, en.search),
        ('cut', l.cut, en.cut),
        ('copy', l.copy, en.copy),
        ('paste', l.paste, en.paste),
        ('selectAll', l.selectAll, en.selectAll),
        ('lookUp', l.lookUp, en.lookUp),
        ('share', l.share, en.share),
        ('searchWeb', l.searchWeb, en.searchWeb),
        ('showPassword', l.showPassword, en.showPassword),
        ('hidePassword', l.hidePassword, en.hidePassword),
        (
          'characterCountLabel',
          l.characterCountLabel(12, 100),
          en.characterCountLabel(12, 100),
        ),
        (
          'charactersRemaining',
          l.charactersRemaining(3),
          en.charactersRemaining(3),
        ),
        ('charactersOver', l.charactersOver(3), en.charactersOver(3)),
        ('fieldRequired', l.fieldRequired, en.fieldRequired),
        ('textTooShort', l.textTooShort(3), en.textTooShort(3)),
        ('textTooLong', l.textTooLong(3), en.textTooLong(3)),
        ('invalidEmail', l.invalidEmail, en.invalidEmail),
      ]) {
        // Words that are the same in English and French.
        if (code == 'fr' &&
            {'page', 'pagination', 'notification'}.contains(name)) {
          continue;
        }
        expect(value, isNot(english), reason: '$code.$name is untranslated');
      }
    }
  });

  // Every key, with sample arguments, by name.
  Map<String, String> strings(DsLocalizations l) => {
    'close': l.close,
    'cancel': l.cancel,
    'confirm': l.confirm,
    'dismiss': l.dismiss,
    'previousPage': l.previousPage,
    'nextPage': l.nextPage,
    'selectPlaceholder': l.selectPlaceholder,
    'selectNoResults': l.selectNoResults,
    'selectResultCount': l.selectResultCount(3),
    'loading': l.loading,
    'percent': l.percent(40),
    'moreCount': l.moreCount(3),
    'overflowCount': l.overflowCount(3),
    'countOverflow': l.countOverflow(99),
    'page': l.page(2),
    'pageOf': l.pageOf(2, 9),
    'tabOf': l.tabOf(2, 4),
    'navigation': l.navigation,
    'currentPage': l.currentPage,
    'pagination': l.pagination,
    'breadcrumb': l.breadcrumb,
    'error': l.error,
    'warning': l.warning,
    'success': l.success,
    'info': l.info,
    'selected': l.selected,
    'notification': l.notification,
    'dismissNotification': l.dismissNotification,
    'dialog': l.dialog,
    'more': l.more,
    'required': l.required,
    'increase': l.increase,
    'decrease': l.decrease,
    'clear': l.clear,
    'search': l.search,
    'cut': l.cut,
    'copy': l.copy,
    'paste': l.paste,
    'selectAll': l.selectAll,
    'lookUp': l.lookUp,
    'share': l.share,
    'searchWeb': l.searchWeb,
    'showPassword': l.showPassword,
    'hidePassword': l.hidePassword,
    'characterCount': l.characterCount(12, 100),
    'characterCountLabel': l.characterCountLabel(12, 100),
    'charactersRemaining': l.charactersRemaining(3),
    'charactersOver': l.charactersOver(3),
    'fieldRequired': l.fieldRequired,
    'textTooShort': l.textTooShort(3),
    'textTooLong': l.textTooLong(3),
    'invalidEmail': l.invalidEmail,
  };

  group('regional locales', () {
    testWidgets('the most specific match wins; unknown parts fall back', (
      tester,
    ) async {
      Future<String> name(Locale locale) async =>
          (await resolve(tester, locale: locale)).localeName;
      const zh = 'zh', hant = 'Hant', hans = 'Hans';
      expect(await name(const Locale(zh, 'TW')), 'zh_Hant');
      expect(await name(const Locale(zh, 'HK')), 'zh_Hant');
      expect(await name(const Locale(zh, 'MO')), 'zh_Hant');
      expect(
        await name(
          const Locale.fromSubtags(languageCode: zh, scriptCode: hant),
        ),
        'zh_Hant',
      );
      expect(
        await name(
          const Locale.fromSubtags(
            languageCode: zh,
            scriptCode: hant,
            countryCode: 'CN',
          ),
        ),
        'zh_Hant',
        reason: 'an explicit script beats the region',
      );
      expect(
        await name(
          const Locale.fromSubtags(
            languageCode: zh,
            scriptCode: hans,
            countryCode: 'TW',
          ),
        ),
        'zh',
        reason: 'Simplified in Taiwan stays Simplified',
      );
      expect(await name(const Locale(zh, 'CN')), 'zh');
      expect(await name(const Locale(zh)), 'zh');
      expect(await name(const Locale('pt', 'BR')), 'pt');
      expect(await name(const Locale('pt', 'PT')), 'pt_PT');
      expect(await name(const Locale('pt')), 'pt');
      expect(
        await name(const Locale('de', 'CH')),
        'de',
        reason: 'an unknown region falls back to the language',
      );
      expect(
        await name(const Locale('xx', 'YY')),
        'en',
        reason: 'an unknown language falls back to English',
      );
      expect(
        (await resolve(tester, locale: const Locale(zh, 'TW'))).nextPage,
        '下一頁',
      );
      expect(
        (await resolve(tester, locale: const Locale('pt', 'PT'))).loading,
        'A carregar',
      );
    });

    test('lookup keys, most specific first', () {
      expect(DsLocalizations.lookupKeys(const Locale('zh', 'TW')), [
        'zh_Hant_TW',
        'zh_Hant',
        'zh_TW',
        'zh',
      ]);
      expect(DsLocalizations.lookupKeys(const Locale('pt', 'BR')), [
        'pt_BR',
        'pt',
      ]);
      expect(
        DsLocalizations.lookupKeys(
          const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
        ),
        ['sr_Latn', 'sr'],
      );
      expect(DsLocalizations.lookupKeys(const Locale('tr')), ['tr']);
      expect(DsLocalizations.lookupKeys(const Locale('tr', '')), ['tr']);
      expect(DsLocalizations.resolve(null).localeName, 'en');
    });

    testWidgets('scope overrides take regional keys', (tester) async {
      Widget scoped(Widget child) => DsLocalizationScope(
        overrides: const {'pt_BR': _Greek(), 'zh': DsLocalizationsTr()},
        child: child,
      );
      expect(
        (await resolve(
          tester,
          locale: const Locale('pt', 'BR'),
          wrap: scoped,
        )).close,
        'Κλείσιμο',
      );
      expect(
        (await resolve(tester, locale: const Locale('pt'), wrap: scoped)).close,
        'Fechar',
        reason: 'pt_BR overrides do not leak to plain pt',
      );
      expect(
        (await resolve(tester, locale: const Locale('zh'), wrap: scoped)).close,
        'Kapat',
      );
      expect(
        (await resolve(
          tester,
          locale: const Locale('zh', 'TW'),
          wrap: scoped,
        )).close,
        '關閉',
        reason: 'the bundled zh_Hant is more specific than a zh override',
      );
    });

    test('Traditional Chinese translates every key', () {
      final en = strings(const DsLocalizationsEn());
      final hant = strings(const DsLocalizationsZhHant());
      // Characters that exist only in Simplified, as used by `zh`.
      const simplified = '关闭认页选择无结个载当错误话对还减请确导';
      for (final MapEntry(:key, :value) in hant.entries) {
        for (final char in simplified.split('')) {
          expect(
            value.contains(char),
            isFalse,
            reason: 'zh_Hant.$key "$value" has the Simplified $char',
          );
        }
        // Numbers and symbols are written the same way in both.
        if ({
          'percent',
          'overflowCount',
          'countOverflow',
          'characterCount',
        }.contains(key)) {
          continue;
        }
        expect(value, isNot(en[key]), reason: 'zh_Hant.$key is English');
      }
      expect(hant['pageOf'], '第 2 頁，共 9 頁');
    });

    test('European Portuguese differs from Brazilian only where needed', () {
      final br = strings(const DsLocalizationsPt());
      final pt = strings(const DsLocalizationsPtPt());
      final differ = {
        for (final key in br.keys)
          if (br[key] != pt[key]) key,
      };
      expect(differ, {
        'dismiss',
        'dismissNotification',
        'loading',
        'nextPage',
        'breadcrumb',
        'cut',
        'lookUp',
        'share',
        'showPassword',
        'hidePassword',
        'characterCountLabel',
        'charactersRemaining',
        'charactersOver',
        'textTooShort',
        'textTooLong',
        'invalidEmail',
        'tabOf',
      });
      expect(pt['nextPage'], 'Página seguinte');
      expect(br['nextPage'], 'Próxima página');
    });
  });

  test('percentages follow local typography', () {
    expect(const DsLocalizationsEn().percent(40), '40%');
    expect(const DsLocalizationsTr().percent(40), '%40');
    expect(const DsLocalizationsFr().percent(40), '40\u202F%');
    expect(const DsLocalizationsDe().percent(40), '40\u00A0%');
    expect(const DsLocalizationsJa().percent(40), '40%');
  });

  test('counts and pages', () {
    const en = DsLocalizationsEn(), tr = DsLocalizationsTr();
    expect(en.countOverflow(99), '99+');
    expect(en.overflowCount(3), '+3');
    expect(en.moreCount(3), '3 more');
    expect(tr.moreCount(3), '3 tane daha');
    expect(en.pageOf(3, 10), 'Page 3 of 10');
    expect(tr.pageOf(3, 10), '3. sayfa, toplam 10');
    expect(en.tabOf(2, 4), 'Tab 2 of 4');
    expect(tr.tabOf(2, 4), '2. sekme, toplam 4');
    expect(en.navigation, 'Navigation');
    expect(tr.navigation, 'Gezinme');
  });

  // F-15, S-14: announced values come from the app language.
  testWidgets('progress, slider, avatar group and count speak the language', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('tr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DsProgressBar(value: .4),
                  const DsProgressBar(),
                  DsSlider(value: .25, onChanged: (_) {}),
                  const DsAvatarGroup(
                    max: 2,
                    avatars: [
                      DsAvatar(initials: 'AL'),
                      DsAvatar(initials: 'GH'),
                      DsAvatar(initials: 'MD'),
                    ],
                  ),
                  const DsCount(120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // A progress bar's value stays machine-readable (Flutter's progress-bar
    // role requires "N%"); the screen reader speaks it in the language.
    expect(tester.getSemantics(find.byType(DsProgressBar).first).value, '40%');
    expect(
      tester.getSemantics(find.byType(DsProgressBar).last).label,
      'Yükleniyor',
    );
    expect(
      find.bySemanticsLabel('2 tane daha'),
      findsOneWidget,
      reason: 'the +N bubble is announced as words',
    );
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(tester.semantics.find(find.byType(DsSlider)).value, '%25');
    semantics.dispose();
  });

  test('plurals', () {
    expect(const DsLocalizationsEn().selectResultCount(1), '1 result');
    expect(const DsLocalizationsEn().selectResultCount(3), '3 results');
    const ru = DsLocalizationsRu();
    expect(ru.selectResultCount(1), '1 результат');
    expect(ru.selectResultCount(3), '3 результата');
    expect(ru.selectResultCount(5), '5 результатов');
    expect(ru.selectResultCount(11), '11 результатов');
    expect(ru.selectResultCount(22), '22 результата');
  });

  test('the character counter reads and plurals per language', () {
    const en = DsLocalizationsEn();
    expect(en.characterCount(12, 100), '12 / 100');
    expect(en.characterCountLabel(12, 100), '12 of 100 characters');
    expect(en.charactersRemaining(1), '1 character left');
    expect(en.charactersRemaining(4), '4 characters left');
    expect(en.charactersOver(1), '1 character too many');
    expect(en.charactersOver(14), '14 characters too many');
    expect(const DsLocalizationsTr().charactersOver(14), '14 karakter fazla');
    const ru = DsLocalizationsRu();
    expect(ru.characterCountLabel(3, 21), '3 из 21 символа');
    expect(ru.characterCountLabel(3, 100), '3 из 100 символов');
    expect(ru.charactersRemaining(1), 'Остался 1 символ');
    expect(ru.charactersRemaining(3), 'Осталось 3 символа');
    expect(ru.charactersRemaining(11), 'Осталось 11 символов');
    expect(const DsLocalizationsTr().searchWeb, "Web'de ara");
    expect(const DsLocalizationsDe().characterCount(12, 100), '12 / 100');
  });

  test('case folding matches Turkish, German and Greek', () {
    expect(dsFoldCase('ISPARTA'), dsFoldCase('ısparta'));
    expect(dsFoldCase('İstanbul'), dsFoldCase('istanbul'));
    expect(dsFoldCase('Straße'), dsFoldCase('STRASSE'));
    expect(dsFoldCase('λόγος'), dsFoldCase('λόγοσ'));
    expect(dsFoldCase('résumé'), isNot(dsFoldCase('resume')));
  });

  testWidgets('pagination reads its labels from the app language', (
    tester,
  ) async {
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('tr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DsPagination(page: 1, pageCount: 3, onChanged: (_) {}),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Önceki sayfa'), findsOneWidget);
    expect(find.bySemanticsLabel('Sonraki sayfa'), findsOneWidget);
  });

  testWidgets('DsApp with only a locale gets that language', (tester) async {
    late DsLocalizations strings;
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) {
            strings = DsLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(strings, isA<DsLocalizationsTr>());
  });

  test('supported locales list every bundled language, English first', () {
    final locales = DsLocalizations.supportedLocales;
    expect(locales.first, const Locale('en'));
    expect(locales, contains(const Locale('tr')));
    expect(locales, contains(const Locale('pt', 'PT')));
    expect(
      locales,
      contains(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
    );
  });
}
