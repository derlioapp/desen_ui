import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../theme/sizes.dart';

/// The side of its anchor a floating layer prefers.
enum DsSide {
  /// Above the anchor: tooltips.
  top,

  /// Below the anchor: menus, popovers, selects.
  bottom,

  /// Before the anchor in reading direction (left in LTR).
  start,

  /// After the anchor in reading direction (right in LTR).
  end;

  bool get _vertical => this == top || this == bottom;
}

/// How a floating layer lines up with its anchor along the other axis.
enum DsAlign {
  /// Start edges flush (left in LTR for top and bottom).
  start,

  /// Centers agree.
  center,

  /// End edges flush.
  end,
}

/// Where a floating layer goes: the side it ended up on (after flipping)
/// and its top-left corner in the overlay.
@immutable
class DsPlacement {
  /// Creates a placement.
  const DsPlacement(this.side, this.offset, this.maxExtent);

  /// The side, after flipping. Never [DsSide.start] or [DsSide.end] in the
  /// result for vertical sides; for horizontal ones it is the resolved side.
  final DsSide side;

  /// Top-left corner of the layer in overlay coordinates.
  final Offset offset;

  /// The room on [side] along the main axis: how tall (top, bottom) or wide
  /// (start, end) the layer may be without leaving the viewport.
  final double maxExtent;

  @override
  bool operator ==(Object other) =>
      other is DsPlacement &&
      other.side == side &&
      other.offset == offset &&
      other.maxExtent == maxExtent;

  @override
  int get hashCode => Object.hash(side, offset, maxExtent);

  @override
  String toString() => 'DsPlacement($side, $offset, max $maxExtent)';
}

/// Places a layer of [size] next to [anchor] inside [viewport], like
/// Floating UI's flip and shift.
///
/// - The preferred [side] wins while it fits, or while it has at least as
///   much room as the opposite side; otherwise the layer flips.
/// - Along the other axis the layer lines up per [align], then shifts to
///   stay inside the viewport minus [margin].
/// - [gap] separates the layer from the anchor.
///
/// [direction] resolves [DsSide.start], [DsSide.end] and [DsAlign].
DsPlacement dsPlace({
  required Rect anchor,
  required Size size,
  required Size viewport,
  required DsSide side,
  DsAlign align = DsAlign.center,
  double gap = DsSpace.s6,
  EdgeInsets margin = const EdgeInsets.all(DsSpace.s8),
  TextDirection direction = TextDirection.ltr,
}) {
  final rtl = direction == TextDirection.rtl;
  // Resolve start/end to physical sides; left/right are encoded as start
  // and end in LTR terms below.
  final vertical = side._vertical;
  final double before, after; // room before/after the anchor on the main axis
  if (vertical) {
    before = anchor.top - margin.top - gap;
    after = viewport.height - margin.bottom - anchor.bottom - gap;
  } else {
    before = anchor.left - margin.left - gap;
    after = viewport.width - margin.right - anchor.right - gap;
  }
  final extent = vertical ? size.height : size.width;
  // Does the layer prefer the "after" side (below / right)?
  final prefersAfter = switch (side) {
    DsSide.bottom => true,
    DsSide.top => false,
    DsSide.start => rtl,
    DsSide.end => !rtl,
  };
  final wanted = prefersAfter ? after : before;
  final other = prefersAfter ? before : after;
  final keep = wanted >= extent || wanted >= other;
  final useAfter = keep ? prefersAfter : !prefersAfter;
  final room = math.max(0.0, useAfter ? after : before);

  final DsSide resolved = vertical
      ? (useAfter ? DsSide.bottom : DsSide.top)
      : (useAfter != rtl ? DsSide.end : DsSide.start);

  double clamp(double value, double min, double max, double length) =>
      math.max(min, math.min(value, math.max(min, max - length)));

  if (vertical) {
    final top = useAfter ? anchor.bottom + gap : anchor.top - gap - size.height;
    final startEdge = rtl ? anchor.right - size.width : anchor.left;
    final endEdge = rtl ? anchor.left : anchor.right - size.width;
    final left = switch (align) {
      DsAlign.start => startEdge,
      DsAlign.center => anchor.center.dx - size.width / 2,
      DsAlign.end => endEdge,
    };
    return DsPlacement(
      resolved,
      Offset(
        clamp(left, margin.left, viewport.width - margin.right, size.width),
        clamp(top, margin.top, viewport.height - margin.bottom, size.height),
      ),
      room,
    );
  }
  final left = useAfter ? anchor.right + gap : anchor.left - gap - size.width;
  final top = switch (align) {
    DsAlign.start => anchor.top,
    DsAlign.center => anchor.center.dy - size.height / 2,
    DsAlign.end => anchor.bottom - size.height,
  };
  return DsPlacement(
    resolved,
    Offset(
      clamp(left, margin.left, viewport.width - margin.right, size.width),
      clamp(top, margin.top, viewport.height - margin.bottom, size.height),
    ),
    room,
  );
}
