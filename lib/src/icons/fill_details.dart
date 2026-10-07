import 'package:flutter/painting.dart';

/// For each of [shapes], whether a filled icon fills it: only shapes that
/// enclose an area. An open stroke (a chart's axes, an undo arrow) stays a
/// stroke; filled, its ends would join into a wedge or a disc.
List<bool> dsFillable(List<Path> shapes) => [
  for (final shape in shapes) dsIsClosed(shape),
];

/// For each of [shapes], whether it is a detail: every point along it lies
/// inside the fill of another shape that is filled. A filled icon cuts
/// details out of the fill (the mark in an alert circle, an envelope's
/// flap) rather than inking them over it, where they would vanish.
List<bool> dsFillDetails(List<Path> shapes) {
  final fillable = dsFillable(shapes);
  return [
    for (final (i, shape) in shapes.indexed)
      () {
        final points = dsSamplePoints(shape);
        if (points.isEmpty) return false;
        for (final (j, other) in shapes.indexed) {
          if (j != i && fillable[j] && points.every(other.contains)) {
            return true;
          }
        }
        return false;
      }(),
  ];
}

/// Whether [shape] encloses an area: every part of it closes, or ends where
/// it starts (a circle drawn as two arcs).
bool dsIsClosed(Path shape) {
  final metrics = shape.computeMetrics().toList();
  return metrics.isNotEmpty &&
      metrics.every(
        (m) =>
            m.isClosed ||
            (m.getTangentForOffset(0)!.position -
                        m.getTangentForOffset(m.length)!.position)
                    .distance <
                .05,
      );
}

/// Points every half unit along [shape], leaving out the round caps at the
/// ends; a dot gives its middle.
List<Offset> dsSamplePoints(Path shape) => [
  for (final m in shape.computeMetrics())
    if (m.length <= 1)
      m.getTangentForOffset(m.length / 2)!.position
    else
      for (var at = .5; at < m.length - .5; at += .5)
        m.getTangentForOffset(at)!.position,
];
