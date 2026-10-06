import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Public files stand on their own: a comment, a test name or a doc gives
/// its reason in words, never a pointer to a document or a numbered rule
/// that a reader of the package cannot open.
///
/// The patterns live here and only here; this file is the one exception.
final _internalReferences = <RegExp>[
  // Document names.
  RegExp(r'KALITE|TESLIM|[Dd]enetim|[Aa]ra[sş]t[ıi]rma'),
  // Numbered rules and items.
  RegExp(r'\b[KSRF]-\d{1,3}\b'),
  // Work phases.
  RegExp(r'\bFaz \d|\b[Pp]hase (\d+[a-z]?|[A-Z])\b'),
  // Section numbers.
  RegExp('§'),
  // An external design file.
  RegExp(r'\bconcept\b', caseSensitive: false),
  // Review decisions and finding codes.
  RegExp(r'\bdecision \d+\b', caseSensitive: false),
  RegExp(r'\b([Ee]ng|[Uu]x|[Vv]isual|[Bb]ugs|[Rr]ules) [A-Z]\d'),
  RegExp(r'\b[BDHLMPRSV]\d{1,2}:\s'),
  RegExp(r'\([BDHLMPRSV]\d{1,2}\)'),
  RegExp(r'\b(blind|the) audit\b(?! log)', caseSensitive: false),
];

/// The tracked (or new, not ignored) files a reader of the package or the
/// repository sees.
const _publicPaths = [
  'lib',
  'test',
  'tool',
  'example/lib',
  'example/test',
  '.github',
  ':(glob)*.md',
  ':(glob)*.yaml',
  '.pubignore',
  '.gitignore',
];

const _self = 'test/architecture/self_contained_docs_test.dart';

/// A line with its leading comment marker removed, so a reference broken
/// across two comment lines is joined back.
String _unmarked(String line) =>
    line.trimLeft().replaceFirst(RegExp(r'^(///|//|#|/?\*+)\s?'), '');

void main() {
  test('public files cite no internal notes', () {
    final listed = Process.runSync('git', [
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
      '-z',
      '--',
      ..._publicPaths,
    ]);
    expect(listed.exitCode, 0, reason: '${listed.stderr}');
    final paths = (listed.stdout as String)
        .split('\u0000')
        .where((p) => p.isNotEmpty && p != _self)
        .toList();
    expect(paths, isNotEmpty);
    bool hit(String text) => _internalReferences.any((r) => r.hasMatch(text));
    final offenders = <String>[];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue; // deleted, not yet staged
      final bytes = file.readAsBytesSync();
      if (bytes.contains(0)) continue; // binary
      final lines = utf8.decode(bytes, allowMalformed: true).split('\n');
      for (final (i, line) in lines.indexed) {
        final next = i + 1 < lines.length ? _unmarked(lines[i + 1]) : '';
        if (hit(line) || (hit('$line $next') && !hit(next))) {
          offenders.add('$path:${i + 1} ${line.trim()}');
        }
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
