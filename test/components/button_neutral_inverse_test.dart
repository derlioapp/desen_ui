import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The neutral (ink) and inverse (for accent grounds) buttons: their
/// colors in both modes, at both contrast levels and for any brand color,
/// with labels at 4.5:1 or more and a focus ring that shows where they
/// stand.
void main() {
  final seeds = {
    'blue': DsSeed.blue,
    'graphite': DsSeed.graphite,
    'oxblood': DsSeed.oxblood,
    'forest': DsSeed.forest,
    // A bright accent: a dark label on a light fill.
    'yellow': DsSeed.color(const Color(0xFFFFCC00)),
    'sky': DsSeed.color(const Color(0xFF5AC8FA)),
  };

  Iterable<(String, DsThemeData)> themes() sync* {
    for (final MapEntry(key: name, value: seed) in seeds.entries) {
      for (final brightness in Brightness.values) {
        for (final contrast in DsContrast.values) {
          yield (
            '$name ${brightness.name} ${contrast.name}',
            DsThemeData(seed: seed, brightness: brightness, contrast: contrast),
          );
        }
      }
    }
  }

  DsButtonStyle style(DsThemeData t, DsButtonVariant v) =>
      DsButton.defaultStyle(t, variant: v, size: DsSize.md);

  double cr(Color fg, Color bg, [Color backdrop = const Color(0xFFFFFFFF)]) =>
      DsColorUtils.contrastRatio(fg, bg, backdrop: backdrop);

  group('neutral', () {
    test('the ink under its inverse: near-black in light mode, soft white '
        'in dark mode', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final s = style(t, DsButtonVariant.neutral);
        expect(s.background, k.text, reason: reason);
        expect(s.foreground, t.isDark ? k.canvas : k.surface, reason: reason);
        // Flat, like the primary button, with the default gapped ring.
        expect(s.shadows, isEmpty, reason: reason);
        expect(s.borderColor, const Color(0x00000000), reason: reason);
        expect(s.focusShadows, t.focusShadows, reason: reason);
      }
    });

    test('hover and press move toward the label, press beyond hover, and '
        'the label stays at 7:1', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final s = style(t, DsButtonVariant.neutral);
        final rest = s.background!;
        final hover = s.resolve({WidgetState.hovered}).background!;
        final press = s.resolve({WidgetState.pressed}).background!;
        final lRest = DsOklch.fromColor(rest).l;
        final lHover = DsOklch.fromColor(hover).l;
        final lPress = DsOklch.fromColor(press).l;
        if (t.isDark) {
          // Dims, never glares.
          expect(lHover, lessThan(lRest), reason: reason);
          expect(lPress, lessThan(lHover), reason: reason);
        } else {
          expect(lHover, greaterThan(lRest), reason: reason);
          expect(lPress, greaterThan(lHover), reason: reason);
        }
        for (final fill in [rest, hover, press]) {
          for (final bg in [k.canvas, k.surface, k.overlay]) {
            expect(
              cr(s.foreground!, fill, bg),
              greaterThanOrEqualTo(7),
              reason: reason,
            );
          }
        }
      }
    });

    test('presses with the motion of a filled button', () {
      final t = DsThemeData();
      expect(
        style(t, DsButtonVariant.neutral).pressScale,
        t.motion.pressScaleLarge,
      );
      expect(
        DsButton.defaultStyle(
          t,
          variant: DsButtonVariant.neutral,
          size: DsSize.sm,
        ).pressScale,
        t.motion.pressScale,
      );
    });

    test('disabled looks like every other disabled button', () {
      final t = DsThemeData();
      final off = style(
        t,
        DsButtonVariant.neutral,
      ).resolve({WidgetState.disabled});
      expect(off.background, t.colors.disabled);
      expect(off.foreground, t.colors.onDisabled);
    });

    testWidgets('draws the ink and its label', (tester) async {
      final t = DsThemeData(brightness: Brightness.dark);
      await tester.pumpWidget(
        host(
          DsButton(
            variant: .neutral,
            onPressed: () {},
            child: const Text('New'),
          ),
          theme: t,
        ),
      );
      expect(buttonDecoration(tester).color, t.colors.text);
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('New'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, t.colors.canvas);
    });
  });

  group('inverse', () {
    test('the accent label color as the fill, the accent as the label', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final s = style(t, DsButtonVariant.inverse);
        expect(s.background, k.onAccent, reason: reason);
        expect(s.foreground, k.accent, reason: reason);
        final hover = s.resolve({WidgetState.hovered});
        final press = s.resolve({WidgetState.pressed});
        expect(hover.foreground, k.accentHover, reason: reason);
        expect(press.foreground, k.accentPress, reason: reason);
      }
    });

    test('labels read 4.5:1 on the accent ground, hover never weaker than '
        'rest below 7:1', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final s = style(t, DsButtonVariant.inverse);
        final rest = cr(s.foreground!, s.background!, k.accent);
        expect(rest, greaterThanOrEqualTo(4.5), reason: reason);
        final floor = rest < 7 ? rest : 7;
        for (final state in [WidgetState.hovered, WidgetState.pressed]) {
          final r = s.resolve({state});
          expect(
            cr(r.foreground!, r.background!, k.accent),
            greaterThanOrEqualTo(floor - .01),
            reason: '$reason ${state.name}',
          );
        }
      }
    });

    test('hover and press move away from rest, press beyond hover', () {
      for (final (reason, t) in themes()) {
        final s = style(t, DsButtonVariant.inverse);
        final rest = s.background!;
        final hover = s.resolve({WidgetState.hovered}).background!;
        final press = s.resolve({WidgetState.pressed}).background!;
        expect(
          cr(press, rest),
          greaterThanOrEqualTo(cr(hover, rest)),
          reason: reason,
        );
      }
      // The presets keep the full step: hover is visible.
      final t = DsThemeData();
      final s = style(t, DsButtonVariant.inverse);
      expect(s.resolve({WidgetState.hovered}).background, isNot(s.background));
    });

    test('the focus ring is in the label color, which shows on the accent', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final ring = style(t, DsButtonVariant.inverse).focusShadows!;
        expect(ring, hasLength(t.focusShadows.length), reason: reason);
        final outline = ring.firstWhere((x) => x.isOutline);
        expect(outline.color, k.onAccent, reason: reason);
        // Same geometry as every filled button's ring.
        final theirs = t.focusShadows.firstWhere((x) => x.isOutline);
        expect(outline.gap, theirs.gap, reason: reason);
        expect(outline.spread, theirs.spread, reason: reason);
        expect(cr(outline.color, k.accent), greaterThanOrEqualTo(3));
      }
    });

    test('disabled fades to a wash of the label color, legible on the '
        'accent', () {
      for (final (reason, t) in themes()) {
        final k = t.colors;
        final off = style(
          t,
          DsButtonVariant.inverse,
        ).resolve({WidgetState.disabled});
        expect(off.foreground, k.onAccent, reason: reason);
        expect(off.background!.a, lessThan(1), reason: reason);
        expect(off.focusShadows, isEmpty, reason: reason);
        expect(
          cr(off.foreground!, off.background!, k.accent),
          greaterThanOrEqualTo(3),
          reason: reason,
        );
      }
    });

    testWidgets('keyboard focus draws the ring in the label color', (
      tester,
    ) async {
      useTraditionalHighlights();
      final t = DsThemeData();
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsButton(
            variant: .inverse,
            focusNode: node,
            onPressed: () {},
            child: const Text('Start trial'),
          ),
          theme: t,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      final ring =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byType(DsButton),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .foregroundDecoration!
              as DsBoxDecoration;
      expect(
        ring.shadows.firstWhere((x) => x.isOutline).color,
        t.colors.onAccent,
      );
      expect(buttonDecoration(tester).color, t.colors.onAccent);
    });
  });
}
