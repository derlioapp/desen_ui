import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/haptic_feedback.dart';
import '../../behavior/focus_visibility.dart';
import '../../behavior/min_tap_target.dart';
import '../../behavior/pressable.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../field/field.dart';
import 'error_edge.dart';
import 'first_line.dart';
import 'radio_circle.dart';
import 'radio_group_scope.dart';
import 'selection_text.dart';
import 'radio_style.dart';

/// Holds the selected value for the [DsRadio]s and [DsRadioCard]s below
/// it.
///
/// Keyboard (WAI-ARIA radio group): the group is one Tab stop, on the
/// selected option (or the first one when none is selected). Down and Up
/// select the next and previous enabled option in reading order, wrapping
/// around; Right and Left do too and mirror in RTL (Right goes toward the
/// end of the line). Home and End select the first and last enabled
/// option; Space selects the focused one.
class DsRadioGroup<T> extends StatefulWidget {
  /// Creates a group.
  const DsRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.error = false,
    required this.child,
  });

  /// The selected value, or null for none.
  final T? value;

  /// Called with the newly selected value. Null disables every radio.
  final ValueChanged<T?>? onChanged;

  /// Marks every radio in the group invalid, e.g. a required choice left
  /// empty; see [DsRadio.error]. Show the message itself next to the
  /// group (a [DsField] with `group: true` does both).
  final bool error;

  /// The subtree containing the radios.
  final Widget child;

  @override
  State<DsRadioGroup<T>> createState() => _DsRadioGroupState<T>();
}

class _DsRadioGroupState<T> extends State<DsRadioGroup<T>> {
  /// The radios and radio cards below, which add themselves.
  final _members = <RadioGroupMember>{};

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final int? step = switch (key) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      _ => null,
    };
    final home = key == LogicalKeyboardKey.home;
    final end = key == LogicalKeyboardKey.end;
    if (step == null && !home && !end) return KeyEventResult.ignored;
    // Only while one of the group's options has focus, so the keys still
    // reach anything else inside the group.
    final focused = _members
        .where((m) => m.focusNode().hasPrimaryFocus)
        .firstOrNull;
    if (focused == null || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    // Reading order (top to bottom, and along each line in the text
    // direction) of the options that can take part: the enabled ones and
    // the focused one, which a step starts from.
    final byNode = {
      for (final m in _members)
        if (m.enabled() || m == focused) m.focusNode(): m,
    };
    final order = [
      for (final n in ReadingOrderTraversalPolicy.sort(byNode.keys)) byNode[n]!,
    ];
    final RadioGroupMember? next;
    if (home) {
      next = order.where((m) => m.enabled()).firstOrNull;
    } else if (end) {
      next = order.where((m) => m.enabled()).lastOrNull;
    } else {
      // The nearest enabled option in that direction, wrapping around.
      final n = order.length;
      final at = order.indexOf(focused);
      next = [for (var i = 1; i < n; i++) order[((at + step! * i) % n + n) % n]]
          .where((m) => m.enabled())
          .firstOrNull;
    }
    if (next == null || next == focused) return KeyEventResult.handled;
    widget.onChanged!(next.value() as T?);
    next.focusNode().requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final onChanged = widget.onChanged;
    final error = widget.error;
    Widget group = Actions(
      // RadioGroup's arrow-key shortcuts invoke VoidCallbackIntent, which
      // WidgetsApp normally handles; provide it so arrows work under any root.
      actions: <Type, Action<Intent>>{VoidCallbackIntent: VoidCallbackAction()},
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (v) {
          final report = onChanged;
          if (report == null) return;
          // A tap on a new option ticks; arrow keys move the choice
          // silently, as on iOS.
          if (v != value && !DsFocusVisibility.keyboard.value) {
            DsHapticFeedback.play(context, DsHapticEvent.selection);
          }
          report(v);
        },
        child: RadioGroupScope(
          enabled: onChanged != null,
          error: error,
          members: _members,
          // Below RadioGroup's own arrow shortcuts, so these keys win:
          // they mirror in RTL and add Home and End.
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: widget.child,
          ),
        ),
      ),
    );
    // RawRadio reads WidgetsLocalizations on iOS and macOS. Without an app
    // root there are none; supply the defaults, keeping the ambient text
    // direction (Localizations would otherwise force its own).
    if (Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations) ==
        null) {
      group = Localizations(
        locale: const Locale('en', 'US'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: Directionality.of(context),
          child: group,
        ),
      );
    }
    return group;
  }
}

