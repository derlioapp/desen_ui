import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// B2 / V11 / visual C1 / K-61: a selected item used to override the hover
/// look, so hovering a selected chip, sidebar item, current page, "on"
/// toolbar toggle or bottom-nav item showed nothing; a selected list row
/// follows the same rule. Selected items have their own hover step
/// ([DsThemeData.selectedHoverFill]); keyboard focus draws the ring on top
/// of the plain selected fill.
void main() {
  /// The first AnimatedContainer under [of]: the item's visual box.
  Finder box(Type of) => find
      .descendant(of: find.byType(of), matching: find.byType(AnimatedContainer))
      .first;

  final cases = <String, (Widget, Finder)>{
    'chip': (
      DsChip(label: const Text('Açık'), selected: true, onChanged: (_) {}),
      find.text('Açık'),
    ),
    'sidebar item': (
      SizedBox(
        width: 220,
        child: DsSidebarItem(
          label: const Text('Gelen'),
          selected: true,
          onPressed: () {},
        ),
      ),
      find.text('Gelen'),
    ),
    'list row': (
      SizedBox(
        width: 320,
        child: DsListRow(
          title: const Text('Haftalık rapor'),
          selected: true,
          onPressed: () {},
        ),
      ),
      find.text('Haftalık rapor'),
    ),
    'current page': (
      DsPagination(page: 1, pageCount: 3, onChanged: (_) {}),
      find.text('1'),
    ),
    'toolbar toggle (on)': (
      DsToolbarToggle(
        icon: const DsIcon(DsIcons.bold),
        semanticLabel: 'Kalın',
        selected: true,
        onChanged: (_) {},
      ),
      find.byType(DsIcon),
    ),
    'bottom nav item': (
      DsBottomNav(
        value: 0,
        onChanged: (_) {},
        items: const [
          DsBottomNavItem(
            value: 0,
            icon: DsIcon(DsIcons.house),
            label: Text('Ana'),
          ),
          DsBottomNavItem(
            value: 1,
            icon: DsIcon(DsIcons.search),
            label: Text('Ara'),
          ),
        ],
      ),
      find.text('Ana'),
    ),
  };

  for (final selectionStyle in DsSelectionStyle.values) {
    for (final MapEntry(key: name, value: (widget, inside)) in cases.entries) {
      testWidgets(
        '${selectionStyle.name}: hover is visible on a selected $name',
        (tester) async {
          useTraditionalHighlights();
          final theme = DsThemeData(selectionStyle: selectionStyle);
          await tester.pumpWidget(host(widget, theme: theme));
          Finder filled(Color color) => find.byWidgetPredicate(
            (w) =>
                w is AnimatedContainer &&
                (w.decoration as DsBoxDecoration?)?.color == color,
          );
          expect(filled(theme.selectedFill), findsOneWidget);
          await hover(tester, inside);
          expect(
            filled(theme.selectedHoverFill),
            findsOneWidget,
            reason: 'hover left the selected item unchanged',
          );
          expect(theme.selectedHoverFill, isNot(theme.selectedFill));
        },
      );
    }
  }

  // Keyboard focus: a selected item draws the focus ring too, and
  // keeps its plain selected fill (the hover step is for hover only).
  for (final MapEntry(key: name, value: (widget, inside)) in cases.entries) {
    testWidgets('ring: focus draws a ring on a selected $name', (tester) async {
      useTraditionalHighlights();
      final theme = DsThemeData();
      await tester.pumpWidget(host(widget, theme: theme));
      Focus.of(tester.element(inside)).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      final focused = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            (w.decoration as DsBoxDecoration?)?.color == theme.selectedFill &&
            // The ring sits in the decoration or, drawn above the fill,
            // in the foreground one (chip, button).
            [w.decoration, w.foregroundDecoration].any(
              (d) =>
                  d is DsBoxDecoration &&
                  d.shadows.any(
                    (s) => s.color == theme.colors.focus && s.blur == 0,
                  ),
            ),
      );
      expect(focused, findsOneWidget, reason: 'no ring on the selected item');
    });
  }

  testWidgets('the strong style fills a selected chip, with no edge', (
    tester,
  ) async {
    final theme = DsThemeData(selectionStyle: DsSelectionStyle.strong);
    await tester.pumpWidget(
      host(
        DsChip(label: const Text('Açık'), selected: true, onChanged: (_) {}),
        theme: theme,
      ),
    );
    final deco =
        tester.widget<AnimatedContainer>(box(DsChip)).decoration!
            as DsBoxDecoration;
    expect(deco.color, theme.colors.selectionStrong);
    expect(deco.shadows.where((s) => s.color.a > 0 && s.blur == 0), isEmpty);
  });

  test('only the strong style fills selected items; only a bright fill '
      'wears an edge', () {
    for (final contrast in DsContrast.values) {
      for (final style in DsSelectionStyle.values) {
        final t = DsThemeData(contrast: contrast, selectionStyle: style);
        final filled = style == DsSelectionStyle.strong;
        expect(t.fillsSelection, filled, reason: '$contrast $style');
        expect(
          t.selectedFill,
          filled ? t.colors.selectionStrong : t.colors.selection,
        );
        expect(t.selectedEdge, isNull, reason: '$contrast $style');
      }
    }
    // A bright accent keeps its edge off the card when filled, at every
    // level.
    const yellow = DsSeed.oklch(0.86, 0.17, 95);
    for (final contrast in DsContrast.values) {
      for (final style in DsSelectionStyle.values) {
        final t = DsThemeData(
          seed: yellow,
          contrast: contrast,
          selectionStyle: style,
        );
        expect(
          t.selectedEdge,
          style == DsSelectionStyle.strong ? t.colors.accentEdge : isNull,
          reason: '$contrast $style',
        );
      }
    }
  });
}
