import 'dart:math' as math;
import 'dart:ui' show Color, Offset, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../foundation/color_utils.dart';

/// A box shadow that can also be drawn inside the box, like CSS
/// `box-shadow: inset …`.
///
/// Desen draws most edges with shadows instead of borders: a 1px ring is a
/// shadow with `spread: 1, blur: 0`, which follows rounded corners exactly
/// and does not take up layout space. Inset shadows draw field outlines,
/// top highlights and the inner part of the focus ring.
///
/// Decorative edges (card and layer edges, separators) are [hairline]s:
/// one device pixel wide instead of one logical pixel, which keeps them
/// crisp on high-density screens.
@immutable
class DsShadow {
  /// Creates a shadow. Values follow CSS `box-shadow` semantics.
  // ds-raw: the class itself, not a use of it
  const DsShadow({
    required this.color,
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
    this.inset = false,
    this.hairline = false,
  }) : gap = 0;

  /// A crisp ring of [width] around the outside of the box. With
  /// [hairline], [width] counts device pixels.
  const DsShadow.ring(this.color, {double width = 1, this.hairline = false})
    : offset = Offset.zero,
      blur = 0,
      spread = width,
      inset = false,
      gap = 0;

  /// A crisp ring of [width] drawn [gap] away from the box, with a
  /// transparent gap, like CSS `outline` with `outline-offset`. Used for
  /// focus rings so they look right on any background.
  ///
  /// A negative [gap] moves the ring inward, as a negative
  /// `outline-offset` does: `gap: -1` with `width: 2` centers the ring on
  /// the box edge, so it covers a 1px border drawn inside or outside the
  /// box. Its inner part lies over the fill, so draw such a ring above it
  /// (for example in a foreground decoration).
  const DsShadow.outline(this.color, {double width = 2, this.gap = 2})
    : offset = Offset.zero,
      blur = 0,
      spread = width,
      inset = false,
      hairline = false;

  /// A crisp ring of [width] along the inside edge of the box. With
  /// [hairline], [width] counts device pixels.
  const DsShadow.innerRing(
    this.color, {
    double width = 1,
    this.hairline = false,
  }) : offset = Offset.zero,
       blur = 0,
       spread = width,
       inset = true,
       gap = 0;

  /// A hairline along the inside of the bottom edge, like CSS
  /// `box-shadow: inset 0 -1px 0`: separates a header from its content
  /// without taking layout space. With [hairline], [width] counts device
  /// pixels.
  DsShadow.bottomLine(this.color, {double width = 1, this.hairline = false})
    : offset = Offset(0, -width),
      blur = 0,
      spread = 0,
      inset = true,
      gap = 0;

  /// A hairline along the inside of the top edge (`inset 0 1px 0`). With
  /// [hairline], [width] counts device pixels.
  DsShadow.topLine(this.color, {double width = 1, this.hairline = false})
    : offset = Offset(0, width),
      blur = 0,
      spread = 0,
      inset = true,
      gap = 0;

  const DsShadow._raw(
    this.color,
    this.offset,
    this.blur,
    this.spread,
    this.inset,
    this.gap,
    this.hairline,
  );

  /// Shadow color.
  final Color color;

  /// Shadow offset.
  final Offset offset;

  /// Blur radius, as in CSS.
  final double blur;

  /// Spread distance. Positive grows an outer shadow; for an inset shadow it
  /// grows the shadow inward.
  final double spread;

  /// Whether the shadow is drawn inside the box.
  final bool inset;

  /// Transparent space between the box and an outline ring; negative
  /// moves the ring over the box edge. Only used by [DsShadow.outline];
  /// other shadows start at the box edge.
  final double gap;

  /// Whether the lengths ([offset], [spread], [gap], [blur]) count device
  /// pixels rather than logical ones.
  ///
  /// For decorative lines such as card edges and separators: a ring of
  /// width 1 is one device pixel wide on any screen. So that it reads as
  /// strong as a one-logical-pixel line of the same color, its color is
  /// made more opaque: it carries as much ink as the wider line would (on
  /// a 2x screen alpha 0.11 paints as 0.21, on 3x as 0.30). At 1x, or
  /// below, it paints exactly like a regular shadow. An opaque color stays
  /// opaque, so its line just gets thinner.
  final bool hairline;

