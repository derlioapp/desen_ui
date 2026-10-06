import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import 'calendar_style.dart';
import 'calendar_metrics.dart';
import 'date_locale.dart';
import 'date_math.dart';

export 'calendar_style.dart';
export 'date_format.dart';
export 'date_locale.dart';

/// A range of calendar days: a [start] and, once chosen, an [end] (the
/// same day for a one-day range). Times of day are ignored.
@immutable
class DsDateRange {
  /// Creates a range; [end] is null while only the start is chosen.
  DsDateRange({required DateTime start, DateTime? end})
    : start = DsDateUtils.dateOnly(start),
      end = end == null ? null : DsDateUtils.dateOnly(end),
      assert(end == null || !end.isBefore(DsDateUtils.dateOnly(start)));

  /// The first day.
  final DateTime start;

  /// The last day, or null while only [start] is chosen.
  final DateTime? end;

  /// Whether both ends are chosen.
  bool get isComplete => end != null;

  /// Whether [day] is from [start] to [end], both included.
  bool contains(DateTime day) {
    final d = DsDateUtils.dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end ?? start);
  }

  @override
  bool operator ==(Object other) =>
      other is DsDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DsDateRange($start – $end)';
}

/// An inline month calendar for choosing one day: a month and year
/// header with previous and next buttons, the weekday row, and the days.
/// [DsRangeCalendar] chooses a range of days.
///
/// ```dart
/// DsCalendar(
///   value: day,
///   firstDate: DateTime(2026),
///   onChanged: (d) => setState(() => day = d),
/// )
/// ```
///
/// **Days.** The chosen day is a solid accent fill (the strong selection
/// pair, whatever the theme's [DsSelectionStyle]): it is the most
/// prominent day in the grid. Today is
/// bold in the accent text color inside a thin ring of the same color, so
/// it is not told by color alone; a chosen today is only filled.
/// Days before [firstDate], after [lastDate] or refused by
/// [selectableDayPredicate] are struck through and cannot be chosen; the
/// keyboard still moves over them. Days of the months before and after are
/// hidden, or muted with [showOutsideDays]. Every month shows six weeks, so
/// the calendar keeps its height from month to month.
///
/// **Size.** A day is drawn at the density's day size (32, or 38 for touch
/// density, `DsSizes.day`) and grows with large text; its tap area fills
/// the space up to the next day and is never smaller than the minimum tap
/// target (24 on desktop, 44 on touch screens).
///
/// **Locale.** Month and weekday names come from [DsLocalizations]; the
/// first day of the week from the region ([dsFirstDayOfWeek]: Monday in
/// Turkey and Europe, Sunday in the US and Japan, Saturday in Egypt).
///
/// **Keyboard** (WAI-ARIA date grid). The days are one Tab stop: focus
/// lands on the chosen day, else today, else the first day that can be
/// chosen, and moves with the keys (roving focus). Left and right are
/// mirrored in right-to-left text.
///
/// | Key | Action |
/// |---|---|
/// | Left / Right | Previous / next day |
/// | Up / Down | Same day of the previous / next week |
/// | Home / End | First / last day of the week |
/// | Page Up / Page Down | Same day of the previous / next month |
/// | Shift + Page Up / Page Down | Same day of the previous / next year |
/// | Enter, Space | Chooses the focused day |
///
/// Moving past the shown months turns the page. A new month slides in with
/// the movement spring; under reduced motion it only fades.
///
/// **Screen readers.** Each day is a button named by its full date in the
/// language ("5 Ekim 2026 Pazartesi"), with today said after it; the
/// chosen day is selected. The month title is a live region, so turning
/// the page is announced.
///
/// Anatomy: header (title, previous and next buttons), weekday row, days.
/// Works without `DsScope` or `DsApp`.
class DsCalendar extends _Calendar {
  /// A calendar for choosing one day.
  const DsCalendar({
    super.key,
    required this.value,
    required this.onChanged,
    super.firstDate,
    super.lastDate,
    super.selectableDayPredicate,
    super.initialMonth,
    super.onMonthChanged,
    super.currentDate,
    super.showOutsideDays,
    super.months,
    super.focusNode,
    super.autofocus,
    super.semanticLabel,
    super.style,
  });

  /// The chosen day, or null.
  final DateTime? value;

  /// Called with the day chosen. Null disables the calendar.
  final ValueChanged<DateTime>? onChanged;

