import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/spring_value.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'checkbox_style.dart';
import 'first_line.dart';
import 'selection_text.dart';
import '../field/field.dart';
import 'error_edge.dart';

/// A checkbox with an optional label and description; the whole row
/// toggles.
///
/// ```dart
/// DsCheckbox(
///   value: weekly,
///   onChanged: (v) => setState(() => weekly = v!),
///   label: const Text('Haftalık özet e-postası'),
///   description: const Text('Her pazartesi sabahı'),
/// )
/// ```
///
/// The box sits on the first line of the label; a [description] goes
/// under the label in the secondary text color, and screen readers read
/// it with the label.
///
/// With [tristate], a null [value] shows a dash (mixed) and a tap cycles
/// false → true → null. A null [onChanged] disables it. Space or Enter
/// toggles from the keyboard.
class DsCheckbox extends StatefulWidget {
  /// Creates a checkbox.
  const DsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.tristate = false,
    this.error = false,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(
         tristate || value != null,
         'value can only be null when tristate',
       );

  /// Checked, unchecked, or null (mixed) when [tristate].
  final bool? value;

  /// Called with the next value. Null disables the checkbox.
  final ValueChanged<bool?>? onChanged;

  /// Text after the box, usually a [Text]. Tapping it toggles too.
  final Widget? label;

  /// Secondary text under the label (13, muted), e.g. what the option
  /// means. Tapping it toggles too.
  final Widget? description;

  /// Allows the mixed (null) value.
  final bool tristate;

  /// Marks the box invalid, e.g. a required box left unchecked: a 2px
  /// error outline (a danger fill when checked), and screen readers hear
  /// it as invalid. Show the message itself next to the control.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsCheckboxStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Label for screen readers when there is no [label].
  final String? semanticLabel;

  /// Desen's default checkbox style under [theme].
  static DsCheckboxStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    const size = 18.0;
    return DsCheckboxStyle(
      size: size,
      background: k.field,
      borderColor: k.borderField,
      borderWidth: 1,
      borderRadius: BorderRadius.circular(theme.radii.checkbox(size)),
      markColor: k.onAccent,
      markSize: 14,
      shadows: const [],
      focusShadows: theme.focusShadows,
      labelStyle: theme.typography.body
          .copyWith(height: 1.3)
          .copyWith(color: k.text),
      descriptionStyle: theme.typography.label
          .copyWith(fontWeight: FontWeight.w400)
          .copyWith(color: k.textMuted),
      textGap: 2,
      gap: DsSpace.s12,
      hovered: DsCheckboxStyle(
        background: k.controlHover,
        borderColor: k.textSubtle,
      ),
      // A fill under 3:1 off its layer (a bright accent on a light card,
      // a white-labeled fill on a dark floating layer) keeps the box's
      // shape with its edge; transparent when the fill stands alone.
      selected: DsCheckboxStyle(
        background: k.accent,
        borderColor: k.accentEdge,
        borderWidth: 1,
        hovered: DsCheckboxStyle(background: k.accentHover),
      ),
      // A thicker edge, so the error is not told by hue alone; a checked
      // box turns danger instead of wearing a red line on blue (visual M6).
      error: DsCheckboxStyle(
        borderColor: dsErrorEdge(theme),
        borderWidth: 2,
        selected: DsCheckboxStyle(
          background: k.danger.fill,
          borderColor: clear,
          markColor: k.danger.onFill,
          hovered: DsCheckboxStyle(background: k.danger.fillHover),
        ),
      ),
      // Disabled keeps the shape: an unchecked box keeps an edge, a checked
      // one its fill (visual M7).
      disabled: DsCheckboxStyle(
        background: k.disabled,
        borderColor: k.border,
        borderWidth: 1,
        markColor: k.onDisabled,
        labelStyle: TextStyle(color: k.onDisabled),
        descriptionStyle: TextStyle(color: k.onDisabled),
        selected: const DsCheckboxStyle(borderColor: clear),
      ),
    );
  }

  @override
  State<DsCheckbox> createState() => _DsCheckboxState();
}

class _DsCheckboxState extends State<DsCheckbox> {
  Set<WidgetState>? _lastStates;

  void _toggle() {
    final next = switch (widget.value) {
      false => true,
      true => widget.tristate ? null : false,
      null => false,
    };
    widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    // A surrounding DsField with an error marks the control too (K-71).
    final error =
        widget.error || (DsFieldScope.maybeOf(context)?.hasError ?? false);
    final layers = [
      DsCheckbox.defaultStyle(t),
      DsCheckboxTheme.of(context).style,
      widget.style,
    ];
    final checked = widget.value ?? true;
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onChanged == null ? null : _toggle,
      haptic: DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      isButton: false,
      checked: widget.value == true,
      mixed: widget.tristate && widget.value == null,
      semanticLabel: widget.semanticLabel,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsCheckboxStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (checked) WidgetState.selected,
          if (error) WidgetState.error,
        };
        final s = DsCheckboxStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final duration = animate ? t.motion.toneDuration : Duration.zero;
        final size = s.size!;
        final border = s.borderColor ?? const Color(0x00000000);

        final box = AnimatedContainer(
          duration: duration,
          curve: t.motion.toneCurve,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: [
              if (border.a > 0)
                DsShadow.innerRing(border, width: s.borderWidth!),
              ...?s.shadows,
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          // Only the mark springs; the box stays put.
          child: DsSpringValue(
            // ds-raw: the mark springs in from 40% (motion, not a size)
            value: checked ? 1 : 0.4,
            spring: t.motion.moveSpringOrNull,
            builder: (context, v, child) =>
                Transform.scale(scale: v < 0 ? 0 : v, child: child),
            child: AnimatedOpacity(
              opacity: checked ? 1 : 0,
              duration: t.motion.toneDuration,
              curve: t.motion.toneCurve,
              child: DsIcon(
                widget.value == null ? DsIcons.minus : DsIcons.check,
                size: s.markSize!,
                color: s.markColor,
              ),
            ),
          ),
        );
        if (widget.label == null && widget.description == null) return box;
        // The box sits on the label's first line (web alignment).
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            FirstLineControl(
              height: size,
              lineStyle: widget.label != null
                  ? s.labelStyle
                  : s.descriptionStyle,
              child: box,
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
        );
      },
    );
  }
}
