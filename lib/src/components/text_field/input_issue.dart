import 'package:flutter/foundation.dart';

/// What is wrong with the text typed into a date, time or number field.
enum DsInputIssueKind {
  /// The text is not a date, a time or a number ("31.02.2026", "25:00",
  /// "-").
  invalid,

  /// The value is before the first date or under the minimum.
  belowMin,

  /// The value is after the last date or over the maximum.
  aboveMax,

  /// The day is in range but cannot be chosen (a date picker's
  /// `selectableDayPredicate`).
  unavailable,
}

/// Why a typed field's text has no value: what is wrong and a message
/// saying how to fix it, in the field's language ("Enter a date as
/// DD.MM.YYYY.").
///
/// `DsDatePicker`, `DsDateRangePicker`, `DsTimePicker` and `DsNumberField`
/// report it through `onInputIssueChanged`, and with null once the text is
/// valid or empty again. With `onChanged(null)` it tells an empty field (no
/// issue) from one holding text that is not a value (an issue). Inside a
/// `DsField` without an `error`, the field shows [message] in its message row
/// (WCAG 3.3.1).
@immutable
class DsInputIssue {
  /// Creates an issue.
  const DsInputIssue(this.kind, this.message);

  /// What is wrong.
  final DsInputIssueKind kind;

  /// How to fix it, in the field's language.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DsInputIssue && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'DsInputIssue(${kind.name}, "$message")';
}
