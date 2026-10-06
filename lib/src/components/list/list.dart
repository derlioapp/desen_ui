import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/shadow.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'list_row_style.dart';
import 'list_section_style.dart';

/// A group of [DsListRow]s in one card, with an optional header above it.
/// Dividers between rows start where the row text
/// starts.
///
/// ```dart
/// DsListSection(
///   header: const Text('TERCİHLER'),
///   children: [
///     DsListRow(leading: const DsIcon(DsIcons.bell), title: const Text('Bildirimler'),
///         detail: const Text('Açık'), showChevron: true, onPressed: openNotifications),
///     DsListRow(leading: const DsIcon(DsIcons.logOut), title: const Text('Oturumu kapat'),
///         destructive: true, onPressed: signOut),
///   ],
/// )
/// ```
///
/// The header is shown as given: write it in capitals yourself if you want
/// them (automatic upper-casing gets Turkish "i" wrong).
class DsListSection extends StatelessWidget {
  /// Creates a list section.
  const DsListSection({
    super.key,
    required this.children,
    this.header,
    this.style,
  });

  /// The rows, usually [DsListRow]s.
  final List<Widget> children;

  /// A short label above the card.
  final Widget? header;

  /// Style laid over the theme and defaults.
  final DsListSectionStyle? style;

  /// Desen's default list section style under [theme].
  static DsListSectionStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsListSectionStyle(
      background: k.surface,
      shadows: theme.shadows.surface,
      borderRadius: BorderRadius.circular(theme.radii.card),
      padding: const EdgeInsets.all(DsSpace.s5),
      headerStyle: theme.typography.overline.copyWith(color: k.textSubtle),
      headerPadding: const EdgeInsetsDirectional.only(
        start: 14,
        bottom: DsSpace.s8,
      ),
      dividerColor: k.border,
      dividerEndIndent: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final s = DsListSectionStyle.resolveLayers([
      defaultStyle(t),
      DsListSectionTheme.of(context).style,
      style,
    ], const {});
    // Where a row's text starts: padding, icon and gap.
    final row = DsListRowStyle.resolveLayers([
      DsListRow.defaultStyle(t),
      DsListRowTheme.of(context).style,
    ], const {});
    final rowStart =
        row.padding?.resolve(Directionality.of(context)).left ?? DsSpace.s12;
    final gap = row.gap ?? DsSpace.s12;
    final icon = row.iconSize!;

    Widget divider(Widget above) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: above is DsListRow && above.leading != null
            ? rowStart + icon + gap
            : rowStart,
        end: s.dividerEndIndent ?? 0,
      ),
      child: DsLine(color: s.dividerColor ?? const Color(0x00000000)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: s.headerPadding ?? EdgeInsets.zero,
            child: Semantics(
              header: true,
              child: DefaultTextStyle.merge(
                style: s.headerStyle,
                child: header!,
              ),
            ),
          ),
        DecoratedBox(
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: s.shadows ?? const [],
          ),
          child: Padding(
            padding: s.padding ?? EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) divider(children[i - 1]),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A settings-style row: icon, title, detail and chevron.
///
/// With [onPressed] the row is a button with a hover fill; without it, a static
/// row. [destructive] colors it as a danger action ("Oturumu kapat").
///
/// In a master-detail list (mail, files), [selected] marks the row whose
/// detail is open: it takes the theme's selection style, still answers
/// hover, and is announced as selected.
///
/// ```dart
/// DsListRow(
///   title: Text(mail.subject),
///   detail: Text(mail.time),
///   selected: mail.id == openId,
///   onPressed: () => open(mail.id),
/// )
/// ```
class DsListRow extends StatefulWidget {
  /// Creates a list row.
  const DsListRow({
    super.key,
    required this.title,
    this.leading,
    this.detail,
    this.trailing,
    this.showChevron = false,
    this.onPressed,
    this.destructive = false,
    this.selected = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The row's name.
  final Widget title;

  /// An icon before the title, usually a [DsIcon].
  final Widget? leading;

  /// A detail shown muted on the end side, such as the current setting
  /// ("Açık").
  final Widget? detail;

  /// A widget on the end side, e.g. a [DsSwitch] or a [DsBadge].
  final Widget? trailing;

  /// Shows a chevron: the row opens another page.
  final bool showChevron;

  /// Makes the row pressable.
  final VoidCallback? onPressed;

  /// Colors the row as a danger action.
  final bool destructive;

  /// Whether this is the current row of a list, e.g. the open message.
  final bool selected;

  /// Style laid over the theme and defaults.
  final DsListRowStyle? style;

  /// Focus node when the row is pressable; one is created when null.
  final FocusNode? focusNode;

  /// Whether a pressable row takes focus when first built.
  final bool autofocus;

  /// Overrides the label screen readers announce.
  final String? semanticLabel;

  /// Desen's default list row style under [theme]. [destructive] uses the
  /// danger text color for icon and title.
  static DsListRowStyle defaultStyle(
    DsThemeData theme, {
    bool destructive = false,
  }) {
    final k = theme.colors;
    return DsListRowStyle(
      height: theme.sizes.listRow,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s12),
      // Concentric with the section's card, inset by its padding.
      borderRadius: BorderRadius.circular(
        theme.radii.nested(theme.radii.card, DsSpace.s5),
      ),
      background: const Color(0x00000000),
      foreground: destructive ? k.danger.text : k.text,
      iconColor: destructive ? k.danger.text : k.textMuted,
      iconSize: 16,
      titleStyle: destructive
          ? theme.typography.body.copyWith(fontWeight: FontWeight.w500)
          : theme.typography.body,
      detailStyle: theme.typography.small.copyWith(color: k.textSubtle),
      // Wraps before it cuts: a long title at 320px or 2x text stays
      // readable (denetim-2 ux M3; it was cut to one line even at 1x).
      maxLines: 2,
      chevronColor: k.textSubtle,
      gap: DsSpace.s12,
      // Inside the row: rows run edge to edge in a rounded, clipped
      // section, which would cut an outside ring.
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      hovered: DsListRowStyle(background: k.hover),
      pressed: DsListRowStyle(background: k.press),
      selected: DsListRowStyle(
        background: theme.selectedFill,
        borderColor: theme.selectedEdge,
        // Every ink takes the selected label color: the muted and subtle
        // grays are tuned for the card, not for the selection fill.
        foreground: theme.onSelectedFill,
        iconColor: theme.onSelectedFill,
        detailStyle: TextStyle(color: theme.onSelectedFill),
        chevronColor: theme.onSelectedFill,
        // On a filled selection the accent ring would vanish; its label
        // color reads at 4.5:1.
        focusShadows: theme.fillsSelection
            ? [DsShadow.innerRing(theme.onSelectedFill, width: 2)]
            : null,
        // Hover stays visible on a selected row (K-61).
        hovered: DsListRowStyle(background: theme.selectedHoverFill),
      ),
      disabled: DsListRowStyle(
        foreground: k.onDisabled,
        iconColor: k.onDisabled,
      ),
    );
  }

  @override
  State<DsListRow> createState() => _DsListRowState();
}

class _DsListRowState extends State<DsListRow> {
  Set<WidgetState>? _lastStates;