  @override
  DateTime? get _anchor => value;

  @override
  bool get _enabled => onChanged != null;

  /// Desen's default calendar style under [theme], for [DsCalendar] and
  /// [DsRangeCalendar].
  static DsCalendarStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final type = theme.typography;
    const clear = Color(0x00000000);
    // The chosen day is filled whatever the selection style: the strong
    // pair, with the hairline a bright accent needs off the card (K-130).
    final strong = theme.selectionStyle == DsSelectionStyle.strong
        ? theme
        : theme.copyWith(selectionStyle: DsSelectionStyle.strong);
    return DsCalendarStyle(
      daySize: theme.sizes.day,
      // No day radius: the corners follow the resolved day size.
      dayBackground: clear,
      dayForeground: k.text,
      dayBorderColor: clear,
      dayTextStyle: type.numeric(type.small).copyWith(height: 1),
      todayForeground: k.accentText,
      todayTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      // A ring as well as the color (WCAG 1.4.1): accent text stands 4.5:1
      // off every layer and the band, so its ring stands 3:1.
      todayBorderColor: k.accentText,
      outsideForeground: k.textSubtle,
      rangeColor: k.accentTint,
      // No line along the band, at any contrast level: its filled ends
      // mark the range.
      rangeEdgeColor: clear,
      columnGap: DsSpace.s4,
      rowGap: 2,
      headerStyle: type.bodyStrong.copyWith(color: k.text),
      headerPadding: const EdgeInsetsDirectional.only(
        start: DsSpace.s6,
        end: 2,
        bottom: DsSpace.s4,
      ),
      weekdayStyle: type.overline.copyWith(
        letterSpacing: 0,
        color: k.textSubtle,
      ),
      gap: DsSpace.s8,
      monthGap: DsSpace.s24,
      navButtonStyle: DsButtonStyle(foreground: k.textMuted),
      slideOffset: DsSpace.s24,
      focusShadows: theme.focusShadows,
      hovered: DsCalendarStyle(dayBackground: k.hover),
      pressed: DsCalendarStyle(dayBackground: k.press),
      selected: DsCalendarStyle(
        dayBackground: strong.selectedFill,
        dayForeground: strong.onSelectedFill,
        dayBorderColor: strong.selectedEdge ?? clear,
        dayTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        hovered: DsCalendarStyle(dayBackground: strong.selectedHoverFill),
        pressed: DsCalendarStyle(dayBackground: strong.selectedHoverFill),
      ),
      disabled: DsCalendarStyle(
        dayBackground: clear,
        dayForeground: k.onDisabled,
        dayTextStyle: TextStyle(
          decoration: TextDecoration.lineThrough,
          decorationColor: k.onDisabled,
        ),
        cursor: SystemMouseCursors.basic,
      ),
      cursor: SystemMouseCursors.click,
    );
  }
}

/// An inline month calendar for choosing a range of days: the first
/// choice is the start, the second the end (they swap when the end comes
/// first), the next starts over. [DsCalendar] chooses one day; the
/// header, sizes, locale, keyboard and style ([DsCalendarStyle],
/// [DsCalendarTheme]) are the same.
///
/// ```dart
/// DsRangeCalendar(
///   value: stay,
///   months: 2,
///   onChanged: (r) => setState(() => stay = r),
/// )
/// ```
///
/// **Days.** Both ends of the range are filled and the days between sit on
/// a soft accent band that runs into the ends; the band rounds where the
/// range, a week or the month ends. While only the start is chosen, the
/// band previews the range to the day under the pointer or the keyboard
/// focus. Today, days that cannot be chosen and the days of other months
/// look as in [DsCalendar].
///
/// **Keyboard.** As in [DsCalendar]; focus lands on the range's start,
/// else today, else the first day that can be chosen.
///
/// **Screen readers.** Each day is a button named by its full date in the
/// language, with today, range ends and days in the range said after it;
/// the range's ends are selected. The month title is a live region, so
/// turning the page is announced.
///
/// Anatomy: header (title, previous and next buttons), weekday row, days
/// (range band, day). Works without `DsScope` or `DsApp`.
class DsRangeCalendar extends _Calendar {
  /// A calendar for choosing a range of days.
  const DsRangeCalendar({
    super.key,
    required this.value,
    required this.onChanged,
    super.firstDate,
    super.lastDate,
    super.selectableDayPredicate,
    super.initialMonth,
    super.onMonthChanged,
    super.currentDate,
    super.showOutsideDays,
    super.months,
    super.focusNode,
    super.autofocus,
    super.semanticLabel,
    super.style,
  });

