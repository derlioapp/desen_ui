import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rule 12 of the pre-1.0 API round: `copyWith` on a hand-built theme keeps
/// its tokens unless a setting that only feeds generation changes, which
/// asserts.
void main() {
  const magenta = Color(0xFFFF00FF);

  /// A raw theme with hand-set colors and radii.
  DsThemeData custom() {
    final base = DsThemeData(density: DsDensity.compact);
    return DsThemeData.raw(
      brightness: base.brightness,
      seed: base.seed,
      contrast: base.contrast,
      cornerStyle: base.cornerStyle,
      density: base.density,
      platform: base.platform,
      selectionStyle: base.selectionStyle,
      autoClashRule: base.autoClashRule,
      dangerOverride: null,
      successOverride: null,
      seedRole: base.seedRole,
      colors: base.colors.copyWith(accent: magenta),
      shadows: base.shadows,
      radii: base.radii.copyWith(card: 0),
      sizes: base.sizes,
      typography: base.typography,
      motion: base.motion,
    );
  }

  test('a raw theme keeps its tokens through copyWith()', () {
    final raw = custom();
    expect(raw.copyWith(), raw);
    expect(raw.copyWith().colors.accent, magenta);
  });

  test('selection style, typography and motion change in place', () {
    final raw = custom();
    final typography = DsTypography(family: 'Mono');
    final copy = raw.copyWith(
      selectionStyle: DsSelectionStyle.strong,
      typography: typography,
      motion: const DsMotion(reduced: true),
    );
    expect(copy.selectionStyle, DsSelectionStyle.strong);
    expect(copy.typography, typography);
    expect(copy.motion.reduced, isTrue);
    expect(copy.colors, raw.colors);
    expect(copy.radii.card, 0);
    expect(copy.shadows, raw.shadows);
    expect(copy.sizes, raw.sizes);
  });

  test('a setting passed at its current value is no change', () {
    final raw = custom();
    final copy = raw.copyWith(
      brightness: raw.brightness,
      density: raw.density,
      platform: raw.platform,
      dangerOverride: () => null,
    );
    expect(copy, raw);
  });

  test('changing a generation input on a raw theme asserts', () {
    final raw = custom();
    expect(
      () => raw.copyWith(brightness: Brightness.dark),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('brightness'),
        ),
      ),
    );
    expect(() => raw.copyWith(density: DsDensity.touch), throwsAssertionError);
    expect(
      () => raw.copyWith(
        adjustRadii: () =>
            (r, _) => r,
      ),
      throwsAssertionError,
    );
  });

  test('a raw theme holding generated tokens regenerates freely', () {
    final base = DsThemeData(density: DsDensity.compact);
    final raw = DsThemeData.raw(
      brightness: base.brightness,
      seed: base.seed,
      contrast: base.contrast,
      cornerStyle: base.cornerStyle,
      density: base.density,
      platform: base.platform,
      selectionStyle: base.selectionStyle,
      autoClashRule: base.autoClashRule,
      dangerOverride: null,
      successOverride: null,
      seedRole: base.seedRole,
      colors: base.colors,
      shadows: base.shadows,
      radii: base.radii,
      sizes: base.sizes,
      typography: base.typography,
      motion: base.motion,
    );
    expect(
      raw.copyWith(brightness: Brightness.dark),
      DsThemeData(
        brightness: Brightness.dark,
        density: DsDensity.compact,
        platform: base.platform,
      ),
    );
  });

  test('a generated theme regenerates and keeps its hooks', () {
    DsRadii round(DsRadii r, DsCornerStyle _) => r.copyWith(card: 20);
    final theme = DsThemeData(adjustRadii: round);
    final dark = theme.copyWith(brightness: Brightness.dark);
    expect(dark.isDark, isTrue);
    expect(dark.radii.card, 20);
    expect(
      dark,
      DsThemeData(
        brightness: Brightness.dark,
        platform: theme.platform,
        adjustRadii: round,
      ),
    );
    // Only typography: the tokens are the same objects' values.
    final typed = theme.copyWith(typography: DsTypography(family: 'Mono'));
    expect(typed.colors, theme.colors);
    expect(typed.typography.family, 'Mono');
  });

  testWidgets('DsScope keeps a raw theme in light mode', (tester) async {
    late DsThemeData seen;
    await tester.pumpWidget(
      DsScope(
        theme: custom(),
        themeMode: DsThemeMode.light,
        animateChanges: false,
        child: Builder(
          builder: (context) {
            seen = DsTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.colors.accent, magenta);
  });

  testWidgets('DsScope in dark mode keeps a raw theme without a darkTheme', (
    tester,
  ) async {
    late DsThemeData seen;
    await tester.pumpWidget(
      DsScope(
        theme: custom(),
        themeMode: DsThemeMode.dark,
        animateChanges: false,
        child: Builder(
          builder: (context) {
            seen = DsTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull, reason: 'a warning, not a failure');
    expect(seen.colors.accent, magenta, reason: 'its tokens are kept');
  });
}