  /// Keeps the row's widgets (e.g. a trailing switch) when [DsListRow.onPressed]
  /// turns on or off, which changes the tree around them.
  final _rowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final layers = [
      DsListRow.defaultStyle(t, destructive: widget.destructive),
      DsListRowTheme.of(context).style,
      widget.style,
    ];

    Widget row(Set<WidgetState> states, Duration duration) {
      final s = DsListRowStyle.resolveLayers(layers, states);
      return AnimatedContainer(
        key: _rowKey,
        duration: duration,
        curve: t.motion.toneCurve,
        constraints: BoxConstraints(minHeight: s.height!),
        padding: s.padding,
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: s.borderRadius ?? BorderRadius.zero,
          shadows: [
            if (s.borderColor case final edge? when edge.a > 0)
              DsShadow.innerRing(edge),
            if (states.contains(WidgetState.focused)) ...?s.focusShadows,
          ],
        ),
        // A long detail wraps, then ellipsizes, and leaves the title at least
        // half the row (B22).
        child: LayoutBuilder(
          builder: (context, c) => Row(
            spacing: s.gap ?? DsSpace.s12,
            children: [
              if (widget.leading != null)
                IconTheme.merge(
                  data: IconThemeData(color: s.iconColor, size: s.iconSize),
                  child: widget.leading!,
                ),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: (s.titleStyle ?? const TextStyle()).copyWith(
                    color: s.foreground,
                  ),
                  maxLines: s.maxLines,
                  overflow: TextOverflow.ellipsis,
                  child: widget.title,
                ),
              ),
              if (widget.detail != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: c.hasBoundedWidth
                        ? c.maxWidth / 2
                        : double.infinity,
                  ),
                  child: DefaultTextStyle.merge(
                    style: s.detailStyle,
                    maxLines: s.maxLines,
                    overflow: TextOverflow.ellipsis,
                    child: widget.detail!,
                  ),
                ),
              ?widget.trailing,
              if (widget.showChevron)
                DsIcon(
                  DsIcons.chevronRight,
                  size: s.iconSize!,
                  color: s.chevronColor,
                ),
            ],
          ),
        ),
      );
    }

    if (widget.onPressed == null) {
      return MergeSemantics(
        child: Semantics(
          selected: widget.selected ? true : null,
          child: row({
            if (widget.selected) WidgetState.selected,
          }, Duration.zero),
        ),
      );
    }
    return DsPressable(
      onPressed: widget.onPressed,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // Only a selected row says so: most lists have no selection.
      selected: widget.selected ? true : null,
      semanticLabel: widget.semanticLabel,
      minTapTarget: 0,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsListRowStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
        };
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        return row(states, animate ? t.motion.toneDuration : Duration.zero);
      },
    );
  }
}
