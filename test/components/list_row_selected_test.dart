import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A selected list row (the open message of a mail list) takes the
/// theme's selection style, soft or filled, in light and dark; hover stays
/// visible on it; screen readers hear it as selected; its corners nest in
/// the section card.
void main() {
  DsBoxDecoration rowDecoration(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: find.byType(DsListRow),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  Color? textColor(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;

  Widget mail({bool selected = true, VoidCallback? onPressed}) => SizedBox(
    width: 360,
    child: DsListSection(
      children: [
        DsListRow(
          leading: const DsIcon(DsIcons.inbox),
          title: const Text('Haftalık rapor'),
          detail: const Text('09:41'),
          showChevron: true,
          selected: selected,
          onPressed: onPressed,
        ),
      ],
    ),
  );

  group('semantics', () {
    testWidgets('a selected pressable row is announced as selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(mail(onPressed: () {})));
      final data = tester.getSemantics(find.byType(DsListRow));
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, contains('Haftalık rapor'));
      handle.dispose();
    });

    testWidgets('a selected static row is announced as selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(mail()));
      final data = tester.getSemantics(find.byType(DsListRow));
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.label, contains('Haftalık rapor'));
      handle.dispose();
    });

    testWidgets('a row that is not selected announces no selection state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(mail(selected: false, onPressed: () {})));
      expect(
        tester.getSemantics(find.byType(DsListRow)).flagsCollection.isSelected,
        Tristate.none,
      );
      handle.dispose();
    });
  });

  for (final brightness in Brightness.values) {
    for (final selectionStyle in DsSelectionStyle.values) {
      final name = '${brightness.name} ${selectionStyle.name}';

      testWidgets('$name: the selected row takes the selection colors', (
        tester,
      ) async {
        useTraditionalHighlights();
        final theme = DsThemeData(
          brightness: brightness,
          selectionStyle: selectionStyle,
        );
        await tester.pumpWidget(host(mail(onPressed: () {}), theme: theme));
        expect(rowDecoration(tester).color, theme.selectedFill);
        expect(textColor(tester, 'Haftalık rapor'), theme.onSelectedFill);
        expect(textColor(tester, '09:41'), theme.onSelectedFill);
        final icons = tester.widgetList<DsIcon>(find.byType(DsIcon));
        expect(icons.last.color, theme.onSelectedFill, reason: 'chevron');

        await hover(tester, find.text('Haftalık rapor'));
        expect(
          rowDecoration(tester).color,
          theme.selectedHoverFill,
          reason: 'hover left the selected row unchanged',
        );
        expect(theme.selectedHoverFill, isNot(theme.selectedFill));
      });

      test('$name: every ink on the selected row reads on its fill', () {
        final theme = DsThemeData(
          brightness: brightness,
          selectionStyle: selectionStyle,
        );
        for (final states in [
          {WidgetState.selected},
          {WidgetState.selected, WidgetState.hovered},
        ]) {
          final s = DsListRowStyle.resolveLayers([
            DsListRow.defaultStyle(theme),
          ], states);
          final fill = DsColorUtils.flatten(
            s.background!,
            theme.colors.surface,
          );
          for (final ink in [
            s.foreground!,
            s.iconColor!,
            s.detailStyle!.color!,
            s.chevronColor!,
          ]) {
            expect(
              DsColorUtils.contrastRatio(
                ink,
                fill,
                backdrop: theme.colors.surface,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$states',
            );
          }
        }
      });
    }
  }

  test('a filled selected row rings in its label color', () {
    final theme = DsThemeData(selectionStyle: DsSelectionStyle.strong);
    final s = DsListRowStyle.resolveLayers(
      [DsListRow.defaultStyle(theme)],
      {WidgetState.selected, WidgetState.focused},
    );
    expect(s.focusShadows, [
      DsShadow.innerRing(theme.onSelectedFill, width: 2),
    ]);
  });

  testWidgets('a bright filled selection draws its edge', (tester) async {
    final theme = DsThemeData(
      seed: const DsSeed.oklch(0.86, 0.17, 95),
      selectionStyle: DsSelectionStyle.strong,
    );
    expect(theme.selectedEdge, isNotNull);
    await tester.pumpWidget(host(mail(onPressed: () {}), theme: theme));
    expect(
      rowDecoration(tester).shadows,
      contains(DsShadow.innerRing(theme.selectedEdge!)),
    );
  });

  testWidgets('the selected fill nests in the section card', (tester) async {
    final theme = DsThemeData();
    await tester.pumpWidget(host(mail(onPressed: () {}), theme: theme));
    final card = DsListSection.defaultStyle(theme);
    final inset = (card.padding! as EdgeInsets).left;
    expect(
      rowDecoration(tester).borderRadius,
      BorderRadius.circular(theme.radii.nested(theme.radii.card, inset)),
    );
  });
}
