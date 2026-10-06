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
/// or open hour and minute columns (and AM/PM on a 12-hour clock) with the
/// button at the end of the field.
///
/// ```dart
/// DsField(
///   label: const Text('Başlangıç'),
///   child: DsTimePicker(
///     value: start,
///     minuteStep: 15,
///     onChanged: (t) => setState(() => start = t),
///   ),
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
/// `2:30 pm`, `2p`. [onChanged] follows the typing once the minutes are typed;
/// on Enter or when focus leaves the text is shown in the clock's pattern
/// again, and text that is not a time keeps the error look with a null value.
/// Nothing is reported without an edit. [onInputIssueChanged] tells why the
/// text holds no time ("Enter a time such as 14:30."), and null once it does or
/// is empty again; inside a [DsField] without an error of its own the field
/// shows that message (WCAG 3.3.1).
///
/// **Columns.** The button at the end ("Choose time") or Alt+Down opens
/// the columns; each scrolls, shows its chosen item in the selection style
/// and scrolls it into view. Minutes go in [minuteStep]s (a typed minute
/// off the steps is listed too). Choosing an item changes the time at
/// once and keeps the columns open.
///
/// | Key | Action |
/// |---|---|
/// | Up / Down | Previous / next item in the column |
/// | Home / End | First / last item |
/// | Left / Right | Previous / next column (mirrored right to left) |
/// | Enter | Closes the columns, keeping the time |
/// | Escape | Closes the columns, restoring the time they opened with |
///
/// **Screen readers.** Each column is one adjustable node ("Saat, 14";
/// swipe up or down to change it), the field and the button their own.
///
/// **Field.** Inside a [DsField] the label names the field and the
/// field's error and required state apply. Null [onChanged] disables it;
/// [readOnly] keeps the time focusable and selectable but fixed, in the
/// text field's read-only look, without the clock button.
///
/// Anatomy: text field (well, time, error icon), clock button; popup panel
/// with hour, minute and AM/PM columns.
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
    this.use24HourClock,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.style,
  }) : assert(minuteStep > 0 && minuteStep <= 30);

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
        // spaced out like a console (denetim-2, decision 1).
      ),
      // The field's own buttons' look (K-80).
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
        // selection (K-69).
        focusShadows: [DsShadow.innerRing(ring, width: 2)],
        hovered: DsTimePickerStyle(itemBackground: theme.selectedHoverFill),
        pressed: DsTimePickerStyle(itemBackground: theme.selectedHoverFill),
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

  final _columns = [FocusNode(), FocusNode(), FocusNode()];

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
    final next = _locale!.timeFormat(use24HourClock: _uses24);
    if (next == _format) return;
    final first = _format == null;
    _format = next;
    if (first || issue == null) showValue(widget.value);
  }

  @override
  void didUpdateWidget(DsTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateFocusNode(oldWidget.focusNode);
    if (widget.use24HourClock != oldWidget.use24HourClock) _resolveFormat();
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

  /// While typing: the time once the minutes are typed, null while empty.
  @override
  DsTypedRead<DsTime>? readTyping(String text) {
    if (text.trim().isEmpty) return (value: null, issue: null);
    if (!_minutesTyped.hasMatch(text)) return null;
    return (value: _format!.tryParseTime(text), issue: null);
  }

  @override
  DsTypedRead<DsTime> readCommit(String text) {
    if (_format!.tryParseTime(text) case final time?) {
      return (value: time, issue: null);
    }
    return (
      value: null,
      issue: DsInputIssue(
        DsInputIssueKind.invalid,
        _locale!.strings.invalidTime(_format!.formatTime(const DsTime(14, 30))),
      ),
    );
  }

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

  /// The time the columns start from when none is chosen: now's hour.
  DsTime get _base => reported ?? DsTime(DateTime.now().hour, 0);

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
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

    final hours = _ColumnData(
      label: l10n.hours,
      items: [
        for (var h = 0; h < (uses24 ? 24 : 12); h++)
          (uses24 ? two(h) : '${h == 0 ? 12 : h}', h),
      ],
      selected: current == null
          ? null
          : (uses24 ? current.hour : current.hour % 12),
      start: uses24 ? base.hour : base.hour % 12,
      onSelect: (h) =>
          choose(base.copyWith(hour: uses24 ? h : h + (base.isPm ? 12 : 0))),
    );
    final minuteValues = {
      for (var m = 0; m < 60; m += widget.minuteStep) m,
      ?current?.minute,
    }.toList()..sort();
    final minutes = _ColumnData(
      label: l10n.minutes,
      items: [for (final m in minuteValues) (two(m), m)],
      selected: current?.minute,
      start: base.minute,
      onSelect: (m) => choose(base.copyWith(minute: m)),
    );
    final period = _ColumnData(
      label: l10n.dayPeriod,
      items: [(l10n.am, 0), (l10n.pm, 1)],
      selected: current == null ? null : (current.isPm ? 1 : 0),
      start: base.isPm ? 1 : 0,
      onSelect: (p) => choose(base.copyWith(hour: base.hour % 12 + p * 12)),
    );
    final periodFirst =
        !uses24 && l10n.timePattern12.trimLeft().startsWith('a');
    final columns = [
      if (!uses24 && periodFirst) period,
      hours,
      minutes,
      if (!uses24 && !periodFirst) period,
    ];

    void move(int from, int delta) {
      final to = from + delta;
      if (to < 0 || to >= columns.length) return;
      _columns[to].requestFocus();
    }

    // Every column is as tall as the longest needs, up to the visible
    // items; items grow with large text (K-34).
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

class _ColumnData {
  const _ColumnData({
    required this.label,
    required this.items,
    required this.selected,
    required this.start,
    required this.onSelect,
  });

  /// Names the column for screen readers.
  final String label;

  /// Shown text and value of each item.
  final List<(String, int)> items;

  /// The chosen value, or null.
  final int? selected;

  /// Where the keys start when nothing is chosen.
  final int start;

  final ValueChanged<int> onSelect;
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

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    FocusManager.instance.addHighlightModeListener(_onHighlight);
    DsFocusVisibility.keyboard.addListener(_onModality);
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
    final i = data.items.indexWhere((item) => item.$2 == value);
    if (i >= 0) return i;
    // The nearest item before the value.
    var best = 0;
    for (var j = 0; j < data.items.length; j++) {
      if (data.items[j].$2 <= value) best = j;
    }
    return best;
  }

  /// Whole rows the column shows at once.
  int get _rows =>
      math.max(1, ((_viewport + widget.style.itemGap!) / _extent).round());

  /// The offset that shows [index] in the middle row, on whole rows (no
  /// row cut by an edge).
  double _centered(int index, int count) {
    final first = (index - (_rows - 1) ~/ 2).clamp(
      0,
      math.max(0, count - _rows),
    );
    return first * _extent;
  }

  /// Scrolls so the chosen item shows, clear of the faded edge rows: by
  /// whole rows to one row inside the edge it crossed, or centered when it
  /// was out of view.
  void _reveal() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    final count = widget.data.items.length;
    final index = _index;
    final top = index * _extent;
    final offset = scroll.offset;
    final max = scroll.position.maxScrollExtent;
    final band = _fadeBand;
    final fadeTop = offset > 0 ? band : 0.0;
    final fadeBottom = offset < max ? band : 0.0;
    final shown = top >= offset && top + _extent <= offset + _viewport;
    if (shown &&
        top >= offset + fadeTop &&
        top + _extent - widget.style.itemGap! <=
            offset + _viewport - fadeBottom) {
      return;
    }
    final margin = _rows >= 3 ? 1 : 0;
    final double target;
    if (!shown) {
      target = _centered(index, count);
    } else if (top < offset + fadeTop) {
      target = (index - margin) * _extent;
    } else {
      target = (index - (_rows - 1 - margin)) * _extent;
    }
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

  void _choose(int index) {
    final items = widget.data.items;
    final i = index.clamp(0, items.length - 1);
    _select(items[i].$2);
  }

  /// Reports [value]. A [touch] (a tap) on a new value ticks; keys and
  /// assistive actions are silent, as on iOS.
  void _select(int value, {bool touch = false}) {
    if (touch && value != widget.data.selected) {
      DsHapticFeedback.play(context, DsHapticEvent.selection);
    }
    widget.data.onSelect(value);
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
    final selected = widget.data.selected != null;
    if (key == LogicalKeyboardKey.arrowUp) {
      _choose(selected ? _index - 1 : _index);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _choose(selected ? _index + 1 : _index);
    } else if (key == LogicalKeyboardKey.home) {
      _choose(0);
    } else if (key == LogicalKeyboardKey.end) {
      _choose(widget.data.items.length - 1);
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
    final t = DsTheme.of(context);
    final s = widget.style;
    final data = widget.data;
    final itemHeight = widget.itemHeight;
    final gap = s.itemGap!;
    _extent = itemHeight + gap;
    final count = data.items.length;
    _viewport = math.min(widget.maxHeight, count * _extent - gap);
    final width = math.max(
      s.columnWidth!,
      DsTheme.sizesOf(context).minTapTarget,
    );
    final index = _index;
    _scroll ??= ScrollController(initialScrollOffset: _centered(index, count));
    final focusVisible =
        widget.focusNode.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
        DsFocusVisibility.keyboard.value;

    Widget item(int i) {
      final (label, value) = data.items[i];
      final selected = data.selected == value;
      final states = <WidgetState>{
        if (_hovered == i && widget.enabled) WidgetState.hovered,
        if (_pressed == i && widget.enabled) WidgetState.pressed,
        if (selected) WidgetState.selected,
        if (focusVisible && i == index) WidgetState.focused,
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
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = i)
              : null,
          onTapCancel: () => setState(() => _pressed = null),
          onTap: widget.enabled
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

    final i = index;
    final value = data.selected == null ? null : data.items[i].$1;
    return Semantics(
      container: true,
      label: data.label,
      value: value,
      // Next and previous values only beside a value (a column with
      // nothing chosen still takes the actions).
      increasedValue: value != null && i + 1 < count
          ? data.items[i + 1].$1
          : null,
      decreasedValue: value != null && i > 0 ? data.items[i - 1].$1 : null,
      onIncrease: widget.enabled && i + 1 < count ? () => _choose(i + 1) : null,
      onDecrease: widget.enabled && i > 0 ? () => _choose(i - 1) : null,
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
                enabled: count * _extent - gap > _viewport + 0.5,
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  itemCount: count,
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
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.scroll,
    required this.band,
    required this.enabled,
    required this.child,
  });

  final ScrollController scroll;
  final double band;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ListenableBuilder(
      listenable: scroll,
      child: child,
      builder: (context, child) {
        final position = scroll.hasClients ? scroll.position : null;
        final more = position != null && position.hasContentDimensions;
        final top = more && position.pixels > position.minScrollExtent;
        final bottom = !more || position.pixels < position.maxScrollExtent;
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
    );
  }
}

// Mask colors: only alpha counts.
const _opaque = Color(0xFF000000); // ds-raw: a mask, only alpha counts
const _clear = Color(0x00000000);
