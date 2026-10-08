import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shape.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../avatar/cover_image.dart';
import '../skeleton/skeleton.dart';
import '../skeleton/skeleton_style.dart';
import 'image_style.dart';

/// A picture in a box whose size is known before the picture arrives, with
/// a loading and an error state of the same size.
///
/// **The box is reserved.** A [DsImage] needs [width] and [height], or an
/// [aspectRatio] (with at most one of them): the layout never jumps when
/// the picture loads, also on a slow connection where a self-sizing image
/// would push the content below it down mid-read.
///
/// **Loading** shows a [DsSkeleton] filling the box. Put the image in a
/// `DsShimmer` with the text placeholders beside it for one shared sweep.
/// **Loaded**, the picture fades in briefly (a tone change, so reduced
/// motion keeps it; nothing moves). A picture that is already decoded
/// shows at once, with no fade. **Unavailable** (the picture fails, or
/// [image] is null) shows a quiet crossed-out picture icon on a
/// channel-toned fill, announced as "Image unavailable" (localized); give
/// a [fallback] to show your own stand-in there instead, such as initials
/// or a placeholder cover.
///
/// **Corners** follow the theme: by default the radius of media inside a
/// card, with continuous corners, the same in every state. Set
/// [DsImageStyle.borderRadius] to change them, `BorderRadius.zero` for a
/// square picture.
///
/// **Memory.** The picture is decoded just large enough to cover the box
/// at the device's pixel ratio ([DsCoverImage]), not at full resolution;
/// see [resizeImage].
///
/// ```dart
/// DsImage.network(
///   album.coverUrl,
///   aspectRatio: 1,
///   semanticLabel: album.title,
/// )
/// ```
///
/// Any [ImageProvider] works, so a caching provider drops in unchanged.
///
/// A station logo that may be missing or broken, with its initials in the
/// same box instead:
///
/// ```dart
/// DsImage(
///   image: station.logoUrl == null ? null : NetworkImage(station.logoUrl!),
///   width: 48,
///   height: 48,
///   semanticLabel: station.name,
///   fallback: ColoredBox(
///     color: tone,
///     child: Center(child: Text(station.initials)),
///   ),
/// )
/// ```
class DsImage extends StatefulWidget {
  /// Shows [image] in a reserved box.
  const DsImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.resizeImage = true,
    this.semanticLabel,
    this.fallback,
    this.style,
  }) : assert(
         (width != null && height != null) != (aspectRatio != null),
         'DsImage needs a reserved box: pass width and height, or an '
         'aspectRatio with at most one of them.',
       ),
       assert(aspectRatio == null || aspectRatio > 0);

  /// Shows the image at [src] in a reserved box: a [NetworkImage] with
  /// [scale] and [headers].
  DsImage.network(
    String src, {
    super.key,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.resizeImage = true,
    this.semanticLabel,
    this.fallback,
    this.style,
    double scale = 1.0,
    Map<String, String>? headers,
  }) : image = NetworkImage(src, scale: scale, headers: headers),
       assert(
         (width != null && height != null) != (aspectRatio != null),
         'DsImage needs a reserved box: pass width and height, or an '
         'aspectRatio with at most one of them.',
       ),
       assert(aspectRatio == null || aspectRatio > 0);

  /// Where the picture comes from. Null, when there is none, shows the
  /// unavailable state (or [fallback]) at once, without loading.
  final ImageProvider? image;

  /// Width of the box. With [height], the whole box; with [aspectRatio],
  /// the height follows.
  final double? width;

  /// Height of the box. With [width], the whole box; with [aspectRatio],
  /// the width follows.
  final double? height;

  /// Width divided by height of the box. On its own, the box is as wide as
  /// its parent allows (or as tall, in an unbounded width).
  final double? aspectRatio;

  /// How the picture fills the box; by default it covers it and is
  /// cropped. The box keeps its size either way.
  final BoxFit fit;

  /// Where the picture sits in the box when it is cropped or smaller.
  final AlignmentGeometry alignment;

  /// Decodes [image] just large enough to cover the box at the device's
  /// pixel ratio ([DsCoverImage]) instead of at full resolution. When the
  /// box grows, the picture is decoded again at the new size; when it
  /// shrinks, the larger decode is kept.
  ///
  /// Turn it off when the same full-size picture is shown elsewhere and
  /// should be decoded only once. It is skipped for providers that set
  /// their own decode size ([ResizeImage], [DsCoverImage]).
  final bool resizeImage;

  /// What the picture shows, for screen readers. Null marks it as
  /// decoration: screen readers skip it in every state.
  final String? semanticLabel;

  /// Shown instead of the crossed-out picture when the picture fails or
  /// [image] is null: a stand-in such as initials or a placeholder cover.
  /// It fills the box and is clipped to its corners, so nothing moves; it
  /// draws its own background. Screen readers hear [semanticLabel] for
  /// the box, not the stand-in's own text, and no "Image unavailable": the
  /// stand-in is the picture's place, not an error. While the picture
  /// loads, the box shows the loading placeholder as usual.
  final Widget? fallback;

  /// Style laid over the theme and defaults.
  final DsImageStyle? style;

  /// Desen's default image style under [theme].
  static DsImageStyle defaultStyle(DsThemeData theme) => DsImageStyle(
    // Media inside a card: concentric with the card, inset by its padding.
    borderRadius: BorderRadius.circular(
      theme.radii.nested(theme.radii.card, DsSpace.s16),
    ),
    errorBackground: theme.colors.channel,
    errorIconColor: theme.colors.textSubtle,
    errorIconSize: theme.sizes.iconLg,
  );

  @override
  State<DsImage> createState() => _DsImageState();
}

