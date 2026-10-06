import 'package:flutter/widgets.dart';

/// Whether every box takes circular corners (see [DsShape]).
const _plainCorners = bool.fromEnvironment('DS_PLAIN_CORNERS');

/// The outline of a rounded box in Desen's corner geometry.
///
/// Corners are continuous (a rounded superellipse, as on Apple platforms):
/// the curve eases out of the straight edge instead of meeting it with a
/// sudden change in curvature. A fully round box (some corner reaches half
/// its shorter side: capsules, circles, the round end of a band) keeps
/// circular arcs instead, because a superellipse at that radius is not a
/// true capsule.
///
/// Every draw, clip and hit test of a rounded box goes through this class,
/// so fills, rings, shadows and clips of one box share one outline.
/// [inflate], [deflate] and [shift] keep the choice made for the original
/// box, so rings stay concentric with it.
///
/// Built with `--dart-define=DS_PLAIN_CORNERS=true`, every box takes
/// circular corners (a plain rounded rectangle). It is a switch for
/// measuring what continuous corners cost, not a look: compare frame times
/// of the same build with and without it.
@immutable
class DsShape {
  /// The shape of [rrect].
  DsShape(RRect rrect) : this._(rrect, _plainCorners || _fullyRound(rrect));

  /// The shape of [rect] with corners [radius], resolved for [direction].
  factory DsShape.fromRadius(
    Rect rect,
    BorderRadiusGeometry radius, [
    TextDirection? direction,
  ]) => DsShape(radius.resolve(direction).toRRect(rect));

  const DsShape._(this.rrect, this.circular);

  /// The box and its corner radii.
  final RRect rrect;

  /// Whether the corners are circular arcs rather than continuous curves.
  final bool circular;

  static bool _fullyRound(RRect r) {
    final half = (r.width < r.height ? r.width : r.height) / 2;
    if (half <= 0) return true;
    // A hair under half still counts, so rounding in a radius such as
    // `size / 2 - 1e-9` does not flip a capsule into a superellipse.
    final limit = half - 1e-6;
    bool round(Radius c) => (c.x < c.y ? c.x : c.y) >= limit;
    return round(r.tlRadius) ||
        round(r.trRadius) ||
        round(r.brRadius) ||
        round(r.blRadius);
  }

  /// The bounding box.
  Rect get outerRect => rrect.outerRect;

  /// Whether the box has no area.
  bool get isEmpty => rrect.width <= 0 || rrect.height <= 0;

  /// The shape grown by [delta] on every side, radii included.
  DsShape inflate(double delta) => DsShape._(rrect.inflate(delta), circular);

  /// The shape shrunk by [delta] on every side, radii included.
  DsShape deflate(double delta) => DsShape._(rrect.deflate(delta), circular);

  /// The shape moved by [offset].
  DsShape shift(Offset offset) => DsShape._(rrect.shift(offset), circular);

  RSuperellipse get _superellipse => RSuperellipse.fromLTRBAndCorners(
    rrect.left,
    rrect.top,
    rrect.right,
    rrect.bottom,
    topLeft: rrect.tlRadius,
    topRight: rrect.trRadius,
    bottomRight: rrect.brRadius,
    bottomLeft: rrect.blRadius,
  );

  bool get _square =>
      rrect.tlRadius == Radius.zero &&
      rrect.trRadius == Radius.zero &&
      rrect.brRadius == Radius.zero &&
      rrect.blRadius == Radius.zero;

  // Two ways to put continuous corners on the canvas. The engine's direct
  // superellipse draw and clip ([drawDirect], [clipDirect]) are far cheaper
  // to raster than a path, but trace a slightly different curve than
  // `Path.addRSuperellipse` ([draw], [clip], [addTo]). Pieces that must
  // meet exactly use one way: a ring built as an even-odd path goes with a
  // path fill.

  /// Whether [point] lies inside the shape.
  bool contains(Offset point) {
    if (isEmpty) return false;
    if (circular || _square) return rrect.contains(point);
    return toPath().contains(point);
  }

  /// Adds the outline to [path].
  void addTo(Path path) {
    if (circular || _square) {
      path.addRRect(rrect);
    } else {
      path.addRSuperellipse(_superellipse);
    }
  }

  /// The outline as a path.
  Path toPath() {
    final path = Path();
    addTo(path);
    return path;
  }

  /// Fills (or strokes) the shape on [canvas].
  void draw(Canvas canvas, Paint paint) {
    if (circular || _square) {
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawPath(toPath(), paint);
    }
  }

  /// Fills (or strokes) the shape with the engine's direct superellipse
  /// draw: much cheaper to raster than [draw], on a slightly different
  /// curve (see above).
  void drawDirect(Canvas canvas, Paint paint) {
    if (circular || _square) {
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRSuperellipse(_superellipse, paint);
    }
  }

  /// Clips [canvas] to the shape on the curve [drawDirect] draws.
  void clipDirect(Canvas canvas, {bool doAntiAlias = true}) {
    if (circular || _square) {
      canvas.clipRRect(rrect, doAntiAlias: doAntiAlias);
    } else {
      canvas.clipRSuperellipse(_superellipse, doAntiAlias: doAntiAlias);
    }
  }

  /// Clips [canvas] to the shape.
  void clip(Canvas canvas, {bool doAntiAlias = true}) {
    if (circular || _square) {
      canvas.clipRRect(rrect, doAntiAlias: doAntiAlias);
    } else {
      canvas.clipPath(toPath(), doAntiAlias: doAntiAlias);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DsShape && other.rrect == rrect && other.circular == circular;

  @override
  int get hashCode => Object.hash(rrect, circular);
}

/// Clips [child] to the outline a `DsBoxDecoration` with the same
/// [borderRadius] paints: continuous corners, or true half circles for a
/// fully round box. Use it instead of `ClipRRect`, whose circular corners
/// would not line up with the decoration's edge.
class DsShapeClip extends StatelessWidget {
  /// Clips [child] to its bounds with [borderRadius].
  const DsShapeClip({
    super.key,
    required this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });

  /// Corner radii.
  final BorderRadiusGeometry borderRadius;

  /// How to clip.
  final Clip clipBehavior;

  /// The clipped widget.
  final Widget? child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _ShapeClipper(borderRadius, Directionality.maybeOf(context)),
    clipBehavior: clipBehavior,
    child: child,
  );
}

class _ShapeClipper extends CustomClipper<Path> {
  const _ShapeClipper(this.radius, this.direction);

  final BorderRadiusGeometry radius;
  final TextDirection? direction;

  @override
  Path getClip(Size size) =>
      DsShape.fromRadius(Offset.zero & size, radius, direction).toPath();

  @override
  bool shouldReclip(_ShapeClipper old) =>
      old.radius != radius || old.direction != direction;
}
