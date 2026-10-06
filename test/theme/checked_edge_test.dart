import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';

/// A checked control (checked checkbox and radio, on switch, filled
/// selection) stands 3:1 off every layer it sits on, in both modes and at
/// both contrast levels (WCAG 1.4.11). The oxblood preset in dark mode
/// used to rest at 2.94:1 on the surface; every white-labeled dark fill
/// sat near 2.5:1 on the floating layer.
void main() {
  const presets = {
    'blue': DsSeed.blue,
    'navy': DsSeed.navy,
    'graphite': DsSeed.graphite,
    'oxblood': DsSeed.oxblood,
    'forest': DsSeed.forest,
    'indigo': DsSeed.indigo,
  };

  double worst(DsColors k) {
    final grounds = [k.canvas, k.surface, k.sidebar, k.control, k.overlay];
    var min = double.infinity;
    for (final fill in [k.accent, k.accentHover, k.accentPress]) {
      for (final ground in grounds) {
        final r = DsColorUtils.contrastRatio(
          Color.alphaBlend(k.accentEdge, fill),
          ground,
        );
        if (r < min) min = r;
      }
    }
    return min;
  }

  test('every preset, both modes and levels: 3:1 on every layer', () {
    for (final MapEntry(key: name, value: seed) in presets.entries) {
      for (final brightness in Brightness.values) {
        for (final contrast in DsContrast.values) {
          final k = DsThemeData(
            seed: seed,
            brightness: brightness,
            contrast: contrast,
          ).colors;
          expect(
            worst(k),
            greaterThanOrEqualTo(3),
            reason: '$name $brightness $contrast',
          );
          expect(
            accentEdgeOnlyWhereNeeded(k),
            isEmpty,
            reason: '$name $brightness $contrast',
          );
        }
      }
    }
  });

  test('oxblood in dark mode: a light rim on the checked fill', () {
    final k = DsThemeData(
      seed: DsSeed.oxblood,
      brightness: Brightness.dark,
    ).colors;
    expect(k.accentEdge.a, greaterThan(0));
    // The edge is the white label at a low opacity: a faint light rim.
    expect(k.accentEdge.withValues(alpha: 1), k.onAccent.withValues(alpha: 1));
    expect(k.accentEdge.a, lessThan(.5));
    expect(
      DsColorUtils.contrastRatio(
        Color.alphaBlend(k.accentEdge, k.accent),
        k.surface,
      ),
      greaterThanOrEqualTo(3),
    );
  });

  test('a white-labeled fill in light mode needs no edge', () {
    for (final seed in presets.values) {
      expect(DsThemeData(seed: seed).colors.accentEdge.a, 0);
    }
  });

  testWidgets('dark checked controls draw the edge; buttons stay flat', (
    tester,
  ) async {
    final theme = DsThemeData(
      seed: DsSeed.oxblood,
      brightness: Brightness.dark,
    );
    final edge = theme.colors.accentEdge;
    expect(
      DsCheckbox.defaultStyle(theme)
          .resolve(const {WidgetState.selected})
          .borderColor,
      edge,
    );
    expect(
      DsSwitch.defaultStyle(theme)
          .resolve(const {WidgetState.selected})
          .trackShadows,
      [DsShadow.innerRing(edge)],
    );
    // A labeled button says what it is by its label: no hairline.
    expect(
      DsButton.defaultStyle(
        theme,
        variant: DsButtonVariant.primary,
        size: DsSize.md,
      ).shadows,
      isEmpty,
    );
  });

  test('the fuzzed seeds keep the rule too', () {
    // A sample across hues and lightness, dark mode (where the rim is
    // needed), both levels.
    for (var hue = 0.0; hue < 360; hue += 30) {
      for (final l in [.45, .6, .75]) {
        for (final contrast in DsContrast.values) {
          final k = DsThemeData(
            seed: DsSeed.oklch(l, .15, hue),
            brightness: Brightness.dark,
            contrast: contrast,
          ).colors;
          expect(
            worst(k),
            greaterThanOrEqualTo(3),
            reason: 'oklch($l .15 $hue) $contrast',
          );
        }
      }
    }
  });
}
