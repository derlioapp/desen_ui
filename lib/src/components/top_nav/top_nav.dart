import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/edge_fade_scroll.dart';
import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../behavior/reveal_in_row.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'top_nav_style.dart';

/// One destination of a [DsTopNav].
@immutable
class DsTopNavItem<T> {
  /// Creates a destination.
  const DsTopNavItem({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The value this destination selects.
  final T value;

  /// The label, usually a short [Text].
  final Widget label;

  /// An icon before the label, usually a [DsIcon].
  final Widget? icon;

  /// Overrides the label screen readers announce.
  final String? semanticLabel;

  /// Whether the destination can be chosen. A disabled one is dimmed,
  /// skipped by Tab and the arrow keys, ignores taps and is announced as
  /// disabled.
  final bool enabled;
}

/// A row of an app's destinations, for a header: the wide-screen
/// counterpart of [DsBottomNav], and the horizontal one of [DsSidebar].
///
/// It is navigation, not a choice: each destination swaps the page.
/// Choosing the current one reports it too ([onChanged]), so the app can
/// go back to that page's first screen or scroll it to the top, as a tab
/// bar does on iOS and Android and a link to a section's root does on the
/// web. To switch a panel within a page, use [DsTabs]; to choose a value,
/// [DsSegmentedControl].
///
/// The current destination takes the theme's selection, as a sidebar's
/// current page does. Labels keep one weight, so moving the selection
/// moves nothing beside it. Destinations that do not fit scroll; the edge
/// that hides them fades, and the current one, or the one that takes
/// keyboard focus, scrolls into view.
///
/// ```dart
/// DsTopNav<String>(
///   value: section,
///   onChanged: go,
///   items: const [
///     DsTopNavItem(value: 'radio', label: Text('Radio')),
///     DsTopNavItem(value: 'podcasts', label: Text('Podcasts')),
///     DsTopNavItem(value: 'library', label: Text('Library')),
///   ],
/// )
/// ```
///
/// **Screen readers** hear a navigation landmark named by [semanticLabel]
/// (the localized "Navigation" by default). Each destination is a button
/// announced with its label, whether it is the current one (selected; the
/// current item on the web) and its position ("2 of 4", localized), since
/// a button does not tell it.
///
/// **Keyboard:** the row is one Tab stop, the current destination (or the
/// first enabled one). Left and Right (mirrored in RTL) move focus to the
/// previous or next enabled destination, wrapping around; Home and End to
/// the first and last. Moving focus does not choose: Enter or Space
/// chooses the focused one. [focusNode] stands for the whole row: it has
/// focus while a destination does, and focusing it (or [autofocus])
/// focuses the current destination.
///
/// A tap plays the selection haptic, or the command one on the current
/// destination; the keyboard plays none.
class DsTopNav<T> extends StatefulWidget {
  /// Creates top navigation.
  const DsTopNav({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The destinations, start to end.
  final List<DsTopNavItem<T>> items;

  /// The current destination's value. A value that matches no destination
  /// marks none, e.g. on a page outside them.
  final T value;

  /// Called with the chosen destination's value. Null disables the row;
  /// [DsTopNavItem.enabled] disables one destination.
  ///
  /// Choosing the current destination calls it too, with the current
  /// value.
  final ValueChanged<T>? onChanged;

  /// Style laid over the theme and defaults.
  final DsTopNavStyle? style;

  /// Focus node for the row; one is created when null. See the class docs.
  final FocusNode? focusNode;

  /// Whether to focus the current destination when first built.
  final bool autofocus;

  /// Names the navigation for screen readers; the localized "Navigation"
  /// when null.
  final String? semanticLabel;

  /// Desen's default top navigation style under [theme].
  static DsTopNavStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsTopNavStyle(
      height: theme.sizes.sm,
      gap: DsSpace.s4,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s12),
      // No radius: the corners follow the resolved height.
      background: const Color(0x00000000),
      foreground: k.textMuted,
      iconSize: 16,
      iconGap: DsSpace.s8,
      textStyle: theme.typography.body.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      // Inside the item: the row scrolls, and its edges would cut a ring
      // drawn outside.
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      hovered: DsTopNavStyle(background: k.hover, foreground: k.text),
      pressed: DsTopNavStyle(background: k.press),
      selected: DsTopNavStyle(
        background: theme.selectedFill,
        borderColor: theme.selectedEdge,
        foreground: theme.onSelectedFill,
        // On a filled selection the accent ring would vanish; its label
        // color reads at 4.5:1.
        focusShadows: theme.fillsSelection
            ? [DsShadow.innerRing(theme.onSelectedFill, width: 2)]
            : null,
        // Hover stays visible on a selected item.
        hovered: DsTopNavStyle(background: theme.selectedHoverFill),
      ),
      // The disabled ink; the current destination of a disabled row keeps
      // its shape in the disabled fill.
      disabled: DsTopNavStyle(
        foreground: k.onDisabled,
        selected: DsTopNavStyle(
          background: k.disabled,
          borderColor: const Color(0x00000000),
        ),
      ),
    );
  }

  @override
  State<DsTopNav<T>> createState() => _DsTopNavState<T>();
}

class _DsTopNavState<T> extends State<DsTopNav<T>> {
  /// One node and one key per destination, by position.
  final _nodes = <FocusNode>[];
  final _keys = <GlobalKey>[];

  /// A reveal that found the row not laid out yet (a page built under a
  /// covering one): it runs when the row first reports its metrics.
  int Function()? _pendingReveal;

  @override
  void initState() {
    super.initState();
    _reveal(() => _current, animate: false);
  }

  @override
  void didUpdateWidget(DsTopNav<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _reveal(() => _current, animate: true);
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeAt(int i) {
    while (_nodes.length <= i) {
      _nodes.add(FocusNode(debugLabel: 'DsTopNav item'));
      _keys.add(GlobalKey());
    }
    return _nodes[i];
  }

  int get _current => widget.items.indexWhere((d) => d.value == widget.value);

  /// Whether destination [i] can be chosen.
  bool _enabledAt(int i) => widget.onChanged != null && widget.items[i].enabled;

  /// The destination that stands for the row's focus, its one Tab stop:
  /// the current one, or the first enabled one when it is not enabled; -1
  /// when none is.
  int get _tabStop {
    final current = _current;
    if (current >= 0 && _enabledAt(current)) return current;
    for (var i = 0; i < widget.items.length; i++) {
      if (_enabledAt(i)) return i;
    }
    return -1;
  }

  void _focus(int i) {
    _nodeAt(i).requestFocus();
    _reveal(() => i, animate: true);
  }

  void _focusCurrent() {
    final i = _tabStop;
    if (i >= 0) _focus(i);
  }

  /// After this frame's layout, scrolls the destination [index] gives into
  /// view ([revealInRow]).
  void _reveal(int Function() index, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final i = index();
      if (i < 0 || i >= _keys.length) return;
      if (!revealInRow(_keys[i].currentContext, animate: animate)) {
        _pendingReveal = index;
      }
    });
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
    if (target != null) _focus(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final DsTopNav(:items, :value, :onChanged, :style, :semanticLabel) = widget;
    final t = dsThemeOf(context);
    final layers = [
      DsTopNav.defaultStyle(t),
      DsTopNavTheme.of(context).style,
      style,
    ];
    final base = DsTopNavStyle.resolveLayers(layers, const {});
    // One Tab stop: the arrow keys reach the other destinations.
    final tabStop = _tabStop;
    for (var i = 0; i < items.length; i++) {
      _nodeAt(i).skipTraversal = i != tabStop;
    }
    final l10n = DsLocalizations.of(context);
    return Semantics(
      container: true,
      role: SemanticsRole.navigation,
      label: semanticLabel ?? l10n.navigation,
      explicitChildNodes: true,
      child: FocusForward(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocused: _focusCurrent,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          // Only the arrow keys: no node of its own, so the destinations
          // stay the landmark's direct children.
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: DsEdgeFade(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                final pending = _pendingReveal;
                if (pending != null) {
                  _pendingReveal = null;
                  _reveal(pending, animate: false);
                }
                return false;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: base.gap ?? 0,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _Item(
                        key: _keys[i],
                        item: items[i],
                        selected: items[i].value == value,
                        onPressed: _enabledAt(i)
                            ? () => onChanged!(items[i].value)
                            : null,
                        position: l10n.positionOf(i + 1, items.length),
                        focusNode: _nodeAt(i),
                        layers: layers,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatefulWidget {
  const _Item({
    super.key,
    required this.item,
    required this.selected,
    required this.onPressed,
    required this.position,
    required this.focusNode,
    required this.layers,
  });

  final DsTopNavItem<Object?> item;
  final bool selected;
  final VoidCallback? onPressed;

  /// The position phrase ("2 of 4") read after the label.
  final String position;
  final FocusNode focusNode;
  final List<DsTopNavStyle?> layers;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final item = widget.item;
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
      semanticLabel: switch (item.semanticLabel) {
        final label? => '$label\n${widget.position}',
        null => null,
      },
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsTopNavStyle.resolveLayers(widget.layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
        };
        final s = DsTopNavStyle.resolveLayers(widget.layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final fg = s.foreground ?? t.colors.text;
        final height = s.height ?? 0;
        // A minimum height that grows with large text.
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          constraints: BoxConstraints(minHeight: height),
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: t.radii.controlCorners(s.borderRadius, height),
            shadows: [
              if (s.borderColor case final edge? when edge.a > 0)
                DsShadow.innerRing(edge),
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: s.iconSize),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: s.iconGap ?? 0,
              children: [
                ?item.icon,
                Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    DefaultTextStyle.merge(
                      style: (s.textStyle ?? const TextStyle()).copyWith(
                        color: fg,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      child: item.label,
                    ),
                    // Read after the label, which it follows in the tree.
                    if (item.semanticLabel == null)
                      Semantics(label: widget.position),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
