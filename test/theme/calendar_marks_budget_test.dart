import 'dart:math' as math;
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart' show WidgetState;
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';
import 'contrast_budget_test.dart' show seeds;
import 'seed_fuzz_test.dart' show brands;

/// The calendar's day marks against the contrast budget (§2.1), over the
/// presets, the brand colors and a random sweep, both modes and both
/// contrasts: today's ring (a non-text indicator, 3:1) and the chosen
/// day's solid fill, which is the strong pair whatever the selection style.
List<String> calendarMarkFailures(DsThemeData t) {
  final k = t.colors;
  final style = DsCalendar.defaultStyle(t);
  final selected = DsCalendarStyle.resolveLayers(
    [style],
    {WidgetState.selected},
  );
  final selectedHover = DsCalendarStyle.resolveLayers(
    [style],
    {WidgetState.selected, WidgetState.hovered},
  );
  final ring = style.todayBorderColor!;
  final band = DsColorUtils.flatten(k.accentTint, k.overlay);
  return [
    if (selected.dayBackground != k.selectionStrong)
      'selected day is not the strong fill (${t.selectionStyle.name})',
    if (selectedHover.dayBackground != k.selectionStrongHover)
      'selected day hover is not the strong hover (${t.selectionStyle.name})',
    for (final r in [
      for (final (name, bg) in [
        ('overlay', k.overlay),
        ('surface', k.surface),
        ('canvas', k.canvas),
        ('range band', band),
      ])
        Rule('today ring on $name', ring, bg, min: 3),
      Rule(
        'selected day label',
        selected.dayForeground!,
        selected.dayBackground!,
        backdrop: k.overlay,
        min: 4.5,
      ),
      Rule(
        'selected day label on hover',
        selectedHover.dayForeground!,
        selectedHover.dayBackground!,
        backdrop: k.overlay,
        min: 4.5,
      ),
    ])
      ?r.check(withMax: false),
  ];
}

List<String> failuresFor(DsSeed seed) => [
  for (final brightness in Brightness.values)
    for (final contrast in DsContrast.values)
      for (final selection in DsSelectionStyle.values)
        for (final f in calendarMarkFailures(
          DsThemeData(
            seed: seed,
            brightness: brightness,
            contrast: contrast,
            selectionStyle: selection,
          ),
        ))
          '${brightness.name} ${contrast.name} ${selection.name}: $f',
];

void main() {
  test('presets', () {
    final failures = [
      for (final MapEntry(key: name, value: seed) in seeds.entries)
        for (final f in failuresFor(seed)) '$name $f',
    ];
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('brand colors', () {
    final failures = [
      for (final MapEntry(key: name, value: color) in brands.entries)
        for (final f in failuresFor(DsSeed.color(color))) '$name $f',
    ];
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('100 random seeds', () {
    final random = math.Random(24);
    final failures = <String>[];
    for (var i = 0; i < 100; i++) {
      final seed = DsSeed.oklch(
        .2 + random.nextDouble() * .75,
        random.nextDouble() * .3,
        random.nextDouble() * 360,
      );
      failures.addAll(failuresFor(seed).map((f) => '$seed $f'));
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
  });
}
