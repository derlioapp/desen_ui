/// Internal: how a `DsFormField` reaches the typed control inside it (a
/// date, time or number field). Not exported from the package.
library;

import 'package:flutter/widgets.dart';

/// A control whose text can hold an edit not yet committed to its value.
abstract interface class DsFormLinkTarget {
  /// Commits typed text that Enter or leaving the field would commit, so
  /// the form reads the value the text shows (or the issue it has).
  void flushForForm();

  /// Shows [value] anew, dropping typed text and any issue (a form reset).
  void showForForm(Object? value);
}

/// The form field's end of the link: the control attaches itself while it
/// builds inside the field.
class DsFormLink {
  DsFormLinkTarget? _target;

  /// Makes [target] the control the form field talks to.
  void attach(DsFormLinkTarget target) => _target = target;

  /// Forgets [target], if it is the attached control.
  void detach(DsFormLinkTarget target) {
    if (identical(_target, target)) _target = null;
  }

  /// See [DsFormLinkTarget.flushForForm].
  void flush() => _target?.flushForForm();

  /// See [DsFormLinkTarget.showForForm].
  void show(Object? value) => _target?.showForForm(value);
}

/// Provides a form field's [DsFormLink] to the control inside it.
class DsFormLinkScope extends InheritedWidget {
  /// Provides [link] to [child].
  const DsFormLinkScope({super.key, required this.link, required super.child});

  /// The form field's link.
  final DsFormLink link;

  /// The nearest link, or null outside a form field. Does not make
  /// [context] depend on it: the link of a form field never changes.
  static DsFormLink? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DsFormLinkScope>()?.link;

  @override
  bool updateShouldNotify(DsFormLinkScope oldWidget) => link != oldWidget.link;
}

/// Whether the form field whose validator runs right now has typed text
/// that is not a value (an input issue). `DsFormFieldState` sets it around
/// its validator; `DsValidators.required` reads it, so "required" fails
/// only for empty text and the control's own message ("Enter a date as
/// …") shows for anything else.
bool dsValidatingTypedIssue = false;

/// Runs [body] with [dsValidatingTypedIssue] set to [issue], restoring it
/// after (validators of nested fields do not run inside one another, but a
/// build may).
R dsWithTypedIssue<R>(bool issue, R Function() body) {
  final previous = dsValidatingTypedIssue;
  dsValidatingTypedIssue = issue;
  try {
    return body();
  } finally {
    dsValidatingTypedIssue = previous;
  }
}
