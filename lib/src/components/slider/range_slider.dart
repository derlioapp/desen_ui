import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../l10n/localizations.dart';
import '../../theme/haptics.dart';
import '../../theme/theme.dart';
import 'slider.dart';
import 'slider_style.dart';
import 'slider_track.dart';

/// The two values of a [DsRangeSlider]: where the range starts and ends.
@immutable
class DsRangeValues {
  /// Creates a range; [start] is at most [end].
  const DsRangeValues({required this.start, required this.end})
    : assert(!(start > end), 'start must not be greater than end');

  /// The lower value.
  final double start;

  /// The upper value.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is DsRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'DsRangeValues')}($start, $end)';
}

/// Picks a range on a track with two thumbs, such as a price filter.
///
/// ```dart
/// DsRangeSlider(
///   values: price,
///   min: 0,
///   max: 500,
///   divisions: 50,
///   semanticLabel: 'Price',
///   semanticFormatter: (v) => '\$${v.round()}',
///   onChanged: (v) => setState(() => price = v),
/// )
/// ```
///
/// It is a [DsSlider] with a second thumb: the same track, thumbs, step
/// marks and states, styled by the same [DsSliderStyle] and
/// [DsSliderTheme]. The fill lies between the thumbs.
///
/// **Pointer.** Drag a thumb, or press the track to move the nearer thumb
/// there. The thumbs never cross: one stops at the other, or
/// [minDistance] short of it. When both sit on the same spot, the drag's
/// direction picks the thumb: toward [max] moves the end thumb, toward
/// [min] the start thumb. A mouse hovering the track rings the thumb a
/// press would move.
///
/// **Keyboard.** Each thumb is its own focus stop, the start thumb first.
/// Arrows step (mirrored in RTL), Page Up/Down move a tenth of the range
/// (at least one step), and Home/End go as far as the thumb can: to [min]
/// or [max], or to the other thumb.
///
/// **Screen readers.** Each thumb is its own slider, named by
/// [semanticLabel] and its end ("Minimum", "Maximum", in the app's
/// language), with its value read through [semanticFormatter] and
/// increase and decrease actions that stop at the other thumb.
///
/// [onChangeStart] and [onChangeEnd] come in pairs, once per tap or drag,
/// and [onChangeEnd] gets the values the gesture produced. A key press or
/// a screen reader's increase or decrease that changes a value is a change
/// of its own, with its own pair; each repeat of a held key is one too.
/// Values outside `min..max` show at the nearest end, a NaN start as [min]
/// and a NaN end as [max]; an empty range (`min == max`) cannot be changed.
class DsRangeSlider extends StatefulWidget {
  /// Creates a range slider.
  const DsRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.minDistance = 0,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatter,
    this.style,
    this.startFocusNode,
    this.endFocusNode,
    this.autofocus = false,
  }) : assert(min <= max),
       assert(divisions == null || divisions > 0),
       assert(minDistance >= 0);

  /// The current range, between [min] and [max].
  final DsRangeValues values;

  /// Called while either value changes. Null disables the slider.
  final ValueChanged<DsRangeValues>? onChanged;

  /// Called once when a drag, tap or key step starts, with the values
  /// before it.
  final ValueChanged<DsRangeValues>? onChangeStart;

  /// Called once when a drag, tap or key step ends, with the values it
  /// produced.
  final ValueChanged<DsRangeValues>? onChangeEnd;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Number of equal steps; null for continuous. Values land on the grid
  /// points as written, as with [DsSlider.divisions].
  final int? divisions;

  /// The smallest gap the thumbs keep between them, in values; 0 lets
  /// them meet. With [divisions], a thumb stops at the last step that
  /// keeps the gap.
  final double minDistance;

  /// Name for screen readers, read before each thumb's own name: "Price,
  /// Minimum".
  final String? semanticLabel;

  /// Turns a value into what screen readers say; defaults to a percentage.
  final String Function(double value)? semanticFormatter;

  /// Style laid over the theme and defaults; each thumb resolves it for
  /// its own states.
  final DsSliderStyle? style;

  /// Focus node of the start thumb; one is created when null.
  final FocusNode? startFocusNode;

  /// Focus node of the end thumb; one is created when null.
  final FocusNode? endFocusNode;

  /// Whether the start thumb takes focus when first built.
  final bool autofocus;

  @override
  State<DsRangeSlider> createState() => _DsRangeSliderState();
}

