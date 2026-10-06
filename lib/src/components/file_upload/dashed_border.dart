import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../painting/shape.dart';

/// A dashed outline drawn inside its child's box, e.g. a file drop zone's
/// edge.
///
/// The dashes are spread evenly over the whole outline, so the pattern
/// closes without a long or a cut dash where it starts, also around
/// rounded corners. The stroke sits inside the box, like an inner border.
/// It paints over [child] and takes no pointers.
class DsDashedBorder extends StatelessWidget {
  /// Creates a dashed outline around [child].
  const DsDashedBorder({
    super.key,
    required this.color,
    required this.width,
    required this.dashLength,
    required this.dashGap,
    this.borderRadius = BorderRadius.zero,
    this.child,
  });

  /// Stroke color.
  final Color color;

  /// Stroke width.
  final double width;

  /// Length of one dash, before it is evened out over the outline.
  final double dashLength;

  /// Space between dashes, before it is evened out over the outline.
  final double dashGap;

  /// Corners of the outline.
  final BorderRadiusGeometry borderRadius;

  /// What the outline goes around.
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedPainter(
      color: color,
      width: width,
      dash: dashLength,
      gap: dashGap,
      radius: borderRadius.resolve(Directionality.maybeOf(context)),
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('dashLength', dashLength))
      ..add(DoubleProperty('dashGap', dashGap))
      ..add(DiagnosticsProperty('borderRadius', borderRadius));
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({
    required this.color,
    required this.width,
    required this.dash,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double width, dash, gap;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || color.a == 0 || size.isEmpty) return;
    // The stroke's center line, half a stroke inside the box, with the
    // corners concentric to the box's.
    final outline = DsShape(radius.toRRect(Offset.zero & size))
        .deflate(width / 2)
        .toPath();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final period = dash + gap;
    if (dash <= 0 || period <= 0) {
      canvas.drawPath(outline, paint);
      return;
    }
    for (final metric in outline.computeMetrics()) {
      // A whole number of dash periods: the pattern closes evenly.
      final count = math.max(1, (metric.length / period).round());
      final step = metric.length / count;
      final on = step * dash / period;
      final dashes = Path();
      for (var i = 0; i < count; i++) {
        dashes.addPath(
          metric.extractPath(i * step, i * step + on),
          Offset.zero,
        );
      }
      canvas.drawPath(dashes, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color ||
      old.width != width ||
      old.dash != dash ||
      old.gap != gap ||
      old.radius != radius;
}
