import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/theme/palette.dart' show DsPalette;
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';

/// Every preset seed fits the contrast budget.

const seeds = {
  'blue': DsSeed.blue,
  'navy': DsSeed.navy,
  'graphite': DsSeed.graphite,
  'oxblood': DsSeed.oxblood,
  'forest': DsSeed.forest,
  'indigo': DsSeed.indigo,
};

/// The text tiers step down evenly enough to tell apart (cila): text,
/// then textMuted a clear step below, then textSubtle below that, all on
/// the surface at standard contrast. In dark mode textMuted stays under
/// [darkMutedMax]: it used to sit at 9.2:1, reading almost as loud as
/// text (12.7:1). textSubtle steps a clear notch below textMuted in both
/// modes: on a highlighted row in a floating layer, where it would
/// fall under 4.5:1, components use textMuted.
const darkMutedMax = 8.7;

/// In light mode the tiers sit apart like iOS's labels, within AA:
/// textMuted about 6.4:1 on the surface (was 7.75:1, reading almost like
/// text) and textSubtle about 5.2:1 (was 6.24:1, the same gray as muted).
/// textSubtle keeps 4.5:1 on the page, which sets its floor.
const lightMutedMax = 7.0, lightSubtleMax = 5.6;

List<String> tierSpreadFailures(DsColors k, {required bool dark}) {
  double on(Color c) => DsColorUtils.contrastRatio(c, k.surface);
  final text = on(k.text), muted = on(k.textMuted), subtle = on(k.textSubtle);
  return [
    if (text / muted < 1.4)
      'text/textMuted step ${(text / muted).toStringAsFixed(2)} < 1.4',
    if (muted / subtle < 1.2)
      'textMuted/textSubtle step ${(muted / subtle).toStringAsFixed(2)} '
          '< 1.2',
    if (dark && muted > darkMutedMax)
      'dark textMuted on surface ${muted.toStringAsFixed(2)} > $darkMutedMax',
    if (!dark && muted > lightMutedMax)
      'light textMuted on surface ${muted.toStringAsFixed(2)} > '
          '$lightMutedMax',
    if (!dark && subtle > lightSubtleMax)
      'light textSubtle on surface ${subtle.toStringAsFixed(2)} > '
          '$lightSubtleMax',
  ];
}

void main() {
  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      for (final contrast in DsContrast.values) {
        final dark = brightness == Brightness.dark;
        test('$name ${brightness.name} ${contrast.name} fits the budget', () {
          final p = DsPalette.fromSeed(
            seed,
            brightness: brightness,
            contrast: contrast,
          );
          final failures = [
            ...budgetFailures(p, dark: dark, level: contrast),
            ...componentFailures(
              DsThemeData(
                seed: seed,
                brightness: brightness,
                contrast: contrast,
              ),
            ),
          ];
          expect(failures, isEmpty, reason: failures.join('\n'));
        });
      }
    }
  }

  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      test('$name ${brightness.name} text tiers are spread', () {
        // Soft shares standard's text (see "soft keeps standard's text").
        final k = DsPalette.fromSeed(seed, brightness: brightness).colors;
        final failures = tierSpreadFailures(
          k,
          dark: brightness == Brightness.dark,
        );
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }

  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      test('$name ${brightness.name} soft keeps standard\'s text', () {
        DsPalette p(DsContrast c) =>
            DsPalette.fromSeed(seed, brightness: brightness, contrast: c);
        final failures = softKeepsText(
          p(DsContrast.standard),
          p(DsContrast.soft),
        );
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }

  // The levels share the page: layers, controls, the accent family
  // and the strong selection are the same at both, so soft never turns the
  // page gray or muddy. Only lines and control boundaries (the switch's off
  // track, the slider track) move.
  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      test('$name ${brightness.name} soft keeps the page', () {
        DsColors k(DsContrast c) => DsPalette.fromSeed(
          seed,
          brightness: brightness,
          contrast: c,
        ).colors;
        final std = k(DsContrast.standard);
        final backgrounds = <String, Color Function(DsColors)>{
          'canvas': (k) => k.canvas,
          'surface': (k) => k.surface,
          'sidebar': (k) => k.sidebar,
          'control': (k) => k.control,
          'controlHover': (k) => k.controlHover,
          'controlPress': (k) => k.controlPress,
          'overlay': (k) => k.overlay,
          'field': (k) => k.field,
          'accent': (k) => k.accent,
          'accentHover': (k) => k.accentHover,
          'accentPress': (k) => k.accentPress,
          'indicator': (k) => k.indicator,
          'selectionStrong': (k) => k.selectionStrong,
          'selectionStrongHover': (k) => k.selectionStrongHover,
          'channelThumb': (k) => k.channelThumb,
          'knob': (k) => k.knob,
          'hover': (k) => k.hover,
          'press': (k) => k.press,
          'disabled': (k) => k.disabled,
          'tooltip': (k) => k.tooltip,
          'scrim': (k) => k.scrim,
          for (final (n, st) in [
            ('neutral', (DsColors k) => k.neutral),
            ('danger', (DsColors k) => k.danger),
            ('success', (DsColors k) => k.success),
            ('warning', (DsColors k) => k.warning),
            ('info', (DsColors k) => k.info),
          ]) ...{
            '$n.fill': (k) => st(k).fill,
            '$n.fillHover': (k) => st(k).fillHover,
            '$n.fillPress': (k) => st(k).fillPress,
          },
        };
        final soft = k(DsContrast.soft);
        final changed = [
          for (final MapEntry(key: role, value: get) in backgrounds.entries)
            if (get(std) != get(soft)) role,
        ];
        expect(changed, isEmpty, reason: 'changed: $changed');
      });
    }
  }
}