class _DsRangeSliderState extends State<DsRangeSlider> {
  FocusNode? _ownStart, _ownEnd;
  FocusNode _node(int i) => i == 0
      ? widget.startFocusNode ?? (_ownStart ??= FocusNode())
      : widget.endFocusNode ?? (_ownEnd ??= FocusNode());

  /// The thumb the current gesture moves: 0 start, 1 end. Null when none
  /// is chosen yet: no gesture, or a press on both thumbs at once, which
  /// waits for the drag's direction.
  int? _thumb;

  /// The current gesture has chosen its thumb, or decided to wait.
  bool _grabbed = false;

  bool _dragging = false;

  /// A tap or drag is under way: onChangeStart was sent, onChangeEnd not.
  bool _active = false;

  /// The thumb moved last, painted on top of the other.
  int _top = 1;

  /// Where a mouse hovers, across the track; null when none does.
  double? _hoverX;

  /// The latest values this slider produced or was given. A quick click
  /// ends before the parent rebuilds, so [DsRangeSlider.values] can be
  /// stale.
  late DsRangeValues _latest = _values;

  /// Flutter's focus highlight per thumb, before the keyboard check.
  final _highlight = [false, false];
  bool _focusVisible(int i) =>
      _highlight[i] && DsFocusVisibility.keyboard.value;
  // Input modality only changes how focus looks: rebuild only while a
  // thumb is focused, not on every pointer or key event in the app.
  void _onModality() {
    if (_highlight.contains(true)) setState(() {});
  }

  double get _range => widget.max - widget.min;

  bool get _enabled => widget.onChanged != null && _range > 0;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// [DsRangeSlider.values] made safe: in the range, a NaN start at the
  /// minimum and a NaN end at the maximum, and in order.
  DsRangeValues get _values {
    final lo = widget.min, hi = widget.max;
    var a = widget.values.start, b = widget.values.end;
    a = a.isNaN ? lo : a.clamp(lo, hi).toDouble();
    b = b.isNaN ? hi : b.clamp(lo, hi).toDouble();
    if (a > b) (a, b) = (b, a);
    return DsRangeValues(start: a, end: b);
  }

  double _valueOf(int i) => i == 0 ? _values.start : _values.end;

  /// [v] as a fraction of the track.
  double _t(double v) => _range > 0 ? (v - widget.min) / _range : 0;

