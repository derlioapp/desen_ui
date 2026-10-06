import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a theme without a density follows the platform', () {
    for (final (platform, expected) in [
      (TargetPlatform.iOS, DsDensity.touch),
      (TargetPlatform.android, DsDensity.touch),
      (TargetPlatform.macOS, DsDensity.compact),
      (TargetPlatform.windows, DsDensity.compact),
      (TargetPlatform.linux, DsDensity.compact),
      (TargetPlatform.fuchsia, DsDensity.compact),
    ]) {
      test(platform.name, () {
        final t = DsThemeData(platform: platform);
        expect(t.density, expected);
        expect(DsDensity.forPlatform(platform), expected);
        expect(t.sizes, DsSizes.forDensity(expected, platform: platform));
        expect(t.typography.density, expected);
      });
    }

    test('touch brings body 16 on a phone, compact keeps 14 on desktop', () {
      expect(
        DsThemeData(platform: TargetPlatform.iOS).typography.body.fontSize,
        16,
      );
      expect(
        DsThemeData(platform: TargetPlatform.macOS).typography.body.fontSize,
        14,
      );
    });

    test('an explicit density wins on every platform', () {
      expect(
        DsThemeData(
          platform: TargetPlatform.iOS,
          density: DsDensity.compact,
        ).density,
        DsDensity.compact,
      );
      expect(
        DsThemeData(
          platform: TargetPlatform.windows,
          density: DsDensity.touch,
        ).density,
        DsDensity.touch,
      );
    });

    test('the resolved density survives copyWith', () {
      final t = DsThemeData(platform: TargetPlatform.android);
      expect(t.copyWith(contrast: DsContrast.soft).density, DsDensity.touch);
      expect(t.copyWith(density: DsDensity.compact).density, DsDensity.compact);
    });
  });
}
