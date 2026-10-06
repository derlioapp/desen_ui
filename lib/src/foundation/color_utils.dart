import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Color helpers for contrast checks and flattening translucent colors.
abstract final class DsColorUtils {
  /// Interpolates two colors in premultiplied alpha, as CSS does.
  ///
  /// `Color.lerp` mixes the channels as if alpha did not exist, so going
  /// from transparent (`0x00000000`, transparent black) to a light fill
  /// passes through a translucent gray: a visible dark flash mid-way. Here
  /// a transparent end takes the other end's hue, and translucent colors
  /// mix by their weight, so a fill simply fades in. Null is transparent.
  static Color? lerp(Color? a, Color? b, double t) {
    if (a == null && b == null) return null;
    // The ends are exact, not rebuilt through premultiplication.
    if (t == 0 && a != null) return a;
    if (t == 1 && b != null) return b;
    a ??= b!.withValues(alpha: 0);
    b ??= a.withValues(alpha: 0);
    final alpha = a.a + (b.a - a.a) * t;
    if (alpha <= 0) return b.withValues(alpha: 0);
    double ch(double x, double y) =>
        ((x * a!.a) + ((y * b!.a) - (x * a.a)) * t) / alpha;
    return Color.from(
      alpha: alpha.clamp(0.0, 1.0),
      red: ch(a.r, b.r).clamp(0.0, 1.0),
      green: ch(a.g, b.g).clamp(0.0, 1.0),
      blue: ch(a.b, b.b).clamp(0.0, 1.0),
    );
  }

  /// Composites [top] over [bottom] (source-over). The result is opaque if
  /// [bottom] is.
  static Color flatten(Color top, Color bottom) {
    final a = top.a + bottom.a * (1 - top.a);
    if (a == 0) return const Color(0x00000000);
    double ch(double t, double b) =>
        (t * top.a + b * bottom.a * (1 - top.a)) / a;
    return Color.from(
      alpha: a,
      red: ch(top.r, bottom.r),
      green: ch(top.g, bottom.g),
      blue: ch(top.b, bottom.b),
    );
  }

  /// WCAG 2 relative luminance of an opaque color.
  static double luminance(Color c) {
    double lin(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  /// WCAG 2 contrast ratio between [foreground] and [background], 1–21.
  ///
  /// Translucent colors are flattened first: [background] over
  /// [backdrop], then [foreground] over the result.
  static double contrastRatio(
    Color foreground,
    Color background, {
    Color backdrop = const Color(0xFFFFFFFF),
  }) {
    final bg = flatten(background, backdrop);
    final fg = flatten(foreground, bg);
    final l1 = luminance(fg), l2 = luminance(bg);
    final hi = math.max(l1, l2), lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// A color tween that mixes in premultiplied alpha ([DsColorUtils.lerp]).
class DsColorTween extends Tween<Color?> {
  /// Creates a color tween.
  DsColorTween({super.begin, super.end});

  @override
  Color? lerp(double t) => DsColorUtils.lerp(begin, end, t);
}
