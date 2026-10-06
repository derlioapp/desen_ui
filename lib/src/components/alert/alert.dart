import 'package:flutter/widgets.dart';

import '../../foundation/color_utils.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../l10n/localizations.dart';
import '../../theme/colors.dart';
import '../../theme/sizes.dart';
import '../../theme/status.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'alert_style.dart';

/// An inline message: info, success, warning or danger.
///
/// A vivid status icon and a title in status ink, with an optional
/// description in muted ink. In light mode the box has a soft status
/// background; in dark mode it is a neutral raised block, the status
/// carried by the icon and title alone (a deep status background reads
/// brown or maroon in the dark). Status is never told by color alone: the
/// icon always comes along.
class DsAlert extends StatelessWidget {
  /// Creates an alert.
  const DsAlert({
    super.key,
    required this.title,
    this.description,
    this.status = DsStatus.info,
    this.icon,
    this.action,
    this.announce = false,
    this.style,
  });

  /// The headline, usually a short [Text].
  final Widget title;

  /// Supporting text.
  final Widget? description;

  /// Which status colors and default icon to use.
  final DsStatus status;

  /// Replaces the default status icon.
  final Widget? icon;

  /// A trailing control, e.g. a small ghost button.
  final Widget? action;

  /// Announce the alert to screen readers when it appears (a live region).
  /// Use for alerts that show up in response to something.
  final bool announce;

  /// Style laid over the theme and defaults.
  final DsAlertStyle? style;

  /// Desen's default alert style for [status] under [theme].
  static DsAlertStyle defaultStyle(
    DsThemeData theme, {
    required DsStatus status,
  }) {
    final k = theme.colors;
    final s = k.status(status);
    // Light mode: the soft status tint. Dark mode: a neutral raised block
    // (the neutral tint, lighter than the layer below), the status told by
    // the vivid icon and the colored title, as on iOS: a deep status tint
    // reads brown or maroon this dark.
    final background = theme.isDark ? k.neutral.tint : s.tint;
    return DsAlertStyle(
      padding: const EdgeInsets.all(DsSpace.s12),
      background: background,
      borderRadius: BorderRadius.circular(theme.radii.card),
      iconColor: iconColor(s, DsColorUtils.flatten(background, k.surface)),
      iconSize: 16,
      titleStyle: theme.typography.labelStrong.copyWith(color: s.text),
      descriptionStyle: theme.typography.caption.copyWith(color: k.textMuted),
      gap: DsSpace.s12,
      textGap: 2,
    );
  }

  static DsIconData _defaultIcon(DsStatus status) => switch (status) {
    DsStatus.neutral || DsStatus.info => DsIcons.info,
    DsStatus.success => DsIcons.circleCheck,
    DsStatus.warning => DsIcons.triangleAlert,
    DsStatus.danger => DsIcons.circleAlert,
  };

  static String? _statusLabel(DsLocalizations l10n, DsStatus status) =>
      switch (status) {
        DsStatus.neutral => null,
        DsStatus.info => l10n.info,
        DsStatus.success => l10n.success,
        DsStatus.warning => l10n.warning,
        DsStatus.danger => l10n.error,
      };

  /// The icon color on an alert's [background] (opaque): the vivid
  /// [DsStatusColors.signal] when it reads at 3:1 there (WCAG 1.4.11),
  /// else the status ink.
  static Color iconColor(DsStatusColors s, Color background) =>
      DsColorUtils.contrastRatio(s.signal, background) >= 3 ? s.signal : s.text;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final theme = DsAlertTheme.of(context);
    final s = DsAlertStyle.resolveLayers([
      defaultStyle(t, status: status),
      theme.style,
      theme.statuses[status],
      style,
    ], const {});

    return Semantics(
      container: true,
      liveRegion: announce,
      child: Container(
        padding: s.padding,
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: s.borderRadius ?? BorderRadius.zero,
          shadows: [
            if (s.borderColor case final edge? when edge.a > 0)
              DsShadow.innerRing(edge),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: s.gap ?? DsSpace.s12,
          children: [
            // The icon names the status for screen readers ("Warning"), so
            // it does not rest on the title wording (ux V25).
            Semantics(
              label: _statusLabel(DsLocalizations.of(context), status),
              child: Padding(
                // ds-raw: optical nudge onto the title's first line
                padding: const EdgeInsets.only(top: 1),
                child: IconTheme.merge(
                  data: IconThemeData(color: s.iconColor, size: s.iconSize),
                  child: icon ?? DsIcon(_defaultIcon(status)),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: s.textGap!,
                children: [
                  DefaultTextStyle(
                    style: s.titleStyle ?? const TextStyle(),
                    child: title,
                  ),
                  if (description != null)
                    DefaultTextStyle(
                      style: s.descriptionStyle ?? const TextStyle(),
                      child: description!,
                    ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
