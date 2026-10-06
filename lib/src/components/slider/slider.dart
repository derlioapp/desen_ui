import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/radii.dart';
import '../../theme/theme.dart';
import '../../l10n/localizations.dart';
import '../../theme/theme_data.dart';
import 'slider_style.dart';

/// Picks a value on a track: continuous, or in steps with [divisions].
///
/// Drag or tap the track. From the keyboard: arrows step (mirrored in RTL),
/// Page Up/Down move a tenth, Home/End jump to the ends. Screen readers get
/// a slider with increase/decrease actions.
///
/// The thumb has a form-control outline, so it stays visible on light
/// surfaces, where a plain white thumb would disappear.
///
/// It fills the available width; under an unbounded width (in a [Row])
/// it takes [DsSliderStyle.width]. [onChangeStart] and [onChangeEnd] come
/// in pairs, once per tap or drag, and [onChangeEnd] gets the value the
/// gesture produced. A NaN [value] shows as [min]; an empty range
/// (`min == max`) shows a full-left thumb and cannot be changed.
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

  /// Called once when a drag or tap starts, with the value before it.
  final ValueChanged<double>? onChangeStart;

  /// Called once when a drag or tap ends, with the value it produced.
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

  /// [v] in the range and, with divisions, on the nearest grid point,
  /// without float dust: 3 of 10 steps from 0 to 1 is 0.3, not
  /// 0.30000000000000004, and the ends are exactly [DsSlider.min] and
  /// [DsSlider.max].
  double _snap(double v) {
    v = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    final range = widget.max - widget.min;
    if (d == null || range <= 0) return v;
    final k = ((v - widget.min) / range * d).round();
    if (k <= 0) return widget.min;
    if (k >= d) return widget.max;
    final point = widget.min + range * k / d;
    // Rounded to a millionth of the step's decade: a point's own digits
    // stay, the last-bit error of the sum goes.
    final digits = 6 - (math.log(range / d) / math.ln10).floor();
    if (digits <= 0 || digits > 20) return point;
    return double.parse(point.toStringAsFixed(digits))
        .clamp(widget.min, widget.max);
  }

  /// Reports [v], snapped. A [touch] (tap or drag) on a stepped slider
  /// ticks; keys and assistive actions are silent, as on iOS.
  void _emit(double v, {bool touch = false}) {
    if (!_enabled || v.isNaN) return;
    final next = _snap(v);
    if (next != _latest) {
      _latest = next;
      // A stepped slider ticks as the thumb crosses each step, like a
      // physical detent. A continuous one stays silent: it has no steps to
      // mark, and a drag would buzz on every frame.
      if (touch && widget.divisions != null) {
        DsHapticFeedback.play(context, DsHapticEvent.selection);
      }
      widget.onChanged!(next);
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

  double _valueAt(double dx, double width, double thumb) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final travel = width - thumb;
    var f = travel > 0 ? ((dx - thumb / 2) / travel).clamp(0.0, 1.0) : 0.0;
    if (rtl) f = 1 - f;
    return widget.min + f * (widget.max - widget.min);
  }

  double get _step {
    final d = widget.divisions;
    final range = widget.max - widget.min;
    return d != null ? range / d : range / 100;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final range = widget.max - widget.min;
    double? next;
    if (key == LogicalKeyboardKey.arrowUp ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight)) {
      next = _value + _step;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft)) {
      next = _value - _step;
    } else if (key == LogicalKeyboardKey.pageUp) {
      next = _value + range / 10;
    } else if (key == LogicalKeyboardKey.pageDown) {
      next = _value - range / 10;
    } else if (key == LogicalKeyboardKey.home) {
      next = widget.min;
    } else if (key == LogicalKeyboardKey.end) {
      next = widget.max;
    }
    if (next == null) return KeyEventResult.ignored;
    _emit(next);
    return KeyEventResult.handled;
  }

  String _format(double v) =>
      widget.semanticFormatter?.call(v) ??
      DsLocalizations.of(context)
          .percent(_range > 0 ? ((v - widget.min) / _range * 100).round() : 0);

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
    final height = s.height!, trackH = s.trackHeight!;
    final thumb = s.thumbSize!;
    final tick = s.tickSize!;
    final v = _t;
    final border = s.thumbBorderColor ?? const Color(0x00000000);

    // Fill the width; take the style's width when there is no bound.
    double widthOf(BoxConstraints c) =>
        c.hasBoundedWidth ? c.maxWidth : math.max(s.width!, thumb);

    Widget paint(BoxConstraints c) {
      final width = widthOf(c);
      final travel = math.max(0.0, width - thumb);
      final thumbStart = v * travel;
      final ticks = widget.divisions;
      return SizedBox(
        width: width,
        // The touch band grows to the minimum tap target; the track and
        // thumb stay centered in it. Not DsMinTapTarget: a tap above the
        // track must keep its horizontal position.
        height: math.max(height, t.sizes.minTapTarget),
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Container(
              height: trackH,
              decoration: DsBoxDecoration(
                color: s.trackColor,
                borderRadius: BorderRadius.circular(DsRadii.pill),
                shadows: s.trackShadows ?? const <DsShadow>[],
              ),
            ),
            Container(
              width: thumbStart + thumb / 2,
              height: trackH,
              decoration: BoxDecoration(
                color: s.fillColor,
                borderRadius: BorderRadius.circular(DsRadii.pill),
              ),
            ),
            if (ticks != null)
              for (var i = 0; i <= ticks; i++)
                if ((i / ticks - v).abs() * travel > thumb / 2)
                  PositionedDirectional(
                    start: thumb / 2 + i / ticks * travel - tick / 2,
                    child: Container(
                      width: tick,
                      height: tick,
                      decoration: BoxDecoration(
                        color: i / ticks <= v ? s.tickFilledColor : s.tickColor,
                        borderRadius: BorderRadius.circular(tick / 2),
                      ),
                    ),
                  ),
            PositionedDirectional(
              start: thumbStart,
              child: Container(
                width: thumb,
                height: thumb,
                decoration: DsBoxDecoration(
                  color: s.thumbColor,
                  borderRadius: BorderRadius.circular(thumb / 2),
                  shadows: [
                    if (border.a > 0) DsShadow.innerRing(border),
                    ...?s.thumbShadows,
                    if (_focusVisible) ...?s.focusShadows,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      enabled: _enabled,
      value: _format(_value),
      increasedValue: _enabled ? _format(_snap(_value + _step)) : null,
      decreasedValue: _enabled ? _format(_snap(_value - _step)) : null,
      onIncrease: _enabled ? () => _emit(_value + _step) : null,
      onDecrease: _enabled ? () => _emit(_value - _step) : null,
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
