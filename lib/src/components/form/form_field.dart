import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../../overlay/plain_text.dart';
import '../field/field.dart';
import '../field/field_style.dart';
import '../text_field/input_issue.dart';
import 'form_link.dart';

/// Builds the control of a [DsFormField] from its state: the control shows
/// [DsFormFieldState.value] and reports changes to
/// [DsFormFieldState.didChange].
typedef DsFormFieldBuilder<T> = Widget Function(DsFormFieldState<T> field);

/// A [FormField] that draws a [DsField] around its control: Flutter's
/// [Form] validates, saves and resets it, and the field shows the result.
///
/// ```dart
/// Form(
///   key: formKey,
///   child: DsFormField<String>(
///     label: const Text('Proje'),
///     required: true,
///     validator: DsValidators.required(context),
///     builder: (field) => DsSelect<String>(
///       value: field.value,
///       onChanged: field.didChange,
///       options: options,
///     ),
///   ),
/// )
/// ```
///
/// The typed form fields ([DsTextFormField], [DsSelectFormField],
/// [DsDateFormField] and the others) are this with their control built in;
/// use [DsFormField] for a control they do not cover, or for a parameter
/// they do not pass on.
///
/// **Error.** The validator's message (or [forceErrorText]) becomes the
/// field's [DsField.errorText]: the field shows it under the control with
/// a status icon, and the control takes the error look through
/// [DsFieldScope], with no `error: true` of its own.
///
/// **Typed text.** A date, time or number field whose text is not a value
/// reports an [DsInputIssue]; wire its `onInputIssueChanged` to
/// [DsFormFieldState.didChangeInputIssue] (the typed form fields do). While
/// there is one, [DsFormFieldState.validate] fails with the issue's localized
/// message ("Enter a date as DD.MM.YYYY."), unless the validator returns a
/// message of its own, which wins. [DsValidators.required] does not count typed
/// text that is not a value as empty, so the issue's message shows instead of
/// "This field is required." Before validating or saving, text typed but not
/// yet committed (focus still in the field, no Enter) is committed, so a form
/// never saves a value the text no longer shows; invalid text saves null.
///
/// **Required.** [required] shows the field's required mark and marks the
/// control required for screen readers; pair it with
/// [DsValidators.required], which checks it.
///
/// **Focus.** [DsFormValidation.validateAndFocus] validates a [Form] and
/// moves focus to the first invalid field ([DsFormFieldState.focus]).
///
/// **Restoration.** With a [restorationId] (and a [RestorationScope]
/// above, as `DsApp(restorationScopeId: …)` or [RootRestorationScope]
/// gives), the value is restored when it is a [bool], [num] or [String];
/// a subclass restores other types by overriding [encodeValue] and
/// [decodeValue] (the date and time form fields do). The validation error
/// is restored as well (by [FormFieldState]).
///
/// **Screen readers.** When a [Form] validates, Flutter's [FormState]
/// announces the first error; the fields do not add announcements of their
/// own for that validation (one announcement, not one per field).
/// [DsFormValidation.validateAndFocus] instead moves focus, and the screen
/// reader, to the first invalid field, which is read with its name, state
/// and error; Flutter's announcement (the bare message, without the name)
/// is left out so the error is heard once. An error that appears otherwise
/// (autovalidation of this field, an invalid typed text) is announced by
/// the field as a [DsField] does.
///
/// Works without `DsScope` or `DsApp`; needs a [Form] only to be
/// validated together with other fields.
class DsFormField<T> extends FormField<T> {
  /// Creates a form field whose control [builder] builds.
  DsFormField({
    super.key,
    required DsFormFieldBuilder<T> builder,
    this.label,
    this.description,
    this.required = false,
    this.group = false,
    this.fieldStyle,
    super.onSaved,
    super.onReset,
    super.validator,
    super.forceErrorText,
    super.initialValue,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
  }) : super(
         builder: (field) {
           final state = field as DsFormFieldState<T>;
           return state._frame(builder(state));
         },
       );

  /// What the field asks for, above the control ([DsField.label]).
  final Widget? label;

  /// A hint below the control, hidden while there is an error
  /// ([DsField.description]).
  final Widget? description;

  /// Shows the required mark and marks the control required for screen
  /// readers ([DsField.required]). Checking it is the [validator]'s job,
  /// e.g. [DsValidators.required].
  final bool required;

