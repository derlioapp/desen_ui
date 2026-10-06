import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contrast_budget_test.dart' show seeds;

/// A sidebar item's count reads at 4.5:1 on the item's fill in every
/// state: at rest and hovered, selected or not, with either selection
/// style (soft or fill), for every seed, mode and contrast. It used to stay
/// `textSubtle` on a selected item, gray on the accent fill.
void main() {
  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      for (final contrast in DsContrast.values) {
        for (final selection in DsSelectionStyle.values) {
          test('$name ${brightness.name} ${contrast.name} ${selection.name}: '
              'sidebar count >= 4.5:1', () {
            final t = DsThemeData(
              seed: seed,
              brightness: brightness,
              contrast: contrast,
            ).copyWith(selectionStyle: selection);
            final k = t.colors;
            final failures = <String>[];
            for (final states in [
              <WidgetState>{},
              {WidgetState.hovered},
              {WidgetState.selected},
              {WidgetState.selected, WidgetState.hovered},
            ]) {
              final s = DsSidebarItemStyle.resolveLayers([
                DsSidebarItem.defaultStyle(t),
              ], states);
              final fill = DsColorUtils.flatten(s.background!, k.sidebar);
              final ink = s.countStyle!.color!;
              final ratio = DsColorUtils.contrastRatio(
                ink,
                fill,
                backdrop: k.sidebar,
              );
              if (ratio < 4.5) {
                failures.add(
                  '${states.map((e) => e.name).join('+')}: '
                  '${ratio.toStringAsFixed(2)}',
                );
              }
            }
            expect(failures, isEmpty, reason: failures.join('\n'));
          });
        }
      }
    }
  }
}
