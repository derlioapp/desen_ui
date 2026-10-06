import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Decodes [imageProvider] just large enough to cover a box of [width] ×
/// [height] logical pixels, as `BoxFit.cover` would draw it.
///
/// [ResizeImage] has no cover policy: fitting by width or by height
/// under-decodes a photo whose shape differs from the box, and the photo
/// then blurs when `BoxFit.cover` scales it up. This provider picks the
/// smallest scale at which both sides reach the box's physical size
/// (logical size × [ImageConfiguration.devicePixelRatio]) and never decodes
/// above the image's own size. A 4000×3000 photo in a 40px avatar at 3x
/// decodes to 160×120, not 12 MP.
///
/// The cache key holds the target size in physical pixels, so the same
/// photo at two sizes (or two pixel ratios) is cached twice, each small.
///
/// ```dart
/// Image(
///   image: DsCoverImage(NetworkImage(url), width: 40, height: 40),
///   fit: BoxFit.cover,
/// )
/// ```
///
/// Do not wrap a provider that already resizes ([ResizeImage] or another
/// [DsCoverImage]); only one decode size can apply.
@immutable
class DsCoverImage extends ImageProvider<DsCoverImageKey> {
  /// Decodes [imageProvider] to cover [width] × [height] logical pixels.
  const DsCoverImage(
    this.imageProvider, {
    required this.width,
    required this.height,
  }) : assert(width > 0 && height > 0);

  /// The provider whose image is decoded smaller.
  final ImageProvider imageProvider;

  /// Width of the box to cover, in logical pixels.
  final double width;

  /// Height of the box to cover, in logical pixels.
  final double height;

  /// The decode size that covers [targetWidth] × [targetHeight] (physical
  /// pixels) with an image of [intrinsicWidth] × [intrinsicHeight]: the
  /// aspect ratio is kept, both sides are at least the target, and neither
  /// grows past the intrinsic size.
  static ui.TargetImageSize coverSize(
    int intrinsicWidth,
    int intrinsicHeight,
    int targetWidth,
    int targetHeight,
  ) {
    if (intrinsicWidth <= 0 ||
        intrinsicHeight <= 0 ||
        (targetWidth >= intrinsicWidth || targetHeight >= intrinsicHeight)) {
      // Covering needs the full image on at least one side: no reduction.
      return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
    }
    // The side whose ratio target/intrinsic is larger sets the scale; the
    // other side is rounded up (exact integer math) so it still covers.
    if (targetWidth * intrinsicHeight >= targetHeight * intrinsicWidth) {
      final h = _ceilDiv(intrinsicHeight * targetWidth, intrinsicWidth);
      return ui.TargetImageSize(
        width: targetWidth,
        height: math.min(h, intrinsicHeight),
      );
    }
    final w = _ceilDiv(intrinsicWidth * targetHeight, intrinsicHeight);
    return ui.TargetImageSize(
      width: math.min(w, intrinsicWidth),
      height: targetHeight,
    );
  }

  static int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

  @override
  Future<DsCoverImageKey> obtainKey(ImageConfiguration configuration) {
    // ds-raw: the pixel ratio Image assumes without a MediaQuery
    final ratio = configuration.devicePixelRatio ?? 1.0;
    final physicalWidth = math.max(1, (width * ratio).ceil());
    final physicalHeight = math.max(1, (height * ratio).ceil());
    // Same shape as ResizeImage.obtainKey: stay synchronous when the
    // wrapped provider's key is.
    Completer<DsCoverImageKey>? completer;
    SynchronousFuture<DsCoverImageKey>? result;
    imageProvider.obtainKey(configuration).then((Object key) {
      final coverKey = DsCoverImageKey._(key, physicalWidth, physicalHeight);
      if (completer == null) {
        result = SynchronousFuture<DsCoverImageKey>(coverKey);
      } else {
        completer.complete(coverKey);
      }
    });
    if (result != null) return result!;
    completer = Completer<DsCoverImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(
    DsCoverImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeCover(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      assert(
        getTargetSize == null,
        'DsCoverImage cannot wrap a provider that sets its own decode size '
        '(ResizeImage, cacheWidth/cacheHeight or another DsCoverImage).',
      );
      return decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) =>
            coverSize(intrinsicWidth, intrinsicHeight, key.width, key.height),
      );
    }

    final completer = imageProvider.loadImage(
      key._providerCacheKey,
      decodeCover,
    );
    if (!kReleaseMode) {
      completer.debugLabel =
          '${completer.debugLabel} - Cover(${key.width}×${key.height})';
    }
    // As ResizeImage: a failed load must not stay cached under this key.
    completer.addEphemeralErrorListener((exception, stackTrace) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
    });
    return completer;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is DsCoverImage &&
        other.imageProvider == imageProvider &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(imageProvider, width, height);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'DsCoverImage')}'
      '($imageProvider, ${width}x$height)';
}

/// The [ImageCache] key of a [DsCoverImage]: the wrapped provider's key and
/// the target size in physical pixels.
@immutable
class DsCoverImageKey {
  // Private, like ResizeImageKey, so nothing outside can poison the cache
  // with it.
  const DsCoverImageKey._(this._providerCacheKey, this.width, this.height);

  final Object _providerCacheKey;

  /// Width of the box to cover, in physical pixels.
  final int width;

  /// Height of the box to cover, in physical pixels.
  final int height;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is DsCoverImageKey &&
        other._providerCacheKey == _providerCacheKey &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(_providerCacheKey, width, height);

  @override
  String toString() => 'DsCoverImageKey($_providerCacheKey, ${width}x$height)';
}
