import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';

/// KALITE.md §2.1 for the multi-select tags (K-85), read from the
/// component's own default style in every preset and a set of hard brand
/// colors, both modes and both contrasts:
///
/// - a resting tag is a neutral chip: its label 4.5:1 on its fill, the
///   remove cross 3:1 on the fill and on its hover and press steps;
/// - the active tag (the arrow keys') is the accent: the same two
///   bounds on its fill, and it stands apart from the resting tags;
/// - resting and disabled tags draw no edge.
const _seeds = {
  'blue': DsSeed.blue,
  'navy': DsSeed.navy,
  'graphite': DsSeed.graphite,
  'oxblood': DsSeed.oxblood,
  'forest': DsSeed.forest,
  'indigo': DsSeed.indigo,
};

const _brands = {
  'mcdonalds yellow': Color(0xFFFFC72C),
  'amazon orange': Color(0xFFFF9900),
  'twitter blue': Color(0xFF1DA1F2),
  'spotify green': Color(0xFF1DB954),
  'snapchat yellow': Color(0xFFFFFC00),
  'tiffany blue': Color(0xFF81D8D0),
  'pure black': Color(0xFF000000),
  'pure white': Color(0xFFFFFFFF),
  'lime': Color(0xFF00FF00),
  'sky': Color(0xFF7CE2FE),
};

void main() {
  final seeds = {
    ..._seeds,
    for (final MapEntry(key: name, value: c) in _brands.entries)
      name: DsSeed.color(c),
  };
  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    test('$name: tags read in both modes and contrasts', () {
      final failures = [
        for (final brightness in Brightness.values)
          for (final contrast in DsContrast.values)
            for (final f in tagFailures(
              DsThemeData(
                seed: seed,
                brightness: brightness,
                contrast: contrast,
              ),
            ))
              '${brightness.name} ${contrast.name}: $f',
      ];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }
}
