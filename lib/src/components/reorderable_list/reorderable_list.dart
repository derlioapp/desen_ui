import 'dart:ui' show lerpDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_ring.dart';
import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../behavior/min_tap_target.dart';
import '../../foundation/platform.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/direction.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'reorderable_list_style.dart';

/// A scrolling list whose items people put in their own order: favorites,
/// a playlist, a task list, the order of a menu.
///
/// Each item gets a grip handle at its end. Drag the handle to move the
/// item; on iOS and Android a long press anywhere on the item lifts it
/// too. The lifted item floats above the others, which make room, and the
/// list scrolls when it is dragged near an edge. A lift and a drop each
/// tick as the platform's selection haptic. Under reduced motion the
/// lifted item does not grow; the others still slide to make room, as
/// Flutter 3.47's reorderable list has no setting for that motion.
///
/// Without a pointer:
/// - **Keyboard:** the handle is a Tab stop; Up and Down move its item one
///   place, Home and End to the start or the end. From anywhere inside an
///   item (a focused row), Alt+Up and Alt+Down move it too. Focus stays
///   on the moved item.
/// - **Screen readers:** each item has the actions "Move up", "Move down",
///   "Move to the start" and "Move to the end" (in the app's language
///   under `DsApp`); the handle itself is not announced.
///
/// The app owns the data: [onReorder] gets the item's index and the index
/// it ends up at (counted after the move, so `items.insert(to,
/// items.removeAt(from))` does it). Every item needs a [Key] that stays
/// with it as it moves, such as `ValueKey(item.id)`. A null [onReorder]
/// turns reordering off: no handles, no actions, a plain list, as a list
/// out of its edit mode.
///
/// ```dart
/// DsReorderableList(
///   itemCount: favorites.length,
///   itemBuilder: (context, i) => DsListRow(
///     key: ValueKey(favorites[i].id),
///     title: Text(favorites[i].name),
///   ),
///   onReorder: (from, to) => setState(
///     () => favorites.insert(to, favorites.removeAt(from)),
///   ),
/// )
/// ```
class DsReorderableList extends StatefulWidget {
  /// Creates a reorderable list.
  const DsReorderableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.style,
  });

  /// How many items there are.
  final int itemCount;

  /// Builds item [index]. Each item needs a [Key] that moves with it.
  final IndexedWidgetBuilder itemBuilder;

  /// Called when an item moves from index `from` to index `to`, both
  /// counted as the list is after the move. Null turns reordering off.
  final void Function(int from, int to)? onReorder;

  /// Controls the scroll position; one is created when null.
  final ScrollController? controller;

  /// How the list scrolls.
  final ScrollPhysics? physics;

  /// Whether the list takes the height of its items instead of filling
  /// the space it is given, e.g. inside a page that scrolls as a whole.
  final bool shrinkWrap;

  /// Space around the items, inside the scrolling area.
  final EdgeInsetsGeometry? padding;

  /// Style laid over the theme and defaults.
  final DsReorderableListStyle? style;

  /// Desen's default reorderable list style under [theme].
  static DsReorderableListStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsReorderableListStyle(
      handleColor: k.textSubtle,
      handleSize: theme.sizes.iconSm,
      // The grip sits as far from the end edge as a row's leading icon
      // from the start edge.
      handleGap: DsSpace.s8,
      // A layer above the list, like a menu.
      liftedBackground: k.overlay,
      liftedShadows: theme.shadows.overlay,
      liftedBorderRadius: BorderRadius.circular(theme.radii.overlay),
      liftedScale: 1.02,
      focusShadows: theme.focusShadows,
      hovered: DsReorderableListStyle(handleColor: k.textMuted),
      pressed: DsReorderableListStyle(handleColor: k.text),
      disabled: DsReorderableListStyle(handleColor: k.onDisabled),
    );
  }

  @override
  State<DsReorderableList> createState() => _DsReorderableListState();
}

class _DsReorderableListState extends State<DsReorderableList> {
  /// The item whose handle takes focus after the next build: one moved
  /// from the keyboard, rebuilt in its new place.
  int? _refocus;

  List<DsReorderableListStyle?> _layers(BuildContext context) => [
    DsReorderableList.defaultStyle(dsThemeOf(context)),
    DsReorderableListTheme.of(context).style,
    widget.style,
  ];

  /// Moves item [from] to [to] (after the move), held to the list.
  void _move(int from, int to, {bool keepFocus = false}) {
    final onReorder = widget.onReorder;
    final n = widget.itemCount;
    if (onReorder == null || n == 0) return;
    final target = to.clamp(0, n - 1);
    if (target == from) return;
    if (keepFocus) _refocus = target;
    onReorder(from, target);
  }

