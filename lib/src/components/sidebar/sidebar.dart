import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../overlay/placement.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../badge/badge.dart';
import '../tooltip/tooltip.dart';
import 'sidebar_item_style.dart';
import 'sidebar_style.dart';

/// Side navigation that runs edge to edge, not floating.
///
/// Give it the full height, e.g. as the first child of a [Row] with
/// `crossAxisAlignment: CrossAxisAlignment.stretch`. Contents scroll when
/// they do not fit.
///
/// Give each item a [DsSidebarItem.value] and the sidebar the current
/// [value] and [onChanged]: the matching item is selected and pressing an
/// item reports its value. (Items can also take `selected` and `onPressed`
/// themselves.)
///
/// ```dart
/// DsSidebar<String>(
///   value: page,
///   onChanged: go,
///   collapsed: narrow,
///   children: const [
///     DsSidebarItem(value: 'inbox', leading: DsIcon(DsIcons.inbox),
///         label: Text('Gelen'), count: 4),
///     DsSidebarSection(label: Text('EKİPLER')),
///     DsSidebarItem(value: 'design', leading: DsIcon(DsIcons.folder),
///         label: Text('Tasarım')),
///   ],
/// )
/// ```
///
/// **Collapsed** ([collapsed]), the sidebar narrows to a rail of icons:
/// each item shows its icon alone and its label as a tooltip on hover and
/// keyboard focus, a count becomes a dot, and a section label becomes a
/// line. Screen readers still hear every label and count. The width
/// change moves with the theme's motion (at once under reduced motion);
/// icons stay where they are while it does. The app owns the state, e.g.
/// a toolbar button that toggles it, or a narrow window.
class DsSidebar<T extends Object> extends StatelessWidget {
  /// Creates a sidebar.
  const DsSidebar({
    super.key,
    required this.children,
    this.header,
    this.collapsed = false,
    this.value,
    this.onChanged,
    this.style,
    this.semanticLabel,
  });

  /// Items and section labels, top to bottom.
  final List<Widget> children;

  /// Shown above the items, e.g. a workspace switcher. It stays as given
  /// when [collapsed]; read [collapsedOf] to show a smaller one.
  final Widget? header;

  /// Narrows the sidebar to a rail of icons, labels as tooltips.
  final bool collapsed;

  /// The current page: the item with this [DsSidebarItem.value] is
  /// selected. Null selects none.
  final T? value;

  /// Called with an item's [DsSidebarItem.value] when it is pressed. Items
  /// with a value and no `onPressed` of their own are disabled when null.
  final ValueChanged<T>? onChanged;

  /// Style laid over the theme and defaults.
  final DsSidebarStyle? style;

  /// Names the navigation for screen readers.
  final String? semanticLabel;

  /// Whether the nearest [DsSidebar] around [context] is collapsed; false
  /// outside one. For custom children, such as a header that shrinks to a
  /// logo.
  static bool collapsedOf(BuildContext context) =>
      _DsSidebarScope.maybeOf(context)?.collapsed ?? false;

