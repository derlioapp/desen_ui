import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundation/color_utils.dart';
import '../../foundation/oklch.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/colors.dart';
import '../../theme/sizes.dart';
import '../../theme/status.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../../l10n/localizations.dart';
import '../../theme/typography.dart';
import 'avatar_group_style.dart';
import 'avatar_style.dart';
import 'cover_image.dart';

/// A round avatar: an image, initials, or a person icon.
///
/// Initials sit on soft brand-derived colors that meet AA in every seed and
/// mode (the concept's solid avatars had white initials as low
/// as 2.7:1). [toneIndex] picks one of several hues so neighbors stay
/// apart; use [DsAvatar.toneFor] to give each person a stable color.
class DsAvatar extends StatelessWidget {
  /// Creates an avatar. Shows [image] when given, else [initials], else a
  /// person icon.
  const DsAvatar({
    super.key,
    this.initials,
    this.image,
    this.size,
    this.status,
    this.statusLabel,
    this.toneIndex,
    this.semanticLabel,
    this.resizeImage = true,
    this.style,
  }) : _contentInsetEnd = 0,
       _paintsStatus = true;

  /// An avatar in a [DsAvatarGroup]: the group paints the status dot above
  /// the whole stack, so the next avatar cannot cover it.
  const DsAvatar._inGroup({
    required this.initials,
    required this.image,
    required this.size,
    required this.status,
    required this.statusLabel,
    required this.toneIndex,
    required this.semanticLabel,
    required this._contentInsetEnd,
    required this.resizeImage,
    required this.style,
  }) : _paintsStatus = false;

  /// Up to two letters.
  final String? initials;

  /// A photo. It is decoded at the avatar's size (see [resizeImage]).
  /// Until its first frame arrives, and if it fails to load, the avatar
  /// shows [initials] (or the person icon).
  final ImageProvider? image;

  /// Decodes [image] just large enough to cover the circle at the device's
  /// pixel ratio ([DsCoverImage]) instead of at full resolution: a 12 MP
  /// photo in a 40px avatar costs ~100 KB of memory, not ~48 MB.
  ///
  /// Turn it off when [image] already sets its own decode size (it is
  /// skipped for [ResizeImage] and [DsCoverImage]) or when the same
  /// full-size image is shown elsewhere and should be decoded only once.
  final bool resizeImage;

  /// Diameter: 24 · 32 · 40 · 48 by default ([DsAvatarStyle.diameter]).
  /// Null uses [DsAvatarThemeData.size], else [DsSize.md].
  final DsSize? size;

  /// A status dot on the bottom-end edge. Screen readers hear it after the
  /// name ("Ayşe Kaya, Online"): see [statusLabel].
  final DsStatus? status;

  /// What screen readers hear for [status]. Defaults to the localized
  /// presence: [DsStatus.success] "Online", [DsStatus.warning] "Away",
  /// [DsStatus.danger] "Busy", [DsStatus.neutral] "Offline", and the
  /// generic "Information" for [DsStatus.info] (give it a word of your
  /// own, e.g. "In a meeting").
  final String? statusLabel;

  /// False when a [DsAvatarGroup] paints the dot instead.
  final bool _paintsStatus;

  /// The default [statusLabel] for [status].
  static String presenceLabel(DsLocalizations l10n, DsStatus status) =>
      switch (status) {
        DsStatus.success => l10n.presenceOnline,
        DsStatus.warning => l10n.presenceAway,
        DsStatus.danger => l10n.presenceBusy,
        DsStatus.neutral => l10n.presenceOffline,
        DsStatus.info => l10n.info,
      };

  /// Picks one of the [toneCount] (8) generated avatar tones for initials
  /// and icon avatars, by index; it wraps around, so any int works. Null
  /// uses the selection colors (tone 0). A style's
  /// [DsAvatarStyle.background] and [DsAvatarStyle.foreground] win over it.
  final int? toneIndex;

  /// Number of distinct tones before they repeat.
  static const toneCount = 8;

