import 'package:flutter/foundation.dart';

/// A time of day, to the minute: what a `DsTimePicker` holds.
///
/// The widgets layer has no time-of-day type (Material's `TimeOfDay` is not
/// available to Desen), so this is a small immutable pair.
///
/// ```dart
/// DsDateLocale.of(context).time.formatTime(const DsTime(14, 30));
/// // '14:30' in Turkish, '2:30 PM' in US English
/// ```
@immutable
class DsTime implements Comparable<DsTime> {
  /// Creates a time; [hour] is 0–23, [minute] 0–59.
  const DsTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The time of [dateTime], ignoring seconds.
  DsTime.fromDateTime(DateTime dateTime) : this(dateTime.hour, dateTime.minute);

  /// The hour, 0–23.
  final int hour;

  /// The minute, 0–59.
  final int minute;

  /// Minutes since midnight.
  int get inMinutes => hour * 60 + minute;

  /// Whether the time is noon or later.
  bool get isPm => hour >= 12;

  /// The hour on a 12-hour clock: 12, 1, …, 11.
  int get hourOf12 => hour % 12 == 0 ? 12 : hour % 12;

  /// A copy with the given parts replaced.
  DsTime copyWith({int? hour, int? minute}) =>
      DsTime(hour ?? this.hour, minute ?? this.minute);

  /// [date] with this time of day.
  DateTime on(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(DsTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  bool operator ==(Object other) =>
      other is DsTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      'DsTime(${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')})';
}
