import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A horizontal scroll view for a row of items that may not fit, such as
/// a toolbar: an edge that hides items fades out, so a clipped row reads
/// as scrollable. When everything fits, nothing fades and nothing scrolls.
///
/// It sizes to its child under an unbounded width (in a Row), and its
/// [padding] scrolls with the child, so focus rings that reach into the
/// padding are not clipped.
class EdgeFadeScrollView extends StatefulWidget {
  /// Creates the scroll view.
  const EdgeFadeScrollView({
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

  /// How far the fade reaches in from an edge that hides items.
  static const fadeWidth = 24.0;

  @override
  State<EdgeFadeScrollView> createState() => _EdgeFadeScrollViewState();
}

class _EdgeFadeScrollViewState extends State<EdgeFadeScrollView> {
  /// Keeps the scroll view, and its position, when the fade turns on or
  /// off.
  final _key = GlobalKey();

  /// Whether items are hidden past the start or the end.
  bool _before = false, _after = false;

  bool _onMetrics(ScrollMetrics m) {
    // Past the start edge in reading order: the right one in RTL, where
    // the pixels count from the right.
    final before = m.extentBefore > 0.5;
    final after = m.extentAfter > 0.5;
    if (before != _before || after != _after) {
      void apply() {
        if (!mounted) return;
        setState(() {
          _before = before;
          _after = after;
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
    final scroller = NotificationListener<ScrollMetricsNotification>(
      key: _key,
      onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
        child: SingleChildScrollView(
          controller: widget.controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
    if (!_before && !_after) return scroller;
    const opaque = Color(0xFF000000); // ds-raw: a mask, only alpha counts
    const clear = Color(0x00000000);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final edge = rect.width <= 0
            ? 0.0
            : (EdgeFadeScrollView.fadeWidth / rect.width);
        return LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            _before ? clear : opaque,
            opaque,
            opaque,
            _after ? clear : opaque,
          ],
          stops: [0, edge.clamp(0, .5), 1 - edge.clamp(0, .5), 1],
        ).createShader(rect, textDirection: Directionality.of(context));
      },
      child: scroller,
    );
  }
}
