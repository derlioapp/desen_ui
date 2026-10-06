/// The browser's "more contrast" request, which Flutter's
/// `MediaQueryData.highContrast` does not carry on the web (the engine maps
/// only `forced-colors: active` there). Not exported.
library;

import 'package:flutter/foundation.dart';

import 'platform_contrast_stub.dart'
    if (dart.library.js_interop) 'platform_contrast_web.dart'
    as impl;

/// True while the browser matches `(prefers-contrast: more)`: macOS and iOS
/// "Increase contrast" in Safari, Chrome and Firefox. Always false off the
/// web.
ValueListenable<bool> get prefersMoreContrast => impl.prefersMoreContrast;
