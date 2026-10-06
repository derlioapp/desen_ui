import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The type scale: the compact ramp is exactly what it was, the touch
/// ramp steps every role up, the default family follows the app's
/// platform (San Francisco in iOS and macOS apps), an explicit family
/// wins, and a display family sets the titles.
void main() {
  const bundled = 'packages/desen_ui_fonts/SchibstedGrotesk';

  /// (size, weight, tracking in em, line height) of [s].
  (double, int, double, double?) spec(TextStyle s) => (
    s.fontSize!,
    s.fontWeight!.value,
    (s.letterSpacing! / s.fontSize! * 1000).roundToDouble() / 1000,
    s.height == null ? null : (s.height! * 1000).roundToDouble() / 1000,
  );

  Map<String, TextStyle> roles(DsTypography y) => {
    'display': y.display,
    'title': y.title,
    'heading': y.heading,
    'body': y.body,
    'bodyStrong': y.bodyStrong,
    'small': y.small,
    'label': y.label,
    'labelStrong': y.labelStrong,
    'caption': y.caption,
    'fieldLabel': y.fieldLabel,
    'overline': y.overline,
  };

  /// Runs [body] as if the app ran on [platform].
  T on<T>(TargetPlatform platform, T Function() body) {
    debugDefaultTargetPlatformOverride = platform;
    try {
      return body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('compact ramp', () {
    test('is unchanged: every role at its exact size', () {
      final y = DsTypography();
      expect(y.density, DsDensity.compact);
      expect(roles(y).map((k, v) => MapEntry(k, spec(v))), {
        'display': (30.0, 700, -0.02, 1.1),
        'title': (22.0, 600, -0.02, 1.2),
        'heading': (16.0, 600, -0.01, null),
        'body': (14.0, 400, 0.0, 1.5),
        'bodyStrong': (14.0, 600, 0.0, null),
        'small': (13.0, 400, 0.0, 1.45),
        'label': (13.0, 500, 0.0, null),
        'labelStrong': (13.0, 600, 0.0, null),
        'caption': (12.0, 400, 0.0, 1.45),
        'fieldLabel': (12.0, 600, 0.0, null),
        'overline': (11.0, 600, 0.08, null),
      });
      for (final MapEntry(:key, :value) in roles(y).entries) {
        expect(value.fontFamily, bundled, reason: key);
        expect(
          value.leadingDistribution,
          TextLeadingDistribution.even,
          reason: key,
        );
      }
    });

    test('is what a compact theme carries, on any platform setting', () {
      for (final platform in TargetPlatform.values) {
        expect(
          DsThemeData(
            platform: platform,
            density: DsDensity.compact,
          ).typography,
          DsTypography(),
          reason: platform.name,
        );
      }
    });
  });

  group('touch ramp', () {
    test('steps every role up; body is 16 on a 22px line', () {
      final y = DsTypography(density: DsDensity.touch);
      expect(roles(y).map((k, v) => MapEntry(k, spec(v))), {
        'display': (34.0, 700, -0.02, 1.1),
        'title': (24.0, 600, -0.02, 1.2),
        'heading': (18.0, 600, -0.01, null),
        'body': (16.0, 400, 0.0, 1.375),
        'bodyStrong': (16.0, 600, 0.0, null),
        'small': (15.0, 400, 0.0, 1.333),
        'label': (15.0, 500, 0.0, null),
        'labelStrong': (15.0, 600, 0.0, null),
        'caption': (13.0, 400, 0.0, 1.385),
        'fieldLabel': (13.0, 600, 0.0, null),
        'overline': (12.0, 600, 0.08, null),
      });
      // Lines in whole pixels.
      expect(y.body.fontSize! * y.body.height!, 22);
      expect(y.small.fontSize! * y.small.height!, closeTo(20, 1e-9));
      expect(y.caption.fontSize! * y.caption.height!, closeTo(18, 1e-9));
    });

    test('keeps the hierarchy: every role grows, the order stays', () {
      final compact = roles(DsTypography());
      final touch = roles(DsTypography(density: DsDensity.touch));
      for (final name in compact.keys) {
        expect(
          touch[name]!.fontSize,
          greaterThan(compact[name]!.fontSize!),
          reason: name,
        );
        expect(
          touch[name]!.fontWeight,
          compact[name]!.fontWeight,
          reason: name,
        );
      }
      List<String> order(Map<String, TextStyle> r) =>
          r.keys.toList()
            ..sort((a, b) => r[b]!.fontSize!.compareTo(r[a]!.fontSize!));
      expect(order(touch), order(compact));
    });

    test('a touch theme carries it', () {
      final theme = DsThemeData(density: DsDensity.touch);
      expect(theme.typography, DsTypography(density: DsDensity.touch));
      expect(
        DsThemeData().copyWith(density: DsDensity.touch).typography,
        theme.typography,
      );
      expect(
        theme.copyWith(density: DsDensity.compact).typography,
        DsTypography(),
      );
    });

    test('a theme sets a given typography for its density, same fonts', () {
      final inter = DsTypography(family: 'Inter', package: null);
      final theme = DsThemeData(density: DsDensity.touch, typography: inter);
      expect(theme.typography.density, DsDensity.touch);
      expect(theme.typography.body.fontFamily, 'Inter');
      expect(theme.typography.body.fontSize, 16);
      // Replacing only the typography sets it for the density too.
      final copy = DsThemeData(density: DsDensity.touch)
          .copyWith(typography: inter);
      expect(copy.typography, theme.typography);
    });

    test('control labels follow the ramp: 12 13 14 16, touch 13 15 16 18', () {
      List<double> sizes(DsTypography y) => [
        for (final s in DsSize.values) y.controlLabel(s).fontSize!,
      ];
      expect(sizes(DsTypography()), [12, 13, 14, 16]);
      expect(sizes(DsTypography(density: DsDensity.touch)), [13, 15, 16, 18]);
      for (final s in DsSize.values) {
        final style = DsTypography().controlLabel(s);
        expect(style.fontWeight, FontWeight.w600, reason: s.name);
        expect(style.letterSpacing, 0, reason: s.name);
        expect(style.fontFamily, bundled, reason: s.name);
      }
    });
  });

  group('customization', () {
    test('roles replaced with copyWith keep their values at every density', () {
      const custom = TextStyle(fontSize: 19, fontWeight: FontWeight.w300);
      final y = DsTypography().copyWith(body: custom);
      final touch = y.forDensity(DsDensity.touch);
      expect(touch.body, custom);
      expect(touch.small, DsTypography(density: DsDensity.touch).small);
      // And back again.
      expect(touch.forDensity(DsDensity.compact), y);
      expect(
        DsThemeData(density: DsDensity.touch, typography: y).typography.body,
        custom,
      );
    });

    test('forDensity at its own density is the same object', () {
      final y = DsTypography();
      expect(identical(y.forDensity(DsDensity.compact), y), isTrue);
    });

    test('lerp switches fonts and density at the midpoint', () {
      final a = DsTypography();
      final b = DsTypography(density: DsDensity.touch);
      expect(DsTypography.lerp(a, b, 0.4).density, DsDensity.compact);
      expect(DsTypography.lerp(a, b, 0.6).density, DsDensity.touch);
      expect(DsTypography.lerp(a, b, 0.5).body.fontSize, 15);
    });

    test('equality counts fonts and density', () {
      expect(DsTypography(), DsTypography());
      expect(DsTypography() == DsTypography(density: DsDensity.touch), isFalse);
      expect(DsTypography() == DsTypography(displayFamily: 'Serif'), isFalse);
      expect(DsTypography() == DsTypography(monoFamily: 'Other'), isFalse);
    });
  });

  group('system font in Apple apps', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      test('${platform.name}: San Francisco by default', () {
        final y = on(platform, DsTypography.new);
        expect(y.family, DsTypography.systemFamily);
        expect(y.package, isNull);
        expect(y.displayFamily, DsTypography.systemDisplayFamily);
        expect(y.displayPackage, isNull);
        expect(y.body.fontFamily, 'CupertinoSystemText');
        expect(y.heading.fontFamily, 'CupertinoSystemText');
        // Titles (20px and up) in the display cut.
        expect(y.title.fontFamily, 'CupertinoSystemDisplay');
        expect(y.display.fontFamily, 'CupertinoSystemDisplay');
        // Code keeps the bundled mono.
        expect(y.mono(y.body).fontFamily, 'packages/desen_ui_fonts/GeistMono');
        // A theme built in the app carries it.
        expect(
          on(platform, () => DsThemeData().typography.family),
          DsTypography.systemFamily,
        );
      });
    }

    test('sizes stay; tracking is Apple\'s for each size', () {
      final compact = on(TargetPlatform.iOS, DsTypography.new);
      final touch = on(
        TargetPlatform.iOS,
        () => DsTypography(density: DsDensity.touch),
      );
      expect(compact.body.fontSize, 14);
      expect(touch.body.fontSize, 16);
      // Thousandths of an em: 14px −11, 16px −20, 13px −6, 12px 0,
      // 22px −12, 30px +14 (display cut).
      double em(TextStyle s) => s.letterSpacing! / s.fontSize!;
      expect(em(compact.body), closeTo(-0.011, 1e-9));
      expect(em(touch.body), closeTo(-0.020, 1e-9));
      expect(em(compact.label), closeTo(-0.006, 1e-9));
      expect(em(compact.caption), closeTo(0, 1e-9));
      expect(em(compact.title), closeTo(-0.012, 1e-9));
      expect(em(compact.display), closeTo(0.014, 1e-9));
      // The uppercase overline keeps its wide spacing.
      expect(em(compact.overline), closeTo(0.08, 1e-9));
      // A large control label takes Apple's tracking at its own size.
      expect(em(compact.controlLabel(DsSize.lg)), closeTo(-0.020, 1e-9));
    });

    test('tabular figures still apply in the system font', () {
      final y = on(TargetPlatform.iOS, DsTypography.new);
      final body = y.numeric(y.body);
      expect(body.fontFamily, 'CupertinoSystemText');
      expect(body.fontFeatures, contains(const FontFeature.tabularFigures()));
      // A title keeps the display cut.
      final title = y.numeric(y.title);
      expect(title.fontFamily, 'CupertinoSystemDisplay');
      expect(title.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      test('${platform.name}: the bundled family', () {
        final y = on(platform, DsTypography.new);
        expect(y.family, 'SchibstedGrotesk');
        expect(y.package, 'desen_ui_fonts');
        expect(y.displayFamily, 'SchibstedGrotesk');
        expect(y.body.fontFamily, bundled);
        expect(y.title.fontFamily, bundled);
      });
    }

    test('an explicit family wins on Apple platforms too', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        final inter = on(
          platform,
          () => DsTypography(family: 'Inter', package: null),
        );
        expect(inter.body.fontFamily, 'Inter', reason: platform.name);
        expect(inter.title.fontFamily, 'Inter', reason: platform.name);
        // Its own tracking, not Apple's.
        expect(inter.body.letterSpacing, 0, reason: platform.name);
        expect(
          inter.display.letterSpacing,
          closeTo(-0.02 * 30, 1e-9),
          reason: platform.name,
        );
        final bundledHere = on(
          platform,
          () => DsTypography(family: 'SchibstedGrotesk'),
        );
        expect(bundledHere.body.fontFamily, bundled, reason: platform.name);
      }
    });
  });

  group('display family', () {
    test('sets display and title; the rest stays in the text family', () {
      for (final density in DsDensity.values) {
        final y = DsTypography(
          displayFamily: 'Fraunces',
          displayPackage: null,
          density: density,
        );
        expect(y.display.fontFamily, 'Fraunces', reason: density.name);
        expect(y.title.fontFamily, 'Fraunces', reason: density.name);
        for (final MapEntry(:key, :value) in roles(y).entries) {
          if (key == 'display' || key == 'title') continue;
          expect(value.fontFamily, bundled, reason: '$key ${density.name}');
        }
        // The scale is the same, only the face changes.
        expect(y.title.fontSize, DsTypography(density: density).title.fontSize);
      }
    });

    test('defaults to the text family', () {
      final y = DsTypography(family: 'Inter', package: null);
      expect(y.displayFamily, 'Inter');
      expect(y.display.fontFamily, 'Inter');
    });

    test('a packaged display family is qualified', () {
      final y = DsTypography(displayFamily: 'Serif', displayPackage: 'fonts');
      expect(y.title.fontFamily, 'packages/fonts/Serif');
    });

    test('survives a density change and keeps titles in numeric()', () {
      final y = DsTypography(displayFamily: 'Fraunces', displayPackage: null);
      final touch = y.forDensity(DsDensity.touch);
      expect(touch.title.fontFamily, 'Fraunces');
      expect(touch.title.fontSize, 24);
      expect(y.numeric(y.title).fontFamily, 'Fraunces');
      expect(y.numeric(y.body).fontFamily, bundled);
    });

    test('an Apple app keeps a given display family', () {
      final y = on(
        TargetPlatform.iOS,
        () => DsTypography(displayFamily: 'Fraunces', displayPackage: null),
      );
      expect(y.title.fontFamily, 'Fraunces');
      expect(y.body.fontFamily, 'CupertinoSystemText');
      // A face of its own keeps its own tracking.
      expect(y.title.letterSpacing, closeTo(-0.02 * 22, 1e-9));
    });
  });

  group('font packages', () {
    // Off Apple platforms, where the default text family is the bundled
    // one.
    T offApple<T>(T Function() body) => on(TargetPlatform.android, body);

    test('an app family without a package is used as is', () {
      final y = offApple(() => DsTypography(family: 'Inter'));
      expect(y.package, isNull);
      expect(y.body.fontFamily, 'Inter');
      expect(y.title.fontFamily, 'Inter');
      // The bundled mono face keeps its package.
      expect(y.monoPackage, 'desen_ui_fonts');
      expect(y.mono(y.body).fontFamily, 'packages/desen_ui_fonts/GeistMono');
    });

    test('an app mono family without a package is used as is', () {
      final y = offApple(() => DsTypography(monoFamily: 'JetBrains Mono'));
      expect(y.monoPackage, isNull);
      expect(y.mono(y.body).fontFamily, 'JetBrains Mono');
      expect(y.body.fontFamily, bundled);
    });

    test('numeric() drops the package of a bundled style for an app '
        'family', () {
      final y = offApple(() => DsTypography(family: 'Inter'));
      const packaged = TextStyle(
        fontFamily: 'SchibstedGrotesk',
        package: DsTypography.fontsPackage,
        fontSize: 13,
      );
      final numeric = y.numeric(packaged);
      expect(numeric.fontFamily, 'Inter');
      expect(numeric.fontSize, 13);
    });

    test('a family from another package is qualified with it', () {
      final y = offApple(
        () => DsTypography(
          family: 'Inter',
          package: 'brand_fonts',
          monoFamily: 'Code',
          monoPackage: 'code_fonts',
        ),
      );
      expect(y.body.fontFamily, 'packages/brand_fonts/Inter');
      expect(y.mono(y.body).fontFamily, 'packages/code_fonts/Code');
    });

    test('the bundled faces keep the fonts package by default', () {
      final y = offApple(() => DsTypography(family: 'SchibstedGrotesk'));
      expect(y.body.fontFamily, bundled);
      expect(y.package, DsTypography.fontsPackage);
    });

    test('package: null declares even the bundled faces in the app', () {
      final y = offApple(() => DsTypography(package: null, monoPackage: null));
      expect(y.body.fontFamily, 'SchibstedGrotesk');
      expect(y.mono(y.body).fontFamily, 'GeistMono');
    });
  });
}
