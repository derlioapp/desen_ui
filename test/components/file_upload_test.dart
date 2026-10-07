import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// File upload: `DsFileUpload`, `DsFileItem`,
/// `dsFormatFileSize`.
void main() {
  /// A host with a locale (for size formatting) and announcement support.
  Widget app(
    Widget child, {
    Locale locale = const Locale('tr'),
    bool announce = true,
    double width = 420,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQueryData.fromView(View.of(context)).copyWith(
        supportsAnnounce: announce,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );

  DsDashedBorder edge(WidgetTester tester) =>
      tester.widget<DsDashedBorder>(find.byType(DsDashedBorder));

  group('dsFormatFileSize', () {
    String tr(int b) => dsFormatFileSize(b, locale: const Locale('tr'));
    String en(int b) => dsFormatFileSize(b, locale: const Locale('en'));

    test('steps by 1000; KB whole, MB and up with one decimal', () {
      expect(tr(512), '512 B');
      expect(tr(840000), '840 KB');
      expect(tr(1500), '2 KB');
      expect(tr(2400000), '2,4 MB');
      expect(tr(10000000), '10 MB', reason: 'a zero decimal is dropped');
      expect(tr(999999), '1 MB', reason: 'rounds up into the next unit');
      expect(tr(1250000000), '1,3 GB');
      expect(tr(-5), '0 B');
    });

    test('decimal separator and units follow the locale', () {
      expect(en(2400000), '2.4 MB');
      expect(dsFormatFileSize(2400000, locale: const Locale('de')), '2,4 MB');
      expect(dsFormatFileSize(2400000, locale: const Locale('fr')), '2,4 Mo');
      expect(dsFormatFileSize(840000, locale: const Locale('ru')), '840 КБ');
    });

    test('progress shares the unit when it can', () {
      expect(
        dsFormatFileProgress(2400000, 3100000, locale: const Locale('tr')),
        '2,4 / 3,1 MB',
      );
      expect(
        dsFormatFileProgress(840000, 3100000, locale: const Locale('tr')),
        '840 KB / 3,1 MB',
      );
    });
  });

  group('DsFileUpload', () {
    testWidgets('works without DsScope; shows the localized prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: DsFileUpload(
              onBrowse: () {},
              description: const Text('PDF, PNG · en fazla 10 MB'),
            ),
          ),
        ),
      );
      expect(find.byType(DsDashedBorder), findsOneWidget);
      expect(
        find.textContaining('Drop files here or browse', findRichText: true),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(DsFileUpload)).height, 104);
    });

    testWidgets('keyboard: one Tab stop; Enter and Space browse', (
      tester,
    ) async {
      var browsed = 0;
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('tr'),
          home: Center(
            child: SizedBox(
              width: 420,
              child: DsFileUpload(
                onBrowse: () => browsed++,
                files: [DsFileItem(name: 'a.pdf', size: 1000, onRemove: () {})],
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final zone = FocusManager.instance.primaryFocus!;
      expect(
        zone.context!.findAncestorWidgetOfExactType<DsFileUpload>(),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(browsed, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(browsed, 2);
      // The next stop is the row's remove button: the zone has no inner
      // stops.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<DsButton>()
            ?.semanticLabel,
        'Kaldır: a.pdf',
      );
    });

    testWidgets('a click anywhere on the zone browses', (tester) async {
      var browsed = 0;
      await tester.pumpWidget(app(DsFileUpload(onBrowse: () => browsed++)));
      await tester.tapAt(
        tester.getTopLeft(find.byType(DsFileUpload)) + const Offset(12, 12),
      );
      expect(browsed, 1);
    });

    testWidgets('dragging: the accent edge, a tint and the drop prompt', (
      tester,
    ) async {
      final theme = DsThemeData.light();
      Widget zone(bool dragging) => app(
        DsTheme(
          data: theme,
          child: DsFileUpload(onBrowse: () {}, dragging: dragging),
        ),
      );
      await tester.pumpWidget(zone(false));
      expect(edge(tester).color, theme.colors.borderField);
      expect(find.text('Yüklemek için bırakın'), findsNothing);
      await tester.pumpWidget(zone(true));
      await tester.pumpAndSettle();
      expect(edge(tester).color, theme.colors.indicator);
      expect(find.text('Yüklemek için bırakın'), findsOneWidget);
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DsFileUpload),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        (box.decoration! as DsBoxDecoration).color,
        Color.alphaBlend(theme.colors.accentTint, theme.colors.surface),
      );
    });

    testWidgets('disabled: no focus, no browse, faint look', (tester) async {
      final theme = DsThemeData.light();
      await tester.pumpWidget(
        app(DsTheme(data: theme, child: const DsFileUpload(onBrowse: null))),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<DsFileUpload>(),
        isNull,
      );
      expect(edge(tester).color, theme.colors.border);
      final handle = tester.ensureSemantics();
      await tester.pump();
      final data = tester
          .getSemantics(find.byType(DsDashedBorder))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });

    testWidgets('in a DsField: the error edge (2px), invalid, named by the '
        'label; rows keep their own nodes', (tester) async {
      final theme = DsThemeData.light();
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsTheme(
            data: theme,
            child: DsField(
              label: const Text('Ekler'),
              errorText: 'En az bir dosya ekleyin.',
              required: true,
              child: DsFileUpload(
                onBrowse: () {},
                description: const Text('PDF · en fazla 10 MB'),
                files: [DsFileItem(name: 'a.pdf', size: 1000, onRemove: () {})],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(edge(tester).width, 2);
      expect(edge(tester).color, dsErrorEdgeForTest(theme));
      final zone = tester
          .getSemantics(find.byType(DsDashedBorder))
          .getSemanticsData();
      expect(zone.validationResult, SemanticsValidationResult.invalid);
      expect(zone.label, contains('Ekler'));
      expect(zone.label, contains('Dosyaları buraya bırakın ya da seçin'));
      expect(zone.label, contains('PDF · en fazla 10 MB'));
      expect(zone.flagsCollection.isRequired.toBoolOrNull(), isTrue);
      expect(find.bySemanticsLabel('Kaldır: a.pdf'), findsOneWidget);
      expect(
        find.textContaining('En az bir dosya ekleyin.', findRichText: true),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the files are a list of list items', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsFileUpload(
            onBrowse: () {},
            files: const [
              DsFileItem(name: 'a.pdf', size: 1000),
              DsFileItem(name: 'b.pdf', size: 2000),
            ],
          ),
        ),
      );
      final item = tester.getSemantics(find.text('a.pdf'));
      SemanticsNode? node = item;
      while (node != null &&
          node.getSemanticsData().role != SemanticsRole.listItem) {
        node = node.parent;
      }
      expect(node, isNotNull);
      expect(node!.parent!.getSemanticsData().role, SemanticsRole.list);
      handle.dispose();
    });

    testWidgets('RTL, 2.0 text at 358px and in a Row', (tester) async {
      await tester.pumpWidget(
        app(
          DsFileUpload(
            onBrowse: () {},
            description: const Text('PDF, PNG · en fazla 10 MB'),
            files: [
              DsFileItem(
                name: 'çok-uzun-bir-dosya-adı-2025-final-v3.pdf',
                size: 3100000,
                status: DsFileStatus.uploading,
                progress: .78,
                onCancel: () {},
              ),
              DsFileItem(
                name: 'rapor.xlsx',
                status: DsFileStatus.error,
                message: 'Desteklenmeyen dosya türü',
                onRetry: () {},
                onRemove: () {},
              ),
            ],
          ),
          width: 358,
          direction: TextDirection.rtl,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsFileUpload(
                onBrowse: () {},
                files: const [DsFileItem(name: 'a.pdf', size: 1000)],
              ),
            ],
          ),
          width: 600,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DsFileItem', () {
    testWidgets('uploading: size, percentage, progress value and cancel', (
      tester,
    ) async {
      var canceled = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsFileItem(
            name: 'sunum-v3.pdf',
            size: 3100000,
            status: DsFileStatus.uploading,
            progress: .78,
            onCancel: () => canceled++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2,4 / 3,1 MB · %78'), findsOneWidget);
      // One node says it all: the bar's progress is the item's value.
      final item = tester
          .getSemantics(find.text('sunum-v3.pdf'))
          .getSemanticsData();
      expect(item.role, SemanticsRole.progressBar);
      expect(item.label, 'sunum-v3.pdf\nYükleniyor\n2,4 / 3,1\u00a0MB');
      expect(item.value, '78%');
      await tester.tap(
        find.bySemanticsLabel('sunum-v3.pdf yüklemesini iptal et'),
      );
      expect(canceled, 1);
      handle.dispose();
    });

    testWidgets('done: success icon, size and remove', (tester) async {
      var removed = 0;
      final theme = DsThemeData.light();
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsTheme(
            data: theme,
            child: DsFileItem(
              name: 'kapak.png',
              size: 840000,
              onRemove: () => removed++,
            ),
          ),
        ),
      );
      expect(find.text('840 KB'), findsOneWidget);
      final icon = tester.widget<DsIcon>(
        find
            .descendant(
              of: find.byType(DsFileItem),
              matching: find.byType(DsIcon),
            )
            .first,
      );
      expect(icon.icon, DsIcons.circleCheck);
      expect(
        DsColorUtils.contrastRatio(icon.color!, theme.colors.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        find.bySemanticsLabel(RegExp('kapak.png yüklendi')),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Kaldır: kapak.png'));
      expect(removed, 1);
      handle.dispose();
    });

    testWidgets('error: 2px error edge, message, retry and remove', (
      tester,
    ) async {
      var retried = 0;
      final theme = DsThemeData.dark();
      await tester.pumpWidget(
        app(
          DsTheme(
            data: theme,
            child: DsFileItem(
              name: 'rapor.xlsx',
              status: DsFileStatus.error,
              message: 'Desteklenmeyen dosya türü',
              onRetry: () => retried++,
              onRemove: () {},
            ),
          ),
        ),
      );
      expect(find.text('Desteklenmeyen dosya türü'), findsOneWidget);
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DsFileItem),
              matching: find.byType(Container),
            )
            .first,
      );
      final ring = (box.decoration! as DsBoxDecoration).shadows.single;
      expect(ring, DsShadow.innerRing(dsErrorEdgeForTest(theme), width: 2));
      await tester.tap(find.text('Yeniden dene'));
      expect(retried, 1);
      // Without a message, the localized fallback.
      await tester.pumpWidget(
        app(const DsFileItem(name: 'x.pdf', status: DsFileStatus.error)),
      );
      expect(find.text('Yüklenemedi'), findsOneWidget);
    });

    testWidgets('retry is named with the file, like cancel and remove (site)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in ['a.pdf', 'b.pdf'])
                DsFileItem(
                  name: name,
                  status: DsFileStatus.error,
                  onRetry: () {},
                  onRemove: () {},
                ),
            ],
          ),
        ),
      );
      // The visible word stays short; the name carries it (label in name).
      expect(find.text('Yeniden dene'), findsNWidgets(2));
      for (final name in ['a.pdf', 'b.pdf']) {
        expect(
          find.bySemanticsLabel('$name yüklemesini yeniden dene'),
          findsOneWidget,
        );
      }
      handle.dispose();
    });

    testWidgets('state changes are announced politely, once', (tester) async {
      final handle = tester.ensureSemantics();
      Widget item(DsFileStatus status, {String? error}) => app(
        DsFileItem(
          name: 'a.pdf',
          size: 1000,
          status: status,
          progress: .5,
          message: error,
        ),
      );
      await tester.pumpWidget(item(DsFileStatus.uploading));
      expect(tester.takeAnnouncements(), isEmpty);
      await tester.pumpWidget(item(DsFileStatus.done));
      final done = tester.takeAnnouncements().single;
      expect(done.message, 'a.pdf yüklendi');
      expect(done.assertiveness, Assertiveness.polite);
      await tester.pumpWidget(item(DsFileStatus.error, error: 'Ağ hatası'));
      expect(
        tester.takeAnnouncements().single.message,
        'a.pdf yüklenemedi\nAğ hatası',
      );
      await tester.pumpWidget(item(DsFileStatus.error, error: 'Ağ hatası'));
      expect(tester.takeAnnouncements(), isEmpty);
      // Not a live region as well (it would be heard twice).
      expect(
        tester
            .getSemantics(find.text('a.pdf'))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('without announcements (Android) the state is a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(const DsFileItem(name: 'a.pdf', size: 1000), announce: false),
      );
      await tester.pumpWidget(
        app(
          const DsFileItem(name: 'a.pdf', status: DsFileStatus.error),
          announce: false,
        ),
      );
      expect(tester.takeAnnouncements(), isEmpty);
      expect(
        tester
            .getSemantics(find.text('a.pdf'))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('uploading is read once, with its progress', (tester) async {
      final handle = tester.ensureSemantics();
      for (final progress in [.4, null]) {
        await tester.pumpWidget(
          app(
            DsFileItem(
              name: 'a.pdf',
              status: DsFileStatus.uploading,
              progress: progress,
            ),
          ),
        );
        // The indeterminate bar keeps moving: no settling.
        await tester.pump(const Duration(milliseconds: 300));
        final nodes = find.semantics.byPredicate(
          (n) => n.getSemanticsData().label.contains('a.pdf'),
        );
        expect(nodes, findsOne, reason: 'no second node for the bar');
        final data = tester.getSemantics(find.text('a.pdf')).getSemanticsData();
        expect(data.label, 'a.pdf\nYükleniyor', reason: 'said once');
        expect(data.value, progress == null ? '' : '40%');
      }
      handle.dispose();
    });

    testWidgets('indeterminate progress says uploading', (tester) async {
      await tester.pumpWidget(
        app(const DsFileItem(name: 'a.pdf', status: DsFileStatus.uploading)),
      );
      expect(find.text('Yükleniyor'), findsOneWidget);
      expect(
        tester.widget<DsProgressBar>(find.byType(DsProgressBar)).value,
        isNull,
      );
    });
  });
}

/// The error edge the controls use (`dsErrorEdge` is internal).
Color dsErrorEdgeForTest(DsThemeData theme) =>
    theme.shadows.fieldError.firstOrNull?.color ?? theme.colors.danger.text;
