import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

class ImagePage extends StatelessWidget {
  const ImagePage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Data display',
    title: 'Image',
    lead:
        'A picture in a box whose size is known before the picture '
        'arrives, so the page never jumps when it loads. While it loads a '
        'skeleton fills the box; when it cannot load, a quiet crossed-out '
        'picture takes its place. For people, use an '
        '[Avatar](/components/avatar).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The same box in its three states: loading, loaded and '
            'unavailable. A picture that arrives late fades in briefly; one '
            'that is already decoded shows at once. Replay the load to see '
            'it again.',
          ),
          Example(snippet: 'image-overview', child: _StatesDemo()),
        ],
      ),
      DocSection(
        title: 'Reserved box',
        children: [
          DocText(
            'A `DsImage` needs `width` and `height`, or an `aspectRatio` '
            '(with at most one of them); it asserts otherwise. An '
            '`aspectRatio` alone takes the width its parent gives, which '
            'suits a card or a grid cell. `fit` decides how the picture '
            'fills the box; by default it covers it and is cropped.',
          ),
          Example(snippet: 'image-ratio', child: _RatioDemo()),
        ],
      ),
      DocSection(
        title: 'From the network',
        children: [
          DocText(
            '`DsImage.network(url, …)` is the plain case. Any '
            '`ImageProvider` works with the default constructor, so a '
            'caching provider from another package drops in unchanged.',
          ),
          CodeBlock(
            'DsImage.network(\n'
            '  album.coverUrl,\n'
            '  aspectRatio: 1,\n'
            '  semanticLabel: album.title,\n'
            ')',
          ),
          DocText(
            'The picture is decoded just large enough to cover the box at '
            'the screen\'s pixel density, not at full size: a 12 MP photo '
            'in a 160px tile costs a few hundred kilobytes of memory, not '
            'tens of megabytes. Turn it off with `resizeImage: false` when '
            'the same full-size picture is shown elsewhere.',
          ),
        ],
      ),
      DocSection(
        title: 'Fallback',
        children: [
          DocText(
            'Give `fallback` to show your own stand-in when the picture '
            'cannot load, such as initials for a missing logo or a '
            'placeholder cover. Pass `image: null` when there is no picture '
            'at all: the fallback shows at once, in the same box and '
            'corners, so a list of logos lines up whether they load or not.',
          ),
          Example(snippet: 'image-fallback', child: _FallbackDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Corners follow the theme: the radius of media inside a card, '
            'with continuous corners, the same in every state. Change them '
            'and the unavailable state\'s fill and icon with `style`, or '
            'for every image in a subtree with `DsImageTheme`. '
            '`BorderRadius.zero` makes the picture square, for one that '
            'bleeds to the edge of a card.',
          ),
          Example(snippet: 'image-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'With `semanticLabel`, the picture is announced as an image with '
                'that name. Without one it is decoration and screen readers '
                'skip it.',
            'When it cannot load, a named picture is announced with "Image '
                'unavailable", in the app\'s language. The state is shown by '
                'an icon, not by color.',
            'A `fallback` is announced by the picture\'s `semanticLabel`, '
                'not by its own text, and without "Image unavailable".',
            'The fade-in changes only opacity: nothing moves, also with '
                'reduced motion.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsImage'),
          ApiTable([
            (
              'image',
              'ImageProvider?',
              'Where the picture comes from; null when there is none.',
            ),
            ('width', 'double?', 'Box width.'),
            ('height', 'double?', 'Box height.'),
            (
              'aspectRatio',
              'double?',
              'Width divided by height; with at most one of width and '
                  'height.',
            ),
            ('fit', 'BoxFit', 'How the picture fills the box. `cover`.'),
            (
              'alignment',
              'AlignmentGeometry',
              'Where a cropped picture sits. Centered.',
            ),
            ('resizeImage', 'bool', 'Decodes at the box size. Default true.'),
            (
              'fallback',
              'Widget?',
              'Shown instead of the unavailable state: when the picture '
                  'fails, or `image` is null.',
            ),
            (
              'semanticLabel',
              'String?',
              'What the picture shows; null for decoration.',
            ),
            (
              'style',
              'DsImageStyle?',
              'Corners, and the unavailable state\'s fill and icon.',
            ),
          ]),
          DocText(
            '`DsImage.network(src, …)` takes the same box and look '
            'parameters, plus `scale` and `headers`.',
          ),
        ],
      ),
    ],
  );
}

class _StatesDemo extends StatefulWidget {
  const _StatesDemo();

  @override
  State<_StatesDemo> createState() => _StatesDemoState();
}

