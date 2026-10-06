import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../behavior/spring_value.dart';
import '../../behavior/tap_band.dart';
import '../../foundation/case.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/anchored_overlay.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../autocomplete/layout.dart';
import '../button/button.dart';
import '../field/field.dart';
import '../field/field_well.dart';
import '../menu/menu.dart';
import '../menu/menu_item_style.dart';
import '../selection/error_edge.dart';
import '../text_field/text_field.dart';
import 'select_style.dart';

/// One choice of a [DsSelect].
@immutable
class DsSelectOption<T> {
  /// Creates an option.
  const DsSelectOption({
    required this.value,
    required this.label,
    this.leading,
    this.detail,
    this.enabled = true,
  });

  /// The value [DsSelect.onChanged] reports.
  final T value;

  /// The text shown in the menu and, once chosen, in the trigger.
  final String label;

  /// An icon before the label.
  final Widget? leading;

  /// A short muted note on the end side ("salt okunur").
  final String? detail;

  /// Whether the option can be chosen.
  final bool enabled;
}

/// A select: a field-like trigger and a menu of options.
///
/// Keyboard: the trigger is one Tab stop. Closed, arrow keys, Enter and
/// Space open it, and typing a letter picks the next option starting with
/// it without opening (like a native select). Open, it is a [DsMenu]: the
/// current option has focus, arrow keys, Home, End and letters move, Enter
/// chooses, Escape closes; focus returns to the trigger. Tab chooses the
/// focused option, closes and moves on (WAI-ARIA select-only combobox).
///
/// Screen readers hear [semanticLabel] as the name, the chosen option as
/// the value, whether the menu is open, and an invalid state with
/// [error]. The options are radio items of the menu. The error look is not
/// color alone: an error icon joins the border.
///
/// **Clearing.** With [clearable], a clear button shows before the chevron
/// while there is a value, and Delete or Backspace on the focused trigger
/// clears it; screen readers get a "Clear" action. Either reports null to
/// [onChanged]. The button is not a Tab stop.
///
/// **Disabled and read-only.** A null [onChanged] disables the select.
/// With [readOnly] it stays a Tab stop and shows its value at full
/// contrast, in the text field's read-only look: no fill, a faint hairline
/// edge and no chevron. It does not open, pick by letter or clear; Ctrl+C
/// (⌘C) copies the chosen label, as it does on any focused select.
///
/// **Focus.** Keyboard focus turns the edge 2px in the focus color, as a
/// text field's, with no ring around it.
///
/// In a bounded width the trigger fills it, like a field; in an unbounded
/// one (a toolbar [Row]) it is as wide as its longest option.
///
/// ```dart
/// DsSelect<String>(
///   value: project,
///   onChanged: (v) => setState(() => project = v),
///   semanticLabel: 'Proje',
///   options: const [
///     DsSelectOption(value: 'web', label: 'Derlio Web'),
///     DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
///     DsSelectOption(value: 'archive', label: 'Arşiv', detail: 'salt okunur', enabled: false),
///   ],
/// )
/// ```
class DsSelect<T> extends StatefulWidget {
  /// Creates a select.
  const DsSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.placeholder,
    this.leading,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.clearable = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The chosen value, or null for none.
  final T? value;

  /// Called with the chosen value, or null when it is cleared
  /// ([clearable]). Null disables the select.
  final ValueChanged<T?>? onChanged;

  /// The choices, top to bottom. [DsMenuDivider]s are not supported here;
  /// order the options instead.
  final List<DsSelectOption<T>> options;

  /// Shown while nothing is chosen. Defaults to the localized "Select".
  /// Screen readers hear it as the name only when nothing else names the
  /// select (no [semanticLabel], no [DsField] label).
  final String? placeholder;

  /// An icon before the value, e.g. what the select chooses.
  final Widget? leading;

  /// What the select chooses, for screen readers ("Proje").
  final String? semanticLabel;

  /// Shows the error look (from a form's validation): the error border,
  /// an error icon, and an invalid state for screen readers. Inside a
  /// [DsField] with an error it is on without this.
  final bool error;

  /// Whether the value is fixed: the select shows it and can be focused,
  /// but does not open, change or clear.
  final bool readOnly;

  /// Adds a clear button while there is a value; Delete and Backspace
  /// clear too. Clearing reports null to [onChanged].
  final bool clearable;

  /// Style laid over the theme and defaults.
  final DsSelectStyle? style;

  /// Focus node of the trigger; one is created when null.
  final FocusNode? focusNode;

