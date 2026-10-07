import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../../theme/theme.dart';
import '../autocomplete/autocomplete.dart';
import '../date/calendar.dart';
import '../date/date_picker.dart';
import '../field/field.dart';
import '../field/field_style.dart';
import '../number_field/number_field.dart';
import '../select/select.dart';
import '../selection/checkbox.dart';
import '../selection/radio.dart';
import '../selection/switch.dart';
import '../text_field/text_field.dart';
import '../time/time_picker.dart';
import 'form_field.dart';

// The typed form fields: a DsFormField with its control built in. Each
// passes on the control's common parameters; for any other, build the
// control in a DsFormField.

/// A [DsTextField] in a [DsFormField]: the text is the field's value.
///
/// ```dart
/// DsTextFormField(
///   label: const Text('Full name'),
///   required: true,
///   validator: DsValidators.required(context),
///   onSaved: (v) => name = v!,
/// )
/// ```
///
/// Like Flutter's text form fields, it keeps a [TextEditingController] and
/// the form state in step: typing changes the value, and a reset or
/// [DsFormFieldState.didChange] changes the text. Pass a [controller] to
/// own the text (then the initial text is the controller's, and
/// [initialValue] must be null); a change made to the controller from
/// outside also changes the value. With a [restorationId] and no
/// [controller], the text and selection are restored.
class DsTextFormField extends DsFormField<String> {
  /// Creates a single-line text form field.
  DsTextFormField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    Widget? label,
    Widget? description,
    bool required = false,
    DsFieldStyle? fieldStyle,
    FormFieldSetter<String>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<String>? validator,
    String? forceErrorText,
    bool enabled = true,
    AutovalidateMode? autovalidateMode,
    String? restorationId,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    bool readOnly = false,
    bool obscureText = false,
    bool revealable = false,
    bool clearable = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    Iterable<String>? autofillHints,
    bool? autocorrect,
    bool? enableSuggestions,
    bool? spellCheck,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextAlign textAlign = TextAlign.start,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    String? placeholder,
    Widget? leading,
    Widget? trailing,
  }) : this._(
         key: key,
         controller: controller,
         initialValue: initialValue,
         label: label,
         description: description,
         required: required,
         fieldStyle: fieldStyle,
         onSaved: onSaved,
         onReset: onReset,
         validator: validator,
         forceErrorText: forceErrorText,
         enabled: enabled,
         autovalidateMode: autovalidateMode,
         restorationId: restorationId,
         control: (field, text) => DsTextField(
           controller: text,
           onChanged: (v) {
             field.didChange(v);
             onChanged?.call(v);
           },
           onSubmitted: onSubmitted,
           focusNode: focusNode,
           autofocus: autofocus,
           enabled: field.widget.enabled,
           readOnly: readOnly,
           obscureText: obscureText,
           revealable: revealable,
           clearable: clearable,
           keyboardType: keyboardType,
           textInputAction: textInputAction,
           onEditingComplete: onEditingComplete,
           autofillHints: autofillHints,
           autocorrect: autocorrect,
           enableSuggestions: enableSuggestions,
           spellCheck: spellCheck,
           textCapitalization: textCapitalization,
           textAlign: textAlign,
           maxLength: maxLength,
           maxLengthEnforcement: maxLengthEnforcement,
           inputFormatters: inputFormatters,
           placeholder: placeholder,
           leading: leading,
           trailing: trailing,
         ),
       );

  /// Creates a multi-line text form field ([DsTextField.multiline]).
  DsTextFormField.multiline({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    Widget? label,
    Widget? description,
    bool required = false,
    DsFieldStyle? fieldStyle,
    FormFieldSetter<String>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<String>? validator,
    String? forceErrorText,
    bool enabled = true,
    AutovalidateMode? autovalidateMode,
    String? restorationId,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
    bool autofocus = false,
    bool readOnly = false,
    bool? autocorrect,
    bool? enableSuggestions,
    bool? spellCheck,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextAlign textAlign = TextAlign.start,
    int? minLines = 3,
    int? maxLines = 8,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    String? placeholder,
  }) : this._(
         key: key,
         controller: controller,
         initialValue: initialValue,
         label: label,
         description: description,
         required: required,
         fieldStyle: fieldStyle,
         onSaved: onSaved,
         onReset: onReset,
         validator: validator,
         forceErrorText: forceErrorText,
         enabled: enabled,
         autovalidateMode: autovalidateMode,
         restorationId: restorationId,
         control: (field, text) => DsTextField.multiline(
           controller: text,
           onChanged: (v) {
             field.didChange(v);
             onChanged?.call(v);
           },
           focusNode: focusNode,
           autofocus: autofocus,
           enabled: field.widget.enabled,
           readOnly: readOnly,
           autocorrect: autocorrect,
           enableSuggestions: enableSuggestions,
           spellCheck: spellCheck,
           textCapitalization: textCapitalization,
           textAlign: textAlign,
           minLines: minLines,
           maxLines: maxLines,
           maxLength: maxLength,
           maxLengthEnforcement: maxLengthEnforcement,
           inputFormatters: inputFormatters,
           placeholder: placeholder,
         ),
       );

  DsTextFormField._({
    super.key,
    this.controller,
    String? initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    required Widget Function(
      DsFormFieldState<String> field,
      TextEditingController text,
    )
    control,
  }) : assert(
         initialValue == null || controller == null,
         'Pass the initial text through the controller.',
       ),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         builder: (field) =>
             control(field, (field as _DsTextFormFieldState)._text),
       );

  /// Holds the text; the field keeps one of its own when null.
  final TextEditingController? controller;

  /// The text is restored with the controller, not as a value.
  @override
  Object? encodeValue(String value) => null;

  @override
  DsFormFieldState<String> createState() => _DsTextFormFieldState();
}

