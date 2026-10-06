import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/pressable.dart';
import '../../foundation/case.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../overlay/anchored_overlay.dart';
import '../../overlay/placement.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/surface.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'menu_item_style.dart';
import 'menu_style.dart';
import 'shortcut.dart';

/// Marks where a menu's items end: a menu inside a menu keeps its own.
class _MenuScope extends InheritedWidget {
  const _MenuScope({
    required this.state,
    required this.gutter,
    required this.checks,
    required super.child,
  });

  final _DsMenuState state;

  /// Some item has a leading icon: every item keeps its column, so the
  /// labels line up.
  final bool gutter;

  /// Some item is a choice ([DsMenuItem.checked] not null): every item
  /// keeps the check column, so the labels line up.
  final bool checks;

  @override
  bool updateShouldNotify(_MenuScope oldWidget) =>
      gutter != oldWidget.gutter || checks != oldWidget.checks;
}

/// Closes the layer a menu sits in; provided by [DsMenuAnchor] and
/// [DsContextMenuRegion].
class _MenuCloser extends InheritedWidget {
  const _MenuCloser({required this.close, required super.child});

  final VoidCallback close;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuCloser>()?.close;

  @override
  bool updateShouldNotify(_MenuCloser oldWidget) => false;
}

/// A menu panel: plain, with shortcuts, dangerous actions in their own
/// group. Usually opened by [DsMenuAnchor] or
/// [DsContextMenuRegion]; it can also sit inline.
///
/// Keyboard (WAI-ARIA menu): arrow keys move between items and wrap, Home
/// and End jump to the ends, typing a letter jumps to the next item that
/// starts with it, Enter or Space chooses, Escape closes. In a layer
/// ([DsMenuAnchor], [DsContextMenuRegion]) Tab closes the menu and moves
/// focus on from its trigger. The order and the type-ahead text always
/// follow the items as they are now, also after they change.
///
/// **Submenus.** A [DsMenuItem.submenu] opens a menu of its own beside it
/// (see there): Right (Left in RTL), Enter or Space opens it and focuses
/// its first item, Left (Right in RTL) or Escape closes it and returns to
/// its item, and a second Escape closes this menu. Each level keeps its
/// own arrow keys and type-ahead.
class DsMenu extends StatefulWidget {
  /// Creates a menu panel.
  const DsMenu({
    super.key,
    required this.children,
    this.autofocus = false,
    this.onDone,
    this.semanticLabel,
    this.style,
  });

  /// [DsMenuItem]s and [DsMenuDivider]s.
  final List<Widget> children;

  /// Focuses an item when built: the one marked [DsMenuItem.autofocus], or
  /// the first (set by the anchors).
  final bool autofocus;

  /// Called after an item is chosen, e.g. to close the layer.
  final VoidCallback? onDone;

  /// Names the menu for screen readers.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsMenuStyle? style;

  /// Desen's default menu style under [theme].
  static DsMenuStyle defaultStyle(DsThemeData theme) => DsMenuStyle(
    background: theme.colors.overlay,
    shadows: theme.shadows.overlay,
    borderRadius: BorderRadius.circular(theme.radii.overlay),
    padding: const EdgeInsets.all(DsSpace.s6),
    minWidth: 200,
    gap: 1,
    dividerColor: theme.colors.border,
    dividerMargin: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: DsSpace.s4,
    ),
  );

  @override
  State<DsMenu> createState() => _DsMenuState();
}

class _DsMenuState extends State<DsMenu> {
  /// Whether this menu builds its entries on demand.
  bool get _lazy => widget.children.length > _lazyAbove;

  /// The enabled items as they are now, in tree (= visual) order. Read
  /// when needed, so the order and labels never go stale. Only
  /// for a menu that builds every entry; a long one keeps a [_LazyModel].
  List<_DsMenuItemState> get _items {
    final result = <_DsMenuItemState>[];
    void visit(Element element) {
      final widget = element.widget;
      // A menu nested inside this one keeps its own items.
      if (widget is _MenuScope && widget.state != this) return;
      if (element is StatefulElement) {
        final state = element.state;
        if (state is _DsMenuItemState) {
          if (state._enabled) result.add(state);
          return;
        }
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return result;
  }

  // A long menu: its model, its scroll position and its built items.

  _LazyModel? _model;
  ScrollController? _scroll;

  /// The items of a long menu that are built now, by entry index.
  final Map<int, _DsMenuItemState> _built = {};

  /// The entry a long menu opens on (the autofocus item), until its first
  /// frame is out.
  int? _initialTarget;

  @override
  void initState() {
    super.initState();
    if (!widget.autofocus) return;
    if (_lazy) {
      _initialTarget = _LazyModel.autofocusIndex(widget.children);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_lazy) {
        final target = _initialTarget;
        _initialTarget = null;
        if (target != null) _built[target]?._node.requestFocus();
        return;
      }
      final items = _items;
      if (items.isEmpty) return;
      final preferred = items.where((i) => i.widget.autofocus).firstOrNull;
      _show((preferred ?? items.first)._node);
    });
  }

