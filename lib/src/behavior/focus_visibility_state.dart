/// The input tracking behind `DsFocusVisibility`. Not exported: the
/// package's public surface is `DsFocusVisibility.keyboard`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Whether focus shows before any input on [platform]. On desktop and the
/// web, true: focus placed first (e.g. autofocus) is visible, as in a
/// browser. On phones and tablets, false: there is usually no keyboard, so
/// an autofocused field must not look focused until a key is pressed.
bool focusVisibleInitially(TargetPlatform platform) =>
    kIsWeb ||
    switch (platform) {
      TargetPlatform.iOS || TargetPlatform.android => false,
      _ => true,
    };

final ValueNotifier<bool> _keyboard = ValueNotifier(
  focusVisibleInitially(defaultTargetPlatform),
);
bool _listening = false;

/// True while the user is navigating with the keyboard; starts listening
/// to input on first use.
ValueListenable<bool> keyboardFocusVisible() {
  _listen();
  return _keyboard;
}

/// Back to the desktop initial state (focus visible), between tests. The
/// test binding clears keyboard handlers after each test, so listening
/// restarts.
void resetFocusVisibility() {
  if (_listening) {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _listening = false;
  }
  _listen();
  _keyboard.value = true;
}

void _listen() {
  if (_listening) return;
  _listening = true;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  HardwareKeyboard.instance.addHandler(_onKey);
}

void _onPointer(PointerEvent event) {
  if (event is PointerDownEvent) _keyboard.value = false;
}

bool _onKey(KeyEvent event) {
  if (event is KeyDownEvent && !_modifiers.contains(event.logicalKey)) {
    _keyboard.value = true;
  }
  return false;
}

final _modifiers = {
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.fn,
};
