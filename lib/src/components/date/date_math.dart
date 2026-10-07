/// Internal: not exported from the package.
library;

/// Date arithmetic on calendar days (local, midnight), shared by the
/// calendar and the pickers.
abstract final class DsDateUtils {
  /// [date] at midnight, dropping the time of day. A UTC date stays UTC.
  static DateTime dateOnly(DateTime date) => (date.isUtc
      ? DateTime.utc
      : DateTime.new)(date.year, date.month, date.day);

  /// [date]'s calendar day at local midnight, as the days of a calendar
  /// grid are: a UTC date keeps its day, not its moment.
  static DateTime localDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Whether [a] and [b] are the same calendar day (null never is).
  static bool isSameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  /// Whether [a] and [b] are in the same month.
  static bool isSameMonth(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month;

  /// The number of days in [month] of [year].
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The first day of [date]'s month.
  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  /// [month] moved by [delta] months (the first day of that month).
  static DateTime addMonths(DateTime month, int delta) =>
      DateTime(month.year, month.month + delta);

  /// [date] moved by [days] calendar days. Built from the parts, so a
  /// daylight-saving change never lands on the wrong day.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// [date] moved by [months], keeping the day where the month has it
  /// (31 January plus a month is 28 or 29 February).
  static DateTime addMonthsKeepingDay(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final day = date.day.clamp(1, daysInMonth(target.year, target.month));
    return DateTime(target.year, target.month, day);
  }

  /// The calendar days from [a] to [b] (negative when [b] is earlier).
  static int dayDelta(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
