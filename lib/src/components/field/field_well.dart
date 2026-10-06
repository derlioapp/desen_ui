/// Internal: the well every field draws. Not exported from the package;
/// `DsFieldSurface` is its public face.
library;

import 'package:flutter/widgets.dart';

import '../../painting/decoration.dart';
import '../../painting/shadow.dart';

/// The well of a text field, select or field-like control: a [background]
/// fill, an inner edge of [borderWidth] in [borderColor] (drawn inside the
/// box, so a thicker focus or error edge moves nothing), any [shadows]
/// under it, and [focusShadows] on top while [focused]. At least
/// [minHeight] tall, with [padding] around [child].
///
/// A [key] reaches the well's outermost render box, so a field can measure
/// the well through it.
class FieldWell extends StatelessWidget {
  /// Creates a well.
  const FieldWell({
    super.key,
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.minHeight,
    required this.duration,
    required this.curve,
    required this.child,
    this.padding,
    this.shadows,
    this.focusShadows,
    this.focused = false,
  });

  /// The fill; null for none.
  final Color? background;

  /// The inner edge; null or transparent for none.
  final Color? borderColor;

  /// Width of the inner edge.
  final double borderWidth;

  /// Corners of the well.
  final BorderRadiusGeometry borderRadius;

  /// Smallest height; content can make the well taller.
  final double minHeight;

  /// How long a change of fill, edge or ring takes.
  final Duration duration;

  /// Easing of those changes.
  final Curve curve;

  /// Space between the edge and [child].
  final EdgeInsetsGeometry? padding;

  /// Elevation drawn under the edge.
  final List<DsShadow>? shadows;

  /// Drawn on top of the edge while [focused].
  final List<DsShadow>? focusShadows;

  /// Whether to draw [focusShadows].
  final bool focused;

  /// The well's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? const Color(0x00000000);
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: DsBoxDecoration(
        color: background,
        borderRadius: borderRadius,
        shadows: [
          ...?shadows,
          if (border.a > 0) DsShadow.innerRing(border, width: borderWidth),
          if (focused) ...?focusShadows,
        ],
      ),
      child: child,
    );
  }
}
