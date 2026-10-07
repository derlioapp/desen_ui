import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../overlay/anchored_overlay.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import '../date/date_format.dart';
import '../date/date_locale.dart';
import '../date/picker_field.dart';
import '../field/field.dart';
import '../popover/popover.dart';
import '../popover/popover_style.dart';
import '../text_field/text_field.dart';
import '../text_field/text_field_style.dart';
import '../text_field/typed_field.dart';
import 'time_of_day.dart';
import 'time_picker_style.dart';

export 'time_of_day.dart';
export 'time_picker_style.dart';

/// A time field with a popup of columns: type the time,
/// or open hour and minute columns (and AM/PM on a 12-hour clock, seconds
/// with [showSeconds]) with the button at the end of the field.
///
/// ```dart
/// DsField(
///   label: const Text('Start'),
///   child: DsTimePicker(
///     value: start,
///     minuteStep: 15,
///     onChanged: (t) => setState(() => start = t),
///   ),
/// )
/// ```
///
/// Office hours, and a duration to the second:
///
/// ```dart
/// DsTimePicker(
///   value: meeting,
///   firstTime: const DsTime(9, 0),
///   lastTime: const DsTime(18, 0),
///   onChanged: (t) => setState(() => meeting = t),
/// )
/// DsTimePicker(
///   value: lap,
///   use24HourClock: true,
///   showSeconds: true,
///   onChanged: (t) => setState(() => lap = t),
/// )
/// ```
///
/// **Clock.** 24-hour (`14:30`) or 12-hour (`2:30 PM`, `ÖS 2:30`) as the locale
/// reads time ([dsUses24HourClock], by language and region: 12-hour in US and
/// Canadian English, Korean, Hindi, Egyptian Arabic; 24-hour in Turkish,
/// British English, Canadian French and most of Europe), or as [use24HourClock]
/// says. The columns set their digits in tabular figures.
///
/// **Typing.** Lenient ([DsDateFormat.tryParseTime]): `14:30`, `14.30`, `1430`,
/// `2:30 pm`, `2p`; with [showSeconds] also `14:30:05` and `143005`.
/// [onChanged] follows the typing once the minutes are typed (and the
/// seconds, once a second separator is typed); on Enter or when focus
/// leaves the text is shown in the clock's pattern again, and text that is
/// not a time, or a time outside [firstTime]–[lastTime], keeps the error
/// look with a null value. Nothing is reported without an edit.
/// [onInputIssueChanged] tells why the text holds no time ("Enter a time
/// such as 14:30.", "Enter a time at or after 09:00."), and null once it
/// does or is empty again; inside a [DsField] without an error of its own
/// the field shows that message (WCAG 3.3.1).
///
/// **Columns.** The button at the end ("Choose time") or Alt+Down opens
/// the columns; each scrolls, shows its chosen item in the selection style
/// and scrolls it into view. Minutes go in [minuteStep]s and seconds in
/// [secondStep]s (a typed value off the steps is listed too). Choosing an
/// item changes the time at once and keeps the columns open.
///
/// The hour, minute and second columns wrap, like the time wheels of iOS
/// and Android: Down on 23 gives 00, Down on minute 55 gives 00, and a
/// column longer than it shows scrolls round without an end. A wrapping
/// minute or second does not carry into the hour (59 to 00 stays in the
/// same hour), as on iOS. On a 12-hour clock the hours step through the
/// day: Down on 11 AM gives 12 PM.
///
/// **Limits.** [firstTime] and [lastTime] bound the times that can be
/// chosen or typed, such as office hours or "not before now". Items with
/// no time in range show as unavailable (muted and struck through, the
/// [DsTimePickerStyle.disabled] look) and cannot be chosen; a column stops
/// at the last item in range instead of wrapping into the unavailable
/// ones, and a column whose first or last item is out of range has ends
/// instead of scrolling round. An hour or AM/PM that holds a time in range can be chosen, and
/// the time moves to the nearest one in range (choosing 9 on 10:15 in
/// 09:30–18:00 gives 09:30).
///
/// A [firstTime] after [lastTime] is a range across midnight, such as a
/// night shift from 22:00 to 06:00: the hour column runs 22, 23, 00 … 06
/// and goes round between them, and Home and End give 22 and 06.
///
/// | Key | Action |
/// |---|---|
/// | Up / Down | Previous / next item in the column (an earlier / later time, as the list reads top to bottom), wrapping |
/// | Home / End | First / last item that can be chosen |
/// | Left / Right | Previous / next column (mirrored right to left) |
/// | Enter | Closes the columns, keeping the time |
/// | Escape | Closes the columns, restoring the time they opened with |
///
/// **Screen readers.** Each column is one adjustable node ("Hours, 14";
/// swipe up or down to change it), the field and the button their own.
/// Increase gives the next item, the later time, as Down does: the
/// columns read as lists, like the time lists of Android, Windows and
/// browsers, not as spin buttons. Increase and decrease wrap as the keys
/// do and are not offered toward an item out of range; a chosen item out
/// of range (a [value] given outside the limits) reads as "08,
/// Unavailable".
///
/// **Field.** Inside a [DsField] the label names the field and the
/// field's error and required state apply. Null [onChanged] disables it;
/// [readOnly] keeps the time focusable and selectable but fixed, in the
/// text field's read-only look, without the clock button.
///
/// Anatomy: text field (well, time, error icon), clock button; popup panel
/// with hour, minute, optional seconds and AM/PM columns.
///
/// Needs an [Overlay] for the popup; the field types without one.
class DsTimePicker extends StatefulWidget {
  /// Creates a time picker.
  const DsTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.onInputIssueChanged,
    this.minuteStep = 5,
    this.firstTime,
    this.lastTime,
    this.showSeconds = false,
    this.secondStep = 1,
    this.use24HourClock,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.style,
  }) : assert(minuteStep > 0 && minuteStep <= 30),
       assert(secondStep > 0 && secondStep <= 30);

  /// The chosen time, or null.
  final DsTime? value;

  /// Called with the new time, or null when the field is emptied or does
  /// not hold a time. Null disables the picker.
  final ValueChanged<DsTime?>? onChanged;

  /// Called with what is wrong when committed text holds no time, and
  /// with null once it does or is empty again.
  final ValueChanged<DsInputIssue?>? onInputIssueChanged;

  /// Minutes between items of the minute column.
  final int minuteStep;

  /// The earliest time that can be chosen or typed, or null for none.
  ///
  /// With [lastTime] it bounds one stretch of the day: up to [lastTime],
  /// or, when it is after [lastTime], across midnight (22:00 to 06:00).
  /// Without [showSeconds] its seconds are ignored. For "not before now":
  /// `firstTime: DsTime.fromDateTime(DateTime.now())`.
  final DsTime? firstTime;

  /// The latest time that can be chosen or typed, or null for none.
  ///
  /// Without [showSeconds] its seconds are ignored.
  final DsTime? lastTime;

  /// Whether the time has seconds: a seconds column, and the field shows
  /// and reads them (`14:30:05`, `2:30:05 PM`), for durations and logs.
  /// Off, the picker works to the minute and reports times on the minute.
  final bool showSeconds;

  /// Seconds between items of the seconds column, with [showSeconds].
  final int secondStep;

  /// Forces the 24-hour (true) or 12-hour (false) clock; null follows the
  /// region.
  final bool? use24HourClock;

  /// Shown while the field is empty.
  final String? placeholder;

  /// Focus node of the text field; one is created when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// Names the field for screen readers when no [DsField] label does.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Whether the value is fixed. The text can still be focused, selected
  /// and copied; it takes no typing and the columns do not open.
  final bool readOnly;

  /// Style laid over the theme and defaults.
  final DsTimePickerStyle? style;

  /// Desen's default time picker style under [theme].
  static DsTimePickerStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    final ring = theme.fillsSelection ? k.onSelectionStrong : k.focus;
    return DsTimePickerStyle(
      fieldStyle: const DsTextFieldStyle(
        width: 140,
        // Proportional figures, as in a browser's input: in the text
        // family, tabular figures make the period, comma and colon
        // digit-wide, so a typed "12.10.2026" or "12.500,00" would read
        // spaced out like a console.
      ),
      // The field's own buttons' look.
      buttonStyle: DsButtonStyle(
        height: 22,
        borderRadius: BorderRadius.circular(11),
        foreground: k.textMuted,
        iconSize: 16,
        hovered: DsButtonStyle(foreground: k.text),
        pressed: DsButtonStyle(foreground: k.text),
      ),
      panelStyle: const DsPopoverStyle(
        padding: EdgeInsets.all(DsSpace.s4),
        maxWidth: double.infinity,
      ),
      columnWidth: 68,
      columnGap: DsSpace.s8,
      dividerColor: k.border,
      visibleItems: 6,
      itemHeight: theme.sizes.row,
      itemGap: 1,
      // Concentric with the panel, inset by its padding.
      itemRadius: BorderRadius.circular(
        theme.radii.nested(theme.radii.overlay, DsSpace.s4),
      ),
      itemBackground: clear,
      itemForeground: k.text,
      itemBorderColor: clear,
      itemTextStyle: theme.typography.numeric(theme.typography.small),
      focusShadows: const [],
      cursor: SystemMouseCursors.click,
      hovered: DsTimePickerStyle(itemBackground: k.hover),
      pressed: DsTimePickerStyle(itemBackground: k.press),
      selected: DsTimePickerStyle(
        itemBackground: theme.selectedFill,
        itemForeground: theme.onSelectedFill,
        itemBorderColor: theme.selectedEdge ?? clear,
        itemTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        // Inside the full-width item, in the item's ink on a filled
        // selection.
        focusShadows: [DsShadow.innerRing(ring, width: 2)],
        hovered: DsTimePickerStyle(itemBackground: theme.selectedHoverFill),
        pressed: DsTimePickerStyle(itemBackground: theme.selectedHoverFill),
      ),
      // As the calendar's days out of range: muted and struck through,
      // not by color alone. A chosen item out of range keeps its fill.
      disabled: DsTimePickerStyle(
        itemForeground: k.onDisabled,
        itemTextStyle: TextStyle(
          decoration: TextDecoration.lineThrough,
          decorationColor: k.onDisabled,
        ),
        cursor: SystemMouseCursors.basic,
      ),
    );
  }

  @override
  State<DsTimePicker> createState() => _DsTimePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('value', value))
      ..add(IntProperty('minuteStep', minuteStep, defaultValue: 5))
      ..add(DiagnosticsProperty('firstTime', firstTime, defaultValue: null))
      ..add(DiagnosticsProperty('lastTime', lastTime, defaultValue: null))
      ..add(FlagProperty('showSeconds', value: showSeconds, ifTrue: 'seconds'))
      ..add(IntProperty('secondStep', secondStep, defaultValue: 1))
      ..add(
        FlagProperty(
          'use24HourClock',
          value: use24HourClock,
          ifTrue: '24-hour',
          ifFalse: '12-hour',
        ),
      )
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsTimePickerState extends State<DsTimePicker>
    with DsTypedFieldState<DsTimePicker, DsTime> {
  final _popup = DsOverlayController();

  /// The time when the columns opened, for Escape.
  DsTime? _opened;

  DsDateLocale? _locale;
  DsDateFormat? _format;

  final _columns = [FocusNode(), FocusNode(), FocusNode(), FocusNode()];

  bool get _enabled => widget.onChanged != null;

  /// Enabled and not read-only: the value can change.
  bool get _canEdit => _enabled && !widget.readOnly;

  bool get _uses24 => widget.use24HourClock ?? _locale!.uses24HourClock;

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  ValueChanged<DsTime?>? get onChanged => widget.onChanged;

  @override
  ValueChanged<DsInputIssue?>? get onInputIssueChanged =>
      widget.onInputIssueChanged;

  @override
  bool get canCommit => _canEdit;

  @override
  bool get commitsOnBlur => !_popup.isOpen;

  @override
  void initState() {
    super.initState();
    initTypedField(widget.value);
    _popup.addListener(_onPopup);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = DsDateLocale.of(context);
    _resolveFormat();
  }

  void _resolveFormat() {
    final next = _locale!.timeFormat(
      use24HourClock: _uses24,
      seconds: widget.showSeconds,
    );
    if (next == _format) return;
    final first = _format == null;
    _format = next;
    if (first || issue == null) showValue(widget.value);
  }

  @override
  void didUpdateWidget(DsTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(oldWidget.focusNode);
    if (widget.use24HourClock != oldWidget.use24HourClock ||
        widget.showSeconds != oldWidget.showSeconds) {
      _resolveFormat();
    }
    if (widget.value != reported) showValue(widget.value);
    if (!_canEdit) _popup.close();
  }

  @override
  void dispose() {
    disposeTypedField();
    _popup.dispose();
    for (final node in _columns) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  String show(DsTime? time) => time == null ? '' : _format!.formatTime(time);

  /// While typing: the time once the minutes (and seconds begun) are
  /// typed, null while empty or out of range. An issue waits for the
  /// commit.
  @override
  DsTypedRead<DsTime>? readTyping(String text) {
    if (text.trim().isEmpty) return (value: null, issue: null);
    if (!_minutesTyped.hasMatch(text)) return null;
    if (widget.showSeconds && _secondsPending.hasMatch(text)) return null;
    return (value: readCommit(text).value, issue: null);
  }

  @override
  DsTypedRead<DsTime> readCommit(String text) {
    final time = _format!.tryParseTime(text);
    if (time == null) {
      return (
        value: null,
        issue: DsInputIssue(
          DsInputIssueKind.invalid,
          _locale!.strings.invalidTime(
            _format!.formatTime(const DsTime(14, 30)),
          ),
        ),
      );
    }
    final l10n = _locale!.strings;
    if (_overnight) {
      if (_inside(time.inSeconds)) return (value: time, issue: null);
      // Out of the night: early when nearer the start, else late.
      final early = _lo - time.inSeconds < time.inSeconds - _hi;
      return (
        value: null,
        issue: DsInputIssue(
          early ? DsInputIssueKind.belowMin : DsInputIssueKind.aboveMax,
          l10n.timeOutsideRange(
            _format!.formatTime(DsTime.fromSeconds(_lo)),
            _format!.formatTime(DsTime.fromSeconds(_hi)),
          ),
        ),
      );
    }
    if (time.inSeconds < _lo) {
      return (
        value: null,
        issue: DsInputIssue(
          DsInputIssueKind.belowMin,
          l10n.timeTooEarly(_format!.formatTime(DsTime.fromSeconds(_lo))),
        ),
      );
    }
    if (time.inSeconds > _hi) {
      return (
        value: null,
        issue: DsInputIssue(
          DsInputIssueKind.aboveMax,
          l10n.timeTooLate(_format!.formatTime(DsTime.fromSeconds(_hi))),
        ),
      );
    }
    return (value: time, issue: null);
  }

  /// The finest step of the time: a second, or a minute without seconds.
  int get _unit => widget.showSeconds ? 1 : 60;

  /// The seconds of [time] since midnight, to the [_unit].
  int _toUnit(DsTime time) => time.inSeconds - time.inSeconds % _unit;

  /// The first time in range, in seconds since midnight.
  int get _lo => switch (widget.firstTime) {
    final first? => _toUnit(first),
    null => 0,
  };

  /// The last time in range, in seconds since midnight.
  int get _hi => switch (widget.lastTime) {
    final last? => _toUnit(last),
    null => 24 * 3600 - _unit,
  };

  /// Whether the range runs across midnight: [_lo] to the end of the
  /// day, then the start of the day to [_hi].
  bool get _overnight => _lo > _hi;

  /// Whether the time [seconds] after midnight is in range.
  bool _inside(int seconds) => _overnight
      ? seconds >= _lo || seconds <= _hi
      : seconds >= _lo && seconds <= _hi;

  /// Whether a time in range starts in the [length] seconds from [from].
  bool _holds(int from, int length) => _overnight
      ? from + length > _lo || from <= _hi
      : from <= _hi && from + length > _lo;

  /// [time] to the [_unit], moved into range: to the nearer end of it.
  DsTime _inRange(DsTime time) {
    final s = _toUnit(time);
    if (!_overnight) return DsTime.fromSeconds(s.clamp(_lo, _hi));
    if (_inside(s)) return DsTime.fromSeconds(s);
    return DsTime.fromSeconds(_lo - s <= s - _hi ? _lo : _hi);
  }

  /// Chooses [time], moved into range: an hour chosen on 10:15 in
  /// 09:30–18:00 gives 09:30.
  void _pick(DsTime time) => choose(_inRange(time));

  void _onPopup() {
    if (_popup.isOpen) {
      commit();
      _opened = issue != null ? null : reported;
    }
    if (mounted) setState(() {});
  }

  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (!_canEdit || !isOpenPopupKey(event)) return KeyEventResult.ignored;
    _popup.open();
    return KeyEventResult.handled;
  }

  /// The time the columns start from when none is chosen: now's hour,
  /// moved into range.
  DsTime get _base => reported ?? _inRange(DsTime(DateTime.now().hour, 0));

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final locale = _locale!;
    final l10n = locale.strings;
    final scope = DsFieldScope.maybeOf(context);
    tellField(scope);
    final layers = [
      DsTimePicker.defaultStyle(t),
      DsTimePickerTheme.of(context).style,
      widget.style,
    ];
    final ps = DsTimePickerStyle.resolveLayers(layers, const {});
    final enabled = _enabled;
    final error = widget.error || issue != null || (scope?.hasError ?? false);
    final fieldStyle = ps.fieldStyle ?? const DsTextFieldStyle();
    final buttonStyle = ps.buttonStyle ?? const DsButtonStyle();
    final visual = buttonStyle.height ?? 0;
    final field = DsTextField(
      controller: controller,
      focusNode: node,
      autofocus: widget.autofocus,
      enabled: enabled,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.datetime,
      placeholder: widget.placeholder,
      semanticLabel: widget.semanticLabel,
      error: error,
      style: fieldStyle,
      onChanged: onText,
      onSubmitted: (_) => commit(),
    );

    final frame = PickerFieldFrame(
      field: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onFieldKey,
        child: field,
      ),
      button: PickerFieldFrame.expandedButton(
        expanded: _popup.isOpen,
        child: DsButton.icon(
          size: DsSize.xs,
          variant: DsButtonVariant.ghost,
          style: buttonStyle,
          semanticLabel: l10n.chooseTime,
          onPressed: _canEdit ? _popup.toggle : null,
          icon: const DsIcon(DsIcons.clock),
        ),
      ),
      buttonVisual: visual,
    );

    return DsPopover(
      controller: _popup,
      semanticLabel: l10n.chooseTime,
      style: ps.panelStyle,
      contentBuilder: (context) => _columnsPanel(context, locale, layers, ps),
      child: frame,
    );
  }

  Widget _columnsPanel(
    BuildContext context,
    DsDateLocale locale,
    List<DsTimePickerStyle?> layers,
    DsTimePickerStyle ps,
  ) {
    final l10n = locale.strings;
    final uses24 = _uses24;
    final current = issue != null ? null : reported;
    final base = _base;
    String two(int v) => v.toString().padLeft(2, '0');
    String hourLabel(int h) => uses24 ? two(h) : '${h % 12 == 0 ? 12 : h % 12}';
    final pm = base.isPm ? 12 : 0;

    // Hours step through the day on either clock: on a 12-hour clock 11 AM
    // then 12 PM, as the AM/PM wheel turns with the hour on iOS and
    // Android; 23 wraps to 00.
    _Step? stepHour(int delta) {
      final h = (base.hour + delta) % 24;
      if (!_holds(h * 3600, 3600)) return null;
      return (label: hourLabel(h), go: () => _pick(base.copyWith(hour: h)));
    }

    final hours = _ColumnData(
      label: l10n.hours,
      items: [
        for (var h = 0; h < (uses24 ? 24 : 12); h++)
          (
            label: uses24 ? two(h) : '${h == 0 ? 12 : h}',
            value: h,
            available: _holds((uses24 ? h : h + pm) * 3600, 3600),
          ),
      ],
      selected: current == null
          ? null
          : (uses24 ? current.hour : current.hour % 12),
      start: uses24 ? base.hour : base.hour % 12,
      onSelect: (h) => _pick(base.copyWith(hour: uses24 ? h : h + pm)),
      step: stepHour,
      wraps: true,
    );

    // A column of sorted values, wrapping within its own unit: minute 55
    // steps to 00 of the same hour, not into the next.
    _ColumnData listColumn({
      required String label,
      required List<int> values,
      required int? selected,
      required int start,
      required bool Function(int value) available,
      required DsTime Function(int value) at,
    }) {
      final items = [
        for (final v in values)
          (label: two(v), value: v, available: available(v)),
      ];
      final from = math.max(0, values.lastIndexWhere((v) => v <= start));
      _Step? step(int delta) {
        final to = items[(from + delta) % items.length];
        if (!to.available) return null;
        return (label: to.label, go: () => _pick(at(to.value)));
      }

      return _ColumnData(
        label: label,
        items: items,
        selected: selected,
        start: start,
        onSelect: (v) => _pick(at(v)),
        step: step,
        wraps: true,
      );
    }

    final minutes = listColumn(
      label: l10n.minutes,
      values: {
        for (var m = 0; m < 60; m += widget.minuteStep) m,
        base.minute,
      }.toList()..sort(),
      selected: current?.minute,
      start: base.minute,
      available: (m) => _holds(base.hour * 3600 + m * 60, 60),
      at: (m) => base.copyWith(minute: m),
    );
    final seconds = widget.showSeconds
        ? listColumn(
            label: l10n.seconds,
            values: {
              for (var s = 0; s < 60; s += widget.secondStep) s,
              base.second,
            }.toList()..sort(),
            selected: current?.second,
            start: base.second,
            available: (s) => _holds(base.inMinutes * 60 + s, 1),
            at: (s) => base.copyWith(second: s),
          )
        : null;

    DsTime inPeriod(int p) => base.copyWith(hour: base.hour % 12 + p * 12);
    bool periodOpen(int p) => _holds(p * 12 * 3600, 12 * 3600);
    final period = _ColumnData(
      label: l10n.dayPeriod,
      items: [
        (label: l10n.am, value: 0, available: periodOpen(0)),
        (label: l10n.pm, value: 1, available: periodOpen(1)),
      ],
      selected: current == null ? null : (current.isPm ? 1 : 0),
      start: base.isPm ? 1 : 0,
      onSelect: (p) => _pick(inPeriod(p)),
      // Two items: no wrap; Down gives PM.
      step: (delta) {
        final p = (base.isPm ? 1 : 0) + delta;
        if (p < 0 || p > 1 || !periodOpen(p)) return null;
        return (
          label: p == 0 ? l10n.am : l10n.pm,
          go: () => _pick(inPeriod(p)),
        );
      },
      wraps: false,
    );
    final periodFirst =
        !uses24 && l10n.timePattern12.trimLeft().startsWith('a');
    final columns = [
      if (!uses24 && periodFirst) period,
      hours,
      minutes,
      ?seconds,
      if (!uses24 && !periodFirst) period,
    ];

    void move(int from, int delta) {
      final to = from + delta;
      if (to < 0 || to >= columns.length) return;
      _columns[to].requestFocus();
    }

    // Every column is as tall as the longest needs, up to the visible
    // items; items grow with large text.
    final scaler = MediaQuery.textScalerOf(context);
    final fontSize = ps.itemTextStyle?.fontSize ?? 0;
    final itemHeight = math.max(ps.itemHeight!, scaler.scale(fontSize) * 2);
    final extent = itemHeight + ps.itemGap!;
    final longest = columns.map((c) => c.items.length).reduce(math.max);
    final height =
        math.min(ps.visibleItems!, longest.toDouble()) * extent - ps.itemGap!;
    final divider = SizedBox(
      width: ps.columnGap,
      height: height,
      child: Center(
        child: DsLine(
          color: ps.dividerColor ?? const Color(0x00000000),
          axis: Axis.vertical,
        ),
      ),
    );
    final children = <Widget>[];
    for (var i = 0; i < columns.length; i++) {
      if (i > 0) children.add(divider);
      children.add(
        _TimeColumn(
          data: columns[i],
          focusNode: _columns[i],
          autofocus: i == (periodFirst && !uses24 ? 1 : 0),
          layers: layers,
          style: ps,
          itemHeight: itemHeight,
          maxHeight: height,
          enabled: _canEdit,
          unavailableLabel: l10n.unavailable,
          onMove: (delta) => move(i, delta),
          onCommit: _popup.close,
          onRevert: () => choose(_opened),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Minutes typed: a separator then two digits, or three or four digits.
final _minutesTyped = RegExp(r'\d\D+\d{2}(?!\d)|\d{3,4}');

/// Seconds begun but not yet two digits: `14:30:`, `14:30:1`.
final _secondsPending = RegExp(r'\d\D+\d{2}\s*[:.]\s*\d?\s*$');

/// An item of a column: its text, its value, and whether a time in range
/// can be chosen through it.
typedef _Item = ({String label, int value, bool available});

/// One step in a column: the next item's text, and choosing it.
typedef _Step = ({String label, VoidCallback go});

class _ColumnData {
  const _ColumnData({
    required this.label,
    required this.items,
    required this.selected,
    required this.start,
    required this.onSelect,
    required this.step,
    required this.wraps,
  });

  /// Names the column for screen readers.
  final String label;

  /// Shown text, value and availability of each item.
  final List<_Item> items;

  /// The chosen value, or null.
  final int? selected;

  /// Where the keys start when nothing is chosen.
  final int start;

  final ValueChanged<int> onSelect;

  /// The step by delta items from the chosen one (or [start]): wrapping
  /// as the column does, null when the item there is unavailable or
  /// there is none.
  final _Step? Function(int delta) step;

  /// Whether the column wraps, so a column that scrolls goes round.
  final bool wraps;
}

/// A scrolling column of choices: one Tab stop, Up and Down choose, one
/// adjustable semantics node.
class _TimeColumn extends StatefulWidget {
  const _TimeColumn({
    required this.data,
    required this.focusNode,
    required this.autofocus,
    required this.layers,
    required this.style,
    required this.itemHeight,
    required this.maxHeight,
    required this.enabled,
    required this.unavailableLabel,
    required this.onMove,
    required this.onCommit,
    required this.onRevert,
  });

  final _ColumnData data;
  final FocusNode focusNode;
  final bool autofocus;
  final List<DsTimePickerStyle?> layers;
  final DsTimePickerStyle style;
  final double itemHeight;
  final double maxHeight;
  final bool enabled;

  /// Follows the value of a chosen item out of range.
  final String unavailableLabel;
  final ValueChanged<int> onMove;
  final VoidCallback onCommit;
  final VoidCallback onRevert;

  @override
  State<_TimeColumn> createState() => _TimeColumnState();
}

class _TimeColumnState extends State<_TimeColumn> {
  ScrollController? _scroll;
  int? _hovered;
  int? _pressed;
  double _extent = 0;
  double _viewport = 0;

  /// Whether the column goes round: it wraps, both its ends can be
  /// chosen (so the wrap is open) and it has more items than it shows. Its
  /// list then repeats the items [_cycles] times and starts in the middle
  /// copy.
  bool _loops = false;

  /// The item count the scroll controller was made for.
  int _laidCount = 0;

  static const _loopCycles = 200;

  int get _cycles => _loops ? _loopCycles : 1;

  int get _count => widget.data.items.length;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    FocusManager.instance.addHighlightModeListener(_onHighlight);
    DsFocusVisibility.keyboard.addListener(_onModality);
    WidgetsBinding.instance.addPostFrameCallback((_) => _settle());
  }

  /// After the first layout, when the room the popup gave is known: an
  /// item at the end of the list rests at the very end, not cut by a
  /// window too short for whole rows.
  void _settle() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    final want = _centered(_position(_index));
    if ((want - scroll.offset).abs() > 0.5) scroll.jumpTo(want);
  }

  @override
  void didUpdateWidget(_TimeColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
    if (oldWidget.data.selected != widget.data.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    FocusManager.instance.removeHighlightModeListener(_onHighlight);
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _scroll?.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});
  void _onHighlight(FocusHighlightMode _) => setState(() {});
  void _onModality() => setState(() {});

  int get _index {
    final data = widget.data;
    final value = data.selected ?? data.start;
    final i = data.items.indexWhere((item) => item.value == value);
    if (i >= 0) return i;
    // The nearest item before the value.
    var best = 0;
    for (var j = 0; j < data.items.length; j++) {
      if (data.items[j].value <= value) best = j;
    }
    return best;
  }

  /// Whole rows the column shows at once.
  int get _rows =>
      math.max(1, ((_viewport + widget.style.itemGap!) / _extent).round());

  /// The offset that shows list position [index] in the middle row, on
  /// whole rows (no row cut by an edge); near the end of the list, the
  /// end itself.
  double _centered(int index) {
    final last = math.max(0, _count * _cycles - _rows);
    final first = (index - (_rows - 1) ~/ 2).clamp(0, last);
    if (first == last && first > 0) return _end;
    return first * _extent;
  }

  /// The offset at the end of the list: the scroll end once laid out (the
  /// popup may give less room than the rows asked for), else what the
  /// rows ask for.
  double get _end {
    final scroll = _scroll;
    if (scroll != null && scroll.hasClients) {
      return scroll.position.maxScrollExtent;
    }
    return math.max(0, _count * _cycles * _extent - _viewport);
  }

  /// The list position of item [index]: in a column that goes round, the
  /// copy nearest the middle of the view (or of the list, before layout).
  int _position(int index) {
    if (!_loops) return index;
    final scroll = _scroll;
    final middle = scroll != null && scroll.hasClients
        ? scroll.offset / _extent + (_rows - 1) / 2
        : (_cycles ~/ 2 * _count + index).toDouble();
    return index + _count * ((middle - index) / _count).round();
  }

  /// Scrolls so the chosen item shows, clear of the faded edge rows: by
  /// whole rows to one row inside the edge it crossed, or centered when it
  /// was out of view.
  void _reveal() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    if (_loops) {
      // Far from the middle copy after long scrolling: jump back by whole
      // copies, which looks the same.
      final copy = _extent * _count;
      final away = (scroll.offset / copy).floor() - _cycles ~/ 2;
      if (away.abs() > 2) scroll.jumpTo(scroll.offset - away * copy);
    }
    final index = _position(_index);
    final top = index * _extent;
    final offset = scroll.offset;
    final max = scroll.position.maxScrollExtent;
    final view = scroll.position.viewportDimension;
    final gap = widget.style.itemGap!;
    final band = _fadeBand;
    // As the edge fade decides: an end fades with an item beyond it.
    final fadeTop = offset > 0.5 ? band : 0.0;
    final fadeBottom = offset < max - gap - 0.5 ? band : 0.0;
    final shown = top >= offset && top + _extent - gap <= offset + view;
    if (shown &&
        top >= offset + fadeTop &&
        top + _extent - gap <= offset + view - fadeBottom) {
      return;
    }
    final margin = _rows >= 3 ? 1 : 0;
    var target = !shown
        ? _centered(index)
        : top < offset + fadeTop
        ? (index - margin) * _extent
        : (index - (_rows - 1 - margin)) * _extent;
    // Among the last rows: the end, so the last item is not cut.
    if (target >= (_count * _cycles - _rows) * _extent) target = max;
    final clamped = target.clamp(0.0, max);
    if (clamped == offset) return;
    final motion = DsTheme.motionOf(context);
    if (motion.reduced) {
      scroll.jumpTo(clamped);
    } else {
      scroll.animateTo(
        clamped,
        duration: motion.toneDuration,
        curve: motion.toneCurve,
      );
    }
  }

  /// The faded band at an edge with more items beyond: the outer half of
  /// the edge row, so it never reaches a row clear of the edge.
  double get _fadeBand => _extent / 2;

  /// Reports [value]. A [touch] (a tap) on a new value ticks; keys and
  /// assistive actions are silent, as on iOS.
  void _select(int value, {bool touch = false}) {
    if (touch && value != widget.data.selected) {
      DsHapticFeedback.play(context, DsHapticEvent.selection);
    }
    widget.data.onSelect(value);
  }

  /// Up or Down: the start item when nothing is chosen, else the next
  /// item that way, wrapping, unless it is out of range.
  void _step(int delta) {
    final data = widget.data;
    if (data.selected == null) {
      final item = data.items[_index];
      if (item.available) _select(item.value);
      return;
    }
    data.step(delta)?.go();
  }

  /// Home or End: the first or last item that can be chosen. In a column
  /// whose items in range run round its end (22, 23, 00 … 06 for a night),
  /// the run's first and last.
  void _edge({required bool first}) {
    final items = widget.data.items;
    final n = items.length;
    if (!items.any((item) => item.available)) return;
    if (items.every((item) => item.available)) {
      _select((first ? items.first : items.last).value);
      return;
    }
    for (var i = 0; i < n; i++) {
      final before = items[(i - 1 + n) % n].available;
      final after = items[(i + 1) % n].available;
      if (items[i].available && (first ? !before : !after)) {
        _select(items[i].value);
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onRevert();
      // The layer closes it.
      return KeyEventResult.ignored;
    }
    if (!widget.enabled) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _step(1);
    } else if (key == LogicalKeyboardKey.home) {
      _edge(first: true);
    } else if (key == LogicalKeyboardKey.end) {
      _edge(first: false);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      widget.onMove(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      widget.onMove(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) widget.onCommit();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = widget.style;
    final data = widget.data;
    final itemHeight = widget.itemHeight;
    final gap = s.itemGap!;
    _extent = itemHeight + gap;
    final count = _count;
    _viewport = math.min(widget.maxHeight, count * _extent - gap);
    final scrolls = count * _extent - gap > _viewport + 0.5;
    final loops =
        data.wraps &&
        scrolls &&
        data.items.first.available &&
        data.items.last.available;
    if (_scroll != null && (loops != _loops || count != _laidCount)) {
      // The positions moved (the column starts or stops going round, or a
      // typed minute off the steps joined it): a new controller shows the
      // chosen item in the middle again. The list lets go of the old one
      // in this frame.
      final old = _scroll!;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      _scroll = null;
    }
    _loops = loops;
    _laidCount = count;
    final width = math.max(
      s.columnWidth!,
      DsTheme.sizesOf(context).minTapTarget,
    );
    final index = _index;
    _scroll ??= ScrollController(
      // Always from the chosen item, never a stored offset.
      keepScrollOffset: false,
      initialScrollOffset: _centered(
        _loops ? _cycles ~/ 2 * count + index : index,
      ),
    );
    final focusVisible =
        widget.focusNode.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
        DsFocusVisibility.keyboard.value;

    // [i] is the list position; a column that goes round repeats its
    // items.
    Widget item(int i) {
      final k = i % count;
      final (:label, :value, :available) = data.items[k];
      final selected = data.selected == value;
      final live = widget.enabled && available;
      final states = <WidgetState>{
        if (_hovered == i && live) WidgetState.hovered,
        if (_pressed == i && live) WidgetState.pressed,
        if (selected) WidgetState.selected,
        if (focusVisible && k == index) WidgetState.focused,
        if (!available) WidgetState.disabled,
      };
      final d = DsTimePickerStyle.resolveLayers(widget.layers, states);
      final border = d.itemBorderColor ?? const Color(0x00000000);
      return MouseRegion(
        cursor: d.cursor ?? MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = i),
        onExit: (_) {
          if (_hovered == i) setState(() => _hovered = null);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: live ? (_) => setState(() => _pressed = i) : null,
          onTapCancel: () => setState(() => _pressed = null),
          onTap: live
              ? () {
                  setState(() => _pressed = null);
                  _select(value, touch: true);
                }
              : null,
          child: AnimatedContainer(
            duration: t.motion.toneDuration,
            curve: t.motion.toneCurve,
            height: itemHeight,
            alignment: Alignment.center,
            decoration: DsBoxDecoration(
              color: d.itemBackground,
              borderRadius: d.itemRadius ?? BorderRadius.zero,
              shadows: [
                if (border.a > 0) DsShadow.innerRing(border),
                if (states.contains(WidgetState.focused)) ...?d.focusShadows,
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: (d.itemTextStyle ?? const TextStyle()).copyWith(
                color: d.itemForeground,
              ),
            ),
          ),
        ),
      );
    }

    final chosen = data.selected == null ? null : data.items[index];
    final value = chosen == null
        ? null
        : chosen.available
        ? chosen.label
        : '${chosen.label}, ${widget.unavailableLabel}';
    // Next and previous values only beside a value (a column with
    // nothing chosen still takes the actions), and only in range.
    final next = widget.enabled ? data.step(1) : null;
    final previous = widget.enabled ? data.step(-1) : null;
    return Semantics(
      container: true,
      label: data.label,
      value: value,
      increasedValue: value == null ? null : next?.label,
      decreasedValue: value == null ? null : previous?.label,
      onIncrease: next?.go,
      onDecrease: previous?.go,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _onKey,
        child: ExcludeSemantics(
          child: SizedBox(
            width: width,
            height: _viewport,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              // An edge with more items beyond fades, like a wheel: only the
              // outer half of the edge row, where the chosen item never
              // rests. A column that fits shows every item unfaded.
              child: _EdgeFade(
                scroll: _scroll!,
                band: _fadeBand,
                trailing: gap,
                enabled: scrolls,
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  itemCount: count * _cycles,
                  itemExtent: _extent,
                  itemBuilder: (context, i) =>
                      Align(alignment: Alignment.topCenter, child: item(i)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades the ends of a scrolling column where more items lie beyond.
///
/// Whether an end fades is read from the list's scroll position, which
/// is only known once the list is laid out: the fade is decided again on
/// every scroll and every change of the scroll metrics, the first layout
/// included.
class _EdgeFade extends StatefulWidget {
  const _EdgeFade({
    required this.scroll,
    required this.band,
    required this.trailing,
    required this.enabled,
    required this.child,
  });

  final ScrollController scroll;
  final double band;

  /// Space after the last item that holds nothing (the gap after it): at
  /// most this much left to scroll is no item beyond the bottom edge.
  final double trailing;
  final bool enabled;
  final Widget child;

  @override
  State<_EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<_EdgeFade> {
  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0) setState(() {});
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: ListenableBuilder(
        listenable: widget.scroll,
        child: widget.child,
        builder: (context, child) {
          final position = widget.scroll.hasClients
              ? widget.scroll.position
              : null;
          final known = position != null && position.hasContentDimensions;
          // An end fades only with part of an item beyond it. Before the
          // first layout neither is known; the metrics notification after
          // it decides.
          final top = known && position.pixels > position.minScrollExtent + 0.5;
          final bottom =
              known &&
              position.pixels <
                  position.maxScrollExtent - widget.trailing - 0.5;
          final band = widget.band;
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final edge = rect.height <= 0
                  ? 0.0
                  : (band / rect.height).clamp(0.0, .5);
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  top ? _clear : _opaque,
                  _opaque,
                  _opaque,
                  bottom ? _clear : _opaque,
                ],
                stops: [0, edge, 1 - edge, 1],
              ).createShader(rect);
            },
            child: child,
          );
        },
      ),
    );
  }
}

// Mask colors: only alpha counts.
const _opaque = Color(0xFF000000); // ds-raw: a mask, only alpha counts
const _clear = Color(0x00000000);
