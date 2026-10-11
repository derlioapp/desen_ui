import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every place that names the release follows pubspec.yaml's version, so
/// a release that bumps it cannot leave one behind.
void main() {
  final version = RegExp(
    r'^version: (\d+)\.(\d+)\.(\d+)$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())!;
  final full = '${version[1]}.${version[2]}.${version[3]}';
  final minor = '${version[1]}.${version[2]}';

  test('the README names the version and its caret constraint', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('> Status: `$full`,'));
    expect(readme, contains('desen_ui: ^$minor.0\n'));
  });

  test('the changelog opens with the version or unreleased work', () {
    final first = File('CHANGELOG.md').readAsLinesSync().first;
    expect(first, anyOf('## $full', '## Unreleased'));
  });

  test("the site's header badge shows the minor version", () {
    final shell = File('example/lib/site/shell.dart').readAsStringSync();
    final badge = RegExp(r"DsBadge\(label: const Text\('([^']*)'\)")
        .firstMatch(shell);
    expect(badge?[1], minor);
  });
}
