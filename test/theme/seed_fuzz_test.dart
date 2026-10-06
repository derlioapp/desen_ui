import 'dart:math' as math;
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/theme/palette.dart' show DsPalette;
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';
import 'contrast_budget_test.dart' show tierSpreadFailures;

/// S-24: any brand color, not just the presets, fits the contrast budget.
///
/// Real brand colors cover the hard cases (light yellows, oranges, sky
/// blues and greens); a fixed-seed random sweep covers the rest of the
/// OKLCH space.

const brands = {
  'mcdonalds yellow': Color(0xFFFFC72C),
  'amazon orange': Color(0xFFFF9900),
  'twitter blue': Color(0xFF1DA1F2),
  'spotify green': Color(0xFF1DB954),
  'coca-cola red': Color(0xFFF40009),
  'netflix red': Color(0xFFE50914),
  'slack aubergine': Color(0xFF4A154B),
  'whatsapp green': Color(0xFF25D366),
  'stripe blurple': Color(0xFF635BFF),
  'figma purple': Color(0xFFA259FF),
  'ikea blue': Color(0xFF0058A3),
  'snapchat yellow': Color(0xFFFFFC00),
  'tiffany blue': Color(0xFF81D8D0),
  'pure black': Color(0xFF000000),
  'pure white': Color(0xFFFFFFFF),
  'lime': Color(0xFF00FF00),
  'cyan': Color(0xFF00FFFF),
  'magenta': Color(0xFFFF00FF),
  'apple yellow': Color(0xFFFFCC00),
  'sky': Color(0xFF7CE2FE),
  'mint': Color(0xFF98FF98),
  'figma purple light': Color(0xFFB980FF),
};

/// ΔE in OKLab between two colors.
double deltaE(DsOklch a, DsOklch b) {
  double ab(DsOklch v, double Function(double) f) =>
      v.c * f(v.h * math.pi / 180);
  return math.sqrt(
    math.pow(a.l - b.l, 2) +
        math.pow(ab(a, math.cos) - ab(b, math.cos), 2) +
        math.pow(ab(a, math.sin) - ab(b, math.sin), 2),
  );
}

/// The bright-accent branch (K-38 revised): a light brand keeps its own
/// fill with a dark label. In light mode the accent is the seed itself
/// (lowered only where it would melt into a white card); in dark mode the
/// same lightness at the K-44 chroma cap. The unlabeled roles (indicator,
/// focus) stay darkened.
List<String> brightFailures(DsSeed seed) {
  final v = seed.value;
  if (!v.inGamut) return const [];
  final failures = <String>[];
  for (final brightness in Brightness.values) {
    final k = DsPalette.fromSeed(seed, brightness: brightness).colors;
    if (!isBright(k)) continue;
    final dark = brightness == Brightness.dark;
    final accent = DsOklch.fromColor(k.accent);
    final target = dark ? v.copyWith(c: math.min(v.c, .148)) : v;
    // Only the white-card floor may lower it, and only a little.
    final e = deltaE(accent, target);
    if (e > .04) {
      failures.add(
        '${brightness.name}: accent ΔE ${e.toStringAsFixed(3)} from seed',
      );
    }
    // (8-bit quantization moves lightness by up to ~.002.)
    if (!dark && accent.l > v.l + .005) {
      failures.add('light: accent lighter than the seed');
    }
    // Light mode: the unlabeled roles keep the darkened color. (Dark mode's
    // indicator is its own lighter role already, K-44.)
    if (!dark &&
        DsColorUtils.luminance(k.indicator) >=
            DsColorUtils.luminance(k.accent)) {
      failures.add('light: indicator not darker than accent');
    }
  }
  return failures;
}

