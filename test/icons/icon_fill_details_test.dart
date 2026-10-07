import 'dart:io';

import 'package:desen_ui/src/foundation/svg_path.dart';
import 'package:desen_ui/src/icons/fill_details.dart';
import 'package:flutter_test/flutter_test.dart';

/// Icons whose filled form hides most of a line: the line touches the
/// outline, so it is neither cut out nor visible on the fill. Reviewed and
/// accepted; a new name here means a new icon to look at before it ships.
const _accepted = {
  'cog',
  'loaderPinwheel',
  'mouth',
  'pie',
  'plug2',
  'spiderWeb',
  'waveCircle',
};

void main() {
  test('a filled icon hides no line under its fill', () {
    final constant = RegExp(
      r'const _(\w+) = DsIconData\(\[(.*?)\]',
      dotAll: true,
    );
    final string = RegExp(r"'((?:[^'\\]|\\.)*)'");
    final hidden = <String>{};
    for (final file in Directory('lib/src/icons/set').listSync()) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in constant.allMatches(file.readAsStringSync())) {
        final shapes = [
          for (final s in string.allMatches(m[2]!)) dsParseSvgPath(s[1]!),
        ];
        final details = dsFillDetails(shapes);
        final fillable = dsFillable(shapes);
        for (final (i, shape) in shapes.indexed) {
          final points = dsSamplePoints(shape);
          if (details[i] || points.isEmpty) continue;
          for (final (j, other) in shapes.indexed) {
            if (j == i || details[j] || !fillable[j]) continue;
            // Lines that cross the outline (a calendar's rings) keep a
            // visible part; most of a line under the fill does not.
            final under = points.where(other.contains).length / points.length;
            if (under >= .85) hidden.add(m[1]!);
          }
        }
      }
    }
    expect(hidden, _accepted);
  });
}
