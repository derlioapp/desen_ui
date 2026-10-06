import 'dart:io';

import 'package:desen_ui_example/site/pages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every internal link in the site's text, `[label](/path)`, and every
/// `go('/path')`, leads to a registered page.
void main() {
  test('no dead internal links', () {
    final pages = {
      for (final group in siteGroups)
        for (final page in group.pages) page.path,
    };
    final link = RegExp(r"\]\((/[^)#\s]*)\)|go\('(/[^']*)'\)|path: '(/[^']*)'");
    final dead = <String>[];
    for (final file in Directory('lib/site').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart')) continue;
      // Comments may show the syntax itself.
      final text = file
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      for (final m in link.allMatches(text)) {
        final target = m[1] ?? m[2] ?? m[3]!;
        if (!pages.contains(target)) dead.add('${file.path}: $target');
      }
    }
    expect(dead, isEmpty, reason: dead.join('\n'));
  });
}
