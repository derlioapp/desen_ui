import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import 'form_link.dart';

/// Validators for form fields ([DsFormField], [FormField]), with messages
/// in the app's language from [DsLocalizations] that say how to fix the
/// value (WCAG 3.3.3).
///
/// ```dart
/// DsTextFormField(
///   label: const Text('E-posta'),
///   required: true,
///   validator: DsValidators.all([
///     DsValidators.required(context),
///     DsValidators.email(context),
///   ]),
/// )
/// ```
///
/// The message is looked up when the validator is made, so make it in
/// `build` with the field's context. Pass `message` for wording of your
/// own. Only [required] rejects an empty value: the others accept it, so
/// an optional field can be left empty.
abstract final class DsValidators {
  /// Fails while the value is empty: null, text of only spaces, an empty
  /// list, set or map, or `false` (a box that must be checked, e.g.
  /// accepting terms). "This field is required."
  ///
  /// In a date, time or number form field, text that is typed but is not
  /// a value (`2/30/2026`) leaves the value null without being empty: this
  /// passes then, and the field shows the control's own message ("Enter a
  /// date as MM/DD/YYYY.") instead.
  static FormFieldValidator<T> required<T>(
    BuildContext context, {
    String? message,
  }) {
    final text = message ?? DsLocalizations.of(context).fieldRequired;
    return (value) => _isEmpty(value) && !dsValidatingTypedIssue ? text : null;
  }

  /// Fails for text shorter than [min] characters, counted as people
  /// count them (grapheme clusters, as a text field's counter does).
  /// "Enter at least 8 characters."
  static FormFieldValidator<String> minLength(
    BuildContext context,
    int min, {
    String? message,
  }) {
    assert(min > 0);
    final text = message ?? DsLocalizations.of(context).textTooShort(min);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.characters.length < min ? text : null;
    };
  }

  /// Fails for text longer than [max] characters, counted as [minLength]
  /// counts. "Enter at most 100 characters."
  static FormFieldValidator<String> maxLength(
    BuildContext context,
    int max, {
    String? message,
  }) {
    assert(max > 0);
    final text = message ?? DsLocalizations.of(context).textTooLong(max);
    return (value) {
      if (value == null || value.isEmpty) return null;
      return value.characters.length > max ? text : null;
    };
  }

  /// Fails for text that is not an email address: one `@`, no spaces, and
  /// a domain with a dot ("ad@alan.com"; spaces around are ignored). It
  /// checks the shape only, not that the address exists. "Enter an email
  /// address such as name@example.com."
  static FormFieldValidator<String> email(
    BuildContext context, {
    String? message,
  }) {
    final text = message ?? DsLocalizations.of(context).invalidEmail;
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return null;
      return _email.hasMatch(v) ? null : text;
    };
  }

  /// Runs [validators] in order and returns the first message.
  static FormFieldValidator<T> all<T>(List<FormFieldValidator<T>> validators) =>
      (value) {
        for (final validate in validators) {
          if (validate(value) case final message?) return message;
        }
        return null;
      };

  static final _email = RegExp(r'^[^\s@]+@[^\s@.]+(\.[^\s@.]+)+$');

  static bool _isEmpty(Object? value) => switch (value) {
    null => true,
    final String s => s.trim().isEmpty,
    final Iterable<Object?> i => i.isEmpty,
    final Map<Object?, Object?> m => m.isEmpty,
    false => true,
    _ => false,
  };
}
