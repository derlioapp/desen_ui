import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('navy seed converts to the concept accent', () {
    expect(const DsOklch(0.43, 0.11, 262).toColor(), const Color(0xFF2D4D8B));
  });

  test('sRGB round-trips through OKLCH within one channel step', () {
    for (final argb in [
      0xFF2D4D8B,
      0xFFC83A35,
      0xFF3D865A,
      0xFFD48E00,
      0xFF808080,
      0xFFFFFFFF,
    ]) {
      final back = DsOklch.fromColor(Color(argb)).toColor().toARGB32();
      for (final shift in [16, 8, 0]) {
        expect(
          (((back >> shift) & 0xFF) - ((argb >> shift) & 0xFF)).abs(),
          lessThanOrEqualTo(1),
        );
      }
    }
  });

  test('gray has zero hue and near-zero chroma', () {
    final g = DsOklch.fromColor(const Color(0xFF777777));
    expect(g.c, lessThan(1e-4));
    expect(g.h, 0);
  });

  test('hueDistance takes the short way around', () {
    expect(DsOklch.hueDistance(10, 350), 20);
    expect(DsOklch.hueDistance(27, 262), 125);
  });

  test('mixing with black keeps the hue of the chromatic end', () {
    final red = DsOklch.fromColor(const Color(0xFFC83A35));
    final mixed = DsOklch.fromColor(
      DsOklch.mix(const Color(0xFFC83A35), const Color(0xFF000000), .12),
    );
    expect(DsOklch.hueDistance(mixed.h, red.h), lessThan(2));
    expect(mixed.l, lessThan(red.l));
  });

  test('fitted keeps the hue where clipping would shift it (H3)', () {
    // A dark yellow is far outside sRGB at this chroma.
    const dark = DsOklch(.566, .165, 86.5);
    expect(dark.inGamut, isFalse);
    final clipped = DsOklch.fromColor(dark.toColor());
    final fitted = DsOklch.fromColor(dark.fitted().toColor());
    expect(DsOklch.hueDistance(clipped.h, 86.5), greaterThan(8));
    expect(DsOklch.hueDistance(fitted.h, 86.5), lessThan(6));
    expect((fitted.l - .566).abs(), lessThan(.02));
    // In-gamut colors come back unchanged.
    const blue = DsOklch(.52, .1, 255);
    expect(blue.fitted(), blue);
  });
}