/// Brand fidelity (H3): the accent keeps the seed's hue (within the few
/// degrees CSS gamut mapping allows) even when it has to be darkened for its
/// label, and a near-status seed's selection stays in
/// the brand's family while keeping clear of that status.
List<String> fidelityFailures(DsSeed seed) {
  final v = seed.value;
  if (v.c < .05 || !v.inGamut) return const [];
  final failures = <String>[];
  for (final brightness in Brightness.values) {
    final p = DsPalette.fromSeed(seed, brightness: brightness);
    final k = p.colors;
    double hue(Color c) => DsOklch.fromColor(c).h;
    final accent = DsOklch.fromColor(k.accent);
    if (accent.c > .03 && DsOklch.hueDistance(accent.h, v.h) > 8) {
      failures.add(
        '${brightness.name}: accent hue ${accent.h.round()} drifts from '
        'seed ${v.h.round()}',
      );
    }
    // In dark mode a warm brand selects in gray (K-161): no hue to check.
    final graySelection = DsOklch.fromColor(k.selection).c < .02;
    if (p.role == DsSeedRole.nearStatus && !graySelection) {
      final sel = hue(k.selection);
      final status = DsOklch.hueDistance(v.h, 27) < 35
          ? hue(k.danger.text)
          : hue(k.success.text);
      if (DsOklch.hueDistance(sel, v.h) > 25) {
        failures.add(
          '${brightness.name}: selection hue ${sel.round()} strays from '
          'seed ${v.h.round()}',
        );
      }
      if (DsOklch.hueDistance(sel, status) < 30) {
        failures.add(
          '${brightness.name}: selection hue ${sel.round()} is near the '
          'status hue ${status.round()}',
        );
      }
    }
  }
  return failures;
}

List<String> failuresFor(DsSeed seed) => [
  ...fidelityFailures(seed),
  ...brightFailures(seed),
  for (final brightness in Brightness.values)
    for (final contrast in DsContrast.values) ...[
      for (final f in budgetFailures(
        DsPalette.fromSeed(seed, brightness: brightness, contrast: contrast),
        dark: brightness == Brightness.dark,
        level: contrast,
      ))
        '${brightness.name} ${contrast.name}: $f',
      for (final f in componentFailures(
        DsThemeData(seed: seed, brightness: brightness, contrast: contrast),
      ))
        '${brightness.name} ${contrast.name}: $f',
    ],
  for (final brightness in Brightness.values)
    for (final f in tierSpreadFailures(
      DsPalette.fromSeed(seed, brightness: brightness).colors,
      dark: brightness == Brightness.dark,
    ))
      '${brightness.name}: $f',
  for (final contrast in DsContrast.values)
    for (final f in darkNotMoreChromatic(
      DsPalette.fromSeed(seed, contrast: contrast).colors,
      DsPalette.fromSeed(
        seed,
        brightness: Brightness.dark,
        contrast: contrast,
      ).colors,
    ))
      '${contrast.name}: $f',
  for (final contrast in DsContrast.values)
    for (final f in darkKeepsVivid(
      DsPalette.fromSeed(seed, contrast: contrast).colors,
      DsPalette.fromSeed(
        seed,
        brightness: Brightness.dark,
        contrast: contrast,
      ).colors,
    ))
      '${contrast.name}: $f',
];

