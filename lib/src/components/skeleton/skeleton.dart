import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../painting/decoration.dart';
import '../../painting/shape.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'skeleton_style.dart';

/// A placeholder shape that mimics content while it loads: channel-toned,
/// no edge. Wrap a group of them in [DsShimmer] for the light sweep.
///
/// Its [width] and [height] are the shape of the content it stands in for;
/// the look (tones, default height) comes from [DsSkeletonStyle].
///
/// Corners follow the content: a text line is fully rounded, a circle is
/// round, and a block (an image, a card, a button) takes the radius of
/// media inside a card (the card radius less its padding, see
/// `DsRadii.nested`), never rounder than a capsule. A [DsSkeletonStyle.borderRadius] wins over all of them.
class DsSkeleton extends StatelessWidget {
  /// A line of text, fully rounded. A shape taller than [lineMaxHeight]
  /// is not a line and is drawn as a block ([DsSkeleton.block]).
  const DsSkeleton({
    super.key,
    this.width,
    this.height,
    this.strong = false,
    this.style,
  }) : _shape = _Shape.auto;

  /// A block, e.g. an image, a card or a button: the theme's corners
  /// whatever its height.
  const DsSkeleton.block({
    super.key,
    this.width,
    this.height,
    this.strong = false,
    this.style,
  }) : _shape = _Shape.block;

  /// A circle, e.g. an avatar.
  const DsSkeleton.circle({
    super.key,
    required double size,
    this.strong = false,
    this.style,
  }) : width = size,
       height = size,
       _shape = _Shape.circle;

  /// The tallest a text line placeholder gets (a title line); a taller
  /// [DsSkeleton] is drawn as a block.
  static const lineMaxHeight = 16.0;

  final _Shape _shape;

  /// Width; null fills the available width.
  final double? width;

  /// Height; null uses [DsSkeletonStyle.height].
  final double? height;

  /// Use the stronger channel tone, e.g. for a title line.
  final bool strong;

  /// Style laid over the theme and defaults.
  final DsSkeletonStyle? style;

  /// Desen's default skeleton style under [theme].
  static DsSkeletonStyle defaultStyle(DsThemeData theme) => DsSkeletonStyle(
    height: 8,
    color: theme.colors.channel,
    strongColor: theme.colors.channelStrong,
  );

  @override
  Widget build(BuildContext context) {
    final s = DsSkeletonStyle.resolveLayers([
      defaultStyle(dsThemeOf(context)),
      DsSkeletonTheme.of(context).style,
      style,
    ], const {});
    final h = height ?? s.height ?? 0;
    final block =
        _shape == _Shape.block || (_shape == _Shape.auto && h > lineMaxHeight);
    // A block stands for media inside a card: concentric with the card,
    // inset by its padding.
    final radii = DsTheme.radiiOf(context);
    final radius = block
        ? math.min(radii.nested(radii.card, DsSpace.s16), h / 2)
        : h / 2;
    return Container(
      width: width,
      height: h,
      decoration: DsBoxDecoration(
        color: strong ? s.strongColor : s.color,
        borderRadius: s.borderRadius ?? BorderRadius.circular(radius),
      ),
    );
  }
}

enum _Shape { auto, block, circle }

/// Sweeps a soft highlight across [child] every `DsMotion.shimmer`.
///
/// Off when the platform asks to reduce motion. Screen readers hear
/// [semanticLabel] instead of the placeholder shapes.
class DsShimmer extends StatefulWidget {
  /// Creates a shimmer over [child].
  const DsShimmer({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
  });

  /// The skeleton layout.
  final Widget child;

  /// Clip for the sweep, matching the container it sits in.
  final BorderRadius borderRadius;

  /// What is loading, for screen readers.
  final String? semanticLabel;

  @override
  State<DsShimmer> createState() => _DsShimmerState();
}

class _DsShimmerState extends State<DsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = DsTheme.motionOf(context);
    _sweep.duration = motion.shimmer;
    if (motion.reduced) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final glow = t.colors.shimmer;
    final clear = glow.withValues(alpha: 0);
    final content = ExcludeSemantics(child: widget.child);
    final body = t.motion.reduced
        ? content
        : DsShapeClip(
            borderRadius: widget.borderRadius,
            child: Stack(
              children: [
                content,
                // Only the sweep repaints each frame, on its own layer; the
                // shapes and what is around them stay.
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) => FractionalTranslation(
                          // CSS: translateX(-100% → 100%), ease-in-out.
                          translation: Offset(
                            -1 +
                                2 * t.motion.sweepCurve.transform(_sweep.value),
                            0,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [clear, glow, clear],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
    return Semantics(label: widget.semanticLabel, child: body);
  }
}