class _DsImageState extends State<DsImage> {
  /// A frame of the current picture has been shown: later frames that
  /// come with a new decode size show at once.
  bool _loaded = false;

  /// The fade-in is over: the placeholder under the picture is gone.
  bool _settled = false;

  /// The largest box the picture was decoded for.
  Size? _decodeSize;

  @override
  void didUpdateWidget(DsImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _loaded = false;
      _settled = false;
      _decodeSize = null;
    }
  }

  ImageProvider _provider(ImageProvider image, Size box) {
    if (!widget.resizeImage ||
        image is ResizeImage ||
        image is DsCoverImage ||
        !box.isFinite ||
        box.isEmpty) {
      return image;
    }
    final last = _decodeSize;
    final size = _decodeSize = last == null
        ? box
        : Size(
            math.max(last.width, box.width),
            math.max(last.height, box.height),
          );
    return DsCoverImage(image, width: size.width, height: size.height);
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsImageStyle.resolveLayers([
      DsImage.defaultStyle(t),
      DsImageTheme.of(context).style,
      widget.style,
    ], const {});
    final label = widget.semanticLabel;

    Widget placeholder(Size box) => DsSkeleton.block(
      width: box.width,
      height: box.height,
      // The clip around the box shapes it.
      style: const DsSkeletonStyle(borderRadius: BorderRadius.zero),
    );

    Widget unavailable() => switch (widget.fallback) {
      // The stand-in's own text is not read: the box's label names it.
      final fallback? => ExcludeSemantics(
        child: SizedBox.expand(child: fallback),
      ),
      null => Semantics(
        value: DsLocalizations.of(context).imageUnavailable,
        child: DecoratedBox(
          decoration: DsBoxDecoration(color: s.errorBackground),
          child: Center(
            // A box smaller than the icon shrinks it rather than overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DsIcon(
                DsIcons.imageOff,
                size: s.errorIconSize,
                color: s.errorIconColor,
              ),
            ),
          ),
        ),
      ),
    };

    final image = widget.image;
    Widget picture = image == null
        ? unavailable()
        : LayoutBuilder(
            builder: (context, constraints) {
              final box = constraints.biggest;
              return Image(
                image: _provider(image, box),
                fit: widget.fit,
                alignment: widget.alignment,
                width: box.width,
                height: box.height,
                excludeFromSemantics: true,
                // A new decode size keeps the current picture until it is ready.
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, synchronous) {
                  final shown = synchronous || frame != null || _loaded;
                  if (synchronous || frame != null) _loaded = true;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!synchronous && !_settled) placeholder(box),
                      AnimatedOpacity(
                        opacity: shown ? 1 : 0,
                        duration: t.motion.toneDuration,
                        curve: t.motion.toneCurve,
                        onEnd: () {
                          if (shown && mounted && !_settled) {
                            setState(() => _settled = true);
                          }
                        },
                        child: child,
                      ),
                    ],
                  );
                },
                errorBuilder: (context, error, stackTrace) => unavailable(),
              );
            },
          );

    picture = DsShapeClip(
      borderRadius: s.borderRadius ?? BorderRadius.zero,
      child: picture,
    );

    final ratio = widget.aspectRatio;
    picture = ratio == null
        ? SizedBox(width: widget.width, height: widget.height, child: picture)
        : SizedBox(
            width: widget.width,
            height: widget.height,
            child: AspectRatio(aspectRatio: ratio, child: picture),
          );

    if (label == null) return ExcludeSemantics(child: picture);
    return Semantics(
      container: true,
      image: true,
      label: label,
      child: picture,
    );
  }
}
