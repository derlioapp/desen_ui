import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import 'chip_style.dart';

/// The visuals of a chip for a set of [states]: fill, outline, focus ring,
/// the check (or [leading]) and the label. `DsChip` and `DsChoiceChips`
/// both draw with it, so a single-choice chip and a filter chip look the
/// same.
///
/// [layers] are the chip style layers (defaults, theme, widget style),
/// resolved here for [states]. Tone changes animate; the first build and
/// theme changes do not.
class ChipFace extends StatefulWidget {
  /// Draws a chip.
  const ChipFace({
    super.key,
    required this.layers,
    required this.states,
    required this.label,
    this.leading,
  });

  /// Style layers, lowest first.
  final List<DsChipStyle?> layers;

  /// Interaction and structural states; [WidgetState.selected] draws the
  /// selected look and the check.
  final Set<WidgetState> states;

  /// The text, usually a short [Text].
  final Widget label;

  /// An icon before the label, replaced by the check while selected.
  final Widget? leading;

  @override
  State<ChipFace> createState() => _ChipFaceState();
}

class _ChipFaceState extends State<ChipFace> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final states = widget.states;
    final s = DsChipStyle.resolveLayers(widget.layers, states);
    final animate = _lastStates != null && !setEquals(_lastStates, states);
    _lastStates = states;
    final duration = animate ? t.motion.toneDuration : Duration.zero;
    final border = s.borderColor ?? const Color(0x00000000);
    final fg = s.foreground ?? t.colors.text;
    final selected = states.contains(WidgetState.selected);
    final corners = t.radii.controlCorners(s.borderRadius, s.height!);
    return AnimatedContainer(
      duration: duration,
      curve: t.motion.toneCurve,
      constraints: BoxConstraints(minHeight: s.height!),
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: corners,
        shadows: [if (border.a > 0) DsShadow.innerRing(border)],
      ),
      // Above the fill and the outline, so a tight ring covers the
      // outline it replaces.
      foregroundDecoration: DsBoxDecoration(
        borderRadius: corners,
        shadows: states.contains(WidgetState.focused)
            ? s.focusShadows ?? const []
            : const [],
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: s.iconSize),
          child: DefaultTextStyle(
            style: (s.textStyle ?? const TextStyle()).copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: s.gap ?? DsSpace.s6,
              children: [
                if (selected && (s.showCheck ?? false))
                  const DsIcon(DsIcons.check)
                else
                  ?widget.leading,
                Flexible(child: widget.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