  /// Whether the control is a group of controls that keep their own
  /// semantics nodes, e.g. radios ([DsField.group]).
  final bool group;

  /// Style of the [DsField] around the control.
  final DsFieldStyle? fieldStyle;

  /// [value] in a form state restoration can store (null, bool, num,
  /// String, and lists and maps of them), or null when values of this type
  /// are not restored. By default a [bool], [num] or [String] is kept as
  /// it is.
  @protected
  Object? encodeValue(T value) =>
      value is bool || value is num || value is String ? value : null;

  /// The value [data] stores, as [encodeValue] made it.
  @protected
  T decodeValue(Object data) => data as T;

  @override
  DsFormFieldState<T> createState() => DsFormFieldState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('initialValue', initialValue))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(EnumProperty('autovalidateMode', autovalidateMode));
  }
}

/// The state of a [DsFormField]: Flutter's [FormFieldState] plus the
/// control's typed-text issue, focus and restoration.
class DsFormFieldState<T> extends FormFieldState<T> {
  final _link = DsFormLink();

  /// Around the control: its focusable descendants are what [focus] picks
  /// from. Not a stop itself.
  final _focusGroup = FocusNode(
    debugLabel: 'DsFormField',
    canRequestFocus: false,
    skipTraversal: true,
  );

  final _restorable = _RestorableData();

  DsInputIssue? _issue;

  /// Whether the field leaves its error announcement to the [Form] this
  /// frame.
  bool _quiet = false;

  /// Whether [errorText] reads empty to the [Form] validating it, so it
  /// does not announce the bare message ([DsFormValidation.validateAndFocus]
  /// moves focus to the field instead).
  bool _muted = false;

  DsFormField<T> get _field => widget as DsFormField<T>;

  /// Why the control's typed text holds no value, or null.
  DsInputIssue? get inputIssue => _issue;

  /// Tells the field the control's typed-text issue, or null once the text is a
  /// value or empty again: pass it as a typed control's `onInputIssueChanged`.
  void didChangeInputIssue(DsInputIssue? issue) {
    if (issue == _issue) return;
    setState(() => _issue = issue);
  }

  /// The validator's message (or the forced one), else the typed-text
  /// issue's message.
  @override
  String? get errorText => _muted ? '' : _message;

  String? get _message => super.errorText ?? _issue?.message;

  @override
  bool get hasError => _message != null;

  @override
  bool get isValid => _issue == null && super.isValid;

