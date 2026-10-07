/// Internal: the browser's own context menu while the pointer is over a
/// region that opens Desen's. Not exported from the package.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Turns the browser's context menu off while the pointer is over a region
/// that opens Desen's menu on a right click, and back on when it leaves.
///
/// Holds are counted, so neighbouring regions do not turn it on between
/// them, and a region removed under the pointer gives its hold back on
/// [release] (call it from `dispose`), where the pointer's exit never
/// comes. The menu is turned back on only if it was on before the first
/// hold: an app that turned it off for good keeps it off.
class DsBrowserMenuHold {
  static int _holds = 0;

  /// Whether the holds turned the menu off (it was on before them).
  static bool _ours = false;

  /// Stands in for the browser outside the web, for tests: called with
  /// whether the menu should be on, and read back for its current state.
  @visibleForTesting
  static ({bool Function() enabled, void Function(bool on) set})? debugBrowser;

  bool _held = false;

  static bool get _web => kIsWeb || debugBrowser != null;

  static bool get _enabled =>
      debugBrowser?.enabled() ?? BrowserContextMenu.enabled;

  static void _set(bool on) {
    if (debugBrowser case final browser?) return browser.set(on);
    on
        ? BrowserContextMenu.enableContextMenu()
        : BrowserContextMenu.disableContextMenu();
  }

  /// Turns the browser's menu off, once per holder.
  void hold() {
    if (!_web || _held) return;
    _held = true;
    // Still off from a hold that is about to end: keep it, and the
    // memory that it was on.
    if (_holds++ == 0 && !_ours && _enabled) {
      _ours = true;
      _set(false);
    }
  }

  /// Gives the hold back; the last one turns the menu on again, once the
  /// pointer event is done: moving from one region to the next leaves the
  /// first before it enters the second.
  void release() {
    if (!_web || !_held) return;
    _held = false;
    if (--_holds > 0) return;
    scheduleMicrotask(() {
      if (_holds > 0 || !_ours) return;
      _ours = false;
      _set(true);
    });
  }
}