void main() {
  for (final MapEntry(key: name, value: color) in brands.entries) {
    test('$name fits the budget', () {
      final failures = failuresFor(DsSeed.color(color));
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  test('300 random seeds fit the budget', () {
    final random = math.Random(27);
    final failures = <String>[];
    for (var i = 0; i < 300; i++) {
      final seed = DsSeed.oklch(
        .2 + random.nextDouble() * .75,
        random.nextDouble() * .3,
        random.nextDouble() * 360,
      );
      failures.addAll(failuresFor(seed).map((f) => '$seed $f'));
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
  });

  test('a seed that already passes keeps its exact accent', () {
    final p = DsPalette.fromSeed(DsSeed.navy);
    expect(p.colors.accent, const DsOklch(.43, .11, 262).toColor());
  });

  test('no preset takes the bright branch', () {
    for (final seed in [
      DsSeed.blue,
      DsSeed.navy,
      DsSeed.graphite,
      DsSeed.oxblood,
      DsSeed.forest,
      DsSeed.indigo,
    ]) {
      for (final brightness in Brightness.values) {
        final k = DsPalette.fromSeed(seed, brightness: brightness).colors;
        expect(k.onAccent, const Color(0xFFFFFFFF), reason: '$seed');
        expect(isBright(k), isFalse);
      }
    }
  });

  test('a light brand keeps its fill and gets a dark label', () {
    final seed = DsSeed.color(const Color(0xFFFFC72C));
    for (final brightness in Brightness.values) {
      final p = DsPalette.fromSeed(seed, brightness: brightness);
      final k = p.colors;
      expect(isBright(k), isTrue, reason: brightness.name);
      // The label is tinted toward the brand, not black.
      final label = DsOklch.fromColor(k.onAccent);
      expect(label.l, lessThan(.3));
      expect(DsOklch.hueDistance(label.h, seed.h), lessThan(8));
      // Hover and press lighten under a dark label (K-29, K-68).
      expect(
        DsColorUtils.luminance(k.accentHover),
        greaterThan(DsColorUtils.luminance(k.accent)),
      );
      expect(
        DsColorUtils.luminance(k.accentPress),
        greaterThan(DsColorUtils.luminance(k.accentHover)),
      );
      // The selected strong fill follows the accent.
      expect(k.selectionStrong, k.accent);
      expect(k.onSelectionStrong, k.onAccent);
      // The switch knob gets a dark edge on the on track only.
      expect(ringOf(p.shadows.knobOn), isNotNull);
      expect(p.shadows.knob, isNot(p.shadows.knobOn));
    }
    final light = DsPalette.fromSeed(seed).colors;
    expect(light.accent, seed.value.toColor());
    // Unlabeled roles stay darkened, hue kept (H3).
    final ink = DsOklch.fromColor(light.indicator);
    expect(ink.l, lessThan(seed.l - .2));
    expect(DsOklch.hueDistance(ink.h, seed.h), lessThan(8));
    expect(light.focus, light.indicator);
  });

  test('a seed that carries neither label well is darkened', () {
    // White 3.9:1, a dark label 4.5:1: neither reaches the default
    // button's 5.5:1, so the fill darkens for a white label.
    final seed = DsSeed.color(const Color(0xFFA259FF));
    final k = DsPalette.fromSeed(seed).colors;
    expect(isBright(k), isFalse);
    expect(k.onAccent, const Color(0xFFFFFFFF));
    expect(DsOklch.fromColor(k.accent).l, lessThan(seed.l));
  });

  test('a light neutral seed is darkened, never a white button', () {
    for (final color in [const Color(0xFFFFFFFF), const Color(0xFFCCCCCC)]) {
      final k = DsPalette.fromSeed(DsSeed.color(color)).colors;
      expect(isBright(k), isFalse);
      expect(k.onAccent, const Color(0xFFFFFFFF));
    }
  });

  test('a near-white bright seed stands off the card and darkens on hover', () {
    final seed = DsSeed.color(const Color(0xFFFFFC00));
    final k = DsPalette.fromSeed(seed).colors;
    expect(isBright(k), isTrue);
    expect(
      DsColorUtils.contrastRatio(k.accent, k.surface),
      greaterThanOrEqualTo(1.2),
    );
    // No room to lighten twice: hover darkens, the label stays above 7:1.
    expect(
      DsColorUtils.luminance(k.accentHover),
      lessThan(DsColorUtils.luminance(k.accent)),
    );
    expect(
      DsColorUtils.contrastRatio(k.onAccent, k.accentPress),
      greaterThanOrEqualTo(7),
    );
  });

  test(
    'a red brand keeps a red-family selection, apart from danger (light)',
    () {
      for (final seed in [
        DsSeed.color(const Color(0xFFF40009)),
        DsSeed.oxblood,
      ]) {
        // Dark mode selects a warm brand in gray, the brand in the text
        // (K-161).
        final dark = DsPalette.fromSeed(seed, brightness: Brightness.dark);
        expect(DsOklch.fromColor(dark.colors.selection).c, lessThan(.02));
        expect(
          DsOklch.hueDistance(
            DsOklch.fromColor(dark.colors.onSelection).h,
            seed.h,
          ),
          lessThanOrEqualTo(25),
        );
        for (final brightness in [Brightness.light]) {
          final k = DsPalette.fromSeed(seed, brightness: brightness).colors;
          final sel = DsOklch.fromColor(k.selection).h;
          expect(DsOklch.hueDistance(sel, seed.h), lessThanOrEqualTo(25));
          expect(
            DsOklch.hueDistance(sel, DsOklch.fromColor(k.danger.text).h),
            greaterThanOrEqualTo(30),
          );
        }
      }
    },
  );
}
