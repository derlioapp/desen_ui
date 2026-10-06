import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../tooltip/tooltip.dart';
import 'bottom_nav_item_style.dart';
import 'bottom_nav_style.dart';

/// How a [DsBottomNav] sits on the screen.
enum DsBottomNavVariant {
  /// An opaque bar floating above the content, items filled when selected.
  floating,

  /// Edge to edge along the bottom with a hairline on top and the safe
  /// area below (18b). The selected item is filled like the floating
  /// bar's, inset from the bar's edges.
  bar,
}

/// One destination of a [DsBottomNav].
@immutable
class DsBottomNavItem<T> {
  /// Creates a destination.
  const DsBottomNavItem({
    required this.value,
    required this.icon,
    required this.label,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The value this destination selects.
  final T value;

  /// Usually a [DsIcon].
  final Widget icon;

  /// A short label under the icon.
  final Widget label;

  /// Overrides the label screen readers announce.
  final String? semanticLabel;

  /// Whether the destination can be chosen. A disabled one is dimmed,
  /// skipped by Tab and the arrow keys, ignores taps and is announced as
  /// disabled.
  final bool enabled;
}

/// Bottom navigation for phone layouts.
///
/// Items of the floating bar are [DsBottomNavItemStyle.width] wide and
/// share the width evenly when that does not fit (five items on a 375pt
/// phone). Items grow taller with large text. A label wider than its item
/// wraps onto a second line between words, and every item then keeps
/// room for two lines, so the bar stays even. A label that still does not
/// fit (a long word, very large text) ellipsizes, and the item shows the
/// whole label in a tooltip on a long press, on hover and on keyboard
/// focus; screen readers always get the whole label.
///
/// ```dart
/// DsBottomNav<String>(
///   value: tab,
///   onChanged: (v) => setState(() => tab = v),
///   items: const [
///     DsBottomNavItem(value: 'home', icon: DsIcon(DsIcons.house), label: Text('Ana sayfa')),
///     DsBottomNavItem(value: 'inbox', icon: DsIcon(DsIcons.inbox), label: Text('Gelen')),
///   ],
/// )
/// ```
///
/// **Keyboard:** the bar is one Tab stop, the current destination (or the
/// first enabled one). Left and Right (mirrored in RTL) move focus to the
/// previous or next enabled destination, wrapping around; Home and End to
/// the first and last. Moving focus does not choose: each destination
/// swaps the whole screen, so Enter or Space chooses the focused one.
/// [focusNode] stands for the whole bar: it has focus while a destination
/// does, and focusing it (or [autofocus]) focuses the current destination.
///
/// **Screen readers:** the bar is a navigation landmark named by
/// [semanticLabel] (the localized "Navigation" by default). Each
/// destination is a button that swaps the screen, as links in a web
/// navigation do (not a tab: tabs switch panels within a page), announced
/// with its label, whether it is the current one (selected; the current
/// item on the web) and its position ("2 of 4", localized) on every
/// platform, since a button does not tell it.
///
/// A tap plays the selection haptic, or the command one on the current
/// destination (e.g. back to the top); the keyboard plays none.
class DsBottomNav<T> extends StatefulWidget {
  /// Creates bottom navigation.
  const DsBottomNav({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.variant,
    this.style,
    this.itemStyle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The destinations, start to end.
  final List<DsBottomNavItem<T>> items;

  /// The current destination's value.
  final T value;

  /// Called with the chosen destination's value. Null disables the bar;
  /// [DsBottomNavItem.enabled] disables one destination.
  final ValueChanged<T>? onChanged;

  /// Floating bar or full-width bar. Null uses
  /// [DsBottomNavThemeData.variant], else [DsBottomNavVariant.floating].
  final DsBottomNavVariant? variant;

  /// Container style laid over the theme and defaults.
  final DsBottomNavStyle? style;

  /// Item style laid over the theme and defaults.
  final DsBottomNavItemStyle? itemStyle;

  /// Focus node for the bar; one is created when null. See the class docs.
  final FocusNode? focusNode;

  /// Whether to focus the current destination when first built.
  final bool autofocus;

  /// Names the navigation for screen readers; the localized "Navigation"
  /// when null.
  final String? semanticLabel;

  /// Desen's default container style under [theme] for [variant].
  ///
  /// The floating bar's corners are left unset: it is rounded as a control
  /// as tall as its items and padding (a capsule in the pill style), so an
  /// item height set in a style or theme keeps the bar and its items
  /// concentric. A radius set in a style wins.
  static DsBottomNavStyle defaultStyle(
    DsThemeData theme, {
    required DsBottomNavVariant variant,
  }) {
    final k = theme.colors;
    return switch (variant) {
      DsBottomNavVariant.floating => DsBottomNavStyle(
        background: k.overlay,
        shadows: theme.shadows.overlay,
        padding: const EdgeInsets.all(DsSpace.s5),
        gap: 2,
      ),
      DsBottomNavVariant.bar => DsBottomNavStyle(
        background: k.overlay,
        shadows: [DsShadow.topLine(k.border, hairline: true)],
        // Even above and below, so the selected fill sits centered and
        // clear of the hairline; the safe area adds to the bottom.
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpace.s8,
          vertical: DsSpace.s6,
        ),
        gap: 0,
      ),
    };
  }

  /// Desen's default item style under [theme] for [variant].
  ///
  /// Both variants mark the selected item the same way: the whole item
  /// filled with the theme's selection, its icon and label in the selection
  /// ink at weight 600. Set [DsBottomNavItemStyle.capsuleSize] for a
  /// capsule behind the icon instead.
  static DsBottomNavItemStyle defaultItemStyle(
    DsThemeData theme, {
    required DsBottomNavVariant variant,
  }) {
    final k = theme.colors;
    final floating = variant == DsBottomNavVariant.floating;
    return DsBottomNavItemStyle(
      width: floating ? 72 : null,
      height: floating ? 50 : 52,
      // Unset: concentric with the floating bar, and on the flat bar a
      // control of whatever height the layers settle on.
      background: const Color(0x00000000),
      foreground: k.textMuted,
      iconSize: 20,
      labelStyle: theme.typography.overline.copyWith(letterSpacing: 0),
      focusShadows: theme.focusShadows,
      hovered: DsBottomNavItemStyle(foreground: k.text),
      selected: DsBottomNavItemStyle(
        background: theme.selectedFill,
        // A bright filled selection keeps its edge off a light bar.
        borderColor: theme.selectedEdge,
        foreground: theme.onSelectedFill,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        // Hover stays visible on a selected item (K-61).
        hovered: DsBottomNavItemStyle(background: theme.selectedHoverFill),
      ),
      // The disabled ink; the current destination of a disabled bar keeps
      // its shape in the disabled fill.
      disabled: DsBottomNavItemStyle(
        foreground: k.onDisabled,
        selected: DsBottomNavItemStyle(
          background: k.disabled,
          borderColor: const Color(0x00000000),
        ),
      ),
    );
  }

  @override
  State<DsBottomNav<T>> createState() => _DsBottomNavState<T>();

  static Widget _wrap(bool bar, bool bounded, Widget item) => !bounded
      ? item
      : bar
      ? Expanded(child: item)
      : Flexible(child: item);
}

/// How a destination's label fits the [width] it gets: on one line, on two
/// lines broken between words, or [cut] (one line, ellipsized). [height]
/// is the label's height as laid out.
typedef _LabelFit = ({int lines, bool cut, double height});

/// Measures [label] in [style] (the selected one, the widest) for [width].
/// Null when it cannot be measured (not a plain [Text], or no width
/// limit): the label then keeps to one line, as given.
_LabelFit? _fitLabel(
  BuildContext context,
  Widget label,
  TextStyle? style,
  double width,
) {
  if (label is! Text || label.data == null) return null;
  if (!width.isFinite || width <= 0) return null;
  final painter = TextPainter(
    text: TextSpan(
      text: label.data,
      style: DefaultTextStyle.of(context).style.merge(style).merge(label.style),
    ),
    textDirection: Directionality.of(context),
    textScaler: label.textScaler ?? MediaQuery.textScalerOf(context),
    locale: label.locale ?? Localizations.maybeLocaleOf(context),
    maxLines: 2,
  )..layout(maxWidth: width);
  // A word wider than the line would break inside: keep to one line.
  if (painter.minIntrinsicWidth > width) {
    painter
      ..maxLines = 1
      ..layout(maxWidth: width);
  }
  final fit = (
    lines: painter.computeLineMetrics().length.clamp(1, 2),
    cut: painter.didExceedMaxLines,
    height: painter.height,
  );
  painter.dispose();
  return fit;
}

class _DsBottomNavState<T> extends State<DsBottomNav<T>> {
  /// One node per destination, by position.
  final _nodes = <FocusNode>[];

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeAt(int i) {
    while (_nodes.length <= i) {
      _nodes.add(FocusNode(debugLabel: 'DsBottomNav item'));
    }
    return _nodes[i];
  }

  /// Whether destination [i] can be chosen.
  bool _enabledAt(int i) => widget.onChanged != null && widget.items[i].enabled;

  /// The destination that stands for the bar's focus, its one Tab stop:
  /// the current one, or the first enabled one when it is not enabled; -1
  /// when none is.
  int get _tabStop {
    final items = widget.items;
    final current = items.indexWhere((d) => d.value == widget.value);
    if (current >= 0 && _enabledAt(current)) return current;
    for (var i = 0; i < items.length; i++) {
      if (_enabledAt(i)) return i;
    }
    return -1;
  }

  void _focusCurrent() {
    final i = _tabStop;
    if (i >= 0) _nodeAt(i).requestFocus();
  }

  /// The next enabled destination from [from] in [step], wrapping around.
  int? _step(int from, int step) {
    final n = widget.items.length;
    var i = from;
    for (var tries = 0; tries < n; tries++) {
      i = (i + step) % n;
      if (i < 0) i += n;
      if (_enabledAt(i)) return i;
    }
    return null;
  }

  /// Left and Right (mirrored in RTL), Home and End move focus between the
  /// destinations; Enter and Space (on the destination) choose.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.items.length;
    final focused = _nodes.indexWhere((node) => node.hasPrimaryFocus);
    if (focused < 0 || focused >= n) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final int? target;
    if (key == LogicalKeyboardKey.arrowRight) {
      target = _step(focused, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      target = _step(focused, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      target = _step(n - 1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      target = _step(0, -1);
    } else {
      return KeyEventResult.ignored;
    }
    if (target != null) _nodeAt(target).requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final DsBottomNav(
      :items,
      :value,
      :onChanged,
      :style,
      :itemStyle,
      :semanticLabel,
    ) = widget;
    final t = dsThemeOf(context);
    final theme = DsBottomNavTheme.of(context);
    final itemTheme = DsBottomNavItemTheme.of(context);
    final variant =
        widget.variant ?? theme.variant ?? DsBottomNavVariant.floating;
    final s = DsBottomNavStyle.resolveLayers([
      DsBottomNav.defaultStyle(t, variant: variant),
      theme.style,
      theme.variants[variant],
      style,
    ], const {});
    final itemLayers = [
      DsBottomNav.defaultItemStyle(t, variant: variant),
      itemTheme.style,
      itemTheme.variants[variant],
      itemStyle,
    ];
    final bar = variant == DsBottomNavVariant.bar;
    final padding = (s.padding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    // The floating bar is rounded as a control as tall as its items and
    // padding; its items nest in it. The flat bar has square ends.
    final itemHeight =
        DsBottomNavItemStyle.resolveLayers(itemLayers, const {}).height ?? 0;
    final corners = bar
        ? s.borderRadius ?? BorderRadius.zero
        : t.radii.controlCorners(s.borderRadius, itemHeight + padding.vertical);
    // One Tab stop: the arrow keys reach the other destinations.
    final tabStop = _tabStop;
    for (var i = 0; i < items.length; i++) {
      _nodeAt(i).skipTraversal = i != tabStop;
    }
    final l10n = DsLocalizations.of(context);
    // The selected label is the widest (bolder); it sizes the fit.
    final widest = DsBottomNavItemStyle.resolveLayers(itemLayers, const {
      WidgetState.selected,
    });
    // The full-width bar shares its width; the floating one sizes to its
    // items, which may shrink to share a narrow width (B11, visual H2).
    final row = LayoutBuilder(
      builder: (context, c) {
        final gaps = (s.gap ?? 0) * (items.length - 1);
        final share = c.hasBoundedWidth
            ? (c.maxWidth - gaps) / items.length
            : double.infinity;
        final itemWidth = switch (widest.width) {
          final w? when w < share => w,
          _ => share,
        };
        final fits = [
          for (final item in items)
            _fitLabel(
              context,
              item.label,
              widest.labelStyle,
              itemWidth - 2 * _Item.padding,
            ),
        ];
        // When one label takes two lines, every item keeps room for them,
        // so the items and their fills stay one height.
        final twoLines = fits.any((f) => f != null && f.lines > 1);
        final labelHeight = twoLines
            ? fits.fold(0.0, (h, f) => f != null && f.height > h ? f.height : h)
            : null;
        return Row(
          mainAxisSize: bar ? MainAxisSize.max : MainAxisSize.min,
          spacing: s.gap ?? 0,
          children: [
            for (var i = 0; i < items.length; i++)
              DsBottomNav._wrap(
                bar,
                c.hasBoundedWidth,
                _Item(
                  item: items[i],
                  selected: items[i].value == value,
                  onPressed: _enabledAt(i)
                      ? () => onChanged!(items[i].value)
                      : null,
                  // A button does not tell its place: read it after the
                  // label, on every platform.
                  position: l10n.positionOf(i + 1, items.length),
                  focusNode: _nodeAt(i),
                  layers: itemLayers,
                  barCorners: bar ? null : corners,
                  inset: padding.top,
                  // An unmeasured label keeps to one line.
                  // ds-raw: a line count, not a size.
                  labelLines: fits[i]?.lines ?? 1,
                  labelHeight: labelHeight,
                  cut: fits[i]?.cut ?? false,
                ),
              ),
          ],
        );
      },
    );
    return Semantics(
      container: true,
      role: SemanticsRole.navigation,
      label: semanticLabel ?? l10n.navigation,
      explicitChildNodes: true,
      child: DsSurface(
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: corners,
          shadows: s.shadows ?? const [],
        ),
        backdropFilter: s.backdropFilter,
        child: Padding(
          // The full-width bar keeps clear of the home indicator.
          padding: bar
              ? padding.copyWith(
                  bottom: padding.bottom + MediaQuery.paddingOf(context).bottom,
                )
              : padding,
          child: FocusForward(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onFocused: _focusCurrent,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              // Only the arrow keys: no node of its own, so the
              // destinations stay the landmark's direct children.
              includeSemantics: false,
              onKeyEvent: _onKey,
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatefulWidget {
  const _Item({
    required this.item,
    required this.selected,
    required this.onPressed,
    required this.position,
    required this.focusNode,
    required this.layers,
    required this.barCorners,
    required this.inset,
    required this.labelLines,
    required this.labelHeight,
    required this.cut,
  });

  /// Space on each side of the item's content: a long label wraps or
  /// ellipsizes before it meets the fill's edge.
  static const padding = DsSpace.s4;

  final DsBottomNavItem<Object?> item;
  final bool selected;
  final VoidCallback? onPressed;

  /// The position phrase ("2 of 4") read after the label.
  final String position;
  final FocusNode focusNode;
  final List<DsBottomNavItemStyle?> layers;

  /// The floating bar's corners, which the item nests in by [inset]; null
  /// on the flat bar, where the item is rounded as a control.
  final BorderRadiusGeometry? barCorners;
  final double inset;

  /// Lines the label may take: two when it wraps between words.
  final int labelLines;

  /// Height every item keeps for its label, so the items stay even when
  /// one label wraps; null to fit the label.
  final double? labelHeight;

  /// Whether the label is cut: the whole label then shows in a tooltip.
  final bool cut;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final item = _item(context);
    final label = widget.item.label;
    // A cut label shows whole in a tooltip: on a long press on touch
    // screens, on hover and on keyboard focus. Screen readers already read
    // the whole label, so the tooltip is not announced again.
    if (widget.cut && label is Text && label.data != null) {
      return DsTooltip(
        message: label.data!,
        excludeFromSemantics: true,
        child: item,
      );
    }
    return item;
  }

  Widget _item(BuildContext context) {
    final t = dsThemeOf(context);
    return DsPressable(
      onPressed: widget.onPressed,
      // Moving to another destination ticks; pressing the current one again
      // is a command (e.g. back to the top).
      haptic: widget.selected ? DsHapticEvent.command : DsHapticEvent.selection,
      focusNode: widget.focusNode,
      // A button with the current destination selected (the current item
      // on the web), in the navigation landmark.
      selected: widget.selected,
      // A label set for screen readers replaces the text inside, so the
      // position goes with it.
      semanticLabel: switch (widget.item.semanticLabel) {
        final label? => '$label\n${widget.position}',
        null => null,
      },
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsBottomNavItemStyle.resolveLayers(widget.layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
        };
        final s = DsBottomNavItemStyle.resolveLayers(widget.layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final duration = animate ? t.motion.toneDuration : Duration.zero;
        final fg = s.foreground ?? t.colors.text;
        final radius = switch (widget.barCorners) {
          final outer? => t.radii.nestedCorners(
            s.borderRadius,
            outer,
            widget.inset,
          ),
          null => t.radii.controlCorners(s.borderRadius, s.height ?? 0),
        };
        final focus = [
          if (s.borderColor case final edge? when edge.a > 0)
            DsShadow.innerRing(edge),
          if (states.contains(WidgetState.focused)) ...?s.focusShadows,
        ];
        final capsule = s.capsuleSize;
        Widget icon = IconTheme.merge(
          data: IconThemeData(color: fg, size: s.iconSize),
          child: widget.item.icon,
        );
        if (capsule != null) {
          icon = AnimatedContainer(
            duration: duration,
            curve: t.motion.toneCurve,
            width: capsule.width,
            height: capsule.height,
            alignment: Alignment.center,
            decoration: DsBoxDecoration(
              color: s.background,
              borderRadius: radius,
              shadows: focus,
            ),
            child: icon,
          );
        }
        // A fixed width that a narrow bar may shrink, and a minimum height
        // that grows with large text (B12).
        return AnimatedContainer(
          duration: duration,
          curve: t.motion.toneCurve,
          constraints: BoxConstraints(
            minWidth: s.width ?? 0,
            maxWidth: s.width ?? double.infinity,
            minHeight: s.height ?? 0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: _Item.padding),
          decoration: capsule == null
              ? DsBoxDecoration(
                  color: s.background,
                  borderRadius: radius,
                  shadows: focus,
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: DsSpace.s4,
            children: [
              icon,
              Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.labelHeight case final height?)
                    SizedBox(height: height),
                  DefaultTextStyle.merge(
                    style: (s.labelStyle ?? const TextStyle()).copyWith(
                      color: fg,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: widget.labelLines,
                    overflow: TextOverflow.ellipsis,
                    child: widget.item.label,
                  ),
                  // Read after the label, which it follows in the tree.
                  if (widget.item.semanticLabel == null)
                    Semantics(label: widget.position),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
