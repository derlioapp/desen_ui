import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/sizes.dart';
import '../theme/theme.dart';
import 'initial_focus.dart';
import 'placement.dart';

/// Opens and closes a [DsAnchoredOverlay] (and the components built on it).
/// The owner creates and disposes it, so the trigger can be any widget.
/// `DsPopover` and `DsMenuAnchor` make their own when given none and hand
/// it to their trigger builder ([DsOverlayTriggerBuilder]).
class DsOverlayController extends ChangeNotifier {
  bool _open = false;
  bool _disposed = false;

  /// Whether the layer is showing (or opening).
  bool get isOpen => _open;

  /// Shows the layer. A no-op when open.
  void open() => _set(true);

  /// Hides the layer. A no-op when closed.
  void close() => _set(false);

  /// Opens a closed layer, closes an open one.
  void toggle() => _set(!_open);

  void _set(bool value) {
    if (_open == value) return;
    _open = value;
    notifyListeners();
  }

  /// Closes the layer of a trigger that is going away: closed at once, so
  /// the layer does not come back when the trigger does, but listeners hear
  /// it only after the frame, when the trigger's owners have settled (they
  /// may be going away too).
  void _closeDetached() {
    if (!_open) return;
    _open = false;
    scheduleMicrotask(() {
      if (!_disposed && !_open) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Builds the trigger of a layer (`DsPopover`, `DsMenuAnchor`) with the
/// [controller] that opens and closes it, e.g.
/// `DsButton(onPressed: controller.toggle, child: …)`. [child] is the
/// layer widget's own `child`, passed through so a part of the trigger
/// that does not depend on the controller is built once.
typedef DsOverlayTriggerBuilder = Widget Function(
  BuildContext context,
  DsOverlayController controller,
  Widget? child,
);

/// What Tab does inside a [DsAnchoredOverlay] that holds focus.
enum DsOverlayTab {
  /// Tab and Shift+Tab close the layer and move focus on from the trigger,
  /// to the control after or before it: menus and selects (WAI-ARIA menu
  /// button and select-only combobox). The layer is part of its trigger,
  /// not a stop of its own.
  close,

  /// Tab moves through the layer's controls. Past the last one the layer
  /// closes and focus moves on to the control after the trigger; before
  /// the first one it closes and focus goes back to the trigger: popovers
  /// (WAI-ARIA non-modal dialog). Focus is never trapped.
  flow,
}

/// The groups of the layers this context sits in, innermost last. A layer
/// opened from inside another joins its ancestors' tap regions, so a tap in
/// the inner layer is not "outside" for the outer one.
class _Lineage extends InheritedWidget {
  const _Lineage({required this.groups, required super.child});

  final List<Object> groups;

  static List<Object> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Lineage>()?.groups ??
      const [];

  @override
  bool updateShouldNotify(_Lineage oldWidget) => oldWidget.groups != groups;
}

/// A layer hung from its trigger: the engine behind popovers, menus,
/// tooltips and selects.
///
/// - **Placement:** [side] and [align] are preferences. The layer flips to
///   the other side when the preferred one cannot hold it, shifts to stay
///   inside the window, and follows the trigger through scrolling and
///   resizing (it is laid out against the trigger's live position).
/// - **Dismissal:** a pointer down outside the layer and its trigger closes
///   it without swallowing the event; Escape closes the innermost layer.
///   Layers opened from inside a layer nest: a tap in the inner one keeps
///   the outer one open.
/// - **Focus:** with [focusOnOpen], focus moves into the layer when it
///   opens and returns to the trigger when it closes (to where it was when
///   the trigger has nothing focusable). In a [DsOverlayTab.flow] layer it
///   lands on the control that asks for it (`autofocus: true`), else on
///   the first control inside. [tab] says how Tab leaves it.
/// - **Keyboard and anchor:** the layer keeps clear of the on-screen
///   keyboard. When its trigger leaves the window (scrolled away, or its
///   page slides out) the layer closes and focus goes back to the
///   trigger, so no key acts on a layer nobody can see.
/// - **Back:** while open, the system back (Android back button or
///   gesture, `Navigator.maybePop`) closes the innermost open layer
///   instead of the page. The layer registers with its trigger's
///   [ModalRoute]; with no route above the trigger, back is not
///   intercepted.
/// - **Lifetime:** a trigger that leaves the tree closes its layer, so it
///   does not reopen when the trigger comes back.
/// - **Motion:** it grows from the edge facing the trigger with the
///   movement spring and fades out with the tone spring; with reduced
///   motion it only fades.
///
/// Needs an [Overlay] above it, which [DsApp] and every `WidgetsApp`
/// provide; opening one without it fails with an error that says
/// so.
class DsAnchoredOverlay extends StatefulWidget {
  /// Creates an anchored layer.
  const DsAnchoredOverlay({
    super.key,
    required this.controller,
    required this.overlayBuilder,
    required this.child,
    this.side = DsSide.bottom,
    this.align = DsAlign.start,
    this.gap = DsSpace.s6,
    this.focusOnOpen = true,
    this.dismissOnTapOutside = true,
    this.onDismissed,
    this.anchorPoint,
    this.matchAnchorWidth = false,
    this.tab = DsOverlayTab.flow,
    this.expandsTrigger = false,
  });

  /// Opens and closes the layer.
  final DsOverlayController controller;

  /// Builds the layer while it is open (and while it animates closed).
  final WidgetBuilder overlayBuilder;

  /// The trigger; the layer is placed against its box.
  final Widget child;

  /// Preferred side; flips when it does not fit.
  final DsSide side;

  /// Preferred alignment along the trigger.
  final DsAlign align;

  /// Distance between trigger and layer.
  final double gap;

  /// Moves focus into the layer on open and back on close. Off for
  /// tooltips.
  final bool focusOnOpen;

  /// Closes the layer on a pointer down outside it and its trigger.
  final bool dismissOnTapOutside;

  /// Called when the user dismisses the layer (outside tap or Escape),
  /// after the controller closes.
  final VoidCallback? onDismissed;

  /// Places the layer against this point (in the trigger's coordinates)
  /// instead of the trigger's box, e.g. where a context menu was opened.
  final Offset? anchorPoint;

  /// Makes the layer at least as wide as the trigger (selects).
  final bool matchAnchorWidth;

  /// What Tab does while focus is in the layer.
  final DsOverlayTab tab;

  /// Tells the trigger's buttons whether the layer is open, so a [child]
  /// that is a `DsButton` is announced as expanded or collapsed (WAI-ARIA
  /// menu button, `aria-expanded`). On for menus and popovers; off for
  /// tooltips and for controls that announce it themselves (selects,
  /// comboboxes).
  final bool expandsTrigger;

  /// Whether the layer opened by the trigger [context] is in is open: for
  /// triggers under a [DsAnchoredOverlay] with [expandsTrigger], null
  /// elsewhere. `DsButton` reads it when its own `semanticExpanded` is null.
  static bool? triggerExpandedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TriggerExpanded>()?.open;

  @override
  State<DsAnchoredOverlay> createState() => _DsAnchoredOverlayState();
}

/// The open state of the layer a trigger opens
/// ([DsAnchoredOverlay.expandsTrigger]).
class _TriggerExpanded extends InheritedWidget {
  const _TriggerExpanded({required this.open, required super.child});

  final bool open;

  @override
  bool updateShouldNotify(_TriggerExpanded oldWidget) => open != oldWidget.open;
}

/// The back handler of an open layer, registered with its trigger's route.
class _BackEntry extends PopEntry<Object?> {
  _BackEntry(this.onBack);

  final VoidCallback onBack;

  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) onBack();
  }
}

class _DsAnchoredOverlayState extends State<DsAnchoredOverlay>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _group = Object();
  // Reached through its trigger, never by Tab order from the page: the
  // layer floats wherever it fits, so its place in reading order means
  // nothing.
  final _scope = FocusScopeNode(
    debugLabel: 'DsAnchoredOverlay',
    skipTraversal: true,
  );
  final _trigger = FocusNode(
    debugLabel: 'DsAnchoredOverlay trigger',
    canRequestFocus: false,
    skipTraversal: true,
  );
  late final _reveal = AnimationController.unbounded(vsync: this);
  FocusNode? _returnFocus;

  /// Open layers, oldest first: system back closes the newest.
  static final _openLayers = <_DsAnchoredOverlayState>[];
  static bool _backPending = false;

  late final _back = _BackEntry(_onBack);
  ModalRoute<Object?>? _route;
  bool _backRegistered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    if (widget.controller.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _unregisterBack();
      _route = route;
      if (_openLayers.contains(this)) _registerBack();
    }
  }

