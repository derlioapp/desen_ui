import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../painting/decoration.dart';
import '../painting/shadow.dart';
import '../theme/theme.dart';
import 'focus_visibility.dart';

/// Draws the theme's keyboard focus ring around [child], for controls you
/// build yourself.
///
/// Desen's own controls draw their ring as part of their box. A custom
/// control on `DsPressable` gets the same ring by wrapping its box:
///
/// ```dart
/// DsPressable(
///   onPressed: open,
///   builder: (context, states, _) => DsFocusRing(
///     focused: states.contains(WidgetState.focused),
///     borderRadius: BorderRadius.circular(12),
///     child: MyTile(hovered: states.contains(WidgetState.hovered)),
///   ),
/// )
/// ```
///
/// By default the ring is the gapped outline of a filled control
/// (`DsShadows.focusOffset`): a 2px line in the focus color, 2px off the
/// box, so it reads on any background. A control with a 1px edge of its
/// own looks better with the ring on that edge: pass
/// `DsTheme.shadowsOf(context).focusTight` as [shadows]. Rows that fill
/// their container's width draw an inner ring instead (an inset
/// `DsShadow.innerRing`), so a rounded or clipped container never cuts it.
///
/// The ring shows only while [focused] and the user is navigating with
/// the keyboard ([DsFocusVisibility.keyboard]): a click or a tap never
/// shows it, like CSS `:focus-visible`. `DsPressable` reports
/// [WidgetState.focused] by the same rule, so its state can be passed
/// straight in. The ring fades in and out with the theme's tone motion.
///
/// It is painted above [child] and outside its box, so it never changes
/// the layout; give it room (no clipping ancestor right at the box edge)
/// for the outline to show. Match [borderRadius] to the box's corners, so
/// the ring stays concentric with them; for a control rounded by height,
/// that is `DsTheme.radiiOf(context).controlCorners(null, height)`.
class DsFocusRing extends StatelessWidget {
  /// Draws the focus ring around [child] while [focused].
  const DsFocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.shadows,
  });

  /// Whether the control has focus. The ring shows only while the keyboard
  /// is in use, too.
  final bool focused;

  /// The control's box.
  final Widget child;

  /// The corners of [child]'s box, followed by the ring.
  final BorderRadiusGeometry borderRadius;

  /// The ring; the theme's `DsShadows.focusOffset` when null.
  final List<DsShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final motion = DsTheme.motionOf(context);
    final ring = shadows ?? DsTheme.shadowsOf(context).focusOffset;
    return ValueListenableBuilder<bool>(
      valueListenable: DsFocusVisibility.keyboard,
      child: child,
      builder: (context, keyboard, child) => AnimatedContainer(
        duration: motion.toneDuration,
        curve: motion.toneCurve,
        foregroundDecoration: DsBoxDecoration(
          borderRadius: borderRadius,
          shadows: focused && keyboard ? ring : const [],
        ),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('focused', value: focused, ifTrue: 'focused'))
      ..add(DiagnosticsProperty('borderRadius', borderRadius))
      ..add(DiagnosticsProperty('shadows', shadows, defaultValue: null));
  }
}
