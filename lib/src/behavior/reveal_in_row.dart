/// Internal: scrolling an item of a faded row into view. Not exported from
/// the package.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'edge_fade_scroll.dart';

/// Scrolls the horizontal scroll view around [item] the least distance
/// that shows it whole and clear of a [DsEdgeFade]'s faded edges: to just
/// inside the start edge when it is cut or faded there, to just inside the
/// end edge when it is cut or faded there, not at all when it is in view.
/// Next to the row's own start or end nothing fades, so the first and last
/// items reach the edge. Call it after layout (a post-frame callback).
///
/// Returns false when [item] is not laid out yet, such as on a page built
/// under a covering one: call it again when the scroll view first reports
/// its metrics. Returns true otherwise, including when there is nothing
/// to scroll.
bool revealInRow(BuildContext? item, {required bool animate}) {
  final box = item?.findRenderObject();
  final scrollable = item == null ? null : Scrollable.maybeOf(item);
  if (box == null || !box.attached || scrollable == null) return true;
  if (box is! RenderBox || !box.hasSize) return false;
  final viewport = RenderAbstractViewport.maybeOf(box);
  if (viewport == null) return true;
  final position = scrollable.position;
  const fade = DsEdgeFade.defaultWidth;
  final atStart = viewport.getOffsetToReveal(box, 0).offset - fade;
  final atEnd = viewport.getOffsetToReveal(box, 1).offset + fade;
  final min = position.minScrollExtent, max = position.maxScrollExtent;
  final double target;
  if (position.pixels > atStart.clamp(min, max)) {
    target = atStart;
  } else if (position.pixels < atEnd.clamp(min, max)) {
    target = atEnd;
  } else {
    return true;
  }
  final to = target.clamp(min, max);
  final motion = DsTheme.motionOf(item!);
  if (!animate || motion.reduced) {
    position.jumpTo(to);
  } else {
    position.animateTo(
      to,
      duration: motion.toneDuration,
      curve: motion.toneCurve,
    );
  }
  return true;
}
