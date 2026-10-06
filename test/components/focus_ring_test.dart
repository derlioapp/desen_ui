import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The default focus look is the ring, shown only for keyboard navigation
/// (K-42). Full-bleed rows draw it inside their edge, so a rounded or
/// clipped container never cuts it, and it stays visible on every fill.
void main() {
  const focused = {WidgetState.focused};
  const selectedFocused = {WidgetState.focused, WidgetState.selected};

  test('keyboard focus always draws the ring, at every contrast', () {
    for (final contrast in DsContrast.values) {
      final theme = DsThemeData(contrast: contrast);
      expect(theme.focusShadows, theme.shadows.focusOffset);
      expect(theme.focusShadows, isNotEmpty);
    }
  });

  group('full-bleed rows draw the ring inside', () {
    final theme = DsThemeData();
    final k = theme.colors;
    final inner = DsShadow.innerRing(k.focus, width: 2);

    test('list row', () {
      final s = DsListRowStyle.resolveLayers([
        DsListRow.defaultStyle(theme),
      ], focused);
      expect(s.focusShadows, [inner]);
    });

    test('sidebar item, plain and selected', () {
      for (final states in [focused, selectedFocused]) {
        final s = DsSidebarItemStyle.resolveLayers([
          DsSidebarItem.defaultStyle(theme),
        ], states);
        expect(s.focusShadows, [inner], reason: '$states');
      }
    });

    test('accordion header', () {
      expect(DsAccordion.defaultStyle(theme).focusShadows, [inner]);
    });

    test('menu item', () {
      final s = DsMenuItemStyle.resolveLayers([
        DsMenuItem.defaultStyle(theme),
      ], focused);
      expect(s.focusShadows, [inner]);
    });
  });

  test('a filled selected sidebar item rings in its label color, which '
      'reads on the fill', () {
    for (final brightness in Brightness.values) {
      final theme = DsThemeData(
        brightness: brightness,
        selectionStyle: DsSelectionStyle.strong,
      );
      final s = DsSidebarItemStyle.resolveLayers([
        DsSidebarItem.defaultStyle(theme),
      ], selectedFocused);
      expect(s.focusShadows, [
        DsShadow.innerRing(theme.onSelectedFill, width: 2),
      ]);
      expect(
        DsColorUtils.contrastRatio(theme.onSelectedFill, theme.selectedFill),
        greaterThanOrEqualTo(3),
      );
    }
  });

  test('tabs ring stands 4px off the label, clear of accents', () {
    final s = DsTabs.defaultStyle(DsThemeData());
    expect(s.focusShadows, hasLength(1));
    expect(s.focusShadows!.single.gap, DsSpace.s4);
  });
}
