import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A box at a fractional position must still draw its 1px
/// ring on whole device pixels, without a gray smear.
Future<List<int>> leftEdgeRow(WidgetTester tester, double dpr) async {
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = Size(200 * dpr, 100 * dpr);
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            Positioned(
              left: 10.3,
              top: 10.3,
              width: 40,
              height: 20,
              child: DecoratedBox(
                decoration: DsBoxDecoration(
                  color: Color(0xFFFFFFFF),
                  shadows: [DsShadow.ring(Color(0xFF000000))],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!, width);
  }))!;
  final (data, width) = bytes;
  final y = (20 * dpr).round();
  return [
    for (var x = 0; x < (20 * dpr).round(); x++)
      data.getUint8((y * width + x) * 4),
  ];
}

void main() {
  for (final dpr in [1.0, 2.0]) {
    testWidgets('1px ring is crisp at ${dpr}x on a fractional offset', (
      tester,
    ) async {
      final row = await leftEdgeRow(tester, dpr);
      final gray = [
        for (final v in row)
          if (v > 8 && v < 247) v,
      ];
      expect(gray, isEmpty, reason: 'blended edge pixels in $row');
      expect(row, contains(lessThan(8)), reason: 'ring missing in $row');
    });
  }
}
