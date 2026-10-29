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

/// Grows its child's layout box to at least [size] on each axis, as
/// [DsMinTapTarget] does, for controls whose tap position matters: with
/// [followTap] a tap in the added margin lands at the nearest point of the
/// child (the segment under it, the caret's place in a field), not its
/// center.
class MinTapTarget extends SingleChildRenderObjectWidget {
  /// Creates a minimum tap target.
  const MinTapTarget({
    super.key,
    required this.size,
    this.followTap = false,
    super.child,
  });

  /// The smallest width and height of the target, in logical pixels.
  final double size;

  /// Whether a tap in the margin lands at the nearest point of the child
  /// instead of its center.
  final bool followTap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMinTapTarget(size, followTap: followTap);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as RenderMinTapTarget)
        ..minSize = size
        ..followTap = followTap;
}

/// The render object of [DsMinTapTarget] and [MinTapTarget].
class RenderMinTapTarget extends RenderShiftedBox {
  /// Creates the render object.
  RenderMinTapTarget(this._min, {this._followTap = false}) : super(null);

  double _min;
  set minSize(double value) {
    if (_min == value) return;
    _min = value;
    markNeedsLayout();
  }

  bool _followTap;
  set followTap(bool value) => _followTap = value;

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
    // The margin was never painted: answer as the child's own center, or
    // its nearest point (just inside the edge).
    final target = _followTap
        ? Offset(
            (position.dx - offset.dx).clamp(
              _inside,
              math.max(_inside, child.size.width - _inside),
            ),
            (position.dy - offset.dy).clamp(
              _inside,
              math.max(_inside, child.size.height - _inside),
            ),
          )
        : child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(target),
      position: target,
      hitTest: (result, _) => child.hitTest(result, position: target),
    );
  }
}

/// A semantics node of its own, merging its subtree as [MergeSemantics]
/// does, whose rect reaches the top and bottom of [target]'s box: a control
/// drawn shorter than its tap target is outlined by screen readers and
/// measured by tap target checks at the target's height.
class TargetHeightNode extends SingleChildRenderObjectWidget {
  /// Creates the node.
  const TargetHeightNode({super.key, required this.target, super.child});

  /// The tap target's box, usually a [MinTapTarget]'s.
  final GlobalKey target;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTargetHeightNode(target);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTargetHeightNode).target = target;
}

class _RenderTargetHeightNode extends RenderProxyBox {
  _RenderTargetHeightNode(this._target);

  GlobalKey _target;
  set target(GlobalKey value) {
    if (value == _target) return;
    _target = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  Rect get semanticBounds {
    final own = Offset.zero & size;
    final edges = targetEdges(this, _target);
    if (edges == null) return own;
    return Rect.fromLTRB(own.left, edges.top, own.right, edges.bottom);
  }
}

/// [target]'s box in [from]'s coordinates, or null when it is not laid out.
Rect? targetEdges(RenderObject from, GlobalKey target) {
  final box = target.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final to = from.getTransformTo(box);
  if (to.invert() == 0) return null;
  return MatrixUtils.transformRect(to, Offset.zero & box.size);
}

/// Marks a subtree whose tap target an ancestor already gives, such as a
/// multi-select's well around its bare text field, or a date field's frame
/// that a popup anchors to: a control below takes no target room of its
/// own, and its node reaches the height of [target], the ancestor's
/// [MinTapTarget], when given.
class TapTargetHost extends InheritedWidget {
  /// Marks [child].
  const TapTargetHost({super.key, this.target, required super.child});

  /// The ancestor's tap target.
  final GlobalKey? target;

  /// The nearest [TapTargetHost] above [context]. It never changes for an
  /// element, so there is no dependency.
  static TapTargetHost? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TapTargetHost>();

  @override
  bool updateShouldNotify(TapTargetHost oldWidget) => false;
}
