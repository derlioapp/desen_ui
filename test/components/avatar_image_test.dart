import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A [width] × [height] PNG.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Avatar photos are decoded at the avatar's size, covering the circle.
void main() {
  (int, int) cover(int w, int h, int tw, int th) {
    final s = DsCoverImage.coverSize(w, h, tw, th);
    return (s.width!, s.height!);
  }

  group('coverSize', () {
    test('portrait, landscape and square photos cover the box', () {
      expect(cover(3000, 4000, 120, 120), (120, 160));
      expect(cover(4000, 3000, 120, 120), (160, 120));
      expect(cover(1000, 1000, 120, 120), (120, 120));
      // A non-square box: the side with the larger ratio sets the scale.
      expect(cover(4000, 3000, 300, 100), (300, 225));
      expect(cover(3000, 4000, 100, 300), (225, 300));
    });

    test('rounds up so both sides still cover', () {
      final (w, h) = cover(1000, 333, 120, 120);
      expect(h, 120);
      expect(w, 361, reason: '1000 × 120 / 333 = 360.4, rounded up');
      for (final (iw, ih) in [(997, 1013), (1013, 997), (641, 479)]) {
        final (w, h) = cover(iw, ih, 97, 97);
        expect(w >= 97 && h >= 97, isTrue, reason: '$iw×$ih → $w×$h');
        // And it is the smallest such size: one pixel less would not cover.
        expect(w == 97 || h == 97, isTrue);
      }
    });

    test('never upscales', () {
      expect(cover(100, 80, 120, 120), (100, 80));
      expect(cover(120, 120, 120, 120), (120, 120));
      // Covering needs the full height already, so nothing is reduced.
      expect(cover(400, 100, 120, 120), (400, 100));
      expect(cover(100, 400, 120, 120), (100, 400));
    });
  });

  group('cache key', () {
    final source = MemoryImage(Uint8List.fromList(const [1, 2, 3]));

    Future<Object> keyOf(ImageProvider p, double ratio) =>
        p.obtainKey(ImageConfiguration(devicePixelRatio: ratio));

    test('holds the target size in physical pixels', () async {
      final a = await keyOf(DsCoverImage(source, width: 40, height: 40), 2);
      final b = await keyOf(DsCoverImage(source, width: 40, height: 40), 2);
      final bigger = await keyOf(
        DsCoverImage(source, width: 48, height: 48),
        2,
      );
      final denser = await keyOf(
        DsCoverImage(source, width: 40, height: 40),
        3,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(bigger));
      expect(a, isNot(denser));
      expect(a, isNot(await keyOf(source, 2)));
      expect((a as DsCoverImageKey).width, 80);
      expect((denser as DsCoverImageKey).height, 120);
    });

    test('providers compare by source and size', () {
      expect(
        DsCoverImage(source, width: 40, height: 40),
        DsCoverImage(source, width: 40, height: 40),
      );
      expect(
        DsCoverImage(source, width: 40, height: 40),
        isNot(DsCoverImage(source, width: 32, height: 32)),
      );
    });
  });

  group('DsAvatar', () {
    Future<ui.Image> decoded(WidgetTester tester, Widget avatar) async {
      await tester.pumpWidget(host(avatar));
      // Decoding happens off the fake clock.
      await tester.runAsync(() async {
        final element = tester.element(find.byType(Image));
        final image = tester.widget<Image>(find.byType(Image)).image;
        await precacheImage(image, element);
      });
      await tester.pump();
      return tester.widget<RawImage>(find.byType(RawImage)).image!;
    }

    testWidgets('decodes a photo at the avatar size × pixel ratio', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = (await tester.runAsync(() => _png(600, 400)))!;
      final image = await decoded(
        tester,
        DsAvatar(initials: 'AB', image: MemoryImage(bytes)),
      );
      // 40px at 3x is 120; a 3:2 photo covers it at 180×120.
      expect((image.width, image.height), (180, 120));
    });

    testWidgets('resizeImage: false decodes at full size', (tester) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = (await tester.runAsync(() => _png(600, 400)))!;
      final image = await decoded(
        tester,
        DsAvatar(initials: 'AB', image: MemoryImage(bytes), resizeImage: false),
      );
      expect((image.width, image.height), (600, 400));
    });

    testWidgets('a provider that resizes itself is left alone', (tester) async {
      final bytes = (await tester.runAsync(() => _png(600, 400)))!;
      await tester.pumpWidget(
        host(DsAvatar(image: ResizeImage(MemoryImage(bytes), width: 50))),
      );
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>(),
      );
    });

    testWidgets('a failed photo still falls back to initials', (tester) async {
      final broken = MemoryImage(Uint8List.fromList(const [0, 1, 2, 3, 4]));
      await tester.pumpWidget(host(DsAvatar(initials: 'AB', image: broken)));
      final provider = tester.widget<Image>(find.byType(Image)).image;
      expect(provider, isA<DsCoverImage>());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('AB'), findsOneWidget);
      // The failure is not cached under the cover key.
      final key = await provider.obtainKey(
        createLocalImageConfiguration(tester.element(find.byType(Image))),
      );
      expect(PaintingBinding.instance.imageCache.containsKey(key), isFalse);
    });
  });
}
