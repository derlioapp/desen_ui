import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import 'decoration.dart';
import 'shape.dart';

/// The box of a floating layer (menu, popover, dialog, toast, bars):
/// [decoration] around [child], with [backdropFilter] applied to what
/// shows through the fill when one is given.
///
/// Desen's layers are opaque, so by default there is nothing to filter.
/// A style that sets a translucent background and a `backdropFilter`
/// (e.g. `ImageFilter.blur`) turns the layer into frosted glass: the
/// outer shadows stay outside the box, the blur is clipped to its shape.
class DsSurface extends StatelessWidget {
  /// Paints [decoration] around [child], over a backdrop filtered by
  /// [backdropFilter].
  const DsSurface({
    super.key,
    required this.decoration,
    this.backdropFilter,
    this.width,
    this.constraints,
    this.padding,
    this.child,
  });

  /// Fill, corners and shadows.
  final DsBoxDecoration decoration;

  /// Applied to what lies behind the box; null filters nothing.
  final ImageFilter? backdropFilter;

  /// Fixed width of the box, as in `Container`.
  final double? width;

  /// Limits on the box's size, as in `Container`.
  final BoxConstraints? constraints;

  /// Space between the box and [child].
  final EdgeInsetsGeometry? padding;

  /// The layer's content.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final box = width == null
        ? constraints
        : constraints?.tighten(width: width) ??
              BoxConstraints.tightFor(width: width);
    final surface = _surface(content);
    return box == null
        ? surface
        : ConstrainedBox(constraints: box, child: surface);
  }

  Widget _surface(Widget? content) {
    final filter = backdropFilter;
    if (filter == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    // The blur must sit under the fill and inside the box, while outer
    // shadows are painted outside it: split the decoration around the clip.
    final shadows = decoration.shadows;
    return DecoratedBox(
      decoration: DsBoxDecoration(
        borderRadius: decoration.borderRadius,
        shadows: [
          for (final s in shadows)
            if (!s.inset) s,
        ],
      ),
      child: DsShapeClip(
        borderRadius: decoration.borderRadius,
        child: BackdropFilter(
          filter: filter,
          child: DecoratedBox(
            decoration: decoration.copyWith(
              shadows: [
                for (final s in shadows)
                  if (s.inset) s,
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
