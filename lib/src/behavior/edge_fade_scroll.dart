import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/sizes.dart';

/// A horizontal scroll view for a row of items that may not fit, such as
/// a toolbar or a row of tags: an edge that hides items fades out, so a
/// clipped row reads as scrollable. When everything fits, nothing fades
/// and nothing scrolls. `DsToolbar` and `DsChoiceChips` fade the same way.
///
/// It sizes to its child under an unbounded width (in a Row), and its
/// [padding] scrolls with the child, so focus rings that reach into the
/// padding are not clipped.
///
/// ```dart
/// DsEdgeFadeScrollView(
///   padding: const EdgeInsets.all(4),
///   child: Row(
///     spacing: 8,
///     children: [
///       for (final tag in tags)
///         DsChip(
///           label: Text(tag),
///           selected: chosen.contains(tag),
///           onChanged: (on) => toggle(tag, on),
///         ),
///     ],
///   ),
/// )
/// ```
class DsEdgeFadeScrollView extends StatelessWidget {
  /// Creates the scroll view.
  const DsEdgeFadeScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });

  /// The row of items.
  final Widget child;

  /// Space around [child], inside the scrolling area.
  final EdgeInsetsGeometry? padding;

  /// Controls the scroll position; one is created when null.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => DsEdgeFade(
    child: SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: child,
    ),
  );
}

/// Fades the edges of the horizontal scrollable directly inside [child]
/// (a scroll view, a single-line text editor) where they hide content, so
/// the cut reads as more to scroll rather than a sliced glyph. Nothing
/// fades while everything shows, or while [enabled] is false. In a
/// right-to-left scroll view the edges follow the layout.
///
/// Use it to fade a scrollable you already have, such as a horizontal
/// `ListView`; for a plain row of items, [DsEdgeFadeScrollView] builds the
/// scroll view too.
///
/// ```dart
/// DsEdgeFade(
///   child: ListView.builder(
///     scrollDirection: Axis.horizontal,
///     itemCount: albums.length,
///     itemBuilder: (context, i) => AlbumTile(albums[i]),
///   ),
/// )
/// ```
class DsEdgeFade extends StatefulWidget {
  /// Fades [child]'s edges.
  const DsEdgeFade({
    super.key,
    required this.child,
    this.width = defaultWidth,
    this.enabled = true,
  });

  /// Holds the horizontal scrollable.
  final Widget child;

  /// How far the fade reaches in from an edge that hides content.
  final double width;

  /// Whether the edges fade; false shows a plain cut.
  final bool enabled;

  /// The fade of a row of items.
  static const defaultWidth = DsSpace.s24;

  @override
  State<DsEdgeFade> createState() => _DsEdgeFadeState();
}

class _DsEdgeFadeState extends State<DsEdgeFade> {
  /// Keeps the child, and its scroll position, when the fade turns on or
  /// off.
  final _key = GlobalKey();

  /// Whether content is hidden past the left or the right edge.
  bool _left = false, _right = false;

  bool _onMetrics(ScrollMetrics m) {
    if (m.axis != Axis.horizontal) return false;
    // The pixels count from the left, or from the right in a scroll view
    // laid out right to left.
    final reversed = m.axisDirection == AxisDirection.left;
    final before = m.extentBefore > 0.5;
    final after = m.extentAfter > 0.5;
    final left = reversed ? after : before;
    final right = reversed ? before : after;
    if (left != _left || right != _right) {
      void apply() {
        if (!mounted) return;
        setState(() {
          _left = left;
          _right = right;
        });
      }

      // Metrics can be reported during layout; wait for the frame then.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      } else {
        apply();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final listened = NotificationListener<ScrollMetricsNotification>(
      key: _key,
      onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
        child: widget.child,
      ),
    );
    if (!widget.enabled || (!_left && !_right)) return listened;
    const opaque = Color(0xFF000000); // ds-raw: a mask, only alpha counts
    const clear = Color(0x00000000);
    // The mask covers only this box; a faded edge also clips there, so a
    // scroll view that paints past its box (to leave room for focus rings)
    // shows no sharp sliver outside the fade. Other edges stay open.
    return ClipRect(
      clipper: _FadedEdgeClipper(left: _left, right: _right),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final edge = rect.width <= 0 ? 0.0 : (widget.width / rect.width);
          return LinearGradient(
            colors: [
              _left ? clear : opaque,
              opaque,
              opaque,
              _right ? clear : opaque,
            ],
            stops: [0, edge.clamp(0, .5), 1 - edge.clamp(0, .5), 1],
          ).createShader(rect);
        },
        child: listened,
      ),
    );
  }
}

/// Clips exactly at the box's [left] or [right] edge when that edge
/// fades, and nowhere else.
class _FadedEdgeClipper extends CustomClipper<Rect> {
  const _FadedEdgeClipper({required this.left, required this.right});

  final bool left, right;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    left ? 0 : Rect.largest.left,
    Rect.largest.top,
    right ? size.width : Rect.largest.right,
    Rect.largest.bottom,
  );

  @override
  bool shouldReclip(_FadedEdgeClipper oldClipper) =>
      oldClipper.left != left || oldClipper.right != right;
}
