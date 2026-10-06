import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/press_effect.dart';
import '../../behavior/pressable.dart';
import '../../behavior/spring_value.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/numeric_span.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../number_field/number_format.dart';
import '../text_field/typed_field.dart' show dsConventionsLocale;
import 'stepper_style.dart';

/// A number stepper: − value +.
///
/// The value slot is as wide as the wider of [min] and [max] as shown (at
/// least [DsStepperStyle.valueWidth]), so the control never jumps and long
/// values are not cut; the button at a limit turns inactive. Where the
/// stepper has less room than that (a narrow parent, large text), the
/// number scales down to fit. Keyboard
/// (WAI-ARIA spinbutton): the stepper is one Tab stop; Up and Down step,
/// Left and Right step too and mirror in RTL like the buttons, Home and End
/// jump to [min] and [max]. Screen readers announce the value as shown and
/// can increase or decrease it.
///
/// **Whole or decimal.** [T] is the value's type, inferred from [value]:
/// an `int` stepper reports ints, a `double` stepper doubles. A decimal
/// stepper shows as many fraction digits as [step] and [min] need (`0.5`
/// shows `2.5`; `0.25` shows `2.25`), with the locale's decimal separator
/// (`2,5` in Turkish), unless [format] says otherwise. Steps add [step]
/// and keep to [min]–[max]; float dust is rounded away (`0.1 + 0.2`
/// reports `0.3`).
///
/// **Unit.** [unit] follows the number and [prefix] leads it, smaller and
/// quieter, as in `DsNumberField`; both mirror in RTL and are read with the
/// value ("2.5 kg"). Give the order a language writes in: a Turkish
/// percentage is `prefix: '%'`, an English one `unit: '%'`.
///
/// ```dart
/// DsStepper(
///   value: guests,
///   min: 0,
///   max: 12,
///   semanticLabel: 'Guests',
///   onChanged: (v) => setState(() => guests = v),
/// )
///
/// DsStepper(
///   value: weight, // a double
///   min: 0,
///   max: 5,
///   step: 0.5,
///   unit: 'kg',
///   semanticLabel: 'Weight',
///   onChanged: (v) => setState(() => weight = v),
/// )
/// ```
class DsStepper<T extends num> extends StatefulWidget {
  /// Creates a stepper.
  const DsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.format,
    this.unit,
    this.prefix,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min <= max),
       assert(step > 0);

  /// The current value, between [min] and [max].
  final T value;

  /// Called with the new value. Null disables the stepper.
  final ValueChanged<T>? onChanged;

  /// Smallest value; whole for an `int` stepper. `double.negativeInfinity`
  /// sets none: Home then does nothing.
  final num min;

  /// Largest value; whole for an `int` stepper. `double.infinity` sets
  /// none: End then does nothing, and the value slot grows with the value.
  final num max;

  /// Amount added or removed per step; whole for an `int` stepper, where a
  /// fractional step is rounded to a whole one of at least 1.
  final num step;

  /// How the value is shown and announced: fraction digits, grouping and
  /// separators (separators left null come from the locale). Null shows
  /// the digits [step] and [min] need, without grouping.
  final DsNumberFormat? format;

  /// Text after the number, e.g. "kg"; read with the value ("2.5 kg").
  final String? unit;

  /// Text before the number, e.g. "₺" or a Turkish "%"; read with the
  /// value ("%50").
  final String? prefix;

  /// What the number counts, for screen readers ("Guests").
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsStepperStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Desen's default stepper style under [theme].
  static DsStepperStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    // The buttons are [height] tall; the track around them is a control
    // [inset] taller on each side, its buttons concentric with it. No
    // radii here: both follow whatever height and inset the layers settle
    // on.
    return DsStepperStyle(
      height: theme.sizes.sm,
      inset: 3,
      trackColor: k.channel,
      trackShadows: theme.shadows.channel,
      buttonWidth: 32,
      buttonColor: k.channelThumb,
      buttonShadows: theme.shadows.channelThumb,
      foreground: k.text,
      iconSize: 14,
      valueWidth: 38,
      valueStyle: theme.typography.numeric(
        theme.typography.heading.copyWith(letterSpacing: 0),
      ),
      // As the number field's unit: small, quieter than the number.
      unitStyle: theme.typography.small.copyWith(color: k.textMuted),
      unitGap: DsSpace.s4,
      pressScale: .92,
      focusShadows: theme.focusShadows,
      disabled: DsStepperStyle(
        buttonColor: clear,
        buttonShadows: const [],
        foreground: k.onDisabled,
        unitStyle: TextStyle(color: k.onDisabled),
      ),
    );
  }

  @override
  State<DsStepper<T>> createState() => _DsStepperState<T>();
}