class _StatesDemoState extends State<_StatesDemo> {
  var _load = 0;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    Widget tile(String caption, Widget image) => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        image,
        Text(
          caption,
          style: t.typography.small.copyWith(color: t.colors.textMuted),
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            tile(
              'Loading',
              const DsImage(image: _Never(), width: 160, height: 120),
            ),
            tile(
              'Loaded',
              // #region image-overview
              DsImage(
                image: _Slow(_landscape, _load),
                width: 160,
                height: 120,
                semanticLabel: 'Hills under a low sun',
              ),
              // #endregion
            ),
            tile(
              'Unavailable',
              DsImage(
                image: MemoryImage(_broken),
                width: 160,
                height: 120,
                semanticLabel: 'Team photo',
              ),
            ),
          ],
        ),
        DsButton(
          variant: .secondary,
          size: .sm,
          onPressed: () => setState(() => _load++),
          child: const Text('Replay the load'),
        ),
      ],
    );
  }
}

class _RatioDemo extends StatelessWidget {
  const _RatioDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // #region image-ratio
            DsImage(
              image: MemoryImage(_landscape),
              aspectRatio: 16 / 9,
              semanticLabel: 'Hills under a low sun',
            ),
            // #endregion
            Text(
              'Weekend in the hills',
              style: t.typography.bodyStrong.copyWith(color: t.colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      // #region image-custom
      DsImage(
        image: MemoryImage(_landscape),
        width: 120,
        height: 120,
        style: const DsImageStyle(borderRadius: BorderRadius.zero),
      ),
      DsImage(
        image: MemoryImage(_landscape),
        width: 120,
        height: 120,
        style: DsImageStyle(borderRadius: BorderRadius.circular(DsRadii.pill)),
      ),
      // #endregion
    ],
  );
}

class _FallbackDemo extends StatelessWidget {
  const _FallbackDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    Widget initials(String text) => ColoredBox(
      color: t.colors.accentTint,
      child: Center(
        child: Text(
          text,
          style: t.typography.heading.copyWith(color: t.colors.accentText),
        ),
      ),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        // #region image-fallback
        // The picture fails to load: the initials take its place.
        DsImage(
          image: MemoryImage(_broken),
          width: 96,
          height: 96,
          semanticLabel: 'Radio Nova',
          fallback: initials('RN'),
        ),
        // No picture at all: the initials show at once.
        DsImage(
          image: null,
          width: 96,
          height: 96,
          semanticLabel: 'Jazz FM',
          fallback: initials('JF'),
        ),
        // #endregion
      ],
    );
  }
}

/// A picture that never arrives.
class _Never extends ImageProvider<_Never> {
  const _Never();

  @override
  Future<_Never> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Never key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

/// [bytes] after a second, as from a slow connection; a new [load] loads
/// again.
@immutable
class _Slow extends ImageProvider<_Slow> {
  const _Slow(this.bytes, this.load);

  final Uint8List bytes;
  final int load;

  @override
  Future<_Slow> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Slow key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: Future<void>.delayed(const Duration(seconds: 1)).then(
          (_) async => decode(await ui.ImmutableBuffer.fromUint8List(bytes)),
        ),
        scale: 1,
      );

  @override
  bool operator ==(Object other) =>
      other is _Slow && identical(other.bytes, bytes) && other.load == load;

  @override
  int get hashCode => Object.hash(identityHashCode(bytes), load);
}

/// Bytes that are not an image.
final _broken = Uint8List.fromList(const [0, 1, 2, 3]);

/// A 192 × 144 landscape as a BMP: a warm sky, a low sun and two hills.
final _landscape = () {
  const w = 192, h = 144, size = 54 + w * h * 3;
  final data = ByteData(size)
    ..setUint8(0, 0x42)
    ..setUint8(1, 0x4D)
    ..setUint32(2, size, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, w, Endian.little)
    ..setInt32(22, h, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, w * h * 3, Endian.little)
    ..setUint32(38, 2835, Endian.little)
    ..setUint32(42, 2835, Endian.little);
  const skyTop = Color(0xFF7FA7D9), skyLow = Color(0xFFF6C99A);
  const sun = Color(0xFFFFF1D0);
  const far = Color(0xFF6E8F7A), near = Color(0xFF3F6B55);
  var o = 54;
  int byte(double v) => (v * 255).round().clamp(0, 255);
  // Rows run bottom to top.
  for (var y = h - 1; y >= 0; y--) {
    for (var x = 0; x < w; x++) {
      var c = Color.lerp(skyTop, skyLow, y / h)!;
      final dx = x - 128.0, dy = y - 70.0;
      if (dx * dx + dy * dy <= 16 * 16) c = sun;
      if (y > 92 + 14 * math.sin(x / 26)) c = far;
      if (y > 112 + 10 * math.cos(x / 34 + 1)) c = near;
      data
        ..setUint8(o++, byte(c.b))
        ..setUint8(o++, byte(c.g))
        ..setUint8(o++, byte(c.r));
    }
  }
  return data.buffer.asUint8List();
}();
