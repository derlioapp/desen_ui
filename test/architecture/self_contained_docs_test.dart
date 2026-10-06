import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// API docs stand on their own: a reader of the package cannot look up the
/// repository's internal rule, audit or concept numbers, so doc comments
/// give the reason in words instead. Plain `//` comments may still cite
/// them for maintainers.
void main() {
  test('doc comments in lib/ cite no internal rule numbers', () {
    final internal = RegExp(
      r'\b[KSF]-\d+\b|KALITE|denetim-\d|TESLIM|concept cards? \d|\bFaz \d'
      r'|Concept key|\b(eng|ux|visual|bugs|rules) [A-Z]\d|\([RDBHVMLP]\d{1,2}\)',
    );
    final offenders = <String>[
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (line.trimLeft().startsWith('///') && internal.hasMatch(line))
              '${f.path}:${i + 1} ${line.trim()}',
    ];
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
