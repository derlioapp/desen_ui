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

  test('doc comments cite no design concept or decision numbers', () {
    // "concept 34", "concept card 20", "concept "E"", the concept file, the
    // concept's own look, "(decision 7)". Doc blocks are joined, so a
    // reference broken across lines is caught too.
    final internal = RegExp(
      r'\bconcept\s+(cards?\s+)?(\d+|"[A-Z]")|\bconcept/|\bthe concept\b'
      r'|\(decision \d+\)',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      var start = -1;
      final block = StringBuffer();
      for (final (i, line) in [...lines, ''].indexed) {
        final t = line.trimLeft();
        if (t.startsWith('///')) {
          if (start < 0) start = i;
          block.write(' ${t.substring(3)}');
          continue;
        }
        if (start >= 0 && internal.hasMatch(block.toString())) {
          offenders.add('${f.path}:${start + 1}');
        }
        start = -1;
        block.clear();
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('doc comments describe no high contrast level', () {
    // There are two levels, soft and standard. The platform's own setting
    // ("Increase contrast", high-contrast text) may still be named. Doc
    // blocks are joined, so a phrase broken across lines is caught too.
    final stale = RegExp(
      r'DsContrast\.high|\bhigh\s+contrast\b',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      var start = -1;
      final block = StringBuffer();
      for (final (i, line) in [...lines, ''].indexed) {
        final t = line.trimLeft();
        if (t.startsWith('///')) {
          if (start < 0) start = i;
          block.write(' ${t.substring(3)}');
          continue;
        }
        if (start >= 0 && stale.hasMatch(block.toString())) {
          offenders.add('${f.path}:${start + 1}');
        }
        start = -1;
        block.clear();
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
