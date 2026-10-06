import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/radii.dart';
import 'slider_style.dart';

// The value math and the painted track that DsSlider and DsRangeSlider
// share, so both look and step the same. Not exported.

/// [v] in `min..max` and, with [divisions], on the nearest grid point,
/// without float dust: 3 of 10 steps from 0 to 1 is 0.3, not
/// 0.30000000000000004, and the ends are exactly [min] and [max].
double dsSliderSnap(double v, double min, double max, int? divisions) {
  v = v.clamp(min, max);
  final range = max - min;
  if (divisions == null || range <= 0) return v;
  final k = ((v - min) / range * divisions).round();
  return dsSliderGridPoint(k, min, max, divisions);
}

/// The [k]th of [divisions] grid points from [min] to [max], held in the
/// range and without float dust.
double dsSliderGridPoint(int k, double min, double max, int divisions) {
  if (k <= 0) return min;
  if (k >= divisions) return max;
  final range = max - min;
  final point = min + range * k / divisions;
  // Rounded to a millionth of the step's decade: a point's own digits
  // stay, the last-bit error of the sum goes.
  final digits = 6 - (math.log(range / divisions) / math.ln10).floor();
  if (digits <= 0 || digits > 20) return point;
  return double.parse(point.toStringAsFixed(digits)).clamp(min, max);
}

/// One arrow-key or assistive step: a division, or a hundredth of the
/// range when continuous.
double dsSliderStep(double min, double max, int? divisions) {
  final range = max - min;
  return divisions != null ? range / divisions : range / 100;
}

/// The value under [dx], a position across a track [width] wide whose
/// thumb is [thumb] wide. Mirrored in right-to-left layouts.
double dsSliderValueAt(
  double dx,
  double width,
  double thumb, {
  required double min,
  required double max,
  required bool rtl,
}) {
  final travel = width - thumb;
  var f = travel > 0 ? ((dx - thumb / 2) / travel).clamp(0.0, 1.0) : 0.0;
  if (rtl) f = 1 - f;
  return min + f * (max - min);
}

/// Where [key] moves [value], or null for a key a slider does not use.
/// Arrows step by [step] (Right increases, mirrored in right-to-left
/// layouts; Up always increases), Page Up/Down by a tenth of `min..max`,
/// Home and End go to [low] and [high]: the slider's ends, or the other
/// thumb of a range.
double? dsSliderKeyTarget(
  LogicalKeyboardKey key, {
  required double value,
  required double step,
  required double min,
  required double max,
  required double low,
  required double high,
  required bool rtl,
}) {
  final range = max - min;
  if (key == LogicalKeyboardKey.arrowUp ||
      key ==
          (rtl
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight)) {
    return value + step;
  }
  if (key == LogicalKeyboardKey.arrowDown ||
      key ==
          (rtl
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft)) {
    return value - step;
  }
  if (key == LogicalKeyboardKey.pageUp) return value + range / 10;
  if (key == LogicalKeyboardKey.pageDown) return value - range / 10;
  if (key == LogicalKeyboardKey.home) return low;
  if (key == LogicalKeyboardKey.end) return high;
  return null;
}

/// What screen readers say for [v]: the app's [formatter], or by default a
/// percentage of `min..max` written the local way.
String dsSliderFormat(
  BuildContext context,
  double v, {
  required double min,
  required double max,
  String Function(double value)? formatter,
}) {
  if (formatter != null) return formatter(v);
  final range = max - min;
  return DsLocalizations.of(context)
      .percent(range > 0 ? ((v - min) / range * 100).round() : 0);
}

/// One thumb of a [DsSliderTrack].
@immutable
class DsSliderThumb {
  /// Describes a thumb at [t] (0 at the start, 1 at the end) in [style].
  const DsSliderThumb({
    required this.t,
    required this.style,
    this.focusRing = false,
    this.wrap,
    this.key,
  });

  /// Position along the track, 0 to 1.
  final double t;

