import 'dart:async';
import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
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

/// An image that never arrives: the loading state for as long as a test
/// needs.
class _Pending extends ImageProvider<_Pending> {
  const _Pending();

  @override
  Future<_Pending> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Pending key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

/// An image that fails to load.
class _Broken extends ImageProvider<_Broken> {
  const _Broken();

  @override
  Future<_Broken> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Broken key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('offline')),
      );
}

void main() {
  final theme = DsThemeData.light();

  Finder errorIcon() =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.imageOff);

  group('reserved box', () {
    testWidgets('width and height size the box while loading', (tester) async {
      await tester.pumpWidget(
        host(const DsImage(image: _Pending(), width: 120, height: 80)),
      );
      expect(tester.getSize(find.byType(DsImage)), const Size(120, 80));
    });

    testWidgets('an aspect ratio sizes the box from the width', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DsImage(image: _Pending(), aspectRatio: 2),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DsImage)), const Size(200, 100));
      await tester.pumpWidget(
        host(const DsImage(image: _Pending(), aspectRatio: 1.5, height: 60)),
      );
      expect(tester.getSize(find.byType(DsImage)), const Size(90, 60));
    });

    testWidgets('loading, loaded and failed all keep the box', (tester) async {
      await tester.pumpWidget(
        host(const DsImage(image: _Broken(), width: 120, height: 80)),
      );
      expect(tester.getSize(find.byType(DsImage)), const Size(120, 80));
      await tester.pump();
      expect(errorIcon(), findsOneWidget);
      expect(tester.getSize(find.byType(DsImage)), const Size(120, 80));
    });

    test('a box is required', () {
      expect(() => DsImage(image: const _Pending()), throwsAssertionError);
      expect(
        () => DsImage(image: const _Pending(), width: 100),
        throwsAssertionError,
      );
      expect(
        () => DsImage(
          image: const _Pending(),
          width: 100,
          height: 100,
          aspectRatio: 1,
        ),
        throwsAssertionError,
      );
    });
  });

  group('states', () {
    testWidgets('loading shows a skeleton filling the box', (tester) async {
      await tester.pumpWidget(
        host(
          const DsImage(image: _Pending(), width: 120, height: 80),
          theme: theme,
        ),
      );
      expect(find.byType(DsSkeleton), findsOneWidget);
      expect(tester.getSize(find.byType(DsSkeleton)), const Size(120, 80));
      expect(errorIcon(), findsNothing);
    });

    testWidgets('a failure shows the crossed-out picture on a channel fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DsImage(image: _Broken(), width: 120, height: 80),
          theme: theme,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(DsSkeleton), findsNothing);
      final icon = tester.widget<DsIcon>(errorIcon());
      expect(icon.color, theme.colors.textSubtle);
      expect(icon.size, theme.sizes.iconLg);
      final fill = tester.widget<DecoratedBox>(
        find.ancestor(of: errorIcon(), matching: find.byType(DecoratedBox)),
      );
      expect((fill.decoration as DsBoxDecoration).color, theme.colors.channel);
    });

    testWidgets('a box smaller than the icon shrinks it', (tester) async {
      await tester.pumpWidget(
        host(const DsImage(image: _Broken(), width: 12, height: 12)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(errorIcon()).width, lessThanOrEqualTo(12));
    });

    testWidgets('a picture loading late fades in over the skeleton', (
      tester,
    ) async {
      final bytes = (await tester.runAsync(() => _png(40, 40)))!;
      await tester.pumpWidget(
        host(
          DsImage(
            image: MemoryImage(bytes),
            width: 40,
            height: 40,
            resizeImage: false,
          ),
          theme: theme,
        ),
      );
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(DsImage),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;
      expect(opacity(), 0);
      expect(find.byType(DsSkeleton), findsOneWidget);
      await tester.runAsync(() async {
        await precacheImage(
          MemoryImage(bytes),
          tester.element(find.byType(Image)),
        );
      });
      await tester.pump();
      expect(opacity(), 1);
      // The skeleton stays under the picture until the fade is over.
      expect(find.byType(DsSkeleton), findsOneWidget);
      final fade = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(DsImage),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(fade.duration, theme.motion.toneDuration);
      await tester.pumpAndSettle();
      expect(find.byType(DsSkeleton), findsNothing);
    });

    testWidgets('a decoded picture shows at once, with no skeleton', (
      tester,
    ) async {
      final bytes = (await tester.runAsync(() => _png(40, 40)))!;
      final provider = MemoryImage(bytes);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.runAsync(
        () => precacheImage(provider, tester.element(find.byType(SizedBox))),
      );
      await tester.pumpWidget(
        host(
          DsImage(image: provider, width: 40, height: 40, resizeImage: false),
        ),
      );
      expect(find.byType(DsSkeleton), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('decode size', () {
    testWidgets('decodes to cover the box', (tester) async {
      await tester.pumpWidget(
        host(const DsImage(image: _Pending(), width: 120, height: 80)),
      );
      final provider = tester.widget<Image>(find.byType(Image)).image;
      expect(provider, isA<DsCoverImage>());
      provider as DsCoverImage;
      expect((provider.width, provider.height), (120.0, 80.0));
    });

    testWidgets('a smaller box keeps the larger decode', (tester) async {
      Widget at(double w) => host(
        SizedBox(
          width: w,
          child: const DsImage(image: _Pending(), aspectRatio: 1),
        ),
      );
      await tester.pumpWidget(at(200));
      await tester.pumpWidget(at(100));
      final provider =
          tester.widget<Image>(find.byType(Image)).image as DsCoverImage;
      expect(provider.width, 200);
      await tester.pumpWidget(at(300));
      expect(
        (tester.widget<Image>(find.byType(Image)).image as DsCoverImage).width,
        300,
      );
    });

    testWidgets('resizeImage: false and self-resizing providers are left '
        'alone', (tester) async {
      await tester.pumpWidget(
        host(
          const DsImage(
            image: _Pending(),
            width: 120,
            height: 80,
            resizeImage: false,
          ),
        ),
      );
      expect(tester.widget<Image>(find.byType(Image)).image, isA<_Pending>());
      await tester.pumpWidget(
        host(
          const DsImage(
            image: ResizeImage(_Pending(), width: 50),
            width: 120,
            height: 80,
          ),
        ),
      );
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>(),
      );
    });
  });

  group('corners', () {
    testWidgets('the radius of media inside a card, in every state', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DsImage(image: _Pending(), width: 120, height: 80),
          theme: theme,
        ),
      );
      final clip = tester.widget<DsShapeClip>(
        find.descendant(
          of: find.byType(DsImage),
          matching: find.byType(DsShapeClip),
        ),
      );
      expect(
        clip.borderRadius,
        BorderRadius.circular(
          theme.radii.nested(theme.radii.card, DsSpace.s16),
        ),
      );
    });

    testWidgets('style and theme set the corners', (tester) async {
      await tester.pumpWidget(
        host(
          const DsImageTheme(
            data: DsImageThemeData(
              style: DsImageStyle(borderRadius: BorderRadius.zero),
            ),
            child: DsImage(image: _Pending(), width: 120, height: 80),
          ),
          theme: theme,
        ),
      );
      expect(
        tester.widget<DsShapeClip>(find.byType(DsShapeClip)).borderRadius,
        BorderRadius.zero,
      );
    });
  });

  group('semantics', () {
    testWidgets('a labeled image is an image node with its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DsImage(
            image: _Pending(),
            width: 120,
            height: 80,
            semanticLabel: 'Album cover',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsImage)),
        isSemantics(label: 'Album cover', isImage: true),
      );
      semantics.dispose();
    });

    testWidgets('a failed image says it is unavailable', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DsImage(
            image: _Broken(),
            width: 120,
            height: 80,
            semanticLabel: 'Album cover',
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(DsImage)),
        isSemantics(
          label: 'Album cover',
          value: 'Image unavailable',
          isImage: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('an unlabeled image is decoration, also when it fails', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DsImage(image: _Broken(), width: 120, height: 80)),
      );
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DsImage),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      semantics.dispose();
    });
  });

  testWidgets('DsImage.network loads a NetworkImage', (tester) async {
    final image = DsImage.network(
      'https://example.com/a.png',
      width: 10,
      height: 10,
      headers: const {'x': 'y'},
    );
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, 'https://example.com/a.png');
    expect((image.image as NetworkImage).headers, {'x': 'y'});
  });

  testWidgets('localized in the app language', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      DsLocalizationScope(
        localizations: DsLocalizations.resolve(const Locale('tr')),
        child: host(
          const DsImage(
            image: _Broken(),
            width: 120,
            height: 80,
            semanticLabel: 'Kapak',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(DsImage)),
      isSemantics(label: 'Kapak', value: 'Görsel yüklenemedi', isImage: true),
    );
    semantics.dispose();
  });
}
