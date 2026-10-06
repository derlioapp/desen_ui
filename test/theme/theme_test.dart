import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the theme seen at a point in the tree.
class Probe extends StatelessWidget {
  const Probe(this.onBuild, {super.key});

  final void Function(BuildContext) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox();
  }
}

/// Mimics an app root: MediaQuery from the test view, plus Directionality.
Widget host(Widget child) => Builder(
  builder: (context) => MediaQuery.fromView(
    view: View.of(context),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  ),
);

void main() {
  group('DsThemeData', () {
    test('defaults to blue, light, standard, compact', () {
      final t = DsThemeData(platform: TargetPlatform.macOS);
      expect(t.seed, DsSeed.blue);
      expect(t.isDark, isFalse);
      expect(t.seedRole, DsSeedRole.free);
      expect(t.colors.accent, const DsOklch(.565, .20, 257).toColor());
      expect(t.sizes, DsSizes.compact);
      expect(t.radii, DsRadii.standard);
    });

    test('the platform defaults to the running one', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;
        try {
          expect(DsThemeData().platform, platform);
          expect(DsThemeData().copyWith().platform, platform);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
      // A pinned platform survives regeneration.
      final pinned = DsThemeData(platform: TargetPlatform.iOS);
      expect(
        pinned.copyWith(density: DsDensity.touch).platform,
        pinned.platform,
      );
      expect(pinned, isNot(DsThemeData(platform: TargetPlatform.macOS)));
    });

    // Phones keep the compact visuals and get 44px tap areas;
    // rows are their own tap surface and keep their heights.
    test('iOS and Android get 44px tap areas around compact controls', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        final s = DsThemeData(
          platform: platform,
          density: DsDensity.compact,
        ).sizes;
        expect(s.minTapTarget, 44, reason: platform.name);
        for (final size in DsSize.values) {
          expect(s.height(size), DsSizes.compact.height(size));
        }
        expect(s.row, DsSizes.compact.row);
        expect(s.listRow, DsSizes.compact.listRow);
        expect(s.row, greaterThanOrEqualTo(24), reason: 'WCAG 2.5.8');
        expect(
          DsThemeData(platform: platform, density: DsDensity.touch).sizes,
          DsSizes.touch,
        );
      }
    });

    test('desktop platforms keep 24px tap areas', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        expect(DsThemeData(platform: platform).sizes, DsSizes.compact);
      }
    });

    test('equal inputs give equal themes', () {
      expect(DsThemeData(), DsThemeData());
      expect(DsThemeData().hashCode, DsThemeData().hashCode);
    });

    test('copyWith regenerates the palette when an input changes', () {
      final light = DsThemeData();
      final dark = light.copyWith(brightness: Brightness.dark);
      expect(dark, DsThemeData(brightness: Brightness.dark));
      expect(
        light.copyWith(seed: DsSeed.oxblood).seedRole,
        DsSeedRole.nearStatus,
      );
    });

    test('adjust hooks survive every regeneration', () {
      const lightLink = Color(0xFF123456), darkLink = Color(0xFFABCDEF);
      final t = DsThemeData(
        adjustColors: (k, b) =>
            k.copyWith(link: b == Brightness.dark ? darkLink : lightLink),
        adjustRadii: (r, style) => r.copyWith(card: r.card + 4),
        adjustSizes: (s, density) => s.copyWith(md: s.md + 2),
      );
      expect(t.colors.link, lightLink);
      expect(t.radii.card, 18);
      expect(t.sizes.md, 42);
      final changed = t.copyWith(
        brightness: Brightness.dark,
        contrast: DsContrast.soft,
        cornerStyle: DsCornerStyle.soft,
        density: DsDensity.touch,
      );
      expect(changed.colors.link, darkLink, reason: 'hook sees brightness');
      expect(changed.radii.card, 21 + 4, reason: 'soft card 21, +4');
      expect(changed.sizes.md, 40 + 2, reason: 'touch md 40, +2');
    });

    test('adjustSizes reaches icon sizes', () {
      final t = DsThemeData(
        adjustSizes: (s, density) => s.copyWith(iconMd: 18),
      );
      expect(t.sizes.iconSize(DsSize.md), 18);
      expect(t.sizes.iconSize(DsSize.lg), 20);
      expect(
        DsButton.defaultStyle(
          t,
          variant: DsButtonVariant.secondary,
          size: DsSize.md,
        ).iconSize,
        18,
      );
    });

    test('adjusted colors flow into generated shadows', () {
      const edge = Color(0xFF00AA00);
      final t = DsThemeData(
        adjustColors: (k, _) => k.copyWith(borderControl: edge),
      );
      expect(t.shadows.control.first, const DsShadow.ring(edge));
    });

    test('adjustShadows edits shadows after generation', () {
      final t = DsThemeData(
        adjustShadows: (s, k, b) => s.copyWith(surface: const []),
      );
      expect(t.shadows.surface, isEmpty);
      expect(t.copyWith(brightness: Brightness.dark).shadows.surface, isEmpty);
    });

    test('a hook can be cleared', () {
      final t = DsThemeData(adjustRadii: (r, _) => r.copyWith(card: 40));
      expect(t.copyWith(adjustRadii: () => null).radii.card, 14);
    });

    test('equality ignores hook identity, compares results', () {
      DsThemeData make() =>
          DsThemeData(adjustRadii: (r, _) => r.copyWith(card: 20));
      expect(make(), make(), reason: 'fresh closures, same tokens');
      expect(make() == DsThemeData(), isFalse);
    });

    test('lerp hits both ends', () {
      final a = DsThemeData(), b = DsThemeData(brightness: Brightness.dark);
      expect(DsThemeData.lerp(a, b, 0).colors, a.colors);
      expect(DsThemeData.lerp(a, b, 1).colors, b.colors);
    });

    test('selection style picks soft or filled selection colors', () {
      final soft = DsThemeData();
      final fill = DsThemeData(selectionStyle: DsSelectionStyle.strong);
      expect(soft.selectedFill, soft.colors.selection);
      expect(fill.selectedFill, fill.colors.selectionStrong);
      expect(fill.onSelectedFill, fill.colors.onSelectionStrong);
    });
  });

  group('DsRadii', () {
    // The rules themselves are tested in radii_test.dart.
    test('the corner style picks the rules', () {
      final sharp = DsThemeData(cornerStyle: DsCornerStyle.sharp);
      // Nearly square, clearly apart from the default.
      expect(sharp.radii.control(40), 4);
      expect(sharp.radii.card, 4);
      expect(DsThemeData(cornerStyle: DsCornerStyle.soft).radii.card, 21);
    });
  });

  group('DsSizes', () {
    // Every touch target reaches 44px, visually or by tap area.
    test('touch density meets 44px everywhere', () {
      const t = DsSizes.touch;
      expect(t.minTapTarget, greaterThanOrEqualTo(44));
      expect(t.row, greaterThanOrEqualTo(44), reason: 'rows are the target');
      expect(t.listRow, greaterThanOrEqualTo(44));
      // A calendar day draws smaller and takes the min tap area instead.
      expect(t.day, lessThanOrEqualTo(t.minTapTarget));
      for (final size in DsSize.values) {
        expect(t.height(size), lessThanOrEqualTo(48));
      }
    });
  });

  group('DsTheme', () {
    testWidgets('works without any scope, following platform brightness', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late DsThemeData seen;
      await tester.pumpWidget(host(Probe((c) => seen = DsTheme.of(c))));
      expect(seen.isDark, isTrue);
      expect(DsTheme.maybeOf(tester.element(find.byType(Probe))), isNull);
    });

    testWidgets('colorsOf does not rebuild when only radii change', (
      tester,
    ) async {
      var colorBuilds = 0, radiiBuilds = 0;
      // Same widget instances on every pump, so only the theme can trigger
      // a rebuild.
      final probes = Column(
        children: [
          Probe((c) {
            DsTheme.colorsOf(c);
            colorBuilds++;
          }),
          Probe((c) {
            DsTheme.radiiOf(c);
            radiiBuilds++;
          }),
        ],
      );
      Widget tree(DsThemeData data) => DsTheme(data: data, child: probes);
      final base = DsThemeData();
      await tester.pumpWidget(host(tree(base)));
      await tester.pumpWidget(
        host(tree(base.copyWith(cornerStyle: DsCornerStyle.soft))),
      );
      expect(radiiBuilds, 2);
      expect(colorBuilds, 1);
    });
  });

  group('DsScope', () {
    testWidgets('follows platform dark mode, contrast and reduce motion', (
      tester,
    ) async {
      tester.platformDispatcher
        ..platformBrightnessTestValue = Brightness.dark
        ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          highContrast: true,
          disableAnimations: true,
        );
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            theme: DsThemeData(contrast: DsContrast.soft),
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen.isDark, isTrue);
      expect(seen.contrast, DsContrast.standard);
      expect(seen.motion.reduced, isTrue);
    });

    testWidgets('themeMode overrides the platform', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            themeMode: DsThemeMode.light,
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen.isDark, isFalse);
    });

    testWidgets('dark theme is derived from the light theme by default', (
      tester,
    ) async {
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            theme: DsThemeData(seed: DsSeed.forest, density: DsDensity.touch),
            themeMode: DsThemeMode.dark,
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen.isDark, isTrue);
      expect(seen.seed, DsSeed.forest);
      expect(seen.density, DsDensity.touch);
    });

    DsThemeData rawTheme({DsContrast contrast = DsContrast.standard}) {
      final base = DsThemeData();
      return DsThemeData.raw(
        brightness: base.brightness,
        seed: base.seed,
        contrast: contrast,
        cornerStyle: base.cornerStyle,
        density: base.density,
        platform: base.platform,
        selectionStyle: base.selectionStyle,
        autoClashRule: base.autoClashRule,
        dangerOverride: null,
        successOverride: null,
        seedRole: base.seedRole,
        colors: base.colors.copyWith(accent: const Color(0xFFFF00FF)),
        shadows: base.shadows,
        radii: base.radii.copyWith(card: 0),
        sizes: base.sizes,
        typography: base.typography,
        motion: base.motion,
      );
    }

    // Platform accessibility settings change one setting, not the
    // app's hand-set tokens.
    testWidgets('keeps a raw theme\'s tokens under reduce motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            theme: rawTheme(),
            themeMode: DsThemeMode.light,
            animateChanges: false,
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen.motion.reduced, isTrue);
      expect(seen.colors.accent, const Color(0xFFFF00FF));
      expect(seen.radii.card, 0);
    });

    testWidgets('keeps a raw theme\'s tokens under more contrast', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            theme: rawTheme(contrast: DsContrast.soft),
            themeMode: DsThemeMode.light,
            animateChanges: false,
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen.contrast, DsContrast.standard);
      expect(seen.colors.accent, const Color(0xFFFF00FF));
      expect(seen.radii.card, 0);
    });

    testWidgets('a standard theme stays standard under more contrast', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          DsScope(
            themeMode: DsThemeMode.light,
            animateChanges: false,
            child: Probe((c) => seen = DsTheme.of(c)),
          ),
        ),
      );
      expect(seen, DsThemeData());
    });

    // The platform's "Increase contrast" lifts soft to standard, the
    // strongest level, regenerating its colors; turning the follow off
    // keeps the app's own level.
    for (final follow in [true, false]) {
      testWidgets('a soft theme follows the platform to standard: $follow', (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(highContrast: true);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        late DsThemeData seen;
        await tester.pumpWidget(
          host(
            DsScope(
              theme: DsThemeData(contrast: DsContrast.soft),
              themeMode: DsThemeMode.light,
              followPlatformContrast: follow,
              animateChanges: false,
              child: Probe((c) => seen = DsTheme.of(c)),
            ),
          ),
        );
        expect(
          seen,
          DsThemeData(contrast: follow ? DsContrast.standard : DsContrast.soft),
        );
      });
    }

    // Theme equality ignores hooks, so the scope's cache
    // must not hand back a dark theme derived from an old hook.
    testWidgets('a changed hook reaches the derived dark theme', (
      tester,
    ) async {
      var link = const Color(0xFFFF0000);
      var mode = DsThemeMode.dark;
      late StateSetter setOuter;
      late DsThemeData seen;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              final l = link;
              return DsScope(
                themeMode: mode,
                animateChanges: false,
                theme: DsThemeData(
                  adjustColors: (k, b) =>
                      b == Brightness.dark ? k.copyWith(link: l) : k,
                ),
                child: Probe((c) => seen = DsTheme.of(c)),
              );
            },
          ),
        ),
      );
      expect(seen.colors.link, const Color(0xFFFF0000));
      setOuter(() => mode = DsThemeMode.light);
      await tester.pump();
      setOuter(() => link = const Color(0xFF00FF00));
      await tester.pump();
      setOuter(() => mode = DsThemeMode.dark);
      await tester.pump();
      expect(seen.colors.link, const Color(0xFF00FF00));
    });

    testWidgets('sets default text style and icon color', (tester) async {
      late TextStyle text;
      late IconThemeData icon;
      await tester.pumpWidget(
        host(
          DsScope(
            themeMode: DsThemeMode.light,
            child: Probe((c) {
              text = DefaultTextStyle.of(c).style;
              icon = IconTheme.of(c);
            }),
          ),
        ),
      );
      final t = DsThemeData();
      expect(text.color, t.colors.text);
      expect(text.fontSize, 16);
      expect(icon.color, t.colors.text);
    });
  });

  group('DsApp', () {
    testWidgets('builds a home page on the canvas color', (tester) async {
      await tester.pumpWidget(
        const DsApp(themeMode: DsThemeMode.light, home: Text('Merhaba')),
      );
      expect(find.text('Merhaba'), findsOneWidget);
      final box = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text('Merhaba'),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(box.color, DsThemeData().colors.canvas);
    });

    testWidgets('navigates with DsPageRoute', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        DsApp(
          navigatorKey: key,
          home: const Text('A'),
          routes: {'/b': (_) => const Text('B')},
        ),
      );
      key.currentState!.pushNamed('/b');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.text('B'))),
        isA<DsPageRoute<dynamic>>(),
      );
    });
  });

  group('DsPageRoute', () {
    Future<(GlobalKey<NavigatorState>, DsPageRoute<Object?>)> push(
      WidgetTester tester,
    ) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        DsApp(
          navigatorKey: key,
          home: const Text('A'),
          routes: {'/b': (_) => const Text('B')},
        ),
      );
      key.currentState!.pushNamed('/b');
      await tester.pump();
      final route =
          ModalRoute.of(tester.element(find.text('B')))!
              as DsPageRoute<Object?>;
      return (key, route);
    }

    // No raw durations or curves; the theme's springs.
    testWidgets('times its transition with the theme motion', (tester) async {
      final (_, route) = await push(tester);
      const motion = DsMotion();
      expect(route.transitionDuration, motion.moveDuration);
      expect(route.reverseTransitionDuration, motion.toneDuration);
      await tester.pump(motion.moveDuration ~/ 2);
      expect(
        find.ancestor(of: find.text('B'), matching: find.byType(Transform)),
        findsWidgets,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('only fades with reduce motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final (_, route) = await push(tester);
      expect(route.transitionDuration, const DsMotion().toneDuration);
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        find.ancestor(of: find.text('B'), matching: find.byType(Transform)),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('B'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
    });

    // The curved animations are made once per route and disposed
    // with it, not allocated on every transition frame.
    testWidgets('disposes the curved animations it creates', (tester) async {
      final live = <Object>{};
      void track(ObjectEvent e) {
        if (e.object is! CurvedAnimation) return;
        if (e is ObjectCreated) live.add(e.object);
        if (e is ObjectDisposed) live.remove(e.object);
      }

      FlutterMemoryAllocations.instance.addListener(track);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(track),
      );
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        DsApp(
          navigatorKey: key,
          home: const Text('A'),
          routes: {'/b': (_) => const Text('B')},
        ),
      );
      await tester.pumpAndSettle();
      final before = live.length;
      key.currentState!.pushNamed('/b');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        live.length - before,
        lessThanOrEqualTo(3),
        reason: 'a fade and a move, plus the framework\'s own',
      );
      key.currentState!.pop();
      await tester.pumpAndSettle();
      expect(live.length, before);
    });
  });

  group('DsBoxDecoration', () {
    test('hit testing respects the corner radius', () {
      const d = DsBoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
      expect(d.hitTest(const Size(100, 40), const Offset(1, 1)), isFalse);
      expect(d.hitTest(const Size(100, 40), const Offset(50, 20)), isTrue);
    });

    testWidgets('paints every shadow kind without errors', (tester) async {
      final t = DsThemeData();
      await tester.pumpWidget(
        host(
          Center(
            child: Container(
              width: 120,
              height: 40,
              decoration: DsBoxDecoration(
                color: t.colors.control,
                borderRadius: BorderRadius.circular(t.radii.control(40)),
                shadows: [...t.shadows.overlay, ...t.shadows.focusOffset],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