  double get _step => dsSliderStep(widget.min, widget.max, widget.divisions);

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
  }

  @override
  void didUpdateWidget(DsRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _latest = _values;
    if (!_enabled) {
      // Disabled mid-gesture: no stale grabbing or pressed state.
      _active = false;
      _dragging = false;
      _grabbed = false;
      _thumb = null;
      _hoverX = null;
    }
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownStart?.dispose();
    _ownEnd?.dispose();
    super.dispose();
  }

  /// The grid point at or below [v] (or at or above it, [up]), for a
  /// bound that must keep [DsRangeSlider.minDistance] on a stepped slider.
  double _onGrid(double v, {required bool up}) {
    final d = widget.divisions;
    if (d == null || _range <= 0) return v;
    // A hair of slack, so a bound already on the grid stays put.
    final f = (v - widget.min) / _range * d;
    final k = up ? (f - 1e-9).ceil() : (f + 1e-9).floor();
    return dsSliderGridPoint(k, widget.min, widget.max, d);
  }

  /// How far thumb [i] can go: from an end of the track to the other
  /// thumb, [DsRangeSlider.minDistance] short of it. Values the parent
  /// gave closer than that stay where they are but cannot close in.
  (double, double) _bounds(int i) {
    final v = _values;
    final gap = widget.minDistance;
    if (i == 0) {
      final high = _onGrid(v.end - gap, up: false);
      return (widget.min, math.max(high, v.start));
    }
    final low = _onGrid(v.start + gap, up: true);
    return (math.min(low, v.end), widget.max);
  }

  /// [v] for thumb [i]: snapped to the steps and held between its bounds.
  double _allowed(int i, double v) {
    final (low, high) = _bounds(i);
    return dsSliderSnap(
      v,
      widget.min,
      widget.max,
      widget.divisions,
    ).clamp(low, high);
  }

  /// Moves thumb [i] to [v] and reports the new values. A [touch] (tap or
  /// drag) on a stepped slider ticks; keys and assistive actions are
  /// silent, as on iOS. A [step] (a key or an assistive action) is a
  /// change of its own: it starts and ends around it, unless a gesture is
  /// under way and ends it.
  void _move(int i, double v, {bool touch = false, bool step = false}) {
    if (!_enabled || v.isNaN) return;
    final n = _allowed(i, v);
    final now = _values;
    final next = i == 0
        ? DsRangeValues(start: n, end: now.end)
        : DsRangeValues(start: now.start, end: n);
    if (next == _latest) return;
    final own = step && !_active;
    if (own) widget.onChangeStart?.call(_latest);
    _latest = next;
    if (_top != i) setState(() => _top = i);
    // A detent per step, as on DsSlider.
    if (touch && widget.divisions != null) {
      DsHapticFeedback.play(context, DsHapticEvent.selection);
    }
    widget.onChanged!(next);
    if (own) widget.onChangeEnd?.call(next);
  }

  /// The thumb a press at [x] (across a track [width] wide) would move:
  /// the nearer one. Null when the thumbs sit on the same spot and the
  /// press lands on them: the drag's direction decides.
  int? _pick(double x, double width, double thumb) {
    final travel = math.max(0.0, width - thumb);
    final fromStart = _rtl ? width - x : x;
    final v = _values;
    final a = thumb / 2 + _t(v.start) * travel;
    final b = thumb / 2 + _t(v.end) * travel;
    if (a == b) {
      if ((fromStart - a).abs() <= thumb / 2) return null;
      return fromStart < a ? 0 : 1;
    }
    return (fromStart - a).abs() <= (fromStart - b).abs() ? 0 : 1;
  }

  /// Focus follows the thumb a gesture takes, when it is already in this
  /// slider: arrows then move the thumb that was dragged.
  void _focusFollow(int i) {
    if (_node(0).hasFocus || _node(1).hasFocus) _node(i).requestFocus();
  }

  /// Starts a gesture, once, however many recognizers report it.
  void _begin() {
    if (_active) return;
    _active = true;
    widget.onChangeStart?.call(_latest);
  }

  /// Chooses the gesture's thumb, once, and moves it under the pointer.
  void _grab(double x, double width, double thumb) {
    if (_grabbed) return;
    _grabbed = true;
    final i = _pick(x, width, thumb);
    if (i == null) return;
    setState(() => _thumb = i);
    _focusFollow(i);
    _move(i, _valueAt(x, width, thumb), touch: true);
  }

  void _drag(DragUpdateDetails d, double width, double thumb) {
    if (_thumb == null) {
      // Both thumbs were under the press: the first movement picks one.
      final dx = d.delta.dx;
      if (dx == 0) return;
      final i = (dx > 0) != _rtl ? 1 : 0;
      setState(() => _thumb = i);
      _focusFollow(i);
    }
    _move(_thumb!, _valueAt(d.localPosition.dx, width, thumb), touch: true);
  }

  /// Ends a gesture, once, with the values it produced.
  void _end() {
    if (_dragging || _thumb != null) {
      setState(() {
        _dragging = false;
        _thumb = null;
      });
    }
    _grabbed = false;
    if (!_active) return;
    _active = false;
    widget.onChangeEnd?.call(_latest);
  }

  double _valueAt(double x, double width, double thumb) => dsSliderValueAt(
    x,
    width,
    thumb,
    min: widget.min,
    max: widget.max,
    rtl: _rtl,
  );

  KeyEventResult _onKey(int i, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final (low, high) = _bounds(i);
    final next = dsSliderKeyTarget(
      event.logicalKey,
      value: _valueOf(i),
      step: _step,
      min: widget.min,
      max: widget.max,
      low: low,
      high: high,
      rtl: _rtl,
    );
    if (next == null) return KeyEventResult.ignored;
    _move(i, next, step: true);
    return KeyEventResult.handled;
  }

  String _format(double v) => dsSliderFormat(
    context,
    v,
    min: widget.min,
    max: widget.max,
    formatter: widget.semanticFormatter,
  );

  /// Thumb [i] as its own focus stop and its own slider for screen
  /// readers.
  Widget _wrapThumb(int i, Widget thumb) {
    final l10n = DsLocalizations.of(context);
    final value = _valueOf(i);
    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel,
      enabled: _enabled,
      value: _format(value),
      increasedValue: _enabled ? _format(_allowed(i, value + _step)) : null,
      decreasedValue: _enabled ? _format(_allowed(i, value - _step)) : null,
      onIncrease: _enabled
          ? () => _move(i, _valueOf(i) + _step, step: true)
          : null,
      onDecrease: _enabled
          ? () => _move(i, _valueOf(i) - _step, step: true)
          : null,
      // Merged into the node above, after the slider's own name.
      child: Semantics(
        label: i == 0 ? l10n.rangeMinimum : l10n.rangeMaximum,
        child: FocusTraversalOrder(
          // The start thumb first, also when both sit on the same spot.
          order: NumericFocusOrder(i.toDouble()),
          child: Focus(
            // Key events travel up from the focused node, so the handler
            // sits above the detector that owns focus.
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) => _onKey(i, event),
            child: FocusableActionDetector(
              focusNode: _node(i),
              autofocus: widget.autofocus && i == 0,
              enabled: _enabled,
              onShowFocusHighlight: (f) => setState(() => _highlight[i] = f),
              child: thumb,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsSlider.defaultStyle(t),
      DsSliderTheme.of(context).style,
      widget.style,
    ];
    final base = DsSliderStyle.resolveLayers(layers, {
      if (!_enabled) WidgetState.disabled,
    });
    final thumb = base.thumbSize!;

    // Fill the width; take the style's width when there is no bound.
    double widthOf(BoxConstraints c) =>
        c.hasBoundedWidth ? c.maxWidth : math.max(base.width!, thumb);

    // The thumbs a press under the mouse would move, both while it waits
    // for a direction.
    Set<int> hoveredAt(double? x, double width) {
      if (x == null || !_enabled) return const {};
      final i = _pick(x, width, thumb);
      return i == null ? const {0, 1} : {i};
    }

    Widget paint(BoxConstraints c) {
      final width = widthOf(c);
      final hovered = hoveredAt(_hoverX, width);
      Set<WidgetState> statesOf(int i) => {
        if (!_enabled) WidgetState.disabled,
        if (hovered.contains(i)) WidgetState.hovered,
        if (_dragging && _thumb == i) WidgetState.pressed,
        if (_focusVisible(i)) WidgetState.focused,
      };
      // The track as a whole takes every state either thumb is in.
      final track = DsSliderStyle.resolveLayers(layers, {
        ...statesOf(0),
        ...statesOf(1),
      });
      final v = _values;
      return DsSliderTrack(
        style: track,
        width: width,
        bandHeight: t.sizes.minTapTarget,
        fillFrom: _t(v.start),
        fillTo: _t(v.end),
        divisions: widget.divisions,
        thumbs: [
          for (final i in _top == 0 ? const [1, 0] : const [0, 1])
            DsSliderThumb(
              key: ValueKey(i),
              t: _t(_valueOf(i)),
              style: DsSliderStyle.resolveLayers(layers, statesOf(i)),
              focusRing: _focusVisible(i),
              wrap: (w) => _wrapThumb(i, w),
            ),
        ],
      );
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: LayoutBuilder(
        builder: (context, c) => MouseRegion(
          cursor: !_enabled
              ? SystemMouseCursors.forbidden
              : base.cursor ??
                    (_dragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab),
          onHover: (e) {
            final width = widthOf(c);
            final x = e.localPosition.dx;
            final changed = !setEquals(
              hoveredAt(_hoverX, width),
              hoveredAt(x, width),
            );
            _hoverX = x;
            if (changed) setState(() {});
          },
          onExit: (_) {
            if (_hoverX != null) setState(() => _hoverX = null);
          },
          // The pointer lifting ends any gesture, also one whose tap lost
          // the arena to a scroll; tap and drag ends report it too, and
          // only the first one counts.
          child: Listener(
            onPointerUp: (_) => _end(),
            onPointerCancel: (_) => _end(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              dragStartBehavior: DragStartBehavior.down,
              onTapDown: !_enabled
                  ? null
                  : (d) {
                      _begin();
                      _grab(d.localPosition.dx, widthOf(c), thumb);
                    },
              onTapUp: !_enabled ? null : (_) => _end(),
              onHorizontalDragStart: !_enabled
                  ? null
                  : (d) {
                      setState(() => _dragging = true);
                      _begin();
                      _grab(d.localPosition.dx, widthOf(c), thumb);
                    },
              onHorizontalDragUpdate: !_enabled
                  ? null
                  : (d) => _drag(d, widthOf(c), thumb),
              onHorizontalDragEnd: !_enabled ? null : (_) => _end(),
              onHorizontalDragCancel: !_enabled ? null : _end,
              child: paint(c),
            ),
          ),
        ),
      ),
    );
  }
}
