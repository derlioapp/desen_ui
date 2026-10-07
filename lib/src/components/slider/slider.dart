import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../theme/haptics.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'slider_style.dart';
import 'slider_track.dart';

/// Picks a value on a track: continuous, or in steps with [divisions].
///
/// Drag or tap the track. From the keyboard: arrows step (mirrored in RTL),
/// Page Up/Down move a tenth (at least one step), Home/End jump to the
/// ends. Screen readers get a slider with increase/decrease actions.
///
/// The thumb has a form-control outline, so it stays visible on light
/// surfaces, where a plain white thumb would disappear.
///
/// It fills the available width; under an unbounded width (in a [Row])
/// it takes [DsSliderStyle.width]. [onChangeStart] and [onChangeEnd] come
/// in pairs, once per tap or drag, and [onChangeEnd] gets the value the
/// gesture produced. A key press or a screen reader's increase or
/// decrease that changes the value is a change of its own, with its own
/// pair; each repeat of a held key is one too. A NaN [value] shows as
/// [min]; an empty range (`min == max`) shows a full-left thumb and cannot
/// be changed.
class DsSlider extends StatefulWidget {
  /// Creates a slider.
  const DsSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatter,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min <= max),
       assert(divisions == null || divisions > 0);

  /// The current value, between [min] and [max].
  final double value;

  /// Called while the value changes. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called once when a drag, tap or key step starts, with the value
  /// before it.
  final ValueChanged<double>? onChangeStart;

  /// Called once when a drag, tap or key step ends, with the value it
  /// produced.
  final ValueChanged<double>? onChangeEnd;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Number of equal steps; null for continuous. Reported values are the
  /// grid points as written (0.3 of 0–1 in tenths, not
  /// 0.30000000000000004), the ends exactly [min] and [max].
  final int? divisions;

  /// Name for screen readers.
  final String? semanticLabel;

  /// Turns a value into what screen readers say; defaults to a percentage.
  final String Function(double value)? semanticFormatter;

  /// Style laid over the theme and defaults.
  final DsSliderStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Desen's default slider style under [theme].
  static DsSliderStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsSliderStyle(
      width: 160,
      height: 20,
      trackHeight: 6,
      trackColor: k.channelStrong,
      trackShadows: theme.shadows.channel,
      fillColor: k.indicator,
      thumbSize: 20,
      // The switch's knob: white with a soft shadow and a faint edge, which
      // carry it on a light surface.
      thumbColor: k.knob,
      thumbBorderColor: const Color(0x00000000),
      thumbShadows: theme.shadows.knob,
      tickColor: k.textSubtle,
      // A hole in the fill: the unfilled track color, which the budget
      // keeps 3:1 from the fill in every seed and mode (on-accent at 70%
      // was 2.1:1).
      tickFilledColor: k.channelStrong,
      tickSize: 4,
      focusShadows: theme.focusShadows,
      hovered: DsSliderStyle(thumbBorderColor: k.focus),
      disabled: DsSliderStyle(
        fillColor: k.onDisabled,
        thumbColor: k.onDisabled,
        thumbBorderColor: const Color(0x00000000),
        thumbShadows: const [],
      ),
    );
  }

  @override
  State<DsSlider> createState() => _DsSliderState();
}

