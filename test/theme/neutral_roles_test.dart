import 'dart:math' as math;
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/theme/palette.dart' show DsPalette, DsSeedRole;
import 'package:flutter_test/flutter_test.dart';

import 'seed_fuzz_test.dart' show brands;

/// Neutral roles are near-pure grays on one cool slate hue whatever the
/// brand, and the dark soft selection keeps a cool brand's color but turns
/// gray for a warm one.

/// The roles drawn in gray: the page and surface steps, the text tiers,
/// edges, channels, disabled, tooltip, scrim and the neutral status.
/// Roles drawn in pure white or black (a light surface, dark edges) have
/// no hue to check and are left out.
Map<String, Color> neutralRoles(DsColors k) => {
  'canvas': k.canvas,
  'surface': k.surface,
  'sidebar': k.sidebar,
  'control': k.control,
  'controlHover': k.controlHover,
  'controlPress': k.controlPress,
  'overlay': k.overlay,
  'field': k.field,
  'text': k.text,
  'textMuted': k.textMuted,
  'textSubtle': k.textSubtle,
  'border': k.border,
  'borderControl': k.borderControl,
  'borderField': k.borderField,
  'borderChip': k.borderChip,
  'channel': k.channel,
  'channelStrong': k.channelStrong,
  'skeleton': k.skeleton,
  'skeletonStrong': k.skeletonStrong,
  'rail': k.rail,
  'hover': k.hover,
  'press': k.press,
  'disabled': k.disabled,
  'onDisabled': k.onDisabled,
  'scrim': k.scrim,
  'tooltip': k.tooltip,
  'neutral.fill': k.neutral.fill,
  'neutral.fillHover': k.neutral.fillHover,
  'neutral.fillPress': k.neutral.fillPress,
  'neutral.tint': k.neutral.tint,
  'neutral.tintHover': k.neutral.tintHover,
  'neutral.tintPress': k.neutral.tintPress,
  'neutral.text': k.neutral.text,
};

/// The neutral chroma ceiling (8-bit rounding adds up to ~0.002 on a
/// near-gray).
const neutralChromaMax = .012, quantization = .002;

/// The cool slate hue of every brand's grays.
const slateHue = 255.0;

/// Below this chroma an 8-bit gray's hue is rounding noise.
const hueReadable = .006;

final seeds = <String, DsSeed>{
  'blue': DsSeed.blue,
  'navy': DsSeed.navy,
  'graphite': DsSeed.graphite,
  'oxblood': DsSeed.oxblood,
  'forest': DsSeed.forest,
  'indigo': DsSeed.indigo,
  for (final MapEntry(key: name, value: color) in brands.entries)
    name: DsSeed.color(color),
  for (final (i, s) in _random().indexed) 'random $i $s': s,
};

List<DsSeed> _random() {
  final random = math.Random(59);
  return [
    for (var i = 0; i < 200; i++)
      DsSeed.oklch(
        .2 + random.nextDouble() * .75,
        random.nextDouble() * .3,
        random.nextDouble() * 360,
      ),
  ];
}

Iterable<(String, DsPalette)> palettes(DsSeed seed) sync* {
  for (final b in Brightness.values) {
    for (final c in DsContrast.values) {
      yield (
        '${b.name} ${c.name}',
        DsPalette.fromSeed(seed, brightness: b, contrast: c),
      );
    }
  }
}

void main() {
  test('neutral roles stay near pure: chroma at most 0.012', () {
    final failures = <String>[];
    for (final MapEntry(key: name, value: seed) in seeds.entries) {
      for (final (mode, p) in palettes(seed)) {
        for (final MapEntry(key: role, value: color) in neutralRoles(
          p.colors,
        ).entries) {
          final c = DsOklch.fromColor(color).c;
          if (c > neutralChromaMax + quantization) {
            failures.add('$name $mode $role chroma ${c.toStringAsFixed(4)}');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
  });

  test('a brand seed\'s grays take the slate hue, no more tinted than '
      'the blue preset\'s', () {
    final blue = {
      for (final (mode, p) in palettes(DsSeed.blue))
        mode: neutralRoles(p.colors),
    };
    final failures = <String>[];
    for (final MapEntry(key: name, value: seed) in seeds.entries) {
      for (final (mode, p) in palettes(seed)) {
        if (p.role == DsSeedRole.neutral) continue;
        for (final MapEntry(key: role, value: color) in neutralRoles(
          p.colors,
        ).entries) {
          final v = DsOklch.fromColor(color);
          final ref = DsOklch.fromColor(blue[mode]![role]!).c;
          if (v.c > ref + quantization) {
            failures.add(
              '$name $mode $role chroma ${v.c.toStringAsFixed(4)} > blue '
              '${ref.toStringAsFixed(4)}',
            );
          }
          if (v.c >= hueReadable &&
              DsOklch.hueDistance(v.h, slateHue) > hueTolerance(v.c)) {
            failures.add(
              '$name $mode $role hue ${v.h.round()} (chroma '
              '${v.c.toStringAsFixed(4)}), not slate',
            );
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
  });

  test('a neutral seed\'s grays keep its own hue', () {
    // A warm stone gray: the brand's own gray, not the slate.
    const stone = DsSeed.oklch(.55, .025, 60);
    final failures = <String>[];
    for (final (mode, p) in palettes(stone)) {
      expect(p.role, DsSeedRole.neutral);
      for (final MapEntry(key: role, value: color) in neutralRoles(
        p.colors,
      ).entries) {
        final v = DsOklch.fromColor(color);
        if (v.c >= hueReadable &&
            DsOklch.hueDistance(v.h, 60) > hueTolerance(v.c)) {
          failures.add('$mode $role hue ${v.h.round()}, not the seed\'s 60');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('dark soft selection: a cool brand keeps its color up to 0.09 '
      'chroma, a warm or near-status brand selects in gray', () {
    final failures = <String>[];
    for (final MapEntry(key: name, value: seed) in seeds.entries) {
      final h = seed.value.h;
      for (final contrast in DsContrast.values) {
        final p = DsPalette.fromSeed(
          seed,
          brightness: Brightness.dark,
          contrast: contrast,
        );
        if (p.role == DsSeedRole.neutral) continue;
        final cool = p.role != DsSeedRole.nearStatus && h >= 180 && h <= 330;
        final k = p.colors;
        for (final (role, color) in [
          ('selection', k.selection),
          ('selectionHover', k.selectionHover),
        ]) {
          final v = DsOklch.fromColor(color);
          final where = '$name ${contrast.name} $role';
          if (cool) {
            if (v.c > .09 + quantization) {
              failures.add('$where chroma ${v.c.toStringAsFixed(3)} > 0.09');
            }
            // The brand's own color, not a gray: its hue, with as much
            // chroma as a faint brand has (at least 0.03 for any other).
            final want = math.min(seed.value.c * .55, .03);
            if (v.c < want - quantization) {
              failures.add('$where gray (${v.c.toStringAsFixed(3)})');
            } else if (DsOklch.hueDistance(v.h, h) > hueTolerance(v.c)) {
              failures.add(
                '$where hue ${v.h.round()} strays from ${h.round()}',
              );
            }
          } else if (v.c > neutralChromaMax + quantization) {
            failures.add(
              '$where chroma ${v.c.toStringAsFixed(3)}: not gray for a '
              'warm brand',
            );
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
  });
}

/// How far an 8-bit gray's hue may sit from its intended hue: rounding
/// moves a channel by up to half a step, which turns the hue more the
/// lower the chroma.
double hueTolerance(double chroma) => math.min(60, 8 + .25 / chroma);
