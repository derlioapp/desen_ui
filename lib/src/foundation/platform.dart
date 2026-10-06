import 'package:flutter/foundation.dart';

/// Whether [platform] is touch-first (iOS, Android), where tap areas are
/// 44px by default and there is usually no keyboard. Not exported.
bool isTouchPlatform(TargetPlatform? platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.android;