  /// Holds the keyboard handler; never focused itself.
  final _focusNode = FocusNode(
    debugLabel: 'DsMenu',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _aimTimer?.cancel();
    _focusNode.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  /// Focuses the first item: a submenu opened from the keyboard.
  void _focusFirst() {
    if (_lazy) {
      final model = _model;
      if (model != null && model.enabled.isNotEmpty) {
        _focusEntry(model.enabled.first, down: false);
      }
      return;
    }
    final items = _items;
    if (items.isNotEmpty) _show(items.first._node);
  }

  // Submenus: the item whose submenu is open, and the pointer's way to it.

  /// The item whose submenu is open, if any.
  _DsMenuItemState? _openSub;

  /// While the pointer travels from [_openSub] toward its submenu, the
  /// triangle it may cross without the items it passes taking over ("menu
  /// aim", the safe triangle).
  _Aim? _aim;
  Timer? _aimTimer;

  /// The item the pointer rests on while aiming; it takes over when the
  /// pointer stops ([DsMotion.submenuDelay]) or leaves the triangle.
  _DsMenuItemState? _pending;

  /// The pointer is over [item] at [position] (global).
  void _pointerOver(_DsMenuItemState item, Offset position) {
    if (_aim case final aim? when aim.owner != item) {
      if (aim.contains(position)) {
        // On its way to the submenu: passing items do not take over yet.
        _pending = item;
        return;
      }
    }
    _endAim();
    item._hovered();
  }

  /// The pointer left [owner], whose submenu is open, from [from] (global);
  /// [submenu] is the submenu's box (global).
  void _startAim(_DsMenuItemState owner, Offset from, Rect submenu) {
    _endAim();
    _aim = _Aim(owner, from, submenu);
    _aimTimer = Timer(DsTheme.motionOf(context).submenuDelay, () {
      final pending = _pending;
      _endAim();
      // The pointer stopped short of the submenu: where it rests wins.
      if (pending != null && pending.mounted && pending._pointerInside) {
        pending._hovered();
      }
    });
  }

  void _endAim() {
    _aimTimer?.cancel();
    _aimTimer = null;
    _aim = null;
    _pending = null;
  }

  /// [item] took focus: another item's open submenu closes.
  void _itemFocused(_DsMenuItemState item) {
    final open = _openSub;
    if (open != null && open != item && open.mounted) open._closeSubmenu();
  }

  void _submenuOpened(_DsMenuItemState item) {
    final open = _openSub;
    if (open != null && open != item && open.mounted) open._closeSubmenu();
    _openSub = item;
  }

  void _submenuClosed(_DsMenuItemState item) {
    if (_openSub == item) _openSub = null;
    if (_aim?.owner == item) _endAim();
  }

  /// Focuses [node] and keeps it in view in a long, scrolling menu.
  void _show(FocusNode node) {
    node.requestFocus();
    if (node.context case final context?) {
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  /// A long menu: focuses entry [index]. When it is not built, the list
  /// jumps to it (its end at the bottom edge when moving [down], else its
  /// start at the top) and it takes focus once built, a frame later.
  void _focusEntry(int index, {required bool down}) {
    final built = _built[index];
    if (built != null && built.mounted) {
      _pendingEntry = null;
      _show(built._node);
      return;
    }
    final model = _model;
    final scroll = _scroll;
    if (model == null || scroll == null || !scroll.hasClients) return;
    final position = scroll.position;
    final view = position.viewportDimension;
    final start = model.offsetOf(index);
    final target = down ? start + model.extentOf(index) - view : start;
    position.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
    _pendingEntry = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingEntry != index) return;
      _pendingEntry = null;
      if (_built[index] case final item?) _show(item._node);
    });
  }

  /// The entry a long menu is about to focus, once it is built: a second
  /// key before that frame moves on from it.
  int? _pendingEntry;

  /// A long menu: the entry index of the item with focus, or -1.
  int _focusedEntry() {
    if (_pendingEntry case final pending?) return pending;
    for (final MapEntry(:key, :value) in _built.entries) {
      if (value.mounted && value._node.hasPrimaryFocus) return key;
    }
    return -1;
  }

  /// A long menu, laid out [viewport] tall: on its first frame, scroll so
  /// the item it opens on shows, at the bottom edge as [_show] puts it.
  void _placeInitial(double viewport) {
    final target = _initialTarget;
    final model = _model;
    final scroll = _scroll;
    if (target == null || model == null || scroll == null) return;
    if (!scroll.hasClients) return;
    final max = math.max(0.0, model.total - viewport);
    final offset = model.offsetOf(target) + model.extentOf(target) - viewport;
    scroll.position.correctPixels(offset.clamp(0.0, max));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    // The enabled items: how many, which has focus, how to focus one and
    // its folded text. From the tree, or from a long menu's model.
    final int n;
    final int i;
    final void Function(int j, {required bool down}) go;
    final String? Function(int j) folded;
    final model = _lazy ? _model : null;
    if (model != null) {
      final enabled = model.enabled;
      n = enabled.length;
      i = model.enabledPlace(_focusedEntry());
      go = (j, {required down}) => _focusEntry(enabled[j % n], down: down);
      folded = (j) => model.foldedText(enabled[j]);
    } else {
      final items = _items;
      n = items.length;
      i = items.indexWhere((item) => item._node.hasPrimaryFocus);
      go = (j, {required down}) => _show(items[j % n]._node);
      folded = (j) => switch (items[j]._text) {
        final text? => dsFoldCase(text),
        null => null,
      };
    }
    if (n == 0) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown) {
      go(i < 0 ? 0 : i + 1, down: i + 1 < n);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      go(i < 0 ? n - 1 : i - 1 + n, down: i <= 0);
    } else if (key == LogicalKeyboardKey.home) {
      go(0, down: false);
    } else if (key == LogicalKeyboardKey.end) {
      go(n - 1, down: true);
    } else if (event.character case final c?
        when c.trim().isNotEmpty && c.length == 1) {
      // Type-ahead: the next item, after the current one, starting with c.
      final wanted = dsFoldCase(c);
      for (var step = 1; step <= n; step++) {
        final j = ((i < 0 ? -1 : i) + step) % n;
        if (folded(j)?.startsWith(wanted) ?? false) {
          go(j, down: j > i);
          break;
        }
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// A long menu's entries: a list that builds what shows, as wide as the
  /// widest of a sample of its items (see [_LazyModel]).
  Widget _lazyBody(BuildContext context, DsMenuStyle s) {
    final gap = s.gap!;
    final children = widget.children;
    final model = _model = _LazyModel.of(
      context,
      children,
      gap: gap,
      previous: _model,
    );
    final scroll = _scroll ??= ScrollController(keepScrollOffset: false);
    return _LazyMenuBody(
      contentHeight: model.total,
      onViewport: _placeInitial,
      // Offstage: finders, hit tests and screen readers pass it by.
      measure: Offstage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in model.sample)
              _MenuRowMeasure(item: children[i] as DsMenuItem),
          ],
        ),
      ),
      list: ListView.builder(
        controller: scroll,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        itemExtent: model.uniform,
        itemExtentBuilder: model.uniform == null
            ? (i, _) => i < children.length ? model.extentOf(i) : null
            : null,
        // Screen readers hear "item k of n" for the built window.
        addSemanticIndexes: false,
        semanticChildCount: model.itemCount,
        itemBuilder: (context, i) {
          Widget entry = _MenuSlot(menu: this, index: i, child: children[i]);
          // Each entry keeps the gap below it, the last one too.
          if (gap > 0) {
            entry = Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: entry,
            );
          }
          final place = model.ordinal[i];
          return place < 0
              ? entry
              : IndexedSemantics(index: place, child: entry);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsMenuStyle.resolveLayers([
      DsMenu.defaultStyle(t),
      DsMenuTheme.of(context).style,
      widget.style,
    ], const {});
    final lazy = _lazy;
    if (!lazy) _model = null;
    Widget menu = Semantics(
      container: true,
      role: SemanticsRole.menu,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        // Focus left this menu and its submenus (e.g. the layer closed):
        // an open submenu goes with it.
        onFocusChange: (focused) {
          if (focused) return;
          // Not while the focus manager notifies.
          scheduleMicrotask(() {
            if (mounted && !_focusNode.hasFocus) _openSub?._closeSubmenu();
          });
        },
        child: DsSurface(
          constraints: BoxConstraints(minWidth: s.minWidth ?? 0),
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: s.shadows ?? const [],
          ),
          backdropFilter: s.backdropFilter,
          // Scrolls when the room on screen is shorter than the menu.
          child: lazy
              ? _lazyBody(context, s)
              : SingleChildScrollView(
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: s.gap!,
                      children: widget.children,
                    ),
                  ),
                ),
        ),
      ),
    );
    if (widget.onDone case final done?) {
      menu = _MenuCloser(close: done, child: menu);
    }
    return _MenuScope(
      state: this,
      gutter:
          _model?.gutter ??
          widget.children.any((c) => c is DsMenuItem && c.leading != null),
      checks:
          _model?.checks ??
          widget.children.any((c) => c is DsMenuItem && c.checked != null),
      child: menu,
    );
  }
}

