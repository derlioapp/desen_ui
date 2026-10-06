import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// `warningOverride` replaces the generated warning like `dangerOverride`
/// and `successOverride` do theirs: the fill is the given color, the other
/// shades derive from it and the text reads on the surface and the tint.
void main() {
  double ratio(Color a, Color b) => DsColorUtils.contrastRatio(a, b);

  const amber = Color(0xFFF5A524);
  const burnt = Color(0xFF9A3412);
  const lime = Color(0xFFC6E33B);

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      DsColors colors(Color override) =>
          DsThemeData(brightness: brightness, warningOverride: override).colors;

      test('the fill is the given color; hover and press step off it', () {
        for (final c in [amber, burnt, lime]) {
          final w = colors(c).warning;
          expect(w.fill, c);
          expect(w.fillHover, isNot(c));
          expect(w.fillPress, isNot(w.fillHover));
        }
      });

      test('the text reads 4.5:1 on the surface and on the tint', () {
        for (final c in [amber, burnt, lime]) {
          final k = colors(c);
          expect(
            ratio(k.warning.text, k.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$c on surface',
          );
          expect(
            ratio(k.warning.text, k.warning.tint),
            greaterThanOrEqualTo(4.5),
            reason: '$c on tint',
          );
        }
      });

      test('the signal stands 3:1 off the layers', () {
        for (final c in [amber, burnt, lime]) {
          final k = colors(c);
          for (final ground in [k.canvas, k.surface, k.overlay]) {
            expect(
              ratio(k.warning.signal, ground),
              greaterThanOrEqualTo(3),
              reason: '$c signal',
            );
          }
        }
      });

      test('a light fill keeps the dark label, a deep one takes white', () {
        final generated = DsThemeData(brightness: brightness).colors.warning;
        expect(colors(amber).warning.onFill, generated.onFill);
        expect(colors(burnt).warning.onFill, const Color(0xFFFFFFFF));
        // Hover never lowers the label's contrast on a light fill.
        final w = colors(amber).warning;
        expect(
          ratio(w.onFill, w.fillHover),
          greaterThanOrEqualTo(ratio(w.onFill, w.fill)),
        );
      });
    });
  }

  test('no override leaves the generated warning alone', () {
    expect(DsThemeData(warningOverride: null).colors, DsThemeData().colors);
  });

  test('changing the override regenerates the colors', () {
    final theme = DsThemeData();
    final copy = theme.copyWith(warningOverride: () => amber);
    expect(copy.warningOverride, amber);
    expect(copy.colors.warning.fill, amber);
    expect(copy.copyWith(warningOverride: () => null).colors, theme.colors);
  });
}
