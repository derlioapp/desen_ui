import 'package:flutter/widgets.dart';

import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/radii.dart';
import '../../theme/sizes.dart';
import '../../theme/status.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../../l10n/localizations.dart';
import '../../theme/typography.dart';
import 'badge_style.dart';
import 'count_style.dart';
import 'status_dot_style.dart';

/// A status pill: soft tint, colored text and a dot.
///
/// ```dart
/// const DsBadge(status: .success, label: Text('Yayında'))
/// ```
///
/// The dot is always there by default, so status is never told by color
/// alone; replace it with [icon] or hide it with [dot] when the
/// label alone carries the meaning.
class DsBadge extends StatelessWidget {
  /// Creates a badge.
  const DsBadge({
    super.key,
    required this.label,
    this.status = DsStatus.neutral,
    this.dot = true,
    this.icon,
    this.style,
  });

  /// The text, usually a short [Text].
  final Widget label;

  /// Which status colors to use.
  final DsStatus status;

  /// Show the leading dot.
  final bool dot;

  /// Replaces the dot with an icon (12px).
  final Widget? icon;

  /// Style laid over the theme and defaults.
  final DsBadgeStyle? style;

  /// Desen's default badge style for [status] under [theme].
  static DsBadgeStyle defaultStyle(
    DsThemeData theme, {
    required DsStatus status,
  }) {
    final colors = theme.colors.status(status);
    return DsBadgeStyle(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s8),
      // In dark mode a status tint this deep turns brown or maroon, so the
      // pill stays neutral and the status shows in the text and the dot.
      background: theme.isDark ? theme.colors.control : colors.tint,
      foreground: colors.text,
      dotColor: colors.signal,
      borderRadius: BorderRadius.circular(DsRadii.pill),
      textStyle: theme.typography.fieldLabel,
      dotSize: 6,
      iconSize: 12,
      gap: DsSpace.s6,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final theme = DsBadgeTheme.of(context);
    final s = DsBadgeStyle.resolveLayers([
      defaultStyle(t, status: status),
      theme.style,
      theme.statuses[status],
      style,
    ], const {});
    final ink = s.foreground!;
    final dotSize = s.dotSize!;
    return Container(
      // A minimum, not a fixed height: the pill grows with large text.
      constraints: BoxConstraints(minHeight: s.height!),
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: [
          if (s.borderColor case final edge? when edge.a > 0)
            DsShadow.innerRing(edge),
        ],
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: ink, size: s.iconSize),
        child: DefaultTextStyle(
          style: (s.textStyle ?? const TextStyle()).copyWith(color: ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: s.gap ?? DsSpace.s6,
            children: [
              if (icon != null)
                icon!
              else if (dot)
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: DsBoxDecoration(
                    color: s.dotColor ?? ink,
                    borderRadius: BorderRadius.circular(dotSize / 2),
                  ),
                ),
              Flexible(child: label),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color of a [DsCount] bubble.
enum DsCountTone {
  /// Accent fill: unread items.
  accent,

  /// Danger fill: items needing attention.
  danger,

  /// Neutral tint: totals.
  neutral,
}

/// A number bubble, e.g. unread notifications. Numbers use
/// tabular figures; values above [max] show as `max+`.
///
/// Every count in the library caps this way ([text]): a bubble, a tab's
/// count and a sidebar item's count all show and announce "99+" above 99.
/// Screen readers hear only the number; give [semanticLabel] what it
/// counts ("3 unread").
///
/// A 2px ring in the surface color separates the bubble from what it sits
/// on; set [DsCountStyle.ringColor] to the real background when it is not
/// the surface, or transparent to drop the ring.
class DsCount extends StatelessWidget {
  /// Creates a count bubble.
  const DsCount(
    this.count, {
    super.key,
    this.tone = DsCountTone.accent,
    this.max = defaultMax,
    this.semanticLabel,
    this.style,
  });

  /// The cap every count in the library uses by default.
  static const defaultMax = 99;

  /// [count] as the library shows and announces counts: the number, or
  /// the localized `max+` ("99+") above [max]. Components that show a
  /// count outside a bubble use it, so every count caps the same way.
  static String text(BuildContext context, int count, {int max = defaultMax}) =>
      count > max ? DsLocalizations.of(context).countOverflow(max) : '$count';

  /// The number.
  final int count;

  /// Fill color.
  final DsCountTone tone;

  /// Larger counts show as `max+`.
  final int max;

  /// Overrides what screen readers announce (default: the number).
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsCountStyle? style;

  /// Desen's default count style for [tone] under [theme].
  static DsCountStyle defaultStyle(
    DsThemeData theme, {
    required DsCountTone tone,
  }) {
    final k = theme.colors;
    final (fill, ink) = switch (tone) {
      DsCountTone.accent => (k.accent, k.onAccent),
      DsCountTone.danger => (k.danger.fill, k.danger.onFill),
      DsCountTone.neutral => (k.neutral.tint, k.neutral.text),
    };
    return DsCountStyle(
      minSize: 18,
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s5),
      background: fill,
      foreground: ink,
      borderRadius: BorderRadius.circular(DsRadii.pill),
      ringColor: k.surface,
      ringWidth: 2,
      textStyle: theme.typography.numeric(
        dsTextStyle(
          family: theme.typography.family,
          package: theme.typography.package,
          size: 11,
          weight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final theme = DsCountTheme.of(context);
    final s = DsCountStyle.resolveLayers([
      defaultStyle(t, tone: tone),
      theme.style,
      theme.tones[tone],
      style,
    ], const {});
    final text = DsCount.text(context, count, max: max);
    final minSize = s.minSize ?? 0;
    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        padding: s.padding,
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: s.borderRadius ?? BorderRadius.zero,
          shadows: [
            if (s.ringColor case final ring?)
              DsShadow.ring(ring, width: s.ringWidth ?? 0),
            if (s.borderColor case final edge? when edge.a > 0)
              DsShadow.innerRing(edge),
          ],
        ),
        // Shrink-wrap: in a taller slot (a tab, a row) the bubble keeps its
        // size instead of stretching.
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            text,
            maxLines: 1,
            style: (s.textStyle ?? const TextStyle())
                // ds-raw: a line box of one em centers the figures
                .copyWith(color: s.foreground, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Places a [badge] (usually a [DsCount]) on the top-end corner of [child].
class DsAnchoredBadge extends StatelessWidget {
  /// Anchors [badge] to [child].
  const DsAnchoredBadge({
    super.key,
    required this.child,
    required this.badge,
    this.offset = const Offset(5, -4),
  });

  /// The anchor, e.g. an icon button.
  final Widget child;

  /// The badge.
  final Widget badge;

  /// How far the badge sits past the end edge (x) and above the top (y).
  final Offset offset;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      PositionedDirectional(top: offset.dy, end: -offset.dx, child: badge),
    ],
  );
}

/// A status dot with its label, e.g. "online".
///
/// The label is required: a bare dot would tell the status by color alone.
/// Screen readers read the label.
class DsStatusDot extends StatelessWidget {
  /// Creates a status indicator.
  const DsStatusDot({
    super.key,
    this.status = DsStatus.success,
    required this.label,
    this.style,
  });

  /// Which status colors to use.
  final DsStatus status;

  /// Text next to the dot, usually a [Text].
  final Widget label;

  /// Style laid over the theme and defaults.
  final DsStatusDotStyle? style;

  /// Desen's default status dot style for [status] under [theme].
  static DsStatusDotStyle defaultStyle(
    DsThemeData theme, {
    required DsStatus status,
  }) {
    final colors = theme.colors.status(status);
    return DsStatusDotStyle(
      dotSize: 8,
      dotColor: colors.signal,
      // A deep tint ring reads brown in dark mode; the dot stands alone.
      haloColor: theme.isDark ? const Color(0x00000000) : colors.tint,
      haloWidth: 3,
      gap: DsSpace.s8,
      labelStyle: theme.typography.small.copyWith(
        color: theme.colors.textMuted,
        height: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final theme = DsStatusDotTheme.of(context);
    final s = DsStatusDotStyle.resolveLayers([
      defaultStyle(t, status: status),
      theme.style,
      theme.statuses[status],
      style,
    ], const {});
    final size = s.dotSize ?? 0;
    final dot = Container(
      width: size,
      height: size,
      decoration: DsBoxDecoration(
        color: s.dotColor,
        borderRadius: BorderRadius.circular(size / 2),
        shadows: [
          if (s.haloColor case final halo?)
            DsShadow.ring(halo, width: s.haloWidth ?? 0),
        ],
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: s.gap ?? 0,
      children: [
        dot,
        DefaultTextStyle(
          style: s.labelStyle ?? const TextStyle(),
          child: label,
        ),
      ],
    );
  }
}
