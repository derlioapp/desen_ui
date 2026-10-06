import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../foundation/color_utils.dart';
import 'shadow.dart';
import 'shape.dart';

/// A rounded box with a fill and CSS-like outer and inset shadows.
///
/// Corners are continuous, like Apple's: a rounded superellipse whose
/// curve eases out of the straight edges. A fully round box (a capsule or
/// a circle) keeps true circular ends. The fill, every ring and shadow,
/// and hit testing follow the same outline, so edges stay concentric with
/// the fill.
///
/// Paint order matches CSS: outer shadows, then the fill, then inset shadows.
/// Within each group the first shadow in [shadows] is drawn on top.
///
/// Outer shadows never show through a translucent fill. They are clipped to
/// the outside of the box, as in CSS.
///
/// The box is snapped to whole device pixels before painting, so rings
/// and [DsShadow.hairline] edges stay crisp at any layout position.
@immutable
class DsBoxDecoration extends Decoration {
  /// Creates a decoration.
  const DsBoxDecoration({
    this.color,
    this.shadows = const [],
    this.borderRadius = BorderRadius.zero,
  });

  /// Fill color. Null paints no fill.
  final Color? color;

  /// Outer and inset shadows, topmost first.
  final List<DsShadow> shadows;

  /// Corner radii.
  final BorderRadiusGeometry borderRadius;

  /// Returns a copy with the given fields replaced.
  DsBoxDecoration copyWith({
    Color? color,
    List<DsShadow>? shadows,
    BorderRadiusGeometry? borderRadius,
  }) => DsBoxDecoration(
    color: color ?? this.color,
    shadows: shadows ?? this.shadows,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  bool get isComplex => shadows.isNotEmpty;

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      DsShape.fromRadius(
        Offset.zero & size,
        borderRadius,
        textDirection,
      ).contains(position);

  @override
  DsBoxDecoration? lerpFrom(Decoration? a, double t) {
    if (a is DsBoxDecoration?) return DsBoxDecoration.lerp(a, this, t);
    return super.lerpFrom(a, t) as DsBoxDecoration?;
  }

  @override
  DsBoxDecoration? lerpTo(Decoration? b, double t) {
    if (b is DsBoxDecoration?) return DsBoxDecoration.lerp(this, b, t);
    return super.lerpTo(b, t) as DsBoxDecoration?;
  }

  /// Linearly interpolates between two decorations.
  static DsBoxDecoration? lerp(
    DsBoxDecoration? a,
    DsBoxDecoration? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    a ??= DsBoxDecoration(borderRadius: b!.borderRadius);
    b ??= DsBoxDecoration(borderRadius: a.borderRadius);
    return DsBoxDecoration(
      color: DsColorUtils.lerp(a.color, b.color, t),
      shadows: DsShadow.lerpList(a.shadows, b.shadows, t),
      borderRadius: BorderRadiusGeometry.lerp(
        a.borderRadius,
        b.borderRadius,
        t,
      )!,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DsBoxPainter(this, onChanged);

  @override
  bool operator ==(Object other) =>
      other is DsBoxDecoration &&
      other.color == color &&
      other.borderRadius == borderRadius &&
      listEquals(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(color, borderRadius, Object.hashAll(shadows));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DiagnosticsProperty('borderRadius', borderRadius))
      ..add(
        IterableProperty('shadows', shadows, defaultValue: const <DsShadow>[]),
      );
  }
}

class _DsBoxPainter extends BoxPainter {
  _DsBoxPainter(this._d, super.onChanged);

  final DsBoxDecoration _d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    // Snap the box to whole device pixels so hairline rings and edges stay
    // crisp when layout lands on a fractional position.
    final dpr = configuration.devicePixelRatio ?? 1.0; // ds-raw: identity
    double snap(double v) => (v * dpr).roundToDouble() / dpr;
    final raw = offset & size;
    final rect = Rect.fromLTRB(
      snap(raw.left),
      snap(raw.top),
      snap(raw.right),
      snap(raw.bottom),
    );
    final shape = DsShape.fromRadius(
      rect,
      _d.borderRadius,
      configuration.textDirection,
    );
    final shadows = [for (final s in _d.shadows.reversed) s.resolve(dpr)];
    final fill = _d.color;
    final opaqueFill = fill != null && fill.a >= 1;
    // A ring flush with an opaque fill is drawn as a larger shape under it.
    bool underFill(DsShadow s) => opaqueFill && s.gap == 0;
    // Outer shadows that must be cut out around the box (a ring with a gap,
    // or anything under a fill it would show through) go through paths;
    // the fill then takes the path curve too, so the two meet exactly.
    // Otherwise every piece takes the engine's direct superellipse, which
    // rasters far faster.
    final direct = !shadows.any(
      (s) =>
          !s.inset &&
          s.color.a > 0 &&
          (s.isOutline ? !underFill(s) : !opaqueFill),
    );

    // Outer shadows, bottom-most first. With an opaque fill on top there is
    // no need to clip; skipping the clip also avoids an anti-aliased seam
    // between a 1px ring and the fill.
    for (final s in shadows) {
      if (s.inset || s.color.a == 0) continue;
      if (s.isOutline) {
        final paint = Paint()..color = s.color;
        if (underFill(s)) {
          shape.inflate(s.spread).drawDirect(canvas, paint);
          continue;
        }
        // A ring with a transparent gap: fill between two inflated shapes.
        final path = Path()..fillType = PathFillType.evenOdd;
        shape.inflate(s.gap + s.spread).addTo(path);
        shape.inflate(s.gap).addTo(path);
        canvas.drawPath(path, paint);
        continue;
      }
      final paint = Paint()..color = s.color;
      if (s.blur > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma);
      }
      final shadow = shape.shift(s.offset).inflate(s.spread);
      // A blur hides the corner's exact curve; a rounded rectangle blurs on
      // the engine's fast path.
      void drawShadow() {
        if (s.blur > 0) {
          canvas.drawRRect(shadow.rrect, paint);
        } else if (direct) {
          shadow.drawDirect(canvas, paint);
        } else {
          shadow.draw(canvas, paint);
        }
      }

      if (opaqueFill) {
        drawShadow();
      } else {
        final outside = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(shadow.outerRect.inflate(s.blur * 2 + 1));
        shape.addTo(outside);
        canvas
          ..save()
          ..clipPath(outside);
        drawShadow();
        canvas.restore();
      }
    }

    if (fill != null && fill.a > 0) {
      final paint = Paint()..color = fill;
      direct ? shape.drawDirect(canvas, paint) : shape.draw(canvas, paint);
    }

    // Inset shadows: clip to the box and paint everything outside the
    // shifted, shrunk inner shape.
    var clipped = false;
    for (final s in shadows) {
      if (!s.inset || s.color.a == 0) continue;
      if (!clipped) {
        canvas.save();
        direct ? shape.clipDirect(canvas) : shape.clip(canvas);
        clipped = true;
      }
      final paint = Paint()..color = s.color;
      if (s.blur > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma);
      }
      final inner = shape.shift(s.offset).deflate(s.spread);
      final outer = rect.inflate(
        s.blur * 2 + s.offset.distance + s.spread.abs() + 1,
      );
      if (inner.isEmpty) {
        canvas.drawRect(outer, paint);
      } else {
        final path = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer);
        inner.addTo(path);
        canvas.drawPath(path, paint);
      }
    }
    if (clipped) canvas.restore();
  }
}