  Widget _lifted(Widget child, int index, Animation<double> animation) {
    final s = DsReorderableListStyle.resolveLayers(_layers(context), const {});
    final motion = DsTheme.motionOf(context);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = motion.toneCurve.transform(animation.value);
        final scale = motion.reduced ? 1.0 : lerpDouble(1, s.liftedScale!, t)!;
        return Transform.scale(
          scale: scale,
          child: DsSurface(
            decoration: DsBoxDecoration(
              color: s.liftedBackground,
              borderRadius: s.liftedBorderRadius ?? BorderRadius.zero,
              shadows: t > 0 ? s.liftedShadows ?? const [] : const [],
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReorder == null) {
      return ListView.builder(
        controller: widget.controller,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      );
    }
    final touch = isTouchPlatform(dsThemeOf(context).platform);
    Widget list = ReorderableList(
      controller: widget.controller,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemCount: widget.itemCount,
      onReorderItem: _move,
      onReorderStart: (_) =>
          DsHapticFeedback.play(context, DsHapticEvent.selection),
      onReorderEnd: (_) =>
          DsHapticFeedback.play(context, DsHapticEvent.selection),
      proxyDecorator: _lifted,
      itemBuilder: (context, index) {
        final child = widget.itemBuilder(context, index);
        assert(
          child.key != null,
          'Every DsReorderableList item needs a key that moves with it, '
          'such as ValueKey(item.id).',
        );
        final refocus = _refocus == index;
        if (refocus) _refocus = null;
        return _Item(
          key: child.key,
          index: index,
          count: widget.itemCount,
          layers: _layers(context),
          liftOnLongPress: touch,
          focusHandle: refocus,
          onMove: (to) => _move(index, to, keepFocus: true),
          child: child,
        );
      },
    );
    // Flutter's list reads its screen reader actions from the widgets
    // layer's strings, which only an app root provides. Without one, it
    // gets Desen's, and keeps the direction around it.
    if (Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations) ==
        null) {
      list = Localizations(
        locale: Localizations.maybeLocaleOf(context) ?? const Locale('en'),
        delegates: const [DsWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: list,
        ),
      );
    }
    return list;
  }
}

/// One item with its handle, the long press that lifts it on touch
/// screens and the Alt+arrow keys that move it.
class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.index,
    required this.count,
    required this.layers,
    required this.liftOnLongPress,
    required this.focusHandle,
    required this.onMove,
    required this.child,
  });

  final int index, count;
  final List<DsReorderableListStyle?> layers;
  final bool liftOnLongPress, focusHandle;

  /// Moves this item to the given index.
  final ValueChanged<int> onMove;
  final Widget child;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        !HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      onMove(index - 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      onMove(index + 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final s = DsReorderableListStyle.resolveLayers(layers, const {});
    Widget item = Row(
      children: [
        Expanded(child: child),
        SizedBox(width: s.handleGap),
        _Handle(
          index: index,
          count: count,
          layers: layers,
          autofocus: focusHandle,
          onMove: onMove,
        ),
        SizedBox(width: s.handleGap),
      ],
    );
    if (liftOnLongPress) {
      item = ReorderableDelayedDragStartListener(index: index, child: item);
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: item,
    );
  }
}

/// The grip that drags its item, and moves it from the keyboard.
class _Handle extends StatefulWidget {
  const _Handle({
    required this.index,
    required this.count,
    required this.layers,
    required this.autofocus,
    required this.onMove,
  });

  final int index, count;
  final List<DsReorderableListStyle?> layers;
  final bool autofocus;
  final ValueChanged<int> onMove;

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  final _node = FocusNode(debugLabel: 'DsReorderableList handle');
  bool _hovered = false, _pressed = false;

  /// Flutter's focus highlight, before the keyboard check.
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  void _onModality() {
    if (_highlight) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
    _refocus();
  }

  @override
  void didUpdateWidget(_Handle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refocus();
  }

  /// A handle moved from the keyboard takes focus again in its new place.
  void _refocus() {
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _node.dispose();
    super.dispose();
  }

  /// The pointer may lift after a drop has rebuilt the item in its new
  /// place, with a new handle.
  void _press(bool down) {
    if (mounted && _pressed != down) setState(() => _pressed = down);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final to = switch (key) {
      LogicalKeyboardKey.arrowUp => widget.index - 1,
      LogicalKeyboardKey.arrowDown => widget.index + 1,
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => widget.count - 1,
      _ => null,
    };
    if (to == null) return KeyEventResult.ignored;
    widget.onMove(to);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsReorderableListStyle.resolveLayers(widget.layers, {
      if (_hovered) WidgetState.hovered,
      if (_pressed) WidgetState.pressed,
      if (_focusVisible) WidgetState.focused,
    });
    final size = s.handleSize!;
    return ReorderableDragStartListener(
      index: widget.index,
      child: Listener(
        onPointerDown: (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: FocusableActionDetector(
            focusNode: _node,
            // Screen readers move items with the item's own actions; a
            // handle they could land on would say nothing useful.
            includeFocusSemantics: false,
            mouseCursor:
                s.cursor ??
                (_pressed
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab),
            onShowHoverHighlight: (h) => setState(() => _hovered = h),
            onShowFocusHighlight: (f) => setState(() => _highlight = f),
            child: ExcludeSemantics(
              child: DsMinTapTarget(
                size: t.sizes.minTapTarget,
                child: DsFocusRing(
                  focused: _focusVisible,
                  shadows: s.focusShadows,
                  borderRadius: BorderRadius.circular(size / 2),
                  child: DsIcon(
                    DsIcons.gripVertical,
                    size: size,
                    color: s.handleColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
