import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/min_tap_target.dart';
import '../../behavior/pressable.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../field/field.dart';
import 'error_edge.dart';
import 'first_line.dart';
import 'radio.dart';
import 'radio_card_style.dart';
import 'radio_circle.dart';
import 'radio_group_scope.dart';
import 'radio_style.dart';
import 'selection_text.dart';

/// One option of a [DsRadioGroup] drawn as a card: a plan, a theme, a
/// shipping method. The whole card selects it.
///
/// It is a radio like [DsRadio]: it sits anywhere below the group, keeps
/// the group's roving focus (one Tab stop on the selected option, arrow
/// keys move the selection) and is announced as a radio with all of its
/// text. The selected card takes the theme's selection style (the soft
/// tint, or the filled selection under `DsSelectionStyle.strong`), and a
/// radio circle on its first line shows the choice beyond the fill
/// ([DsRadioCardStyle.showRadio]).
///
/// [child] is extra content under the text, such as a price or a preview.
///
/// ```dart
/// DsRadioGroup<String>(
///   value: plan,
///   onChanged: (v) => setState(() => plan = v!),
///   child: Row(
///     spacing: 12,
///     children: [
///       Expanded(
///         child: DsRadioCard(
///           value: 'free',
///           label: const Text('Free'),
///           description: const Text('For personal projects'),
///         ),
///       ),
///       Expanded(
///         child: DsRadioCard(
///           value: 'pro',
///           label: const Text('Pro'),
///           description: const Text('For teams up to 20'),
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// A card fills the width it is given; in a loose space it is as wide as
/// its content.
class DsRadioCard<T> extends StatefulWidget {
  /// Creates a radio card for [value].
  const DsRadioCard({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.child,
    this.enabled = true,
    this.error = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The value this card stands for.
  final T value;

  /// The title, usually a short [Text] (14, semibold).
  final Widget label;

  /// Secondary text under the label (13, muted).
  final Widget? description;

  /// Extra content under the text, e.g. a price or a preview. Text and
  /// icons in it take the label's color, so they read on the selected
  /// fill.
  final Widget? child;

  /// Whether this option can be selected. The whole group is disabled by
  /// a null [DsRadioGroup.onChanged].
  final bool enabled;

  /// Marks the card invalid: a 2px error outline, and screen readers hear
  /// it as invalid. A [DsRadioGroup.error] or a surrounding [DsField]
  /// with an error sets it too.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsRadioCardStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Replaces the card's text for screen readers.
  final String? semanticLabel;

  /// Desen's default radio card style under [theme].
  static DsRadioCardStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    final strong = theme.fillsSelection;
    return DsRadioCardStyle(
      padding: const EdgeInsets.all(DsSpace.s16),
      background: k.surface,
      shadows: theme.shadows.surface,
      borderColor: clear,
      borderWidth: 1,
      borderRadius: BorderRadius.circular(theme.radii.card),
      labelStyle: theme.typography.bodyStrong
          .copyWith(height: 1.3)
          .copyWith(color: k.text),
      descriptionStyle: theme.typography.label
          .copyWith(fontWeight: FontWeight.w400)
          .copyWith(color: k.textMuted),
      textGap: 2,
      contentGap: DsSpace.s12,
      gap: DsSpace.s12,
      showRadio: true,
      // Filled: the gapped ring, which reads against any fill.
      focusShadows: theme.focusShadows,
      hovered: DsRadioCardStyle(
        background: Color.alphaBlend(k.hover, k.surface),
      ),
      pressed: DsRadioCardStyle(
        background: Color.alphaBlend(k.press, k.surface),
      ),
      selected: DsRadioCardStyle(
        background: theme.selectedFill,
        // A bright filled selection keeps its shape on a light page.
        borderColor: theme.selectedEdge ?? clear,
        labelStyle: TextStyle(color: theme.onSelectedFill),
        descriptionStyle: TextStyle(
          color: strong ? theme.onSelectedFill : k.textMuted,
        ),
        // On a filled card an accent circle would melt into the fill:
        // it turns to the fill's ink, with a dot in the fill's color.
        radioStyle: strong
            ? DsRadioStyle(
                background: theme.onSelectedFill,
                borderColor: clear,
                dotColor: theme.selectedFill,
              )
            : null,
        // Hover stays visible on a selected card.
        hovered: DsRadioCardStyle(background: theme.selectedHoverFill),
      ),
      // A thicker edge, so the error is not told by hue alone.
      error: DsRadioCardStyle(borderColor: dsErrorEdge(theme), borderWidth: 2),
      // Disabled keeps the circle readable on the inactive fill: its edge
      // stays, and a selected one keeps its dot.
      disabled: DsRadioCardStyle(
        background: k.disabled,
        borderColor: clear,
        labelStyle: TextStyle(color: k.onDisabled),
        descriptionStyle: TextStyle(color: k.onDisabled),
        radioStyle: DsRadioStyle(
          background: k.disabled,
          borderColor: k.border,
          borderWidth: 1,
          dotColor: k.onDisabled,
        ),
      ),
    );
  }

  @override
  State<DsRadioCard<T>> createState() => _DsRadioCardState<T>();
}

class _DsRadioCardState<T> extends State<DsRadioCard<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  Set<WidgetState>? _lastStates;

