import 'package:flutter/foundation.dart';

/// A time of day, to the second: what a `DsTimePicker` holds.
///
/// The widgets layer has no time-of-day type (Material's `TimeOfDay` is not
/// available to Desen), so this is a small immutable value. The seconds
/// are optional and 0 unless given; a picker without its seconds column
/// works to the minute.
///
/// ```dart
/// DsDateLocale.of(context).time.formatTime(const DsTime(14, 30));
/// // '14:30' in Turkish, '2:30 PM' in US English
/// const DsTime(0, 4, 30); // a duration-style 00:04:30
/// ```
@immutable
class DsTime implements Comparable<DsTime> {
  /// Creates a time; [hour] is 0–23, [minute] and [second] 0–59.
  const DsTime(this.hour, this.minute, [this.second = 0])
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60),
      assert(second >= 0 && second < 60);

  /// The time of [dateTime], ignoring seconds.
  ///
  /// `DsTime(d.hour, d.minute, d.second)` keeps them.
  DsTime.fromDateTime(DateTime dateTime) : this(dateTime.hour, dateTime.minute);

  /// The time [seconds] after midnight, wrapped into one day: 90 is
  /// 00:01:30, 86400 is 00:00:00 again and -60 is 23:59:00.
  factory DsTime.fromSeconds(int seconds) {
    final s = seconds % _day;
    return DsTime(s ~/ 3600, s ~/ 60 % 60, s % 60);
  }

  static const _day = 24 * 60 * 60;

  /// The hour, 0–23.
  final int hour;

  /// The minute, 0–59.
  final int minute;

  /// The second, 0–59.
  final int second;

  /// Whole minutes since midnight (the seconds left out).
  int get inMinutes => hour * 60 + minute;

  /// Seconds since midnight.
  int get inSeconds => inMinutes * 60 + second;

  /// Whether the time is noon or later.
  bool get isPm => hour >= 12;

  /// The hour on a 12-hour clock: 12, 1, …, 11.
  int get hourOf12 => hour % 12 == 0 ? 12 : hour % 12;

  /// A copy with the given parts replaced.
  DsTime copyWith({int? hour, int? minute, int? second}) =>
      DsTime(hour ?? this.hour, minute ?? this.minute, second ?? this.second);

  /// [date] with this time of day.
  DateTime on(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute, second);

  @override
  int compareTo(DsTime other) => inSeconds.compareTo(other.inSeconds);

  @override
  bool operator ==(Object other) =>
      other is DsTime &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second;

  @override
  int get hashCode => Object.hash(hour, minute, second);

  @override
  String toString() {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'DsTime(${two(hour)}:${two(minute)}'
        '${second == 0 ? '' : ':${two(second)}'})';
  }
}
