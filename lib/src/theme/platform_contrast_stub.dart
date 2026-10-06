import 'package:flutter/foundation.dart';

/// Off the web there is no browser preference: the platform reports
/// contrast through `MediaQueryData.highContrast`.
final ValueListenable<bool> prefersMoreContrast = ValueNotifier(false);
