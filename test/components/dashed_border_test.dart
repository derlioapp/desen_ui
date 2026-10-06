import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A dashed outline (an empty card slot, a file drop zone) spreads its
/// dashes evenly over the whole outline, corners included: every dash is
/// the same length and every gap the same, the gap where the pattern
/// closes too, so there is no cut dash and no long or short gap at the
/// seam. The dashes are read from what the painter draws.
void main() {
  /// The painted dashes, in drawing order (along the outline), with the
  /// gap after each one: the straight distance from its end to the next
  /// dash's start, the last one closing back to the first.
  ({List<double> dashes, List<double> gaps, DsDashedBorder border}) painted(
    WidgetTester tester,
  ) {
    final border = tester.widget<DsDashedBorder>(find.byType(DsDashedBorder));
    final paint = find
        .descendant(
          of: find.byType(DsDashedBorder),
          matching: find.byType(CustomPaint),
        )
        .first;
    final canvas = TestRecordingCanvas();
    tester
        .widget<CustomPaint>(paint)
        .foregroundPainter!
        .paint(canvas, tester.getSize(paint));
    final metrics = [
      for (final call in canvas.invocations)
        if (call.invocation.memberName == #drawPath)
          ...(call.invocation.positionalArguments.first as Path)
              .computeMetrics(),
    ];
    Offset at(PathMetric m, double d) => m.getTangentForOffset(d)!.position;
    final n = metrics.length;
    return (
      dashes: [for (final m in metrics) m.length],
      gaps: [
        for (var i = 0; i < n; i++)
          (at(metrics[(i + 1) % n], 0) - at(metrics[i], metrics[i].length))
              .distance,
      ],
      border: border,
    );
  }

  double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  /// Checks every dash and gap against the mean within [tolerance] (a
  /// fraction of it), and that the pattern keeps its nominal rhythm.
  void expectEven(WidgetTester tester, {required double tolerance}) {
    final (:dashes, :gaps, :border) = painted(tester);
    expect(dashes.length, greaterThan(20));
    final dash = mean(dashes), gap = mean(gaps);
    for (final d in dashes) {
      expect(d, closeTo(dash, dash * tolerance), reason: 'dashes $dashes');
    }
    for (final g in gaps) {
      expect(g, closeTo(gap, gap * tolerance), reason: 'gaps $gaps');
    }
    // Evening out stretches or squeezes the pattern only a little: the
    // dash keeps its share of the period, the period stays near nominal.
    final period = border.dashLength + border.dashGap;
    expect(dash / (dash + gap), closeTo(border.dashLength / period, .01));
    expect(dash + gap, closeTo(period, period * .1));
  }

  testWidgets('on a square box every dash and gap is the same, the seam '
      'included', (tester) async {
    // 237×113 is no whole number of 6 + 4 periods: the pattern must stretch
    // to close evenly.
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 237,
          height: 113,
          child: DsDashedBorder(
            color: Color(0xFF000000),
            width: 1.5,
            dashLength: 6,
            dashGap: 4,
          ),
        ),
      ),
    );
    expectEven(tester, tolerance: .001);
  });

  // Continuous (superellipse) corners. Dashes are measured along the
  // outline, so every dash is the same length; a gap on a corner is read
  // here as a straight line across the curve, a little shorter than its
  // length along it (about 0.5% on these corners). Dashes laid out by the
  // engine's path measure, which runs unevenly along this curve, vary by up
  // to about 7% and gaps by 11%; a cut dash, or a seam gap that takes the
  // rounding remainder, is off by far more.
  const continuousCorners = .01;

  testWidgets('a dashed card spreads its dashes evenly around the corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 241,
          height: 113,
          child: DsCard(dashed: true, child: Text('Empty')),
        ),
        theme: DsThemeData(),
      ),
    );
    expectEven(tester, tolerance: continuousCorners);
  });

  testWidgets('a file drop zone spreads its dashes evenly around the corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(width: 333, child: DsFileUpload(onBrowse: () {})),
        theme: DsThemeData(),
      ),
    );
    expectEven(tester, tolerance: continuousCorners);
  });

  testWidgets('a repaint in a new color, as on hover, reuses the dashes '
      'built for the same outline', (tester) async {
    Future<Path> dashesIn(Color color, {double width = 241}) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: width,
            height: 113,
            child: DsDashedBorder(
              color: color,
              width: 1.5,
              dashLength: 6,
              dashGap: 4,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
      final paint = find.descendant(
        of: find.byType(DsDashedBorder),
        matching: find.byType(CustomPaint),
      );
      final canvas = TestRecordingCanvas();
      tester
          .widget<CustomPaint>(paint)
          .foregroundPainter!
          .paint(canvas, tester.getSize(paint));
      return canvas.invocations
              .singleWhere((call) => call.invocation.memberName == #drawPath)
              .invocation
              .positionalArguments
              .first
          as Path;
    }

    final rest = await dashesIn(const Color(0xFF000000));
    final hovered = await dashesIn(const Color(0xFF3366FF));
    expect(identical(rest, hovered), isTrue);
    final wider = await dashesIn(const Color(0xFF3366FF), width: 260);
    expect(identical(rest, wider), isFalse);
  });
}