/// One option in a [DsRadioGroup]; the whole row selects it.
///
/// The circle sits on the first line of the label; a [description] goes
/// under the label in the secondary text color, and screen readers read it
/// with the label.
///
/// ```dart
/// DsRadio<String>(
///   value: 'express',
///   label: const Text('Express · ₺120'),
///   description: const Text('Next business day'),
/// )
/// ```
class DsRadio<T> extends StatefulWidget {
  /// Creates a radio for [value].
  const DsRadio({
    super.key,
    required this.value,
    this.label,
    this.description,
    this.enabled = true,
    this.error = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The value this radio stands for.
  final T value;

  /// Text after the circle, usually a [Text].
  final Widget? label;

  /// Secondary text under the label (13, muted), e.g. a delivery time.
  /// Tapping it selects too.
  final Widget? description;

  /// Whether this option can be selected. The whole group is disabled by
  /// a null [DsRadioGroup.onChanged]; this turns off one option, as
  /// [DsSegment.enabled] and [DsSelectOption.enabled] do.
  final bool enabled;

  /// Marks the radio invalid: a 2px error outline (a danger fill when
  /// selected), and screen readers hear it as invalid. A
  /// [DsRadioGroup.error] or a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsRadioStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Label for screen readers when there is no [label], or to replace it.
  final String? semanticLabel;

  /// Desen's default radio style under [theme].
  static DsRadioStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    return DsRadioStyle(
      size: 18,
      background: k.field,
      borderColor: k.borderField,
      borderWidth: 1,
      dotColor: k.onAccent,
      dotSize: 7,
      focusShadows: theme.focusShadows,
      labelStyle: theme.typography.body
          .copyWith(height: 1.3)
          .copyWith(color: k.text),
      descriptionStyle: theme.typography.label
          .copyWith(fontWeight: FontWeight.w400)
          .copyWith(color: k.textMuted),
      textGap: 2,
      gap: DsSpace.s12,
      hovered: DsRadioStyle(
        background: k.controlHover,
        borderColor: k.textSubtle,
      ),
      // A bright accent melts into the card; its edge keeps the circle
      // (transparent for other seeds; denetim-2).
      selected: DsRadioStyle(
        background: k.accent,
        borderColor: k.accentEdge,
        borderWidth: 1,
        hovered: DsRadioStyle(background: k.accentHover),
      ),
      error: DsRadioStyle(
        borderColor: dsErrorEdge(theme),
        borderWidth: 2,
        selected: DsRadioStyle(
          background: k.danger.fill,
          borderColor: clear,
          dotColor: k.danger.onFill,
          hovered: DsRadioStyle(background: k.danger.fillHover),
        ),
      ),
      disabled: DsRadioStyle(
        background: k.disabled,
        borderColor: k.border,
        borderWidth: 1,
        dotColor: k.onDisabled,
        labelStyle: TextStyle(color: k.onDisabled),
        descriptionStyle: TextStyle(color: k.onDisabled),
        selected: const DsRadioStyle(borderColor: clear),
      ),
    );
  }

  @override
  State<DsRadio<T>> createState() => _DsRadioState<T>();
}

class _DsRadioState<T> extends State<DsRadio<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  Set<WidgetState>? _lastStates;

  /// Whether the radio can be selected; set in [build].
  bool _enabled = false;
  late final _membership = RadioGroupMembership(
    RadioGroupMember(
      value: () => widget.value,
      focusNode: () => _node,
      enabled: () => _enabled,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _membership.update(context);
  }

  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app (eng L6).
  void _onModality() {
    if (_node.hasFocus) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _membership.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final group = RadioGroupScope.maybeOf(context);
    // A surrounding DsField or group with an error marks the control too
    // (K-71).
    final error =
        widget.error ||
        (group?.error ?? false) ||
        (DsFieldScope.maybeOf(context)?.hasError ?? false);
    final layers = [
      DsRadio.defaultStyle(t),
      DsRadioTheme.of(context).style,
      widget.style,
    ];
    final enabled = widget.enabled && (group?.enabled ?? true);
    final registry = RadioGroup.maybeOf<T>(context);
    _enabled = enabled && registry != null;
    final radio = RawRadio<T>(
      value: widget.value,
      groupRegistry: registry,
      enabled: enabled && registry != null,
      toggleable: false,
      focusNode: _node,
      autofocus: widget.autofocus,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsRadioStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, toggle) {
        final states = <WidgetState>{
          // Focus shows only to keyboard users (DsFocusVisibility).
          for (final s in toggle.states)
            if (s != WidgetState.focused || DsFocusVisibility.keyboard.value) s,
          if (toggle.downPosition != null) WidgetState.pressed,
          if (error) WidgetState.error,
          if (toggle.value ?? false) WidgetState.selected,
        };
        final s = DsRadioStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final size = s.size!;
        final circle = RadioCircle(
          style: s,
          selected: toggle.value ?? false,
          focused: states.contains(WidgetState.focused),
          animate: animate,
        );
        if (widget.label == null && widget.description == null) {
          return circle;
        }
        // A semantic label replaces the visible one, not adds to it.
        return ExcludeSemantics(
          excluding: widget.semanticLabel != null,
          // The circle sits on the label's first line (web alignment).
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              FirstLineControl(
                height: size,
                lineStyle: widget.label != null
                    ? s.labelStyle
                    : s.descriptionStyle,
                child: circle,
              ),
              SizedBox(width: s.gap ?? DsSpace.s12),
              Flexible(
                child: SelectionText(
                  label: widget.label,
                  description: widget.description,
                  labelStyle: s.labelStyle,
                  descriptionStyle: s.descriptionStyle,
                  gap: s.textGap!,
                ),
              ),
            ],
          ),
        );
      },
    );
    return Semantics(
      label: widget.semanticLabel,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: DsMinTapTarget(size: t.sizes.minTapTarget, child: radio),
    );
  }
}