  /// A stable tone index for [key] (e.g. a user id or name).
  static int toneFor(String key) {
    var h = 0;
    for (final unit in key.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h % toneCount;
  }

  /// The background and foreground of tone [index] under [colors]: the
  /// selection pair with its hue turned by the golden angle per step.
  /// Lightness stays, so contrast stays AA; chroma gets a floor so neutral
  /// seeds still tell tones apart.
  static (Color, Color) toneColors(DsColors colors, int index) {
    final step = index % toneCount;
    if (step == 0) return (colors.selection, colors.onSelection);
    DsOklch turn(Color c, double minChroma, double maxChroma) {
      final o = DsOklch.fromColor(c);
      return DsOklch(
        o.l,
        o.c.clamp(minChroma, maxChroma),
        o.h + step * 137.5,
        o.alpha,
      );
    }

    final bg = turn(colors.selection, .035, .08).toColor();
    // Rotating the hue at fixed lightness changes luminance (yellow is
    // brighter than blue at the same OKLCH lightness), so the initials are
    // measured and pushed away from the fill until they read at 4.5:1.
    var fg = turn(colors.onSelection, .06, .14);
    final away =
        DsColorUtils.luminance(fg.toColor()) <
            DsColorUtils.luminance(DsColorUtils.flatten(bg, colors.surface))
        ? -.01
        : .01;
    while (fg.l > 0 &&
        fg.l < 1 &&
        DsColorUtils.contrastRatio(fg.toColor(), bg, backdrop: colors.surface) <
            4.5) {
      fg = DsOklch(fg.l + away, fg.c, fg.h, fg.alpha);
    }
    return (bg, fg.toColor());
  }

  /// Name for screen readers, e.g. the person's full name; defaults to
  /// [initials]. The [status] is added after it.
  final String? semanticLabel;

  /// Centers initials and icon in the part of the circle left visible when
  /// this much of the end edge is covered. [DsAvatarGroup] sets it for
  /// overlapped avatars so their initials stay clear.
  final double _contentInsetEnd;

  /// Style laid over the theme and defaults.
  final DsAvatarStyle? style;

  /// Desen's default avatar style for [size] under [theme]. It leaves
  /// [DsAvatarStyle.background] and [DsAvatarStyle.foreground] to the tone.
  static DsAvatarStyle defaultStyle(DsThemeData theme, {required DsSize size}) {
    final diameter = switch (size) {
      DsSize.xs => 24.0,
      DsSize.sm => 32.0,
      DsSize.md => 40.0,
      DsSize.lg => 48.0,
    };
    return DsAvatarStyle(
      diameter: diameter,
      textStyle: dsTextStyle(
        family: theme.typography.family,
        package: theme.typography.package,
        size: switch (size) {
          DsSize.xs => 10,
          DsSize.sm => 12,
          DsSize.md => 14,
          DsSize.lg => 16,
        },
        weight: FontWeight.w600,
      ),
      iconSize: diameter * 5 / 12,
      statusSize: 10,
      ringColor: theme.colors.surface,
      ringWidth: 2,
    );
  }

  /// The resolved style for [size] in [context], with [style] on top.
  static DsAvatarStyle _resolve(
    BuildContext context,
    DsSize size,
    DsAvatarStyle? style,
  ) {
    final theme = DsAvatarTheme.of(context);
    return DsAvatarStyle.resolveLayers([
      defaultStyle(dsThemeOf(context), size: size),
      theme.style,
      theme.sizes[size],
      style,
    ], const {});
  }

  /// The status dot: a circle in the vivid status signal with a ring.
  static Widget _statusDot(DsAvatarStyle s, Color fill) {
    final dot = s.statusSize ?? 0;
    return Container(
      width: dot,
      height: dot,
      decoration: DsBoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(dot / 2),
        shadows: [
          if (s.ringColor case final ring?)
            DsShadow.ring(ring, width: s.ringWidth ?? 0),
        ],
      ),
    );
  }

  ImageProvider _decoded(ImageProvider image, double diameter) =>
      !resizeImage || image is ResizeImage || image is DsCoverImage
      ? image
      : DsCoverImage(image, width: diameter, height: diameter);

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    final size = this.size ?? DsAvatarTheme.of(context).size ?? DsSize.md;
    final s = _resolve(context, size, style);
    final d = s.diameter!;
    final (toneBg, toneFg) = toneColors(k, toneIndex ?? 0);
    final bg = s.background ?? toneBg;
    final fg = s.foreground ?? toneFg;

    final fallback = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      padding: EdgeInsetsDirectional.only(end: _contentInsetEnd),
      decoration: DsBoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(d / 2),
      ),
      child: initials != null
          ? Text(
              initials!,
              maxLines: 1,
              // Initials are sized to the circle; the name reaches screen
              // readers through the semantics label instead.
              textScaler: TextScaler.noScaling,
              style: (s.textStyle ?? const TextStyle())
                  // ds-raw: a line box of one em centers the initials
                  .copyWith(color: fg, height: 1),
            )
          : DsIcon(DsIcons.user, size: s.iconSize, color: fg),
    );
    // A photo that fails to load shows the initials (or the icon) instead
    // of an error (B21, eng M14).
    Widget face = image == null
        ? fallback
        : ClipOval(
            child: Image(
              image: _decoded(image!, d),
              width: d,
              height: d,
              fit: BoxFit.cover,
              // The initials (or the icon) hold the place while the photo
              // decodes, instead of an empty circle.
              frameBuilder: (context, child, frame, synchronous) =>
                  synchronous || frame != null ? child : fallback,
              errorBuilder: (context, error, stack) => fallback,
            ),
          );

    if (status != null && _paintsStatus) {
      face = SizedBox(
        width: d,
        height: d,
        child: Stack(
          children: [
            face,
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: _statusDot(s, k.status(status!).signal),
            ),
          ],
        ),
      );
    }

    // The status is not told by color alone (KALITE R5): it is read after
    // the name.
    final name = semanticLabel ?? initials;
    final presence = status == null
        ? null
        : statusLabel ?? presenceLabel(DsLocalizations.of(context), status!);
    return Semantics(
      image: true,
      label: name == null && presence == null
          ? null
          : [?name, ?presence].join(', '),
      excludeSemantics: true,
      child: face,
    );
  }
}

