import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Library code does not change the case of text with `toUpperCase()` or
/// `toLowerCase()`.
///
/// Dart's case methods ignore the language: `'dil'.toUpperCase()` is
/// `'DIL'`, never the Turkish `'DİL'`, and `'I'.toLowerCase()` is `'i'`,
/// not `'ı'`. Flutter also has no paint-only text transform, so casing a
/// label changes what screen readers read. A component shows the string it
/// was given; for case-insensitive matching it folds both sides with
/// `dsFoldCase`, and it sorts with `dsCompareText` (both in
/// `lib/src/foundation/case.dart`).
///
/// Scope: every Dart file under `lib/src` except `lib/src/foundation/`,
/// where those helpers and other primitives (an SVG path parser reading
/// ASCII command letters) are built. Comments are skipped.
///
/// A line that really needs one (ASCII text Desen generates itself, such
/// as a hex code) carries `// ds-raw: <reason>` on the line itself or the
/// line above, as in `no_raw_values_test.dart`.
void main() {
  test('lib/src changes no case outside the case helpers', () {
    final offenders = <String>[];
    final files = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _inScope(f.path.replaceAll(r'\', '/')));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final excused =
            line.contains('ds-raw:') ||
            (i > 0 && lines[i - 1].contains('ds-raw:'));
        if (excused || line.trimLeft().startsWith('//')) continue;
        if (_caseTransform.hasMatch(line.split('//').first)) {
          offenders.add('${file.path}:${i + 1} ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the check catches what it should', () {
    expect(_caseTransform.hasMatch('label.toUpperCase()'), isTrue);
    expect(_caseTransform.hasMatch("'x'.toLowerCase()"), isTrue);
    expect(_caseTransform.hasMatch('a?.toLowerCase()'), isTrue);
    expect(_caseTransform.hasMatch('s.toLowerCase'), isTrue); // a tear-off
    expect(_caseTransform.hasMatch('dsFoldCase(label)'), isFalse);
    expect(_caseTransform.hasMatch('toUpperCaseName'), isFalse);

    expect(_inScope('lib/src/components/x/x.dart'), isTrue);
    expect(_inScope('lib/src/overlay/x.dart'), isTrue);
    expect(_inScope('lib/src/foundation/case.dart'), isFalse);
  });
}

final _caseTransform = RegExp(r'\.to(Upper|Lower)Case\b');

bool _inScope(String path) =>
    path.endsWith('.dart') &&
    path.startsWith('lib/src/') &&
    !path.startsWith('lib/src/foundation/');
