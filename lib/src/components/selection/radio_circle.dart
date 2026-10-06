import 'package:flutter/widgets.dart';

import '../../behavior/spring_value.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/theme.dart';
import 'radio_style.dart';

/// The circle of a radio, drawn from a resolved [style]: the fill, the
/// inner outline, the focus ring while [focused], and the dot, which
/// springs in when [selected]. `DsRadio` and `DsRadioCard` both draw it.
class RadioCircle extends StatelessWidget {
  /// Draws a radio circle.
  const RadioCircle({
    super.key,
    required this.style,
    required this.selected,
    required this.focused,
    required this.animate,
  });

  /// The radio style, already resolved for the current states.
  final DsRadioStyle style;

  /// Whether the dot shows.
  final bool selected;

  /// Whether the focus ring shows.
  final bool focused;

  /// Whether tone changes animate (false on the first build and for
  /// theme changes).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final s = style;
    final size = s.size!;
    final dot = s.dotSize!;
    final border = s.borderColor ?? const Color(0x00000000);
    return AnimatedContainer(
      duration: animate ? t.motion.toneDuration : Duration.zero,
      curve: t.motion.toneCurve,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(size / 2),
        shadows: [
          if (border.a > 0) DsShadow.innerRing(border, width: s.borderWidth!),
          if (focused) ...?s.focusShadows,
        ],
      ),
      child: DsSpringValue(
        value: selected ? 1 : 0,
        spring: t.motion.moveSpringOrNull,
        builder: (context, v, child) =>
            Transform.scale(scale: v < 0 ? 0 : v, child: child),
        child: Container(
          width: dot,
          height: dot,
          decoration: DsBoxDecoration(
            color: s.dotColor,
            borderRadius: BorderRadius.circular(dot / 2),
          ),
        ),
      ),
    );
  }
}
