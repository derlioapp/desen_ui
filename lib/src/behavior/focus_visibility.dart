import 'package:flutter/foundation.dart';

import 'focus_visibility_state.dart';

/// Whether keyboard focus should be shown right now: the browser heuristic
/// behind CSS `:focus-visible`.
///
/// Flutter's own highlight mode stays "traditional" on desktop and the web
/// even when the user only uses the mouse, so focus that arrives with a
/// click (or programmatically after one) would show. Browsers and macOS
/// show focus only to people using the keyboard. This tracks the last input:
/// - any pointer down (mouse, touch, stylus) hides focus;
/// - any key press other than a lone modifier shows it again.
///
/// Every Desen component that draws focus combines this with Flutter's
/// highlight mode. It only listens; it never consumes events or changes
/// Flutter's global focus settings.
abstract final class DsFocusVisibility {
  /// True while the user is navigating with the keyboard.
  ///
  /// Before any input it is true on desktop and the web, so focus placed
  /// first (e.g. autofocus) is visible, as in a browser; on iOS and Android
  /// it is false, since there is usually no keyboard and an autofocused
  /// field must not look focused until a key is pressed.
  static ValueListenable<bool> get keyboard => keyboardFocusVisible();
}