/// A line between groups of a [DsMenu].
class DsMenuDivider extends StatelessWidget {
  /// Creates a divider.
  const DsMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsMenuStyle.resolveLayers([
      DsMenu.defaultStyle(t),
      DsMenuTheme.of(context).style,
    ], const {});
    return ExcludeSemantics(
      child: Padding(
        padding: s.dividerMargin ?? EdgeInsets.zero,
        child: DsLine(color: s.dividerColor ?? const Color(0x00000000)),
      ),
    );
  }
}

/// How screen readers announce a [DsMenuItem] that can be checked
/// ([DsMenuItem.checked] not null).
enum DsMenuCheckRole {
  /// One choice of a set, of which one is checked (a sort order, a
  /// select's options): a radio menu item.
  radio,

  /// A setting that turns on or off on its own ("Show grid"), or one of
  /// several that can be checked together: a checkbox menu item.
  checkbox,
}

/// An item of a [DsMenu]. Choosing it runs [onPressed] and closes the
/// menu. Hover and keyboard focus share one highlight; when the theme
/// shows focus rings (the default), the keyboard-focused item also draws
/// an inset ring, so the active item is never told by color alone.
///
/// [DsMenuItem.submenu] makes an item that opens a menu of its own.
class DsMenuItem extends StatefulWidget {
  /// Creates a menu item.
  const DsMenuItem({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.shortcut,
    this.trailing,
    this.destructive = false,
    this.checked,
    this.checkRole = DsMenuCheckRole.radio,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  }) : submenu = null,
       _submenuEnabled = false;

  /// Creates an item that opens [submenu], a menu of its own, beside it: on
  /// the end side, or the start side when the end has no room (mirrored in
  /// RTL). It shows a chevron and keeps its highlight while the submenu is
  /// open.
  ///
  /// - **Pointer:** resting on the item for [DsMotion.submenuDelay] opens the
  ///   submenu, and so does a click or tap. Moving toward the open submenu
  ///   across other items does not close it: while the pointer stays in
  ///   the triangle between where it left the item and the submenu's near
  ///   edge, the items it passes wait, until it stops for
  ///   [DsMotion.submenuDelay] ("menu aim").
  /// - **Keyboard (WAI-ARIA menu):** Right (Left in RTL), Enter or Space
  ///   opens the submenu and focuses its first item. In the submenu, Left
  ///   (Right in RTL) or Escape closes it and returns focus here; Tab
  ///   closes every level and moves on, like in the parent menu.
  /// - **Choosing** an item in the submenu closes the whole menu.
  /// - **Screen readers** hear a menu item that is expanded or collapsed;
  ///   the submenu is a menu named by [label].
  ///
  /// Submenus nest. Each level has its own arrow keys and type-ahead.
  const DsMenuItem.submenu({
    super.key,
    required this.label,
    required List<Widget> this.submenu,
    this.leading,
    bool enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.style,
  }) : onPressed = null,
       shortcut = null,
       trailing = null,
       destructive = false,
       checked = null,
       checkRole = DsMenuCheckRole.radio,
       autofocus = false,
       _submenuEnabled = enabled;

  /// The label, usually a short [Text] (its text drives type-ahead).
  final Widget label;

  /// Runs when the item is chosen. Null disables it.
  final VoidCallback? onPressed;

  /// An icon before the label.
  final Widget? leading;

  /// A keyboard shortcut shown muted on the end side ("⌘E"); key symbols
  /// are drawn as icons ([DsShortcut]).
  final String? shortcut;

  /// A widget on the end side, e.g. a chevron.
  final Widget? trailing;

  /// Colors the item as a dangerous action ("Sil").
  final bool destructive;

  /// Makes the item one that can be checked: by default one choice of a
  /// single-choice menu (selects), announced as a radio item, checked or
  /// not; [checkRole] makes it an on/off setting instead. When checked it
  /// shows a check before the label and is bold. Every item of a menu with
  /// such items keeps the check column, so the labels line up; it comes
  /// before the icon column. Choosing it plays the selection haptic
  /// (`DsHapticEvent.selection`), where a plain item plays a command.
  /// Null for a plain item.
  final bool? checked;

  /// How a checkable item ([checked] not null) is announced:
  /// [DsMenuCheckRole.radio] (the default) for one choice of a set,
  /// [DsMenuCheckRole.checkbox] for a setting that turns on or off on its
  /// own, or one of several that can be checked together. The look is the
  /// same.
  ///
  /// ```dart
  /// DsMenuItem(
  ///   label: const Text('Show grid'),
  ///   checked: showGrid,
  ///   checkRole: .checkbox,
  ///   onPressed: () => setState(() => showGrid = !showGrid),
  /// )
  /// ```
  final DsMenuCheckRole checkRole;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Takes focus when the menu opens (the current choice of a select).
  final bool autofocus;

  /// Overrides what screen readers announce (default: the label's text).
  final String? semanticLabel;

  /// The submenu's [DsMenuItem]s and [DsMenuDivider]s; null for an item
  /// that does not open a submenu.
  final List<Widget>? submenu;

  final bool _submenuEnabled;

  /// Whether the item can be chosen or opened.
  bool get _canChoose => submenu != null ? _submenuEnabled : onPressed != null;

  /// Style laid over the theme and defaults.
  final DsMenuItemStyle? style;