  /// Whether the card can be selected; set in [build].
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
  // focused, not on every pointer or key event in the app.
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
    // A surrounding DsField or group with an error marks the card too.
    final error =
        widget.error ||
        (group?.error ?? false) ||
        (DsFieldScope.maybeOf(context)?.hasError ?? false);
    final layers = [
      DsRadioCard.defaultStyle(t),
      DsRadioCardTheme.of(context).style,
      widget.style,
    ];
    final enabled = widget.enabled && (group?.enabled ?? true);
    final registry = RadioGroup.maybeOf<T>(context);
    _enabled = enabled && registry != null;
    final card = RawRadio<T>(
      value: widget.value,
      groupRegistry: registry,
      enabled: enabled && registry != null,
      toggleable: false,
      focusNode: _node,
      autofocus: widget.autofocus,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsRadioCardStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, toggle) {
        final selected = toggle.value ?? false;
        final states = <WidgetState>{
          // Focus shows only to keyboard users (DsFocusVisibility).
          for (final s in toggle.states)
            if (s != WidgetState.focused || DsFocusVisibility.keyboard.value) s,
          if (toggle.downPosition != null) WidgetState.pressed,
          if (error) WidgetState.error,
          if (selected) WidgetState.selected,
        };
        final s = DsRadioCardStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final border = s.borderColor ?? const Color(0x00000000);

        Widget? circle;
        if (s.showRadio ?? true) {
          // The circle follows the card's states, except focus: the ring
          // goes around the card.
          final r = DsRadioStyle.resolveLayers([
            DsRadio.defaultStyle(t),
            DsRadioTheme.of(context).style,
            s.radioStyle,
          ], {...states}..remove(WidgetState.focused));
          circle = FirstLineControl(
            height: r.size!,
            lineStyle: s.labelStyle,
            child: RadioCircle(
              style: r,
              selected: selected,
              focused: false,
              animate: animate,
            ),
          );
        }

        final text = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: s.contentGap!,
          children: [
            SelectionText(
              label: widget.label,
              description: widget.description,
              labelStyle: s.labelStyle,
              descriptionStyle: s.descriptionStyle,
              gap: s.textGap!,
            ),
            if (widget.child case final child?)
              // Text and icons in it take the title's color, so they read
              // on the selected fill.
              IconTheme.merge(
                data: IconThemeData(color: s.labelStyle?.color),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: s.labelStyle?.color),
                  child: child,
                ),
              ),
          ],
        );

        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: [
              ...?s.shadows,
              if (border.a > 0)
                DsShadow.innerRing(border, width: s.borderWidth!),
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          // A semantic label replaces the card's text, not adds to it.
          child: ExcludeSemantics(
            excluding: widget.semanticLabel != null,
            // The circle sits on the label's first line (web alignment).
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: circle == null ? 0 : s.gap!,
              children: [
                ?circle,
                Flexible(child: text),
              ],
            ),
          ),
        );
      },
    );
    return Semantics(
      label: widget.semanticLabel,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: DsMinTapTarget(size: t.sizes.minTapTarget, child: card),
    );
  }
}
