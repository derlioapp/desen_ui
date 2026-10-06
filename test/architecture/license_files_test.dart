import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// LICENSE holds the package's own license only, so pub.dev recognizes it
/// (its detector gives up on long stretches of other text). NOTICES carries
/// every license that ships, in the format Flutter reads into an app's
/// license page: it prefers NOTICES over LICENSE, splits sections on a line
/// of 80 hyphens, and takes the lines before a section's first blank line
/// as the package names.
void main() {
  final separator = '\n${'-' * 80}\n';

  test('LICENSE is the MIT License alone', () {
    final text = File('LICENSE').readAsStringSync();
    expect(text, startsWith('MIT License\n'));
    expect(text, isNot(contains(separator)));
    expect(text, isNot(contains('Open Font License')));
    expect(text, isNot(contains('ISC License')));
  });

  test('NOTICES has a named section for every bundled license', () {
    final sections = File('NOTICES').readAsStringSync().split(separator);
    final byName = {
      for (final section in sections)
        section.substring(0, section.indexOf('\n\n')): section.substring(
          section.indexOf('\n\n') + 2,
        ),
    };
    expect(byName.keys, [
      'desen_ui',
      'lucide',
      'Schibsted Grotesk',
      'Geist Mono',
    ]);
    expect(
      byName['desen_ui']!.trimRight(),
      File('LICENSE').readAsStringSync().trimRight(),
    );
    expect(byName['lucide'], contains('ISC License'));
    for (final font in ['Schibsted Grotesk', 'Geist Mono']) {
      expect(
        byName[font],
        contains('SIL OPEN FONT LICENSE Version 1.1'),
        reason: font,
      );
    }
  });
}