class _DsSliderState extends State<DsSlider> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  bool _hovered = false, _dragging = false;

  /// A tap or drag is under way: onChangeStart was sent, onChangeEnd not.
  bool _active = false;

  /// The latest value this slider produced or was given. A quick click
  /// ends before the parent rebuilds, so [DsSlider.value] can be stale.
  late double _latest = _value;

  double get _range => widget.max - widget.min;

  bool get _enabled => widget.onChanged != null && _range > 0;

  /// [DsSlider.value] made safe: NaN reads as [DsSlider.min], and the
  /// value is held inside the range.
  double get _value {
    final v = widget.value;
    if (v.isNaN) return widget.min;
    return v.clamp(widget.min, widget.max).toDouble();
  }

  double get _t => _range > 0 ? (_value - widget.min) / _range : 0;

  /// Flutter's focus highlight, before the keyboard check.
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app.
  void _onModality() {
    if (_highlight) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
  }

  @override
  void didUpdateWidget(DsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _latest = _value;
    if (!_enabled) {
      // Disabled mid-gesture: no stale grabbing or pressed state.
      _active = false;
      _dragging = false;
      _hovered = false;
    }
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownNode?.dispose();
    super.dispose();
  }

  double _snap(double v) =>
      dsSliderSnap(v, widget.min, widget.max, widget.divisions);

  /// Reports [v], snapped. A [touch] (tap or drag) on a stepped slider
  /// ticks; keys and assistive actions are silent, as on iOS. A [step] (a
  /// key or an assistive action) is a change of its own: it starts and
  /// ends around it, unless a gesture is under way and ends it.
  void _emit(double v, {bool touch = false, bool step = false}) {
    if (!_enabled || v.isNaN) return;
    final next = _snap(v);
    if (next != _latest) {
      final own = step && !_active;
      if (own) widget.onChangeStart?.call(_latest);
      _latest = next;
      // A stepped slider ticks as the thumb crosses each step, like a
      // physical detent. A continuous one stays silent: it has no steps to
      // mark, and a drag would buzz on every frame.
      if (touch && widget.divisions != null) {
        DsHapticFeedback.play(context, DsHapticEvent.selection);
      }
      widget.onChanged!(next);
      if (own) widget.onChangeEnd?.call(next);
    }
  }

  /// Starts a gesture, once, however many recognizers report it.
  void _begin() {
    if (_active) return;
    _active = true;
    widget.onChangeStart?.call(_latest);
  }

  /// Ends a gesture, once, with the value it produced.
  void _end() {
    if (_dragging) setState(() => _dragging = false);
    if (!_active) return;
    _active = false;
    widget.onChangeEnd?.call(_latest);
  }

  double _valueAt(double dx, double width, double thumb) => dsSliderValueAt(
    dx,
    width,
    thumb,
    min: widget.min,
    max: widget.max,
    rtl: Directionality.of(context) == TextDirection.rtl,
  );

  double get _step => dsSliderStep(widget.min, widget.max, widget.divisions);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final next = dsSliderKeyTarget(
      event.logicalKey,
      value: _value,
      step: _step,
      min: widget.min,
      max: widget.max,
      low: widget.min,
      high: widget.max,
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    if (next == null) return KeyEventResult.ignored;
    _emit(next, step: true);
    return KeyEventResult.handled;
  }

  String _format(double v) => dsSliderFormat(
    context,
    v,
    min: widget.min,
    max: widget.max,
    formatter: widget.semanticFormatter,
  );

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_hovered) WidgetState.hovered,
      if (_dragging) WidgetState.pressed,
      if (_focusVisible) WidgetState.focused,
    };
    final s = DsSliderStyle.resolveLayers([
      DsSlider.defaultStyle(t),
      DsSliderTheme.of(context).style,
      widget.style,
    ], states);
    final thumb = s.thumbSize!;

    // Fill the width; take the style's width when there is no bound.
    double widthOf(BoxConstraints c) =>
        c.hasBoundedWidth ? c.maxWidth : math.max(s.width!, thumb);

    Widget paint(BoxConstraints c) => DsSliderTrack(
      style: s,
      width: widthOf(c),
      bandHeight: t.sizes.minTapTarget,
      fillTo: _t,
      divisions: widget.divisions,
      thumbs: [DsSliderThumb(t: _t, style: s, focusRing: _focusVisible)],
    );

    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      enabled: _enabled,
      value: _format(_value),
      increasedValue: _enabled ? _format(_snap(_value + _step)) : null,
      decreasedValue: _enabled ? _format(_snap(_value - _step)) : null,
      onIncrease: _enabled ? () => _emit(_value + _step, step: true) : null,
      onDecrease: _enabled ? () => _emit(_value - _step, step: true) : null,
      child: Focus(
        // Key events travel up from the focused node, so the handler sits
        // above the detector that owns focus.
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _node,
          autofocus: widget.autofocus,
          enabled: _enabled,
          mouseCursor: !_enabled
              ? SystemMouseCursors.forbidden
              : s.cursor ??
                    (_dragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab),
          onShowHoverHighlight: (h) => setState(() => _hovered = h),
          onShowFocusHighlight: (f) => setState(() => _highlight = f),
          child: LayoutBuilder(
            // The pointer lifting ends any gesture, also one whose tap lost
            // the arena to a scroll; tap and drag ends report it too, and
            // only the first one counts.
            builder: (context, c) => Listener(
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
                        _emit(
                          _valueAt(d.localPosition.dx, widthOf(c), thumb),
                          touch: true,
                        );
                      },
                onTapUp: !_enabled ? null : (_) => _end(),
                onHorizontalDragStart: !_enabled
                    ? null
                    : (d) {
                        setState(() => _dragging = true);
                        _begin();
                      },
                onHorizontalDragUpdate: !_enabled
                    ? null
                    : (d) => _emit(
                        _valueAt(d.localPosition.dx, widthOf(c), thumb),
                        touch: true,
                      ),
                onHorizontalDragEnd: !_enabled ? null : (_) => _end(),
                onHorizontalDragCancel: !_enabled ? null : _end,
                child: paint(c),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