class _DsTextFormFieldState extends DsFormFieldState<String> {
  RestorableTextEditingController? _own;

  /// The app controller's text when the field was created: what [reset]
  /// restores, as the widget's initial value follows the controller.
  String? _startText;

  DsTextFormField get _w => widget as DsTextFormField;

  TextEditingController get _text => _w.controller ?? _own!.value;

  @override
  void initState() {
    super.initState();
    if (_w.controller case final c?) {
      c.addListener(_onText);
      _startText = c.text;
    } else {
      _own = RestorableTextEditingController(text: _w.initialValue);
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    if (_own case final own?) registerForRestoration(own, 'text');
    // The value follows the (restored) text.
    setValue(_text.text);
  }

  @override
  void didUpdateWidget(DsTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _w.controller, old = oldWidget.controller;
    if (next == old) return;
    old?.removeListener(_onText);
    next?.addListener(_onText);
    if (old != null && next == null) {
      _own = RestorableTextEditingController.fromValue(old.value);
      registerForRestoration(_own!, 'text');
    }
    if (next != null) {
      setValue(next.text);
      if (_own case final own?) {
        unregisterFromRestoration(own);
        own.dispose();
        _own = null;
      }
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_text.text != value) {
      _text.value = TextEditingValue(
        text: value ?? '',
        selection: TextSelection.collapsed(offset: (value ?? '').length),
      );
    }
  }

  @override
  void reset() {
    // The text first, so the controller listener finds nothing to report.
    _text.value = TextEditingValue(
      text: _startText ?? widget.initialValue ?? '',
    );
    super.reset();
    // The value follows the text, not the widget's latest initial value.
    if (value != _text.text) setValue(_text.text);
  }

  /// A change made to the app's controller from outside.
  void _onText() {
    if (_text.text != value) didChange(_text.text);
  }

  @override
  void dispose() {
    _w.controller?.removeListener(_onText);
    _own?.dispose();
    super.dispose();
  }
}

/// A [DsNumberField] in a [DsFormField]. Text that is not a number in
/// range fails validation with the field's own message ("Enter a
/// number.", "Enter 100 or less.") and saves null.
class DsNumberFormField extends DsFormField<num> {
  /// Creates a number form field.
  DsNumberFormField({
    super.key,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<num?>? onChanged,
    num? min,
    num? max,
    num step = 1,
    DsNumberFormat format = const DsNumberFormat(),
    String? unit,
    String? prefix,
    String? placeholder,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
  }) : super(
         builder: (field) => DsNumberField(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           onInputIssueChanged: field.didChangeInputIssue,
           min: min,
           max: max,
           step: step,
           format: format,
           unit: unit,
           prefix: prefix,
           placeholder: placeholder,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
           textInputAction: textInputAction,
         ),
       );
}

/// A [DsSelect] in a [DsFormField].
class DsSelectFormField<T> extends DsFormField<T> {
  /// Creates a select form field.
  DsSelectFormField({
    super.key,
    required List<DsSelectOption<T>> options,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<T?>? onChanged,
    String? placeholder,
    Widget? leading,
    bool clearable = false,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsSelect<T>(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           options: options,
           placeholder: placeholder,
           leading: leading,
           clearable: clearable,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );
}

/// A [DsAutocomplete] in a [DsFormField]. The value is the chosen option;
/// text typed but not chosen does not change it. Needs an [Overlay].
class DsAutocompleteFormField<T> extends DsFormField<T> {
  /// Creates an autocomplete form field.
  DsAutocompleteFormField({
    super.key,
    required List<DsSelectOption<T>> options,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<T?>? onChanged,
    DsOptionsBuilder<T>? optionsBuilder,
    DsOptionFilter<T>? filter,
    ValueChanged<String>? onCreate,
    String? placeholder,
    String? emptyText,
    String? loadingText,
    bool clearable = true,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsAutocomplete<T>(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           options: options,
           optionsBuilder: optionsBuilder,
           filter: filter,
           onCreate: onCreate,
           placeholder: placeholder,
           emptyText: emptyText,
           loadingText: loadingText,
           clearable: clearable,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );
}

/// A [DsMultiSelect] in a [DsFormField]; the value is the chosen list
/// (empty, never null, in the control). Restored when every value is a
/// [bool], [num] or [String]. Needs an [Overlay].
class DsMultiSelectFormField<T> extends DsFormField<List<T>> {
  /// Creates a multi-select form field.
  DsMultiSelectFormField({
    super.key,
    required List<DsSelectOption<T>> options,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<List<T>>? onChanged,
    DsOptionsBuilder<T>? optionsBuilder,
    DsOptionFilter<T>? filter,
    ValueChanged<String>? onCreate,
    String? placeholder,
    String? emptyText,
    String? loadingText,
    bool clearable = true,
    bool readOnly = false,
    bool collapseTags = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsMultiSelect<T>(
           value: field.value ?? List<T>.empty(),
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           options: options,
           optionsBuilder: optionsBuilder,
           filter: filter,
           onCreate: onCreate,
           placeholder: placeholder,
           emptyText: emptyText,
           loadingText: loadingText,
           clearable: clearable,
           readOnly: readOnly,
           collapseTags: collapseTags,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );

  @override
  Object? encodeValue(List<T> value) =>
      value.every((v) => v is bool || v is num || v is String) ? value : null;

  @override
  List<T> decodeValue(Object data) => List<T>.from(data as List);
}

/// A [DsDatePicker] in a [DsFormField]. Typed text that is not a date
/// that can be chosen fails validation with the picker's own message
/// ("Enter a date as DD.MM.YYYY.") and saves null. The value is restored.
/// Needs an [Overlay] for the calendar.
class DsDateFormField extends DsFormField<DateTime> {
  /// Creates a date form field.
  DsDateFormField({
    super.key,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<DateTime?>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime day)? selectableDayPredicate,
    DateTime? currentDate,
    String? placeholder,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsDatePicker(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           onInputIssueChanged: field.didChangeInputIssue,
           firstDate: firstDate,
           lastDate: lastDate,
           selectableDayPredicate: selectableDayPredicate,
           currentDate: currentDate,
           placeholder: placeholder,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );

  @override
  Object? encodeValue(DateTime value) => [
    value.microsecondsSinceEpoch,
    value.isUtc,
  ];

  @override
  DateTime decodeValue(Object data) {
    final [micros as int, utc as bool] = data as List;
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: utc);
  }
}

/// A [DsDateRangePicker] in a [DsFormField]; the value is a complete
/// range. Typed text that is not a range fails validation with the
/// picker's own message and saves null. The value is restored. Needs an
/// [Overlay] for the calendar.
class DsDateRangeFormField extends DsFormField<DsDateRange> {
  /// Creates a date range form field.
  DsDateRangeFormField({
    super.key,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<DsDateRange?>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime day)? selectableDayPredicate,
    DateTime? currentDate,
    int? months,
    String? placeholder,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsDateRangePicker(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           onInputIssueChanged: field.didChangeInputIssue,
           firstDate: firstDate,
           lastDate: lastDate,
           selectableDayPredicate: selectableDayPredicate,
           currentDate: currentDate,
           months: months,
           placeholder: placeholder,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );

  @override
  Object? encodeValue(DsDateRange value) => [
    _day(value.start),
    if (value.end case final end?) _day(end),
  ];

  @override
  DsDateRange decodeValue(Object data) {
    final days = data as List;
    return DsDateRange(
      start: _fromDay(days[0] as String),
      end: days.length > 1 ? _fromDay(days[1] as String) : null,
    );
  }

  // Calendar days as "y-m-d": a day, not an instant, so a time zone
  // change between runs cannot move it.
  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static DateTime _fromDay(String s) {
    final [y, m, d] = s.split('-').map(int.parse).toList();
    return DateTime(y, m, d);
  }
}

/// A [DsTimePicker] in a [DsFormField]. Typed text that is not a time
/// fails validation with the picker's own message ("Enter a time such as
/// 14:30.") and saves null. The value is restored. Needs an [Overlay] for
/// the time list.
class DsTimeFormField extends DsFormField<DsTime> {
  /// Creates a time form field.
  DsTimeFormField({
    super.key,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<DsTime?>? onChanged,
    int minuteStep = 5,
    bool? use24HourClock,
    String? placeholder,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
         builder: (field) => DsTimePicker(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           onInputIssueChanged: field.didChangeInputIssue,
           minuteStep: minuteStep,
           use24HourClock: use24HourClock,
           placeholder: placeholder,
           readOnly: readOnly,
           focusNode: focusNode,
           autofocus: autofocus,
         ),
       );

  @override
  Object? encodeValue(DsTime value) => value.inMinutes;

  @override
  DsTime decodeValue(Object data) {
    final minutes = data as int;
    return DsTime(minutes ~/ 60, minutes % 60);
  }
}

/// A [DsCheckbox] in a [DsFormField], e.g. accepting terms. [label] is
/// the checkbox's own label; with [DsFormField.required] the required
/// mark follows it. [DsValidators.required] fails while the box is unchecked.
class DsCheckboxFormField extends DsFormField<bool> {
  /// Creates a checkbox form field.
  DsCheckboxFormField({
    super.key,
    bool initialValue = false,
    Widget? label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<bool>? onChanged,
    FocusNode? focusNode,
    bool autofocus = false,
    String? semanticLabel,
  }) : super(
         initialValue: initialValue,
         builder: (field) => DsCheckbox(
           value: field.value ?? false,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v ?? false);
                   onChanged?.call(v ?? false);
                 }
               : null,
           label: _markRequired(field, label),
           focusNode: focusNode,
           autofocus: autofocus,
           semanticLabel: semanticLabel,
         ),
       );
}

/// A [DsSwitch] in a [DsFormField]. [label] and [description] are the
/// switch's own; with [DsFormField.required] the required mark follows
/// the label.
class DsSwitchFormField extends DsFormField<bool> {
  /// Creates a switch form field.
  DsSwitchFormField({
    super.key,
    bool initialValue = false,
    Widget? label,
    Widget? description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<bool>? onChanged,
    FocusNode? focusNode,
    bool autofocus = false,
    String? semanticLabel,
  }) : super(
         initialValue: initialValue,
         builder: (field) => DsSwitch(
           value: field.value ?? false,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           label: _markRequired(field, label),
           description: description,
           focusNode: focusNode,
           autofocus: autofocus,
           semanticLabel: semanticLabel,
         ),
       );
}

/// A [DsRadioGroup] in a [DsFormField]: [child] holds the [DsRadio]s.
/// The field is a group ([DsField.group]): its label, then each radio,
/// then the message.
class DsRadioGroupFormField<T> extends DsFormField<T> {
  /// Creates a radio group form field.
  DsRadioGroupFormField({
    super.key,
    required Widget child,
    super.initialValue,
    super.label,
    super.description,
    super.required,
    super.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    ValueChanged<T?>? onChanged,
  }) : super(
         group: true,
         builder: (field) => DsRadioGroup<T>(
           value: field.value,
           onChanged: field.widget.enabled
               ? (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 }
               : null,
           child: child,
         ),
       );
}

/// [label] with the field's required mark after it when the form field is
/// required: a checkbox or switch names itself, so the mark goes with its
/// label rather than above it.
Widget? _markRequired(DsFormFieldState<bool> field, Widget? label) {
  final w = field.widget as DsFormField<bool>;
  if (label == null || !w.required) return label;
  return _RequiredLabel(style: w.fieldStyle, child: label);
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.style, required this.child});

  final DsFieldStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = DsFieldStyle.resolveLayers([
      DsField.defaultStyle(dsThemeOf(context)),
      DsFieldTheme.of(context).style,
      style,
    ], const {});
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: s.gap!,
      children: [
        Flexible(child: child),
        // As in DsField: the shape marks it, screen readers hear the word.
        Semantics(
          label: DsLocalizations.of(context).required,
          child: ExcludeSemantics(
            // ds-raw: the mark; its spoken name is l10n.required
            child: Text('*', style: TextStyle(color: s.requiredColor)),
          ),
        ),
      ],
    );
  }
}
