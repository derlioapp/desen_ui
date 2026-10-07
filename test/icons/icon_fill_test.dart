import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws [icon] black at 24px on white and returns the alpha-blended
/// darkness (0 white, 1 black) of the pixel at [at].
Future<double> _inkAt(WidgetTester tester, Widget icon, Offset at) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: SizedBox.square(dimension: 24, child: icon),
          ),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final i = (at.dy.floor() * image.width + at.dx.floor()) * 4;
    return 1 - data!.getUint8(i) / 255;
  }))!;
}

const _black = Color(0xFF000000);

// A 16-unit square outline, and a line across the middle.
const _square = DsIconData(['M4 4h16v16H4z']);
const _line = DsIconData(['M4 12h16']);

void main() {
  testWidgets('an outlined icon leaves its inside empty', (tester) async {
    final ink = await _inkAt(
      tester,
      const DsIcon(_square, size: 24, color: _black),
      const Offset(12, 12),
    );
    expect(ink, lessThan(.05));
  });

  testWidgets('a filled icon paints its inside', (tester) async {
    final ink = await _inkAt(
      tester,
      const DsIcon(
        DsIconData(['M4 4h16v16H4z'], fill: true),
        size: 24,
        color: _black,
      ),
      const Offset(12, 12),
    );
    expect(ink, greaterThan(.95));
  });

  testWidgets('DsIcon.fill fills an outlined icon, and can turn fill off', (
    tester,
  ) async {
    expect(
      await _inkAt(
        tester,
        const DsIcon(_square, size: 24, color: _black, fill: true),
        const Offset(12, 12),
      ),
      greaterThan(.95),
    );
    expect(
      await _inkAt(
        tester,
        const DsIcon(
          DsIconData(['M4 4h16v16H4z'], fill: true),
          size: 24,
          color: _black,
          fill: false,
        ),
        const Offset(12, 12),
      ),
      lessThan(.05),
    );
  });

  testWidgets('each path fills on its own, like separate SVG elements', (
    tester,
  ) async {
    // The inner square winds the other way. Filled as one path it would
    // cut a hole; as two elements it is covered.
    final ink = await _inkAt(
      tester,
      const DsIcon(
        DsIconData(['M2 2h20v20H2z', 'M8 8v8h8V8z'], fill: true),
        size: 24,
        color: _black,
      ),
      const Offset(12, 12),
    );
    expect(ink, greaterThan(.95));
  });

  testWidgets('a detail inside a filled shape is cut out of the fill', (
    tester,
  ) async {
    // A line across a square: drawn in ink it would vanish into the fill.
    const icon = DsIconData(['M2 2h20v20H2z', 'M7 12h10'], fill: true);
    Future<double> at(Offset p) =>
        _inkAt(tester, const DsIcon(icon, size: 24, color: _black), p);
    expect(await at(const Offset(12, 12)), lessThan(.05));
    expect(await at(const Offset(12, 6)), greaterThan(.95));
  });

  testWidgets('a mark in a circle drawn as two arcs is cut out too', (
    tester,
  ) async {
    // Circles end where they start without a closing command.
    const icon = DsIconData([
      'M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0',
      'M10 12h4',
    ], fill: true);
    Future<double> at(Offset p) =>
        _inkAt(tester, const DsIcon(icon, size: 24, color: _black), p);
    expect(await at(const Offset(12, 12)), lessThan(.05));
    expect(await at(const Offset(12, 5)), greaterThan(.95));
  });

  testWidgets('a part that reaches outside the shape stays ink', (
    tester,
  ) async {
    // Like a calendar's binding rings over its top edge.
    const icon = DsIconData(['M4 6h16v14H4z', 'M8 2v6'], fill: true);
    expect(
      await _inkAt(
        tester,
        const DsIcon(icon, size: 24, color: _black),
        const Offset(8, 7),
      ),
      greaterThan(.95),
    );
  });

  testWidgets('an open stroke stays a stroke, not a wedge', (tester) async {
    // A chart's axes: filled, the open corner would close into a triangle.
    expect(
      await _inkAt(
        tester,
        const DsIcon(
          DsIconData(['M3 3v16h16'], fill: true),
          size: 24,
          color: _black,
        ),
        const Offset(8, 15),
      ),
      lessThan(.05),
    );
  });

  testWidgets('a filled open line looks like the outlined one', (tester) async {
    for (final at in const [Offset(12, 6), Offset(12, 18)]) {
      expect(
        await _inkAt(
          tester,
          const DsIcon(_line, size: 24, color: _black, fill: true),
          at,
        ),
        lessThan(.05),
      );
    }
    expect(
      await _inkAt(
        tester,
        const DsIcon(_line, size: 24, color: _black, fill: true),
        const Offset(12, 12),
      ),
      greaterThan(.5),
    );
  });

  test('fill is part of the icon data\'s identity', () {
    expect(
      const DsIconData(['M4 4h16v16H4z'], fill: true),
      isNot(const DsIconData(['M4 4h16v16H4z'])),
    );
    expect(
      const DsIconData(['M4 4h16v16H4z'], fill: true).hashCode,
      isNot(const DsIconData(['M4 4h16v16H4z']).hashCode),
    );
  });
}