  /// Desen's default item style under [theme].
  static DsMenuItemStyle defaultStyle(
    DsThemeData theme, {
    bool destructive = false,
  }) {
    final k = theme.colors;
    final shortcut = theme.typography.caption;
    return DsMenuItemStyle(
      height: theme.sizes.row,
      // The vertical padding only shows on a label that wraps (or at a
      // large text scale): one line sits inside the row height.
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s4,
      ),
      // Concentric with the menu, inset by its padding.
      borderRadius: BorderRadius.circular(
        theme.radii.nested(theme.radii.overlay, DsSpace.s6),
      ),
      background: const Color(0x00000000),
      foreground: destructive ? k.danger.text : k.text,
      textStyle: theme.typography.body.copyWith(height: 1.2),
      // Secondary, not tertiary, ink: it stays 4.5:1 on the highlight.
      shortcutStyle: shortcut.copyWith(color: k.textMuted),
      iconSize: 16,
      gap: DsSpace.s12,
      // Rows are full-bleed, so the ring sits inside the highlight.
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      // One highlight for hover and keyboard focus.
      hovered: destructive
          // Neutral in dark mode, where a deep red tint turns maroon.
          ? DsMenuItemStyle(background: theme.isDark ? k.hover : k.danger.tint)
          : DsMenuItemStyle(background: k.selection, foreground: k.onSelection),
      disabled: DsMenuItemStyle(
        background: const Color(0x00000000),
        foreground: k.onDisabled,
        shortcutStyle: TextStyle(color: k.onDisabled),
      ),
    );
  }

  @override
  State<DsMenuItem> createState() => _DsMenuItemState();
}

/// The triangle a pointer may cross on its way from a submenu's item to
/// the submenu: from where it left the item to the submenu's near edge.
class _Aim {
  _Aim(this.owner, Offset from, Rect submenu) {
    final toEnd = submenu.center.dx >= from.dx;
    final edge = toEnd ? submenu.left : submenu.right;
    // A little slack behind the exit point, so a hand that wobbles back a
    // pixel on its way still counts.
    _a = from.translate(toEnd ? -DsSpace.s4 : DsSpace.s4, 0);
    _b = Offset(edge, submenu.top);
    _c = Offset(edge, submenu.bottom);
  }

  final _DsMenuItemState owner;
  late final Offset _a, _b, _c;

  bool contains(Offset p) {
    double side(Offset p1, Offset p2, Offset p3) =>
        (p1.dx - p3.dx) * (p2.dy - p3.dy) - (p2.dx - p3.dx) * (p1.dy - p3.dy);
    final d1 = side(p, _a, _b);
    final d2 = side(p, _b, _c);
    final d3 = side(p, _c, _a);
    final negative = d1 < 0 || d2 < 0 || d3 < 0;
    final positive = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negative && positive);
  }
}

