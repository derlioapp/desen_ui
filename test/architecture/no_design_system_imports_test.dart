import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Desen is built on the widgets layer only. Material and Cupertino must
/// never be imported, not even for small things like `Colors` or
/// `ThemeExtension`.
void main() {
  test('lib/ imports neither Material nor Cupertino', () {
    final banned = RegExp(
      r'''import\s+['"]package:(flutter/(material|cupertino)\.dart|material_ui/|cupertino_ui/)''',
    );
    final offenders = <String>[
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && banned.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Material/Cupertino import in: ${offenders.join(', ')}',
    );
  });
}
