import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/foundation/svg_path.dart';
import 'package:flutter_test/flutter_test.dart';

void expectBounds(Path p, Rect r) {
  final b = p.getBounds();
  for (final (got, want) in [
    (b.left, r.left),
    (b.top, r.top),
    (b.right, r.right),
    (b.bottom, r.bottom),
  ]) {
    expect(got, closeTo(want, 0.05));
  }
}

void main() {
  test('absolute and relative lines', () {
    expectBounds(
      dsParseSvgPath('M5 12h14'),
      const Rect.fromLTRB(5, 12, 19, 12),
    );
    expectBounds(
      dsParseSvgPath('m6 9 6 6 6-6'),
      const Rect.fromLTRB(6, 9, 18, 15),
    );
    expectBounds(
      dsParseSvgPath('M20 6 9 17l-5-5'),
      const Rect.fromLTRB(4, 6, 20, 17),
    );
  });

  test('arcs draw full circles', () {
    expectBounds(
      dsParseSvgPath('M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0'),
      const Rect.fromLTRB(2, 2, 22, 22),
    );
  });

  test('compact arc flags parse like spaced ones', () {
    expectBounds(
      dsParseSvgPath('M0 0a5 5 0 105 5'),
      dsParseSvgPath('M0 0 a 5 5 0 1 0 5 5').getBounds(),
    );
    expectBounds(
      dsParseSvgPath('M1e1 0L2e1 0'),
      const Rect.fromLTRB(10, 0, 20, 0),
    );
  });

  test('smooth curves reflect the previous control point', () {
    final p = dsParseSvgPath('M0 0C0 10 10 10 10 0S20 -10 20 0');
    expect(p.getBounds().top, lessThan(0));
    expect(p.getBounds().bottom, greaterThan(0));
  });

  test('every built-in icon parses inside its 24×24 box', () {
    for (final icon in [
      DsIcons.plus,
      DsIcons.check,
      DsIcons.x,
      DsIcons.chevronDown,
      DsIcons.ellipsis, //
      DsIcons.search, DsIcons.circleAlert, DsIcons.mail, DsIcons.calendar,
      DsIcons.layoutGrid, DsIcons.list, DsIcons.bold, DsIcons.triangleAlert,
      DsIcons.eye, DsIcons.eyeOff,
    ]) {
      final b = icon.path.getBounds();
      expect(b.left, greaterThanOrEqualTo(0));
      expect(b.top, greaterThanOrEqualTo(0));
      expect(b.right, lessThanOrEqualTo(24));
      expect(b.bottom, lessThanOrEqualTo(24));
      expect(b.isEmpty && b.width == 0 && b.height == 0, isFalse);
    }
  });

  test('rejects garbage', () {
    expect(() => dsParseSvgPath('12 12'), throwsFormatException);
  });

  // Shortcut hints can draw modifier keys as icons instead of
  // ⌘ ⌥ ⇧ ⌫ ⏎ glyphs the bundled fonts lack.
  test('keyboard key icons fit their 24px box', () {
    for (final icon in [
      DsIcons.command,
      DsIcons.option,
      DsIcons.arrowBigUp,
      DsIcons.backspace,
      DsIcons.enter,
    ]) {
      for (final d in icon.paths) {
        final b = dsParseSvgPath(d).getBounds();
        expect(b.isEmpty && b.width == 0 && b.height == 0, isFalse);
        expect(
          const Rect.fromLTRB(0, 0, 24, 24).inflate(.01).contains(b.topLeft),
          isTrue,
        );
        expect(
          const Rect.fromLTRB(
            0,
            0,
            24,
            24,
          ).inflate(.01).contains(b.bottomRight),
          isTrue,
        );
      }
    }
  });
}
