import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/modal_route.dart';
import '../../overlay/plain_text.dart';
import '../../overlay/scroll_keys.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/radii.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import '../../foundation/component_theme.dart';
import '../../foundation/spring.dart';
import 'panel_style.dart';

/// How [showDsPanel] presents a panel.
enum DsPanelPresentation {
  /// A side panel on wide screens, a bottom sheet on narrow ones.
  auto,

  /// From the end edge (right in LTR).
  side,

  /// From the bottom, with a drag handle.
  bottom,
}

/// Below this width [DsPanelPresentation.auto] shows a bottom sheet.
const double kDsPanelBreakpoint = 640;

/// The tallest a bottom sheet gets, as a share of the window's height.
const double _sheetMaxShare = .9;

/// A side panel or bottom sheet: a title with a close button, content that
/// scrolls when long, and an optional footer. Show it with [showDsPanel],
/// which places it; the panel draws its own surface there, sized by its
/// style ([DsPanelStyle.width], [DsPanelStyle.sheetMaxWidth]).
///
/// With focus on the close button, the footer or another control in the
/// panel, Page Up, Page Down, Arrow Up, Arrow Down, Home and End scroll
/// long content; a focused text field keeps these keys.
class DsPanel extends StatelessWidget {
  /// Creates a panel.
  const DsPanel({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.showClose,
    this.scrollable = true,
    this.semanticLabel,
    this.style,
  });

  /// The panel's name, shown in the header. When it is a [Text], its text
  /// also names the panel for screen readers.
  final Widget title;

  /// The content; scrolls when it does not fit, unless [scrollable] is
  /// false.
  final Widget child;

  /// Whether the panel scrolls [child] when it does not fit. Set it to false
  /// for content that scrolls itself, such as a `ListView` built lazily:
  /// the child then gets the room left between the header and the footer
  /// as a bounded height (all of it in a side panel; up to it in a bottom
  /// sheet, which a `ListView` fills). The keys that scroll long content
  /// are then the child's own.
  final bool scrollable;

  /// Actions along the bottom, e.g. a full-width primary button.
  final Widget? footer;

  /// Shows a close button in the header. Defaults to whether the panel
  /// can be dismissed (`showDsPanel(dismissible:)`).
  final bool? showClose;

  /// Names the panel for screen readers. Defaults to the [title]'s text,
  /// then to the localized "Dialog".
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsPanelStyle? style;

