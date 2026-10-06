import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// No flash in fill transitions: a fill fading in from transparent must
/// never pass through a darker (or lighter) color than its two ends. The
/// bug: `Color.lerp` mixed transparent black into the hue, so a light
/// selection fill flashed gray mid-way (bottom nav, chips, menus…).
void main() {
  test('premultiplied lerp keeps the hue while fading in', () {
    const blue = Color(0xFFCCE4FF);
    final mid = DsColorUtils.lerp(const Color(0x00000000), blue, .5)!;
    expect(mid.a, closeTo(.5, 1e-9));
    expect((mid.r, mid.g, mid.b), (blue.r, blue.g, blue.b));
    expect(DsColorUtils.lerp(null, blue, 1), blue);
    expect(DsColorUtils.lerp(blue, null, 0), blue);
  });

  // Every fill a component fades in from transparent, on every surface it
  // can sit on, in every theme: the flattened color stays between its ends.
  for (final brightness in Brightness.values) {
    for (final selection in DsSelectionStyle.values) {
      test('no dip: ${brightness.name}, ${selection.name} selection', () {
        final t = DsThemeData(
          brightness: brightness,
          selectionStyle: selection,
        );
        final k = t.colors;
        final fills = {
          'selectedFill': t.selectedFill,
          'selection': k.selection,
          'hover': k.hover,
          'press': k.press,
          'accent': k.accent,
          'danger.tint': k.danger.tint,
          'controlHover': k.controlHover,
          'disabled': k.disabled,
        };
        final pages = {
          'canvas': k.canvas,
          'surface': k.surface,
          'overlay': k.overlay,
          'sidebar': k.sidebar,
        };
        const clear = Color(0x00000000);
        for (final MapEntry(key: name, value: fill) in fills.entries) {
          for (final MapEntry(key: page, value: bg) in pages.entries) {
            // Perceptual lightness (OKLab L): a fixed step in linear
            // luminance is far larger to the eye near black than near white.
            double lum(double x) => DsOklch.fromColor(
              DsColorUtils.flatten(
                DsBoxDecoration.lerp(
                  const DsBoxDecoration(color: clear),
                  DsBoxDecoration(color: fill),
                  x,
                )!.color!,
                bg,
              ),
            ).l;
            final ends = [lum(0), lum(1)]..sort();
            for (var i = 1; i < 20; i++) {
              final l = lum(i / 20);
              expect(
                l,
                // sRGB mixing between two hues of similar lightness is not
                // exactly monotonic (a deep red tint over the dark overlay
                // dips 0.01 for a moment); 0.015 is invisible. The old gray
                // flash dipped over 0.1.
                inInclusiveRange(ends[0] - .015, ends[1] + .015),
                reason: '$name on $page dips at ${i * 5}%',
              );
            }
          }
        }
      });
    }
  }

  for (final variant in DsBottomNavVariant.values) {
    testWidgets('bottom nav (${variant.name}): the selection never flashes '
        'while it moves', (tester) async {
      final theme = DsThemeData();
      var index = 0;
      late StateSetter set;
      await tester.pumpWidget(
        DsApp(
          theme: theme,
          home: Center(
            child: StatefulBuilder(
              builder: (context, s) {
                set = s;
                return DsBottomNav(
                  variant: variant,
                  items: const [
                    DsBottomNavItem(
                      value: 0,
                      icon: DsIcon(DsIcons.house),
                      label: Text('A'),
                    ),
                    DsBottomNavItem(
                      value: 1,
                      icon: DsIcon(DsIcons.user),
                      label: Text('B'),
                    ),
                  ],
                  value: index,
                  onChanged: (i) => set(() => index = i),
                );
              },
            ),
          ),
        ),
      );
      double lumOf(String label) {
        final box = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        final color =
            (box.decoration as DsBoxDecoration?)?.color ??
            const Color(0x00000000);
        return DsColorUtils.luminance(
          DsColorUtils.flatten(color, theme.colors.overlay),
        );
      }

      final idle = lumOf('B'), selected = lumOf('A');
      await tester.tap(find.text('B'));
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final b = lumOf('B');
        expect(
          b,
          inInclusiveRange(
            (idle < selected ? idle : selected) - 2e-3,
            (idle > selected ? idle : selected) + 2e-3,
          ),
          reason: 'frame $f',
        );
      }
    });
  }
}
