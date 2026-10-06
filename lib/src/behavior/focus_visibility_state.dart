/// The input tracking behind `DsFocusVisibility`. Not exported: the
/// package's public surface is `DsFocusVisibility.keyboard`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show FocusManager;

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

/// The focus manager the key handler was registered under. A new one means
/// the bindings were reset (the test binding does this after each test,
/// clearing every keyboard handler with it), so the handler is gone.
FocusManager? _keysFor;
bool _pointerListening = false;

/// True while the user is navigating with the keyboard; starts listening
/// to input on first use, and again after the bindings are reset (a new
/// test), from the initial state.
ValueListenable<bool> keyboardFocusVisible() {
  if (!identical(_keysFor, FocusManager.instance)) {
    _listen();
    _keyboard.value = focusVisibleInitially(defaultTargetPlatform);
  }
  return _keyboard;
}

/// Back to the state before any input: listening afresh, focus visible as
/// [keyboard] says, else as the platform starts ([focusVisibleInitially]).
void resetFocusVisibility({bool? keyboard}) {
  _listen();
  _keyboard.value = keyboard ?? focusVisibleInitially(defaultTargetPlatform);
}

void _listen() {
  // The handler may or may not still be registered: remove it first, so it
  // is never there twice.
  HardwareKeyboard.instance
    ..removeHandler(_onKey)
    ..addHandler(_onKey);
  _keysFor = FocusManager.instance;
  // The pointer router outlives a binding reset.
  if (_pointerListening) return;
  _pointerListening = true;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
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