  /// The chosen range, or null.
  final DsDateRange? value;

  /// Called with the new range: a start alone, then the complete range.
  /// Null disables the calendar.
  final ValueChanged<DsDateRange>? onChanged;

  @override
  DateTime? get _anchor => value?.start;

  @override
  bool get _enabled => onChanged != null;
}

/// What [DsCalendar] and [DsRangeCalendar] share: everything but the
/// value and its callback.
sealed class _Calendar extends StatefulWidget {
  const _Calendar({
    super.key,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.initialMonth,
    this.onMonthChanged,
    this.currentDate,
    this.showOutsideDays = false,
    this.months = 1,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  }) : assert(months >= 1);

  /// The earliest day that can be chosen; the page does not turn before
  /// its month.
  final DateTime? firstDate;

  /// The latest day that can be chosen; the page does not turn after its
  /// month.
  final DateTime? lastDate;

  /// Days for which this returns false cannot be chosen (weekends, booked
  /// days).
  final bool Function(DateTime day)? selectableDayPredicate;

  /// The month shown first; defaults to the chosen day's (the range's
  /// start), else today's.
  final DateTime? initialMonth;

  /// Called with the first shown month when the page turns.
  final ValueChanged<DateTime>? onMonthChanged;

  /// Today; defaults to now. Set it for stable tests and screenshots.
  final DateTime? currentDate;

  /// Shows the days of the months before and after, muted, instead of
  /// leaving their places empty. Choosing one turns the page.
  final bool showOutsideDays;

  /// How many months show side by side.
  final int months;

  /// The focus node of the days. The days are one Tab stop with a node
  /// each (roving focus); focusing this node moves focus to the day the
  /// keyboard is on, and it has focus while any day does. One is created
  /// when null.
  final FocusNode? focusNode;

  /// Focuses the day the keyboard would land on when first built.
  final bool autofocus;

  /// Names the calendar for screen readers, before the shown months
  /// ("Check-in, October 2026").
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsCalendarStyle? style;

  /// The day the calendar is about: the chosen day or the range's start.
  DateTime? get _anchor;

  /// Whether days can be chosen (the callback is set).
  bool get _enabled;

