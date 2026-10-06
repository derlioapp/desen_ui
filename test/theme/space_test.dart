import 'package:desen_ui/desen_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the spacing scale keeps a 4px rhythm into the layout steps', () {
    const steps = [
      DsSpace.s4,
      DsSpace.s8,
      DsSpace.s12,
      DsSpace.s16,
      DsSpace.s20,
      DsSpace.s24,
      DsSpace.s28,
      DsSpace.s32,
      DsSpace.s40,
      DsSpace.s48,
      DsSpace.s64,
    ];
    expect(steps, [4, 8, 12, 16, 20, 24, 28, 32, 40, 48, 64]);
    for (final s in steps) {
      expect(s % 4, 0, reason: '$s is off the 4px rhythm');
    }
  });
}