  @override
  void didUpdateWidget(DsAnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    // The trigger is gone: its layer closes for good instead of coming
    // back open with it (eng L8).
    widget.controller._closeDetached();
    _forget();
    _back.canPopNotifier.dispose();
    _reveal.dispose();
    _scope.dispose();
    _trigger.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    widget.controller.isOpen ? _show() : _hide();
  }

  // System back: an open layer takes it before its page (K-53).

  void _remember() {
    if (_openLayers.contains(this)) return;
    _openLayers.add(this);
    _registerBack();
  }

  void _forget() {
    _openLayers.remove(this);
    _unregisterBack();
  }

  void _registerBack() {
    if (_backRegistered || _route == null) return;
    _route!.registerPopEntry(_back);
    _backRegistered = true;
  }

  void _unregisterBack() {
    if (!_backRegistered) return;
    _route?.unregisterPopEntry(_back);
    _backRegistered = false;
  }

  /// Every open layer of the route hears the same back; the newest one
  /// closes, once the route is done notifying.
  void _onBack() {
    if (_backPending) return;
    _backPending = true;
    scheduleMicrotask(() {
      _backPending = false;
      final newest = _openLayers.lastWhere(
        (layer) => layer._backRegistered && layer._route == _route,
        orElse: () => this,
      );
      if (newest.mounted) newest._dismiss();
    });
  }