/// Overlapping avatars with an optional `+N` overflow.
class DsAvatarGroup extends StatelessWidget {
  /// Creates a group. Shows at most [max] avatars, then a `+N` bubble;
  /// with [max] below 1 only the bubble shows.
  const DsAvatarGroup({
    super.key,
    required this.avatars,
    this.size,
    this.max = 4,
    this.semanticLabel,
    this.style,
  });

  /// The avatars, in order. Their own sizes are overridden by [size].
  final List<DsAvatar> avatars;

  /// Size of every avatar in the group. Null uses
  /// [DsAvatarGroupThemeData.size], else [DsSize.sm].
  final DsSize? size;

  /// Most avatars shown before `+N`.
  final int max;

  /// Description for screen readers, e.g. "8 people editing".
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsAvatarGroupStyle? style;

  /// Desen's default avatar group style under [theme].
  static DsAvatarGroupStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsAvatarGroupStyle(
      ringColor: k.surface,
      ringWidth: 2,
      // A fifth of the diameter: initials stay clear of the next ring.
      overlap: 1 / 5,
      overflowSurface: k.surface,
      overflowBackground: k.neutral.tint,
      overflowForeground: k.neutral.text,
      overflowTextStyle: theme.typography
          .numeric(theme.typography.caption)
          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final theme = DsAvatarGroupTheme.of(context);
    final size = this.size ?? theme.size ?? DsSize.sm;
    final s = DsAvatarGroupStyle.resolveLayers([
      defaultStyle(t),
      theme.style,
      style,
    ], const {});
    final d = DsAvatar._resolve(context, size, null).diameter!;
    final overlap = d * (s.overlap ?? 0);
    final ringWidth = s.ringWidth ?? 0;
    // max: 0 used to throw (B27).
    final shown = avatars.length > max
        ? avatars.take(math.max(0, max - 1)).toList()
        : avatars;
    final hidden = avatars.length - shown.length;

    Widget ringed(Widget child) => DecoratedBox(
      decoration: DsBoxDecoration(
        borderRadius: BorderRadius.circular(d / 2),
        shadows: [
          if (s.ringColor case final ring?)
            DsShadow.ring(ring, width: ringWidth),
        ],
      ),
      child: child,
    );

    final children = <Widget>[
      for (final (i, a) in shown.indexed)
        ringed(
          DsAvatar._inGroup(
            initials: a.initials,
            image: a.image,
            size: size,
            // Neighbors get different tones unless the caller chose one.
            toneIndex: a.toneIndex ?? i,
            // Every avatar but the last is partly covered by the next one
            // and its ring.
            contentInsetEnd: i < shown.length - 1 || hidden > 0
                ? overlap + ringWidth
                : 0,
            // Kept from the caller's avatar (B26).
            semanticLabel: a.semanticLabel,
            status: a.status,
            statusLabel: a.statusLabel,
            resizeImage: a.resizeImage,
            style: a.style,
          ),
        ),
      if (hidden > 0)
        ringed(
          Container(
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: DsBoxDecoration(
              color: s.overflowSurface,
              borderRadius: BorderRadius.circular(d / 2),
            ),
            child: Container(
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: DsBoxDecoration(
                color: s.overflowBackground,
                borderRadius: BorderRadius.circular(d / 2),
              ),
              child: Text(
                DsLocalizations.of(context).overflowCount(hidden),
                semanticsLabel: DsLocalizations.of(context).moreCount(hidden),
                style: (s.overflowTextStyle ?? const TextStyle()).copyWith(
                  color: s.overflowForeground,
                  height: 1, // ds-raw: a line box of one em centers it
                ),
              ),
            ),
          ),
        ),
    ];

    // Status dots sit on each avatar's bottom-end corner, where the next
    // avatar overlaps it; they are painted above the whole stack so none is
    // covered. The group's ring also rings them, unless an avatar sets its
    // own.
    final k = t.colors;
    final dots = <Widget>[
      for (final (i, a) in shown.indexed)
        if (a.status case final status?)
          Builder(
            builder: (context) {
              final as = DsAvatar._resolve(
                context,
                size,
                DsAvatarStyle(ringColor: s.ringColor).merge(a.style),
              );
              final dot = as.statusSize ?? 0;
              return PositionedDirectional(
                start: i * (d - overlap) + d - dot,
                top: d - dot,
                child: ExcludeSemantics(
                  child: DsAvatar._statusDot(as, k.status(status).signal),
                ),
              );
            },
          ),
    ];

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Each avatar but the last takes up less width than it draws,
              // so the next one overlaps it.
              for (var i = 0; i < children.length; i++)
                Align(
                  widthFactor: i == children.length - 1 ? 1 : (d - overlap) / d,
                  alignment: AlignmentDirectional.centerStart,
                  child: children[i],
                ),
            ],
          ),
          ...dots,
        ],
      ),
    );
  }
}
