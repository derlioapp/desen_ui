import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'min_tap_target.dart';

/// Takes taps within [size] around its child (on each axis, centered)
/// without growing the layout, unlike [DsMinTapTarget]: the box keeps its
/// own size, and a tap in the band lands at the child's center. The band
/// only reaches as far as the parents' bounds do (in a field, up into the
/// gap under the label; in a row of taller controls, the row's height).
class TapBand extends SingleChildRenderObjectWidget {
  /// Creates a tap band.
  const TapBand({super.key, required this.size, super.child});

  /// The width and height of the band, in logical pixels.
  final double size;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTapBand(size);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTapBand).band = size;
}

class _RenderTapBand extends RenderProxyBox {
  _RenderTapBand(this.band);

  double band;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final dx = math.max(0.0, (band - size.width) / 2);
    final dy = math.max(0.0, (band - size.height) / 2);
    final area = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!area.contains(position)) return false;
    // The band was never painted: answer as the box's own center.
    final center = size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, _) => super.hitTest(result, position: center),
    );
  }
}
