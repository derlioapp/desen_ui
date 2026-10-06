import 'dart:ui' show CheckedState, SemanticsRole;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressions from the blind audit (phase B): phone widths, large text,
/// narrow containers and navigation semantics.
void main() {
  Future<void> pumpIn(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(800, 600),
    double textScale = 1,
    DsThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = theme ?? DsThemeData();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: direction,
          child: DsTheme(
            data: t,
            child: DefaultTextStyle(style: t.typography.body, child: child),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  const five = [
    DsBottomNavItem(
      value: 0,
      icon: DsIcon(DsIcons.house),
      label: Text('Ana sayfa'),
    ),
    DsBottomNavItem(value: 1, icon: DsIcon(DsIcons.search), label: Text('Ara')),
    DsBottomNavItem(value: 2, icon: DsIcon(DsIcons.plus), label: Text('Ekle')),
    DsBottomNavItem(
      value: 3,
      icon: DsIcon(DsIcons.inbox),
      label: Text('Gelen kutusu'),
    ),
    DsBottomNavItem(
      value: 4,
      icon: DsIcon(DsIcons.user),
      label: Text('Profil'),
    ),
  ];

  group('DsBottomNav', () {
    testWidgets('five floating items fit a 358pt column (B11, H2)', (
      tester,
    ) async {
      await pumpIn(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 358,
            child: Center(
              child: DsBottomNav(value: 0, onChanged: (_) {}, items: five),
            ),
          ),
        ),
        size: const Size(375, 667),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DsBottomNav<int>)).width,
        lessThanOrEqualTo(358),
      );
    });

    testWidgets('items keep their 72pt width when there is room', (
      tester,
    ) async {
      await pumpIn(
        tester,
        Center(
          child: DsBottomNav(
            value: 0,
            onChanged: (_) {},
            items: five.take(3).toList(),
          ),
        ),
      );
      final item = find.descendant(
        of: find.byType(DsBottomNav<int>),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(item.first).width, 72);
      expect(tester.getSize(item.first).height, 50);
    });

    for (final variant in DsBottomNavVariant.values) {
      testWidgets('$variant grows with 200% text (B12)', (tester) async {
        await pumpIn(
          tester,
          Align(
            alignment: Alignment.bottomCenter,
            child: DsBottomNav(
              variant: variant,
              value: 0,
              onChanged: (_) {},
              items: five.take(3).toList(),
            ),
          ),
          size: const Size(390, 844),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a selected item is filled, with no edge, under the strong '
        'style', (tester) async {
      final strong = DsThemeData(selectionStyle: DsSelectionStyle.strong);
      await pumpIn(
        tester,
        Center(
          child: DsBottomNav(
            value: 0,
            onChanged: (_) {},
            items: five.take(2).toList(),
          ),
        ),
        theme: strong,
      );
      final deco =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byType(DsBottomNav<int>),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as DsBoxDecoration;
      expect(strong.selectedEdge, isNull);
      expect(deco.color, strong.colors.selectionStrong);
      expect(deco.shadows.where((s) => s.color.a > 0), isEmpty);
    });
  });

  group('DsSegmentedControl', () {
    testWidgets('ellipsizes in a narrow container (B14, ux V5)', (
      tester,
    ) async {
      await pumpIn(
        tester,
        Center(
          child: SizedBox(
            width: 240,
            child: DsSegmentedControl<int>(
              value: 0,
              onChanged: (_) {},
              segments: const [
                DsSegment(value: 0, label: Text('Overview')),
                DsSegment(value: 1, label: Text('Activity')),
                DsSegment(value: 2, label: Text('Settings')),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('segments take their own widths before cutting a label', (
      tester,
    ) async {
      Widget control(double width, int value) => Center(
        child: SizedBox(
          width: width,
          child: DsSegmentedControl<int>(
            value: value,
            onChanged: (_) {},
            segments: const [
              DsSegment(value: 0, label: Text('Sharp')),
              DsSegment(value: 1, label: Text('Standard')),
              DsSegment(value: 2, label: Text('Soft')),
              DsSegment(value: 3, label: Text('Pill')),
            ],
          ),
        ),
      );
      Rect label(String text) => tester.getRect(find.text(text));
      bool cut(String text) => tester
          .renderObject<RenderParagraph>(find.text(text))
          .didExceedMaxLines;

      // Wide: equal widths.
      await pumpIn(tester, control(600, 1));
      expect(tester.takeException(), isNull);
      final wide = [
        for (final l in ['Sharp', 'Standard', 'Soft', 'Pill'])
          tester
              .getRect(
                find
                    .ancestor(
                      of: find.text(l),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .width,
      ];
      expect(wide.toSet().length, 1);

      // Too narrow for four equal segments, wide enough for their own
      // widths: nothing is cut, and the thumb sits under the selection.
      await pumpIn(tester, control(300, 1));
      expect(tester.takeException(), isNull);
      for (final l in ['Sharp', 'Standard', 'Soft', 'Pill']) {
        expect(cut(l), isFalse, reason: l);
      }
      expect(label('Sharp').right, lessThan(label('Standard').left));
      expect(label('Standard').right, lessThan(label('Soft').left));
      final thumb = tester.getRect(
        find
            .descendant(
              of: find.byType(DsSegmentedControl<int>),
              matching: find.byType(DecoratedBox),
            )
            .at(1),
      );
      expect(thumb.left, lessThanOrEqualTo(label('Standard').left));
      expect(thumb.right, greaterThanOrEqualTo(label('Standard').right));
      expect(thumb.left, greaterThan(label('Sharp').right));
    });

    testWidgets('grows with 200% text', (tester) async {
      await pumpIn(
        tester,
        Center(
          child: DsSegmentedControl<int>(
            value: 0,
            onChanged: (_) {},
            segments: const [
              DsSegment(value: 0, label: Text('Gün')),
              DsSegment(value: 1, label: Text('Hafta')),
            ],
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a value matching no segment checks none (B30)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? changed;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pumpIn(
        tester,
        Center(
          child: DsSegmentedControl<int>(
            value: 9,
            focusNode: node,
            onChanged: (v) => changed = v,
            segments: const [
              DsSegment(value: 0, label: Text('Gün')),
              DsSegment(value: 1, label: Text('Hafta')),
            ],
          ),
        ),
      );
      for (final label in ['Gün', 'Hafta']) {
        expect(
          tester
              .getSemantics(find.text(label))
              .getSemanticsData()
              .flagsCollection
              .isChecked,
          isNot(CheckedState.isTrue),
          reason: label,
        );
      }
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(changed, 0, reason: 'forward from none starts at the first');
      handle.dispose();
    });
  });

  group('DsPagination', () {
    testWidgets('collapses at phone width in touch density (visual H2)', (
      tester,
    ) async {
      await pumpIn(
        tester,
        Center(
          child: SizedBox(
            width: 358,
            child: Center(
              child: DsPagination(page: 6, pageCount: 24, onChanged: (_) {}),
            ),
          ),
        ),
        size: const Size(390, 844),
        theme: DsThemeData(density: DsDensity.touch),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('6 / 24'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 6 of 24'), findsOneWidget);
    });

    testWidgets('shows every page when it fits', (tester) async {
      await pumpIn(
        tester,
        Center(child: DsPagination(page: 6, pageCount: 24, onChanged: (_) {})),
      );
      expect(find.text('6 / 24'), findsNothing);
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('zero pages renders inactive arrows (B32, eng L9)', (
      tester,
    ) async {
      await pumpIn(
        tester,
        Center(child: DsPagination(page: 1, pageCount: 0, onChanged: (_) {})),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DsButton), findsNWidgets(2));
      for (final b in tester.widgetList<DsButton>(find.byType(DsButton))) {
        expect(b.onPressed, isNull);
      }
    });

    testWidgets('names pages and marks the current one (ux V22)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpIn(
        tester,
        Center(child: DsPagination(page: 3, pageCount: 5, onChanged: (_) {})),
      );
      final nav = tester.getSemantics(find.bySemanticsLabel('Pagination'));
      expect(nav.role, SemanticsRole.navigation);
      final current = tester.getSemantics(find.bySemanticsLabel('Page 3'));
      expect(current.value, 'Current page');
      final other = tester.getSemantics(find.bySemanticsLabel('Page 4'));
      expect(other.value, '');
      handle.dispose();
    });
  });

  testWidgets('breadcrumb is a navigation with a current page (ux V22)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpIn(
      tester,
      Center(
        child: DsBreadcrumb(
          items: [
            DsBreadcrumbItem(label: 'Projeler', onPressed: () {}),
            const DsBreadcrumbItem(label: 'Desen'),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Breadcrumb')).role,
      SemanticsRole.navigation,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Desen')).value,
      'Current page',
    );
    handle.dispose();
  });

  testWidgets('a list row with a long value ellipsizes (B22)', (tester) async {
    await pumpIn(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          child: DsListSection(
            children: [
              DsListRow(
                title: const Text('E-posta'),
                detail: const Text('a.very.long.address@subdomain.example.com'),
                showChevron: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('E-posta'), findsOneWidget);
  });

  testWidgets('a long external link wraps (B23, eng L13)', (tester) async {
    await pumpIn(
      tester,
      Center(
        child: SizedBox(
          width: 200,
          child: DsLink(
            label: 'Read the full migration guide on the documentation site',
            external: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(DsLink)).height,
      greaterThan(30),
      reason: 'more than one line',
    );
  });

  group('DsStepper', () {
    testWidgets('wide values are not cut (B29)', (tester) async {
      await pumpIn(
        tester,
        Center(child: DsStepper(value: 12345, max: 99999, onChanged: (_) {})),
      );
      final para = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text('12345'),
          matching: find.byType(RichText),
        ),
      );
      expect(para.didExceedMaxLines, isFalse);
    });

    testWidgets('the width does not jump between values', (tester) async {
      Future<double> widthAt(int v) async {
        await pumpIn(
          tester,
          Center(
            child: DsStepper(value: v, max: 1000, onChanged: (_) {}),
          ),
        );
        return tester.getSize(find.byType(DsStepper<int>)).width;
      }

      expect(await widthAt(5), await widthAt(1000));
    });

    testWidgets('announces the clamped next value (B28)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpIn(
        tester,
        Center(
          child: DsStepper(
            value: 10,
            max: 12,
            step: 5,
            semanticLabel: 'Misafir',
            onChanged: (_) {},
          ),
        ),
      );
      final data = tester.getSemantics(find.bySemanticsLabel('Misafir'));
      expect(data.increasedValue, '12');
      handle.dispose();
    });

    testWidgets('Left and Right mirror in RTL (ux V25)', (tester) async {
      var value = 5;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pumpIn(
        tester,
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => DsStepper(
              value: value,
              focusNode: node,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
        direction: TextDirection.rtl,
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 6);
    });
  });
}
