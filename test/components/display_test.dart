import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Behavior of the display components.
void main() {
  final light = DsThemeData();

  testWidgets('every display component works without any scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: Column(
            children: [
              const DsBadge(label: Text('Taslak')),
              const DsCount(3),
              const DsStatusDot(label: Text('Çevrimiçi')),
              const DsAvatar(initials: 'AK'),
              const DsAvatarGroup(avatars: [DsAvatar(initials: 'A')]),
              const DsCard(child: Text('kart')),
              const DsAlert(title: Text('uyarı')),
              const SizedBox(width: 200, child: DsProgressBar(value: .5)),
              const DsProgressRing(value: .5),
              const DsShimmer(child: DsSkeleton(width: 100)),
              DsLink(label: 'bağlantı', onPressed: () {}),
              const DsBreadcrumb(items: [DsBreadcrumbItem(label: 'A')]),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('display components grow with 2x text instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: Column(
            children: [
              const DsBadge(status: .warning, label: Text('İncelemede')),
              const DsCount(128),
              const DsStatusDot(label: Text('Çevrimiçi')),
              const DsAvatar(initials: 'MD', size: .sm),
              DsBreadcrumb(
                items: [
                  DsBreadcrumbItem(label: 'Projeler', onPressed: () {}),
                  const DsBreadcrumbItem(label: 'Ayarlar'),
                ],
              ),
              DsLink(label: 'kılavuz', onPressed: () {}),
            ],
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DsBadge)).height, greaterThan(22));
  });

  group('DsBadge and DsCount', () {
    testWidgets('badge uses its status tint and ink, with a dot', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DsBadge(status: .success, label: Text('Yayında')),
          theme: light,
        ),
      );
      final box = tester.widget<Container>(find.byType(Container).first);
      expect(
        (box.decoration! as DsBoxDecoration).color,
        light.colors.success.tint,
      );
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Yayında'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, light.colors.success.text);
      // The 6px dot.
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 6,
        ),
        findsOneWidget,
      );
    });

    testWidgets('count caps at max and reads as text', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DsCount(128, tone: .danger), theme: light),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(DsCount)),
        isSemantics(label: '99+'),
      );
      semantics.dispose();
    });

    testWidgets('anchored badge sits on the end corner, mirrored in RTL', (
      tester,
    ) async {
      Future<double> badgeX(TextDirection d) async {
        await tester.pumpWidget(
          host(
            const DsAnchoredBadge(
              badge: DsCount(1),
              child: SizedBox(width: 40, height: 40),
            ),
            direction: d,
          ),
        );
        return tester.getCenter(find.byType(DsCount)).dx -
            tester.getCenter(find.byType(SizedBox).last).dx;
      }

      expect(await badgeX(TextDirection.ltr), greaterThan(0));
      expect(await badgeX(TextDirection.rtl), lessThan(0));
    });
  });

  group('DsAvatar', () {
    testWidgets('sizes follow the scale; initials are the label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final (size, d) in [
        (DsSize.xs, 24.0),
        (DsSize.sm, 32.0),
        (DsSize.md, 40.0),
        (DsSize.lg, 48.0),
      ]) {
        await tester.pumpWidget(host(DsAvatar(initials: 'AK', size: size)));
        expect(tester.getSize(find.byType(DsAvatar)), Size(d, d));
      }
      expect(
        tester.getSemantics(find.byType(DsAvatar)),
        isSemantics(label: 'AK'),
      );
      semantics.dispose();
    });

    test('toneFor is stable and in range', () {
      expect(DsAvatar.toneFor('Ayşe Kaya'), DsAvatar.toneFor('Ayşe Kaya'));
      for (final name in ['a', 'Mehmet', 'Zeynep Ö', '']) {
        expect(
          DsAvatar.toneFor(name),
          inInclusiveRange(0, DsAvatar.toneCount - 1),
        );
      }
    });

    test('tones differ from each other', () {
      final k = light.colors;
      final backgrounds = {
        for (var i = 0; i < DsAvatar.toneCount; i++)
          DsAvatar.toneColors(k, i).$1,
      };
      expect(backgrounds.length, DsAvatar.toneCount);
    });

    testWidgets('group shows +N past max and gives neighbors different tones', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DsAvatarGroup(
            max: 3,
            avatars: [
              DsAvatar(initials: 'A'),
              DsAvatar(initials: 'B'),
              DsAvatar(initials: 'C'),
              DsAvatar(initials: 'D'),
            ],
          ),
          theme: light,
        ),
      );
      expect(find.text('+2'), findsOneWidget);
      final shown = tester.widgetList<DsAvatar>(find.byType(DsAvatar)).toList();
      expect(shown.map((a) => a.toneIndex), [0, 1]);
      // Both are overlapped (the +N bubble follows): their initials sit
      // toward the start, in the part left visible.
      for (final letter in ['A', 'B']) {
        final circle = find.ancestor(
          of: find.text(letter),
          matching: find.byType(DsAvatar),
        );
        expect(
          tester.getCenter(find.text(letter)).dx,
          lessThan(tester.getCenter(circle).dx - 1),
          reason: '$letter is overlapped',
        );
      }
    });
  });

  group('DsCard', () {
    testWidgets('pressable card lifts on hover and activates by keyboard', (
      tester,
    ) async {
      useTraditionalHighlights();
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          Focus(
            focusNode: node,
            child: DsCard(onPressed: () => taps++, child: const Text('kart')),
          ),
          theme: light,
        ),
      );
      DsBoxDecoration deco() =>
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as DsBoxDecoration;
      expect(deco().shadows, light.shadows.surface);
      await hover(tester, find.byType(DsCard));
      expect(deco().shadows, light.shadows.surfaceRaised);
      await tester.tap(find.byType(DsCard));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    });

    testWidgets('static card is not a button', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(const DsCard(child: Text('kart'))));
      expect(
        tester.getSemantics(find.text('kart')),
        isSemantics(label: 'kart', isButton: false),
      );
      semantics.dispose();
    });
  });

  group('DsAlert', () {
    testWidgets('each status brings its own icon', (tester) async {
      for (final (status, icon) in [
        (DsStatus.info, DsIcons.info),
        (DsStatus.success, DsIcons.circleCheck),
        (DsStatus.warning, DsIcons.triangleAlert),
        (DsStatus.danger, DsIcons.circleAlert),
      ]) {
        await tester.pumpWidget(
          host(DsAlert(status: status, title: const Text('x'))),
        );
        expect(
          tester.widget<DsIcon>(find.byType(DsIcon)).icon,
          icon,
          reason: status.name,
        );
      }
    });

    test('the icon reads at 3:1 on the alert, in the vivid signal', () {
      for (final b in Brightness.values) {
        final t = DsThemeData(brightness: b);
        final k = t.colors;
        for (final s in DsStatus.values) {
          final style = DsAlert.defaultStyle(t, status: s);
          final bg = DsColorUtils.flatten(style.background!, k.surface);
          expect(
            DsColorUtils.contrastRatio(style.iconColor!, bg),
            greaterThanOrEqualTo(3),
            reason: '${b.name} ${s.name}',
          );
          expect(style.iconColor, k.status(s).signal, reason: s.name);
        }
      }
    });

    test('dark alerts are a neutral block with a colored title', () {
      final t = DsThemeData(brightness: Brightness.dark);
      final k = t.colors;
      for (final s in DsStatus.values) {
        final style = DsAlert.defaultStyle(t, status: s);
        expect(style.background, k.neutral.tint, reason: s.name);
        expect(style.titleStyle!.color, k.status(s).text, reason: s.name);
      }
      // Light mode keeps the soft status tint.
      final light = DsThemeData();
      expect(
        DsAlert.defaultStyle(light, status: DsStatus.danger).background,
        light.colors.danger.tint,
      );
    });

    testWidgets('announce makes a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DsAlert(announce: true, title: Text('Kaydedildi'))),
      );
      expect(
        tester.getSemantics(find.byType(DsAlert)),
        // The status icon names the status first.
        isSemantics(isLiveRegion: true, label: 'Information\nKaydedildi'),
      );
      semantics.dispose();
    });

    testWidgets('long text wraps at 2x without overflow', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: DsAlert(
              title: Text('Bağlantı kurulamadı, lütfen tekrar deneyin'),
              description: Text('Ağ bağlantınızı kontrol edip tekrar deneyin.'),
            ),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DsProgress', () {
    testWidgets('bar and ring expose a progress role and value', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: DsProgressBar(value: .64, semanticLabel: 'Yükleme'),
              ),
              DsProgressRing(value: .72, semanticLabel: 'Sprint'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(DsProgressBar)),
        isSemantics(label: 'Yükleme', value: '64%'),
      );
      expect(
        tester.getSemantics(find.byType(DsProgressRing)),
        isSemantics(label: 'Sprint', value: '72%'),
      );
      semantics.dispose();
    });

    testWidgets('indeterminate bar stops moving under reduced motion', (
      tester,
    ) async {
      final reduced = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(
        host(
          const SizedBox(width: 200, child: DsProgressBar()),
          theme: reduced,
        ),
      );
      // Settles: nothing repeats.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('DsSkeleton and DsShimmer', () {
    testWidgets('shimmer is off under reduced motion and speaks its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final reduced = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(
        host(
          const DsShimmer(
            semanticLabel: 'Yükleniyor',
            child: DsSkeleton(width: 100),
          ),
          theme: reduced,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FractionalTranslation), findsNothing);
      expect(
        tester.getSemantics(find.byType(DsShimmer)),
        isSemantics(label: 'Yükleniyor'),
      );
      semantics.dispose();
    });
  });

  group('DsLink and DsBreadcrumb', () {
    testWidgets('link has link semantics with its url', (tester) async {
      final semantics = tester.ensureSemantics();
      final url = Uri.parse('https://example.com/destek');
      var taps = 0;
      await tester.pumpWidget(
        host(
          DsLink(
            label: 'destek',
            url: url,
            external: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsLink)),
        isSemantics(isLink: true, label: 'destek'),
      );
      expect(
        tester.getSemantics(find.byType(DsLink)).getSemanticsData().linkUrl,
        url,
      );
      expect(find.byType(DsIcon), findsOneWidget, reason: 'external arrow');
      await tester.tap(find.byType(DsLink));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('link activates with Enter', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(DsLink(label: 'x', onPressed: () => taps++)),
      );
      Focus.of(tester.element(find.text('x'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });

    testWidgets('breadcrumb: ancestors pressable, current page not', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        host(
          DsBreadcrumb(
            items: [
              DsBreadcrumbItem(
                label: 'Projeler',
                onPressed: () => pressed.add('p'),
              ),
              DsBreadcrumbItem(label: 'Web', onPressed: () => pressed.add('w')),
              const DsBreadcrumbItem(label: 'Ayarlar'),
            ],
          ),
          theme: light,
        ),
      );
      expect(find.byType(DsIcon), findsNWidgets(2), reason: 'separators');
      expect(find.byType(DsPressable), findsNWidgets(2));
      await tester.tap(find.text('Projeler'));
      await tester.tap(find.text('Ayarlar'), warnIfMissed: false);
      expect(pressed, ['p']);
      final current = tester.widget<Text>(find.text('Ayarlar'));
      expect(current.style!.fontWeight, FontWeight.w600);
      expect(current.style!.color, light.colors.text);
    });
  });
}
