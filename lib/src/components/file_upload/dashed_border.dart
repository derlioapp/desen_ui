import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

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
        .deflate(width / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (dash <= 0 || dash + gap <= 0) {
      outline.draw(canvas, paint);
      return;
    }
    canvas.drawPath(_dashes(outline, dash, gap), paint);
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color ||
      old.width != width ||
      old.dash != dash ||
      old.gap != gap ||
      old.radius != radius;
}

/// Dash paths already built, by outline and pattern. A hovered card or a
/// drop zone under a drag repaints every frame of its color change, on the
/// same outline, so the dashes are built once per size and shape.
final _cache = <(DsShape, double, double), Path>{};

/// The dashes along [outline]: a whole number of [dash] + [gap] periods,
/// stretched or squeezed a little so the pattern closes evenly.
Path _dashes(DsShape outline, double dash, double gap) {
  final key = (outline, dash, gap);
  final cached = _cache.remove(key);
  if (cached != null) return _cache[key] = cached;
  final period = dash + gap;
  final dashes = Path();
  for (final metric in outline.toPath().computeMetrics()) {
    final line = _Polyline.along(metric);
    if (line.length <= 0) continue;
    // A whole number of dash periods: the pattern closes evenly.
    final count = math.max(1, (line.length / period).round());
    final step = line.length / count;
    final on = step * dash / period;
    for (var i = 0; i < count; i++) {
      line.addSpan(dashes, i * step, i * step + on);
    }
  }
  if (_cache.length >= 16) _cache.remove(_cache.keys.first);
  return _cache[key] = dashes;
}

/// An outline flattened to a polyline, with the distance along it to each
/// point.
///
/// The engine's path measure does not run evenly along a continuous
/// (superellipse) corner: equal steps of its offset cover unequal
/// distances. Measuring along the flattened points instead makes every
/// length a true distance, so dashes and gaps come out even on the curve
/// too.
class _Polyline {
  _Polyline._(this._points, this._distances);

  /// Flattens [metric]. Points are taken closer together where the
  /// outline turns, until neighbors differ by a few degrees at most; a
  /// sharp corner is pinned down to a hair. Points on a straight run are
  /// dropped.
  factory _Polyline.along(PathMetric metric) {
    final length = metric.length;
    final samples = <Offset>[];
    Tangent at(double d) => metric.getTangentForOffset(d)!;

    void refine(double a, Tangent ta, double b, Tangent tb) {
      final turn = _angle(ta.vector, tb.vector);
      if (turn > _maxTurn && b - a > _minStep) {
        final m = (a + b) / 2;
        final tm = at(m);
        refine(a, ta, m, tm);
        refine(m, tm, b, tb);
      } else {
        samples.add(tb.position);
      }
    }

    final first = at(0);
    samples.add(first.position);
    final n = math.max(16, (length / _coarseStep).ceil());
    var prev = first;
    for (var i = 1; i <= n; i++) {
      final d = length * i / n;
      final t = at(d);
      refine(length * (i - 1) / n, prev, d, t);
      prev = t;
    }
    // A closed outline ends exactly where it starts.
    if (metric.isClosed) samples[samples.length - 1] = first.position;

    final points = <Offset>[samples.first];
    final distances = <double>[0];
    for (var i = 1; i < samples.length; i++) {
      final p = samples[i];
      final last = points.last;
      if (i < samples.length - 1 && points.length > 1) {
        // Drop a point that goes on in the same direction as the run so far.
        final next = samples[i + 1];
        if (_angle(p - last, next - p) < _straight) continue;
      }
      if (p == last) continue;
      distances.add(distances.last + (p - last).distance);
      points.add(p);
    }
    return _Polyline._(points, distances);
  }

  /// Longest step between points before they are refined.
  static const _coarseStep = 4.0;

  /// Most the direction may turn between neighboring points, in radians.
  static const _maxTurn = .05;

  /// Shortest step a sharp corner is refined to.
  static const _minStep = 1e-3;

  /// Turns smaller than this, in radians, count as straight.
  static const _straight = 1e-4;

  final List<Offset> _points;
  final List<double> _distances;

  /// The length of the outline.
  double get length => _distances.last;

  /// The angle between the directions of [a] and [b], in radians.
  static double _angle(Offset a, Offset b) =>
      math.atan2((a.dx * b.dy - a.dy * b.dx).abs(), a.dx * b.dx + a.dy * b.dy);

  /// The index of the last point at or before [distance].
  int _indexAt(double distance) {
    var lo = 0, hi = _distances.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_distances[mid] <= distance) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Offset _pointAt(int i, double distance) {
    final span = _distances[i + 1] - _distances[i];
    final t = span <= 0 ? 0.0 : (distance - _distances[i]) / span;
    return Offset.lerp(_points[i], _points[i + 1], t.clamp(0, 1))!;
  }

  /// Adds the stretch of the outline from [start] to [end] to [path].
  void addSpan(Path path, double start, double end) {
    var i = _indexAt(start);
    final s = _pointAt(i, start);
    path.moveTo(s.dx, s.dy);
    while (i + 1 < _points.length - 1 && _distances[i + 1] < end) {
      i++;
      path.lineTo(_points[i].dx, _points[i].dy);
    }
    final e = _pointAt(i, end);
    path.lineTo(e.dx, e.dy);
  }
}
