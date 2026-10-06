import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// A color in the OKLCH space, where every Desen color is derived.
///
/// OKLCH is perceptually uniform: two hues at the same lightness ([l]) look
/// equally light. Rules such as "one step darker" or "same hue, less
/// saturated" therefore give consistent results for any brand color, which
/// HSL cannot guarantee.
///
/// Conversion follows Björn Ottosson's OKLab (2020) and matches what browsers
/// produce for CSS `oklch(L C H / a)`, including per-channel clipping of
/// out-of-gamut values.
@immutable
class DsOklch {
  /// Creates a color from lightness, chroma, hue and alpha.
  const DsOklch(this.l, this.c, this.h, [this.alpha = 1]);

  /// Converts an sRGB [color] to OKLCH. Alpha is preserved.
  factory DsOklch.fromColor(Color color) {
    double dec(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    final r = dec(color.r), g = dec(color.g), b = dec(color.b);
    final l_ = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m_ = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s_ = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    final lab = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
    final a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
    final bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;
    final chroma = math.sqrt(a * a + bb * bb);
    var hue = math.atan2(bb, a) * 180 / math.pi;
    if (hue < 0) hue += 360;
    return DsOklch(lab, chroma, chroma < 1e-4 ? 0 : hue, color.a);
  }

  /// Lightness, 0–1.
  final double l;

  /// Chroma, 0–~0.37. Zero is gray.
  final double c;

  /// Hue angle in degrees, 0–360.
  final double h;

  /// Opacity, 0–1.
  final double alpha;

  /// Returns a copy with the given fields replaced.
  DsOklch copyWith({double? l, double? c, double? h, double? alpha}) =>
      DsOklch(l ?? this.l, c ?? this.c, h ?? this.h, alpha ?? this.alpha);

  /// Keeps the hue and sets lightness, chroma and alpha.
  DsOklch at(double l, double c, [double alpha = 1]) => DsOklch(l, c, h, alpha);

  /// Rotates the hue by [degrees].
  DsOklch rotate(double degrees) => copyWith(h: (h + degrees) % 360);

  /// Linear sRGB channels; values outside 0–1 are out of gamut.
  (double, double, double) _linear() {
    final hr = h * math.pi / 180;
    final a = c * math.cos(hr), b = c * math.sin(hr);
    final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
    final lc = l_ * l_ * l_, mc = m_ * m_ * m_, sc = s_ * s_ * s_;
    return (
      4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc,
      -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc,
      -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc,
    );
  }

  /// Whether sRGB can show this color without clipping a channel.
  bool get inGamut {
    const e = 1e-4;
    final (r, g, b) = _linear();
    bool ok(double x) => x >= -e && x <= 1 + e;
    return ok(r) && ok(g) && ok(b);
  }

  /// This color with its chroma lowered until clipping it to sRGB no
  /// longer visibly changes it: the CSS Color 4 gamut-mapping algorithm
  /// (binary search on chroma, a just-noticeable OKLab difference of 0.02).
  /// [toColor] alone clips channels at full chroma, which can shift the
  /// hue a lot: a dark yellow turns orange-brown. This keeps the hue within
  /// a few degrees while keeping as much saturation as sRGB allows.
  DsOklch fitted() {
    if (inGamut) return this;
    const jnd = .02, epsilon = .0001;
    double clipError(DsOklch v) => v._distance(DsOklch.fromColor(v.toColor()));
    if (clipError(this) < jnd) return this;
    var lo = 0.0, hi = c;
    var loInGamut = true;
    var result = copyWith(c: 0);
    while (hi - lo > epsilon) {
      final mid = (lo + hi) / 2;
      final current = copyWith(c: mid);
      if (loInGamut && current.inGamut) {
        lo = mid;
        result = current;
        continue;
      }
      final e = clipError(current);
      if (e < jnd) {
        result = current;
        if (jnd - e < epsilon) break;
        loInGamut = false;
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return result;
  }

  /// Euclidean distance in OKLab (deltaEOK).
  double _distance(DsOklch o) {
    final h1 = h * math.pi / 180, h2 = o.h * math.pi / 180;
    final da = c * math.cos(h1) - o.c * math.cos(h2);
    final db = c * math.sin(h1) - o.c * math.sin(h2);
    final dl = l - o.l;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  /// Converts to sRGB, clipping out-of-gamut channels.
  Color toColor() {
    final (r, g, bl) = _linear();
    int enc(double x) {
      x = x.clamp(0.0, 1.0);
      final v = x <= 0.0031308
          ? 12.92 * x
          : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
      return (v * 255).round();
    }

    return Color.fromARGB(
      (alpha.clamp(0.0, 1.0) * 255).round(),
      enc(r),
      enc(g),
      enc(bl),
    );
  }

  /// Interpolates in OKLCH, taking the shorter way around the hue circle.
  ///
  /// A gray end (chroma ~0) borrows the other end's hue so the blend does not
  /// swing through unrelated hues, matching CSS `color-mix(in oklch, …)`.
  static DsOklch lerp(DsOklch a, DsOklch b, double t) {
    final ha = a.c < 1e-4 ? b.h : a.h;
    final hb = b.c < 1e-4 ? ha : b.h;
    var dh = (hb - ha) % 360;
    if (dh > 180) dh -= 360;
    return DsOklch(
      a.l + (b.l - a.l) * t,
      a.c + (b.c - a.c) * t,
      (ha + dh * t) % 360,
      a.alpha + (b.alpha - a.alpha) * t,
    );
  }

  /// Mixes two sRGB colors in OKLCH. [t] is the share of [b].
  static Color mix(Color a, Color b, double t) =>
      lerp(DsOklch.fromColor(a), DsOklch.fromColor(b), t).toColor();

  /// The shortest distance between two hue angles, 0–180.
  static double hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  static double _cbrt(double x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  @override
  bool operator ==(Object other) =>
      other is DsOklch &&
      other.l == l &&
      other.c == c &&
      other.h == h &&
      other.alpha == alpha;

  @override
  int get hashCode => Object.hash(l, c, h, alpha);

  @override
  String toString() => 'oklch($l $c $h / $alpha)';
}