  @override
  State<_Calendar> createState() => _CalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final value = switch (this) {
      DsCalendar(:final value) => value as Object?,
      DsRangeCalendar(:final value) => value,
    };
    properties
      ..add(DiagnosticsProperty<Object>('value', value, defaultValue: null))
      ..add(DiagnosticsProperty('firstDate', firstDate, defaultValue: null))
      ..add(DiagnosticsProperty('lastDate', lastDate, defaultValue: null))
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        FlagProperty(
          'showOutsideDays',
          value: showOutsideDays,
          ifTrue: 'outside days',
        ),
      )
      ..add(FlagProperty('enabled', value: _enabled, ifFalse: 'disabled'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _CalendarState extends State<_Calendar>
    with SingleTickerProviderStateMixin {
  /// The first month shown.
  late DateTime _month;

  /// The day the keyboard is on (the roving Tab stop).
  late DateTime _focused;

  DateTime? _hovered;
  DateTime? _pressed;

  /// Whether the days hold focus, for the range preview.
  bool _hasFocus = false;

  final _nodes = <DateTime, FocusNode>{};

  FocusNode? _ownNode;

  /// The node around the days: [DsCalendar.focusNode] or the calendar's
  /// own.
  FocusNode get _gridNode =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'DsCalendar'));

  /// The page turning out, while the new one slides in.
  DateTime? _outgoing;
  int _direction = 1;
  late final _slide = AnimationController.unbounded(vsync: this, value: 1);

  bool get _enabled => widget._enabled;

  DateTime get _today =>
      DsDateUtils.dateOnly(widget.currentDate ?? DateTime.now());

  DateTime? get _first =>
      widget.firstDate == null ? null : DsDateUtils.dateOnly(widget.firstDate!);

  DateTime? get _last =>
      widget.lastDate == null ? null : DsDateUtils.dateOnly(widget.lastDate!);

  /// The day the calendar is about: the chosen day or the range's start.
  DateTime? get _anchor {
    final d = widget._anchor;
    return d == null ? null : DsDateUtils.dateOnly(d);
  }

  /// The range of a [DsRangeCalendar], or null.
  DsDateRange? get _range => switch (widget) {
    DsRangeCalendar(:final value) => value,
    DsCalendar() => null,
  };

  @override
  void initState() {
    super.initState();
    _month = _clampMonth(
      DsDateUtils.monthOf(widget.initialMonth ?? _anchor ?? _today),
    );
    _focused = _landing();
    FocusManager.instance.addHighlightModeListener(_onHighlight);
    DsFocusVisibility.keyboard.addListener(_onModality);
    _gridNode.addListener(_onGridFocus);
  }

  @override
  void didUpdateWidget(_Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onGridFocus);
      if (widget.focusNode != null) {
        _ownNode?.dispose();
        _ownNode = null;
      }
      _gridNode.addListener(_onGridFocus);
    }
    final anchor = _anchor;
    if (anchor != null && !DsDateUtils.isSameDay(anchor, oldWidget._anchor)) {
      // Chosen from outside (or typed): show it.
      if (!_visible(anchor)) _month = _clampMonth(DsDateUtils.monthOf(anchor));
      if (!_hasFocus) _focused = anchor;
    }
    if (widget.months != oldWidget.months ||
        widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _month = _clampMonth(_month);
    }
    if (!_visible(_focused)) _focused = _landing();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlight);
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _gridNode.removeListener(_onGridFocus);
    _ownNode?.dispose();
    _slide.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Focus given to the days as a whole goes on to the day the keyboard
  /// is on.
  void _onGridFocus() {
    if (_gridNode.hasPrimaryFocus) _moveTo(_focused);
  }

  void _onHighlight(FocusHighlightMode _) {
    if (mounted) setState(() {});
  }

  void _onModality() {
    if (mounted) setState(() {});
  }

  bool _selectable(DateTime day) {
    final first = _first, last = _last;
    if (first != null && day.isBefore(first)) return false;
    if (last != null && day.isAfter(last)) return false;
    return widget.selectableDayPredicate?.call(day) ?? true;
  }

  int _monthIndex(DateTime day) =>
      (day.year - _month.year) * 12 + day.month - _month.month;

  bool _visible(DateTime day) {
    final i = _monthIndex(day);
    return i >= 0 && i < widget.months;
  }

  DateTime _clampMonth(DateTime month) {
    final first = _first, last = _last;
    var m = month;
    if (last != null) {
      final latest = DsDateUtils.addMonths(
        DsDateUtils.monthOf(last),
        -(widget.months - 1),
      );
      if (m.isAfter(latest)) m = latest;
    }
    if (first != null && m.isBefore(DsDateUtils.monthOf(first))) {
      m = DsDateUtils.monthOf(first);
    }
    return m;
  }

  DateTime _clampDay(DateTime day) {
    final first = _first, last = _last;
    if (first != null && day.isBefore(first)) return first;
    if (last != null && day.isAfter(last)) return last;
    return day;
  }

  /// Where Tab lands in the shown months: the chosen day, else today,
  /// else the first day that can be chosen, else the first day.
  DateTime _landing() {
    final anchor = _anchor;
    if (anchor != null && _visible(anchor)) return anchor;
    final today = _today;
    if (_visible(today) && _selectable(today)) return today;
    final end = DsDateUtils.addMonths(_month, widget.months);
    for (var d = _month; d.isBefore(end); d = DsDateUtils.addDays(d, 1)) {
      if (_selectable(d)) return d;
    }
    return _month;
  }

  FocusNode _node(DateTime day) =>
      _nodes[day] ??= FocusNode(debugLabel: 'DsCalendar day $day');

  /// Drops the focus nodes of days no longer shown (after the frame, once
  /// focus has moved to a shown day).
  void _pruneNodes() {
    _nodes.removeWhere((day, node) {
      if (_visible(day) || node.hasFocus) return false;
      node.dispose();
      return true;
    });
  }

  /// Turns the page so [month] is the first shown, sliding in from the
  /// side it comes from.
  void _showMonth(DateTime month) {
    final target = _clampMonth(DsDateUtils.monthOf(month));
    if (target == _month) return;
    final motion = DsTheme.motionOf(context);
    setState(() {
      _direction = target.isAfter(_month) ? 1 : -1;
      _outgoing = _month;
      _month = target;
    });
    _slide.value = 0;
    _slide
        .animateWith(
          (motion.reduced ? motion.toneSpring : motion.moveSpring).simulate(
            from: 0,
            to: 1,
            velocity: 0,
          ),
        )
        .then((_) {
          if (mounted) setState(() => _outgoing = null);
        });
    widget.onMonthChanged?.call(target);
  }

  /// The previous or next month button.
  void _turn(int delta) {
    _showMonth(DsDateUtils.addMonths(_month, delta));
    if (!_visible(_focused)) {
      final moved = _clampDay(DsDateUtils.addMonthsKeepingDay(_focused, delta));
      _focused = _visible(moved) ? moved : _landing();
    }
  }

  /// Moves the keyboard to [day], turning the page when it is not shown.
  void _moveTo(DateTime day) {
    final target = _clampDay(day);
    _focused = target;
    if (!_visible(target)) {
      final month = DsDateUtils.monthOf(target);
      _showMonth(
        month.isBefore(_month)
            ? month
            : DsDateUtils.addMonths(month, -(widget.months - 1)),
      );
    } else {
      setState(() {});
    }
    final node = _nodes[target];
    if (node != null && node.context != null) {
      node.requestFocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focused == target) _nodes[target]?.requestFocus();
      });
    }
  }

  /// Scrolls the focused day into view where the calendar scrolls (a
  /// popup on a short window): moving by keys never leaves it unseen.
  void _reveal(FocusNode? node) {
    // After the frame: the popup around may lay out again first (its
    // height is capped in a second pass), which would undo an earlier
    // scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = node?.context;
      if (!mounted || context == null || !context.mounted) return;
      if (!(node?.hasFocus ?? false)) return;
      for (final policy in const [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        unawaited(Scrollable.ensureVisible(context, alignmentPolicy: policy));
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Chooses [day]. A [touch] (a tap) ticks; keys and assistive actions
  /// are silent, as on iOS.
  void _choose(DateTime day, {bool touch = false}) {
    if (!_enabled || !_selectable(day)) return;
    _focused = day;
    if (!_visible(day)) _showMonth(DsDateUtils.monthOf(day));
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    switch (widget) {
      case DsCalendar(:final onChanged):
        onChanged!(day);
      case DsRangeCalendar(value: final range, :final onChanged):
        if (range == null || range.isComplete) {
          onChanged!(DsDateRange(start: day));
        } else if (day.isBefore(range.start)) {
          onChanged!(DsDateRange(start: day, end: range.start));
        } else {
          onChanged!(DsDateRange(start: range.start, end: day));
        }
    }
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isSpace = key == LogicalKeyboardKey.space;
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    // Space shows the press while held and chooses on release (K-39).
    if (event is KeyUpEvent) {
      if (isSpace && _pressed != null) {
        final day = _pressed!;
        setState(() => _pressed = null);
        _choose(day);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent && (isSpace || isEnter)) {
      return KeyEventResult.handled;
    }
    if (isEnter && event is KeyDownEvent) {
      _choose(_focused);
      return KeyEventResult.handled;
    }
    if (isSpace && event is KeyDownEvent) {
      if (_enabled && _selectable(_focused)) {
        setState(() => _pressed = _focused);
      }
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final locale = DsDateLocale.of(context);
    final shift = keyboard.isShiftPressed;
    final day = _focused;
    // Days since the start of the week the day is in.
    final intoWeek = (day.weekday - locale.firstDayOfWeek + 7) % 7;
    DateTime? target;
    if (key == LogicalKeyboardKey.arrowLeft && !shift) {
      target = DsDateUtils.addDays(day, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowRight && !shift) {
      target = DsDateUtils.addDays(day, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowUp && !shift) {
      target = DsDateUtils.addDays(day, -7);
    } else if (key == LogicalKeyboardKey.arrowDown && !shift) {
      target = DsDateUtils.addDays(day, 7);
    } else if (key == LogicalKeyboardKey.home && !shift) {
      target = DsDateUtils.addDays(day, -intoWeek);
    } else if (key == LogicalKeyboardKey.end && !shift) {
      target = DsDateUtils.addDays(day, 6 - intoWeek);
    } else if (key == LogicalKeyboardKey.pageUp) {
      target = DsDateUtils.addMonthsKeepingDay(day, shift ? -12 : -1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      target = DsDateUtils.addMonthsKeepingDay(day, shift ? 12 : 1);
    }
    if (target == null) return KeyEventResult.ignored;
    if (_pressed != null) _pressed = null;
    _moveTo(target);
    return KeyEventResult.handled;
  }

  /// The day the range band previews to: under the pointer, else the
  /// keyboard's, while only the range's start is chosen.
  DateTime? get _previewEnd {
    final range = _range;
    if (range == null || range.isComplete || !_enabled) {
      return null;
    }
    return _hovered ?? (_hasFocus ? _focused : null);
  }

  bool get _focusVisible =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
      DsFocusVisibility.keyboard.value;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final locale = DsDateLocale.of(context);
    final layers = [
      DsCalendar.defaultStyle(t),
      DsCalendarTheme.of(context).style,
      widget.style,
    ];
    final s = DsCalendarStyle.resolveLayers(layers, const {});
    final scaler = MediaQuery.textScalerOf(context);
    final tap = DsTheme.sizesOf(context).minTapTarget;
    // Days grow with large text (K-34) and narrow to fit the width, e.g. a
    // 320px phone or a popup.
    return LayoutBuilder(
      builder: (context, constraints) => _layout(
        context,
        locale: locale,
        layers: layers,
        style: s,
        metrics: CalendarMetrics(
          style: s,
          scaler: scaler,
          tap: tap,
          months: widget.months,
          maxWidth: constraints.maxWidth,
        ),
      ),
    );
  }

  Widget _layout(
    BuildContext context, {
    required DsDateLocale locale,
    required List<DsCalendarStyle?> layers,
    required DsCalendarStyle style,
    required CalendarMetrics metrics,
  }) {
    final t = DsTheme.of(context);
    final l10n = locale.strings;
    final s = style;
    final pitch = metrics.pitch;

    Widget months(DateTime first, {required bool live}) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: s.monthGap!,
      children: [
        for (var i = 0; i < widget.months; i++)
          _monthGrid(
            DsDateUtils.addMonths(first, i),
            locale: locale,
            layers: layers,
            style: s,
            metrics: metrics,
            live: live,
          ),
      ],
    );

    Widget grids = months(_month, live: true);
    final outgoing = _outgoing;
    if (outgoing != null) {
      final motion = t.motion;
      final dir = Directionality.of(context) == TextDirection.rtl
          ? -_direction
          : _direction;
      final travel = motion.reduced ? 0.0 : s.slideOffset!;
      grids = AnimatedBuilder(
        animation: _slide,
        child: grids,
        builder: (context, incoming) {
          final p = _slide.value;
          final fade = p.clamp(0.0, 1.0);
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ExcludeFocus(
                        child: Opacity(
                          opacity: 1 - fade,
                          child: Transform.translate(
                            offset: Offset(-dir * travel * p, 0),
                            child: OverflowBox(
                              alignment: AlignmentDirectional.topStart,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: months(outgoing, live: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset(dir * travel * (1 - p), 0),
                    child: incoming,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final weekdays = locale.weekdays;
    final weekdayRow = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final w in weekdays)
            SizedBox(
              width: pitch.width,
              child: Text(
                l10n.weekdayAbbr(w),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: s.weekdayStyle,
              ),
            ),
        ],
      ),
    );

    Widget header(int index) {
      final month = DsDateUtils.addMonths(_month, index);
      final last = index == widget.months - 1;
      final canPrev =
          _enabled &&
          (_first == null || _month.isAfter(DsDateUtils.monthOf(_first!)));
      final canNext =
          _enabled &&
          (_last == null ||
              DsDateUtils.addMonths(
                _month,
                widget.months - 1,
              ).isBefore(DsDateUtils.monthOf(_last!)));
      final buttons = [
        DsButton.icon(
          size: DsSize.sm,
          variant: DsButtonVariant.ghost,
          style: s.navButtonStyle,
          semanticLabel: l10n.previousMonth,
          onPressed: canPrev ? () => _turn(-1) : null,
          icon: const DsIcon(DsIcons.chevronLeft),
        ),
        DsButton.icon(
          size: DsSize.sm,
          variant: DsButtonVariant.ghost,
          style: s.navButtonStyle,
          semanticLabel: l10n.nextMonth,
          onPressed: canNext ? () => _turn(1) : null,
          icon: const DsIcon(DsIcons.chevronRight),
        ),
      ];
      return Padding(
        padding: s.headerPadding ?? EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  locale.monthYear.format(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: s.headerStyle,
                ),
              ),
            ),
            // Only the last month has the buttons. The others hold an
            // unseen, inert copy, so every header is exactly as tall (the
            // buttons' height follows the platform's tap target, the
            // style and the text scale) and the months line up.
            if (last)
              ...buttons
            else
              ExcludeSemantics(
                child: ExcludeFocus(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: buttons,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final width = pitch.width * 7;
    Widget column(int index) => SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: s.gap!,
        children: [header(index), weekdayRow],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pruneNodes();
    });

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: [
        ?widget.semanticLabel,
        for (var i = 0; i < widget.months; i++)
          locale.monthYear.format(DsDateUtils.addMonths(_month, i)),
      ].join(', '),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: s.gap!,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: s.monthGap!,
            children: [for (var i = 0; i < widget.months; i++) column(i)],
          ),
          Focus(
            focusNode: _gridNode,
            skipTraversal: true,
            onKeyEvent: _onKey,
            onFocusChange: (focused) => setState(() {
              _hasFocus = focused;
              if (!focused) _pressed = null;
            }),
            child: MouseRegion(
              onExit: (_) {
                if (_hovered != null) setState(() => _hovered = null);
              },
              child: grids,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthGrid(
    DateTime month, {
    required DsDateLocale locale,
    required List<DsCalendarStyle?> layers,
    required DsCalendarStyle style,
    required CalendarMetrics metrics,
    required bool live,
  }) {
    final offset = (month.weekday - locale.firstDayOfWeek + 7) % 7;
    final start = DsDateUtils.addDays(month, -offset);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var week = 0; week < 6; week++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < 7; col++)
                _cell(
                  DsDateUtils.addDays(start, week * 7 + col),
                  month: month,
                  column: col,
                  locale: locale,
                  layers: layers,
                  style: style,
                  metrics: metrics,
                  live: live,
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    DateTime day, {
    required DateTime month,
    required int column,
    required DsDateLocale locale,
    required List<DsCalendarStyle?> layers,
    required DsCalendarStyle style,
    required CalendarMetrics metrics,
    required bool live,
  }) {
    final pitch = metrics.pitch;
    final outside = !DsDateUtils.isSameMonth(day, month);
    if (outside && !widget.showOutsideDays) {
      return SizedBox.fromSize(size: pitch);
    }
    final l10n = locale.strings;
    final selectable = _selectable(day);
    final enabled = _enabled && selectable;
    final today = DsDateUtils.isSameDay(day, _today);

    // Range: ends chosen, days between banded (or previewed).
    var selected = false;
    var rangeStart = false, rangeEnd = false, between = false;
    DateTime? bandFrom, bandTo;
    final calendar = widget;
    if (calendar is DsRangeCalendar) {
      final range = calendar.value;
      if (range != null) {
        final preview = _previewEnd;
        final to = range.end ?? preview;
        if (to != null) {
          bandFrom = to.isBefore(range.start) ? to : range.start;
          bandTo = to.isBefore(range.start) ? range.start : to;
        }
        rangeStart = DsDateUtils.isSameDay(day, range.start);
        rangeEnd = DsDateUtils.isSameDay(day, range.end);
        selected = rangeStart || rangeEnd;
        between = range.end != null && range.contains(day) && !selected;
      }
    } else if (calendar is DsCalendar) {
      selected = DsDateUtils.isSameDay(day, calendar.value);
    }
    final inBand =
        !outside &&
        bandFrom != null &&
        bandTo != null &&
        bandFrom != bandTo &&
        !day.isBefore(bandFrom) &&
        !day.isAfter(bandTo);

    final node = live && !outside ? _node(day) : null;
    final states = <WidgetState>{
      if (_hovered == day && enabled) WidgetState.hovered,
      if (_pressed == day && enabled) WidgetState.pressed,
      if (node != null && node.hasPrimaryFocus && _focusVisible)
        WidgetState.focused,
      if (selected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };
    final t = DsTheme.of(context);
    final d = DsCalendarStyle.resolveLayers(layers, states);
    final corners = t.radii.controlCorners(d.dayRadius, d.daySize!);
    var foreground = d.dayForeground;
    var text = d.dayTextStyle ?? const TextStyle();
    if (today) text = text.merge(d.todayTextStyle);
    if (!selected && enabled && today) foreground = d.todayForeground;
    if (outside && !selected) foreground = d.outsideForeground;
    var border = d.dayBorderColor ?? const Color(0x00000000);
    // Today's ring goes with its color; a chosen today is only filled.
    if (!selected && enabled && today && !outside) {
      border = d.todayBorderColor ?? border;
    }
    // A band edge (when a style sets one) runs around the ends it joins.
    if (selected && inBand) {
      if (style.rangeEdgeColor case final edge? when edge.a > 0) border = edge;
    }

    Widget visual = AnimatedContainer(
      duration: t.motion.toneDuration,
      curve: t.motion.toneCurve,
      width: metrics.day,
      height: metrics.day,
      alignment: Alignment.center,
      decoration: DsBoxDecoration(
        color: d.dayBackground,
        borderRadius: corners,
        shadows: [
          if (border.a > 0) DsShadow.innerRing(border),
          if (states.contains(WidgetState.focused)) ...?d.focusShadows,
        ],
      ),
      child: Text(
        '${day.day}',
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: text.copyWith(color: foreground),
      ),
    );

    // The band behind the day: from the day's middle toward the rest of
    // the range, full width between; rounded where the range, a week or
    // the month ends.
    if (inBand) {
      final first = DsDateUtils.isSameDay(day, bandFrom);
      final last = DsDateUtils.isSameDay(day, bandTo);
      final rowStart = column == 0 || day.day == 1;
      final rowEnd =
          column == 6 ||
          day.day == DsDateUtils.daysInMonth(day.year, day.month);
      final half = metrics.day / 2;
      final mid = pitch.width / 2;
      final radius = corners.resolve(Directionality.of(context)).topLeft;
      final startInset = first ? mid : (rowStart ? mid - half : 0.0);
      final endInset = last ? mid : (rowEnd ? mid - half : 0.0);
      visual = Stack(
        alignment: Alignment.center,
        // The cell clips the edge's open sides (below).
        clipBehavior: Clip.hardEdge,
        children: [
          PositionedDirectional(
            start: startInset,
            end: endInset,
            top: (pitch.height - metrics.day) / 2,
            height: metrics.day,
            child: DecoratedBox(
              decoration: DsBoxDecoration(
                color: style.rangeColor,
                borderRadius: BorderRadiusDirectional.horizontal(
                  start: rowStart && !first ? radius : Radius.zero,
                  end: rowEnd && !last ? radius : Radius.zero,
                ),
              ),
            ),
          ),
          // The edge: an inner ring on a box that runs 2px past the cell
          // on every open side, so the cell's clip leaves only the top and
          // bottom lines there and the rounded ends close the outline.
          if (style.rangeEdgeColor case final edge? when edge.a > 0)
            PositionedDirectional(
              start: rowStart && !first ? startInset : startInset - 2,
              end: rowEnd && !last ? endInset : endInset - 2,
              top: (pitch.height - metrics.day) / 2,
              height: metrics.day,
              child: DecoratedBox(
                decoration: DsBoxDecoration(
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: rowStart && !first ? radius : Radius.zero,
                    end: rowEnd && !last ? radius : Radius.zero,
                  ),
                  shadows: [DsShadow.innerRing(edge)],
                ),
              ),
            ),
          visual,
        ],
      );
    } else {
      visual = Center(child: visual);
    }

    Widget cell = SizedBox.fromSize(size: pitch, child: visual);
    if (outside || !live) {
      // Outside days are pointer shortcuts to the next page; the shown
      // month's own days are the ones read and focused.
      return ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && live ? () => _choose(day, touch: true) : null,
          child: MouseRegion(
            cursor: d.cursor ?? MouseCursor.defer,
            child: cell,
          ),
        ),
      );
    }

    final label = [
      locale.fullDate.format(day),
      if (today) l10n.today,
      if (rangeStart) l10n.rangeStart,
      if (rangeEnd) l10n.rangeEnd,
      if (between) l10n.inRange,
    ].join(', ');
    cell = MouseRegion(
      cursor: d.cursor ?? MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = day),
      onExit: (_) {
        if (_hovered == day) setState(() => _hovered = null);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: enabled ? (_) => setState(() => _pressed = day) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = null) : null,
        onTap: enabled
            ? () {
                _pressed = null;
                _choose(day, touch: true);
              }
            : null,
        child: cell,
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      onTap: enabled ? () => _choose(day) : null,
      child: Focus(
        focusNode: node,
        skipTraversal: day != _focused,
        autofocus: widget.autofocus && day == _focused,
        onFocusChange: (focused) {
          if (focused) _reveal(node);
        },
        child: ExcludeSemantics(child: cell),
      ),
    );
  }
}