  /// This shadow as painted at [devicePixelRatio]: a [hairline] with its
  /// lengths in logical pixels and its color strengthened; any other
  /// shadow unchanged.
  DsShadow resolve(double devicePixelRatio) {
    if (!hairline) return this;
    if (devicePixelRatio <= 1) return copyWith(hairline: false);
    final k = 1 / devicePixelRatio;
    return DsShadow._raw(
      hairlineColor(color, devicePixelRatio),
      offset * k,
      blur * k,
      spread * k,
      inset,
      gap * k,
      false,
    );
  }

  /// [color] strengthened for a line one device pixel wide, so that it
  /// carries as much ink as a one-logical-pixel line of [color]: the alpha
  /// of `devicePixelRatio` such lines stacked, `1 - (1 - a)^dpr`. At 1x or
  /// below, [color] itself.
  static Color hairlineColor(Color color, double devicePixelRatio) {
    if (devicePixelRatio <= 1 || color.a >= 1) return color;
    final ink = 1 - math.pow(1 - color.a, devicePixelRatio).toDouble();
    return color.withValues(alpha: ink);
  }

  /// Whether this is an outline ring (a nonzero [gap]) rather than a
  /// regular shadow.
  bool get isOutline => gap != 0;

  /// The Gaussian sigma for [blur], matching [Shadow.blurSigma].
  double get blurSigma => Shadow.convertRadiusToSigma(blur);

  /// Returns a copy with the given fields replaced.
  DsShadow copyWith({
    Color? color,
    Offset? offset,
    double? blur,
    double? spread,
    bool? inset,
    double? gap,
    bool? hairline,
  }) => DsShadow._raw(
    color ?? this.color,
    offset ?? this.offset,
    blur ?? this.blur,
    spread ?? this.spread,
    inset ?? this.inset,
    gap ?? this.gap,
    hairline ?? this.hairline,
  );

  /// Linearly interpolates between two shadows.
  ///
  /// A missing end fades to a transparent copy of the other, so shadows can
  /// appear and disappear smoothly.
  static DsShadow? lerp(DsShadow? a, DsShadow? b, double t) {
    if (identical(a, b)) return a;
    if (a == null) {
      return b!.copyWith(color: b.color.withValues(alpha: 0))._lerpTo(b, t);
    }
    if (b == null) {
      return a._lerpTo(a.copyWith(color: a.color.withValues(alpha: 0)), t);
    }
    return a._lerpTo(b, t);
  }

  DsShadow _lerpTo(DsShadow b, double t) => DsShadow._raw(
    DsColorUtils.lerp(color, b.color, t)!,
    Offset.lerp(offset, b.offset, t)!,
    lerpDouble(blur, b.blur, t)!,
    lerpDouble(spread, b.spread, t)!,
    t < 0.5 ? inset : b.inset,
    lerpDouble(gap, b.gap, t)!,
    t < 0.5 ? hairline : b.hairline,
  );

  /// Interpolates two shadow lists item by item.
  static List<DsShadow> lerpList(List<DsShadow> a, List<DsShadow> b, double t) {
    if (identical(a, b)) return a;
    final n = a.length > b.length ? a.length : b.length;
    return [
      for (var i = 0; i < n; i++)
        lerp(i < a.length ? a[i] : null, i < b.length ? b[i] : null, t)!,
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is DsShadow &&
      other.color == color &&
      other.offset == offset &&
      other.blur == blur &&
      other.spread == spread &&
      other.inset == inset &&
      other.gap == gap &&
      other.hairline == hairline;

  @override
  int get hashCode =>
      Object.hash(color, offset, blur, spread, inset, gap, hairline);

  @override
  String toString() =>
      // ds-raw: debug text
      'DsShadow(${inset ? 'inset ' : ''}${hairline ? 'hairline ' : ''}'
      '${isOutline ? 'outline gap: $gap, ' : ''}'
      '$offset, blur: $blur, spread: $spread, $color)';
}
