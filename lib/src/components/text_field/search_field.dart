part of 'text_field.dart';

/// A search field: a magnifier, the query, a clear
/// button once there is text, and an optional shortcut hint while it is
/// empty.
///
/// ```dart
/// DsSearchField(
///   placeholder: 'Search tasks, people or files',
///   shortcut: '⌘K',
///   onChanged: filter,
///   onSubmitted: search,
/// )
/// ```
///
/// The keyboard's action key reads "Search" ([TextInputAction.search]).
/// Escape clears the text; on an empty field Escape is left to the
/// enclosing layer, so a search inside a dialog or popover closes it with
/// a second Escape. Clearing keeps focus and reports the empty text to
/// [onChanged]. While an input method is composing (Japanese, Chinese,
/// Korean), Escape belongs to it and cancels only the composition.
///
/// [shortcut] only shows the keys: bind them yourself (for example
/// with [CallbackShortcuts] around the page) to focus the field. It is
/// not shown on touch platforms (iOS, Android; the theme's `platform`).
///
/// Screen readers hear it as "Search" (localized) unless [semanticLabel]
/// or a [DsField] label names it. Its look is the text field's
/// [DsTextFieldVariant.search]: style all search fields through
/// `DsTextFieldThemeData.variants`.
///
/// **A quieter edge, on purpose.** It is drawn as a control, like a
/// secondary button: the control fill, its soft edge and a slight lift,
/// rather than the inset well and firm edge of [DsTextField]. The
/// magnifier and the placeholder tell it is a field. For the text field's
/// edge instead, set the variant in a theme:
///
/// ```dart
/// DsTextFieldTheme(
///   data: DsTextFieldThemeData(
///     variants: {
///       DsTextFieldVariant.search: DsTextFieldStyle(
///         borderColor: colors.borderField,
///         hovered: DsTextFieldStyle(borderColor: colors.borderField),
///       ),
///     },
///   ),
///   child: page,
/// )
/// ```
class DsSearchField extends StatelessWidget {
  /// Creates a search field.
  const DsSearchField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.placeholder,
    this.shortcut,
    this.semanticLabel,
    this.error = false,
    this.style,
  }) : assert(
         controller == null || initialValue == null,
         'Pass the initial text through the controller.',
       );

  /// Holds the query; one is created when null.
  final TextEditingController? controller;

  /// The starting query of the field's own controller.
  final String? initialValue;

  /// Called as the query changes, also when it is cleared.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (Enter, or the keyboard's search key).
  final ValueChanged<String>? onSubmitted;

  /// Focus node of the field; one is created when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// Whether the field can be focused and edited.
  final bool enabled;

  /// Whether the query is fixed. It can still be focused, selected and
  /// copied; Escape and the clear button do not clear it.
  final bool readOnly;

  /// Shown while the field is empty, e.g. what can be searched.
  final String? placeholder;

  /// Keys shown on a chip while the field is empty, e.g. "⌘K".
  final String? shortcut;

  /// Names the field for screen readers; defaults to the localized
  /// "Search" when no [DsField] label names it.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsTextFieldStyle? style;

  @override
  Widget build(BuildContext context) {
    final labelled = DsFieldScope.maybeOf(context)?.isLabelled ?? false;
    return DsTextField._search(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      placeholder: placeholder,
      shortcut: shortcut,
      leading: const DsIcon(DsIcons.search),
      semanticLabel:
          semanticLabel ??
          (labelled ? null : DsLocalizations.of(context).search),
      error: error,
      style: style,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('controller', controller, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(StringProperty('placeholder', placeholder, defaultValue: null))
      ..add(StringProperty('shortcut', shortcut, defaultValue: null))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}
