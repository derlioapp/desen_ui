import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton, kTouchSlop;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/haptic_feedback.dart';
import '../../behavior/spring_value.dart';
import '../../foundation/case.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/anchored_overlay.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../painting/surface.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../field/field.dart';
import '../field/field_well.dart';
import '../menu/menu.dart';
import '../menu/menu_item_style.dart';
import '../menu/menu_style.dart';
import '../select/select.dart';
import '../spinner/spinner.dart';
import '../spinner/spinner_style.dart';
import '../text_field/text_field.dart';
import '../text_field/text_field_style.dart';
import '../text_field/text_field_variant.dart';
import 'autocomplete_style.dart';
import 'layout.dart';
import 'match.dart';

/// Finds the options for what the user typed, e.g. from a server.
typedef DsOptionsBuilder<T> = Future<List<DsSelectOption<T>>> Function(
  String query,
);

/// Whether [option] matches what the user typed ([query] is not empty).
typedef DsOptionFilter<T> = bool Function(
  DsSelectOption<T> option,
  String query,
);

/// How long typing must pause before the number of results is announced,
/// so a screen reader is not interrupted on every key.
// ds-raw: a pause in speech, not a design value
const _announceDelay = Duration(milliseconds: 600);

/// An editable combobox: a text field that filters a list of options as
/// the user types (WAI-ARIA APG combobox with a listbox
/// popup and list autocomplete).
///
/// ```dart
/// DsField(
///   label: const Text('City'),
///   child: DsAutocomplete<String>(
///     value: city,
///     onChanged: (v) => setState(() => city = v),
///     options: const [
///       DsSelectOption(value: 'ist', label: 'İstanbul'),
///       DsSelectOption(value: 'izm', label: 'İzmir'),
///       DsSelectOption(value: 'isp', label: 'Isparta'),
///     ],
///   ),
/// )
/// ```
///
/// **Matching.** By default an option matches when its label contains
/// the typed text, compared case-folded with [dsFoldCase] (`ist` finds
/// "İstanbul", `ısp` finds "Isparta"). The matched letters are drawn in
/// the style's `matchStyle` (weight 700). Pass [filter] for another rule,
/// or [optionsBuilder] to look options up asynchronously, e.g. on a server;
/// a spinner and "Loading" show while it runs, and only the answer to the
/// latest text is used.
///
/// **Choosing.** The field shows the chosen option's label. Typing opens
/// the popup and highlights the first match; Enter, Tab or a click chooses
/// it. Leaving the field with text that is not an option puts the chosen
/// label back, unless [onCreate] creates a value from it. Emptying the
/// text and leaving clears the value. With [clearable] (the default) a
/// clear button shows while there is a value.
///
/// **Empty and loading.** When nothing matches, the popup says "No
/// results" (localized), or [emptyText]; while [optionsBuilder] runs it
/// shows a spinner and "Loading", or [loadingText]. With [onCreate] an
/// empty list offers the typed text instead ("Use “Ankara”"), highlighted:
/// Enter or a click takes it.
///
/// **Focus.** Focus stays in the text field the whole time: the active
/// option is shown, not focused (`aria-activedescendant`). It takes the
/// menu's hover highlight, as in native and web comboboxes; the text field
/// keeps the focus ring.
///
/// | Key | Action |
/// |---|---|
/// | Down / Up | Opens the popup; moves the active option (wraps) |
/// | Alt+Down / Alt+Up | Opens / closes the popup without moving |
/// | Enter | Chooses the active option (or takes free text) |
/// | Tab | Chooses the active option and moves on |
/// | Escape | Closes the popup; again: puts the chosen label back over typed text; with nothing to undo it goes on (a dialog closes) |
/// | Home / End, Left / Right | Move the caret in the text |
///
/// **Screen readers.** The field is a text field marked expanded or
/// collapsed (Flutter 3.47 does not support its combobox role yet); its value is the
/// text. The popup is a menu of radio items (Flutter 3.47 has no listbox
/// role either); the chosen one is checked. Where the platform supports
/// announcements, the active option is announced as it moves, and the
/// number of results ("5 results") politely once typing pauses; "No results"
/// is also a live region.
///
/// Anatomy: well (fill + inner edge), text, clear button, error icon,
/// chevron; popup panel with option rows (leading, label with the match in
/// bold, detail or check).
///
/// Needs an [Overlay] for the popup; [DsApp] and every `WidgetsApp`
/// provide one.
///
/// See also [DsMultiSelect] for several values, and [DsSelect] for a short
/// list with no typing.
class DsAutocomplete<T> extends StatelessWidget {
  /// Creates an autocomplete for one value.
  const DsAutocomplete({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.optionsBuilder,
    this.filter,
    this.onCreate,
    this.placeholder,
    this.emptyText,
    this.loadingText,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.clearable = true,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(
         filter == null || optionsBuilder == null,
         'An optionsBuilder does its own matching.',
       );

  /// The chosen value, or null for none.
  final T? value;

  /// Called with the chosen value, or null when it is cleared. Null
  /// disables the field.
  final ValueChanged<T?>? onChanged;

  /// The choices, top to bottom. With [optionsBuilder] they are what shows
  /// before anything is typed, and where the chosen value's label is found.
  final List<DsSelectOption<T>> options;

  /// Looks options up for the typed text instead of filtering [options].
  final DsOptionsBuilder<T>? optionsBuilder;

  /// Replaces the default matching (the label contains the text,
  /// case-folded).
  final DsOptionFilter<T>? filter;

  /// Creates a value from free text: called with text that matches no
  /// option when the user commits it (Enter, Tab, leaving the field, or a
  /// click on the "Use “…”" row an empty list offers). Without it the text
  /// goes back to the chosen option's label.
  final ValueChanged<String>? onCreate;

  /// Shown while the text is empty; screen readers hear it as a hint.
  final String? placeholder;

  /// What the popup says when no option matches, e.g. "No customers
  /// match". Defaults to the localized "No results". Announced like it.
  /// Not shown when [onCreate] offers the typed text instead.
  final String? emptyText;

  /// What the popup says next to the spinner while [optionsBuilder] runs.
  /// Defaults to the localized "Loading".
  final String? loadingText;

  /// Names the field for screen readers when no [DsField] label does.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Whether the value is fixed. The field still shows it and can be
  /// focused, and its text selected and copied; it does not open, take
  /// typing or clear.
  final bool readOnly;

  /// Adds a clear button while there is a value or text.
  final bool clearable;

  /// Focus node of the text; one is created when null.
  final FocusNode? focusNode;

  /// Whether the text takes focus when first built.
  final bool autofocus;

  /// Style laid over the theme and defaults.
  final DsAutocompleteStyle? style;

  /// Desen's default autocomplete style under [theme], shared by
  /// [DsMultiSelect].
  ///
  /// Tags are calm neutral chips in the text color, a little over half the
  /// field height, so a form of several multi-selects does not turn into
  /// a wall of accent; only the tag the arrow keys made active takes the
  /// accent (`selected`).
  static DsAutocompleteStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    // The field's height (the text field's default) sets the tag's: 22 in
    // a 40 field, with the same air above, below and before the tags.
    final field = theme.sizes.md;
    final tag = (field * .55).roundToDouble();
    final air = (field - tag) / 2;
    const removeInset = 2.0;
    // A bright accent fill wears its edge, as a filled selection does.
    final activeEdge = k.accentEdge.a > 0 && k.onSelectionStrong == k.onAccent
        ? k.accentEdge
        : clear;
    return DsAutocompleteStyle(
      tagsPadding: EdgeInsetsDirectional.fromSTEB(air, air, DsSpace.s12, air),
      tagGap: DsSpace.s4,
      inputGap: DsSpace.s4,
      // About five characters of the body text.
      inputMinWidth: 40,
      tagHeight: tag,
      tagPadding: const EdgeInsetsDirectional.fromSTEB(
        DsSpace.s8,
        0,
        removeInset,
        0,
      ),
      // The neutral tint, as a neutral badge: a gray chip in both modes.
      tagBackground: k.neutral.tint,
      tagForeground: k.text,
      tagBorderColor: clear,
      // Corners unset: the tags nest in the field's corners, and the
      // remove button in the tag's.
      tagTextStyle: theme.typography.label,
      tagGapInside: DsSpace.s4,
      tagRemoveStyle: DsButtonStyle(
        height: tag - 2 * removeInset,
        background: clear,
        foreground: k.textMuted,
        iconSize: 12,
        hovered: DsButtonStyle(
          background: k.neutral.tintHover,
          foreground: k.text,
        ),
        pressed: DsButtonStyle(
          background: k.neutral.tintPress,
          foreground: k.text,
        ),
      ),
      matchStyle: const TextStyle(fontWeight: FontWeight.w700),
      checkColor: k.accentText,
      maxHeight: 280,
      messageStyle: theme.typography.body.copyWith(
        color: k.textSubtle,
        height: 1.2,
      ),
      // The active tag: the filled selection, so it stands out among the
      // gray ones.
      selected: DsAutocompleteStyle(
        tagBackground: k.selectionStrong,
        tagForeground: k.onSelectionStrong,
        tagBorderColor: activeEdge,
        tagRemoveStyle: DsButtonStyle(
          foreground: k.onSelectionStrong,
          hovered: DsButtonStyle(
            background: k.selectionStrongHover,
            foreground: k.onSelectionStrong,
          ),
          pressed: DsButtonStyle(
            background: k.selectionStrongHover,
            foreground: k.onSelectionStrong,
          ),
        ),
      ),
      // Disabled keeps the filled shape in the disabled colors: a gray
      // step off the disabled well.
      disabled: DsAutocompleteStyle(
        tagBackground: k.channelStrong,
        tagForeground: k.onDisabled,
        tagBorderColor: clear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Combobox<T>(
    multiple: false,
    value: value,
    values: const [],
    onChanged: onChanged,
    onChangedMany: null,
    options: options,
    optionsBuilder: optionsBuilder,
    filter: filter,
    onCreate: onCreate,
    placeholder: placeholder,
    emptyText: emptyText,
    loadingText: loadingText,
    semanticLabel: semanticLabel,
    error: error,
    readOnly: readOnly,
    clearable: clearable,
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
  );
}

/// An editable combobox for several values: the chosen ones show as tags
/// inside the field and the text filters the rest.
///
/// ```dart
/// DsField(
///   label: const Text('Assignees'),
///   child: DsMultiSelect<String>(
///     value: people,
///     onChanged: (v) => setState(() => people = v),
///     options: const [
///       DsSelectOption(value: 'ayse', label: 'Ayşe Kaya'),
///       DsSelectOption(value: 'mehmet', label: 'Mehmet Demir'),
///     ],
///   ),
/// )
/// ```
///
/// It is a [DsAutocomplete] that keeps a list: matching, the popup, focus
/// and screen readers work the same. Choosing an option adds it (or, if it
/// is chosen already, removes it) and the popup stays open for the next;
/// chosen options show a check and are announced as checked menu items.
/// The text empties after each choice.
///
/// **Tags.** Each value is a small neutral tag with a remove button
/// ("Remove Ayşe Kaya"). The remove buttons are not Tab stops: Backspace
/// in the empty text removes the last tag (announced), and the popup
/// unchecks any value. Left at the start of the text (Right in a
/// right-to-left layout) makes a tag active, in the accent, while focus
/// stays in the text; Backspace or Delete removes it. Tags wrap onto more
/// lines and the field grows on the tone spring; the text follows
/// the last tag on its line, and moves to a line of its own only once
/// typed text has less than [DsAutocompleteStyle.inputMinWidth] left.
///
/// **Collapsed tags.** With [collapseTags] the field keeps to one line
/// while it does not have focus: the tags that fit show, followed by a
/// "+N" tag that counts the rest (read as "N more", with their labels).
/// It is not a Tab stop or a button; a tap on the field focuses it, and
/// with focus every tag shows and wraps again, so the arrow keys reach
/// each one. A disabled field stays collapsed.
///
/// | Key | Action |
/// |---|---|
/// | Down / Up | Opens the popup; moves the active option (wraps) |
/// | Enter | Adds or removes the active option; the popup stays open |
/// | Backspace | In empty text: removes the last tag; on an active tag: removes it, the one before becomes active |
/// | Delete | On an active tag: removes it, the one after becomes active |
/// | Left / Right | At the start of the text: makes the last tag active, then moves along the tags; past the last, back to the text |
/// | Escape | Leaves an active tag; closes the popup; again: clears typed text; with none it goes on (a dialog closes) |
/// | Tab | Closes the popup and moves on (it does not toggle a value) |
///
/// With [onCreate] typed text that matches no option can become a value:
/// it is called on Enter, when leaving the field or on a click on the
/// "Use “…”" row an empty list offers, and adds it itself. [emptyText] and
/// [loadingText] replace "No results" and "Loading", as in
/// [DsAutocomplete].
class DsMultiSelect<T> extends StatelessWidget {
  /// Creates an autocomplete for several values.
  const DsMultiSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.optionsBuilder,
    this.filter,
    this.onCreate,
    this.placeholder,
    this.emptyText,
    this.loadingText,
    this.semanticLabel,
    this.error = false,
    this.readOnly = false,
    this.clearable = true,
    this.collapseTags = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(
         filter == null || optionsBuilder == null,
         'An optionsBuilder does its own matching.',
       );

  /// The chosen values, in the order they were added.
  final List<T> value;

  /// Called with the new list of values. Null disables the field.
  final ValueChanged<List<T>>? onChanged;

  /// The choices; see [DsAutocomplete.options]. Labels of the [value]
  /// are found here (or among loaded options).
  final List<DsSelectOption<T>> options;

  /// See [DsAutocomplete.optionsBuilder].
  final DsOptionsBuilder<T>? optionsBuilder;

  /// See [DsAutocomplete.filter].
  final DsOptionFilter<T>? filter;

  /// Creates a value from typed text that matches no option; see the
  /// class docs.
  final ValueChanged<String>? onCreate;

  /// Shown while there are no values and no text.
  final String? placeholder;

  /// See [DsAutocomplete.emptyText].
  final String? emptyText;

  /// See [DsAutocomplete.loadingText].
  final String? loadingText;

  /// Names the field for screen readers when no [DsField] label does.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Whether the values are fixed: the tags show without remove buttons
  /// and the field can be focused, but it does not open, take typing or
  /// clear.
  final bool readOnly;

  /// Adds a button that removes every value while there are some.
  final bool clearable;

  /// Whether the tags keep to one line while the field does not have
  /// focus, with a "+N" tag for those that do not fit (Ant Design's
  /// responsive `maxTagCount`, MUI's `limitTags`); see the class docs.
  final bool collapseTags;

  /// Focus node of the text; one is created when null.
  final FocusNode? focusNode;

  /// Whether the text takes focus when first built.
  final bool autofocus;

  /// Style laid over the theme and defaults
  /// ([DsAutocomplete.defaultStyle]).
  final DsAutocompleteStyle? style;

  @override
  Widget build(BuildContext context) => _Combobox<T>(
    multiple: true,
    collapseTags: collapseTags,
    value: null,
    values: value,
    onChanged: null,
    onChangedMany: onChanged,
    options: options,
    optionsBuilder: optionsBuilder,
    filter: filter,
    onCreate: onCreate,
    placeholder: placeholder,
    emptyText: emptyText,
    loadingText: loadingText,
    semanticLabel: semanticLabel,
    error: error,
    readOnly: readOnly,
    clearable: clearable,
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
  );
}

/// The engine of [DsAutocomplete] and [DsMultiSelect].
class _Combobox<T> extends StatefulWidget {
  const _Combobox({
    super.key,
    required this.multiple,
    required this.value,
    required this.values,
    required this.onChanged,
    required this.onChangedMany,
    required this.options,
    required this.optionsBuilder,
    required this.filter,
    required this.onCreate,
    required this.placeholder,
    required this.emptyText,
    required this.loadingText,
    required this.semanticLabel,
    required this.error,
    required this.readOnly,
    required this.clearable,
    required this.focusNode,
    required this.autofocus,
    required this.style,
    this.collapseTags = false,
  });

  final bool multiple;
  final bool collapseTags;
  final T? value;
  final List<T> values;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onChangedMany;
  final List<DsSelectOption<T>> options;
  final DsOptionsBuilder<T>? optionsBuilder;
  final DsOptionFilter<T>? filter;
  final ValueChanged<String>? onCreate;
  final String? placeholder;
  final String? emptyText;
  final String? loadingText;
  final String? semanticLabel;
  final bool error;
  final bool readOnly;
  final bool clearable;
  final FocusNode? focusNode;
  final bool autofocus;
  final DsAutocompleteStyle? style;

  @override
  State<_Combobox<T>> createState() => _ComboboxState<T>();
}

class _ComboboxState<T> extends State<_Combobox<T>> {
  final _popup = DsOverlayController();
  final _text = TextEditingController();
  final _scroll = ScrollController();

  /// The trailing buttons never take focus: the text keeps it.
  final _clearFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  final _chevronFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  final _removeFocus = FocusNode(skipTraversal: true, canRequestFocus: false);

  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  /// The options the popup lists now.
  List<DsSelectOption<T>> _results = const [];

  /// Every option seen, for the labels of chosen values.
  final _known = <T, DsSelectOption<T>>{};

  /// The active option's index in [_results], or -1.
  int _active = -1;

  /// Whether the active option was reached with the keyboard.
  bool _keyboardActive = false;

  /// The tag the arrow keys made active (an index into the values), or
  /// -1. Focus stays in the text; Backspace and Delete remove this tag.
  int _activeTag = -1;

  /// The text the popup filters by; empty lists everything.
  String _query = '';

  bool _loading = false;
  int _request = 0;
  bool _hovered = false;

  /// Whether the last pointer down landed on one of the field's buttons.
  bool _downOnButton = false;
  Offset? _downAt;

  Timer? _announceTimer;

  /// Rows of the popup that are built now, by index (to scroll them in).
  final _rows = <int, BuildContext>{};

  /// Identifies the popup for the field's `controls` relation (web).
  late final _popupId = 'ds-combobox-${identityHashCode(this)}';

  DsFieldHooks? _hooks;

  bool get _enabled =>
      widget.multiple ? widget.onChangedMany != null : widget.onChanged != null;

  /// Enabled and not read-only: the value can change.
  bool get _canEdit => _enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _remember(widget.options);
    _focus.addListener(_onFocus);
    _popup.addListener(_onPopup);
    _label = _labelOf(widget.value) ?? '';
    _text.text = _committedText;
    _results = _filtered('');
  }

  @override
  void didUpdateWidget(_Combobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_onFocus);
    }
    _remember(widget.options);
    if (!listEquals(widget.options, oldWidget.options) &&
        widget.optionsBuilder == null) {
      _results = _filtered(_query);
      _active = math.min(_active, _results.length - 1);
    }
    // A value set from outside (or its label, once known) shows, unless
    // the user is typing.
    final label = _labelOf(widget.value) ?? '';
    if (!widget.multiple && label != _label) {
      final typing = _focus.hasFocus && _text.text != _label;
      _label = label;
      if (!typing) _setText(label);
    }
    if (!_canEdit && _popup.isOpen) _popup.close();
    if (!_canEdit || _activeTag >= widget.values.length) {
      _activeTag = _canEdit ? widget.values.length - 1 : -1;
    }
  }

  @override
  void dispose() {
    _report(null);
    _announceTimer?.cancel();
    _focus.removeListener(_onFocus);
    _popup
      ..removeListener(_onPopup)
      ..dispose();
    _text.dispose();
    _scroll.dispose();
    _clearFocus.dispose();
    _chevronFocus.dispose();
    _removeFocus.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _remember(Iterable<DsSelectOption<T>> options) {
    for (final o in options) {
      _known[o.value] = o;
    }
  }

  String? _labelOf(T? value) =>
      value == null ? null : (_known[value]?.label ?? value.toString());

  /// The text a single field shows when nobody is typing.
  String get _committedText => widget.multiple ? '' : _label;

  /// The chosen value's label as this field last set or saw it; it is
  /// ahead of [_Combobox.value] between a choice and the parent's rebuild.
  String _label = '';

  bool _isChosen(T value) =>
      widget.multiple ? widget.values.contains(value) : widget.value == value;

  void _setText(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  List<DsSelectOption<T>> _filtered(String query) {
    if (query.isEmpty) return widget.options;
    final filter = widget.filter;
    if (filter != null) {
      return [
        for (final o in widget.options)
          if (filter(o, query)) o,
      ];
    }
    // The query is folded once per keystroke, each label once per option
    // (not both once per option on every keystroke).
    final wanted = dsFoldCase(query);
    return [
      for (final o in widget.options)
        if (foldedLabel(o).contains(wanted)) o,
    ];
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _activeTag = -1;
      _commitText();
      // Not while the focus manager is still applying this change: closing
      // takes the popup out of the focus tree.
      scheduleMicrotask(() {
        if (mounted && !_focus.hasFocus) _popup.close();
      });
    }
    setState(() {});
  }

  void _onPopup() {
    if (!_popup.isOpen) {
      _announceTimer?.cancel();
      _keyboardActive = false;
    }
    setState(() {});
  }

  // ---------------------------------------------------------------------
  // Results

  /// Lists the options for [query] (synchronously or through the builder)
  /// and picks the active one.
  void _search(String query, {bool announce = true}) {
    _query = query;
    final builder = widget.optionsBuilder;
    if (builder == null || query.isEmpty) {
      _request++;
      _loading = false;
      _show(_filtered(query), announce: announce && query.isNotEmpty);
      return;
    }
    final request = ++_request;
    setState(() => _loading = true);
    builder(query).then(
      (results) {
        if (!mounted || request != _request) return;
        _remember(results);
        _loading = false;
        _show(results, announce: announce);
      },
      onError: (Object _) {
        if (!mounted || request != _request) return;
        _loading = false;
        _show(const [], announce: announce);
      },
    );
  }

  void _show(List<DsSelectOption<T>> results, {required bool announce}) {
    setState(() {
      _results = results;
      _active = _initialActive();
      _keyboardActive = false;
    });
    if (announce) _scheduleCountAnnouncement();
    if (_active >= 0) _reveal(_active);
  }

  /// Typing highlights the option whose label is exactly the text, else
  /// the first match, so Enter takes it; with free text ([onCreate]) only
  /// an exact label is highlighted, so Enter keeps anything else as typed.
  /// With nothing typed the chosen value is active.
  int _initialActive() {
    if (_query.isEmpty) {
      if (widget.multiple) return -1;
      return _results.indexWhere((o) => o.value == widget.value && o.enabled);
    }
    final exact = _exact(_query);
    if (exact != null) {
      final i = _results.indexOf(exact);
      if (i >= 0) return i;
    }
    if (widget.onCreate != null) return -1;
    return _results.indexWhere((o) => o.enabled);
  }

  /// The typed text an empty list offers as the value ([onCreate]), or
  /// null when it offers none.
  String? get _customText {
    if (widget.onCreate == null || _loading || _results.isNotEmpty) {
      return null;
    }
    if (_text.text == _committedText) return null;
    final text = _text.text.trim();
    return text.isEmpty ? null : text;
  }

  /// The click on the offered text: takes it as Enter does.
  void _takeCustom() {
    if (!_canEdit) return;
    _commitEnter();
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  /// The enabled option whose label is [text] (case-folded, trimmed).
  DsSelectOption<T>? _exact(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final wanted = dsFoldCase(trimmed);
    for (final options in [_results, widget.options]) {
      for (final o in options) {
        if (o.enabled && foldedLabel(o) == wanted) return o;
      }
    }
    return null;
  }

  /// Takes the option the user typed out in full: chooses it (adds it, in
  /// a multi-select, unless it is already in).
  void _takeExact(DsSelectOption<T> option) {
    if (widget.multiple && widget.values.contains(option.value)) {
      _setText('');
      _query = '';
      return;
    }
    _choose(option);
  }

  void _scheduleCountAnnouncement() {
    _announceTimer?.cancel();
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    _announceTimer = Timer(_announceDelay, () {
      if (!mounted || !_popup.isOpen || _loading) return;
      final l10n = DsLocalizations.of(context);
      final custom = _customText;
      _announce(
        custom != null
            ? l10n.useCustom(custom)
            : _results.isEmpty
            ? widget.emptyText ?? l10n.selectNoResults
            : l10n.selectResultCount(_results.length),
      );
    });
  }

  void _announce(String message) {
    if (!mounted || !MediaQuery.supportsAnnounceOf(context)) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// Says which option is active, for screen readers that cannot follow
  /// it (focus stays in the text).
  void _announceActive() {
    if (_active < 0 || _active >= _results.length) return;
    final o = _results[_active];
    final l10n = DsLocalizations.of(context);
    _announce(
      [o.label, ?o.detail, if (_isChosen(o.value)) l10n.selected].join(', '),
    );
  }

  // ---------------------------------------------------------------------
  // Opening, moving, choosing

  /// Opens the popup. Unless the user has typed a filter, it lists every
  /// option.
  void _open() {
    if (!_canEdit || _popup.isOpen) return;
    final typed = _text.text != _committedText;
    _search(typed ? _text.text : '', announce: false);
    _popup.open();
  }

  void _close() {
    _popup.close();
  }

  void _onTextChanged(String text) {
    if (!_canEdit) return;
    _activeTag = -1;
    if (!_popup.isOpen) _popup.open();
    _search(text);
  }

  void _move(int delta) {
    final n = _results.length;
    if (n == 0 || !_results.any((o) => o.enabled)) return;
    var i = _active;
    if (i < 0) i = delta > 0 ? -1 : n;
    for (var step = 0; step < n; step++) {
      i = (i + delta + n) % n;
      if (_results[i].enabled) break;
    }
    setState(() {
      _active = i;
      _keyboardActive = true;
    });
    _reveal(i);
    _announceActive();
  }

  /// Scrolls the row at [index] into view once it is laid out.
  void _reveal(int index) {
    void run({required bool retry}) {
      if (!mounted || index != _active) return;
      final row = _rows[index];
      if (row != null && row.mounted) {
        Scrollable.ensureVisible(
          row,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
        Scrollable.ensureVisible(
          row,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      } else if (retry && _scroll.hasClients) {
        // Far from the built rows (a wrap to the other end): jump close,
        // then bring it in.
        final p = _scroll.position;
        _scroll.jumpTo(
          index * p.maxScrollExtent / math.max(1, _results.length - 1),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => run(retry: false));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => run(retry: true));
  }

  /// Chooses [option]. A [touch] (a tap on its row) ticks; keys and
  /// assistive actions are silent, as on iOS.
  void _choose(DsSelectOption<T> option, {bool touch = false}) {
    if (!option.enabled || !_canEdit) return;
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    if (widget.multiple) {
      final chosen = widget.values.contains(option.value);
      final next = chosen
          ? [
              for (final v in widget.values)
                if (v != option.value) v,
            ]
          : [...widget.values, option.value];
      widget.onChangedMany?.call(next);
      if (chosen) {
        _announce(DsLocalizations.of(context).removed(option.label));
      } else {
        _announce(
          [option.label, DsLocalizations.of(context).selected].join(', '),
        );
      }
      // The text empties for the next search; the popup stays open on the
      // same option.
      if (_text.text.isNotEmpty) {
        _setText('');
        _search('', announce: false);
      }
      final i = _results.indexWhere((o) => o.value == option.value);
      setState(() => _active = i);
    } else {
      if (option.value != widget.value) widget.onChanged?.call(option.value);
      _label = option.label;
      _setText(option.label);
      _query = '';
      _close();
    }
  }

  /// Enter, or the on-screen keyboard's action: chooses the active option
  /// or takes free text. Returns whether it did something.
  bool _commitEnter() {
    if (_popup.isOpen && _active >= 0 && _active < _results.length) {
      _choose(_results[_active]);
      return true;
    }
    final text = _text.text.trim();
    // An option's label typed out in full is that option, not free text,
    // as when leaving the field.
    if (_text.text != _committedText) {
      if (_exact(text) case final o?) {
        _takeExact(o);
        if (!widget.multiple) _close();
        return true;
      }
    }
    final custom = widget.onCreate;
    if (custom != null && text.isNotEmpty && _text.text != _committedText) {
      custom(text);
      if (widget.multiple) _setText('');
      _close();
      return true;
    }
    return false;
  }

  /// Leaving the field: an exact label chooses its option, free text goes
  /// to [_Combobox.onCreate], empty text clears a single value; anything
  /// else reverts to the chosen label.
  void _commitText() {
    if (!_canEdit) return;
    final text = _text.text;
    if (text == _committedText) return;
    if (!widget.multiple && text.trim().isEmpty) {
      if (widget.value != null) widget.onChanged?.call(null);
      _label = '';
      _setText('');
      return;
    }
    final folded = text.trim();
    // An exact label chooses its option, in a multi-select too: it is
    // never reported as free text.
    if (_exact(folded) case final o?) {
      _takeExact(o);
      if (widget.multiple) _setText('');
      return;
    }
    if (widget.onCreate != null && folded.isNotEmpty) {
      widget.onCreate!(folded);
    }
    _setText(_committedText);
  }

  void _clearAll() {
    if (!_canEdit) return;
    if (widget.multiple) {
      if (widget.values.isNotEmpty) widget.onChangedMany?.call(const []);
    } else if (widget.value != null) {
      widget.onChanged?.call(null);
    }
    _label = '';
    _setText('');
    _query = '';
    _close();
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  void _removeValue(T value) {
    if (!_canEdit) return;
    widget.onChangedMany?.call([
      for (final v in widget.values)
        if (v != value) v,
    ]);
    _announce(DsLocalizations.of(context).removed(_labelOf(value) ?? ''));
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_canEdit) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // While an input method composes (CJK, Korean), its keys are its own:
    // arrows pick a candidate, Enter confirms it, Escape cancels it,
    // Backspace edits it (as the number field).
    final composing = _text.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_onTagKey(event) case final result?) return result;
    final open = _popup.isOpen;
    final alt = HardwareKeyboard.instance.isAltPressed;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final down = key == LogicalKeyboardKey.arrowDown;
      if (alt) {
        down ? _open() : _close();
        return KeyEventResult.handled;
      }
      if (!open) {
        _open();
        // The chosen option when there is one, else the first or last.
        if (_active < 0) _move(down ? 1 : -1);
        if (_active >= 0) {
          _keyboardActive = true;
          _reveal(_active);
          _announceActive();
        }
        return KeyEventResult.handled;
      }
      _move(down ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return _commitEnter() ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (open) {
        _close();
        return KeyEventResult.handled;
      }
      // The second Escape puts the chosen label back over typed text.
      if (_text.text != _committedText) {
        _setText(_committedText);
        _query = '';
        return KeyEventResult.handled;
      }
      // Nothing to undo: Escape is the page's (a dialog closes). It never
      // clears a chosen value; that is the clear button's job.
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.tab) {
      // As a select: Tab takes the active option, then focus moves on.
      if (open &&
          !widget.multiple &&
          _active >= 0 &&
          _active < _results.length) {
        _choose(_results[_active]);
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.backspace &&
        widget.multiple &&
        _text.text.isEmpty &&
        widget.values.isNotEmpty) {
      _removeValue(widget.values.last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The keys of the tags: Left at the start of the text (Right in a
  /// right-to-left layout) makes the last tag active and walks back along
  /// them, the other arrow walks forward and past the last tag returns to
  /// the text; Backspace and Delete remove the active tag. Any other key
  /// leaves the tags and does its usual job. Null when the key is not
  /// theirs.
  KeyEventResult? _onTagKey(KeyEvent event) {
    final key = event.logicalKey;
    final count = widget.values.length;
    if (!widget.multiple || count == 0 || _modifiers.contains(key)) {
      return null;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final i = _activeTag;
    if (i < 0) {
      final selection = _text.selection;
      final atStart =
          !selection.isValid ||
          (selection.isCollapsed && selection.baseOffset == 0);
      if (key != back || !atStart) return null;
      _setActiveTag(count - 1);
      return KeyEventResult.handled;
    }
    if (key == back) {
      _setActiveTag(math.max(0, i - 1));
    } else if (key == forward) {
      _setActiveTag(i + 1 < count ? i + 1 : -1);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      // One tag per press, not a run while the key is held.
      if (event is! KeyDownEvent) return KeyEventResult.handled;
      // The neighbor takes its place: the one before for Backspace, the
      // one that slides in for Delete; none once the last tag goes.
      final next = count == 1
          ? -1
          : key == LogicalKeyboardKey.backspace
          ? math.max(0, i - 1)
          : math.min(i, count - 2);
      _removeValue(widget.values[i]);
      setState(() => _activeTag = next);
    } else if (key == LogicalKeyboardKey.escape) {
      _setActiveTag(-1);
    } else {
      setState(() => _activeTag = -1);
      return null;
    }
    return KeyEventResult.handled;
  }

  /// Modifier keys alone leave the active tag as it is.
  static final _modifiers = LogicalKeyboardKey.expandSynonyms({
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.meta,
  });

  /// Makes the tag at [index] active (or none, -1) and says which, for
  /// screen readers (focus stays in the text).
  void _setActiveTag(int index) {
    if (index == _activeTag) return;
    setState(() => _activeTag = index);
    if (index >= 0) _announce(_labelOf(widget.values[index]) ?? '');
  }

  // ---------------------------------------------------------------------
  // Pointer on the field

  void _onPointerDown(PointerDownEvent event) {
    // A primary click or a touch; a right click opens the edit menu.
    _downAt = event.buttons == kPrimaryButton ? event.position : null;
  }

  void _onPointerUp(PointerUpEvent event) {
    final onButton = _downOnButton;
    _downOnButton = false;
    final at = _downAt;
    _downAt = null;
    if (onButton || at == null || !_enabled) return;
    if ((event.position - at).distance > kTouchSlop) return;
    if (_activeTag >= 0) setState(() => _activeTag = -1);
    // A read-only field takes focus too (it shows collapsed tags), but
    // does not open.
    if (!_focus.hasFocus) _focus.requestFocus();
    _open();
  }

  /// Marks a pointer down on a button, so the field's own tap ignores it.
  Widget _button(Widget child) =>
      Listener(onPointerDown: (_) => _downOnButton = true, child: child);

  void _toggle() {
    if (!_canEdit) return;
    if (!_focus.hasFocus) _focus.requestFocus();
    _popup.isOpen ? _close() : _open();
  }

  // ---------------------------------------------------------------------
  // Field semantics

  /// Tells the surrounding field that this one has buttons of its own
  /// (clear, tag remove), so they stay separate nodes.
  void _report(DsFieldHooks? hooks, {bool separate = false}) {
    if (_hooks != hooks) {
      _hooks?.separateNodes = false;
      _hooks = hooks;
    }
    hooks?.separateNodes = separate;
  }

  // ---------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final scope = DsFieldScope.maybeOf(context);
    final enabled = _enabled;
    final canEdit = _canEdit;
    final error = widget.error || (scope?.hasError ?? false);
    final focused = enabled && _focus.hasFocus;
    final states = {
      if (focused) WidgetState.focused,
      if (enabled && _hovered && !focused) WidgetState.hovered,
      if (error) WidgetState.error,
      if (!enabled) WidgetState.disabled,
    };
    final a = DsAutocompleteStyle.resolveLayers(
      [
        DsAutocomplete.defaultStyle(t),
        DsAutocompleteTheme.of(context).style,
        widget.style,
      ],
      {if (!enabled) WidgetState.disabled},
    );
    // The tag the arrow keys made active.
    final active = DsAutocompleteStyle.resolveLayers(
      [
        DsAutocomplete.defaultStyle(t),
        DsAutocompleteTheme.of(context).style,
        widget.style,
      ],
      {WidgetState.selected, if (!enabled) WidgetState.disabled},
    );
    final fieldTheme = DsTextFieldTheme.of(context);
    final f = DsTextFieldStyle.resolveLayers(
      [
        DsTextField.defaultStyle(t),
        fieldTheme.style,
        fieldTheme.variants[DsTextFieldVariant.singleLine],
        a.fieldStyle,
      ],
      states,
      readOnly: widget.readOnly && enabled,
    );

    final multiple = widget.multiple;
    final tags = multiple ? widget.values : <T>[];
    final hasValue = multiple
        ? widget.values.isNotEmpty
        : (widget.value != null || _text.text.isNotEmpty);
    final showClear = widget.clearable && canEdit && hasValue;
    // Separate nodes whenever buttons can appear, so the tree does not
    // change shape as the value does.
    final separate = scope?.hooks != null && (widget.clearable || multiple);
    _report(scope?.hooks, separate: separate);

    final name = [if (separate) ?scope?.labelText, ?widget.semanticLabel];
    // The placeholder goes once there are tags; they say what is chosen.
    final placeholder = tags.isEmpty ? widget.placeholder : null;

    // The text: a bare text field inside the well, which draws the edge,
    // fill and focus for the tags and buttons too.
    Widget input = DsFieldScope(
      hasError: error,
      isRequired: scope?.isRequired ?? false,
      isLabelled: scope?.isLabelled ?? false,
      labelText: scope?.labelText,
      // With the buttons apart the text carries the field's message.
      messageText: separate ? scope?.messageText : null,
      child: DsTextField(
        controller: _text,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: enabled,
        readOnly: widget.readOnly,
        placeholder: placeholder,
        semanticLabel: name.isEmpty ? null : name.join('\n'),
        onChanged: _onTextChanged,
        onSubmitted: (_) => _commitEnter(),
        textInputAction: TextInputAction.done,
        // Typing filters the options; a spelling toolbar would cover them.
        spellCheck: false,
        style: (a.fieldStyle ?? const DsTextFieldStyle()).merge(_bare),
      ),
    );
    input = MergeSemantics(
      child: Semantics(
        expanded: canEdit ? _popup.isOpen : null,
        controlsNodes: _popup.isOpen ? {_popupId} : null,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: input,
        ),
      ),
    );
    // Without an app, the text field would bring the text editing keys
    // inside this key handler, and arrow keys would move the caret
    // instead of the active option. Bring them here, above it.
    if (context.findAncestorWidgetOfExactType<DefaultTextEditingShortcuts>() ==
        null) {
      input = DefaultTextEditingShortcuts(child: input);
    }

    final scaler = MediaQuery.textScalerOf(context);
    final iconSize = scaler.scale(f.iconSize!);
    final border = f.borderColor ?? const Color(0x00000000);
    final corners = t.radii.controlCorners(f.borderRadius, f.height!);
    // The tags nest in the field's corners, inset by the well's padding.
    final tagsInset = (a.tagsPadding ?? EdgeInsets.zero)
        .resolve(Directionality.of(context))
        .top;
    BorderRadiusGeometry tagCorners(DsAutocompleteStyle s) =>
        t.radii.nestedCorners(s.tagBorderRadius, corners, tagsInset);

    Widget content;
    if (multiple) {
      // Typed text needs a few characters of room after the last tag;
      // empty text only the caret and its 1px gap (as the text field
      // keeps), so it stays on the tags' line: no empty line below them.
      final caret = f.caretWidth! + 1;
      final labels = [for (final v in tags) _labelOf(v) ?? ''];
      // Without focus the tags may keep to one line; with it they all
      // show, for the arrow keys.
      final collapsed = widget.collapseTags && !focused && tags.isNotEmpty;
      content = TagFlow(
        gap: a.tagGap!,
        inputGap: a.inputGap!,
        inputMinWidth: _text.text.isEmpty
            ? caret
            : math.max(caret, scaler.scale(a.inputMinWidth!)),
        collapsed: collapsed,
        tagCount: tags.length,
        children: [
          for (final (i, v) in tags.indexed)
            _Tag(
              label: labels[i],
              style: i == _activeTag ? active : a,
              corners: tagCorners(i == _activeTag ? active : a),
              onRemove: canEdit ? () => _removeValue(v) : null,
              removeLabel: l10n.remove(labels[i]),
              focusNode: _removeFocus,
              wrapButton: _button,
              wrap: !collapsed,
            ),
          // One "+N" per possible count; the flow measures and shows one.
          if (collapsed)
            for (var hidden = 1; hidden <= tags.length; hidden++)
              _MoreTag(
                hidden: hidden,
                labels: labels,
                style: a,
                corners: tagCorners(a),
              ),
          input,
        ],
      );
      if (!t.motion.reduced) {
        // Wrapping tags grow the field on the tone spring.
        content = AnimatedSize(
          duration: t.motion.toneDuration,
          curve: t.motion.toneCurve,
          alignment: AlignmentDirectional.topStart,
          child: content,
        );
      }
    } else {
      content = input;
    }

    final well = FieldWell(
      duration: t.motion.toneDuration,
      curve: t.motion.toneCurve,
      minHeight: f.height!,
      padding: multiple && tags.isNotEmpty ? a.tagsPadding : f.padding,
      background: f.background,
      borderColor: border,
      borderWidth: f.borderWidth!,
      borderRadius: corners,
      shadows: f.shadows,
      focusShadows: f.focusShadows,
      focused: focused,
      child: Row(
        spacing: f.gap!,
        children: [
          Expanded(child: content),
          if (showClear)
            _button(
              ActionTapArea(
                visual: f.clearStyle!.height!,
                child: DsButton.icon(
                  size: DsSize.xs,
                  focusNode: _clearFocus,
                  style: f.clearStyle,
                  semanticLabel: l10n.clear,
                  onPressed: _clearAll,
                  icon: const DsIcon(DsIcons.x),
                ),
              ),
            ),
          if (error)
            ExcludeSemantics(
              child: DsIcon(
                DsIcons.circleAlert,
                size: iconSize,
                // Danger even while the edge shows focus; the cue is not
                // color alone.
                color:
                    f.errorIconColor ?? (border.a > 0 ? border : f.iconColor),
              ),
            ),
          // The chevron toggles the popup; keyboard users have Down and
          // Alt+Down, so it is not a stop or a node of its own (APG).
          if (canEdit)
            _button(
              ExcludeSemantics(
                child: ActionTapArea(
                  visual: f.revealStyle!.height!,
                  child: DsButton.icon(
                    size: DsSize.xs,
                    focusNode: _chevronFocus,
                    style: f.revealStyle,
                    semanticLabel: '',
                    onPressed: _toggle,
                    icon: DsSpringValue(
                      value: _popup.isOpen ? 1 : 0,
                      spring: t.motion.moveSpringOrNull,
                      builder: (context, v, child) =>
                          Transform.rotate(angle: v * math.pi, child: child),
                      child: const DsIcon(DsIcons.chevronDown),
                    ),
                  ),
                ),
              ),
            )
          else if (!widget.readOnly || !enabled)
            ExcludeSemantics(
              child: DsIcon(
                DsIcons.chevronDown,
                size: iconSize,
                color: f.iconColor,
              ),
            ),
        ],
      ),
    );

    Widget field = Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: MouseRegion(
        cursor: f.cursor ?? MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: well,
      ),
    );
    // Taps on the tags and buttons, like those in the popup, stay inside
    // the text field: they do not take its focus away.
    field = TextFieldTapRegion(child: field);

    field = DsAnchoredOverlay(
      controller: _popup,
      matchAnchorWidth: true,
      gap: DsSpace.s4,
      // Focus stays in the text (aria-activedescendant).
      focusOnOpen: false,
      tab: DsOverlayTab.close,
      overlayBuilder: (context) => _buildPopup(context, a, l10n),
      child: field,
    );

    // In an unbounded width (a Row) the field takes the text field's width.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedWidth
          ? field
          : SizedBox(width: f.width, child: field),
    );
  }

  /// The bare text inside the well: no fill, edge, padding or icons; the
  /// well draws them.
  static const _bare = DsTextFieldStyle(
    height: 0,
    padding: EdgeInsets.zero,
    background: Color(0x00000000),
    borderColor: Color(0x00000000),
    shadows: [],
    focusShadows: [],
    gap: 0,
    iconSize: 0,
  );

  Widget _buildPopup(
    BuildContext context,
    DsAutocompleteStyle a,
    DsLocalizations l10n,
  ) {
    final t = dsThemeOf(context);
    final panel = DsMenuStyle.resolveLayers([
      DsMenu.defaultStyle(t),
      DsMenuTheme.of(context).style,
      a.panelStyle,
    ], const {});
    final itemLayers = [
      DsMenuItem.defaultStyle(t),
      DsMenuItemTheme.of(context).style,
      a.optionStyle,
    ];
    final row = DsMenuItemStyle.resolveLayers(itemLayers, const {});
    final scope = DsFieldScope.maybeOf(this.context);
    final name = widget.semanticLabel ?? scope?.labelText;

    Widget body;
    if (_loading) {
      body = _Message(
        style: row,
        textStyle: a.messageStyle,
        leading: DsSpinner(style: DsSpinnerStyle(size: row.iconSize)),
        text: widget.loadingText ?? l10n.loading,
        live: false,
      );
    } else if (_customText case final custom?) {
      // Free text: what Enter takes, shown as the active row.
      body = Semantics(
        container: true,
        role: SemanticsRole.menu,
        label: name,
        explicitChildNodes: true,
        child: _CustomRow(
          label: l10n.useCustom(custom),
          layers: itemLayers,
          onTap: _takeCustom,
        ),
      );
    } else if (_results.isEmpty) {
      body = _Message(
        style: row,
        textStyle: a.messageStyle,
        text: widget.emptyText ?? l10n.selectNoResults,
        // Android cannot announce; the message speaks for itself there.
        live: !MediaQuery.supportsAnnounceOf(context),
      );
    } else {
      final iconColumn = _results.any((o) => o.leading != null);
      body = Semantics(
        container: true,
        role: SemanticsRole.menu,
        label: name,
        explicitChildNodes: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: a.maxHeight!),
          child: ListView.builder(
            controller: _scroll,
            primary: false,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _results.length,
            itemBuilder: (context, i) {
              final o = _results[i];
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  top: i == 0 ? 0 : panel.gap!,
                ),
                child: _OptionRow<T>(
                  index: i,
                  rows: _rows,
                  option: o,
                  query: _query,
                  layers: itemLayers,
                  style: a,
                  multiple: widget.multiple,
                  chosen: _isChosen(o.value),
                  active: i == _active,
                  // Focus stays in the text field, which draws the ring;
                  // the active option is a highlight.
                  iconColumn: iconColumn,
                  onTap: (touch) => _choose(o, touch: touch),
                  onHover: () {
                    if (_active == i && !_keyboardActive) return;
                    setState(() {
                      _active = i;
                      _keyboardActive = false;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );
    }
    return TextFieldTapRegion(
      // What the field's `controls` relation points at, in every state.
      child: Semantics(
        container: true,
        identifier: _popupId,
        explicitChildNodes: true,
        child: MatchWidth(
          minWidth: panel.minWidth ?? 0,
          // Drawn like every floating layer, so a glass menu style
          // (translucent fill and backdropFilter) frosts it too.
          child: DsSurface(
            padding: panel.padding,
            decoration: DsBoxDecoration(
              color: panel.background,
              borderRadius: panel.borderRadius ?? BorderRadius.zero,
              shadows: panel.shadows ?? const [],
            ),
            backdropFilter: panel.backdropFilter,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// One option of the popup: a menu row that is never focused; the field
/// keeps focus and marks the row active.
class _OptionRow<T> extends StatefulWidget {
  const _OptionRow({
    super.key,
    required this.index,
    required this.rows,
    required this.option,
    required this.query,
    required this.layers,
    required this.style,
    required this.multiple,
    required this.chosen,
    required this.active,
    required this.iconColumn,
    required this.onTap,
    required this.onHover,
  });

  final int index;
  final Map<int, BuildContext> rows;
  final DsSelectOption<T> option;
  final String query;
  final List<DsMenuItemStyle?> layers;
  final DsAutocompleteStyle style;
  final bool multiple;
  final bool chosen;
  final bool active;
  final bool iconColumn;

  /// Chooses the option; true when a tap did, false for an assistive
  /// action.
  final ValueChanged<bool> onTap;
  final VoidCallback onHover;

  @override
  State<_OptionRow<T>> createState() => _OptionRowState<T>();
}

class _OptionRowState<T> extends State<_OptionRow<T>> {
  @override
  void initState() {
    super.initState();
    widget.rows[widget.index] = context;
  }

  @override
  void didUpdateWidget(_OptionRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        widget.rows[oldWidget.index] == context) {
      widget.rows.remove(oldWidget.index);
    }
    widget.rows[widget.index] = context;
  }

  @override
  void dispose() {
    if (widget.rows[widget.index] == context) widget.rows.remove(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final o = widget.option;
    final states = {
      if (widget.active) WidgetState.hovered,
      if (!o.enabled) WidgetState.disabled,
    };
    final s = DsMenuItemStyle.resolveLayers(widget.layers, states);
    final fg = s.foreground ?? t.colors.text;
    final iconSize = s.iconSize!;
    final textStyle = (s.textStyle ?? const TextStyle()).copyWith(color: fg);
    final Widget? trailing = widget.chosen
        ? DsIcon(
            DsIcons.check,
            size: iconSize,
            color: o.enabled ? widget.style.checkColor : fg,
          )
        : o.detail == null
        ? null
        : Text(o.detail!, style: s.shortcutStyle, maxLines: 1);
    final visual = AnimatedContainer(
      duration: t.motion.toneDuration,
      curve: t.motion.toneCurve,
      constraints: BoxConstraints(minHeight: s.height!),
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: s.background,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: fg, size: iconSize),
        child: Row(
          spacing: s.gap ?? DsSpace.s12,
          children: [
            o.leading ?? (widget.iconColumn ? SizedBox(width: iconSize) : null),
            Expanded(
              child: Text.rich(
                highlightMatch(
                  o.label,
                  widget.query,
                  style: textStyle,
                  match: widget.style.matchStyle,
                ),
                // As menu options: wraps once, then an ellipsis.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ].whereType<Widget>().toList(),
        ),
      ),
    );
    return Semantics(
      container: true,
      role: widget.multiple
          ? SemanticsRole.menuItemCheckbox
          : SemanticsRole.menuItemRadio,
      checked: widget.chosen,
      enabled: o.enabled,
      label: o.label,
      hint: o.detail,
      onTap: o.enabled ? () => widget.onTap(false) : null,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: o.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        // Only a moving pointer takes the active row: rows scrolling under
        // a still one do not steal it from the keyboard.
        onHover: (_) {
          if (o.enabled && !widget.active) widget.onHover();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: o.enabled ? () => widget.onTap(true) : null,
          child: visual,
        ),
      ),
    );
  }
}

/// The typed text an empty list offers ("Use “Ankara”"): a menu row in
/// the active highlight, since Enter takes it, with a plus in the leading
/// slot.
class _CustomRow extends StatelessWidget {
  const _CustomRow({
    required this.label,
    required this.layers,
    required this.onTap,
  });

  final String label;
  final List<DsMenuItemStyle?> layers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsMenuItemStyle.resolveLayers(layers, const {
      WidgetState.hovered,
    });
    final fg = s.foreground ?? t.colors.text;
    final iconSize = s.iconSize!;
    return Semantics(
      container: true,
      role: SemanticsRole.menuItem,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: s.height!),
            padding: s.padding,
            decoration: DsBoxDecoration(
              color: s.background,
              borderRadius: s.borderRadius ?? BorderRadius.zero,
            ),
            child: Row(
              spacing: s.gap ?? DsSpace.s12,
              children: [
                DsIcon(DsIcons.plus, size: iconSize, color: fg),
                Expanded(
                  child: Text(
                    label,
                    style: (s.textStyle ?? const TextStyle()).copyWith(
                      color: fg,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "No results" or "Loading" in the popup, sized like a row.
class _Message extends StatelessWidget {
  const _Message({
    required this.style,
    required this.textStyle,
    required this.text,
    required this.live,
    this.leading,
  });

  final DsMenuItemStyle style;
  final TextStyle? textStyle;
  final String text;
  final bool live;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: live,
    child: Container(
      constraints: BoxConstraints(minHeight: style.height!),
      padding: style.padding,
      child: IconTheme.merge(
        data: IconThemeData(color: textStyle?.color, size: style.iconSize),
        child: Row(
          spacing: style.gap ?? DsSpace.s12,
          children: [
            ?leading,
            Expanded(child: Text(text, style: textStyle)),
          ],
        ),
      ),
    ),
  );
}

/// A chosen value inside a [DsMultiSelect]: a soft tag with a remove
/// button.
///
/// A label wider than the line wraps onto more lines (large text, a narrow
/// field), so no tag loses its text; collapsed tags keep to one line and
/// ellipsize instead. In a field narrower than the tag's padding and
/// remove button, the tag is clipped at the field's edge.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.style,
    required this.corners,
    required this.onRemove,
    required this.removeLabel,
    required this.focusNode,
    required this.wrapButton,
    required this.wrap,
  });

  final String label;
  final DsAutocompleteStyle style;

  /// The tag's corners, nested in the field's.
  final BorderRadiusGeometry corners;
  final VoidCallback? onRemove;
  final String removeLabel;
  final FocusNode focusNode;
  final Widget Function(Widget) wrapButton;

  /// Whether a label wider than the line wraps; else it ellipsizes.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final border = s.tagBorderColor ?? const Color(0x00000000);
    final fg = s.tagForeground;
    var remove = s.tagRemoveStyle!;
    // The remove button nests in the tag's corners, inset as far as it
    // sits from the tag's top and bottom.
    if (remove.borderRadius == null) {
      final inset = math.max(0.0, (s.tagHeight! - remove.height!) / 2);
      remove = remove.merge(
        DsButtonStyle(
          borderRadius: DsTheme.radiiOf(context)
              .nestedCorners(null, corners, inset),
        ),
      );
    }
    // Without a remove button (disabled) the tag is even on both sides.
    final direction = Directionality.of(context);
    var padding = s.tagPadding!.resolve(direction);
    if (onRemove == null) {
      padding = direction == TextDirection.ltr
          ? padding.copyWith(right: padding.left)
          : padding.copyWith(left: padding.right);
    }
    // The narrowest the tag lays out: its padding and remove button, the
    // label at no width. A narrower line clips the tag instead of
    // overflowing it.
    final floor =
        padding.horizontal +
        (onRemove == null ? 0.0 : s.tagGapInside! + remove.height!);
    return Semantics(
      container: true,
      child: ConstraintsTransformBox(
        alignment: AlignmentDirectional.centerStart,
        clipBehavior: Clip.hardEdge,
        constraintsTransform: (c) => c.maxWidth >= floor
            ? c
            : c.copyWith(minWidth: floor, maxWidth: floor),
        child: Container(
          constraints: BoxConstraints(minHeight: s.tagHeight!),
          padding: padding,
          decoration: DsBoxDecoration(
            color: s.tagBackground,
            borderRadius: corners,
            shadows: [if (border.a > 0) DsShadow.innerRing(border)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: s.tagGapInside!,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: wrap ? null : 1,
                  overflow: wrap ? null : TextOverflow.ellipsis,
                  style: (s.tagTextStyle ?? const TextStyle()).copyWith(
                    color: fg,
                  ),
                ),
              ),
              if (onRemove != null)
                wrapButton(
                  ActionTapArea(
                    visual: remove.height!,
                    child: DsButton.icon(
                      size: DsSize.xs,
                      focusNode: focusNode,
                      style: remove,
                      semanticLabel: removeLabel,
                      onPressed: onRemove,
                      icon: const DsIcon(DsIcons.x),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "+N" of collapsed tags: a tag's look without the remove button,
/// read as "N more" with the hidden labels. Not a button or a stop: a tap
/// lands on the field, which takes focus and shows every tag.
class _MoreTag extends StatelessWidget {
  const _MoreTag({
    required this.hidden,
    required this.labels,
    required this.style,
    required this.corners,
  });

  /// How many tags it stands for: the last ones of [labels].
  final int hidden;
  final List<String> labels;
  final DsAutocompleteStyle style;

  /// A tag's corners, nested in the field's.
  final BorderRadiusGeometry corners;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final l10n = DsLocalizations.of(context);
    final border = s.tagBorderColor ?? const Color(0x00000000);
    // Even on both sides, as a tag without its remove button.
    final direction = Directionality.of(context);
    final padding = s.tagPadding!.resolve(direction);
    return HiddenTagsSemantics(
      label: l10n.moreCount(hidden),
      labels: labels,
      hidden: hidden,
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minHeight: s.tagHeight!),
          padding: direction == TextDirection.ltr
              ? padding.copyWith(right: padding.left)
              : padding.copyWith(left: padding.right),
          decoration: DsBoxDecoration(
            color: s.tagBackground,
            borderRadius: corners,
            shadows: [if (border.a > 0) DsShadow.innerRing(border)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.overflowCount(hidden),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (s.tagTextStyle ?? const TextStyle()).copyWith(
                    color: s.tagForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
