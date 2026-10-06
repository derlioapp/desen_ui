import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real fonts, so text measures as on the site (flutter_test
/// otherwise draws every glyph as a wide box).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const families = {
    'packages/desen_ui_fonts/SchibstedGrotesk': [
      'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', //
    ],
    'packages/desen_ui_fonts/GeistMono': ['Regular', 'Medium', 'SemiBold'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    final file = family.split('/').last;
    for (final w in weights) {
      final bytes = File('../desen_ui_fonts/fonts/$file-$w.ttf')
          .readAsBytesSync();
      loader.addFont(
        Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    }
    await loader.load();
  }
  await testMain();
}
