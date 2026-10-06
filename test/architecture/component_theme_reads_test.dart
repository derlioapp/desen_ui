import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Desen's widgets read the theme with the component accessor
/// (`dsThemeOf`), which leaves out the app's theme extensions: a change of
/// an extension alone then rebuilds only the app's own readers
/// (`DsTheme.extensionOf`), not every component.
void main() {
  test('lib/ reads the whole theme only through dsThemeOf', () {
    final offenders = <String>[];
    for (final f in Directory('lib/src').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      // Where DsTheme.of is defined.
      if (f.path.endsWith('theme/theme.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('///') || line.startsWith('//')) continue;
        if (line.contains('DsTheme.of(')) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
