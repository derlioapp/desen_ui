import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out a full-width [child] (one that stretches or expands across the
/// width it gets) under an unbounded width too: there the child gets the
/// width of its content, its max intrinsic width, instead of throwing.
///
/// Under a bounded width it is transparent: the child gets the same
/// constraints, and its intrinsic and dry sizes pass through, so it works
/// inside `IntrinsicHeight` and similar parents, where a `LayoutBuilder`
/// would not.
class ShrinkWrapUnboundedWidth extends SingleChildRenderObjectWidget {
  /// Wraps [child].
  const ShrinkWrapUnboundedWidth({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShrinkWrapUnboundedWidth();
}

class _RenderShrinkWrapUnboundedWidth extends RenderProxyBox {
  BoxConstraints _childConstraints(BoxConstraints c) {
    if (c.hasBoundedWidth || child == null) return c;
    final height = c.hasBoundedHeight ? c.maxHeight : double.infinity;
    final width = child!.getMaxIntrinsicWidth(height);
    return c.tighten(width: width.clamp(c.minWidth, c.maxWidth));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (child == null) return constraints.smallest;
    return child!.getDryLayout(_childConstraints(constraints));
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_childConstraints(constraints), baseline);

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child!.layout(_childConstraints(constraints), parentUsesSize: true);
    size = child!.size;
  }
}
