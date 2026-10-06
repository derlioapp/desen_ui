import 'dart:ui' show Brightness, Color;

import 'package:desen_ui/desen_ui.dart';
// The accessor Desen's components read the theme with.
import 'package:desen_ui/src/theme/theme.dart' show dsThemeOf;
import 'package:flutter/widgets.dart' hide Color;
import 'package:flutter_test/flutter_test.dart';

/// An app's tokens: a glow that follows the mode, and a fixed gap.
@immutable
class Brand extends DsThemeExtension<Brand> {
  const Brand({
    this.lightGlow = const Color(0xFF112233),
    this.darkGlow = const Color(0xFFDDEEFF),
    Color? glow,
    this.gap = 10,
  }) : glow = glow ?? lightGlow;

  final Color lightGlow, darkGlow, glow;
  final double gap;

  @override
  Brand resolve(DsThemeData theme) =>
      copyWith(glow: theme.isDark ? darkGlow : lightGlow);

  @override
  Brand copyWith({Color? glow, double? gap}) => Brand(
    lightGlow: lightGlow,
    darkGlow: darkGlow,
    glow: glow ?? this.glow,
    gap: gap ?? this.gap,
  );

  @override
  Brand lerp(Brand? other, double t) => other == null
      ? this
      : Brand(
          lightGlow: other.lightGlow,
          darkGlow: other.darkGlow,
          glow: Color.lerp(glow, other.glow, t),
          gap: gap + (other.gap - gap) * t,
        );

  @override
  bool operator ==(Object other) =>
      other is Brand &&
      other.lightGlow == lightGlow &&
      other.darkGlow == darkGlow &&
      other.glow == glow &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(lightGlow, darkGlow, glow, gap);
}

/// A second type, to check that extensions are keyed by type.
@immutable
class Charts extends DsThemeExtension<Charts> {
  const Charts(this.lines);

  final int lines;

  @override
  Charts copyWith({int? lines}) => Charts(lines ?? this.lines);

  @override
  Charts lerp(Charts? other, double t) =>
      t < .5 || other == null ? this : other;

  @override
  bool operator ==(Object other) => other is Charts && other.lines == lines;

  @override
  int get hashCode => lines.hashCode;
}

