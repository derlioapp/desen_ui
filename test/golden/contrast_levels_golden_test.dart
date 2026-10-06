@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contrast_board.dart';
import 'golden_harness.dart';

/// The two contrast levels side by side on one app-like board (soft,
/// standard), light and dark: soft is the calm iOS look, standard the crisp
/// default.
void main() {
  for (final b in Brightness.values) {
    testWidgets('contrast levels ${b.name}', (tester) async {
      await pumpContrastBoard(
        tester,
        brightness: b,
        contrasts: DsContrast.values,
      );
      await expectGolden(tester, 'goldens/contrast_levels_${b.name}.png');
    });
  }
}