  /// Commits pending typed text, then validates; invalid typed text fails
  /// with its own message unless the validator returns one.
  @override
  bool validate() {
    _flush();
    // Flutter's FormState announces the first error of a validation.
    if (Form.maybeOf(context) != null && !_quiet) {
      _quiet = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => _quiet = false);
    }
    final valid = dsWithTypedIssue(_issue != null, super.validate);
    if (!valid && _focusPass) {
      _muted = true;
      _mutedFields.add(this);
    }
    return valid;
  }

  /// Autovalidation runs the validator while building: it sees the issue
  /// too (see [validate]).
  @override
  Widget build(BuildContext context) =>
      dsWithTypedIssue(_issue != null, () => super.build(context));

  /// Commits pending typed text, then calls `onSaved` with the value
  /// (null while the text is invalid).
  @override
  void save() {
    _flush();
    super.save();
  }

  /// Back to the initial value: the control shows it, typed text and any
  /// issue are dropped.
  @override
  void reset() {
    _issue = null;
    super.reset();
    _link.show(value);
    _syncRestorable();
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    _syncRestorable();
  }

  @override
  void setValue(T? value) {
    super.setValue(value);
    _syncRestorable();
  }

  /// Moves focus to the control (its first focusable part) and scrolls the
  /// whole field, label to message, into view. Returns false when nothing
  /// in it can take focus (a disabled control).
  bool focus() {
    final target = _focusGroup.traversalDescendants.firstOrNull;
    if (target == null || !mounted) return false;
    // Reveal the end, then the start: the label stays in view when the
    // field is taller than the viewport.
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(context, alignmentPolicy: policy);
    }
    target.requestFocus();
    return true;
  }

  /// Commits the control's pending typed text, except during a build (a
  /// form autovalidating), where no value may change.
  void _flush() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      return;
    }
    _link.flush();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    registerForRestoration(_restorable, 'value');
    if (_restorable.value case [final data]) {
      super.setValue(data == null ? null : _field.decodeValue(data));
    } else {
      _syncRestorable();
    }
  }

  void _syncRestorable() {
    if (!_restorable.registered) return;
    final v = value;
    if (v == null) {
      _restorable.value = const [null];
      return;
    }
    final data = _field.encodeValue(v);
    _restorable.value = data == null ? null : [data];
  }

  Widget _frame(Widget control) {
    final f = _field;
    return DsFormLinkScope(
      link: _link,
      child: Focus(
        focusNode: _focusGroup,
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        child: DsFieldQuietScope(
          quiet: _quiet,
          child: DsField(
            label: f.label,
            description: f.description,
            errorText: _message,
            required: f.required,
            group: f.group,
            style: f.fieldStyle,
            child: control,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _restorable.dispose();
    _focusGroup.dispose();
    super.dispose();
  }
}

/// Validation with focus, for a [Form] of Desen form fields.
extension DsFormValidation on FormState {
  /// Validates every field ([FormState.validateGranularly]) and, when one
  /// fails, moves focus to the first invalid [DsFormField] in reading
  /// order (top to bottom, then from the start side) and scrolls it into
  /// view. Returns whether the form is valid.
  ///
  /// Screen readers hear the error once, with the field's name: the screen
  /// reader moves to the focused control, which reads its name, state and
  /// error, and Flutter's own announcement of the bare message is left
  /// out. When no invalid field can take focus (disabled controls), the
  /// first error is announced with its field's name instead.
  ///
  /// ```dart
  /// DsButton(
  ///   onPressed: () {
  ///     if (formKey.currentState!.validateAndFocus()) {
  ///       formKey.currentState!.save();
  ///     }
  ///   },
  ///   child: const Text('Kaydet'),
  /// )
  /// ```
  bool validateAndFocus() {
    final Set<FormFieldState<Object?>> invalid;
    _focusPass = true;
    try {
      invalid = validateGranularly();
    } finally {
      _focusPass = false;
      for (final f in _mutedFields) {
        f._muted = false;
      }
      _mutedFields.clear();
    }
    if (invalid.isEmpty) return true;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final fields = [
      for (final f in invalid)
        if (f is DsFormFieldState && f.mounted)
          if (f.context.findRenderObject() case final RenderBox box
              when box.hasSize)
            (f, box.localToGlobal(Offset.zero)),
    ];
    fields.sort((a, b) {
      final dy = a.$2.dy - b.$2.dy;
      if (dy.abs() >= 1) return dy.sign.toInt();
      final dx = a.$2.dx - b.$2.dx;
      return (rtl ? -dx : dx).sign.toInt();
    });
    for (final (field, _) in fields) {
      if (field.focus()) {
        field._revealToScreenReader();
        return false;
      }
    }
    // Nothing took focus (disabled controls): the first error is
    // announced once, with its field's name.
    if (fields.firstOrNull case (final field, _)) field._announceError();
    return false;
  }
}

/// Whether [DsFormValidation.validateAndFocus] is validating: the fields
/// that fail keep their message from the [Form]'s own announcement.
bool _focusPass = false;

/// The fields muted during this [DsFormValidation.validateAndFocus].
final _mutedFields = <DsFormFieldState<Object?>>{};

extension on DsFormFieldState<Object?> {
  /// After the frame that shows the error, moves the screen reader to the
  /// focused control, which then reads its name, state and error.
  void _revealToScreenReader() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focused = FocusManager.instance.primaryFocus?.context;
      final target = focused?.findRenderObject() ?? context.findRenderObject();
      target?.sendSemanticsEvent(const FocusSemanticEvent());
    });
  }

  /// Announces the error with the field's name, as one announcement.
  void _announceError() {
    final message = _message;
    if (message == null || !MediaQuery.supportsAnnounceOf(context)) return;
    final label = switch (_field.label) {
      final Widget label? => plainTextOf(label),
      null => null,
    };
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        [?label, DsLocalizations.of(context).error, message].join('\n'),
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      ),
    );
  }
}

/// A form field's value as state restoration stores it: `[data]`, or null
/// when it is not restored.
class _RestorableData extends RestorableValue<List<Object?>?> {
  bool get registered => isRegistered;

  @override
  List<Object?>? createDefaultValue() => null;

  @override
  void didUpdateValue(List<Object?>? oldValue) => notifyListeners();

  @override
  List<Object?>? fromPrimitives(Object? data) =>
      data is List ? List<Object?>.of(data) : null;

  @override
  Object? toPrimitives() => value;
}
