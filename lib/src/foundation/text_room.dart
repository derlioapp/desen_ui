/// Internal: room around a control's label at large text sizes. Not
/// exported from the package.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// [padding] with vertical room added so a control [height] tall keeps its
/// label clear of its edges once large text makes the label taller than
/// the control: as much room as the label has at the regular text size,
/// at most [max] on each side. At the regular size the label and that
/// room still fit in [height], so nothing moves; with large text the
/// control grows with its label, as a text field does. A [padding] that
/// already has vertical room is left as it is.
EdgeInsetsGeometry dsWithTextRoom(
  EdgeInsetsGeometry? padding,
  double height,
  TextStyle? style, {
  double max = 8,
}) {
  final base = padding ?? EdgeInsets.zero;
  if (base.vertical > 0) return base;
  // An upper estimate of one line at the regular size, so the room never
  // makes the control taller there.
  final line = (style?.fontSize ?? kDefaultFontSize) * 1.3;
  final room = math.min(max, ((height - line) / 2).floorToDouble());
  if (room <= 0) return base;
  return base.add(EdgeInsets.symmetric(vertical: room));
}
