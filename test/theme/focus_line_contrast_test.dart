import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_rules.dart';

/// The focus line of text-like fields and the tight ring of bordered
/// controls replace an edge instead of circling it with a gap, so the
/// focus color must stand 3:1 (WCAG 1.4.11) against what is on both sides
/// of that edge: the field fill or the control fill inside, the page
/// layers outside. Read-only text keeps full contrast on the page.
void main() {
  const seeds = {
    'blue': DsSeed.blue,
    'navy': DsSeed.navy,
    'graphite': DsSeed.graphite,
    'oxblood': DsSeed.oxblood,
    'forest': DsSeed.forest,
    'indigo': DsSeed.indigo,
  };

  for (final MapEntry(key: name, value: seed) in seeds.entries) {
    for (final brightness in Brightness.values) {
      for (final contrast in DsContrast.values) {
        test('$name ${brightness.name} ${contrast.name}', () {
          final t = DsThemeData(
            seed: seed,
            brightness: brightness,
            contrast: contrast,
          );
          final k = t.colors;
          final focus = k.focus;
          final tight = t.shadows.focusTight.single.color;
          final pages = {
            'canvas': k.canvas,
            'surface': k.surface,
            'overlay': k.overlay,
            'sidebar': k.sidebar,
          };
          final rules = [
            // Inside a focused field: the 2px edge on the field fill, on
            // every layer a field sits on.
            for (final MapEntry(key: page, value: bg) in pages.entries) ...[
              Rule(
                'focus line on field ($page)',
                focus,
                k.field,
                backdrop: bg,
                min: 3,
              ),
              // Outside the field (and a read-only field, which has no
              // fill): the page itself.
              Rule('focus line on $page', focus, bg, min: 3),
              // The tight ring: half outside on the page...
              Rule('tight ring on $page', tight, bg, min: 3),
              // ...half inside, on a secondary button's or search field's
              // fill, resting and hovered, and on a hovered chip.
              for (final (fillName, fill) in [
                ('control', k.control),
                ('controlHover', k.controlHover),
                ('hover', k.hover),
              ])
                Rule(
                  'tight ring on $fillName ($page)',
                  tight,
                  fill,
                  backdrop: bg,
                  min: 3,
                ),
              // Read-only text sits on the page, at full contrast.
              Rule('read-only text on $page', k.text, bg, min: 4.5),
            ],
          ];
          final failures = [for (final r in rules) ?r.check(withMax: false)];
          expect(failures, isEmpty, reason: failures.join('\n'));
          // Read-only and the resting field differ by their edge: the
          // decorative hairline, not the 3:1 field edge.
          expect(k.border, isNot(k.borderField));
        });
      }
    }
  }
}
