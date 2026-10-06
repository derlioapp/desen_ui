import 'dart:io';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Numbers are set in the text family with tabular figures
/// (`DsTypography.numeric`), not in mono: a mono face made dates, amounts
/// and counters read like a console, and its slashed zero like "Ø".
/// Mono is kept for code-like content only.
void main() {
  test('numeric is the text family with tabular figures', () {
    final y = DsTypography();
    final s = y.numeric(y.mono(y.caption));
    expect(s.fontFamily, contains(y.family));
    expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(s.fontSize, y.caption.fontSize);
  });

  test('components use mono only for code-like content', () {
    // The search field's keycap hint ("⌘K"), like a web <kbd>.
    const allowed = {'text_field.dart': 1};
    final uses = <String, int>{
      for (final f in Directory(
        'lib/src/components',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          f.uri.pathSegments.last: RegExp(r'\.mono\(')
              .allMatches(f.readAsStringSync())
              .length,
    }..removeWhere((_, n) => n == 0);
    expect(uses, allowed);
  });
}
