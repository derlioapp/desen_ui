import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shape.dart';
import '../../theme/haptics.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../field/field.dart';
import '../text_field/field_fit.dart';
import '../text_field/text_field.dart';
import '../text_field/text_field_style.dart';
import '../text_field/text_field_variant.dart';
import '../text_field/typed_field.dart';
import 'number_field_style.dart';
import 'number_format.dart';

export 'number_field_style.dart';
export 'number_format.dart';

/// A number field: a text field with an
/// optional unit after the number in the subtle text color, and decrease
/// and increase buttons at the end.
///
/// ```dart
/// DsField(
///   label: const Text('Weight'),
///   child: DsNumberField(
///     value: weight,
///     min: 0,
///     max: 300,
///     step: 0.5,
///     format: const DsNumberFormat(decimals: 1),
///     unit: 'kg',
///     onChanged: (v) => setState(() => weight = v),
///   ),
/// )
/// ```
///
/// **Value.** [value] is null while the field is empty. Typing is free
/// within what can become a number ([DsNumberFormat.inputFormatter]): a
/// minus sign (when [min] allows negatives), digits and the locale's
/// decimal separator (`,` in Turkish and German; `.` or `,` typed are both
/// taken as it, and where `.` also groups thousands, a typed `.` is read
/// by where it stands: [DsNumberFormat.readings]). A grouped number pasted
/// into an ungrouped field ("1.234,56") drops its group separators.
/// [onChanged] follows the typing with each number that is
/// in range, and with null while the text is empty, not yet a number
/// ("-") or out of range. On Enter or when focus leaves, the number is
/// rounded to the format's fraction digits, then kept in [min]–[max] at a
/// number the format shows (`max: 2.5` without fraction digits gives 2),
/// and shown in the format (`12,5` → `12,50`). Nothing is reported without
/// an edit. Text that is not a number is kept with the error look (2px
/// danger edge and icon, invalid for screen readers) and the value is
/// null, so it can be fixed rather than retyped. So is text that reads
/// two ways ("1.234" in a German field with three fraction digits: a
/// thousand or a decimal), with a message offering both, and a number the
/// field cannot hold exactly: past ±9007199254740991 (2^53 − 1) without
/// fraction digits, a hundredth of that with two, and so on, where a
/// double would change it. While typing, a number that more digits cannot
/// bring back into range (over [max] or that limit, or under a negative
/// [min]) shows the error look at once.
///
/// **Invalid input.** [onInputIssueChanged] tells what is wrong ("Enter a
/// number.", "Enter 10 or less.") and null once it is fixed or the field is
/// empty; with `onChanged(null)` it tells an empty field from an invalid one.
/// Inside a [DsField] without an error of its own the field shows the message
/// (WCAG 3.3.1).
///
/// **Buttons.** Side by side at the end, minus then plus (mirrored in
/// RTL): each is the field's height tall and at least
/// [DsSizes.minTapTarget] wide, inside the field, so the field does not
/// grow. They are not Tab stops and do not take focus: the field is
/// the one stop, as a WAI-ARIA spinbutton. A press steps once; holding
/// repeats, faster the longer it is held. A button at a limit is inactive.
/// Steps land on the [step] grid counted from [min] (or 0): 7 steps up to
/// 10 with a step of 5; past the last point of the grid a step stops at
/// the limit.
///
/// | Key | Action |
/// |---|---|
/// | Up / Down | Next / previous step |
/// | Page Up / Page Down | Ten steps |
/// | Home / End | [min] / [max], when set (otherwise the caret moves) |
/// | Enter | Commits: clamps and formats |
///
/// **Screen readers.** One node: a text field whose value carries the unit
/// ("72 kg"), with the next and previous values and increase and decrease
/// actions (swipe up and down on iOS, volume keys on Android). It is heard
/// as an adjustable text field, not as a spin button: Flutter 3.47 does
/// not support its spin button role yet.
///
/// **Field.** Inside a [DsField] the label names it and the field's error
/// and required state apply. [onChanged] null disables it; [readOnly]
/// keeps the value selectable but fixed, in the text field's read-only
/// look and without the step buttons.
///
/// Anatomy: text field (well, prefix, digits, unit, error icon), divider,
/// decrease button, divider, increase button.
///
/// Works without `DsScope` or `DsApp`.
class DsNumberField extends StatefulWidget {
  /// Creates a number field.
  const DsNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.onInputIssueChanged,
    this.onSubmitted,
    this.min,
    this.max,
    this.step = 1,
    this.format = const DsNumberFormat(),
    this.unit,
    this.prefix,
    this.placeholder,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.semanticLabel,
    this.error = false,
    this.style,
  }) : assert(min == null || max == null || min <= max),
       assert(step > 0);

  /// The number, or null when the field is empty.
  final num? value;

  /// Called with the new number (see the class docs for when). It is an
  /// [int] when the format has no fraction digits, a [double] otherwise.
  /// Null disables the field.
  final ValueChanged<num?>? onChanged;

  /// Called with what is wrong when the text holds no number in range, and
  /// with null once it does or is empty again.
  final ValueChanged<DsInputIssue?>? onInputIssueChanged;

  /// Called on Enter, after the text is committed, with the value.
  final ValueChanged<num?>? onSubmitted;

  /// Smallest value; null for none. A negative or null [min] lets a minus
  /// sign be typed.
  final num? min;

  /// Largest value; null for none.
  final num? max;

  /// Amount a button press or an arrow key adds or removes; Page Up and
  /// Page Down move ten times as far.
  final num step;

  /// Fraction digits, grouping and separators; separators left null come
  /// from the locale.
  final DsNumberFormat format;

  /// Text after the number, e.g. "kg"; read with the value ("72 kg").
  final String? unit;

  /// Text before the number, e.g. "₺" or a Turkish "%".
  final String? prefix;

  /// Shown while the field is empty.
  final String? placeholder;

  /// Whether the number is fixed. It can still be focused, selected and
  /// copied; the step buttons go and the step keys do nothing.
  final bool readOnly;

  /// Focus node of the field; one is created when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// The on-screen keyboard's action key.
  final TextInputAction? textInputAction;

  /// Names the field for screen readers when no [DsField] label does.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsNumberFieldStyle? style;

  /// Desen's default number field style under [theme].
  static DsNumberFieldStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    return DsNumberFieldStyle(
      fieldStyle: const DsTextFieldStyle(
        width: 200,
        // Proportional figures, as in a browser's input: in the text
        // family, tabular figures make the period, comma and colon
        // digit-wide, so a typed "12.10.2026" or "12.500,00" would read
        // spaced out like a console.
      ),
      // The unit: 13px, in the field's subtle text color.
      unitStyle: theme.typography.small,
      buttonWidth: 32,
      buttonColor: clear,
      foreground: k.textMuted,
      iconSize: 14,
      dividerColor: k.border,
      dividerWidth: 1,
      hovered: DsNumberFieldStyle(buttonColor: k.hover, foreground: k.text),
      pressed: DsNumberFieldStyle(buttonColor: k.press, foreground: k.text),
      disabled: DsNumberFieldStyle(
        buttonColor: clear,
        foreground: k.onDisabled,
      ),
    );
  }

  @override
  State<DsNumberField> createState() => _DsNumberFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('value', value))
      ..add(DiagnosticsProperty('min', min, defaultValue: null))
      ..add(DiagnosticsProperty('max', max, defaultValue: null))
      ..add(DiagnosticsProperty('step', step, defaultValue: 1))
      ..add(DiagnosticsProperty('format', format))
      ..add(StringProperty('unit', unit, defaultValue: null))
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsNumberFieldState extends State<DsNumberField>
    with DsTypedFieldState<DsNumberField, num> {
  /// The format with the locale's separators; null until the first build.
  DsNumberFormat? _format;
  DsNumberFormat get _fmt => _format!;

  // The buttons are pointer targets only; the field takes focus.
  final _decNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  final _incNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  final _decStates = WidgetStatesController();
  final _incStates = WidgetStatesController();

  /// Direction of the button being held, 0 for none.
  int _holding = 0;
  Timer? _repeat;
  int _repeats = 0;

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  ValueChanged<num?>? get onChanged => widget.onChanged;

  @override
  ValueChanged<DsInputIssue?>? get onInputIssueChanged =>
      widget.onInputIssueChanged;

  @override
  bool get canCommit => _canEdit;

  @override
  void initState() {
    super.initState();
    initTypedField(widget.value);
    _decStates.addListener(() => _onButton(-1, _decStates));
    _incStates.addListener(() => _onButton(1, _incStates));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveFormat();
  }

  @override
  void didUpdateWidget(DsNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(oldWidget.focusNode);
    if (widget.format != oldWidget.format) {
      _resolveFormat(force: true);
    } else if (widget.value != oldWidget.value && widget.value != reported) {
      // Set from outside: show it.
      showValue(widget.value);
    }
    if (!_canEdit) _stopRepeat();
  }

  @override
  void dispose() {
    _stopRepeat();
    disposeTypedField();
    _decNode.dispose();
    _incNode.dispose();
    _decStates.dispose();
    _incStates.dispose();
    super.dispose();
  }

  void _resolveFormat({bool force = false}) {
    final strings = DsLocalizations.of(context);
    final next = widget.format.forLocale(dsConventionsLocale(context, strings));
    if (next == _format && !force) return;
    final first = _format == null;
    _format = next;
    // New separators or digits: the current value, shown anew (unless the
    // text is kept to be fixed).
    if (first || issue == null) showValue(widget.value);
  }

  bool get _enabled => widget.onChanged != null;
  bool get _canEdit => _enabled && !widget.readOnly;
  bool get _signed => widget.min == null || widget.min! < 0;

  /// [v] in the format; empty for no number (null, NaN, infinite).
  @override
  String show(num? v) => v == null || !v.isFinite ? '' : _fmt.format(v);

  /// [v] rounded to the format's digits: an [int] without fraction digits
  /// (a [double] past ±2^53, where an int would not hold what is shown),
  /// never negative zero.
  num _round(num v) {
    final decimals = _decimals;
    if (decimals == 0) {
      return v.abs() < _exactInts ? v.round() : v.roundToDouble();
    }
    if (v.abs() >= 1e21) return v.toDouble();
    final d = double.parse(v.toStringAsFixed(decimals));
    return d == 0 ? 0.0 : d;
  }

  /// [v] rounded toward zero or away from it to the format's digits:
  /// [up] for the smallest number shown at or over [v].
  num _roundTo(num v, {required bool up}) {
    final r = _round(v);
    if (up ? r >= v : r <= v) return r;
    final unit = math.pow(10, -_decimals);
    return _round(up ? r + unit : r - unit);
  }

  /// The format's fraction digits, as many as it shows.
  int get _decimals => math.min(_fmt.decimals, DsNumberFormat.maxDecimals);

  /// The largest magnitude typing can give: past it a double no longer
  /// holds every number the format shows (2^53 − 1 without fraction
  /// digits, a hundredth of that with two), so the number would change.
  num get _exactLimit => (_exactInts - 1) / math.pow(10, _decimals);

  /// [DsNumberField.max], or [_exactLimit] when that is lower or none is
  /// set.
  num get _typedMax {
    final max = widget.max;
    return max == null || max > _exactLimit ? _exactLimit : max;
  }

  /// [DsNumberField.min], or -[_exactLimit] when that is higher or none is
  /// set.
  num get _typedMin {
    final min = widget.min;
    return min == null || min < -_exactLimit ? -_exactLimit : min;
  }

  /// [v] as reported: rounded first, then kept in [min]–[max] at a number
  /// the format shows (`max: 2.5` without fraction digits gives 2, never
  /// 3; `max: 9.99` with one gives 9.9).
  num _settle(num v) {
    final min = widget.min, max = widget.max;
    var r = _round(v);
    if (max != null && r > max) r = _roundTo(max, up: false);
    if (min != null && r < min) r = _roundTo(min, up: true);
    return r;
  }

  bool _inRange(num v) =>
      (widget.min == null || v >= widget.min!) &&
      (widget.max == null || v <= widget.max!);

  /// Why [v] is out of range for good: over [max] (more digits only grow
  /// it), or under a negative [min]; null when more typing can still bring
  /// it in. Past [_exactLimit] counts as out of range too.
  DsInputIssue? _beyondReach(num v) {
    final l10n = DsLocalizations.of(context);
    final min = _typedMin, max = _typedMax;
    if (v > max && v >= 0) {
      return DsInputIssue(
        DsInputIssueKind.aboveMax,
        l10n.numberTooLarge(_fmt.format(_roundTo(max, up: false))),
      );
    }
    if (v < min && v < 0) {
      return DsInputIssue(
        DsInputIssueKind.belowMin,
        l10n.numberTooSmall(_fmt.format(_roundTo(min, up: true))),
      );
    }
    return null;
  }

  /// The number the text holds now, typed or committed.
  num? get _current => _fmt.tryParse(controller.text);

  /// While typing: each number in range, null otherwise; a number more
  /// digits cannot bring back into range is an issue at once. Text that
  /// reads two ways waits for more typing.
  @override
  DsTypedRead<num> readTyping(String text) {
    final v = _fmt.tryParse(text);
    if (v == null) return (value: null, issue: null);
    if (_beyondReach(v) case final issue?) return (value: null, issue: issue);
    return (value: _inRange(v) ? _settle(v) : null, issue: null);
  }

  /// On commit: rounded and kept in range. Text that is not a number,
  /// that reads two ways, or whose number would change past
  /// [_exactLimit] is an issue.
  @override
  DsTypedRead<num> readCommit(String text) {
    final l10n = DsLocalizations.of(context);
    final invalid = DsInputIssue(DsInputIssueKind.invalid, l10n.invalidNumber);
    final readings = _fmt.readings(text);
    if (readings.length == 2) {
      // "1.234" in German with three fraction digits: a thousand or a
      // decimal. Both are offered, written so they read one way.
      return (
        value: null,
        issue: DsInputIssue(
          DsInputIssueKind.invalid,
          l10n.numberAmbiguous(
            _fmt.format(readings.first),
            _fmt.format(readings.last),
          ),
        ),
      );
    }
    if (readings.isEmpty) return (value: null, issue: invalid);
    final v = readings.single;
    final settled = _settle(v);
    // Kept in range, it is exact; past the limit it would change silently.
    if (settled.abs() > _exactLimit) {
      return (value: null, issue: _beyondReach(v) ?? invalid);
    }
    return (value: settled, issue: null);
  }

  void _onSubmitted(String _) {
    commit();
    widget.onSubmitted?.call(reported);
  }

  /// Where a step in [direction] from the current number lands: the next
  /// point of the step grid (from [DsNumberField.min] or 0), or for a
  /// [page], ten steps on. From an empty field, the value nearest 0.
  num _target(int direction, {bool page = false}) {
    final current = _current;
    if (current == null) return _settle(0);
    final step = widget.step;
    final base = widget.min ?? 0;
    // Float steps (0.1) leave dust; a millionth of a step is the same point.
    const dust = 1e-6;
    final k = (current - base) / step;
    final num n;
    if (page) {
      n = (k + direction * 10).roundToDouble();
    } else if (direction > 0) {
      n = (k + dust).floorToDouble() + 1;
    } else {
      n = (k - dust).ceilToDouble() - 1;
    }
    return _settle(base + n * step);
  }

  bool get _canIncrease {
    if (!_canEdit) return false;
    final v = _current;
    return v == null || widget.max == null || v < widget.max!;
  }

  bool get _canDecrease {
    if (!_canEdit) return false;
    final v = _current;
    return v == null || widget.min == null || v > widget.min!;
  }

  void _setValue(num v) => choose(_settle(v));

  /// Steps once; false when nothing changed (at a limit).
  bool _step(int direction, {bool page = false}) {
    if (!_canEdit) return false;
    if (direction > 0 ? !_canIncrease : !_canDecrease) return false;
    final before = controller.text;
    _setValue(_target(direction, page: page));
    return controller.text != before;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_canEdit) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    // An input method still composing keeps its keys.
    final composing = controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _step(1, page: true);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _step(-1, page: true);
    } else if (key == LogicalKeyboardKey.home && widget.min != null) {
      _setValue(widget.min!);
    } else if (key == LogicalKeyboardKey.end && widget.max != null) {
      _setValue(widget.max!);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// A button pressed steps at once; held, it repeats after the long-press
  /// delay, every 100ms at first and faster each time, down to 25ms (the
  /// framework's gesture timings, not design values).
  void _onButton(int direction, WidgetStatesController states) {
    final pressed = states.value.contains(WidgetState.pressed);
    if (pressed && _holding != direction) {
      _stopRepeat();
      _holding = direction;
      if (_stepByButton(direction)) _scheduleRepeat(kLongPressTimeout);
    } else if (!pressed && _holding == direction) {
      _stopRepeat();
    }
  }

  /// A step from a button, which ticks like a stepper when the value moves
  /// under a finger or pointer. Held Space presses the button too; keys
  /// stay silent, as on iOS.
  bool _stepByButton(int direction) {
    final stepped = _step(direction);
    if (stepped && !DsFocusVisibility.keyboard.value) {
      DsHapticFeedback.play(context, DsHapticEvent.selection);
    }
    return stepped;
  }

  void _scheduleRepeat(Duration wait) {
    _repeat = Timer(wait, () {
      if (!mounted || _holding == 0) return;
      if (!_stepByButton(_holding)) return _stopRepeat();
      _repeats++;
      final faster = kPressTimeout * math.pow(0.8, _repeats).toDouble();
      final floor = kPressTimeout ~/ 4;
      _scheduleRepeat(faster < floor ? floor : faster);
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
    _holding = 0;
    _repeats = 0;
  }

  /// [text] as read: the prefix before it, the unit after it ("72 kg").
  String? _spoken(String text) {
    if (text.isEmpty) return null;
    return ['${widget.prefix ?? ''}$text', ?widget.unit].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final scope = DsFieldScope.maybeOf(context);
    tellField(scope);
    final dir = Directionality.of(context);
    final layers = [
      DsNumberField.defaultStyle(t),
      DsNumberFieldTheme.of(context).style,
      widget.style,
    ];
    final ns = DsNumberFieldStyle.resolveLayers(layers, const {});
    final enabled = _enabled;
    final text = controller.text;
    final error = widget.error || issue != null;
    final focused = enabled && node.hasFocus;
    // Read-only shows the value without the step buttons: they edit it.
    final readOnly = enabled && widget.readOnly;

    // The text field as it will resolve, for the edge the buttons sit
    // inside and its corners.
    final fieldTheme = DsTextFieldTheme.of(context);
    final tf = DsTextFieldStyle.resolveLayers(
      [
        DsTextField.defaultStyle(t),
        fieldTheme.style,
        fieldTheme.variants[DsTextFieldVariant.singleLine],
        ns.fieldStyle,
      ],
      {
        if (focused) WidgetState.focused,
        if (error || (scope?.hasError ?? false)) WidgetState.error,
        if (!enabled) WidgetState.disabled,
      },
      readOnly: readOnly,
    );
    final edge = (tf.borderColor?.a ?? 0) > 0 ? tf.borderWidth ?? 0 : 0.0;
    final tap = DsTheme.sizesOf(context).minTapTarget;
    final buttonWidth = math.max(ns.buttonWidth!, tap);
    final hairline = ns.dividerWidth!;
    final buttonsWidth = 2 * (buttonWidth + hairline);
    final corner = t.radii
        .controlCorners(tf.borderRadius, tf.height!)
        .resolve(dir);
    final endCorner = dir == TextDirection.rtl
        ? corner.topLeft
        : corner.topRight;
    final innerRadius = Radius.circular(math.max(0, endCorner.x - edge));

    final scaler = MediaQuery.textScalerOf(context);
    final padding = (tf.padding ?? EdgeInsets.zero).resolve(dir);
    final textStyle = DefaultTextStyle.of(context).style.merge(tf.textStyle);
    // The step buttons give way after the unit (FieldYield.action):
    // they stay while the text and the prefix keep their room beside
    // them. The arrow keys and the increase and decrease actions remain.
    double prefixWidth() {
      final prefix = widget.prefix;
      if (prefix == null) return 0;
      final painter = TextPainter(
        text: TextSpan(text: prefix, style: textStyle.merge(ns.unitStyle)),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width + (tf.affixGap ?? tf.gap ?? 0);
      painter.dispose();
      return width;
    }

    final core = fieldMinTextWidth(textStyle, scaler) + prefixWidth();

    Widget? slot(String? text) => text == null
        ? null
        : ExcludeSemantics(child: Text(text, maxLines: 1, style: ns.unitStyle));

    // With the step buttons, the text field keeps room for them.
    DsTextFieldStyle fieldStyle(bool steps) =>
        (ns.fieldStyle ?? const DsTextFieldStyle()).merge(
          DsTextFieldStyle(
            padding: (tf.padding ?? EdgeInsets.zero).add(
              EdgeInsetsDirectional.only(end: steps ? buttonsWidth : 0),
            ),
          ),
        );

    Widget textField(bool steps) => DsTextField(
      controller: controller,
      focusNode: node,
      autofocus: widget.autofocus,
      enabled: enabled,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.numberWithOptions(
        signed: _signed,
        decimal: _fmt.decimals > 0,
      ),
      textInputAction: widget.textInputAction,
      inputFormatters: [_fmt.inputFormatter(signed: _signed)],
      placeholder: widget.placeholder,
      leading: slot(widget.prefix),
      trailing: slot(widget.unit),
      semanticLabel: widget.semanticLabel,
      error: error,
      style: fieldStyle(steps),
      onChanged: onText,
      onSubmitted: _onSubmitted,
    );

    Widget button(DsIconData icon, int direction, bool active) {
      final states = direction > 0 ? _incStates : _decStates;
      return DsPressable(
        focusNode: direction > 0 ? _incNode : _decNode,
        statesController: states,
        // Steps on press and repeats while held (see _onButton).
        onPressed: active ? _noop : null,
        // The step itself ticks (see _stepByButton), not the release.
        haptic: null,
        minTapTarget: 0,
        mouseCursor: ns.cursor,
        builder: (context, states, _) {
          final b = DsNumberFieldStyle.resolveLayers(layers, {
            ...states,
            if (!active) WidgetState.disabled,
          });
          // The width follows the theme at once; only the fill animates.
          return SizedBox(
            width: buttonWidth,
            child: AnimatedContainer(
              duration: t.motion.toneDuration,
              curve: t.motion.toneCurve,
              alignment: Alignment.center,
              decoration: DsBoxDecoration(color: b.buttonColor),
              child: DsIcon(
                icon,
                size: scaler.scale(b.iconSize!),
                color: b.foreground,
              ),
            ),
          );
        },
      );
    }

    final divider = SizedBox(
      width: hairline,
      child: ColoredBox(color: ns.dividerColor ?? const Color(0x00000000)),
    );
    final buttons = ExcludeSemantics(
      child: DsShapeClip(
        borderRadius: BorderRadiusDirectional.horizontal(end: innerRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            divider,
            button(DsIcons.minus, -1, _canDecrease),
            divider,
            button(DsIcons.plus, 1, _canIncrease),
          ],
        ),
      ),
    );

    Widget field = LayoutBuilder(
      builder: (context, constraints) {
        final steps =
            !readOnly &&
            (!constraints.hasBoundedWidth ||
                constraints.maxWidth - padding.horizontal - buttonsWidth >=
                    core);
        // One tree either way, so the text field keeps its state.
        return Stack(
          children: [
            textField(steps),
            if (steps)
              PositionedDirectional(
                top: edge,
                bottom: edge,
                end: edge,
                child: buttons,
              ),
          ],
        );
      },
    );

    // The step keys go to the field before text editing's own (Up and Down
    // would move the caret).
    field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: field,
    );
    // Outside an app root the field brings the text editing keys itself;
    // they must sit above the step keys.
    if (context.findAncestorWidgetOfExactType<DefaultTextEditingShortcuts>() ==
        null) {
      field = DefaultTextEditingShortcuts(child: field);
    }

    final canIncrease = _canIncrease, canDecrease = _canDecrease;
    // Next and previous values only beside a value (an empty field still
    // takes the actions).
    final spoken = _spoken(text);
    return MergeSemantics(
      child: Semantics(
        value: spoken,
        increasedValue: canIncrease && spoken != null
            ? _spoken(_fmt.format(_target(1)))
            : null,
        decreasedValue: canDecrease && spoken != null
            ? _spoken(_fmt.format(_target(-1)))
            : null,
        onIncrease: canIncrease ? () => _step(1) : null,
        onDecrease: canDecrease ? () => _step(-1) : null,
        child: field,
      ),
    );
  }
}

void _noop() {}

/// 2^53: whole numbers past it are not all doubles, so they stay doubles.
const _exactInts = 9007199254740992;
