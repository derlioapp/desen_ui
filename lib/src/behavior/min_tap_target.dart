import 'package:flutter/widgets.dart';

import 'tap_band.dart';

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
      RenderMinTapTarget(size);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as RenderMinTapTarget).minSize = size;
}
