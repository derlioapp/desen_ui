import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/painting/shape.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders [decoration] on [background] (white; null for transparent) in
/// a [size] box at [topLeft], at [dpr]. Returns the RGBA bytes and the
/// image width.
Future<(ByteData, int)> render(
  WidgetTester tester,
  DsBoxDecoration decoration, {
  required double dpr,
  Offset topLeft = const Offset(10, 10),
  Size size = const Size(60, 40),
  Color? background = const Color(0xFFFFFFFF),
}) async {
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = const Size(100, 80) * dpr;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: ColoredBox(
        color: background ?? const Color(0x00000000),
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: size.width,
              height: size.height,
              child: DecoratedBox(decoration: decoration),
            ),
          ],
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!, width);
  }))!;
}

void main() {
  group('DsShape', () {
    RRect box(double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r));

    test('fully round boxes keep circular arcs', () {
      expect(DsShape(box(60, 20, 10)).circular, isTrue, reason: 'capsule');
      expect(DsShape(box(60, 20, 999)).circular, isTrue, reason: 'pill');
      expect(DsShape(box(30, 30, 15)).circular, isTrue, reason: 'circle');
      const half = Radius.circular(10);
      final band = RRect.fromRectAndCorners(
        const Rect.fromLTWH(0, 0, 40, 20),
        topLeft: half,
        bottomLeft: half,
      );
      expect(DsShape(band).circular, isTrue, reason: 'round band end');
    });

    test('other rounded boxes are continuous', () {
      expect(DsShape(box(60, 40, 10)).circular, isFalse);
      expect(DsShape(box(60, 20, 9)).circular, isFalse);
      expect(DsShape(box(16, 16, 5)).circular, isFalse, reason: 'checkbox');
    });

    test('inflating keeps the choice, so rings stay concentric', () {
      final capsule = DsShape(box(60, 20, 10));
      // Grown by 4 the radius (14) is under half the height (14): the
      // ring around a capsule must still be a capsule.
      expect(capsule.inflate(4).circular, isTrue);
      expect(DsShape(box(60, 40, 10)).inflate(30).circular, isFalse);
    });

    test('hit testing follows the superellipse', () {
      const size = Size(100, 100);
      const decoration = DsBoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      );
      final rse = RSuperellipse.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(30),
      );
      final rrect = RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(30),
      );
      var differs = 0;
      for (var y = 0.5; y < 30; y++) {
        for (var x = 0.5; x < 30; x++) {
          final p = Offset(x, y);
          expect(decoration.hitTest(size, p), rse.contains(p), reason: '$p');
          if (rse.contains(p) != rrect.contains(p)) differs++;
        }
      }
      expect(differs, greaterThan(0), reason: 'the corner is not circular');
    });
  });

  group('DsBoxDecoration', () {
    testWidgets('a capsule ring is a true capsule', (tester) async {
      // A 1px ring around a 60x20 pill: the ring is exactly 1px wide all the
      // way around, including the ends, as with a circle.
      const black = Color(0xFF000000);
      final (data, width) = await render(
        tester,
        const DsBoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(DsRadii.pill)),
          shadows: [DsShadow.ring(black)],
        ),
        dpr: 1,
        size: const Size(60, 20),
      );
      int at(int x, int y) => data.getUint8((y * width + x) * 4);
      // The leftmost point of the ring is the middle of the round end.
      expect(at(9, 20), lessThan(8), reason: 'ring at the end');
      expect(at(11, 20), greaterThan(247), reason: 'fill inside the end');
      // 45° on the round end, radius 10 around (20, 20): a circle puts the
      // ring at 10 + 0.5 px from the center.
      const d = 10.5 * 0.7071;
      expect(at((20 - d).floor(), (20 - d).floor()), lessThan(128));
    });
  });

  group('hairline', () {
    test('resolves to one device pixel and the same ink', () {
      const c = Color(0x1C000000); // alpha 0.11
      const ring = DsShadow.ring(c, hairline: true);
      expect(ring.resolve(1), const DsShadow.ring(c));
      final at2 = ring.resolve(2);
      expect(at2.spread, .5);
      expect(at2.hairline, isFalse);
      expect(at2.color.a, closeTo(1 - (1 - c.a) * (1 - c.a), 1e-6));
      final at3 = DsShadow.bottomLine(c, hairline: true).resolve(3);
      expect(at3.offset.dy, closeTo(-1 / 3, 1e-9));
      expect(at3.color.a, closeTo(.3, .01));
      // Opaque stays opaque.
      expect(
        const DsShadow.ring(
          Color(0xFF000000),
          hairline: true,
        ).resolve(3).color.a,
        1,
      );
    });

    for (final dpr in [2.0, 3.0]) {
      testWidgets('a hairline ring is one crisp device pixel at ${dpr}x', (
        tester,
      ) async {
        final (data, width) = await render(
          tester,
          const DsBoxDecoration(
            color: Color(0xFFFFFFFF),
            shadows: [DsShadow.ring(Color(0xFF000000), hairline: true)],
          ),
          dpr: dpr,
          topLeft: const Offset(10.3, 10.3),
        );
        final y = (30 * dpr).round();
        final row = [
          for (var x = 0; x < (20 * dpr).round(); x++)
            data.getUint8((y * width + x) * 4),
        ];
        expect(row.where((v) => v < 8), hasLength(1), reason: '$row');
        expect(row.where((v) => v >= 8 && v < 247), isEmpty, reason: '$row');
      });
    }

    Future<List<int>> column(
      WidgetTester tester,
      DsLine line,
      double dpr,
    ) async {
      tester.view
        ..devicePixelRatio = dpr
        ..physicalSize = const Size(40, 40) * dpr;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(devicePixelRatio: dpr),
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Padding(
                padding: const EdgeInsets.only(top: 10.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [line],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DsLine)).height, 1);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final width = image.width;
        image.dispose();
        // One pixel per row, from the middle column.
        return [
          for (var y = 0; y < image.height; y++)
            data!.getUint8((y * width + width ~/ 2) * 4),
        ];
      }))!;
    }

    for (final dpr in [2.0, 3.0]) {
      testWidgets('DsLine is one crisp device pixel at ${dpr}x', (
        tester,
      ) async {
        final rows = await column(
          tester,
          const DsLine(color: Color(0xFF000000)),
          dpr,
        );
        expect(rows.where((v) => v < 8), hasLength(1), reason: '$rows');
        expect(rows.where((v) => v >= 8 && v < 247), isEmpty);
      });
    }

    testWidgets('DsLine keeps a logical pixel when not a hairline', (
      tester,
    ) async {
      final rows = await column(
        tester,
        const DsLine(color: Color(0xFF000000), hairline: false),
        2,
      );
      expect(rows.where((v) => v < 8), hasLength(2), reason: '$rows');
      expect(rows.where((v) => v >= 8 && v < 247), isEmpty);
    });
  });

  group('a box draws all its pieces on one curve', () {
    // The engine's direct superellipse and a superellipse path trace
    // slightly different curves, so a fill and a ring that meet must take
    // the same one.
    List<String> calls(DsBoxDecoration d) {
      final canvas = _RecordingCanvas();
      d
          .createBoxPainter(() {})
          .paint(
            canvas,
            Offset.zero,
            const ImageConfiguration(size: Size(60, 40), devicePixelRatio: 2),
          );
      return canvas.calls;
    }

    const radius = BorderRadius.all(Radius.circular(12));
    const ink = Color(0xFF000000);

    test('an opaque fill with a flush ring: direct superellipses', () {
      final c = calls(
        const DsBoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: radius,
          shadows: [DsShadow.ring(ink)],
        ),
      );
      expect(c, ['drawRSuperellipse', 'drawRSuperellipse']);
    });

    test('a translucent fill with a ring: both paths', () {
      final c = calls(
        const DsBoxDecoration(
          color: Color(0x80FFFFFF),
          borderRadius: radius,
          shadows: [DsShadow.ring(ink)],
        ),
      );
      expect(c, ['drawPath', 'drawPath']);
    });

    test('a ring with a gap (focus): both paths', () {
      final c = calls(
        const DsBoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: radius,
          shadows: [DsShadow.outline(ink)],
        ),
      );
      expect(c, ['drawPath', 'drawPath']);
    });

    test('a blurred shadow takes a rounded rectangle', () {
      final c = calls(
        const DsBoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: radius,
          shadows: [DsShadow(color: ink, blur: 8)],
        ),
      );
      expect(c, ['drawRRect', 'drawRSuperellipse']);
    });

    test('a capsule stays a rounded rectangle', () {
      final c = calls(
        const DsBoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          shadows: [DsShadow.ring(ink)],
        ),
      );
      expect(c, ['drawRRect', 'drawRRect']);
    });
  });
}

/// Records the names of the drawing calls made on it.
class _RecordingCanvas implements Canvas {
  final calls = <String>[];

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, Paint paint) =>
      calls.add('drawRSuperellipse');

  @override
  void drawRRect(RRect rrect, Paint paint) => calls.add('drawRRect');

  @override
  void drawPath(Path path, Paint paint) => calls.add('drawPath');

  @override
  void drawRect(Rect rect, Paint paint) => calls.add('drawRect');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