class _DsMenuItemState extends State<DsMenuItem> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  Set<WidgetState>? _lastStates;

  // Submenu parts; created for submenu items only.
  DsOverlayController? _sub;
  FocusNode? _subFocus;
  final _subMenu = GlobalKey<_DsMenuState>();
  Timer? _openTimer;

  /// The pointer is over this item, and where it last was (global).
  bool _pointerInside = false;
  Offset? _lastPointer;

  bool get _isSubmenu => widget.submenu != null;

  bool get _subOpen => _sub?.isOpen ?? false;

  /// Whether the item can be chosen or opened.
  bool get _enabled => widget._canChoose;

  /// The menu this item is in, if any.
  _DsMenuState? get _menu =>
      context.getInheritedWidgetOfExactType<_MenuScope>()?.state;

  /// The label's text, for type-ahead.
  String? get _text => _plainText(widget.label);

  /// In a long menu: the menu and the entry index this item is built at.
  _DsMenuState? _slotMenu;
  int? _slot;

  /// Tells a long menu that this item is built at its slot.
  void _register() {
    final slot = context.dependOnInheritedWidgetOfExactType<_MenuSlot>();
    final menu = _menu;
    _unregister();
    if (slot == null || menu == null || slot.menu != menu) return;
    _slotMenu = menu;
    _slot = slot.index;
    menu._built[slot.index] = this;
  }

  void _unregister() {
    final menu = _slotMenu, slot = _slot;
    if (menu != null && slot != null && menu._built[slot] == this) {
      menu._built.remove(slot);
    }
    _slotMenu = null;
    _slot = null;
  }

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _syncSubmenu();
  }

  @override
  void didUpdateWidget(DsMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      if (widget.focusNode != null) {
        _ownNode?.dispose();
        _ownNode = null;
      }
      _node.addListener(_onFocus);
    }
    _syncSubmenu();
    if (!_enabled && _subOpen) _closeSubmenu();
  }

  void _syncSubmenu() {
    if (_isSubmenu && _sub == null) {
      _sub = DsOverlayController()..addListener(_onSubmenu);
      _subFocus = FocusNode(
        debugLabel: 'DsMenuItem submenu',
        canRequestFocus: false,
        skipTraversal: true,
      );
    }
  }

  @override
  void dispose() {
    _unregister();
    _openTimer?.cancel();
    _sub?.dispose();
    _subFocus?.dispose();
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_node.hasPrimaryFocus) return;
    // Not while the focus manager notifies: closing moves focus.
    scheduleMicrotask(() {
      if (mounted && _node.hasPrimaryFocus) _menu?._itemFocused(this);
    });
  }

  void _choose() {
    widget.onPressed?.call();
    _MenuCloser.maybeOf(context)?.call();
  }

  // Pointer.

  void _onPointer(PointerEvent event) {
    _pointerInside = true;
    _lastPointer = event.position;
    final menu = _menu;
    menu == null ? _hovered() : menu._pointerOver(this, event.position);
  }

  void _onExit(PointerExitEvent event) {
    _pointerInside = false;
    if (!_isSubmenu) return;
    _openTimer?.cancel();
    final from = _lastPointer;
    final box = _subMenu.currentContext?.findRenderObject();
    if (_subOpen && from != null && box is RenderBox && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      _menu?._startAim(this, from, rect);
    }
  }

  /// The pointer rests here: take the highlight (it is where the keyboard
  /// continues from) and, for a submenu, open it after a delay.
  void _hovered() {
    if (!_enabled) return;
    if (!_node.hasPrimaryFocus) _node.requestFocus();
    if (_isSubmenu && !_subOpen && !(_openTimer?.isActive ?? false)) {
      _openTimer = Timer(DsTheme.motionOf(context).submenuDelay, () {
        if (mounted && _pointerInside) _openSubmenu(focusFirst: false);
      });
    }
  }

  // Submenu.

  void _openSubmenu({required bool focusFirst}) {
    final sub = _sub;
    if (sub == null || !_enabled) return;
    _openTimer?.cancel();
    _menu?._submenuOpened(this);
    sub.open();
    if (focusFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && sub.isOpen) _subMenu.currentState?._focusFirst();
      });
    }
  }

  void _closeSubmenu() => _sub?.close();

  void _onSubmenu() {
    if (!mounted) return;
    if (!_subOpen) {
      // Focus inside the closing submenu comes back to this item.
      if (_subFocus?.hasFocus ?? false) _node.requestFocus();
      _menu?._submenuClosed(this);
    }
    setState(() {});
  }

  /// Activation: a click or tap opens the submenu; Enter, Space or a
  /// screen reader also moves focus into it.
  void _activateSubmenu() => _openSubmenu(
    focusFirst: DsFocusVisibility.keyboard.value || _accessibleNavigation,
  );

  /// Whether a screen reader (or switch access) drives the app.
  bool _accessibleNavigation = false;

  bool get _rtl => Directionality.maybeOf(context) == TextDirection.rtl;

  /// On the item: the inline-end arrow opens the submenu.
  KeyEventResult _onItemKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    final open = _rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    if (event.logicalKey != open || !_enabled) return KeyEventResult.ignored;
    _openSubmenu(focusFirst: true);
    return KeyEventResult.handled;
  }

  /// In the submenu: the inline-start arrow closes it, Tab closes every
  /// level and moves on. Escape is the layer's (it closes the innermost).
  KeyEventResult _onSubmenuKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final back = _rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == back) {
      _closeSubmenu();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _closeSubmenu();
      // Hand the key to the menus around this one, past this submenu's own
      // layer, as if it had been pressed on this item: the outermost menu
      // closes and focus moves on from its trigger.
      var outside = false;
      for (final ancestor in _subFocus!.ancestors) {
        if (!outside) {
          outside = ancestor is FocusScopeNode;
          continue;
        }
        if (ancestor.onKeyEvent?.call(ancestor, event) ==
            KeyEventResult.handled) {
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Chosen in the submenu: close it and the menu this item is in.
  void _chosenInSubmenu() {
    final closeParent = _MenuCloser.maybeOf(context);
    _closeSubmenu();
    closeParent?.call();
  }

  Widget _buildSubmenu(BuildContext context) {
    final parent = _menu;
    final t = dsThemeOf(context);
    final s = DsMenuStyle.resolveLayers([
      DsMenu.defaultStyle(t),
      DsMenuTheme.of(context).style,
      parent?.widget.style,
    ], const {});
    // The submenu's first item lines up with this one.
    final padding = (s.padding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    return Transform.translate(
      offset: Offset(0, -padding.top),
      child: MouseRegion(
        // Reached: the pointer's trip from the item is over.
        onEnter: (_) => parent?._endAim(),
        child: Focus(
          focusNode: _subFocus,
          onKeyEvent: _onSubmenuKey,
          child: DsMenu(
            key: _subMenu,
            onDone: _chosenInSubmenu,
            semanticLabel: _text,
            style: parent?.widget.style,
            children: widget.submenu!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsMenuItem.defaultStyle(t, destructive: widget.destructive),
      DsMenuItemTheme.of(context).style,
      widget.style,
    ];
    final submenu = _isSubmenu;
    final scope = context.dependOnInheritedWidgetOfExactType<_MenuScope>();
    final gutter = scope?.gutter ?? false;
    final checks = scope?.checks ?? false;
    _register();
    // A long menu's rows have one height: the label keeps to one line.
    final maxLines = _slot == null ? 2 : 1;
    _accessibleNavigation =
        MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    Widget item = MouseRegion(
      // The hovered item is where the keyboard continues from.
      onEnter: _onPointer,
      onHover: _onPointer,
      onExit: _onExit,
      child: DsPressable(
        focusNode: _node,
        semanticLabel: widget.semanticLabel,
        onPressed: !_enabled
            ? null
            : submenu
            ? _activateSubmenu
            : _choose,
        // Picking one of a set of choices (an option of a select, a radio
        // item) is a selection; any other item issues a command.
        haptic: widget.checked == null
            ? DsHapticEvent.command
            : DsHapticEvent.selection,
        isButton: false,
        role: switch ((widget.checked, widget.checkRole)) {
          (null, _) => SemanticsRole.menuItem,
          (_, DsMenuCheckRole.radio) => SemanticsRole.menuItemRadio,
          (_, DsMenuCheckRole.checkbox) => SemanticsRole.menuItemCheckbox,
        },
        checked: widget.checked,
        expanded: submenu ? _subOpen : null,
        minTapTarget: 0,
        mouseCursor: WidgetStateMouseCursor.resolveWith(
          (states) =>
              DsMenuItemStyle.resolveLayers(layers, states).cursor ??
              DsPressable.defaultCursor.resolve(states),
        ),
        builder: (context, states, _) {
          // Keyboard focus takes the hover highlight in every focus mode;
          // so does an item while its submenu is open.
          final active = {
            ...states,
            if (states.contains(WidgetState.focused) || _subOpen)
              WidgetState.hovered,
          };
          final s = DsMenuItemStyle.resolveLayers(layers, active);
          final animate =
              _lastStates != null && !setEquals(_lastStates, active);
          _lastStates = active;
          final fg = s.foreground ?? t.colors.text;
          return AnimatedContainer(
            duration: animate ? t.motion.toneDuration : Duration.zero,
            curve: t.motion.toneCurve,
            constraints: BoxConstraints(minHeight: s.height!),
            padding: s.padding,
            decoration: DsBoxDecoration(
              color: s.background,
              borderRadius: s.borderRadius ?? BorderRadius.zero,
              shadows: [
                if (states.contains(WidgetState.focused)) ...?s.focusShadows,
              ],
            ),
            child: _itemRow(
              widget,
              s,
              fg,
              gutter: gutter,
              checks: checks,
              maxLines: maxLines,
            ),
          );
        },
      ),
    );
    if (!submenu) return item;
    item = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onItemKey,
      child: item,
    );
    // The submenu meets the parent menu's edge, overlapping it by a hair,
    // and never covers this item's highlight.
    final parentPadding =
        (DsMenuStyle.resolveLayers([
                  DsMenu.defaultStyle(t),
                  DsMenuTheme.of(context).style,
                  _menu?.widget.style,
                ], const {}).padding ??
                EdgeInsets.zero)
            .resolve(Directionality.of(context));
    return DsAnchoredOverlay(
      controller: _sub!,
      side: DsSide.end,
      align: DsAlign.start,
      gap: math.max(0, parentPadding.horizontal / 2 - 2),
      // Focus moves in only from the keyboard ([_openSubmenu]); a pointer
      // opening keeps the highlight here until it reaches the submenu.
      focusOnOpen: false,
      tab: DsOverlayTab.close,
      overlayBuilder: _buildSubmenu,
      child: item,
    );
  }
}

/// Opens a [DsMenu] from a trigger, e.g. a "more" button.
///
/// ```dart
/// DsMenuAnchor(
///   items: [DsMenuItem(label: const Text('Düzenle'), onPressed: edit)],
///   builder: (context, controller, _) => DsButton.icon(
///     icon: const DsIcon(DsIcons.ellipsis),
///     semanticLabel: 'Diğer',
///     onPressed: controller.toggle,
///   ),
/// )
/// ```
///
/// [builder] builds the trigger with the controller that opens and closes
/// the menu; the anchor makes and disposes that controller itself unless
/// you pass [controller] (to open it from elsewhere too). A plain [child]
/// trigger needs a [controller] to toggle.
///
/// A `DsButton` trigger is announced as a menu button that is expanded or
/// collapsed (WAI-ARIA `aria-expanded`) without any wiring
/// ([DsAnchoredOverlay.expandsTrigger]). A trigger of another kind
/// announces it with `Semantics(expanded: controller.isOpen)` around its
/// own control, rebuilt by a `ListenableBuilder` on the controller.
///
/// System back closes the open menu before the page.
class DsMenuAnchor extends StatefulWidget {
  /// Creates a menu anchor. Give [builder], or [child] and [controller].
  const DsMenuAnchor({
    super.key,
    this.controller,
    required this.items,
    this.builder,
    this.child,
    this.side = DsSide.bottom,
    this.align = DsAlign.start,
    this.semanticLabel,
    this.style,
  }) : assert(
         builder != null || (child != null && controller != null),
         'DsMenuAnchor needs a builder, or a child and a controller',
       );

  /// Opens and closes the menu; one is made when null.
  final DsOverlayController? controller;

  /// [DsMenuItem]s and [DsMenuDivider]s.
  final List<Widget> items;

  /// Builds the trigger with the menu's controller; see the class docs.
  final DsOverlayTriggerBuilder? builder;

  /// The trigger, or with [builder], a part of it passed to [builder].
  final Widget? child;

  /// Preferred side of the trigger.
  final DsSide side;

  /// Preferred alignment along the trigger.
  final DsAlign align;

  /// Names the menu for screen readers.
  final String? semanticLabel;

  /// Menu style laid over the theme and defaults.
  final DsMenuStyle? style;

  @override
  State<DsMenuAnchor> createState() => _DsMenuAnchorState();
}

class _DsMenuAnchorState extends State<DsMenuAnchor> {
  DsOverlayController? _own;
  DsOverlayController get _controller =>
      widget.controller ?? (_own ??= DsOverlayController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DsAnchoredOverlay(
    controller: _controller,
    side: widget.side,
    align: widget.align,
    tab: DsOverlayTab.close,
    expandsTrigger: true,
    overlayBuilder: (context) => DsMenu(
      autofocus: true,
      onDone: _controller.close,
      semanticLabel: widget.semanticLabel,
      style: widget.style,
      children: widget.items,
    ),
    child: switch (widget.builder) {
      final build? => Builder(
        builder: (context) => build(context, _controller, widget.child),
      ),
      null => widget.child!,
    },
  );
}

/// Opens a [DsMenu] where the user right-clicks or long-presses [child],
/// or, from the keyboard, with Shift+F10 or the context menu key while
/// focus is inside [child] (the menu then opens at the focused control).
/// On the web, the browser's own context menu is suppressed while the
/// pointer is over [child].
///
/// [child] needs something focusable for the keyboard path, e.g. a list
/// row or card with an `onPressed`.
class DsContextMenuRegion extends StatefulWidget {
  /// Creates a context menu region.
  const DsContextMenuRegion({
    super.key,
    required this.items,
    required this.child,
    this.semanticLabel,
    this.style,
  });

  /// [DsMenuItem]s and [DsMenuDivider]s.
  final List<Widget> items;

  /// The area that opens the menu.
  final Widget child;

  /// Names the menu for screen readers.
  final String? semanticLabel;

  /// Menu style laid over the theme and defaults.
  final DsMenuStyle? style;

  @override
  State<DsContextMenuRegion> createState() => _DsContextMenuRegionState();
}

class _DsContextMenuRegionState extends State<DsContextMenuRegion> {
  final _controller = DsOverlayController();
  Offset _at = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAt(Offset local) {
    setState(() => _at = local);
    _controller
      ..close()
      ..open();
  }

  /// Shift+F10 or the context menu key: open at the focused control's
  /// bottom start corner.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shiftF10 =
        key == LogicalKeyboardKey.f10 &&
        HardwareKeyboard.instance.isShiftPressed;
    if (!shiftF10 && key != LogicalKeyboardKey.contextMenu) {
      return KeyEventResult.ignored;
    }
    final region = context.findRenderObject();
    final focused = FocusManager.instance.primaryFocus?.context
        ?.findRenderObject();
    var at = Offset.zero;
    if (region is RenderBox && focused is RenderBox && focused.attached) {
      final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
      final corner = rtl
          ? focused.size.bottomRight(Offset.zero)
          : focused.size.bottomLeft(Offset.zero);
      at = focused.localToGlobal(corner, ancestor: region);
    }
    _openAt(at);
    return KeyEventResult.handled;
  }

  void _browserMenu({required bool enabled}) {
    if (!kIsWeb) return;
    enabled
        ? BrowserContextMenu.enableContextMenu()
        : BrowserContextMenu.disableContextMenu();
  }

  @override
  Widget build(BuildContext context) => DsAnchoredOverlay(
    controller: _controller,
    anchorPoint: _at,
    gap: 2, // ds-raw: just off the pointer, so the click does not land on it
    tab: DsOverlayTab.close,
    overlayBuilder: (context) => DsMenu(
      autofocus: true,
      onDone: _controller.close,
      semanticLabel: widget.semanticLabel,
      style: widget.style,
      children: widget.items,
    ),
    child: MouseRegion(
      onEnter: (_) => _browserMenu(enabled: false),
      onExit: (_) => _browserMenu(enabled: true),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (d) => _openAt(d.localPosition),
        onLongPressStart: (d) => _openAt(d.localPosition),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: widget.child,
        ),
      ),
    ),
  );
}

/// The row of [item] under style [s] in color [fg]: shared by the item
/// and by the width sample of a long menu ([_MenuRowMeasure]).
Widget _itemRow(
  DsMenuItem item,
  DsMenuItemStyle s,
  Color fg, {
  required bool gutter,
  required bool checks,
  required int maxLines,
}) => IconTheme.merge(
  data: IconThemeData(color: fg, size: s.iconSize),
  child: Row(
    spacing: s.gap ?? DsSpace.s12,
    children: [
      // The check of a choice, in the row's color (as iOS menus draw it),
      // so it reads on the highlight too; the column stays when unchecked.
      if (checks)
        SizedBox(
          width: s.iconSize,
          child: (item.checked ?? false)
              ? DsIcon(DsIcons.check, size: s.iconSize, color: fg)
              : null,
        ),
      ?(item.leading ?? (gutter ? SizedBox(width: s.iconSize) : null)),
      Expanded(
        child: DefaultTextStyle.merge(
          style: (s.textStyle ?? const TextStyle()).copyWith(
            color: fg,
            fontWeight: (item.checked ?? false)
                ? FontWeight.w600
                : item.destructive
                ? FontWeight.w500
                : null,
          ),
          // A long label wraps once, then ends in an ellipsis;
          // screen readers get it whole.
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          child: item.label,
        ),
      ),
      if (item.shortcut case final keys?)
        DsShortcut(keys, textStyle: s.shortcutStyle),
      ?item.trailing,
      // Points to where the submenu opens; mirrored in RTL.
      if (item.submenu != null)
        DsIcon(DsIcons.chevronRight, color: s.shortcutStyle?.color),
    ],
  ),
);

/// The text of a [Text] label, for type-ahead and the width sample.
String? _plainText(Widget? widget) => switch (widget) {
  Text(:final data?) => data,
  Text(:final textSpan?) => textSpan.toPlainText(),
  _ => null,
};

// Long menus. A menu with more entries than [_lazyAbove]
// builds only the rows that show: its arrow keys, type-ahead and the item
// it opens on work from a model of its entries, not from the element tree,
// its rows have heights known up front, and its width is the widest of a
// sample of its items.

/// Menus with more entries than this build only what shows.
const _lazyAbove = 100;

/// How many items a long menu measures for its width: those with the
/// longest text.
const _sampleSize = 48;

/// Marks the entry index a long menu built a row at.
class _MenuSlot extends InheritedWidget {
  const _MenuSlot({
    required this.menu,
    required this.index,
    required super.child,
  });

  final _DsMenuState menu;
  final int index;

  @override
  bool updateShouldNotify(_MenuSlot oldWidget) =>
      index != oldWidget.index || menu != oldWidget.menu;
}

/// What a long menu knows about its entries without building them: which
/// are enabled items, their text, their heights and offsets, and which
/// items it measures for its width.
class _LazyModel {
  _LazyModel._({
    required this.children,
    required this.metrics,
    required this.enabled,
    required this.ordinal,
    required this.itemCount,
    required this.uniform,
    required this._extents,
    required this._offsets,
    required this.total,
    required this.sample,
    required this.gutter,
    required this.checks,
  });

  /// The entries this model describes.
  final List<Widget> children;

  /// The theme inputs the heights came from.
  final Object metrics;

  /// Entry indices of the enabled items, ascending.
  final Int32List enabled;

  /// Per entry: its place among the items (for "k of n"), or -1.
  final Int32List ordinal;

  /// How many entries are items.
  final int itemCount;

  /// The height every entry has, when they share one.
  final double? uniform;
  final Float64List? _extents, _offsets;

  /// The height of all entries.
  final double total;

  /// Entry indices of the items measured for the width.
  final List<int> sample;

  /// Some item has a leading icon.
  final bool gutter;

  /// Some item is a choice (has the check column).
  final bool checks;

  List<String?>? _folded;

  /// Entry [i]'s height, with the gap below it.
  double extentOf(int i) => uniform ?? _extents![i];

  /// Where entry [i] starts.
  double offsetOf(int i) => uniform == null ? _offsets![i] : uniform! * i;

  /// Entry [entry]'s place in [enabled], or -1.
  int enabledPlace(int entry) {
    if (entry < 0) return -1;
    var lo = 0, hi = enabled.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final v = enabled[mid];
      if (v == entry) return mid;
      if (v < entry) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  /// Entry [entry]'s text, case-folded; folded once per model.
  String? foldedText(int entry) => (_folded ??= [
    for (final c in children)
      if (c is DsMenuItem)
        switch (_plainText(c.label)) {
          final text? => dsFoldCase(text),
          null => null,
        }
      else
        null,
  ])[entry];

  /// The entry a menu with autofocus opens on: the enabled item marked
  /// [DsMenuItem.autofocus], else the first enabled item.
  static int? autofocusIndex(List<Widget> children) {
    int? first;
    for (var i = 0; i < children.length; i++) {
      final c = children[i];
      if (c is DsMenuItem && c._canChoose) {
        if (c.autofocus) return i;
        first ??= i;
      }
    }
    return first;
  }

  /// The model of [children] under [context]'s theme; [previous] when
  /// nothing it depends on changed.
  static _LazyModel of(
    BuildContext context,
    List<Widget> children, {
    required double gap,
    _LazyModel? previous,
  }) {
    final t = dsThemeOf(context);
    final itemTheme = DsMenuItemTheme.of(context).style;
    final menuTheme = DsMenuTheme.of(context).style;
    final text = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final metrics = (
      t.sizes,
      t.typography,
      itemTheme,
      menuTheme,
      text,
      scaler,
      gap,
    );
    if (previous != null &&
        identical(previous.children, children) &&
        previous.metrics == metrics) {
      return previous;
    }

    // Row heights: one per item look, from one line of its text.
    final lines = <TextStyle?, double>{};
    double line(TextStyle? style) => lines[style] ??= () {
      final painter = TextPainter(
        // ds-raw: measures one line's height, never painted
        text: TextSpan(text: 'Hg', style: text.merge(style)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }();
    final rows = <(bool, DsMenuItemStyle?), double>{};
    double row(bool destructive, DsMenuItemStyle? style) =>
        rows[(destructive, style)] ??= () {
          final s = DsMenuItemStyle.resolveLayers([
            DsMenuItem.defaultStyle(t, destructive: destructive),
            itemTheme,
            style,
          ], const {});
          final padding = (s.padding ?? EdgeInsets.zero).vertical;
          return math.max(s.height ?? 0, padding + line(s.textStyle)) + gap;
        }();
    final menu = DsMenuStyle.resolveLayers([
      DsMenu.defaultStyle(t),
      menuTheme,
    ], const {});
    final divider = (menu.dividerMargin ?? EdgeInsets.zero).vertical + 1 + gap;

    final n = children.length;
    final extents = Float64List(n);
    final ordinal = Int32List(n);
    final enabled = <int>[];
    final scores = <(int, int)>[];
    final chosen = <int>[];
    var items = 0;
    var gutter = false;
    var checks = false;
    for (var i = 0; i < n; i++) {
      final c = children[i];
      if (c is DsMenuItem) {
        extents[i] = row(c.destructive, c.style);
        ordinal[i] = items++;
        if (c._canChoose) enabled.add(i);
        if (c.leading != null) gutter = true;
        if (c.checked != null) checks = true;
        // Bold rows are wider; they are always measured.
        if (c.checked ?? false) {
          chosen.add(i);
        } else {
          scores.add((_score(c), i));
        }
      } else {
        extents[i] = c is DsMenuDivider ? divider : row(false, null);
        ordinal[i] = -1;
      }
    }
    final List<int> sample;
    if (scores.length + chosen.length <= _sampleSize) {
      sample = [...chosen, for (final (_, i) in scores) i]..sort();
    } else {
      scores.sort((a, b) => b.$1.compareTo(a.$1));
      sample = [
        ...chosen.take(_sampleSize ~/ 4),
        for (final (_, i) in scores.take(_sampleSize)) i,
      ]..sort();
    }

    var uniform = n == 0 ? 0.0 : extents[0];
    for (var i = 1; i < n && uniform >= 0; i++) {
      if (extents[i] != uniform) uniform = -1;
    }
    Float64List? offsets;
    double total;
    if (uniform >= 0) {
      total = uniform * n;
    } else {
      offsets = Float64List(n + 1);
      for (var i = 0; i < n; i++) {
        offsets[i + 1] = offsets[i] + extents[i];
      }
      total = offsets[n];
    }
    return _LazyModel._(
      children: children,
      metrics: metrics,
      enabled: Int32List.fromList(enabled),
      ordinal: ordinal,
      itemCount: items,
      uniform: uniform >= 0 ? uniform : null,
      extents: uniform >= 0 ? null : extents,
      offsets: offsets,
      total: total,
      sample: sample,
      gutter: gutter,
      checks: checks,
    );
  }

  /// How wide [item] likely is, in characters. A label that is not a
  /// [Text] counts as [_unknownChars], an icon as [_iconChars].
  static int _score(DsMenuItem item) =>
      (_plainText(item.label)?.length ?? _unknownChars) +
      (item.shortcut?.length ?? 0) +
      switch (item.trailing) {
        null => 0,
        final trailing => _plainText(trailing)?.length ?? _iconChars,
      } +
      (item.leading == null ? 0 : _iconChars) +
      (item.submenu == null ? 0 : _iconChars);

  static const _unknownChars = 24;
  static const _iconChars = 2;
}

/// One item's row, as wide as the real one, for a long menu's width; it
/// is never shown, focused or read.
class _MenuRowMeasure extends StatelessWidget {
  const _MenuRowMeasure({required this.item});

  final DsMenuItem item;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsMenuItemStyle.resolveLayers([
      DsMenuItem.defaultStyle(t, destructive: item.destructive),
      DsMenuItemTheme.of(context).style,
      item.style,
    ], const {});
    final scope = context.dependOnInheritedWidgetOfExactType<_MenuScope>();
    return Padding(
      padding: s.padding ?? EdgeInsets.zero,
      child: _itemRow(
        item,
        s,
        s.foreground ?? t.colors.text,
        gutter: scope?.gutter ?? false,
        checks: scope?.checks ?? false,
        maxLines: 1,
      ),
    );
  }
}

enum _BodySlot { measure, list }

/// A long menu's body: [list] as wide as [measure] wants (within the
/// constraints) and [contentHeight] tall (within them). [measure] is only
/// asked for its width: never laid out, painted, hit or read.
class _LazyMenuBody
    extends SlottedMultiChildRenderObjectWidget<_BodySlot, RenderBox> {
  const _LazyMenuBody({
    required this.measure,
    required this.list,
    required this.contentHeight,
    required this.onViewport,
  });

  final Widget measure, list;
  final double contentHeight;

  /// Called in layout with the list's height, before the list lays out.
  final ValueChanged<double> onViewport;

  @override
  Iterable<_BodySlot> get slots => _BodySlot.values;

  @override
  Widget? childForSlot(_BodySlot slot) => switch (slot) {
    _BodySlot.measure => measure,
    _BodySlot.list => list,
  };

  @override
  _RenderLazyMenuBody createRenderObject(BuildContext context) =>
      _RenderLazyMenuBody(contentHeight, onViewport);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLazyMenuBody renderObject,
  ) => renderObject
    ..contentHeight = contentHeight
    ..onViewport = onViewport;
}

class _RenderLazyMenuBody extends RenderBox
    with SlottedContainerRenderObjectMixin<_BodySlot, RenderBox> {
  _RenderLazyMenuBody(this._contentHeight, this.onViewport);

  double _contentHeight;
  set contentHeight(double value) {
    if (value == _contentHeight) return;
    _contentHeight = value;
    markNeedsLayout();
  }

  ValueChanged<double> onViewport;

  RenderBox? get _measure => childForSlot(_BodySlot.measure);
  RenderBox? get _list => childForSlot(_BodySlot.list);

  /// The sample's widest row; the measure caches it until a row changes.
  /// The measure is offstage, which reports no width of its own.
  double get _width => switch (_measure) {
    RenderProxyBox(:final child?) => child.getMaxIntrinsicWidth(
      double.infinity,
    ),
    final measure? => measure.getMaxIntrinsicWidth(double.infinity),
    null => 0,
  };

  @override
  double computeMinIntrinsicWidth(double height) => _width;

  @override
  double computeMaxIntrinsicWidth(double height) => _width;

  @override
  double computeMinIntrinsicHeight(double width) => _contentHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _contentHeight;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(Size(_width, _contentHeight));

  @override
  void performLayout() {
    final size = this.size = constraints.constrain(
      Size(_width, _contentHeight),
    );
    onViewport(size.height);
    _list?.layout(BoxConstraints.tight(size));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_list case final list?) context.paintChild(list, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _list?.hitTest(result, position: position) ?? false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_list case final list?) visitor(list);
  }
}
