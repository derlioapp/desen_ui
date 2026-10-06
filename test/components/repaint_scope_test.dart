import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Counts its own paints; never asks to repaint by itself.
class Counter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(Counter old) => false;
}

/// Denetim-2 eng P6: always-running loading animations repaint only
/// themselves, not their surroundings (a sibling used to repaint every
/// frame next to the indeterminate bar and the shimmer).
void main() {
  for (final (name, build) in <(String, Widget Function(Counter inside))>[
    ('DsProgressBar (indeterminate)', (_) => const DsProgressBar()),
    ('DsProgressRing (indeterminate)', (_) => const DsProgressRing()),
    (
      'DsShimmer',
      (inside) => DsShimmer(
        child: Column(
          children: [
            const DsSkeleton(),
            // A stand-in for the skeleton shapes under the sweep.
            CustomPaint(size: const Size(200, 20), painter: inside),
          ],
        ),
      ),
    ),
  ]) {
    testWidgets('$name repaints only itself', (tester) async {
      final sibling = Counter(), inside = Counter();
      await tester.pumpWidget(
        host(
          theme: DsThemeData(),
          RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(size: const Size(200, 20), painter: sibling),
                SizedBox(width: 200, child: build(inside)),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      sibling.paints = 0;
      inside.paints = 0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.hasRunningAnimations, isTrue, reason: 'still animating');
      expect(sibling.paints, 0);
      expect(inside.paints, 0);
    });
  }
}