void main() {
  test('a theme holds one extension per type and finds it by type', () {
    final theme = DsThemeData(extensions: const [Brand(), Charts(3)]);
    expect(theme.extension<Brand>()?.gap, 10);
    expect(theme.extension<Charts>()?.lines, 3);
    expect(DsThemeData().extension<Brand>(), isNull);
    // A later one of the same type wins.
    final twice = DsThemeData(extensions: const [Brand(gap: 1), Brand(gap: 2)]);
    expect(twice.extensions, hasLength(1));
    expect(twice.extension<Brand>()?.gap, 2);
  });

  test('an extension resolves against the theme it lands in', () {
    final light = DsThemeData(extensions: const [Brand()]);
    expect(light.extension<Brand>()!.glow, const Color(0xFF112233));
    final dark = DsThemeData(
      brightness: Brightness.dark,
      extensions: const [Brand()],
    );
    expect(dark.extension<Brand>()!.glow, const Color(0xFFDDEEFF));
  });

  test('regenerating resolves the extensions again', () {
    final light = DsThemeData(extensions: const [Brand()]);
    final dark = light.copyWith(brightness: Brightness.dark);
    expect(dark.extension<Brand>()!.glow, const Color(0xFFDDEEFF));
    expect(
      dark.copyWith(brightness: Brightness.light).extension<Brand>(),
      light.extension<Brand>(),
    );
  });

  test('copyWith(extensions:) replaces them and keeps the tokens', () {
    final theme = DsThemeData(
      brightness: Brightness.dark,
      extensions: const [Brand()],
    );
    final copy = theme.copyWith(extensions: const [Charts(2)]);
    expect(copy.extension<Brand>(), isNull);
    expect(copy.extension<Charts>()?.lines, 2);
    expect(copy.colors, theme.colors);
    // Resolved against the (dark) theme.
    final again = copy.copyWith(extensions: const [Brand()]);
    expect(again.extension<Brand>()!.glow, const Color(0xFFDDEEFF));
  });

  test('extensions count in equality and the hash', () {
    final a = DsThemeData(extensions: const [Brand()]);
    final b = DsThemeData(extensions: const [Brand()]);
    final c = DsThemeData(extensions: const [Brand(gap: 11)]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
    expect(a.hashCode == c.hashCode, isFalse);
    expect(a == DsThemeData(), isFalse);
  });

  test('extensions do not make a theme hand-built', () {
    // Regenerating would assert on a theme whose tokens are not generated.
    final theme = DsThemeData(extensions: const [Brand()]);
    expect(() => theme.copyWith(density: DsDensity.touch), returnsNormally);
  });

  test('lerp interpolates shared extensions and switches the others', () {
    final a = DsThemeData(extensions: const [Brand(gap: 0), Charts(1)]);
    final b = DsThemeData(extensions: const [Brand(gap: 20)]);
    final mid = DsThemeData.lerp(a, b, .25);
    expect(mid.extension<Brand>()!.gap, 5);
    expect(mid.extension<Charts>()?.lines, 1);
    expect(DsThemeData.lerp(a, b, .75).extension<Charts>(), isNull);
  });

  testWidgets('DsAnimatedTheme moves an extension with the theme', (
    tester,
  ) async {
    double? gap;
    Widget app(DsThemeData data) => DsAnimatedTheme(
      data: data,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      child: Builder(
        builder: (context) {
          gap = DsTheme.extensionOf<Brand>(context)?.gap;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(
      app(DsThemeData(extensions: const [Brand(gap: 0)])),
    );
    expect(gap, 0);
    await tester.pumpWidget(
      app(DsThemeData(extensions: const [Brand(gap: 20)])),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(gap, moreOrLessEquals(10, epsilon: .5));
    await tester.pumpAndSettle();
    expect(gap, 20);
  });

  testWidgets('DsScope resolves extensions for dark mode', (tester) async {
    Color? glow;
    await tester.pumpWidget(
      DsScope(
        theme: DsThemeData(extensions: const [Brand()]),
        themeMode: DsThemeMode.dark,
        animateChanges: false,
        child: Builder(
          builder: (context) {
            glow = DsTheme.extensionOf<Brand>(context)?.glow;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(glow, const Color(0xFFDDEEFF));
  });

  testWidgets('extensionOf depends on extensions only', (tester) async {
    var builds = 0;
    final reader = Builder(
      builder: (context) {
        DsTheme.extensionOf<Brand>(context);
        builds++;
        return const SizedBox();
      },
    );
    final theme = DsThemeData(extensions: const [Brand()]);
    await tester.pumpWidget(DsTheme(data: theme, child: reader));
    expect(builds, 1);
    // A change elsewhere in the theme leaves the reader alone.
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(motion: const DsMotion(reduced: true)),
        child: reader,
      ),
    );
    expect(builds, 1);
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(extensions: const [Brand(gap: 12)]),
        child: reader,
      ),
    );
    expect(builds, 2);
  });

  testWidgets('the component accessor ignores a change of extensions', (
    tester,
  ) async {
    var builds = 0;
    final reader = Builder(
      builder: (context) {
        dsThemeOf(context);
        builds++;
        return const SizedBox();
      },
    );
    final theme = DsThemeData(extensions: const [Brand()]);
    await tester.pumpWidget(DsTheme(data: theme, child: reader));
    expect(builds, 1);
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(extensions: const [Brand(gap: 12)]),
        child: reader,
      ),
    );
    expect(builds, 1, reason: 'only the extensions changed');
    // A token group still rebuilds it…
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(motion: const DsMotion(reduced: true)),
        child: reader,
      ),
    );
    expect(builds, 2);
    // …and so does a setting that is not a token group.
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(
          motion: const DsMotion(reduced: true),
          selectionStyle: DsSelectionStyle.strong,
        ),
        child: reader,
      ),
    );
    expect(builds, 3);
  });

  testWidgets('DsTheme.of still follows a change of extensions', (
    tester,
  ) async {
    var builds = 0;
    final reader = Builder(
      builder: (context) {
        DsTheme.of(context);
        builds++;
        return const SizedBox();
      },
    );
    final theme = DsThemeData(extensions: const [Brand()]);
    await tester.pumpWidget(DsTheme(data: theme, child: reader));
    await tester.pumpWidget(
      DsTheme(
        data: theme.copyWith(extensions: const [Brand(gap: 12)]),
        child: reader,
      ),
    );
    expect(builds, 2);
  });
}
