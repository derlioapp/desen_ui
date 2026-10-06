import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Component text styles built with `dsTextStyle` name the theme's font
/// package, as `DsTypography` does: without it a family bundled in a
/// package (Desen's own faces, in `desen_ui`) is not found and the text
/// falls back to the platform font.
void main() {
  test('every dsTextStyle call in a component passes package', () {
    final missing = <String>[];
    for (final f in Directory(
      'lib/src/components',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(r'dsTextStyle\(').allMatches(src)) {
        // The argument list up to the matching parenthesis.
        var depth = 0, i = m.end - 1;
        do {
          if (src[i] == '(') depth++;
          if (src[i] == ')') depth--;
          i++;
        } while (depth > 0);
        if (!src.substring(m.end, i).contains('package:')) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          missing.add('${f.path}:$line');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
