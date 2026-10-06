import 'colors.dart';

/// A status, for badges, alerts and indicators.
///
/// Status is never told by color alone: components pair it with a dot, an
/// icon or text.
enum DsStatus {
  /// Neutral, e.g. draft.
  neutral,

  /// Information, e.g. new.
  info,

  /// Success, e.g. published.
  success,

  /// Warning, e.g. in review.
  warning,

  /// Danger or error, e.g. overdue.
  danger,
}

/// Looks up the color set of a [DsStatus].
extension DsStatusColorsLookup on DsColors {
  /// The colors for [status].
  DsStatusColors status(DsStatus status) => switch (status) {
    DsStatus.neutral => neutral,
    DsStatus.info => info,
    DsStatus.success => success,
    DsStatus.warning => warning,
    DsStatus.danger => danger,
  };
}
