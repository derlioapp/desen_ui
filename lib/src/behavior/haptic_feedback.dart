import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/platform.dart';
import '../theme/haptics.dart';
import '../theme/theme.dart';
import '../theme/theme_data.dart';

/// Plays a [DsHapticEvent] through the theme's [DsThemeData.haptics]
/// setting.
///
/// [DsPressable] plays its `haptic` event on every activation, so a control
/// built on it follows the setting without calling this. Use it in a
/// control that handles its own gestures, at the moment its state changes:
///
/// ```dart
/// void _select(int i) {
///   if (i == _selected) return;
///   DsHapticFeedback.play(context, DsHapticEvent.selection);
///   widget.onChanged(i);
/// }
/// ```
///
/// Components name the event, never the platform call: the weights are the
/// lightest the platforms offer (the selection tick and a light impact),
/// because a control's feedback is punctuation, not a sentence.
abstract final class DsHapticFeedback {
  /// Plays [event] if the theme's [DsThemeData.effectiveHaptics] admits it
  /// and its [DsThemeData.platform] is iOS or Android. Safe to call
  /// unconditionally; it never rebuilds [context].
  ///
  /// Call it before reporting the change: the callback may rebuild, dispose
  /// or navigate, and the feedback belongs to the touch.
  static void play(BuildContext context, DsHapticEvent event) {
    // A lookup that does not depend on the theme: playing happens in
    // callbacks, and must not make the caller rebuild on theme changes.
    final theme =
        context.getInheritedWidgetOfExactType<DsTheme>()?.data ??
        DsTheme.of(context);
    if (!isTouchPlatform(theme.platform)) return;
    if (!theme.effectiveHaptics.plays(event)) return;
    final Future<void> done = switch (event) {
      // The platform's own "selection moved" texture: the tick of a picker
      // wheel on iOS, the clock tick on Android.
      DsHapticEvent.selection => HapticFeedback.selectionClick(),
      DsHapticEvent.command => HapticFeedback.lightImpact(),
    };
    // Best effort: a device or browser without a haptic engine answers with
    // an error, which is silence, not an app failure.
    done.ignore();
  }
}
