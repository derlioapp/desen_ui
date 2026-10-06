import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final light = DsThemeData();

  group('DsButton basics', () {
    testWidgets('works without any scope and calls onPressed on tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(DsButton(onPressed: () => taps++, child: const Text('Kaydet'))),
      );
      await tester.tap(find.text('Kaydet'));
      expect(taps, 1);
    });

    testWidgets('null onPressed disables: no tap, disabled colors, no shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DsButton(onPressed: null, child: Text('Pasif')),
          theme: light,
        ),
      );
      final d = buttonDecoration(tester);
      expect(d.color, light.colors.disabled);
      expect(visibleShadows(d), isEmpty);
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Pasif'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, light.colors.onDisabled);
    });

    testWidgets('variants take their theme colors', (tester) async {
      final k = light.colors;
      final expected = {
        DsButtonVariant.primary: k.accent,
        DsButtonVariant.secondary: k.control,
        DsButtonVariant.tinted: k.accent.withValues(alpha: .15),
        DsButtonVariant.ghost: const Color(0x00000000),
        DsButtonVariant.dangerSoft: k.danger.tint,
        DsButtonVariant.danger: k.danger.fill,
        DsButtonVariant.neutral: k.text,
        DsButtonVariant.inverse: k.onAccent,
      };
      for (final MapEntry(key: variant, value: color) in expected.entries) {
        await tester.pumpWidget(
          host(
            DsButton(
              variant: variant,
              onPressed: () {},
              child: const Text('x'),
            ),
            theme: light,
          ),
        );
        expect(buttonDecoration(tester).color, color, reason: variant.name);
      }
    });

    testWidgets('secondary draws its edge as a 1px ring', (tester) async {
      await tester.pumpWidget(
        host(
          DsButton(
            variant: .secondary,
            onPressed: () {},
            child: const Text('x'),
          ),
          theme: light,
        ),
      );
      expect(
        buttonDecoration(tester).shadows.first,
        DsShadow.ring(light.colors.borderControl),
      );
    });

    testWidgets('heights follow the size scale (compact)', (tester) async {
      for (final (size, h) in [
        (DsSize.xs, 28.0),
        (DsSize.sm, 32.0),
        (DsSize.md, 40.0),
        (DsSize.lg, 48.0),
      ]) {
        await tester.pumpWidget(
          host(
            DsButton(size: size, onPressed: () {}, child: const Text('x')),
            theme: light,
          ),
        );
        expect(buttonBoxSize(tester).height, h, reason: size.name);
      }
    });

    testWidgets('icon button is square and named for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsButton.icon(
            icon: const DsIcon(DsIcons.ellipsis),
            semanticLabel: 'Daha fazla',
            onPressed: () {},
          ),
          theme: light,
        ),
      );
      expect(buttonBoxSize(tester), const Size(40, 40));
      expect(
        tester.getSemantics(find.byType(DsButton)),
        isSemantics(isButton: true, isEnabled: true, label: 'Daha fazla'),
      );
      semantics.dispose();
    });

    testWidgets('text button exposes button semantics with its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(DsButton(onPressed: () {}, child: const Text('Kaydet'))),
      );
      expect(
        tester.getSemantics(find.byType(DsButton)),
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Kaydet',
          hasTapAction: true,
        ),
      );
      await tester.pumpWidget(
        host(const DsButton(onPressed: null, child: Text('Kaydet'))),
      );
      expect(
        tester.getSemantics(find.byType(DsButton)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
      );
      semantics.dispose();
    });
  });

  group('DsButton interaction', () {
    testWidgets('hover switches to the hover color', (tester) async {
      useTraditionalHighlights();
      await tester.pumpWidget(
        host(
          DsButton(onPressed: () {}, child: const Text('x')),
          theme: light,
        ),
      );
      await hover(tester, find.byType(DsButton));
      expect(buttonDecoration(tester).color, light.colors.accentHover);
    });

    testWidgets('pressing scales the button down, releasing restores it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DsButton(onPressed: () {}, child: const Text('x')),
          theme: light,
        ),
      );
      double scale() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(DsSpringValue),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0];
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DsButton)),
      );
      await tester.pumpAndSettle();
      expect(scale(), closeTo(0.955, .001));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1, .001));
    });

    testWidgets('Enter and Space activate, without an app root', (
      tester,
    ) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsButton(
            focusNode: node,
            onPressed: () => taps++,
            child: const Text('x'),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      expect(taps, 3);
    });

    testWidgets('Tab moves focus and skips disabled buttons', (tester) async {
      useTraditionalHighlights();
      final pressed = <String>[];
      await tester.pumpWidget(
        DsApp(
          themeMode: DsThemeMode.light,
          home: Column(
            children: [
              DsButton(
                onPressed: () => pressed.add('a'),
                child: const Text('A'),
              ),
              const DsButton(onPressed: null, child: Text('B')),
              DsButton(
                onPressed: () => pressed.add('c'),
                child: const Text('C'),
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, ['a', 'c']);
    });

    for (final (name, theme) in [
      ('standard contrast', light),
      ('soft contrast', light.copyWith(contrast: DsContrast.soft)),
    ]) {
      testWidgets('keyboard focus, $name', (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          host(
            DsButton(
              variant: DsButtonVariant.secondary,
              focusNode: node,
              onPressed: () {},
              child: const Text('x'),
            ),
            theme: theme,
          ),
        );
        node.requestFocus();
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTouch;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.pumpAndSettle();
        // The ring is drawn above the fill: the foreground decoration.
        List<DsShadow> ring() =>
            (tester
                        .widget<AnimatedContainer>(
                          find
                              .descendant(
                                of: find.byType(DsButton),
                                matching: find.byType(AnimatedContainer),
                              )
                              .first,
                        )
                        .foregroundDecoration!
                    as DsBoxDecoration)
                .shadows;
        // A click or tap never shows focus.
        var d = buttonDecoration(tester);
        expect(ring(), isEmpty);
        expect(d.color, theme.colors.control);

        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        await tester.pumpAndSettle();
        d = buttonDecoration(tester);
        // The tight ring of a bordered button, and not the hover look.
        expect(ring(), theme.shadows.focusTight);
        expect(d.color, theme.colors.control);
      });
    }

    testWidgets('loading ignores presses but keeps the enabled look', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          DsButton(
            loading: true,
            onPressed: () => taps++,
            child: const Text('Kaydet'),
          ),
          theme: light,
        ),
      );
      await tester.tap(find.text('Kaydet'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(DsSpinner), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget, reason: 'label stays');
      expect(buttonDecoration(tester).color, light.colors.accent);
    });

    testWidgets('a theme change is followed directly, not re-animated', (
      tester,
    ) async {
      final dark = DsThemeData(brightness: Brightness.dark);
      Widget tree(DsThemeData t) => host(
        DsButton(onPressed: () {}, child: const Text('x')),
        theme: t,
      );
      await tester.pumpWidget(tree(light));
      await tester.pumpWidget(tree(dark));
      expect(buttonDecoration(tester).color, dark.colors.accent);
    });

    testWidgets('hovering rebuilds only the button', (tester) async {
      useTraditionalHighlights();
      var siblingBuilds = 0;
      final sibling = Builder(
        builder: (context) {
          DsTheme.of(context);
          siblingBuilds++;
          return const SizedBox(width: 10, height: 10);
        },
      );
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsButton(onPressed: () {}, child: const Text('x')),
              sibling,
            ],
          ),
          theme: light,
        ),
      );
      final before = siblingBuilds;
      await hover(tester, find.byType(DsButton));
      expect(siblingBuilds, before);
    });
  });

  group('DsButton layout and i18n', () {
    testWidgets('grows with large text instead of overflowing', (tester) async {
      await tester.pumpWidget(
        host(
          DsButton(onPressed: () {}, child: const Text('Kaydet')),
          theme: light,
          textScale: 4,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(buttonBoxSize(tester).height, greaterThan(40));
    });

    testWidgets('touch density keeps the button size, adds a 44 tap area', (
      tester,
    ) async {
      final touch = DsThemeData(density: DsDensity.touch);
      await tester.pumpWidget(
        host(
          DsButton(size: .xs, onPressed: () {}, child: const Text('x')),
          theme: touch,
        ),
      );
      expect(buttonBoxSize(tester).height, 28, reason: 'same as pointer');
      expect(tester.getSize(find.byType(DsButton)).height, 44);
    });

    testWidgets('leading icon sits on the start side in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DsButton(
            leading: const DsIcon(DsIcons.plus),
            onPressed: () {},
            child: const Text('Yeni'),
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getCenter(find.byType(DsIcon)).dx,
        greaterThan(tester.getCenter(find.text('Yeni')).dx),
      );
    });

    testWidgets('icons report their size to intrinsic layouts', (tester) async {
      await tester.pumpWidget(
        host(const IntrinsicWidth(child: DsIcon(DsIcons.plus, size: 20))),
      );
      expect(tester.getSize(find.byType(IntrinsicWidth)).width, 20);
    });

    testWidgets('directional icons mirror in RTL', (tester) async {
      expect(DsIcons.chevronRight.matchTextDirection, isTrue);
      expect(DsIcons.chevronLeft.matchTextDirection, isTrue);
      expect(DsIcons.plus.matchTextDirection, isFalse);
    });

    testWidgets('a long label ellipsizes in a narrow box', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 90,
            child: DsButton(
              onPressed: () {},
              child: const Text('Çok uzun bir buton etiketi'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fills a tight width and centers its label', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: DsButton(onPressed: () {}, child: const Text('Kaydet')),
          ),
        ),
      );
      expect(buttonBoxSize(tester).width, 300);
      expect(
        tester.getCenter(find.text('Kaydet')).dx,
        closeTo(tester.getCenter(find.byType(DsButton)).dx, 0.5),
      );
    });
  });

  group('DsButton regressions', () {
    testWidgets('loading keeps keyboard focus and announces loading', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      Widget tree(bool loading) => host(
        DsButton(
          focusNode: node,
          loading: loading,
          onPressed: () {},
          child: const Text('Kaydet'),
        ),
        theme: light,
      );
      await tester.pumpWidget(tree(false));
      node.requestFocus();
      await tester.pump();
      await tester.pumpWidget(tree(true));
      expect(node.hasFocus, isTrue, reason: 'loading keeps focus');
      final data = tester
          .getSemantics(find.byType(DsPressable))
          .getSemanticsData();
      expect(data.label, 'Kaydet');
      expect(data.value, 'Loading');
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      await tester.pumpWidget(tree(false));
      expect(node.hasFocus, isTrue);
    });

    testWidgets('loading does not change the width', (tester) async {
      Widget tree(bool loading, {Widget? leading}) => host(
        DsButton(
          loading: loading,
          leading: leading,
          onPressed: () {},
          child: const Text('Kaydet'),
        ),
        theme: light,
      );
      await tester.pumpWidget(tree(false));
      final idle = buttonBoxSize(tester);
      await tester.pumpWidget(tree(true));
      expect(buttonBoxSize(tester), idle);
      expect(find.byType(DsSpinner), findsOneWidget);
      await tester.pumpWidget(tree(false, leading: const DsIcon(DsIcons.plus)));
      final withIcon = buttonBoxSize(tester);
      await tester.pumpWidget(tree(true, leading: const DsIcon(DsIcons.plus)));
      expect(buttonBoxSize(tester), withIcon);
      expect(find.byType(DsIcon), findsNothing, reason: 'spinner replaces it');
    });

    test('tinted: an accent wash under accent ink, never an edge', () {
      DsButtonStyle tinted(DsThemeData t) => DsButton.defaultStyle(
        t,
        variant: DsButtonVariant.tinted,
        size: DsSize.md,
      );
      for (final brightness in Brightness.values) {
        for (final contrast in DsContrast.values) {
          final t = DsThemeData(brightness: brightness, contrast: contrast);
          final k = t.colors;
          final s = tinted(t);
          final dark = brightness == Brightness.dark;
          final reason = '${brightness.name} ${contrast.name}';
          // The accent's wash: 15% in light mode, 18% in dark mode, or a
          // little less where the ink needs it on some layer.
          expect(s.background!.withValues(alpha: 1), k.accent, reason: reason);
          expect(
            s.background!.a,
            inInclusiveRange(.12, dark ? .18 : .15),
            reason: reason,
          );
          expect(s.foreground, k.accentText, reason: reason);
          expect(s.shadows, isEmpty, reason: reason);
          // Hover and press each add more of the wash.
          final hover = s.resolve({WidgetState.hovered}).background!;
          final press = s.resolve({WidgetState.pressed}).background!;
          expect(hover.a, greaterThan(s.background!.a), reason: reason);
          expect(press.a, greaterThan(hover.a), reason: reason);
          // The rest wash reads as a fill: a visible step off the surface.
          expect(
            DsColorUtils.contrastRatio(
              DsColorUtils.flatten(s.background!, k.surface),
              k.surface,
            ),
            greaterThan(1.1),
            reason: reason,
          );
          // A fill, not an outline, at every level.
          expect(s.borderColor, const Color(0x00000000), reason: reason);
          // Disabled looks like every other disabled button.
          final off = s.resolve({WidgetState.disabled});
          expect(off.background, k.disabled, reason: reason);
          expect(off.foreground, k.onDisabled, reason: reason);
        }
      }
    });

    test('tinted: a pale brand gets a lighter wash, never weaker ink', () {
      // A light yellow brand: its ink is dark, close to the wash's
      // luminance, so the full wash would cost contrast.
      for (final brightness in Brightness.values) {
        final t = DsThemeData(
          seed: DsSeed.color(const Color(0xFFFFFC00)),
          brightness: brightness,
        );
        final s = DsButton.defaultStyle(
          t,
          variant: DsButtonVariant.tinted,
          size: DsSize.md,
        ).resolve({WidgetState.pressed});
        for (final bg in [t.colors.canvas, t.colors.surface]) {
          expect(
            DsColorUtils.contrastRatio(
              s.foreground!,
              s.background!,
              backdrop: bg,
            ),
            greaterThanOrEqualTo(4.5),
            reason: brightness.name,
          );
        }
      }
    });

    testWidgets('pressed goes one step beyond hovered', (tester) async {
      final k = light.colors;
      for (final (variant, press) in [
        (DsButtonVariant.primary, k.accentPress),
        (DsButtonVariant.secondary, k.controlPress),
        (DsButtonVariant.tinted, k.accent.withValues(alpha: .23)),
        (DsButtonVariant.dangerSoft, k.danger.tintPress),
        (DsButtonVariant.danger, k.danger.fillPress),
        (DsButtonVariant.ghost, k.press),
      ]) {
        final states = WidgetStatesController({WidgetState.pressed});
        addTearDown(states.dispose);
        await tester.pumpWidget(
          host(
            DsButton(
              key: ValueKey(variant),
              variant: variant,
              statesController: states,
              onPressed: () {},
              child: const Text('x'),
            ),
            theme: light,
          ),
        );
        expect(buttonDecoration(tester).color, press, reason: '$variant');
      }
    });

    test('lerp blends in premultiplied alpha', () {
      const white = Color(0xFFFFFFFF);
      final mid = DsButtonStyle.lerp(
        const DsButtonStyle(background: Color(0x00000000)),
        const DsButtonStyle(background: white),
        .5,
      );
      // Color.lerp would give a half-transparent gray (0x80808080).
      expect(mid.background, white.withValues(alpha: .5));
    });

    testWidgets('the border ring keeps its slot', (tester) async {
      final states = WidgetStatesController();
      addTearDown(states.dispose);
      await tester.pumpWidget(
        host(
          DsButton(
            statesController: states,
            style: const DsButtonStyle(
              borderColor: Color(0xFF00AA00),
              hovered: DsButtonStyle(borderColor: Color(0x00000000)),
            ),
            onPressed: () {},
            child: const Text('x'),
          ),
          theme: light,
        ),
      );
      final rest = buttonDecoration(tester).shadows;
      states.update(WidgetState.hovered, true);
      await tester.pumpAndSettle();
      final hovered = buttonDecoration(tester).shadows;
      expect(hovered.length, rest.length);
      expect(hovered.first.spread, rest.first.spread);
      expect(hovered.first.color.a, 0);
      expect(hovered.skip(1), rest.skip(1));
    });

    test('filled buttons are flat: no glow or lift; a bright accent keeps '
        'an inner hairline', () {
      const yellow = DsSeed.oklch(0.86, 0.17, 95);
      for (final seed in [DsSeed.blue, DsSeed.graphite, yellow]) {
        for (final brightness in Brightness.values) {
          for (final contrast in DsContrast.values) {
            final t = DsThemeData(
              seed: seed,
              brightness: brightness,
              contrast: contrast,
            );
            final k = t.colors;
            for (final variant in [
              DsButtonVariant.primary,
              DsButtonVariant.danger,
            ]) {
              final shadows = DsButton.defaultStyle(
                t,
                variant: variant,
                size: DsSize.md,
              ).shadows!;
              expect(
                shadows.where((x) => x.blur > 0 || x.offset != Offset.zero),
                isEmpty,
                reason: '$variant $seed $brightness $contrast',
              );
              // Only under a bright accent (a dark label): a white-labeled
              // fill keeps its buttons flat even where its checked
              // controls wear an edge (dark mode).
              final bright =
                  DsColorUtils.luminance(k.onAccent) <
                  DsColorUtils.luminance(k.accent);
              final edge =
                  variant == DsButtonVariant.primary &&
                  bright &&
                  k.accentEdge.a > 0;
              expect(
                shadows,
                edge
                    ? [DsShadow.innerRing(k.onAccent.withValues(alpha: .2))]
                    : isEmpty,
                reason: '$variant $seed $brightness $contrast',
              );
            }
          }
        }
      }
      // The yellow seed is bright: the edge is really exercised.
      expect(DsThemeData(seed: yellow).colors.accentEdge.a, greaterThan(0));
    });

    test('every variant and size sets its label in 600', () {
      for (final variant in DsButtonVariant.values) {
        for (final size in DsSize.values) {
          expect(
            DsButton.defaultStyle(
              light,
              variant: variant,
              size: size,
            ).textStyle!.fontWeight,
            FontWeight.w600,
            reason: '$variant $size',
          );
        }
      }
    });

    test('adjustShadows can still give the primary button a lift', () {
      const lift = DsShadow(
        color: Color(0x33000000),
        offset: Offset(0, 1),
        blur: 2,
      );
      final t = DsThemeData(
        adjustShadows: (s, k, b) => s.copyWith(accent: [lift]),
      );
      expect(
        DsButton.defaultStyle(
          t,
          variant: DsButtonVariant.primary,
          size: DsSize.md,
        ).shadows,
        [lift],
      );
    });

    testWidgets('a long-press-only button works', (tester) async {
      var long = 0;
      await tester.pumpWidget(
        host(
          DsButton(
            onPressed: null,
            onLongPress: () => long++,
            child: const Text('Basılı tut'),
          ),
          theme: light,
        ),
      );
      await tester.longPress(find.text('Basılı tut'));
      expect(long, 1);
      expect(buttonDecoration(tester).color, light.colors.accent);
    });

    testWidgets('a zero-duration spring does not crash', (tester) async {
      final theme = DsThemeData(
        motion: const DsMotion(
          toneSpring: DsSpring(duration: Duration.zero),
          moveSpring: DsSpring(duration: Duration.zero),
        ),
      );
      await tester.pumpWidget(
        host(
          DsButton(onPressed: () {}, child: const Text('OK')),
          theme: theme,
        ),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(theme.motion.toneDuration, Duration.zero);
    });
  });
}