class _DsStepperState<T extends num> extends State<DsStepper<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  // The buttons are pointer targets only; the stepper itself takes focus.
  final _decNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  final _incNode = FocusNode(canRequestFocus: false, skipTraversal: true);

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
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownNode?.dispose();
    _decNode.dispose();
    _incNode.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;
  // Against the limits as reported, which a step can actually reach; an
  // unbounded side always takes another step.
  bool get _canDec =>
      _enabled && (!widget.min.isFinite || widget.value > _settle(widget.min));
  bool get _canInc =>
      _enabled && (!widget.max.isFinite || widget.value < _settle(widget.max));

  /// [DsStepper.step], whole and at least 1 for an `int` stepper, where a
  /// fractional step would round back to where it started.
  num get _step => T == int ? math.max(1, widget.step.round()) : widget.step;

  /// The format in use, with the locale's separators; set in [build].
  late DsNumberFormat _format;

  /// Fraction digits a value is rounded to: the format's, or more when the
  /// step or the lower limit needs them, so a step is never lost.
  int get _digits => math.min(
    math.max(_format.decimals, _impliedDigits),
    DsNumberFormat.maxDecimals,
  );

  /// The fraction digits [DsStepper.step] and [DsStepper.min] are written
  /// with (0.25 → 2), up to six; none for an unbounded [DsStepper.min].
  int get _impliedDigits =>
      math.max(_fractionDigits(widget.step), _fractionDigits(widget.min));

  static int _fractionDigits(num v) {
    if (!v.isFinite) return 0;
    var scaled = v.abs().toDouble();
    for (var d = 0; d < 6; d++) {
      // A millionth of the last digit is float dust, not a digit.
      if ((scaled - scaled.roundToDouble()).abs() < 1e-6) return d;
      scaled *= 10;
    }
    return 6;
  }

  /// [v] as reported, as [T]: rounded to [_digits] and kept in
  /// [DsStepper.min]–[DsStepper.max] at a number that is shown (a limit
  /// with more digits rounds inward). An int for an int stepper, or for a
  /// num one without fraction digits; a double otherwise, never negative
  /// zero. [v] is finite; an unbounded limit holds nothing back.
  T _settle(num v) {
    final digits = _digits;
    final min = widget.min, max = widget.max;
    if (T == int || (T == num && digits == 0)) {
      var r = v.round();
      if (max.isFinite && r > max) r = max.floor();
      if (min.isFinite && r < min) r = min.ceil();
      return r as T;
    }
    final scale = math.pow(10, digits);
    double fix(num x) => double.parse(x.toStringAsFixed(digits));
    // A billionth of a digit is float dust (0.3 * 10 = 2.9999999999999996).
    const dust = 1e-9;
    var r = fix(v);
    if (r > widget.max) {
      r = fix((widget.max * scale + dust).floorToDouble() / scale);
    }
    if (r < widget.min) {
      r = fix((widget.min * scale - dust).ceilToDouble() / scale);
    }
    return (r == 0 ? 0.0 : r) as T;
  }

  void _set(num v) {
    final next = _settle(v);
    if (_enabled && next != widget.value) widget.onChanged!(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == LogicalKeyboardKey.arrowUp || key == forward) {
      _set(widget.value + _step);
    } else if (key == LogicalKeyboardKey.arrowDown || key == back) {
      _set(widget.value - _step);
    } else if (key == LogicalKeyboardKey.home && widget.min.isFinite) {
      _set(widget.min);
    } else if (key == LogicalKeyboardKey.end && widget.max.isFinite) {
      _set(widget.max);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final strings = DsLocalizations.of(context);
    _format = (widget.format ?? DsNumberFormat(decimals: _impliedDigits))
        .forLocale(dsConventionsLocale(context, strings));
    final layers = [
      DsStepper.defaultStyle(t),
      DsStepperTheme.of(context).style,
      widget.style,
    ];
    final s = DsStepperStyle.resolveLayers(layers, {
      if (!_enabled) WidgetState.disabled,
      if (_focusVisible) WidgetState.focused,
    });
    final corners = t.radii.controlCorners(
      s.borderRadius,
      s.height! + 2 * s.inset!,
    );

    Widget button(DsIconData icon, bool active, num delta, FocusNode node) {
      final b = DsStepperStyle.resolveLayers(layers, {
        if (!active) WidgetState.disabled,
      });
      return ExcludeSemantics(
        child: DsPressable(
          focusNode: node,
          onPressed: active ? () => _set(widget.value + delta) : null,
          // A tap changes the value, so it ticks; a button is only active
          // while its step can change it. Keys stay silent.
          haptic: DsHapticEvent.selection,
          builder: (context, states, _) => DsSpringValue(
            value: states.contains(WidgetState.pressed)
                ? DsPressEffect.scaleOf(context, b.pressScale!)
                : 1,
            spring: t.motion.moveSpringOrNull,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: AnimatedContainer(
              duration: t.motion.toneDuration,
              curve: t.motion.toneCurve,
              width: b.buttonWidth!,
              height: b.height!,
              alignment: Alignment.center,
              decoration: DsBoxDecoration(
                color: b.buttonColor,
                borderRadius: t.radii.nestedCorners(
                  b.buttonRadius,
                  corners,
                  b.inset!,
                ),
                shadows: b.buttonShadows ?? const [],
              ),
              child: DsIcon(icon, size: b.iconSize!, color: b.foreground),
            ),
          ),
        ),
      );
    }

    final value = widget.value;
    // What a step will actually give: clamped to the range.
    String stepped(num delta) => _format.format(_settle(value + delta));
    final valueStyle = (s.valueStyle ?? const TextStyle()).copyWith(
      color: s.foreground,
    );
    final shown = _format.format(value);
    // As read: the prefix before the number, the unit after it ("2.5 kg"),
    // as the number field reads them.
    String spoken(String text) =>
        ['${widget.prefix ?? ''}$text', ?widget.unit].join(' ');
    // Read with the value, not again on its own.
    Widget? affix(String? text) => text == null
        ? null
        : ExcludeSemantics(child: Text(text, maxLines: 1, style: s.unitStyle));
    final number = Stack(
      alignment: Alignment.center,
      children: [
        // Hold the width of the wider limit as shown; an unbounded
        // one has no width to hold.
        for (final limit in [widget.min, widget.max])
          if (limit.isFinite)
            ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: Text.rich(
                  numericSpan(_format.format(limit), style: valueStyle),
                  maxLines: 1,
                ),
              ),
            ),
        // Tabular digits, proportional separators ("2.5").
        Text.rich(
          numericSpan(shown, style: valueStyle),
          semanticsLabel: '',
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    );
    // The unit follows the number and the prefix leads it, mirrored in
    // RTL; the number holds its own width, so the affixes never move.
    final slot = widget.unit == null && widget.prefix == null
        ? number
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: s.unitGap!,
            children: [?affix(widget.prefix), number, ?affix(widget.unit)],
          );
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: spoken(shown),
      increasedValue: _canInc ? spoken(stepped(_step)) : null,
      decreasedValue: _canDec ? spoken(stepped(-_step)) : null,
      onIncrease: _canInc ? () => _set(value + _step) : null,
      onDecrease: _canDec ? () => _set(value - _step) : null,
      enabled: _enabled,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _node,
          autofocus: widget.autofocus,
          enabled: _enabled,
          onShowFocusHighlight: (v) => setState(() => _highlight = v),
          child: AnimatedContainer(
            duration: t.motion.toneDuration,
            curve: t.motion.toneCurve,
            padding: EdgeInsets.all(s.inset!),
            decoration: DsBoxDecoration(
              color: s.trackColor,
              borderRadius: corners,
              shadows: [
                ...?s.trackShadows,
                if (_focusVisible) ...?s.focusShadows,
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(DsIcons.minus, _canDec, -_step, _decNode),
                // Announced once, as the value, not again inside the label.
                // Short of room (a narrow parent, large text), the number
                // scales down to fit, whole, rather than overflow or cut.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: s.valueWidth!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DsSpace.s4,
                        ),
                        child: slot,
                      ),
                    ),
                  ),
                ),
                button(DsIcons.plus, _canInc, _step, _incNode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