  /// The thumb's own resolved style: its fill, outline and shadows.
  final DsSliderStyle style;

  /// Whether the keyboard focus ring shows.
  final bool focusRing;

  /// Wraps the painted thumb, e.g. in its focus node and semantics.
  final Widget Function(Widget thumb)? wrap;

  /// Keeps the thumb's state when the paint order of thumbs changes.
  final Key? key;
}

/// The painted slider: track, fill, step marks and thumbs, in a band as
/// tall as the minimum tap target.
class DsSliderTrack extends StatelessWidget {
  /// Paints [thumbs] on a track [width] wide.
  const DsSliderTrack({
    super.key,
    required this.style,
    required this.width,
    required this.bandHeight,
    required this.thumbs,
    required this.fillTo,
    this.fillFrom,
    this.divisions,
  });

  /// The resolved style of the whole slider: sizes, track, fill and ticks.
  final DsSliderStyle style;

  /// Full width, thumbs included.
  final double width;

  /// Minimum height of the touch band.
  final double bandHeight;

  /// The thumbs, painted in order (the last on top).
  final List<DsSliderThumb> thumbs;

  /// Where the fill starts, 0 to 1; null fills from the track's start.
  final double? fillFrom;

  /// Where the fill ends, 0 to 1.
  final double fillTo;

  /// Step count; null draws no step marks.
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final height = s.height!, trackH = s.trackHeight!;
    final thumb = s.thumbSize!;
    final tick = s.tickSize!;
    final travel = math.max(0.0, width - thumb);
    final from = fillFrom, to = fillTo;
    final ticks = divisions;
    return SizedBox(
      width: width,
      // The touch band grows to the minimum tap target; the track and
      // thumb stay centered in it. Not DsMinTapTarget: a tap above the
      // track must keep its horizontal position.
      height: math.max(height, bandHeight),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Container(
            height: trackH,
            decoration: DsBoxDecoration(
              color: s.trackColor,
              borderRadius: BorderRadius.circular(DsRadii.pill),
              shadows: s.trackShadows ?? const <DsShadow>[],
            ),
          ),
          if (from == null)
            Container(
              width: to * travel + thumb / 2,
              height: trackH,
              decoration: BoxDecoration(
                color: s.fillColor,
                borderRadius: BorderRadius.circular(DsRadii.pill),
              ),
            )
          else
            // Between two thumb centers; the thumbs cover its ends.
            PositionedDirectional(
              start: from * travel + thumb / 2,
              child: Container(
                width: math.max(0.0, to - from) * travel,
                height: trackH,
                color: s.fillColor,
              ),
            ),
          if (ticks != null)
            for (var i = 0; i <= ticks; i++)
              if (thumbs.every(
                (th) => (i / ticks - th.t).abs() * travel > thumb / 2,
              ))
                PositionedDirectional(
                  start: thumb / 2 + i / ticks * travel - tick / 2,
                  child: Container(
                    width: tick,
                    height: tick,
                    decoration: BoxDecoration(
                      color: i / ticks <= to && i / ticks >= (from ?? 0)
                          ? s.tickFilledColor
                          : s.tickColor,
                      borderRadius: BorderRadius.circular(tick / 2),
                    ),
                  ),
                ),
          for (final th in thumbs)
            PositionedDirectional(
              key: th.key,
              start: th.t * travel,
              child: (th.wrap ?? _same)(_thumb(th, thumb)),
            ),
        ],
      ),
    );
  }

  static Widget _same(Widget w) => w;

  Widget _thumb(DsSliderThumb th, double size) {
    final s = th.style;
    final border = s.thumbBorderColor ?? const Color(0x00000000);
    return Container(
      width: size,
      height: size,
      decoration: DsBoxDecoration(
        color: s.thumbColor,
        borderRadius: BorderRadius.circular(size / 2),
        shadows: [
          if (border.a > 0) DsShadow.innerRing(border),
          ...?s.thumbShadows,
          if (th.focusRing) ...?s.focusShadows,
        ],
      ),
    );
  }
}
