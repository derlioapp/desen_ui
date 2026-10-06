/// Internal: how big a calendar's days are, shared by the calendar and the
/// date pickers' popups. Not exported from the package.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'calendar_style.dart';

/// The sizes of a calendar's days.
@immutable
class CalendarMetrics {
  /// Measures a calendar of [months] in [style] (resolved), with text
  /// scaled by [scaler] and taps of at least [tap], to fit [maxWidth].
  ///
  /// A day is [DsCalendarStyle.daySize], or half again the scaled number
  /// when that is larger. Each column takes the day and its gap, at
  /// least [tap] wide; when the months do not fit [maxWidth], the columns
  /// narrow (whole pixels) and the days with them, so the calendar fits a
  /// 320px phone. Rows keep [tap]: the tap areas tile the grid, so a
  /// narrower column still leaves no gap between targets.
  factory CalendarMetrics({
    required DsCalendarStyle style,
    required TextScaler scaler,
    required double tap,
    int months = 1,
    double maxWidth = double.infinity,
  }) {
    final fontSize = style.dayTextStyle?.fontSize ?? 0;
    var day = math.max(style.daySize!, scaler.scale(fontSize) * 1.5);
    var column = math.max(day + style.columnGap!, tap);
    final row = math.max(day + style.rowGap!, tap);
    final gaps = (months - 1) * style.monthGap!;
    final preferred = months * 7 * column + gaps;
    if (maxWidth.isFinite && preferred > maxWidth) {
      column = math.max(
        1.0,
        ((maxWidth - gaps) / (7 * months)).floorToDouble(),
      );
      day = math.min(day, column);
    }
    return CalendarMetrics._(
      day: day,
      pitch: Size(column, row),
      preferredWidth: preferred,
    );
  }

  const CalendarMetrics._({
    required this.day,
    required this.pitch,
    required this.preferredWidth,
  });

  /// Drawn size of a day.
  final double day;

  /// The space each day takes: its tap area.
  final Size pitch;

  /// The width the months take at their full size, before narrowing.
  final double preferredWidth;
}