  /// Whether the trigger takes focus when first built.
  final bool autofocus;

  /// Desen's default select style under [theme].
  static DsSelectStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsSelectStyle(
      height: theme.sizes.md,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s12),
      background: k.field,
      borderColor: k.borderField,
      borderWidth: 1,
      // No radius: the corners follow the resolved height.
      foreground: k.text,
      placeholderColor: k.textSubtle,
      iconColor: k.textMuted,
      iconSize: 16,
      textStyle: theme.typography.body.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      gap: DsSpace.s12,
      // The text field's clear button, so the two read alike.
      clearStyle: DsTextField.defaultStyle(theme).clearStyle,
      // Focus is one line, the edge, as on the text field: no ring.
      focusShadows: const [],
      focused: DsSelectStyle(borderColor: k.focus, borderWidth: 2),
      hovered: DsSelectStyle(background: k.controlHover),
      // Thicker, so the error is not told by hue alone (K-67), as on the
      // text field. Focused, the edge shows focus; the icon keeps the
      // error.
      error: DsSelectStyle(
        borderColor: dsErrorEdge(theme),
        borderWidth: 2,
        errorIconColor: dsErrorEdge(theme),
        focused: DsSelectStyle(borderColor: k.focus),
      ),
      // The text field's read-only look: a value on the page, not a well.
      readOnly: DsSelectStyle(
        background: const Color(0x00000000),
        borderColor: k.border,
        borderWidth: 1,
        focused: DsSelectStyle(borderColor: k.focus, borderWidth: 2),
      ),
      // Disabled keeps the field's shape: a faint edge on the disabled
      // fill (K-66), as the text field.
      disabled: DsSelectStyle(
        background: k.disabled,
        borderColor: k.border,
        borderWidth: 1,
        foreground: k.onDisabled,
        placeholderColor: k.onDisabled,
        iconColor: k.onDisabled,
      ),
    );
  }

  @override
  State<DsSelect<T>> createState() => _DsSelectState<T>();
}

class _DsSelectState<T> extends State<DsSelect<T>> {
  final _menu = DsOverlayController();
  Set<WidgetState>? _lastStates;

  /// The clear button is not a Tab stop and never takes focus.
  final _clearFocus = FocusNode(
    debugLabel: 'DsSelect clear',
    skipTraversal: true,
    canRequestFocus: false,
  );