  /// The trigger left the window: close, focus back on the trigger.
  void _onAnchorLost() {
    if (mounted) _dismiss();
  }

  void _show() {
    if (Overlay.maybeOf(context) == null) {
      assert(() {
        throw FlutterError.fromParts([
          ErrorSummary(
            '${widget.child.runtimeType} opened a layer, but there '
            'is no Overlay above it.',
          ),
          ErrorDescription(
            'Desen layers (selects, autocompletes, menus, popovers, date and '
            'time pickers) float in an Overlay above the page. '
            'DsScope alone does not add one.',
          ),
          ErrorHint(
            'Put the widget under DsApp, or under any WidgetsApp, MaterialApp '
            'or CupertinoApp (their Navigator holds an Overlay). Without an '
            'app root, wrap the page in an Overlay: '
            'Overlay(initialEntries: [OverlayEntry(builder: (_) => page)]).',
          ),
        ]);
      }());
      return;
    }
    _remember();
    final motion = DsTheme.motionOf(context);
    if (!_portal.isShowing) _portal.show();
    _scope.descendantsAreTraversable = true;
    _reveal.animateWith(
      (motion.reduced ? motion.toneSpring : motion.moveSpring).simulate(
        from: _reveal.value,
        to: 1,
        velocity: _reveal.velocity,
      ),
    );
    if (widget.focusOnOpen) {
      _returnFocus = _returnTarget();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.controller.isOpen) return;
        _scope.requestFocus();
        if (widget.tab != DsOverlayTab.flow) return;
        // A panel (popover) puts focus on its first control unless one
        // asked for it: that request and any autofocus apply in a
        // microtask already queued, this one runs after them. Menus and
        // selects place focus themselves.
        scheduleMicrotask(() {
          if (mounted && widget.controller.isOpen) focusFirstControl(_scope);
        });
      });
    }
    setState(() {});
  }

  /// Where focus goes back when the layer closes: the trigger's focused
  /// control, else its first focusable one (a click does not focus),
  /// else whatever had focus.
  FocusNode? _returnTarget() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && _trigger.descendants.contains(primary)) {
      return primary;
    }
    return _trigger.traversalDescendants.firstOrNull ?? primary;
  }

  void _hide() {
    _forget();
    if (!_portal.isShowing) return;
    // A closing layer is out of the Tab order, so focus moving on from
    // the trigger does not land in it.
    _scope.descendantsAreTraversable = false;
    _restoreFocus();
    // The closing layer no longer takes pointers.
    setState(() {});
    final motion = DsTheme.motionOf(context);
    _reveal
        .animateWith(
          motion.toneSpring.simulate(
            from: _reveal.value,
            to: 0,
            velocity: _reveal.velocity,
          ),
        )
        .then((_) {
          if (mounted && !widget.controller.isOpen) {
            _portal.hide();
            setState(() {});
          }
        });
  }

  /// Gives focus back if it is in the layer; returns where it went.
  FocusNode? _restoreFocus() {
    FocusNode? target;
    if (widget.focusOnOpen && _scope.hasFocus) {
      final back = _returnFocus;
      if (back != null && back.context != null) {
        back.requestFocus();
        target = back;
      }
    }
    _returnFocus = null;
    return target;
  }

  void _dismiss() {
    if (!widget.controller.isOpen) return;
    widget.controller.close();
    widget.onDismissed?.call();
  }

  /// Closes the layer; focus goes back to the trigger and, unless
  /// [toTrigger], on to the control after ([forward]) or before it.
  void _leave({required bool forward, bool toTrigger = false}) {
    final back = _returnFocus;
    _dismiss();
    if (toTrigger || back == null || back.context == null) return;
    // Traversal moves from the scope's focused child, so move on once
    // focus is back on the trigger (focus changes apply in a microtask).
    scheduleMicrotask(() {
      if (back.context == null) return;
      forward ? back.nextFocus() : back.previousFocus();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      final backward = HardwareKeyboard.instance.isShiftPressed;
      switch (widget.tab) {
        case DsOverlayTab.close:
          _leave(forward: !backward);
          return KeyEventResult.handled;
        case DsOverlayTab.flow:
          final primary = FocusManager.instance.primaryFocus;
          final policy =
              (primary?.context == null
                  ? null
                  : FocusTraversalGroup.maybeOf(primary!.context!)) ??
              ReadingOrderTraversalPolicy();
          final first = policy.findFirstFocus(_scope, ignoreCurrentFocus: true);
          final hasControls = first != null && first != _scope;
          if (primary == _scope && hasControls && !backward) {
            // Nothing inside has focus yet: Tab enters the layer.
            first.requestFocus();
            return KeyEventResult.handled;
          }
          final edge = backward
              ? first
              : policy.findLastFocus(_scope, ignoreCurrentFocus: true);
          // Inside: let Tab move between the layer's controls.
          if (primary != _scope && hasControls && primary != edge) {
            return KeyEventResult.ignored;
          }
          _leave(forward: !backward, toTrigger: backward);
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ancestors = _Lineage.of(context);
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) {
        final point = widget.anchorPoint;
        // A trigger kept alive off screen in a lazy list (focused, or the
        // table's active row) has a zeroed paint transform, so its rect
        // comes out NaN: that is a trigger that left the window.
        final anchor = MatrixUtils.transformRect(
          info.childPaintTransform,
          point == null ? Offset.zero & info.childSize : point & Size.zero,
        );
        final motion = DsTheme.motionOf(context);
        Widget layer = _Lineage(
          groups: [...ancestors, _group],
          // The scope holds the keyboard: keys from anything focused inside
          // bubble up to it, and when nothing inside takes focus the scope
          // itself is focused, so Escape always lands here.
          child: FocusScope(
            node: _scope,
            onKeyEvent: _onKey,
            child: Builder(builder: widget.overlayBuilder),
          ),
        );
        layer = TapRegion(
          groupId: _group,
          onTapOutside: widget.dismissOnTapOutside ? (_) => _dismiss() : null,
          child: layer,
        );
        // A tap in this layer is inside every enclosing layer too.
        for (final group in ancestors.reversed) {
          layer = TapRegion(groupId: group, child: layer);
        }
        return _Placed(
          anchor: anchor,
          side: widget.side,
          align: widget.align,
          gap: widget.gap,
          // Clear of the system bars and the on-screen keyboard.
          margin:
              MediaQuery.paddingOf(context) +
              MediaQuery.viewInsetsOf(context) +
              const EdgeInsets.all(DsSpace.s8),
          direction: Directionality.of(context),
          reveal: _reveal,
          travel: motion.reduced ? 0 : motion.overlayOffset,
          startScale: motion.reduced ? 1 : motion.overlayScale,
          minWidth: widget.matchAnchorWidth && anchor.isFinite
              ? anchor.width
              : 0,
          interactive: widget.controller.isOpen,
          onAnchorLost: _onAnchorLost,
          child: layer,
        );
      },
      child: TapRegion(
        groupId: _group,
        child: Focus(
          focusNode: _trigger,
          child: widget.expandsTrigger
              ? _TriggerExpanded(
                  open: widget.controller.isOpen,
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}

/// Lays out the layer against the anchor (flip and shift) and paints the
/// reveal: fade plus a short travel and scale from the anchor-facing edge.
class _Placed extends SingleChildRenderObjectWidget {
  const _Placed({
    required this.anchor,
    required this.side,
    required this.align,
    required this.gap,
    required this.margin,
    required this.direction,
    required this.reveal,
    required this.travel,
    required this.startScale,
    this.minWidth = 0,
    this.interactive = true,
    this.onAnchorLost,
    super.child,
  });

  final Rect anchor;
  final DsSide side;
  final DsAlign align;
  final double gap;
  final EdgeInsets margin;
  final TextDirection direction;
  final Animation<double> reveal;
  final double travel, startScale, minWidth;
  final bool interactive;
  final VoidCallback? onAnchorLost;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPlaced(
    anchor: anchor,
    side: side,
    align: align,
    gap: gap,
    margin: margin,
    direction: direction,
    reveal: reveal,
    travel: travel,
    startScale: startScale,
    minWidth: minWidth,
    interactive: interactive,
    onAnchorLost: onAnchorLost,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderPlaced)
      ..anchor = anchor
      ..side = side
      ..align = align
      ..gap = gap
      ..margin = margin
      ..direction = direction
      ..reveal = reveal
      ..travel = travel
      ..startScale = startScale
      ..minWidth = minWidth
      ..interactive = interactive
      ..onAnchorLost = onAnchorLost;
  }
}

class _RenderPlaced extends RenderShiftedBox {
  _RenderPlaced({
    required this._anchor,
    required this._side,
    required this._align,
    required this._gap,
    required this._margin,
    required this._direction,
    required this._reveal,
    required this._travel,
    required this._startScale,
    required this._minWidth,
    required this.interactive,
    this.onAnchorLost,
  }) : super(null);

  /// False while closing: a layer on its way out takes no pointers.
  bool interactive;

  /// Called after the frame in which an open layer's anchor left the
  /// window.
  VoidCallback? onAnchorLost;

  Rect _anchor;
  set anchor(Rect value) {
    if (_anchor == value) return;
    _anchor = value;
    markNeedsLayout();
  }

  DsSide _side;
  set side(DsSide value) {
    if (_side == value) return;
    _side = value;
    markNeedsLayout();
  }

  DsAlign _align;
  set align(DsAlign value) {
    if (_align == value) return;
    _align = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  EdgeInsets _margin;
  set margin(EdgeInsets value) {
    if (_margin == value) return;
    _margin = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  double _travel;
  set travel(double value) {
    if (_travel == value) return;
    _travel = value;
    markNeedsPaint();
  }

  double _minWidth;
  set minWidth(double value) {
    if (_minWidth == value) return;
    _minWidth = value;
    markNeedsLayout();
  }

  double _startScale;
  set startScale(double value) {
    if (_startScale == value) return;
    _startScale = value;
    markNeedsPaint();
  }

  Animation<double> _reveal;
  set reveal(Animation<double> v) {
    if (_reveal == v) return;
    if (attached) _reveal.removeListener(markNeedsPaint);
    _reveal = v;
    if (attached) _reveal.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  DsSide _placedSide = DsSide.bottom;

  /// Whether the anchor is on screen. A layer whose anchor scrolled away
  /// hides instead of clinging to the window edge.
  bool _anchorVisible = true;
  final _opacity = LayerHandle<OpacityLayer>();
  final _transform = LayerHandle<TransformLayer>();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _reveal.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _reveal.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _opacity.layer = null;
    _transform.layer = null;
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    // A NaN anchor (a trigger kept alive off screen) "overlaps" every rect,
    // since each comparison with NaN is false: test it first.
    final visible = _anchor.isFinite && _anchor.overlaps(Offset.zero & size);
    final room = Size(
      (size.width - _margin.horizontal).clamp(0, double.infinity),
      (size.height - _margin.vertical).clamp(0, double.infinity),
    );
    final minWidth = _minWidth.clamp(0.0, room.width);
    child.layout(
      BoxConstraints(
        minWidth: minWidth,
        maxWidth: room.width,
        maxHeight: room.height,
      ),
      parentUsesSize: true,
    );
    if (!_anchor.isFinite) {
      // Nothing to place against: keep the last place (the layer is hidden
      // and closing) instead of laying it out at NaN.
      _reportLost(visible);
      return;
    }
    DsPlacement place() => dsPlace(
      anchor: _anchor,
      size: child.size,
      viewport: size,
      side: _side,
      align: _align,
      gap: _gap,
      margin: _margin,
      direction: _direction,
    );
    var placement = place();
    // Too long for the side it landed on: cap the main axis and place again.
    final vertical =
        placement.side == DsSide.top || placement.side == DsSide.bottom;
    final extent = vertical ? child.size.height : child.size.width;
    if (extent > placement.maxExtent) {
      child.layout(
        BoxConstraints(
          minWidth: vertical ? minWidth : 0,
          maxWidth: vertical ? room.width : placement.maxExtent,
          maxHeight: vertical ? placement.maxExtent : room.height,
        ),
        parentUsesSize: true,
      );
      placement = place();
    }
    _placedSide = placement.side;
    _reportLost(visible);
    (child.parentData! as BoxParentData).offset = placement.offset;
  }

  /// Records whether the anchor is on screen; an open layer whose anchor
  /// left hears [onAnchorLost] after the frame.
  void _reportLost(bool visible) {
    if (!visible && interactive && onAnchorLost != null) {
      // Not during layout: closing rebuilds and moves focus.
      final lost = onAnchorLost!;
      WidgetsBinding.instance.addPostFrameCallback((_) => lost());
    }
    _anchorVisible = visible;
  }

  /// The reveal: a scale and short travel from the edge facing the anchor,
  /// in this box's coordinates.
  Matrix4 _revealTransform() {
    final child = this.child!;
    final box = (child.parentData! as BoxParentData).offset & child.size;
    // Grow from the edge facing the anchor, travelling toward it.
    final (Offset origin, Offset away) = switch (_placedSide) {
      DsSide.bottom => (box.topCenter, const Offset(0, -1)),
      DsSide.top => (box.bottomCenter, const Offset(0, 1)),
      DsSide.start =>
        _direction == TextDirection.ltr
            ? (box.centerRight, const Offset(1, 0))
            : (box.centerLeft, const Offset(-1, 0)),
      DsSide.end =>
        _direction == TextDirection.ltr
            ? (box.centerLeft, const Offset(-1, 0))
            : (box.centerRight, const Offset(1, 0)),
    };
    final progress = _reveal.value.clamp(0.0, 1.2);
    final scale = lerpDouble(_startScale, 1, progress)!;
    final shift = away * (_travel * (1 - progress));
    return Matrix4.identity()
      ..translateByDouble(origin.dx + shift.dx, origin.dy + shift.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final alpha = (_reveal.value.clamp(0.0, 1.0) * 255).round();
    if (alpha == 0 || !_anchorVisible) {
      _opacity.layer = null;
      _transform.layer = null;
      return;
    }
    final childOffset = (child.parentData! as BoxParentData).offset;
    final matrix = _revealTransform();
    _opacity.layer = context.pushOpacity(offset, alpha, (context, offset) {
      _transform.layer = context.pushTransform(
        needsCompositing,
        offset,
        matrix,
        (context, offset) => context.paintChild(child, offset + childOffset),
        oldLayer: _transform.layer,
      );
    }, oldLayer: _opacity.layer);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    // Closing, hidden or not yet visible layers do not take pointers.
    if (child == null ||
        !interactive ||
        !_anchorVisible ||
        _reveal.value <= 0.05) {
      return false;
    }
    // Hit testing sees the layer where it is painted, mid-reveal too.
    return result.addWithPaintTransform(
      transform: _paintTransform(child),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  Matrix4 _paintTransform(RenderBox child) {
    final offset = (child.parentData! as BoxParentData).offset;
    return _revealTransform()..translateByDouble(offset.dx, offset.dy, 0, 1);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.multiply(_paintTransform(child));
}
