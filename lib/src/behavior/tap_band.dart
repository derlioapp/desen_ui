import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'min_tap_target.dart';

/// Takes taps within [size] around its child (on each axis, centered), and
/// within [outset] beyond each of its edges, without growing the layout,
/// unlike [DsMinTapTarget]: the box keeps its own size, and a tap in the
/// band lands at the child's center (or, with [followTap], at the nearest
/// point of the child). The band only reaches as far as the
/// parents' bounds do (in a field, up into the gap under the label; in a
/// row of taller controls, the row's height; in a row of tabs, into the
/// gaps between them).
class TapBand extends SingleChildRenderObjectWidget {
  /// Creates a tap band.
  const TapBand({
    super.key,
    required this.size,
    this.outset = EdgeInsets.zero,
    this.followTap = false,
    super.child,
  });

  /// The width and height of the band, in logical pixels.
  final double size;

  /// How far past each edge the band reaches besides [size], e.g. half the
  /// gap to a neighbor, so neighbors split the gap between them.
  final EdgeInsets outset;

  /// Whether a tap in the band lands at the nearest point of the box
  /// instead of its center: a tap above a row of segments reaches the
  /// segment under it, not the middle one.
  final bool followTap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTapBand(size, outset, followTap);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTapBand)
        ..band = size
        ..outset = outset
        ..followTap = followTap;
}

/// How far inside the edge a tap redirected to the nearest point lands:
/// half a pixel, so it is within the box and not on its open edge.
const _inside = .5;

class _RenderTapBand extends RenderProxyBox {
  _RenderTapBand(this.band, this.outset, this.followTap);

  double band;
  EdgeInsets outset;
  bool followTap;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final dx = math.max(0.0, (band - size.width) / 2);
    final dy = math.max(0.0, (band - size.height) / 2);
    final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!area.contains(position) &&
        !outset.inflateRect(Offset.zero & size).contains(position)) {
      return false;
    }
    // The band was never painted: answer as the box's own center, or at
    // its nearest point (just inside the edge).
    final target = followTap
        ? Offset(
            position.dx.clamp(_inside, math.max(_inside, size.width - _inside)),
            position.dy.clamp(
              _inside,
              math.max(_inside, size.height - _inside),
            ),
          )
        : size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(target),
      position: target,
      hitTest: (result, _) => super.hitTest(result, position: target),
    );
  }
}
