import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../overlay/anchored_overlay.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import '../field/field.dart';
import '../popover/popover.dart';
import '../popover/popover_style.dart';
import '../text_field/text_field.dart';
import '../text_field/text_field_style.dart';
import '../text_field/typed_field.dart';
import 'calendar.dart';
import 'calendar_metrics.dart';
import 'date_picker_style.dart';
import 'date_math.dart';
import 'picker_field.dart';

export 'date_picker_style.dart';

/// A date field with a popup calendar: type the date, or
/// open the calendar with the button at the end of the field.
///
/// ```dart
/// DsField(
///   label: const Text('Doğum tarihi'),
///   child: DsDatePicker(
///     value: birthday,
///     lastDate: DateTime.now(),
///     onChanged: (d) => setState(() => birthday = d),
///   ),
/// )
/// ```
///
/// **Typing.** The field shows the date in the language's numeric pattern
/// (`05.10.2026` in Turkish, `10/5/2026` in US English) and
/// reads what is typed leniently ([DsDateFormat.tryParse]): any
/// separators, one- or two-digit days and months, a month name, a
/// two-digit year. [onChanged] follows the typing as soon as the text
/// holds a whole date (four-digit year) that can be chosen, and null while
/// it is empty. On Enter or when focus leaves, the text is shown in the
/// pattern again; text that is not a date, or a day that cannot be chosen,
/// keeps the error look (2px danger edge and icon, invalid for screen
/// readers) and the value is null. Nothing is reported without an edit:
/// tabbing through the field leaves [value] exactly as given, and a
/// [value] with a time of day keeps it (typing or choosing changes only
/// the date). Years show with four digits (`0476`), so every year reads
/// back as itself.
///
/// **Invalid input.** [onInputIssueChanged] tells why the text holds no date
/// (not a date, before [firstDate], after [lastDate], a day that cannot be
/// chosen), with a message in the field's language ("Enter a date as
/// DD.MM.YYYY."), and null once that is fixed; with `onChanged(null)` it tells
/// an empty field from an invalid one. Inside a [DsField] without an error of
/// its own, the field shows the message (WCAG 3.3.1).
///
/// **Calendar.** The button at the end of the field ("Choose date") opens
/// a [DsCalendar] in a popover, as does Alt+Down in the field. Focus moves
/// to the chosen day (else today); the calendar's keys apply. Choosing a
/// day closes it; Escape or a tap outside closes it without a change.
/// Focus returns to where it was, the button or the field (WAI-ARIA date
/// picker dialog). The button reads as expanded while it is open. On a
/// short or narrow window the calendar narrows its columns to fit and
/// scrolls inside the popup, following the keyboard.
///
/// **Field.** Inside a [DsField] the label names the field and the field's
/// error and required state apply; the button stays its own node. Null
/// [onChanged] disables it; [readOnly] keeps the date focusable and
/// selectable but fixed, and hides the calendar button (there is nothing
/// to choose).
///
/// Anatomy: text field (well, date, error icon), calendar button; popup
/// panel with a calendar.
///
/// Needs an [Overlay] for the popup; the field types without one.
class DsDatePicker extends StatefulWidget {
  /// Creates a date picker.
  const DsDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.onInputIssueChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.currentDate,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.style,
  });

  /// The chosen day, or null.
  final DateTime? value;

  /// Called with the new day, or null when the field is emptied or does
  /// not hold a date that can be chosen. Null disables the picker.
  final ValueChanged<DateTime?>? onChanged;

  /// Called with what is wrong when committed text holds no date that can
  /// be chosen, and with null once the text is a date or empty again.
  final ValueChanged<DsInputIssue?>? onInputIssueChanged;

  /// The earliest day that can be chosen or typed.
  final DateTime? firstDate;

  /// The latest day that can be chosen or typed.
  final DateTime? lastDate;

  /// Days for which this returns false cannot be chosen or typed.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Today, for the calendar; defaults to now.
  final DateTime? currentDate;

  /// Shown while the field is empty; defaults to the pattern to type
  /// ("GG.AA.YYYY").
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
  /// and copied; it takes no typing, the calendar button is hidden and
  /// Alt+Down does not open the calendar.
  final bool readOnly;

  /// Style laid over the theme and defaults.
  final DsDatePickerStyle? style;

  /// Desen's default date picker style under [theme].
  static DsDatePickerStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsDatePickerStyle(
      fieldStyle: const DsTextFieldStyle(
        width: 200,
        // Proportional figures, as in a browser's input: in the text
        // family, tabular figures make the period, comma and colon
        // digit-wide, so a typed "12.10.2026" or "12.500,00" would read
        // spaced out like a console.
      ),
      rangeWidth: 280,
      // The field's own buttons' look.
      buttonStyle: DsButtonStyle(
        height: 22,
        borderRadius: BorderRadius.circular(11),
        foreground: k.textMuted,
        iconSize: 16,
        hovered: DsButtonStyle(foreground: k.text),
        pressed: DsButtonStyle(foreground: k.text),
      ),
      panelStyle: const DsPopoverStyle(maxWidth: double.infinity),
      wideBreakpoint: 640,
    );
  }

  @override
  State<StatefulWidget> createState() => _DatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('value', value))
      ..add(DiagnosticsProperty('firstDate', firstDate, defaultValue: null))
      ..add(DiagnosticsProperty('lastDate', lastDate, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

/// A date range field with a popup calendar: the field
/// shows `12.10.2026 – 18.10.2026`; the calendar ([DsRangeCalendar])
/// chooses the start, then the end, previewing the range under the
/// pointer or the keyboard.
///
/// ```dart
/// DsDateRangePicker(
///   value: stay,
///   firstDate: DateTime.now(),
///   onChanged: (r) => setState(() => stay = r),
/// )
/// ```
///
/// Typing reads two dates in the language's pattern, separated by a dash (`–`,
/// `—`, ` - `, with or without spaces) or by nothing more than their numbers
/// (`12.10.2026-18.10.2026`, `12.10.2026 18.10.2026`); see [DsDatePicker] for
/// the rest. The popup shows two months side by side in a window at least
/// [DsDatePickerStyle.wideBreakpoint] wide (640) where they fit, one otherwise,
/// or [months] when set. It closes once the end is chosen; closing it before
/// leaves the value as it was. [onChanged] reports only whole ranges (or null).
class DsDateRangePicker extends StatefulWidget {
  /// Creates a date range picker.
  const DsDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.onInputIssueChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.currentDate,
    this.months,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.style,
  });

  /// The chosen range (both ends), or null.
  final DsDateRange? value;

  /// Called with the new range, or null when the field is emptied or does
  /// not hold a range that can be chosen. Null disables the picker.
  final ValueChanged<DsDateRange?>? onChanged;

  /// Called with what is wrong when committed text holds no range that
  /// can be chosen, and with null once it does or is empty again.
  final ValueChanged<DsInputIssue?>? onInputIssueChanged;

  /// The earliest day that can be chosen or typed.
  final DateTime? firstDate;

  /// The latest day that can be chosen or typed.
  final DateTime? lastDate;

  /// Days for which this returns false cannot be range ends.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Today, for the calendar; defaults to now.
  final DateTime? currentDate;

  /// Months in the popup; null picks one or two by the window's width.
  final int? months;

  /// Shown while the field is empty; defaults to the pattern to type.
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
  /// and copied; it takes no typing, the calendar button is hidden and
  /// Alt+Down does not open the calendar.
  final bool readOnly;

  /// Style laid over the theme and defaults.
  final DsDatePickerStyle? style;

  @override
  State<StatefulWidget> createState() => _DatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('value', value))
      ..add(IntProperty('months', months, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

/// Between the two dates of a range, shown and in the hints: an en dash
/// with spaces, as typography writes a span of dates. The localizations
/// have no range separator, and the dash reads in every supported script.
const _rangeDash = ' – ';

/// One state for both pickers: the value is a [DateTime] or a complete
/// [DsDateRange].
class _DatePickerState extends State<StatefulWidget>
    with DsTypedFieldState<StatefulWidget, Object> {
  final _popup = DsOverlayController();

  /// The range being chosen in the popup.
  DsDateRange? _draft;

  DsDateLocale? _locale;

  bool get _isRange => widget is DsDateRangePicker;
  DsDatePicker get _single => widget as DsDatePicker;
  DsDateRangePicker get _range => widget as DsDateRangePicker;

  Object? get _value => _isRange ? _range.value : _single.value;
  DateTime? get _firstDate => _isRange ? _range.firstDate : _single.firstDate;
  DateTime? get _lastDate => _isRange ? _range.lastDate : _single.lastDate;
  bool Function(DateTime)? get _predicate =>
      _isRange ? _range.selectableDayPredicate : _single.selectableDayPredicate;
  DateTime? get _currentDate =>
      _isRange ? _range.currentDate : _single.currentDate;
  DsDatePickerStyle? get _style => _isRange ? _range.style : _single.style;

  bool get _enabled => onChanged != null;

  bool get _readOnly => _isRange ? _range.readOnly : _single.readOnly;

  /// Enabled and not read-only: the value can change.
  bool get _canEdit => _enabled && !_readOnly;

  @override
  FocusNode? get widgetFocusNode =>
      _isRange ? _range.focusNode : _single.focusNode;

  @override
  ValueChanged<Object?>? get onChanged {
    if (_isRange) {
      final f = _range.onChanged;
      return f == null ? null : (v) => f(v as DsDateRange?);
    }
    final f = _single.onChanged;
    return f == null ? null : (v) => f(v as DateTime?);
  }

  @override
  ValueChanged<DsInputIssue?>? get onInputIssueChanged =>
      _isRange ? _range.onInputIssueChanged : _single.onInputIssueChanged;

  @override
  bool get canCommit => _canEdit;

  @override
  bool get commitsOnBlur => !_popup.isOpen;

  @override
  void initState() {
    super.initState();
    initTypedField(_value);
    _popup.addListener(_onPopup);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DsDateLocale.of(context);
    if (next == _locale) return;
    final first = _locale == null;
    _locale = next;
    // New pattern: the value, shown anew (unless the text is kept to be
    // fixed).
    if (first || issue == null) showValue(_value);
  }

  @override
  void didUpdateWidget(StatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(
      oldWidget is DsDatePicker
          ? oldWidget.focusNode
          : (oldWidget as DsDateRangePicker).focusNode,
    );
    // Set from outside: show it.
    if (_value != reported) showValue(_value);
    if (!_canEdit) _popup.close();
  }

  @override
  void dispose() {
    disposeTypedField();
    _popup.dispose();
    super.dispose();
  }

  DsDateFormat get _format => _locale!.shortDate;

  @override
  String show(Object? value) => switch (value) {
    final DateTime d => _format.format(d),
    DsDateRange(:final start, :final end) =>
      '${_format.format(start)}$_rangeDash'
          '${end == null ? '' : _format.format(end)}',
    _ => '',
  };

  /// [day] at the time of day of the value (a picker edits the date of a
  /// `DateTime`, never its time).
  DateTime _keepTime(DateTime day) {
    final base = reported is DateTime ? reported! as DateTime : _value;
    if (base is! DateTime) return day;
    return (base.isUtc ? DateTime.utc : DateTime.new)(
      day.year,
      day.month,
      day.day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  /// What is wrong with [day], or null when it can be chosen.
  DsInputIssue? _check(DateTime day) {
    final l10n = _locale!.strings;
    final first = _firstDate == null ? null : DsDateUtils.dateOnly(_firstDate!);
    final last = _lastDate == null ? null : DsDateUtils.dateOnly(_lastDate!);
    if (first != null && day.isBefore(first)) {
      return DsInputIssue(
        DsInputIssueKind.belowMin,
        l10n.dateTooEarly(_format.format(first)),
      );
    }
    if (last != null && day.isAfter(last)) {
      return DsInputIssue(
        DsInputIssueKind.aboveMax,
        l10n.dateTooLate(_format.format(last)),
      );
    }
    if (!(_predicate?.call(day) ?? true)) {
      return DsInputIssue(DsInputIssueKind.unavailable, l10n.dateUnavailable);
    }
    return null;
  }

  DsInputIssue get _unreadable {
    final hint = _locale!.dateHint;
    return DsInputIssue(
      DsInputIssueKind.invalid,
      _locale!.strings.invalidDate(_isRange ? '$hint$_rangeDash$hint' : hint),
    );
  }

  /// The date [text] holds, or why it holds none.
  DsTypedRead<DateTime> _readDate(String text) {
    final d = _format.tryParse(text, today: _currentDate);
    if (d == null) return (value: null, issue: _unreadable);
    if (_check(d) case final issue?) return (value: null, issue: issue);
    return (value: d, issue: null);
  }

  /// The value [text] holds (not empty), or why it holds none.
  @override
  DsTypedRead<Object> readCommit(String text) {
    if (!_isRange) {
      final read = _readDate(text);
      final d = read.value;
      return (value: d == null ? null : _keepTime(d), issue: read.issue);
    }
    final parts = _splitRange(text);
    if (parts == null) return (value: null, issue: _unreadable);
    final start = _readDate(parts.$1);
    if (start.issue != null) return (value: null, issue: start.issue);
    final end = _readDate(parts.$2);
    if (end.issue != null) return (value: null, issue: end.issue);
    if (end.value!.isBefore(start.value!)) {
      return (
        value: null,
        issue: DsInputIssue(
          DsInputIssueKind.belowMin,
          _locale!.strings.dateTooEarly(_format.format(start.value!)),
        ),
      );
    }
    return (
      value: DsDateRange(start: start.value!, end: end.value),
      issue: null,
    );
  }

  /// While typing: the value once every date has its four-digit year
  /// ("2", "20" would read as 2002, 2020), and null while it is empty.
  /// An issue waits for the commit.
  @override
  DsTypedRead<Object>? readTyping(String text) {
    if (text.trim().isEmpty) return (value: null, issue: null);
    if (!_yearsTyped(text)) return null;
    return (value: readCommit(text).value, issue: null);
  }

  /// [text] split into its two dates: at a dash, else after the third
  /// number.
  (String, String)? _splitRange(String text) {
    final dash = RegExp(r'\s*[–—~]\s*|\s+-\s+').allMatches(text).toList();
    if (dash.length == 1) {
      return (
        text.substring(0, dash.single.start),
        text.substring(dash.single.end),
      );
    }
    final numbers = RegExp(r'\d+').allMatches(text).toList();
    if (numbers.length == 6) {
      final at = numbers[3].start;
      return (text.substring(0, at), text.substring(at));
    }
    return null;
  }

  /// Whether every date in [text] has its four-digit year.
  bool _yearsTyped(String text) =>
      RegExp(r'(?<!\d)\d{4}(?!\d)').allMatches(text).length >=
      (_isRange ? 2 : 1);

  void _onPopup() {
    if (_popup.isOpen) {
      commit();
      final current = issue != null ? null : reported;
      _draft = current is DsDateRange ? current : null;
    } else {
      _draft = null;
    }
    if (mounted) setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_canEdit || !isOpenPopupKey(event)) return KeyEventResult.ignored;
    _popup.open();
    return KeyEventResult.handled;
  }

  void _chooseDay(DateTime day) {
    choose(_keepTime(day));
    _popup.close();
  }

  void _chooseRange(DsDateRange range) {
    if (!range.isComplete) {
      setState(() => _draft = range);
      return;
    }
    choose(range);
    _popup.close();
  }

  /// The height the popup's content can take: the room on the larger side
  /// of the field, as the popup places itself (below while it fits
  /// or has the most room, else above), less the panel's padding. Capping
  /// the content here, rather than letting the popup cap it in a second
  /// layout pass, keeps a scrolled offset (a day revealed by keys) from
  /// being clamped by the first pass.
  double _popupRoom(BuildContext overlayContext, DsDatePickerStyle ps) {
    final box = context.findRenderObject();
    final window = MediaQuery.maybeSizeOf(overlayContext);
    if (box is! RenderBox || !box.hasSize || window == null) {
      return double.infinity;
    }
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    // A field kept alive off screen in a lazy list has no place (NaN): its
    // popup is closing, so leave the content uncapped.
    if (!anchor.isFinite) return double.infinity;
    final margin =
        MediaQuery.paddingOf(overlayContext) +
        MediaQuery.viewInsetsOf(overlayContext) +
        const EdgeInsets.all(DsSpace.s8);
    const gap = DsSpace.s6; // DsAnchoredOverlay's default
    final above = anchor.top - margin.top - gap;
    final below = window.height - margin.bottom - anchor.bottom - gap;
    final panel = DsPopoverStyle.resolveLayers([
      DsPopover.defaultStyle(dsThemeOf(overlayContext)),
      DsPopoverTheme.of(overlayContext).style,
      ps.panelStyle,
    ], const {});
    final padding = panel.padding?.vertical ?? 0;
    return math.max(0.0, math.max(above, below) - padding);
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final locale = _locale!;
    final l10n = locale.strings;
    final scope = DsFieldScope.maybeOf(context);
    tellField(scope);
    final ps = DsDatePickerStyle.resolveLayers([
      DsDatePicker.defaultStyle(t),
      DsDatePickerTheme.of(context).style,
      _style,
    ], const {});
    final enabled = _enabled;
    final error =
        (_isRange ? _range.error : _single.error) ||
        issue != null ||
        (scope?.hasError ?? false);

    var fieldStyle = ps.fieldStyle ?? const DsTextFieldStyle();
    if (_isRange) {
      fieldStyle = fieldStyle.merge(DsTextFieldStyle(width: ps.rangeWidth));
    }
    final buttonStyle = ps.buttonStyle ?? const DsButtonStyle();
    final visual = buttonStyle.height ?? 0;
    final tap = DsTheme.sizesOf(context).minTapTarget;

    final field = DsTextField(
      controller: controller,
      focusNode: node,
      autofocus: _isRange ? _range.autofocus : _single.autofocus,
      enabled: enabled,
      readOnly: _readOnly,
      keyboardType: TextInputType.datetime,
      placeholder:
          (_isRange ? _range.placeholder : _single.placeholder) ??
          (_isRange
              ? '${locale.dateHint}$_rangeDash${locale.dateHint}'
              : locale.dateHint),
      semanticLabel: _isRange ? _range.semanticLabel : _single.semanticLabel,
      error: error,
      style: fieldStyle,
      onChanged: onText,
      onSubmitted: (_) => commit(),
    );

    final button = PickerFieldFrame.expandedButton(
      expanded: _popup.isOpen,
      child: DsButton.icon(
        size: DsSize.xs,
        variant: DsButtonVariant.ghost,
        style: buttonStyle,
        semanticLabel: l10n.chooseDate,
        onPressed: _canEdit ? _popup.toggle : null,
        icon: const DsIcon(DsIcons.calendar),
      ),
    );

    final keyed = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: field,
    );
    // A read-only value has nothing to choose: no calendar button.
    final child = _readOnly
        ? keyed
        : PickerFieldFrame(field: keyed, button: button, buttonVisual: visual);

    final window = MediaQuery.maybeSizeOf(context);
    final wide = window != null && window.width >= ps.wideBreakpoint!;

    return DsPopover(
      controller: _popup,
      semanticLabel: l10n.chooseDate,
      style: ps.panelStyle,
      // The popup's room is the window's less the trigger's: the calendar
      // narrows to its width and scrolls in its height (a landscape phone,
      // an 800×600 window).
      contentBuilder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final calendarStyle = ps.calendarStyle;
          final Widget calendar;
          if (!_isRange) {
            final current = reported is DateTime ? reported! as DateTime : null;
            calendar = DsCalendar(
              value: current,
              onChanged: _chooseDay,
              firstDate: _firstDate,
              lastDate: _lastDate,
              selectableDayPredicate: _predicate,
              currentDate: _currentDate,
              autofocus: true,
              style: calendarStyle,
            );
          } else {
            var months = _range.months;
            if (months == null) {
              // Two months where the window is wide and they fit at their
              // full size; else one.
              final two = CalendarMetrics(
                style: DsCalendarStyle.resolveLayers([
                  DsCalendar.defaultStyle(t),
                  DsCalendarTheme.of(context).style,
                  calendarStyle,
                ], const {}),
                scaler: MediaQuery.textScalerOf(context),
                tap: tap,
                months: 2,
              );
              months = wide && two.preferredWidth <= constraints.maxWidth
                  ? 2
                  : 1;
            }
            calendar = DsRangeCalendar(
              value: _draft,
              onChanged: _chooseRange,
              firstDate: _firstDate,
              lastDate: _lastDate,
              selectableDayPredicate: _predicate,
              currentDate: _currentDate,
              months: months,
              autofocus: true,
              style: calendarStyle,
            );
          }
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _popupRoom(context, ps)),
            child: SingleChildScrollView(child: calendar),
          );
        },
      ),
      child: child,
    );
  }
}
