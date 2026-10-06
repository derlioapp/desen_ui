import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/spring_value.dart';
import '../../foundation/color_utils.dart';
import '../../behavior/pressable.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/palette.dart' show DsContrast;
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../field/field.dart';
import 'error_edge.dart';
import 'first_line.dart';
import 'selection_text.dart';
import 'switch_style.dart';

/// An on/off switch, optionally in a settings row with a title and
/// description; the whole row toggles.
///
/// ```dart
/// DsSwitch(
///   value: push,
///   onChanged: (v) => setState(() => push = v),
///   label: const Text('Anlık bildirimler'),
///   description: const Text('Mobil ve masaüstü'),
/// )
/// ```
///
/// At the standard contrast level the off track meets 3:1 against
/// surfaces. Space or Enter toggles.
class DsSwitch extends StatefulWidget {
  /// Creates a switch.
  const DsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.error = false,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// On or off.
  final bool value;

  /// Called with the new value. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Row title (14 / 600). The switch sits at the row's end.
  final Widget? label;

  /// Secondary text under the title (13, muted).
  final Widget? description;

  /// Marks the switch invalid, e.g. a required consent left off: a 2px
  /// error outline on the track (a danger track when on), and screen
  /// readers hear it as invalid. A surrounding [DsField] with an error
  /// sets it too. Show the message itself next to the control.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsSwitchStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Label for screen readers when there is no [label].
  final String? semanticLabel;

  /// Desen's default switch style under [theme].
  static DsSwitchStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsSwitchStyle(
      width: 42,
      height: 24,
      inset: 3,
      trackColor: k.rail,
      trackShadows: const [],
      knobColor: k.knob,
      knobShadows: theme.shadows.knob,
      labelStyle: theme.typography.bodyStrong,
      descriptionStyle: theme.typography.label.copyWith(
        fontWeight: FontWeight.w400,
      ),
      textGap: 2,
      focusShadows: theme.focusShadows,
      hovered: DsSwitchStyle(trackColor: offHover(theme)),
      // Over a bright accent the white knob takes a dark edge, and
      // the track its own, so it does not melt into the card.
      selected: DsSwitchStyle(
        trackColor: k.accent,
        trackShadows: [
          if (k.accentEdge.a > 0) DsShadow.innerRing(k.accentEdge),
        ],
        knobShadows: theme.shadows.knobOn,
        hovered: DsSwitchStyle(trackColor: k.accentHover),
      ),
      // A thicker edge, so the error is not told by hue alone; an on
      // track turns danger, as the checkbox does.
      error: DsSwitchStyle(
        trackShadows: [DsShadow.innerRing(dsErrorEdge(theme), width: 2)],
        selected: DsSwitchStyle(
          trackColor: k.danger.fill,
          trackShadows: const [],
          hovered: DsSwitchStyle(trackColor: k.danger.fillHover),
        ),
      ),
      // A muted knob reads as inactive in both modes (the page color looked
      // like a hole in dark mode).
      disabled: DsSwitchStyle(
        trackColor: k.disabled,
        knobColor: k.onDisabled,
        knobShadows: const [],
      ),
    );
  }

  /// The off track while hovered:
  /// one visible step from [DsColors.rail] that keeps the knob at 3:1.
  /// Light themes darken it. Dark themes lighten it, unless that
  /// would leave the knob under 3:1; then it steps toward
  /// the surface instead. The old dark hover (`textSubtle`) left the knob
  /// at 1.8:1.
  ///
  /// At soft contrast the light rail is a pale fill and the knob rests on
  /// its shadow, as on iOS: hover darkens it one gentle step.
  static Color offHover(DsThemeData theme) {
    final k = theme.colors;
    if (!theme.isDark && theme.contrast == DsContrast.soft) {
      return DsColorUtils.lerp(k.rail, k.textSubtle, .22)!;
    }
    if (!theme.isDark) return k.textSubtle;
    final lighter = Color.alphaBlend(k.press, k.rail);
    final knob = DsColorUtils.contrastRatio(
      k.knob,
      lighter,
      backdrop: k.surface,
    );
    return knob >= 3 ? lighter : DsColorUtils.lerp(k.rail, k.surface, .16)!;
  }

  @override
  State<DsSwitch> createState() => _DsSwitchState();
}

class _DsSwitchState extends State<DsSwitch> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    // A surrounding DsField with an error marks the control too.
    final error =
        widget.error || (DsFieldScope.maybeOf(context)?.hasError ?? false);
    final layers = [
      DsSwitch.defaultStyle(t),
      DsSwitchTheme.of(context).style,
      widget.style,
    ];
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onChanged == null
          ? null
          : () => widget.onChanged!(!widget.value),
      haptic: DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      isButton: false,
      toggled: widget.value,
      semanticLabel: widget.semanticLabel,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsSwitchStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.value) WidgetState.selected,
          if (error) WidgetState.error,
        };
        final s = DsSwitchStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final width = s.width!, height = s.height!;
        final pad = s.inset!;
        final knob = height - pad * 2;

        final control = AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          width: width,
          height: height,
          padding: EdgeInsets.all(pad),
          decoration: DsBoxDecoration(
            color: s.trackColor,
            borderRadius: BorderRadius.circular(height / 2),
            shadows: [
              ...?s.trackShadows,
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          // The knob keeps its velocity when toggled again mid-flight.
          child: DsSpringValue(
            value: widget.value ? 1 : 0,
            spring: t.motion.moveSpringOrNull,
            builder: (context, v, child) => Align(
              alignment: AlignmentDirectional(-1 + 2 * v, 0),
              child: child,
            ),
            child: Container(
              width: knob,
              height: knob,
              decoration: DsBoxDecoration(
                color: s.knobColor,
                borderRadius: BorderRadius.circular(knob / 2),
                shadows: s.knobShadows ?? const <DsShadow>[],
              ),
            ),
          ),
        );
        if (widget.label == null && widget.description == null) return control;

        final k = t.colors;
        final enabled = !states.contains(WidgetState.disabled);
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: s.textGap!,
          children: [
            if (widget.label != null)
              DefaultTextStyle(
                style: s.labelStyle!.copyWith(
                  color: enabled ? k.text : k.onDisabled,
                ),
                child: widget.label!,
              ),
            if (widget.description != null)
              DefaultTextStyle(
                style: s.descriptionStyle!.copyWith(
                  color: enabled ? k.textMuted : k.onDisabled,
                ),
                // Under a label: read after the name and state, as the
                // hint. Alone it names the switch.
                child: widget.label == null
                    ? widget.description!
                    : descriptionAsHint(widget.description!),
              ),
          ],
        );
        // A settings row puts the switch at the end of the width it gets;
        // under an unbounded width (in a Row) it shrink-wraps instead of
        // throwing.
        return LayoutBuilder(
          // The track sits on the first line (web alignment), not between
          // the label and the description.
          builder: (context, c) => Row(
            mainAxisSize: c.hasBoundedWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: DsSpace.s12,
            children: [
              if (c.hasBoundedWidth) Expanded(child: text) else text,
              FirstLineControl(
                height: height,
                lineStyle: widget.label != null
                    ? s.labelStyle
                    : s.descriptionStyle,
                child: control,
              ),
            ],
          ),
        );
      },
    );
  }
}
