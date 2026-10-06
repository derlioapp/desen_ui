import 'package:flutter/widgets.dart';

import '../components/scrollbar/scrollbar.dart';

/// Scrolling that feels native on every platform, without Material.
///
/// - No glow or stretch on overscroll; iOS and macOS keep their bounce.
/// - On desktop, a thin [DsScrollbar] in theme colors (restyle it with a
///   `DsScrollbarTheme`).
/// - The mouse never drag-scrolls (inherited from [ScrollBehavior]).
class DsScrollBehavior extends ScrollBehavior {
  /// Creates the behavior.
  const DsScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return DsScrollbar(controller: details.controller, child: child);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }
}
