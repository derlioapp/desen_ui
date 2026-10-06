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

  group('copyWith(platform:)', () {
    test('derives the density again when none was given', () {
      final desktop = DsThemeData(platform: TargetPlatform.macOS);
      expect(desktop.densityFollowsPlatform, isTrue);
      final phone = desktop.copyWith(platform: TargetPlatform.iOS);
      expect(phone.density, DsDensity.touch);
      expect(phone.typography.body.fontSize, 16);
      expect(
        phone.sizes,
        DsSizes.forDensity(DsDensity.touch, platform: TargetPlatform.iOS),
      );
      expect(phone, DsThemeData(platform: TargetPlatform.iOS));
      // And back.
      expect(
        phone.copyWith(platform: TargetPlatform.windows),
        DsThemeData(platform: TargetPlatform.windows),
      );
    });

    test('keeps following the platform through other changes', () {
      final t = DsThemeData(platform: TargetPlatform.macOS)
          .copyWith(brightness: Brightness.dark)
          .copyWith(selectionStyle: DsSelectionStyle.strong);
      expect(t.densityFollowsPlatform, isTrue);
      expect(
        t.copyWith(platform: TargetPlatform.android).density,
        DsDensity.touch,
      );
    });

    test('a density given to the constructor stays', () {
      final t = DsThemeData(
        platform: TargetPlatform.macOS,
        density: DsDensity.compact,
      );
      expect(t.densityFollowsPlatform, isFalse);
      final phone = t.copyWith(platform: TargetPlatform.iOS);
      expect(phone.density, DsDensity.compact);
      expect(phone.typography.body.fontSize, 14);
    });

    test('a density given to copyWith stays', () {
      final t = DsThemeData(platform: TargetPlatform.iOS)
          .copyWith(density: DsDensity.compact);
      expect(t.densityFollowsPlatform, isFalse);
      expect(
        t.copyWith(platform: TargetPlatform.android).density,
        DsDensity.compact,
      );
      // Pinned at the value the platform gave counts as given, too.
      final pinned = DsThemeData(platform: TargetPlatform.iOS)
          .copyWith(density: DsDensity.touch);
      expect(pinned.densityFollowsPlatform, isFalse);
      expect(
        pinned.copyWith(platform: TargetPlatform.macOS).density,
        DsDensity.touch,
      );
    });

    test('whether the density follows the platform counts for equality', () {
      final follows = DsThemeData(platform: TargetPlatform.iOS);
      final given = DsThemeData(
        platform: TargetPlatform.iOS,
        density: DsDensity.touch,
      );
      expect(follows.density, given.density);
      expect(follows == given, isFalse);
      expect(follows, DsThemeData(platform: TargetPlatform.iOS));
      expect(
        follows.hashCode,
        DsThemeData(platform: TargetPlatform.iOS).hashCode,
      );
    });

    test('a theme that follows the platform still regenerates freely', () {
      // Not mistaken for a hand-built theme: no assert.
      final t = DsThemeData(platform: TargetPlatform.macOS);
      expect(() => t.copyWith(platform: TargetPlatform.iOS), returnsNormally);
      expect(() => t.copyWith(contrast: DsContrast.soft), returnsNormally);
    });
  });
}
