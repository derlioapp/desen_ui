/// Internal: the typed-value model shared by the date, time and number
/// fields. Not exported from the package.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../field/field.dart';
import '../form/form_link.dart';
import 'input_issue.dart';

/// The locale whose numeric conventions (date order, separators, first
/// weekday, clock) apply where [context] is: the app's locale, which
/// carries the region, unless [strings] were chosen in another bundled
/// language (a `DsLocalizationScope` forcing Turkish in an English app);
/// then the strings' own ('tr', 'pt_PT', 'zh_Hant'). An app in a language
/// without bundled strings (Polish, Dutch) keeps its locale while the
/// words fall back to English.
Locale dsConventionsLocale(BuildContext context, DsLocalizations strings) {
  final parts = strings.localeName.split('_');
  final app = Localizations.maybeLocaleOf(context);
  if (app != null &&
      (app.languageCode == parts.first ||
          !DsLocalizations.supportedLocales.any(
            (l) => l.languageCode == app.languageCode,
          ))) {
    return app;
  }
  if (parts.length == 1) return Locale(parts.first);
  return parts[1].length == 4
      ? Locale.fromSubtags(languageCode: parts.first, scriptCode: parts[1])
      : Locale(parts.first, parts[1]);
}

/// What a typed field's text holds: a [value], or an [issue] saying why it
/// holds none. Both null: the text is empty (or, while typing, not far
/// enough along to say).
typedef DsTypedRead<T> = ({T? value, DsInputIssue? issue});

/// A text field that holds a value of type [T] (a date, a time, a number):
/// the text is read leniently while typing and committed (shown in the
/// value's format, or kept with an issue) on Enter, when focus leaves and
/// when a popup opens.
///
/// - [onChanged] follows what typing makes of the text ([readTyping]),
///   and is called only for a change: a field focused and left without an
///   edit reports nothing, and committing unedited text does nothing.
/// - An [issue] (error look, `onInputIssueChanged`, the [DsField] message)
///   comes with every invalid commit and with what [readTyping] finds at once;
///   typing clears it otherwise.
/// - A value set from outside replaces the text ([showValue]).
mixin DsTypedFieldState<W extends StatefulWidget, T> on State<W>
    implements DsFormLinkTarget {
  /// The field's text.
  final controller = TextEditingController();

  FocusNode? _ownNode;

  /// The focus node the widget gives, or null for one of the field's own.
  FocusNode? get widgetFocusNode;

  /// The text field's focus node.
  FocusNode get node => widgetFocusNode ?? (_ownNode ??= FocusNode());

  /// The value last reported or given: a widget value that differs from
  /// it comes from outside.
  T? reported;

  /// Why the text holds no value, or null.
  DsInputIssue? issue;

  /// Whether the text was typed into since it was last committed or shown.
  bool _edited = false;

  /// The field around, told of [issue].
  DsFieldHooks? _hooks;

  /// The form field around (a `DsFormField`), which commits pending text
  /// before it validates or saves, and shows its value on reset.
  DsFormLink? _form;

  /// Reports a new value; null disables the field.
  ValueChanged<T?>? get onChanged;

  /// Reports a new [issue], or null once there is none.
  ValueChanged<DsInputIssue?>? get onInputIssueChanged;

  /// Whether a commit may change the text and the value.
  bool get canCommit;

  /// Whether leaving the field commits it now (not while its popup holds
  /// focus).
  bool get commitsOnBlur => true;

  /// [value] as the field shows it.
  String show(T? value);

  /// What typed [text] makes: null leaves the value as it is (a date
  /// whose year is still being typed).
  DsTypedRead<T>? readTyping(String text);

  /// What [text] holds when committed (not empty).
  DsTypedRead<T> readCommit(String text);

  /// Call from `initState`, with the widget's value.
  void initTypedField(T? value) {
    reported = value;
    node.addListener(_onFocus);
  }

  /// Call from `didUpdateWidget` with the old widget's focus node.
  void updateFocusNode(FocusNode? old) {
    if (widgetFocusNode == old) return;
    (old ?? _ownNode)?.removeListener(_onFocus);
    if (widgetFocusNode != null) {
      _ownNode?.dispose();
      _ownNode = null;
    }
    node.addListener(_onFocus);
  }

  /// Call from `dispose`.
  void disposeTypedField() {
    node.removeListener(_onFocus);
    _ownNode?.dispose();
    controller.dispose();
    _hooks?.setInputIssue(this, null);
    _form?.detach(this);
  }

  /// Call from `build`: tells the [DsField] around of [issue], and links
  /// the field to the form field around, if any.
  void tellField(DsFieldScope? scope) {
    final hooks = scope?.hooks;
    if (hooks != _hooks) {
      _hooks?.setInputIssue(this, null);
      _hooks = hooks;
    }
    hooks?.setInputIssue(this, issue?.message);
    final form = DsFormLinkScope.maybeOf(context);
    if (form != _form) {
      _form?.detach(this);
      _form = form;
    }
    form?.attach(this);
  }

  /// A form validates or saves: typed text not committed yet (a date
  /// whose year is still being typed, with focus still in the field) is
  /// committed now, so the form never reads a stale value.
  @override
  void flushForForm() => commit();

  /// A form resets: the text shows [value] even when it equals the value
  /// last reported (typed text or an issue would otherwise stay).
  @override
  void showForForm(Object? value) {
    if (!mounted) return;
    showValue(value as T?);
    setState(() {});
  }

  /// Replaces the text without reporting.
  void setText(String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Shows [value], set from outside (or in a new format): the text is replaced
  /// and any issue dropped. Safe during build; `onInputIssueChanged(null)`
  /// follows after the frame.
  void showValue(T? value) {
    reported = value;
    _edited = false;
    setText(show(value));
    if (issue != null) {
      issue = null;
      _hooks?.setInputIssue(this, null);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && issue == null) onInputIssueChanged?.call(null);
      });
    }
  }

  /// Reports [value] when it differs from the last one.
  void report(T? value) {
    if (value == reported) return;
    reported = value;
    onChanged?.call(value);
  }

  /// Sets [issue], telling the app and the field when it changes.
  void setIssue(DsInputIssue? next) {
    if (next == issue) return;
    issue = next;
    _hooks?.setInputIssue(this, next?.message);
    onInputIssueChanged?.call(next);
  }

  /// Sets a value chosen by other means (a calendar, a column, a step
  /// key): shown, reported, and no issue.
  void choose(T? value) {
    _edited = false;
    setText(show(value));
    setIssue(null);
    report(value);
    if (mounted) setState(() {});
  }

  /// The text field's `onChanged`: the user typed.
  void onText(String text) {
    _edited = true;
    final read = readTyping(text);
    if (read != null) report(read.value);
    setIssue(read?.issue);
    setState(() {});
  }

  /// Enter, focus leaving, a popup opening: shows the value in its format,
  /// or keeps the text with an issue. Text not edited since it was shown
  /// or committed is left alone, so nothing changes without an edit.
  void commit() {
    if (!canCommit || !_edited) return;
    _edited = false;
    final text = controller.text;
    if (text.trim().isEmpty) {
      setText('');
      setIssue(null);
      report(null);
    } else {
      final read = readCommit(text);
      if (read.value case final value? when read.issue == null) {
        setText(show(value));
        setIssue(null);
        report(value);
      } else {
        setIssue(read.issue);
        report(null);
      }
    }
    if (mounted) setState(() {});
  }

  void _onFocus() {
    if (!node.hasFocus && commitsOnBlur) commit();
    if (mounted) setState(() {});
  }
}
