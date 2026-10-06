import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('matchMedia')
external _MediaQueryList? _matchMedia(String query);

extension type _MediaQueryList._(JSObject _) implements JSObject {
  external bool get matches;
  external void addEventListener(String type, JSFunction listener);
}

/// Follows `(prefers-contrast: more)` and its changes.
final ValueListenable<bool> prefersMoreContrast = () {
  final list = _matchMedia('(prefers-contrast: more)');
  final notifier = ValueNotifier(list?.matches ?? false);
  list?.addEventListener(
    'change',
    ((JSAny _) {
      notifier.value = list.matches;
    }).toJS,
  );
  return notifier;
}();
