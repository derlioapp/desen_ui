import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Turns the press motion of every control below it off, or back on.
///
/// Buttons and stepper buttons shrink a little while pressed (their
/// style's `pressScale`). One scope switches that off for a whole app or
/// a part of it, such as a dense toolbar or a navigation rail, whatever
/// the controls' styles say:
///
/// ```dart
/// DsPressEffect(
///   enabled: false,
///   child: MyToolbar(),
/// )
/// ```
///
/// Only the motion goes: hover and press colors, focus rings, haptics and
/// semantics stay. The nearest scope wins, so `DsPressEffect(enabled:
/// true)` inside a disabled one brings the motion back for its subtree;
/// each control then plays its own `pressScale`, so a ghost button, which
/// has none, still does not move. Reduced motion still wins: there the
/// press never animates.
///
/// A control of your own built on `DsPressable` follows the scope by
/// scaling by [scaleOf].
class DsPressEffect extends InheritedWidget {
  /// Turns the press motion in [child] on or off.
  const DsPressEffect({super.key, required this.enabled, required super.child});

  /// Whether controls below may play their press motion.
  final bool enabled;

  /// Whether the press motion is on at [context]: the nearest scope's
  /// [enabled], or true when there is none.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DsPressEffect>()?.enabled ??
      true;

  /// [scale] when the press motion is on at [context], otherwise 1 (no
  /// motion). For a control's resolved `pressScale`.
  static double scaleOf(BuildContext context, double scale) =>
      of(context) ? scale : 1;

  @override
  bool updateShouldNotify(DsPressEffect oldWidget) =>
      enabled != oldWidget.enabled;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('enabled', value: enabled, ifFalse: 'press motion off'),
    );
  }
}
