import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'chip_face.dart';
import 'chip_style.dart';

/// A selectable filter chip. Unselected: transparent with a faint edge.
/// Selected: the theme's selection style and a check before the label (in
/// place of [leading]), so the state does not rest on a faint tint and hue
/// alone (WCAG 1.4.1; turn it off with [DsChipStyle.showCheck]). No edge,
/// except around a bright accent fill.
///
/// A label that does not fit ellipsizes; screen readers still get all of
/// it.
///
/// Each chip is a Tab stop; Space or Enter toggles it. A chip turns on and
/// off on its own, so screen readers hear a checkbox, checked or not (not
/// a "selected" button, which the web reads as the current item).
///
/// ```dart
/// DsChip(
///   label: const Text('Tasarım'),
///   selected: filters.contains('design'),
///   onChanged: (on) => toggle('design', on),
/// )
/// ```
class DsChip extends StatefulWidget {
  /// Creates a chip.
  const DsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.leading,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The text, usually a short [Text].
  final Widget label;

  /// Whether the chip is on.
  final bool selected;

  /// Called with the new selected value. Null disables the chip.
  final ValueChanged<bool>? onChanged;

  /// An icon before the label.
  final Widget? leading;

  /// Style laid over the theme and defaults.
  final DsChipStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Replaces the label for screen readers, e.g. when the label is an
  /// icon or abbreviated.
  final String? semanticLabel;

  /// Desen's default chip style under [theme].
  static DsChipStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    return DsChipStyle(
      height: theme.sizes.sm,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s16),
      background: clear,
      foreground: k.textMuted,
      borderColor: k.borderChip,
      // No radius: the corners follow the resolved height.
      textStyle: theme.typography.labelStrong,
      gap: DsSpace.s6,
      iconSize: 16,
      showCheck: true,
      // Outlined: the ring takes the outline's place, one 2px line on the
      // edge, instead of circling it.
      focusShadows: theme.shadows.focusTight,
      hovered: DsChipStyle(background: k.hover, foreground: k.text),
      pressed: DsChipStyle(background: k.press),
      selected: DsChipStyle(
        background: theme.selectedFill,
        foreground: theme.onSelectedFill,
        borderColor: theme.selectedEdge ?? clear,
        // Filled: the gapped ring, which reads against the fill.
        focusShadows: theme.focusShadows,
        // Hover stays visible on a selected item.
        hovered: DsChipStyle(background: theme.selectedHoverFill),
      ),
      // Disabled keeps the shape: an unselected chip its outline, a
      // selected one its fill and no outline, as when enabled.
      disabled: DsChipStyle(
        background: clear,
        foreground: k.onDisabled,
        borderColor: k.borderChip,
        selected: DsChipStyle(background: k.disabled, borderColor: clear),
      ),
    );
  }

  @override
  State<DsChip> createState() => _DsChipState();
}

class _DsChipState extends State<DsChip> {
  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsChip.defaultStyle(t),
      DsChipTheme.of(context).style,
      widget.style,
    ];
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onChanged == null
          ? null
          : () => widget.onChanged!(!widget.selected),
      haptic: DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // On or off on its own: a checkbox, as a filter chip is.
      isButton: false,
      checked: widget.selected,
      semanticLabel: widget.semanticLabel,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsChipStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) => ChipFace(
        layers: layers,
        states: {...interaction, if (widget.selected) WidgetState.selected},
        leading: widget.leading,
        label: widget.label,
      ),
    );
  }
}