  /// Desen's default panel style under [theme].
  static DsPanelStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsPanelStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      borderRadius: BorderRadius.circular(theme.radii.overlay),
      padding: const EdgeInsets.all(DsSpace.s20),
      margin: const EdgeInsets.all(DsSpace.s8),
      width: 400,
      gap: DsSpace.s16,
      titleStyle: theme.typography.heading.copyWith(color: k.text),
      // Translucent subtle ink, like the scrollbar thumb: it reads in both
      // modes and on a panel's own background.
      grabberColor: k.textSubtle.withValues(alpha: .65),
      grabberSize: const Size(36, 4),
      sheetMaxWidth: 560,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsPanelStyle.resolveLayers([
      defaultStyle(t),
      DsPanelTheme.of(context).style,
      style,
    ], const {});
    final kind = _PanelKind.maybeOf(context);
    final bottom = kind?.bottom ?? false;
    // A side panel, and a bottom sheet held at a detent, have a set height:
    // the body fills it and the footer sits at the bottom. A bottom sheet
    // without detents hugs its content.
    final hug = bottom && kind?.detents == null;
    // A bottom sheet keeps clear of the system's bottom inset (the home
    // indicator) itself: with a bottom margin it floats above the inset,
    // without one it reaches the screen's bottom edge and pads the inset
    // inside its surface.
    final inset = kind?.bottomInset ?? 0;
    final margin = s.margin ?? EdgeInsets.zero;
    final edge =
        inset > 0 && margin.resolve(Directionality.of(context)).bottom == 0;
    final l10n = DsLocalizations.of(context);
    final body = Semantics(
      container: true,
      role: SemanticsRole.dialog,
      scopesRoute: true,
      namesRoute: true,
      label: semanticLabel ?? plainTextOf(title) ?? l10n.dialog,
      explicitChildNodes: true,
      child: Padding(
        padding: (s.padding ?? EdgeInsets.zero).add(
          EdgeInsets.only(bottom: edge ? inset : 0),
        ),
        // The frame and the panel keep clear of the system insets, so the
        // content sees none left: a ListView in it does not pad them again.
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: kind != null,
          removeTop: kind != null,
          removeRight: kind != null,
          removeBottom: kind != null,
          child: LayerScrollKeys(
            builder: (context, controller) => Column(
              mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: s.gap ?? DsSpace.s16,
              children: [
                if (bottom)
                  _Grabber(
                    detents: kind?.detents,
                    child: Center(
                      child: Container(
                        width: s.grabberSize!.width,
                        height: s.grabberSize!.height,
                        decoration: BoxDecoration(
                          color: s.grabberColor,
                          borderRadius: BorderRadius.circular(DsRadii.pill),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: DefaultTextStyle.merge(
                          style: s.titleStyle,
                          child: title,
                        ),
                      ),
                    ),
                    if (showClose ?? kind?.dismissible ?? true)
                      DsComponentThemeReset<DsButtonThemeData>(
                        child: DsButton.icon(
                          variant: DsButtonVariant.ghost,
                          size: DsSize.sm,
                          style: s.closeStyle,
                          icon: const DsIcon(DsIcons.x),
                          semanticLabel: l10n.close,
                          // A close button shown on a panel that cannot be
                          // dismissed (showClose: true) is the panel's own
                          // action: it closes even though back does not.
                          onPressed: () => kind?.dismissible == false
                              ? Navigator.of(context).pop()
                              : Navigator.of(context).maybePop(),
                        ),
                      ),
                  ],
                ),
                Flexible(
                  fit: hug ? FlexFit.loose : FlexFit.tight,
                  child: scrollable
                      ? SingleChildScrollView(
                          controller: controller,
                          child: child,
                        )
                      : child,
                ),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
    // Outside showDsPanel (a preview) the panel is only its content.
    if (kind == null) return body;
    final surface = DsSurface(
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: s.shadows ?? const [],
      ),
      backdropFilter: s.backdropFilter,
      child: body,
    );
    return _TakesInset(
      child: Padding(
        padding: margin.add(EdgeInsets.only(bottom: edge ? 0 : inset)),
        // One box for both, so that the content keeps its state when the
        // window's size turns one presentation into the other.
        child: ConstrainedBox(
          constraints: bottom
              ? BoxConstraints(
                  maxWidth: s.sheetMaxWidth!,
                  maxHeight: MediaQuery.sizeOf(context).height * _sheetMaxShare,
                )
              : BoxConstraints.tightFor(width: s.width),
          child: surface,
        ),
      ),
    );
  }
}

/// The grabber of a bottom sheet. With more than one detent, screen
/// readers adjust it to move the sheet between them, as iOS's sheet
/// grabber; otherwise it says nothing.
class _Grabber extends StatelessWidget {
  const _Grabber({required this.detents, required this.child});

  final _Detents? detents;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = detents;
    if (d == null || d.shares.length < 2) {
      return ExcludeSemantics(child: child);
    }
    final l10n = DsLocalizations.of(context);
    String value(int i) => l10n.percent((d.shares[i] * 100).round());
    final up = d.index + 1 < d.shares.length, down = d.index > 0;
    return Semantics(
      label: l10n.resizeSheet,
      value: value(d.index),
      increasedValue: up ? value(d.index + 1) : null,
      decreasedValue: down ? value(d.index - 1) : null,
      onIncrease: up ? () => d.goTo(d.index + 1) : null,
      onDecrease: down ? () => d.goTo(d.index - 1) : null,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// A bottom sheet's detents as its grabber sees them: the [shares] of the
/// window's height, the [index] it rests at, and [goTo] to move.
@immutable
class _Detents {
  const _Detents(this.shares, this.index, this.goTo);

  final List<double> shares;
  final int index;
  final ValueChanged<int> goTo;

  @override
  bool operator ==(Object other) =>
      other is _Detents &&
      other.index == index &&
      listEquals(other.shares, shares);

  @override
  int get hashCode => Object.hash(index, Object.hashAll(shares));
}

/// Positions the panel for its presentation, clear of the system bars and
/// the on-screen keyboard, and handles the bottom sheet's drag: between
/// its detents, and down to dismiss. The panel draws its own surface, so
/// its style sizes it.
class _PanelFrame extends StatefulWidget {
  const _PanelFrame({
    required this.bottom,
    required this.dismissible,
    required this.detents,
    required this.initialDetent,
    required this.child,
  });

  final bool bottom;
  final bool dismissible;

  /// Shares of the window's height, ascending; null to hug the content.
  final List<double>? detents;

  /// Index into [detents].
  final int initialDetent;
  final Widget child;

  @override
  State<_PanelFrame> createState() => _PanelFrameState();
}

class _PanelKind extends InheritedWidget {
  const _PanelKind({
    required this.bottom,
    required this.dismissible,
    required this.detents,
    required this.bottomInset,
    required super.child,
  });

  final bool bottom;
  final bool dismissible;

  /// The system's bottom inset a bottom sheet keeps clear of itself; 0 for
  /// a side panel.
  final double bottomInset;

  /// A bottom sheet's detents; null for a side panel or a sheet that hugs
  /// its content.
  final _Detents? detents;

  static _PanelKind? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PanelKind>();

  @override
  bool updateShouldNotify(_PanelKind oldWidget) =>
      oldWidget.bottom != bottom ||
      oldWidget.dismissible != dismissible ||
      oldWidget.detents != detents ||
      oldWidget.bottomInset != bottomInset;
}

class _PanelFrameState extends State<_PanelFrame>
    with SingleTickerProviderStateMixin {
  final _sheet = GlobalKey();
  double _drag = 0;

  /// The detent the sheet rests at, or heads for.
  late int _detent = widget.initialDetent;

  /// The sheet's height while a drag or a settle moves it; at rest the
  /// height comes from [_detent] and the window, so it follows a resize.
  late final _height = AnimationController.unbounded(vsync: this);
  bool _moving = false;

  /// Counts the moves, so that a settle cut short by a new drag does not
  /// end it.
  int _move = 0;

  @override
  void didUpdateWidget(_PanelFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottom != widget.bottom) _drag = 0;
  }

  @override
  void dispose() {
    _height.dispose();
    super.dispose();
  }

  /// The detents' heights in this window, from its bottom edge, each held
  /// below the tallest a sheet gets and the room between the top system
  /// bar and the keyboard; null without detents.
  List<double>? _heights() {
    final detents = widget.detents;
    if (detents == null || !widget.bottom) return null;
    final media = MediaQuery.of(context);
    final window = media.size.height;
    final room = window - media.padding.top - media.viewInsets.bottom;
    final most = math.max(0.0, math.min(window * _sheetMaxShare, room));
    return [for (final d in detents) math.min(d * window, most)];
  }

  /// Takes over the height from where it shows, for a drag or a settle.
  void _startMove(List<double> heights) {
    _move++;
    if (!_moving) {
      _height.value = heights[_detent];
      _moving = true;
    } else {
      _height.stop();
    }
  }

  /// Moves to detent [index], keeping the drag's [velocity] (pixels per
  /// second, upward positive) and without bounce: an overshooting sheet
  /// would lift off the bottom edge. Under reduced motion it jumps.
  void _settle(int index, List<double> heights, {double velocity = 0}) {
    final motion = DsTheme.motionOf(context);
    final move = _move;
    void rest() {
      if (mounted && move == _move) setState(() => _moving = false);
    }

    setState(() => _detent = index);
    if (motion.reduced) {
      _height.value = heights[index];
      rest();
      return;
    }
    _height
        .animateWith(
          DsSpring(duration: motion.moveSpring.duration).simulate(
            from: _height.value,
            to: heights[index],
            velocity: velocity,
          ),
        )
        .whenCompleteOrCancel(rest);
  }

  void _goTo(int index) {
    final heights = _heights();
    if (heights == null || index < 0 || index >= heights.length) return;
    _startMove(heights);
    _settle(index, heights);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final heights = _heights();
    if (heights == null) {
      setState(() => _drag = (_drag + d.delta.dy).clamp(0, 9999));
      return;
    }
    _startMove(heights);
    var dy = d.delta.dy;
    setState(() {
      // Up: first take back a drag toward dismissal.
      if (dy < 0 && _drag > 0) {
        final back = math.min(_drag, -dy);
        _drag -= back;
        dy += back;
      }
      var height = _height.value - dy;
      if (height < heights.first) {
        // Below the lowest detent the sheet slides down to dismiss.
        if (widget.dismissible) _drag += heights.first - height;
        height = heights.first;
      }
      _height.value = math.min(height, heights.last);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    // ds-raw: a divisor guard, not a size
    final sheet = _sheet.currentContext?.size?.height ?? 1;
    if (_drag > 0 || _heights() == null) {
      // Past a third of the sheet's height, or flicked, it closes.
      if (_drag > sheet / 3 || velocity > _flick) {
        _dismiss();
      } else {
        setState(() => _drag = 0);
      }
      if (_heights() case final heights?) _settle(0, heights);
      return;
    }
    final heights = _heights()!;
    final height = _height.value;
    var index = 0;
    if (velocity.abs() > _flick) {
      // A flick goes to the next detent its way.
      if (velocity < 0) {
        index = heights.indexWhere((h) => h > height + 1);
        if (index < 0) index = heights.length - 1;
      } else {
        index = heights.lastIndexWhere((h) => h < height - 1);
        if (index < 0) index = 0;
      }
    } else {
      for (var i = 1; i < heights.length; i++) {
        if ((heights[i] - height).abs() < (heights[index] - height).abs()) {
          index = i;
        }
      }
    }
    _settle(index, heights, velocity: -velocity);
  }

  /// A drag faster than this, in pixels per second, is a flick.
  static const double _flick = 700;

  /// A drag past the threshold: asks the route to close. When it refuses
  /// (a [PopScope] that cannot pop, e.g. to ask about unsaved changes),
  /// the sheet goes back in place.
  Future<void> _dismiss() async {
    final route = ModalRoute.of(context);
    await Navigator.of(context).maybePop();
    if (!mounted) return;
    final closing = switch (route?.animation?.status) {
      AnimationStatus.reverse || AnimationStatus.dismissed => true,
      _ => false,
    };
    if (!closing) setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Clear of the system bars and the on-screen keyboard. A bottom sheet
    // leaves the bottom inset to the panel (_BottomInset).
    final padding = media.padding;
    final inset = widget.bottom ? padding.bottom : 0.0;
    final margin = EdgeInsets.fromLTRB(
      padding.left,
      padding.top,
      padding.right,
      padding.bottom - inset + media.viewInsets.bottom,
    );
    final heights = _heights();
    final detents = widget.detents;
    // Keyed, so that the panel keeps its state (and focus) when the
    // window's size turns one presentation into the other.
    Widget panel = KeyedSubtree(
      key: _sheet,
      child: _PanelKind(
        bottom: widget.bottom,
        dismissible: widget.dismissible,
        detents: heights == null || detents == null
            ? null
            : _Detents(detents, _detent, _goTo),
        bottomInset: inset,
        child: widget.child,
      ),
    );
    if (!widget.bottom) {
      return Padding(
        padding: margin,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(height: double.infinity, child: panel),
        ),
      );
    }
    if (heights != null) {
      final sheet = panel;
      panel = AnimatedBuilder(
        animation: _height,
        builder: (context, _) => SizedBox(
          height: _moving
              ? _height.value.clamp(heights.first, heights.last)
              : heights[_detent],
          child: sheet,
        ),
      );
    }
    // A sheet that cannot be dismissed drags only between its detents.
    final drags = widget.dismissible || heights != null;
    return Padding(
      padding: margin,
      child: _BottomInset(
        inset: inset,
        child: Align(
          alignment: Alignment.bottomCenter,
          // Drag to resize between the detents and down to dismiss. Screen
          // readers get no scroll action from the drag, which would close
          // the sheet: the close button, the scrim and Escape do that, and
          // the grabber's adjust actions move between the detents.
          child: GestureDetector(
            excludeFromSemantics: true,
            onVerticalDragUpdate: drags ? _onDragUpdate : null,
            onVerticalDragEnd: drags ? _onDragEnd : null,
            child: Transform.translate(offset: Offset(0, _drag), child: panel),
          ),
        ),
      ),
    );
  }
}

/// Keeps a bottom sheet's content clear of the system's bottom inset (the
/// home indicator), unless a [DsPanel] inside takes the inset itself
/// ([_TakesInset]): it then floats above the inset or pads it inside.
class _BottomInset extends SingleChildRenderObjectWidget {
  const _BottomInset({required this.inset, required super.child});

  final double inset;

  @override
  _RenderBottomInset createRenderObject(BuildContext context) =>
      _RenderBottomInset(inset);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBottomInset renderObject,
  ) => renderObject.inset = inset;
}

class _RenderBottomInset extends RenderShiftedBox {
  _RenderBottomInset(this._inset) : super(null);

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  /// The panels below that take the inset themselves.
  int _takers = 0;
  bool _laying = false;

  void _take(int by) {
    _takers += by;
    // A panel built during this box's own layout (under a LayoutBuilder)
    // is counted when the layout checks again.
    if (!_laying && attached) markNeedsLayout();
  }

  double get _pad => _takers > 0 ? 0 : _inset;

  BoxConstraints _inner(BoxConstraints constraints, double pad) =>
      constraints.deflate(EdgeInsets.only(bottom: pad));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    var pad = _pad;
    _laying = true;
    try {
      child.layout(_inner(constraints, pad), parentUsesSize: true);
      // A panel that came or went while the child laid out.
      if (_pad != pad) {
        pad = _pad;
        child.layout(_inner(constraints, pad), parentUsesSize: true);
      }
    } finally {
      _laying = false;
    }
    (child.parentData! as BoxParentData).offset = Offset.zero;
    size = constraints.constrain(
      Size(child.size.width, child.size.height + pad),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_inner(constraints, _pad));
    return constraints.constrain(Size(size.width, size.height + _pad));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) + _pad;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) + _pad;
}

/// Marks a [DsPanel] that keeps clear of the bottom inset itself, so that
/// the sheet's [_BottomInset] above leaves the inset to it.
class _TakesInset extends SingleChildRenderObjectWidget {
  const _TakesInset({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTakesInset();
}

class _RenderTakesInset extends RenderProxyBox {
  _RenderBottomInset? _frame;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var node = parent;
    while (node != null && node is! _RenderBottomInset) {
      node = node.parent;
    }
    _frame = node as _RenderBottomInset?;
    _frame?._take(1);
  }

  @override
  void detach() {
    _frame?._take(-1);
    _frame = null;
    super.detach();
  }
}

/// Shows a panel built by [builder] (usually a [DsPanel]): from the end
/// edge on wide screens and from the bottom on narrow ones (below
/// [kDsPanelBreakpoint]), unless [presentation] says otherwise. Escape, the
/// close button, a tap on the scrim, system back (the Android back button
/// or gesture) and dragging a bottom sheet down close it when
/// [dismissible]; otherwise none of them does and the close button is
/// hidden, so the panel's own actions must close it.
///
/// The [DsPanel] draws the panel's surface and takes its size from its
/// style; other content is placed as it is and draws its own.
///
/// A bottom sheet keeps clear of the system's bottom inset (the home
/// indicator). A [DsPanel] with a bottom margin, as by default, floats
/// above it; one whose [DsPanelStyle.margin] has no bottom reaches the
/// screen's bottom edge and pads the inset inside its surface, below its
/// content and footer. Give it top corners only for a sheet attached to
/// the bottom edge:
///
/// ```dart
/// DsPanel(
///   title: const Text('Reading settings'),
///   style: const DsPanelStyle(
///     margin: EdgeInsets.zero,
///     borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
///   ),
///   child: const ReadingSettings(),
/// )
/// ```
///
/// The on-screen keyboard is kept clear in both cases: the sheet sits on
/// it.
///
/// With [DsPanelPresentation.auto] the choice follows the window while the
/// panel is open: resizing the window or turning a tablet across the
/// breakpoint turns a side panel into a bottom sheet and back.
///
/// [scrim] set to [DsScrim.clear] leaves the page at full contrast, for a
/// live preview: a short bottom sheet of settings whose effect shows on
/// the page above it. A tap on the page still closes the panel.
///
/// [detents] are heights a bottom sheet rests at, as shares of the
/// window's height from its bottom edge: `[.5, 1]` opens it at half the
/// window and pulls up to full (a sheet is at most 90% of the window). Held at a detent, the
/// sheet keeps that height whatever its content, which scrolls inside,
/// and a [DsPanel]'s footer stays at its bottom. Dragging the sheet (by
/// its grabber, title or anything that does not scroll) moves it to the
/// nearest detent, a flick to the next one; below the lowest it closes
/// when [dismissible]. It settles without bounce, and under reduced motion
/// without moving on its own. Screen readers adjust the grabber to move
/// between detents. [initialDetent], one of [detents], is where it opens;
/// the lowest by default. Without [detents] a sheet takes its content's
/// height; a side panel ignores them.
///
/// [routeSettings] names the panel's route for navigator observers and
/// analytics, and can carry arguments.
Future<T?> showDsPanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  DsPanelPresentation presentation = DsPanelPresentation.auto,
  bool dismissible = true,
  List<double>? detents,
  double? initialDetent,
  DsScrim scrim = DsScrim.dim,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  assert(
    detents == null ||
        (detents.isNotEmpty && detents.every((d) => d > 0 && d <= 1)),
    'detents are shares of the window\'s height, above 0 and at most 1.',
  );
  assert(
    initialDetent == null || (detents?.contains(initialDetent) ?? false),
    'initialDetent is one of the detents.',
  );
  final sorted = detents == null ? null : ({...detents}.toList()..sort());
  // Decided from the modal's own context each time it builds, so that it
  // follows the window's current size.
  bool bottomIn(BuildContext context) => switch (presentation) {
    DsPanelPresentation.bottom => true,
    DsPanelPresentation.side => false,
    DsPanelPresentation.auto =>
      MediaQuery.sizeOf(context).width < kDsPanelBreakpoint,
  };
  return pushDsModal<T>(
    context: context,
    placementOf: (context) =>
        bottomIn(context) ? DsModalPlacement.bottom : DsModalPlacement.end,
    dismissible: dismissible,
    scrim: scrim,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (context) => _PanelFrame(
      bottom: bottomIn(context),
      dismissible: dismissible,
      detents: sorted,
      initialDetent: sorted == null || initialDetent == null
          ? 0
          : math.max(0, sorted.indexOf(initialDetent)),
      child: Builder(builder: builder),
    ),
  );
}