  /// Desen's default sidebar style under [theme].
  static DsSidebarStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsSidebarStyle(
      width: 220,
      // Item padding and the 16px icon inside the sidebar padding, on both
      // sides: the icon is centered and does not move as the sidebar
      // collapses.
      collapsedWidth: 2 * (DsSpace.s12 + DsSpace.s8) + 16,
      background: k.sidebar,
      shadows: theme.shadows.sidebarEdge,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s16,
      ),
      gap: 2,
      sectionStyle: theme.typography.overline.copyWith(color: k.textSubtle),
      sectionPadding: const EdgeInsetsDirectional.fromSTEB(
        DsSpace.s8,
        DsSpace.s16,
        DsSpace.s8,
        DsSpace.s6,
      ),
      dividerColor: k.border,
      dividerPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsSidebarStyle.resolveLayers([
      defaultStyle(t),
      DsSidebarTheme.of(context).style,
      style,
    ], const {});
    final target = collapsed ? s.collapsedWidth! : s.width!;
    final onChanged = this.onChanged;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: _DsSidebarScope(
        collapsed: collapsed,
        value: value,
        source: onChanged,
        onChanged: onChanged == null ? null : (v) => onChanged(v as T),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: t.motion.moveDuration,
          curve: t.motion.moveCurve,
          builder: (context, width, child) {
            // While the width moves, the contents are laid out at no less
            // than the target width and clipped: opening uncovers full rows
            // instead of squeezing them, and a spring that dips under the
            // rail width cuts the edge rather than the layout.
            final moving = width != target;
            final layout = math.max(width, target);
            return DecoratedBox(
              decoration: DsBoxDecoration(
                color: s.background,
                shadows: s.shadows ?? const [],
              ),
              child: SizedBox(
                width: width,
                child: ClipRect(
                  clipBehavior: moving ? Clip.hardEdge : Clip.none,
                  child: OverflowBox(
                    alignment: AlignmentDirectional.topStart,
                    minWidth: moving ? layout : null,
                    maxWidth: moving ? layout : null,
                    fit: OverflowBoxFit.deferToChild,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: DsSidebarTheme(
            data: DsSidebarThemeData(style: s),
            child: SingleChildScrollView(
              padding: s.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: s.gap!,
                children: [?header, ...children],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a [DsSidebar] tells its items: collapsed or not, and the current
/// value.
class _DsSidebarScope extends InheritedWidget {
  const _DsSidebarScope({
    required this.collapsed,
    required this.value,
    required this.source,
    required this.onChanged,
    required super.child,
  });

  final bool collapsed;
  final Object? value;

  /// The sidebar's own callback, compared to tell when it changed.
  final Function? source;

  /// [source], typed for the items.
  final ValueChanged<Object?>? onChanged;

  static _DsSidebarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DsSidebarScope>();

  @override
  bool updateShouldNotify(_DsSidebarScope old) =>
      collapsed != old.collapsed || value != old.value || source != old.source;
}

/// The text of [label] when it is a [Text], else null.
String? _plainText(Widget label) => switch (label) {
  Text(:final data?) => data,
  Text(:final textSpan?) => textSpan.toPlainText(),
  _ => null,
};

/// A section label inside a [DsSidebar] ("EKİPLER"). Shown as given.
///
/// In a collapsed sidebar it becomes a short line in the label's place,
/// so the items below do not move; screen readers still hear the label as
/// a heading.
class DsSidebarSection extends StatelessWidget {
  /// Creates a section label.
  const DsSidebarSection({super.key, required this.label});

  /// The label, usually a short [Text].
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsSidebarStyle.resolveLayers([
      DsSidebar.defaultStyle(t),
      DsSidebarTheme.of(context).style,
    ], const {});
    final collapsed = DsSidebar.collapsedOf(context);
    final text = Padding(
      padding: s.sectionPadding ?? EdgeInsets.zero,
      child: Semantics(
        header: true,
        child: DefaultTextStyle.merge(
          style: s.sectionStyle,
          // Collapsed, the hidden label keeps one line of height.
          maxLines: collapsed ? 1 : null,
          softWrap: !collapsed,
          overflow: collapsed ? TextOverflow.clip : null,
          child: label,
        ),
      ),
    );
    if (!collapsed) return text;
    return Stack(
      children: [
        Opacity(opacity: 0, alwaysIncludeSemantics: true, child: text),
        Positioned.fill(
          child: Padding(
            padding: s.dividerPadding ?? EdgeInsets.zero,
            child: Center(
              child: DsLine(color: s.dividerColor ?? const Color(0x00000000)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A navigation item in a [DsSidebar]. The selected item takes the theme's
/// selection style.
///
/// It is selected when [selected] is true or its [value] is the sidebar's
/// [DsSidebar.value]. Pressing it reports [value] to
/// [DsSidebar.onChanged], then calls [onPressed].
///
/// In a collapsed sidebar it needs a [leading] icon, and a [Text] [label]
/// or a [semanticLabel] for its tooltip.
class DsSidebarItem<T extends Object> extends StatefulWidget {
  /// Creates a sidebar item.
  const DsSidebarItem({
    super.key,
    required this.label,
    this.value,
    this.leading,
    this.count,
    this.selected = false,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The label, usually a short [Text].
  final Widget label;

  /// Identifies the item to [DsSidebar.value] and [DsSidebar.onChanged].
  final T? value;

  /// An icon before the label, usually a [DsIcon] (or a color dot). The
  /// only thing shown when the sidebar is collapsed.
  final Widget? leading;

  /// A count on the end side (e.g. unread items). Above 99 it shows and
  /// announces "99+", like every count in the library ([DsCount.text]).
  /// A collapsed sidebar shows a dot for it.
  final int? count;

  /// Whether this is the current page, besides matching [DsSidebar.value].
  final bool selected;

  /// Called when the item is chosen. With neither this nor a [value] the
  /// sidebar reports (see [DsSidebar.onChanged]), the item is disabled.
  final VoidCallback? onPressed;

  /// Style laid over the theme and defaults.
  final DsSidebarItemStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Overrides the label screen readers announce.
  final String? semanticLabel;

  /// Desen's default sidebar item style under [theme].
  static DsSidebarItemStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsSidebarItemStyle(
      height: theme.sizes.row,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s8),
      // No radius: the corners follow the resolved height.
      background: const Color(0x00000000),
      foreground: k.textMuted,
      iconSize: 16,
      textStyle: theme.typography.body.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      countStyle: theme.typography.numeric(
        theme.typography.fieldLabel.copyWith(color: k.textSubtle),
      ),
      dotSize: 6,
      gap: DsSpace.s12,
      // Inside the row: items run edge to edge in a narrow, often clipped
      // column, where an outside ring would be cut or touch its neighbors.
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      hovered: DsSidebarItemStyle(background: k.hover, foreground: k.text),
      pressed: DsSidebarItemStyle(background: k.press),
      selected: DsSidebarItemStyle(
        background: theme.selectedFill,
        borderColor: theme.selectedEdge,
        foreground: theme.onSelectedFill,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        // The count takes the label's ink: the subtle gray would sink into
        // the fill (under 1.2:1 on a light accent fill).
        countStyle: TextStyle(color: theme.onSelectedFill),
        // On a filled selection the accent ring would vanish; its label
        // color reads at 4.5:1.
        focusShadows: theme.fillsSelection
            ? [DsShadow.innerRing(theme.onSelectedFill, width: 2)]
            : null,
        // Hover stays visible on a selected item (K-61).
        hovered: DsSidebarItemStyle(background: theme.selectedHoverFill),
      ),
      disabled: DsSidebarItemStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsSidebarItem<T>> createState() => _DsSidebarItemState<T>();
}

class _DsSidebarItemState<T extends Object> extends State<DsSidebarItem<T>> {
  Set<WidgetState>? _lastStates;

  /// Keeps the pressable (and its focus) when collapsing wraps it in a
  /// tooltip.
  final _pressableKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final scope = _DsSidebarScope.maybeOf(context);
    final collapsed = scope?.collapsed ?? false;
    final value = widget.value;
    final selected =
        widget.selected || (value != null && scope?.value == value);
    final report = value == null ? null : scope?.onChanged;
    final onPressed = report == null && widget.onPressed == null
        ? null
        : () {
            report?.call(value);
            widget.onPressed?.call();
          };
    final text = _plainText(widget.label);
    assert(
      !collapsed || widget.leading != null,
      'A collapsed DsSidebar shows only icons: give the item a leading icon.',
    );
    assert(
      !collapsed || text != null || widget.semanticLabel != null,
      'A collapsed DsSidebar shows labels as tooltips: give the item a Text '
      'label or a semanticLabel.',
    );
    final layers = [
      DsSidebarItem.defaultStyle(t),
      DsSidebarItemTheme.of(context).style,
      widget.style,
    ];
    final pressable = DsPressable(
      key: _pressableKey,
      onPressed: onPressed,
      // Moving to another page ticks; pressing the current one again is a
      // command.
      haptic: selected ? DsHapticEvent.command : DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      selected: selected,
      semanticLabel: widget.semanticLabel,
      minTapTarget: 0,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsSidebarItemStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {...interaction, if (selected) WidgetState.selected};
        final s = DsSidebarItemStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final fg = s.foreground ?? t.colors.text;
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          constraints: BoxConstraints(minHeight: s.height!),
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: t.radii.controlCorners(s.borderRadius, s.height!),
            shadows: [
              if (s.borderColor case final edge? when edge.a > 0)
                DsShadow.innerRing(edge),
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: s.iconSize),
            child: collapsed
                ? _rail(context, s, text)
                : Row(
                    spacing: s.gap ?? DsSpace.s12,
                    children: [
                      ?widget.leading,
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: (s.textStyle ?? const TextStyle()).copyWith(
                            color: fg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: widget.label,
                        ),
                      ),
                      if (widget.count != null)
                        Text(
                          DsCount.text(context, widget.count!),
                          style: s.countStyle,
                        ),
                    ],
                  ),
          ),
        );
      },
    );
    if (!collapsed) return pressable;
    return DsTooltip(
      message: text ?? widget.semanticLabel ?? '',
      side: DsSide.end,
      // The item announces its label itself.
      excludeFromSemantics: true,
      child: pressable,
    );
  }

  /// The collapsed item: the icon at the start, where it sits in the full
  /// row, and a dot on its corner for the count. The label and count stay
  /// in the semantics.
  Widget _rail(BuildContext context, DsSidebarItemStyle s, String? text) {
    final dot = s.dotSize ?? 0;
    Widget icon = widget.leading ?? const SizedBox.shrink();
    if (widget.count case final count?) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          PositionedDirectional(
            top: -dot / 2,
            end: -dot / 2,
            child: Semantics(
              label: DsCount.text(context, count),
              child: Container(
                width: dot,
                height: dot,
                decoration: DsBoxDecoration(
                  color: s.countStyle?.color,
                  borderRadius: BorderRadius.circular(dot / 2),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(label: text, child: icon),
    );
  }
}
