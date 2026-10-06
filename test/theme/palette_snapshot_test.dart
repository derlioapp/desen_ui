import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/theme/palette.dart' show DsPalette;
import 'package:flutter_test/flutter_test.dart';

/// Every generated color, for every tone, brightness and contrast level,
/// pinned to test/fixtures/palette_snapshot.json.
///
/// Fails on any color change. When a change is intended, regenerate with
/// `flutter test --update-goldens test/theme/palette_snapshot_test.dart`
/// and review the JSON diff.
const seeds = {
  'blue': DsSeed.blue,
  'navy': DsSeed.navy,
  'graphite': DsSeed.graphite,
  'oxblood': DsSeed.oxblood,
  'forest': DsSeed.forest,
  'indigo': DsSeed.indigo,
};

Map<String, Object> snapshot() => {
  for (final MapEntry(key: name, value: seed) in seeds.entries)
    name: {
      for (final b in Brightness.values)
        for (final c in DsContrast.values)
          '${b.name}_${c.name}': {
            for (final MapEntry(:key, :value) in DsPalette.fromSeed(
              seed,
              brightness: b,
              contrast: c,
            ).colors.toMap().entries)
              key:
                  '0x${value.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
          },
    },
};

void main() {
  test('palette matches the recorded snapshot', () {
    final file = File('test/fixtures/palette_snapshot.json');
    final current = const JsonEncoder.withIndent(' ').convert(snapshot());
    if (autoUpdateGoldenFiles || !file.existsSync()) {
      file.writeAsStringSync('$current\n');
      return;
    }
    expect(current, file.readAsStringSync().trimRight());
  });
}