  /// The trigger's node when [DsSelect.focusNode] is null; kept until
  /// dispose, as the trigger may still hold it while a new one comes in.
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenu);
  }

  @override
  void dispose() {
    _menu.removeListener(_onMenu);
    _menu.dispose();
    _clearFocus.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DsSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabled (or read-only) while open: the menu goes too (bugs B32).
    if (!_canEdit && _menu.isOpen) _menu.close();
  }

  void _onMenu() => setState(() {});

  bool get _enabled => widget.onChanged != null;

  /// Enabled and not read-only: the value can change.
  bool get _canEdit => _enabled && !widget.readOnly;

  bool get _canClear => widget.clearable && _canEdit && _selected != null;

  DsSelectOption<T>? get _selected {
    for (final o in widget.options) {
      if (o.value == widget.value) return o;
    }
    return null;
  }

  void _choose(DsSelectOption<T> option) {
    if (option.value != widget.value) widget.onChanged?.call(option.value);
  }

  void _clear() {
    if (!_canClear) return;
    widget.onChanged?.call(null);
    if (!_node.hasFocus) _node.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || _menu.isOpen) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    // Copy: the chosen label, as the text of a field.
    if (command && key == LogicalKeyboardKey.keyC) {
      final label = _selected?.label;
      if (label == null) return KeyEventResult.ignored;
      Clipboard.setData(ClipboardData(text: label));
      return KeyEventResult.handled;
    }
    if (!_canEdit) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      _menu.open();
      return KeyEventResult.handled;
    }
    // Shortcuts are the app's; a letter with Ctrl or ⌘ does not pick.
    if (command || keyboard.isAltPressed) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      if (!_canClear) return KeyEventResult.ignored;
      _clear();
      return KeyEventResult.handled;
    }
    // Type-ahead while closed: pick the next option starting with the
    // letter, as a native select does.
    if (event.character case final c? when c.trim().isNotEmpty) {
      final options = widget.options;
      // With nothing chosen the search starts before the first option, so
      // the first one can match (bugs B17).
      final current = options.indexWhere((o) => o.value == widget.value);
      final wanted = dsFoldCase(c);
      for (var step = 1; step <= options.length; step++) {
        final o = options[(current + step) % options.length];
        if (o.enabled && dsFoldCase(o.label).startsWith(wanted)) {
          _choose(o);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  /// Tab in the open menu chooses the focused option before the layer
  /// closes and focus moves on.
  KeyEventResult _onMenuKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed) {
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<DsMenuItem>()
          ?.onPressed
          ?.call();
    }
    return KeyEventResult.ignored;
  }

  /// The last [_widestLabel], and what it was measured for.
  (List<DsSelectOption<T>>, Object, double)? _widest;

  /// The widest of the placeholder and the option labels, for an
  /// unbounded width. Measured once per options and text style, not on
  /// each hover or focus change. Of a long list only the
  /// [_measuredLabels] longest labels (by characters) are measured.
  double _widestLabel(BuildContext context, TextStyle style, String extra) {
    final options = widget.options;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final key = (style, extra, direction, scaler);
    if (_widest case (final seen, final seenKey, final width)
        when seenKey == key && _sameLabels(seen, options)) {
      _widest = (options, key, width);
      return width;
    }
    var labels = [for (final o in options) o.label];
    if (labels.length > _measuredLabels) {
      labels.sort((a, b) => b.length.compareTo(a.length));
      labels = labels.sublist(0, _measuredLabels);
    }
    final painter = TextPainter(
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    );
    var widest = 0.0;
    for (final label in [extra, ...labels]) {
      painter
        ..text = TextSpan(text: label, style: style)
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    final width = widest.ceilToDouble();
    _widest = (options, key, width);
    return width;
  }

  static bool _sameLabels(
    List<DsSelectOption<Object?>> a,
    List<DsSelectOption<Object?>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final l10n = DsLocalizations.of(context);
    final layers = [
      DsSelect.defaultStyle(t),
      DsSelectTheme.of(context).style,
      widget.style,
    ];
    final selected = _selected;
    final placeholder = widget.placeholder ?? l10n.selectPlaceholder;
    final field = DsFieldScope.maybeOf(context);
    final error = widget.error || (field?.hasError ?? false);
    // A field's label names the select; the placeholder is then only
    // what it shows.
    final labelled = field?.isLabelled ?? false;
    // Shared by every option row, so a long list does not look it up once
    // per option. Secondary ink, so it stays 4.5:1 on the highlighted row.
    final detailStyle = t.typography.caption.copyWith(
      color: t.colors.textMuted,
    );
    // On touch the tap area reaches the 44px target around the box without
    // growing the layout, as a text field keeps its own height: a select
    // and a text field in one row line up. The band sits outermost, so its
    // parent (a DsField's column) asks it directly.
    return TapBand(
      size: DsTheme.sizesOf(context).minTapTarget,
      child: DsAnchoredOverlay(
        controller: _menu,
        matchAnchorWidth: true,
        gap: DsSpace.s4,
        tab: DsOverlayTab.close,
        overlayBuilder: (context) => Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onMenuKey,
          child: DsMenu(
            autofocus: true,
            onDone: _menu.close,
            semanticLabel: widget.semanticLabel,
            children: [
              // Nothing to choose: say so instead of an empty box (ux L4).
              if (widget.options.isEmpty)
                _NoOptions(text: l10n.selectNoResults),
              // Options without an icon line up with those that have one
              // (visual L5): the menu keeps the icon column for all. The
              // chosen one takes the menu's check before its label.
              for (final o in widget.options)
                DsMenuItem(
                  label: Text(o.label),
                  leading: o.leading,
                  // One value of a set: radio items.
                  checked: o.value == widget.value,
                  checkRole: DsMenuCheckRole.radio,
                  autofocus: o.value == widget.value,
                  onPressed: o.enabled ? () => _choose(o) : null,
                  trailing: o.detail == null
                      ? null
                      : Text(o.detail!, style: detailStyle),
                ),
            ],
          ),
        ),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: DsPressable(
            focusNode: _node,
            autofocus: widget.autofocus,
            minTapTarget: 0,
            // Read-only stays enabled, so it keeps its look and its Tab stop;
            // a press does nothing.
            onPressed: _canEdit
                ? _menu.toggle
                : _enabled
                ? _ignorePress
                : null,
            expanded: widget.readOnly ? null : _menu.isOpen,
            mouseCursor: widget.readOnly
                ? SystemMouseCursors.basic
                : WidgetStateMouseCursor.resolveWith(
                    (states) =>
                        DsSelectStyle.resolveLayers(layers, states).cursor ??
                        DsPressable.defaultCursor.resolve(states),
                  ),
            builder: (context, interaction, _) {
              final states = {
                // Read-only: no hover or press look, only focus.
                for (final s in interaction)
                  if (!widget.readOnly || s == WidgetState.focused) s,
                if (error) WidgetState.error,
              };
              final s = DsSelectStyle.resolveLayers(
                layers,
                states,
                readOnly: widget.readOnly && _enabled,
              );
              final animate =
                  _lastStates != null && !setEquals(_lastStates, states);
              _lastStates = states;
              final border = s.borderColor ?? const Color(0x00000000);
              final textStyle = (s.textStyle ?? const TextStyle()).copyWith(
                color: selected == null ? s.placeholderColor : s.foreground,
              );
              final label = Text(
                selected?.label ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              );
              // The name, the chosen value and the validation state of a form
              // field (ux V8, V9); the visuals below are not read.
              final visual = FieldWell(
                duration: animate ? t.motion.toneDuration : Duration.zero,
                curve: t.motion.toneCurve,
                minHeight: s.height!,
                padding: s.padding,
                background: s.background,
                borderColor: border,
                borderWidth: s.borderWidth!,
                borderRadius: t.radii.controlCorners(s.borderRadius, s.height!),
                focusShadows: s.focusShadows,
                focused: states.contains(WidgetState.focused),
                child: IconTheme.merge(
                  data: IconThemeData(color: s.iconColor, size: s.iconSize),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Row(
                      mainAxisSize: constraints.hasBoundedWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      spacing: s.gap ?? DsSpace.s12,
                      children: [
                        ?(selected?.leading ?? widget.leading),
                        if (constraints.hasBoundedWidth)
                          Expanded(child: label)
                        else
                          SizedBox(
                            width: _widestLabel(
                              context,
                              DefaultTextStyle.of(context).style
                                  .merge(textStyle),
                              placeholder,
                            ),
                            child: label,
                          ),
                        // The clear button's place is kept while there is no
                        // value, so choosing one does not move the chevron.
                        if (widget.clearable && _canEdit)
                          ActionTapArea(
                            visual: s.clearStyle!.height!,
                            child: selected == null
                                ? null
                                : DsButton.icon(
                                    size: DsSize.xs,
                                    focusNode: _clearFocus,
                                    style: s.clearStyle,
                                    semanticLabel: l10n.clear,
                                    onPressed: _clear,
                                    icon: const DsIcon(DsIcons.x),
                                  ),
                          ),
                        if (error)
                          DsIcon(
                            DsIcons.circleAlert,
                            size: s.iconSize!,
                            // Error border color; the cue is not color alone.
                            color:
                                s.errorIconColor ??
                                (border.a > 0 ? border : s.iconColor),
                          ),
                        // The chevron turns over while the menu is open. A
                        // read-only select does not open, so it has none.
                        if (!(widget.readOnly && _enabled))
                          DsSpringValue(
                            value: _menu.isOpen ? 1 : 0,
                            spring: t.motion.moveSpringOrNull,
                            builder: (context, v, child) => Transform.rotate(
                              angle: v * math.pi,
                              child: child,
                            ),
                            child: DsIcon(
                              DsIcons.chevronDown,
                              size: s.iconSize!,
                              color: s.iconColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              return Semantics(
                label:
                    widget.semanticLabel ??
                    (selected == null && !labelled ? placeholder : null),
                value: selected?.label,
                readOnly: widget.readOnly,
                customSemanticsActions: _canClear
                    ? {CustomSemanticsAction(label: l10n.clear): _clear}
                    : null,
                validationResult: error
                    ? SemanticsValidationResult.invalid
                    : SemanticsValidationResult.none,
                child: ExcludeSemantics(child: visual),
              );
            },
          ),
        ),
      ),
    );
  }
}

void _ignorePress() {}

/// How many labels a select measures for its width in an unbounded row:
/// the longest by characters.
const _measuredLabels = 200;

/// The row of an open select with no options.
class _NoOptions extends StatelessWidget {
  const _NoOptions({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final s = DsMenuItem.defaultStyle(t)
        .merge(DsMenuItemTheme.of(context).style);
    return Container(
      constraints: BoxConstraints(minHeight: s.height!),
      padding: s.padding,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: (s.textStyle ?? const TextStyle()).copyWith(
          color: t.colors.textSubtle,
        ),
      ),
    );
  }
}
