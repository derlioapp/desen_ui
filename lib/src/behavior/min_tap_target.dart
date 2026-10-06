import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Grows its child's layout box to at least [size] on each axis, keeping the
/// child centered and its visuals unchanged (WCAG 2.5.8).
///
/// A tap inside the child lands where the pointer actually is, so nested
/// hit targets keep working. A tap in the added margin is redirected to the
/// child's center, which is what makes a small control answer across the
/// whole target.
///
/// [DsPressable] applies it to every pressable; use it directly for custom
/// controls that do not go through [DsPressable].
class DsMinTapTarget extends SingleChildRenderObjectWidget {
  /// Creates a minimum tap target.
  const DsMinTapTarget({super.key, required this.size, super.child});

  /// The smallest width and height of the target, in logical pixels.
  final double size;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTapTarget(size);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderMinTapTarget).minSize = size;
}

class _RenderMinTapTarget extends RenderShiftedBox {
  _RenderMinTapTarget(this._min) : super(null);

  double _min;
  set minSize(double value) {
    if (_min == value) return;
    _min = value;
    markNeedsLayout();
  }

  Size _grow(Size child, BoxConstraints c) => c.constrain(
    Size(
      math.max(child.width, math.min(_min, c.maxWidth)),
      math.max(child.height, math.min(_min, c.maxHeight)),
    ),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(super.computeMinIntrinsicWidth(height), _min);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(super.computeMaxIntrinsicWidth(height), _min);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(width), _min);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(width), _min);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _grow(child.getDryLayout(constraints), constraints);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    // Tight constraints pass through (a full-width button stays full width).
    child.layout(constraints, parentUsesSize: true);
    size = _grow(child.size, constraints);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    if ((offset & child.size).contains(position)) {
      return result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
    }
    // The margin was never painted: answer as the child's own center.
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, _) => child.hitTest(result, position: center),
    );
  }
}
