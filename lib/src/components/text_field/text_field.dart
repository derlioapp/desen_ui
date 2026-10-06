import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/edge_fade_scroll.dart';
import '../../foundation/platform.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/anchored_overlay.dart';
import '../../overlay/modal_route.dart';
import '../../painting/decoration.dart';
import '../../painting/numeric_span.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../field/field.dart';
import '../field/field_well.dart';
import '../menu/shortcut.dart';
import '../selection/error_edge.dart';
import 'field_fit.dart';
import 'text_field_style.dart';
import 'text_field_variant.dart';
import 'text_magnifier.dart';
import 'text_selection.dart';

export 'input_issue.dart';

part 'search_field.dart';

/// A single- or multi-line text field: a well
/// with an inner edge, on Flutter's own text editing, so typing, IME
/// composition, autofill, keyboard shortcuts and selection behave as on
/// each platform.
///
/// ```dart
/// DsField(
///   label: const Text('E-posta'),
///   errorText: invalid ? 'Geçerli bir adres girin.' : null,
///   required: true,
///   child: DsTextField(
///     controller: email,
///     keyboardType: TextInputType.emailAddress,
///     autofillHints: const [AutofillHints.email],
///     placeholder: 'ad@ornek.com',
///   ),
/// )
/// ```
///
/// **Selection.** With a mouse: click places the caret, drag selects,
/// double-click selects a word, triple-click a paragraph, Shift+click
/// extends. On touch: tap places the caret, long press selects a word,
/// and handles in the caret color drag the ends (lollipops on iOS,
/// teardrops elsewhere). While a handle is dragged or a long press
/// selects, a loupe enlarges the text under the finger
/// ([DsTextMagnifier]). The selection is the soft selection fill; text
/// stays at least 4.5:1 on it.
///
/// **Edit menu.** On iOS the native edit menu
/// ([SystemContextMenu]) where the system supports it; on Android, and on
/// iOS as a fallback, Desen's floating toolbar ([DsTextSelectionToolbar]).
/// On desktop a right click or Shift+F10 opens a Desen menu
/// ([DsTextContextMenu]) with Cut, Copy, Paste and Select all and their
/// shortcuts, disabled when they cannot run. On the web the browser's own
/// menu stays (spellcheck, translate, autofill); call
/// `BrowserContextMenu.disableContextMenu()` once at startup to use
/// Desen's instead. Menus, handles and the loupe need an [Overlay]; without
/// one the field still types, selects and copies with the keyboard.
///
/// **Focus.** The field shows focus whenever it has it, also after a click
/// or tap: the edge turns 2px in the focus color, drawn inside the box so
/// nothing moves. That one line is the whole focus look, with no ring
/// around it (a style can add one through `focusShadows`); a field with an
/// error shows it too, and keeps its error icon and message. A text field
/// is where typing goes, so browsers treat it as `:focus-visible` on click
/// too.
///
/// **Read-only.** A [readOnly] field has no fill and a faint hairline
/// edge, and its text keeps full contrast: it reads as a value on the
/// page, not as a disabled field (which stays dimmed). The text still
/// selects and copies, and focus still shows. The clear button and a
/// picker's popup button go; the show-password button stays.
///
/// **Field.** Inside a [DsField] the field takes its error look and its
/// required state from the field, and the field's label names it. Pass
/// [error] when it stands alone. Errors show a 2px danger edge and an icon,
/// not color alone.
///
/// **Slots and buttons.** [leading] and [trailing] take icons or short
/// text (a unit), colored and sized by the style. Icons sit the style's
/// `gap` from the text. Text (a [Text], as `Text('kg')` or
/// `Text('https://')`) is an affix of the value: it sits the closer
/// `affixGap` from it, and trailing text follows the typed text (or the
/// placeholder) instead of the field's end, as a number field's unit does.
/// In a multi-line field trailing text stays at the end. [clearable] adds a clear
/// button while there is text; [revealable] adds a show-password button
/// to an [obscureText] field. The buttons keep a full tap target
/// ([DsSizes.minTapTarget] wide, the field's height tall) without making
/// the field taller, and stay separate buttons for screen readers. The
/// error icon comes last. The clear button is not a Tab stop (Escape or
/// select-all and delete do the same from the keyboard); the
/// show-password button is.
///
/// **Counter.** With [maxLength] a tabular counter ("12 / 100") shows under
/// the field, at the end of a [DsField]'s message row, so the description
/// or the error keeps the start. The limit is enforced by default; with
/// [maxLengthEnforcement] set to [MaxLengthEnforcement.none] it is a soft
/// limit, as on GitHub: typing goes on, the counter turns to the danger
/// color and the field shows its error look. Screen readers hear the count
/// with the field, and near the limit (the last tenth) a polite
/// announcement says how many characters are left.
///
/// **Multi-line.** [DsTextField.multiline] grows with the text from
/// `minLines` to `maxLines`, then scrolls; Enter adds a line. It has no
/// resize handle: growing with the text does the job on every platform.
///
/// Anatomy: well (fill + inner edge), leading slot, text (or placeholder),
/// trailing slot, clear button, show-password button, error icon; counter
/// below. `DsFieldSurface` draws the same well around content of your own.
///
/// | Key | Action |
/// |---|---|
/// | Tab / Shift+Tab | Next / previous field (the clear button is skipped) |
/// | Enter | Submits; a new line in a multi-line field |
/// | Shift+F10, context menu key | Edit menu (desktop) |
/// | Escape | In a [DsSearchField], clears the text |
///
/// **Caret.** 2px, rounded, in the indicator color; it blinks as the
/// platform does (Apple platforms fade) and stays still under reduced
/// motion.
///
/// Works without `DsScope` or `DsApp`: the keyboard shortcuts that
/// `WidgetsApp` provides are added when no ancestor has them.
class DsTextField extends StatefulWidget {
  /// Creates a single-line text field.
  const DsTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.revealable = false,
    this.clearable = false,
    this.keyboardType,
    this.textInputAction,
    this.onEditingComplete,
    this.autofillHints,
    this.autocorrect,
    this.enableSuggestions,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.placeholder,
    this.leading,
    this.trailing,
    this.semanticLabel,
    this.error = false,
    this.style,
  }) : maxLines = 1,
       minLines = null,
       _variant = DsTextFieldVariant.singleLine,
       _shortcut = null,
       assert(
         controller == null || initialValue == null,
         'Pass the initial text through the controller.',
       ),
       assert(
         !revealable || obscureText,
         'Only an obscured field can be revealed.',
       ),
       assert(maxLength == null || maxLength > 0);

  /// Creates a multi-line text field (a text area): it is
  /// [minLines] tall, grows with the text up to [maxLines], then scrolls.
  /// A null [maxLines] grows without limit. Enter adds a new line.
  const DsTextField.multiline({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autocorrect,
    this.enableSuggestions,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.minLines = 3,
    this.maxLines = 8,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.placeholder,
    this.semanticLabel,
    this.error = false,
    this.style,
  }) : onSubmitted = null,
       onEditingComplete = null,
       obscureText = false,
       revealable = false,
       clearable = false,
       leading = null,
       trailing = null,
       _variant = DsTextFieldVariant.multiline,
       _shortcut = null,
       assert(
         controller == null || initialValue == null,
         'Pass the initial text through the controller.',
       ),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         maxLines == null || minLines == null || maxLines >= minLines,
         'minLines cannot be more than maxLines.',
       ),
       assert(maxLength == null || maxLength > 0);

  /// A search field ([DsSearchField] builds it).
  const DsTextField._search({
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.placeholder,
    this.leading,
    this.semanticLabel,
    this.error = false,
    this.style,
    this._shortcut,
  }) : obscureText = false,
       revealable = false,
       clearable = true,
       keyboardType = TextInputType.text,
       textInputAction = TextInputAction.search,
       onEditingComplete = null,
       autofillHints = null,
       autocorrect = null,
       enableSuggestions = null,
       textCapitalization = TextCapitalization.none,
       textAlign = TextAlign.start,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       maxLengthEnforcement = null,
       inputFormatters = null,
       trailing = null,
       _variant = DsTextFieldVariant.search,
       assert(
         controller == null || initialValue == null,
         'Pass the initial text through the controller.',
       );

  /// Holds the text and the selection; one is created when null.
  final TextEditingController? controller;

  /// The starting text of the field's own controller.
  final String? initialValue;

  /// Called on every change the user makes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (Enter, or the keyboard's action key).
  final ValueChanged<String>? onSubmitted;

  /// Focus node of the field; one is created when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// Whether the field can be focused and edited. A disabled field keeps
  /// its shape in the disabled colors and is skipped by Tab.
  final bool enabled;

  /// Whether the text is fixed. It can still be focused, selected and
  /// copied; it shows the read-only look ([DsTextFieldStyle.readOnly]).
  final bool readOnly;

  /// Hides the text behind bullets (passwords). Copy and cut are off.
  final bool obscureText;

  /// Adds a show-password button to an [obscureText] field. The selection
  /// and focus stay as the text is shown or hidden.
  final bool revealable;

  /// Adds a clear button while the field has text and can be edited.
  /// Clearing keeps focus in the field (and focuses it) and reports the
  /// empty text to [onChanged].
  final bool clearable;

  /// The on-screen keyboard to show; inferred from [autofillHints] and
  /// [maxLines] when null.
  final TextInputType? keyboardType;

  /// The on-screen keyboard's action key.
  final TextInputAction? textInputAction;

  /// Called when the user finishes editing (Enter, or the keyboard's
  /// action key), before [onSubmitted].
  ///
  /// Given, it replaces what the field does by itself at that point:
  /// moving focus for [TextInputAction.next] and
  /// [TextInputAction.previous], closing the on-screen keyboard on a
  /// phone. As in Flutter's own text fields.
  final VoidCallback? onEditingComplete;

  /// What the field holds, for the platform's autofill (an
  /// [AutofillGroup] collects related fields).
  final Iterable<String>? autofillHints;

  /// Whether the platform corrects spelling as the user types.
  ///
  /// Null decides by what the field holds, as browsers and the platforms'
  /// own fields do: off for text that must stay exactly as typed (an
  /// [obscureText] field, the [TextInputType.emailAddress],
  /// [TextInputType.url] and [TextInputType.visiblePassword] keyboards,
  /// or, without a [keyboardType], an email, URL, user name, password or
  /// one-time code in [autofillHints]); on for other text. Such literal
  /// text also gets no smart dashes or quotes.
  final bool? autocorrect;

  /// Whether the on-screen keyboard offers word suggestions.
  ///
  /// Null decides as for [autocorrect]: off for text that must stay
  /// exactly as typed, on for other text.
  final bool? enableSuggestions;

  /// Whether the on-screen keyboard starts words or sentences with a
  /// capital letter. [TextCapitalization.none] by default; names suit
  /// [TextCapitalization.words], prose [TextCapitalization.sentences].
  final TextCapitalization textCapitalization;

  /// How the text lines up in the field, the placeholder with it.
  /// [TextAlign.start] by default; [TextAlign.end] suits amounts.
  final TextAlign textAlign;

  /// Most lines shown before the field scrolls; null grows without limit.
  /// 1 for a single-line field; see [DsTextField.multiline].
  final int? maxLines;

  /// Fewest lines the field is tall.
  final int? minLines;

  /// Most characters (grapheme clusters, as people count them). Shows a
  /// counter; screen readers hear the limit and the current length.
  final int? maxLength;

  /// How [maxLength] is kept: null enforces it as the platform does (after
  /// an input method finishes composing where that matters);
  /// [MaxLengthEnforcement.none] makes it a soft limit that typing can go
  /// past, shown as an error.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Formatters run on each change, before [maxLength] is enforced.
  final List<TextInputFormatter>? inputFormatters;

  /// Shown while the field is empty; screen readers hear it as a hint.
  final String? placeholder;

  /// Before the text, e.g. an icon; icons take the style's icon color and
  /// size. A [Text] ("https://") sits close to the value (see the class
  /// docs).
  final Widget? leading;

  /// After the text, e.g. a unit; before the field's own buttons. A [Text]
  /// ("kg") follows the value (see the class docs).
  final Widget? trailing;

  /// Names the field for screen readers when no [DsField] label does.
  final String? semanticLabel;

  /// Shows the error look; a surrounding [DsField] with an error sets it
  /// too.
  final bool error;

  /// Style laid over the theme and defaults.
  final DsTextFieldStyle? style;

  final DsTextFieldVariant _variant;

  /// A search field's shortcut hint, shown while it is empty.
  final String? _shortcut;

  /// Desen's default text field style under [theme] for [variant].
  static DsTextFieldStyle defaultStyle(
    DsThemeData theme, {
    DsTextFieldVariant variant = DsTextFieldVariant.singleLine,
  }) {
    final k = theme.colors;
    final edge = dsErrorEdge(theme);
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    // A field is a control: rounded like a button of its height. No radius
    // here, for the shortcut hint either: both follow whatever height the
    // layers settle on (DsRadii.controlCorners).
    final height = theme.sizes.md;
    final base = DsTextFieldStyle(
      height: height,
      width: 240,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s8,
      ),
      background: k.field,
      borderColor: k.borderField,
      borderWidth: 1,
      foreground: k.text,
      placeholderColor: k.textSubtle,
      iconColor: k.textMuted,
      iconSize: 16,
      textStyle: theme.typography.body,
      // The select's icon-to-text space.
      gap: DsSpace.s12,
      // About a space of the body text: a unit or "https://" reads with
      // the value ("72 kg"), not as a separate part.
      affixGap: DsSpace.s4,
      caretColor: k.indicator,
      caretWidth: 2,
      selectionColor: k.selection,
      handleColor: k.indicator,
      // Apple's lollipop knob; Android's teardrop is larger.
      handleSize: apple ? 12 : 20,
      composingStyle: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: k.indicator,
        decorationThickness: 2,
      ),
      shadows: const [],
      counterStyle: theme.typography
          .numeric(theme.typography.caption)
          .copyWith(color: k.textSubtle),
      // Over the limit: the danger text color, bolder.
      counterOverStyle: TextStyle(
        color: k.danger.text,
        fontWeight: FontWeight.w600,
      ),
      counterGap: DsSpace.s6,
      // A small filled circle; the cross darkens under
      // the pointer.
      clearStyle: DsButtonStyle(
        height: 22,
        borderRadius: BorderRadius.circular(11),
        background: k.channelStrong,
        foreground: k.textMuted,
        iconSize: 14,
        hovered: DsButtonStyle(foreground: k.text),
        pressed: DsButtonStyle(foreground: k.text),
      ),
      revealStyle: DsButtonStyle(
        height: 22,
        borderRadius: BorderRadius.circular(11),
        foreground: k.textMuted,
        iconSize: 16,
        hovered: DsButtonStyle(foreground: k.text),
        pressed: DsButtonStyle(foreground: k.text),
      ),
      shortcutStyle: theme.typography
          .mono(theme.typography.overline)
          .copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: k.textMuted,
          ),
      shortcutBackground: k.hover,
      shortcutPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s8,
        vertical: DsSpace.s3,
      ),
      // No ring around a field: its focus edge is the one focus line.
      focusShadows: const [],
      cursor: SystemMouseCursors.text,
      // The well's edge strengthens, as a checkbox's does.
      hovered: DsTextFieldStyle(borderColor: k.textSubtle),
      // Focus is one line: the edge turns 2px in the focus color, inside
      // the box so nothing moves, with a focus-colored leading icon.
      focused: DsTextFieldStyle(
        borderColor: k.focus,
        borderWidth: 2,
        iconColor: k.focus,
      ),
      // Thicker, so the error is not told by hue alone.
      // The error icon takes the edge's color; slot icons keep theirs.
      // Focused, the edge shows focus; the icon and the message keep
      // telling the error.
      error: DsTextFieldStyle(
        borderColor: edge,
        borderWidth: 2,
        errorIconColor: edge,
        focused: DsTextFieldStyle(borderColor: k.focus),
      ),
      // Read-only reads as text on the page, not as a well to type in: no
      // fill, the decorative hairline for an edge, the text at full
      // contrast. It still selects, copies and shows focus.
      readOnly: DsTextFieldStyle(
        background: const Color(0x00000000),
        borderColor: k.border,
        borderWidth: 1,
        shadows: const [],
        focused: DsTextFieldStyle(borderColor: k.focus, borderWidth: 2),
      ),
      // Disabled keeps the shape: a faint edge on the disabled fill,
      // as the select.
      disabled: DsTextFieldStyle(
        background: k.disabled,
        borderColor: k.border,
        borderWidth: 1,
        shadows: const [],
        foreground: k.onDisabled,
        placeholderColor: k.onDisabled,
        iconColor: k.onDisabled,
        cursor: SystemMouseCursors.forbidden,
      ),
    );
    final form = switch (variant) {
      DsTextFieldVariant.singleLine => null,
      // The text area: 12 all around, airy lines.
      DsTextFieldVariant.multiline => const DsTextFieldStyle(
        padding: EdgeInsetsDirectional.all(DsSpace.s12),
        textStyle: TextStyle(height: 1.5),
      ),
      // Search is drawn as a control, like a secondary button:
      // control fill, soft edge and lift; the magnifier and the
      // placeholder tell it is a field.
      DsTextFieldVariant.search => DsTextFieldStyle(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DsSpace.s16,
          DsSpace.s8,
          DsSpace.s8,
          DsSpace.s8,
        ),
        background: k.control,
        borderColor: k.borderControl,
        shadows: theme.shadows.controlLift,
        iconColor: k.textSubtle,
        hovered: DsTextFieldStyle(
          background: k.controlHover,
          borderColor: k.borderControl,
        ),
      ),
    };
    return base.merge(form);
  }

  @override
  State<DsTextField> createState() => _DsTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('controller', controller, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(FlagProperty('obscureText', value: obscureText, ifTrue: 'obscured'))
      ..add(FlagProperty('revealable', value: revealable, ifTrue: 'revealable'))
      ..add(FlagProperty('clearable', value: clearable, ifTrue: 'clearable'))
      ..add(EnumProperty('variant', _variant))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('minLines', minLines, defaultValue: null))
      ..add(IntProperty('maxLength', maxLength, defaultValue: null))
      ..add(
        EnumProperty(
          'maxLengthEnforcement',
          maxLengthEnforcement,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('placeholder', placeholder, defaultValue: null))
      ..add(DiagnosticsProperty('autocorrect', autocorrect, defaultValue: null))
      ..add(
        DiagnosticsProperty(
          'enableSuggestions',
          enableSuggestions,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty(
          'textCapitalization',
          textCapitalization,
          defaultValue: TextCapitalization.none,
        ),
      )
      ..add(EnumProperty('textAlign', textAlign, defaultValue: TextAlign.start))
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsTextFieldState extends State<DsTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get selectionEnabled => widget.enabled;

  late final _gestures = _GestureBuilder(this);
  final _box = GlobalKey();
  final _menu = DsOverlayController();
  Offset _menuAt = Offset.zero;

  /// While the desktop menu holds focus and until it gives it back, the
  /// field must not select everything on refocus (desktop single-line
  /// fields select all when focused from outside).
  bool _keepSelectionOnFocus = false;

  bool _hovered = false;
  bool _showHandles = false;

  /// Whether a revealable password shows its text.
  bool _revealed = false;

  /// The highest [FieldYield] order that gave way in the last layout, or
  /// -1: hidden buttons leave focus and the semantics tree, and a hidden
  /// clear button leaves its action on the field.
  int _yielded = -1;

  /// The clear button is not a Tab stop and never takes focus.
  final _clearFocus = FocusNode(
    debugLabel: 'DsTextField clear',
    skipTraversal: true,
    canRequestFocus: false,
  );

  /// The field this one reports its counter and buttons to.
  DsFieldHooks? _hooks;

  /// The text length last seen, for announcements near the limit.
  int? _lastCount;
  _StaticCaret? _staticCaret;
  _StaticCaret? _paintedCaret;
  DsTextSelectionControls? _controls;

  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialValue));

  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  EditableTextState? get _editable => editableTextKey.currentState;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
    _controller.addListener(_onText);
    _menu.addListener(_onMenu);
    _lastCount = _controller.text.characters.length;
  }

  @override
  void didUpdateWidget(DsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocus);
      if (widget.focusNode != null) {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
      _focusNode.addListener(_onFocus);
    }
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      } else if (oldWidget.controller != null) {
        // Taking over: keep the text the outside controller had.
        _ownController = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
      }
      _controller.addListener(_onText);
    }
    if (!widget.enabled && _menu.isOpen) _menu.close();
    if (!widget.obscureText) _revealed = false;
  }

  @override
  void dispose() {
    _report(null);
    _clearFocus.dispose();
    _focusNode.removeListener(_onFocus);
    _controller.removeListener(_onText);
    _menu
      ..removeListener(_onMenu)
      ..dispose();
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    _staticCaret?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focusNode.hasFocus) _keepSelectionOnFocus = _menu.isOpen;
    _staticCaret?.refresh();
    setState(() {});
  }

  void _onText() {
    _announceCount();
    // The placeholder and the length read by screen readers follow it.
    setState(() {});
  }

  /// Near the limit, says politely how many characters are left: when the
  /// count enters the last tenth, when it reaches the limit, and when it
  /// goes over a soft limit. Deleting is not announced.
  void _announceCount() {
    final count = _controller.text.characters.length;
    final before = _lastCount;
    _lastCount = count;
    final max = widget.maxLength;
    if (max == null || before == null || count <= before) return;
    if (!mounted || !MediaQuery.supportsAnnounceOf(context)) return;
    final near = math.max(1, (max / 10).ceil());
    final left = max - count, leftBefore = max - before;
    final l10n = DsLocalizations.of(context);
    final String message;
    if (left < 0 && leftBefore >= 0) {
      message = l10n.charactersOver(-left);
    } else if (left >= 0 &&
        ((left <= near && leftBefore > near) ||
            (left == 0 && leftBefore > 0))) {
      message = l10n.charactersRemaining(left);
    } else {
      return;
    }
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// Tells the surrounding field about the counter and the buttons.
  void _report(
    DsFieldHooks? hooks, {
    Widget? counter,
    Object? key,
    bool separate = false,
  }) {
    if (_hooks != hooks) {
      _hooks?.setMessageEnd(null);
      _hooks?.separateNodes = false;
      _hooks = hooks;
    }
    hooks?.setMessageEnd(counter, key: key);
    hooks?.separateNodes = separate;
  }

  /// Empties the field, keeps (or takes) focus and reports the change.
  void _clear() {
    _controller.value = TextEditingValue.empty;
    widget.onChanged?.call('');
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  void _toggleReveal() => setState(() => _revealed = !_revealed);

  void _onYield(int level) {
    if (mounted && level != _yielded) setState(() => _yielded = level);
  }

  void _onMenu() {
    if (!_menu.isOpen) {
      // Focus comes back in a microtask, before the next frame; after
      // that, refocusing from outside selects all again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_menu.isOpen && _keepSelectionOnFocus) {
          setState(() => _keepSelectionOnFocus = false);
        }
      });
    }
    setState(() {});
  }

  bool get _overlayAvailable =>
      Overlay.maybeOf(context, rootOverlay: true) != null;

  /// Whether a right click opens Desen's desktop menu: on desktop, with
  /// an overlay, and on the web only when the app turned the browser's
  /// own menu off.
  bool get _usesDesktopMenu {
    if (kIsWeb && BrowserContextMenu.enabled) return false;
    if (!_overlayAvailable) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  /// Opens the desktop menu at [global], or at the caret when null.
  void _openMenu([Offset? global]) {
    final editable = _editable;
    final box = _box.currentContext?.findRenderObject();
    if (editable == null || box is! RenderBox || !widget.enabled) return;
    var at = global;
    if (at == null) {
      final selection = _controller.selection;
      final render = editable.renderEditable;
      final caret = selection.isValid
          ? render.getLocalRectForCaret(selection.extent)
          : Rect.zero;
      at = render.localToGlobal(caret.bottomLeft);
    }
    editable.clipboardStatus.update();
    setState(() {
      _menuAt = box.globalToLocal(at!);
      _keepSelectionOnFocus = true;
    });
    _menu
      ..close()
      ..open();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // A search field: Escape clears the text first; on an empty field it
    // goes on to the enclosing layer (a dialog closes). While an input
    // method is composing, Escape is its own (it cancels the composition).
    final composing = _controller.value.composing;
    if (key == LogicalKeyboardKey.escape &&
        widget._variant == DsTextFieldVariant.search &&
        _controller.text.isNotEmpty &&
        !widget.readOnly &&
        !(composing.isValid && !composing.isCollapsed)) {
      _clear();
      return KeyEventResult.handled;
    }
    if (!_usesDesktopMenu) return KeyEventResult.ignored;
    final shiftF10 =
        key == LogicalKeyboardKey.f10 &&
        HardwareKeyboard.instance.isShiftPressed;
    if (!shiftF10 && key != LogicalKeyboardKey.contextMenu) {
      return KeyEventResult.ignored;
    }
    _openMenu();
    return KeyEventResult.handled;
  }

  void _onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final show = _shouldShowHandles(cause);
    if (show != _showHandles) setState(() => _showHandles = show);
    final editable = _editable;
    if (editable == null) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS || TargetPlatform.macOS:
        if (cause == SelectionChangedCause.longPress) {
          editable.bringIntoView(selection.extent);
        }
      case TargetPlatform.android ||
          TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) {
          editable.bringIntoView(selection.extent);
        }
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS ||
          TargetPlatform.linux ||
          TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) editable.hideToolbar();
      case TargetPlatform.iOS ||
          TargetPlatform.android ||
          TargetPlatform.fuchsia:
        break;
    }
  }

  /// Handles appear for touch selection, as Flutter's own fields do.
  bool _shouldShowHandles(SelectionChangedCause? cause) {
    if (!_gestures.shouldShowSelectionHandles) return false;
    if (cause == SelectionChangedCause.keyboard) return false;
    if (widget.readOnly && _controller.selection.isCollapsed) return false;
    if (!widget.enabled) return false;
    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.stylusHandwriting) {
      return true;
    }
    return _controller.text.isNotEmpty;
  }

  /// Whether the text must stay exactly as typed (an address, a password,
  /// a code), so the platform neither corrects nor suggests: see
  /// [DsTextField.autocorrect].
  bool get _literal {
    if (widget.obscureText) return true;
    if (widget.keyboardType case final type?) {
      return type == TextInputType.emailAddress ||
          type == TextInputType.url ||
          type == TextInputType.visiblePassword;
    }
    return widget.autofillHints?.any(_literalHints.contains) ?? false;
  }

  static const _literalHints = {
    AutofillHints.email,
    AutofillHints.url,
    AutofillHints.username,
    AutofillHints.newUsername,
    AutofillHints.password,
    AutofillHints.newPassword,
    AutofillHints.oneTimeCode,
  };

  void _onHandleTapped() {
    if (_controller.selection.isCollapsed) _editable?.toggleToolbar();
  }

  /// Enter on a single-line field: on desktop and the web focus stays, as
  /// in a browser; on phones the keyboard closes. Next and previous move
  /// focus.
  void _onEditingComplete() {
    _controller.clearComposing();
    if (widget.onEditingComplete case final callback?) {
      callback();
      return;
    }
    final action =
        widget.textInputAction ??
        (_multiline ? TextInputAction.newline : TextInputAction.done);
    switch (action) {
      case TextInputAction.next:
        _focusNode.nextFocus();
      case TextInputAction.previous:
        _focusNode.previousFocus();
      case TextInputAction.newline:
        break;
      default:
        final touch = switch (defaultTargetPlatform) {
          TargetPlatform.iOS ||
          TargetPlatform.android ||
          TargetPlatform.fuchsia => true,
          _ => false,
        };
        if (touch) _focusNode.unfocus();
    }
  }

  bool get _multiline => widget.maxLines != 1;

  Widget _buildContextMenu(BuildContext context, EditableTextState editable) {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        SystemContextMenu.isSupported(context)) {
      return SystemContextMenu.editableText(editableTextState: editable);
    }
    // The toolbar lives in the root overlay; carry over the theme,
    // direction and strings between the field and it.
    final captured = DsCapturedThemes.capture(
      from: this.context,
      to: Overlay.maybeOf(this.context, rootOverlay: true)?.context,
    );
    return captured.wrap(
      DsTextSelectionToolbar(
        anchors: editable.contextMenuAnchors,
        buttonItems: editable.contextMenuButtonItems,
      ),
    );
  }

  /// The selection handles for the resolved style, reused while it holds.
  DsTextSelectionControls _controlsFor(DsTextFieldStyle s) {
    final next = DsTextSelectionControls(
      color: s.handleColor ?? s.caretColor!,
      size: s.handleSize!,
      stemWidth: s.caretWidth!,
    );
    return _controls == next ? _controls! : (_controls = next);
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final scope = DsFieldScope.maybeOf(context);
    final enabled = widget.enabled;
    final variant = widget._variant;
    final text = _controller.text;
    final empty = text.isEmpty;
    final count = text.characters.length;
    final maxLength = widget.maxLength;
    final soft = widget.maxLengthEnforcement == MaxLengthEnforcement.none;
    // Past a soft limit the field is in error, as the counter says.
    final over = maxLength != null && count > maxLength;
    final error = widget.error || (scope?.hasError ?? false) || over;
    final focused = enabled && (_focusNode.hasFocus || _menu.isOpen);
    final readOnly = widget.readOnly && enabled;
    final states = {
      if (focused) WidgetState.focused,
      // A focused field keeps its focus edge under the pointer.
      if (enabled && _hovered && !focused) WidgetState.hovered,
      if (error) WidgetState.error,
      if (!enabled) WidgetState.disabled,
    };
    final themeData = DsTextFieldTheme.of(context);
    final s = DsTextFieldStyle.resolveLayers(
      [
        DsTextField.defaultStyle(t, variant: variant),
        themeData.style,
        themeData.variants[variant],
        widget.style,
      ],
      states,
      readOnly: readOnly,
    );
    // Corners by the resolved height, unless a layer sets them. The
    // shortcut hint's key cap sits inside the end padding, concentric.
    final corners = t.radii.controlCorners(s.borderRadius, s.height!);
    final dir = Directionality.of(context);
    final padding = (s.padding ?? EdgeInsets.zero).resolve(dir);
    final shortcutCorners = t.radii.nestedCorners(
      s.shortcutBorderRadius,
      corners,
      dir == TextDirection.rtl ? padding.left : padding.right,
    );

    // The composing range is underlined over this style, so its decoration
    // color and thickness style the IME underline; the rest of the text
    // has no decoration and ignores them.
    final composing = s.composingStyle;
    final textStyle = DefaultTextStyle.of(context).style
        .merge(s.textStyle)
        .copyWith(
          color: s.foreground,
          decorationColor: composing?.decorationColor,
          decorationThickness: composing?.decorationThickness,
          decorationStyle: composing?.decorationStyle,
        );
    final overlay = _overlayAvailable;
    final reduced = t.motion.reduced;
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final caretColor = s.caretColor!;
    final caretWidth = s.caretWidth!;
    final caretRadius = Radius.circular(caretWidth / 2);
    final showCaret = !widget.readOnly && enabled;
    // Under reduced motion the caret does not blink: Flutter's blinking
    // caret is off and a still one is painted in its place.
    if (reduced) {
      (_staticCaret ??= _StaticCaret()).update(
        color: caretColor,
        radius: caretRadius,
        active: showCaret,
      );
    } else if (_staticCaret != null) {
      _staticCaret!.dispose();
      _staticCaret = null;
    }
    if (_paintedCaret != _staticCaret) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCaret());
    }

    final formatters = [
      ...?widget.inputFormatters,
      if (maxLength != null && !soft)
        LengthLimitingTextInputFormatter(
          maxLength,
          maxLengthEnforcement: widget.maxLengthEnforcement,
        ),
    ];
    final obscured = widget.obscureText && !_revealed;
    final literal = _literal;

    Widget editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly || !enabled,
      obscureText: obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: enabled ? widget.autofillHints : null,
      autocorrect: widget.autocorrect ?? (literal ? false : null),
      enableSuggestions: widget.enableSuggestions ?? !literal,
      smartDashesType: literal ? SmartDashesType.disabled : null,
      smartQuotesType: literal ? SmartQuotesType.disabled : null,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      inputFormatters: formatters,
      style: textStyle,
      cursorColor: caretColor,
      backgroundCursorColor: s.placeholderColor ?? caretColor,
      cursorWidth: caretWidth,
      cursorRadius: caretRadius,
      cursorOpacityAnimates: apple,
      showCursor: showCaret && !reduced,
      // Painted only while the field has focus, as browsers do; kept
      // while the desktop menu holds focus.
      selectionColor: focused ? s.selectionColor : null,
      selectionControls: overlay && enabled ? _controlsFor(s) : null,
      contextMenuBuilder: overlay && enabled ? _buildContextMenu : null,
      showSelectionHandles: _showHandles,
      enableInteractiveSelection: enabled,
      selectAllOnFocus: _keepSelectionOnFocus ? false : null,
      // The loupe on iOS and Android while a handle is dragged or a long
      // press selects; none on desktop.
      magnifierConfiguration: overlay && enabled
          ? DsTextMagnifier.configuration
          : TextMagnifierConfiguration.disabled,
      mouseCursor: s.cursor,
      rendererIgnoresPointer: true,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: _onEditingComplete,
      onSelectionChanged: _onSelectionChanged,
      onSelectionHandleTapped: _onHandleTapped,
    );
    // A single line too long for the field fades out at the edge that
    // hides text while the field is not being edited, instead of slicing
    // a glyph in two; editing shows the plain edge the caret moves along.
    if (!_multiline) {
      editable = EdgeFade(
        width: DsSpace.s12,
        enabled: !focused,
        child: editable,
      );
    }

    // Text in the slots is an affix of the value; trailing text follows
    // the value on a single line.
    final leadingAffix = _isText(widget.leading);
    final trailingAffix = _isText(widget.trailing);
    final hug = trailingAffix && !_multiline;
    if (widget.placeholder case final placeholder? when empty) {
      final shown = IgnorePointer(
        child: ExcludeSemantics(
          child: Text(
            placeholder,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
            style: textStyle.copyWith(color: s.placeholderColor),
          ),
        ),
      );
      editable = Stack(
        // Hugging, the placeholder counts in the width, so a trailing
        // affix follows it; it keeps the caret's room at its right edge
        // as the editor does (see FieldFitRow.mainRightInset).
        fit: hug ? StackFit.passthrough : StackFit.loose,
        children: [
          if (hug)
            Padding(
              // ds-raw: the editor's caret room (width and its 1px gap)
              padding: EdgeInsets.only(right: caretWidth + 1),
              child: shown,
            )
          else
            Positioned.fill(child: shown),
          editable,
        ],
      );
    }

    // Shift+F10 and the context menu key open the desktop menu; Escape
    // clears a search field.
    editable = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: editable,
    );
    // Text editing keys come from WidgetsApp; outside one, the field
    // brings them itself, without overriding an app's own.
    if (context.findAncestorWidgetOfExactType<DefaultTextEditingShortcuts>() ==
        null) {
      editable = DefaultTextEditingShortcuts(child: editable);
    }

    final scaler = MediaQuery.textScalerOf(context);
    final iconSize = scaler.scale(s.iconSize!);
    final crossAxis = _multiline
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    // Slots: icons in the style's icon color and size, text in the
    // placeholder color (a unit reads as secondary).
    Widget slot(Widget child) => IconTheme.merge(
      data: IconThemeData(color: s.iconColor, size: iconSize),
      child: DefaultTextStyle.merge(
        style: textStyle.copyWith(color: s.placeholderColor),
        child: child,
      ),
    );
    // A key hint means nothing on a phone or tablet: no keyboard to press.
    final shortcut = isTouchPlatform(t.platform) ? null : widget._shortcut;

    final canEdit = !widget.readOnly && enabled;
    final clearable = widget.clearable && canEdit;
    final revealable = widget.revealable && widget.obscureText && enabled;
    // A picker's popup button edits the value, so a read-only field drops
    // it, as it drops the clear button.
    final endAction = readOnly ? null : FieldEndAction.maybeOf(context);
    final separate =
        scope?.hooks != null &&
        (widget.clearable ||
            widget.revealable ||
            widget.trailing != null ||
            endAction != null);
    // The field's own node: name, hint (placeholder, counter, and the
    // field's message when the field does not merge it: buttons apart, or
    // a scope without a field), value and states, merged with the
    // editable's. The buttons stay outside it.
    final hint = [
      if (empty) ?widget.placeholder,
      if (maxLength != null) l10n.characterCountLabel(count, maxLength),
      if (separate || scope?.hooks == null) ?scope?.messageText,
    ];
    // A clear button that gave way leaves its action on the field.
    final clearHidden = clearable && !empty && _yielded >= FieldYield.clear;
    final semanticLabel = [
      if (separate) ?scope?.labelText,
      ?widget.semanticLabel,
    ];
    Widget node = Semantics(
      label: semanticLabel.isEmpty ? null : semanticLabel.join('\n'),
      hint: hint.isEmpty ? null : hint.join('\n'),
      enabled: enabled,
      isRequired: (scope?.isRequired ?? false) ? true : null,
      validationResult: error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      maxValueLength: maxLength,
      currentValueLength: maxLength == null ? null : count,
      onTap: canEdit ? _requestKeyboard : null,
      customSemanticsActions: clearHidden
          ? {CustomSemanticsAction(label: l10n.clear): _clear}
          : null,
      // Too narrow for every part, the extras give way in order and the
      // text keeps its room.
      child: FieldFitRow(
        crossAxisAlignment: crossAxis,
        spacing: s.gap!,
        affixSpacing: s.affixGap ?? s.gap!,
        // The text editor keeps the caret's room (its width and a 1px gap)
        // at its right edge; trailing text sits as close as leading text.
        mainRightInset: caretWidth + 1,
        parts: [
          if (widget.leading != null)
            FieldExtra(
              FieldYield.leading,
              lastResort: true,
              affix: leadingAffix,
            ),
          FieldMain(minWidth: fieldMinTextWidth(textStyle, scaler), hug: hug),
          if (widget.trailing != null)
            FieldExtra(FieldYield.trailing, affix: trailingAffix),
          if (shortcut != null && empty) const FieldExtra(FieldYield.trailing),
        ],
        children: [
          if (widget.leading case final leading?) slot(leading),
          editable,
          if (widget.trailing case final trailing?) slot(trailing),
          if (shortcut != null && empty)
            _ShortcutHint(
              keys: shortcut,
              style: s,
              borderRadius: shortcutCorners,
            ),
        ],
      ),
    );
    node = MergeSemantics(child: node);

    final border = s.borderColor ?? const Color(0x00000000);
    Widget box = FieldWell(
      key: _box,
      duration: t.motion.toneDuration,
      curve: t.motion.toneCurve,
      minHeight: s.height!,
      padding: s.padding,
      background: s.background,
      borderColor: s.borderColor,
      borderWidth: s.borderWidth!,
      borderRadius: corners,
      shadows: s.shadows,
      focusShadows: s.focusShadows,
      focused: focused,
      child: FieldFitRow(
        crossAxisAlignment: crossAxis,
        spacing: s.gap!,
        onLevel: _onYield,
        parts: [
          const FieldMain(),
          if (clearable && !empty) const FieldExtra(FieldYield.clear),
          if (revealable) const FieldExtra(FieldYield.reveal),
          if (endAction != null) const FieldExtra(FieldYield.action),
          if (error) const FieldExtra(FieldYield.error),
        ],
        children: [
          node,
          if (clearable && !empty)
            _ActionTapArea(
              visual: s.clearStyle!.height!,
              child: DsButton.icon(
                size: DsSize.xs,
                focusNode: _clearFocus,
                style: s.clearStyle,
                semanticLabel: l10n.clear,
                onPressed: _clear,
                icon: const DsIcon(DsIcons.x),
              ),
            ),
          if (revealable)
            _ActionTapArea(
              visual: s.revealStyle!.height!,
              child: ExcludeFocus(
                excluding: _yielded >= FieldYield.reveal,
                child: DsButton.icon(
                  size: DsSize.xs,
                  style: s.revealStyle,
                  semanticLabel: _revealed
                      ? l10n.hidePassword
                      : l10n.showPassword,
                  onPressed: _toggleReveal,
                  icon: DsIcon(_revealed ? DsIcons.eyeOff : DsIcons.eye),
                ),
              ),
            ),
          if (endAction != null)
            _ActionTapArea(
              visual: endAction.visual,
              child: ExcludeFocus(
                excluding: _yielded >= FieldYield.action,
                child: endAction.button,
              ),
            ),
          if (error)
            ExcludeSemantics(
              child: DsIcon(
                DsIcons.circleAlert,
                size: iconSize,
                // The edge's color; the cue is not color alone.
                color:
                    s.errorIconColor ?? (border.a > 0 ? border : s.iconColor),
              ),
            ),
        ],
      ),
    );

    box = _gestures.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: box,
    );
    if (overlay) {
      box = DsAnchoredOverlay(
        controller: _menu,
        anchorPoint: _menuAt,
        gap: DsSpace.s3,
        tab: DsOverlayTab.close,
        overlayBuilder: (context) => ListenableBuilder(
          listenable: _editable?.clipboardStatus ?? _menu,
          builder: (context, _) => DsTextContextMenu(
            buttonItems: _editable?.contextMenuButtonItems ?? const [],
            onDone: _menu.close,
          ),
        ),
        child: box,
      );
    }

    box = TextFieldTapRegion(
      child: IgnorePointer(ignoring: !enabled, child: box),
    );
    box = MouseRegion(
      cursor: s.cursor ?? MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ExcludeFocus(excluding: !enabled, child: box),
    );

    // The counter: at the end of a field's message row, or under the
    // field when it stands alone.
    Widget? counter;
    if (maxLength != null) {
      counter = _Counter(
        controller: _controller,
        maxLength: maxLength,
        style: s.counterStyle,
        overStyle: s.counterOverStyle,
      );
    }
    final hooks = scope?.hooks;
    _report(
      hooks,
      counter: counter,
      key: counter == null
          ? null
          : (_controller, maxLength, s.counterStyle, s.counterOverStyle),
      separate: separate,
    );
    if (counter != null && hooks == null) {
      box = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: s.counterGap!,
        children: [
          box,
          Align(alignment: AlignmentDirectional.centerEnd, child: counter),
        ],
      );
    }

    // In an unbounded width (a Row) the field takes its default width.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedWidth
          ? box
          : SizedBox(width: s.width, child: box),
    );
  }

  /// Hands the still caret to the editable's renderer (or takes it back).
  void _syncCaret() {
    final editable = _editable;
    if (!mounted || editable == null) return;
    editable.renderEditable.foregroundPainter = _staticCaret;
    _paintedCaret = _staticCaret;
  }

  void _requestKeyboard() {
    if (!_controller.selection.isValid) {
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    _editable?.requestKeyboard();
  }
}

/// Right click on desktop opens Desen's menu instead of Flutter's
/// toolbar; everything else is Flutter's platform behavior.
class _GestureBuilder extends TextSelectionGestureDetectorBuilder {
  _GestureBuilder(this._field) : super(delegate: _field);

  final _DsTextFieldState _field;
  Offset? _secondaryDown;

  @override
  void onSecondaryTapDown(TapDownDetails details) {
    super.onSecondaryTapDown(details);
    _secondaryDown = details.globalPosition;
  }

  @override
  void onSecondaryTap() {
    final at = _secondaryDown;
    if (!_field._usesDesktopMenu || at == null) {
      super.onSecondaryTap();
      return;
    }
    if (delegate.selectionEnabled) {
      final editable = renderEditable;
      switch (defaultTargetPlatform) {
        case TargetPlatform.macOS || TargetPlatform.iOS:
          // macOS selects the word under the pointer unless the click is
          // inside the selection.
          final selection = editable.selection;
          final position = editable.getPositionForPoint(at).offset;
          final onSelection =
              selection != null &&
              selection.start <= position &&
              selection.end >= position;
          if (!onSelection || !editable.hasFocus) {
            editable.selectWord(cause: SelectionChangedCause.tap);
          }
        default:
          if (!editable.hasFocus) {
            editable.selectPosition(cause: SelectionChangedCause.tap);
          }
      }
    }
    _field._openMenu(at);
  }
}

/// A caret that does not blink, painted above the text while the field
/// has focus and a collapsed selection.
class _StaticCaret extends RenderEditablePainter {
  Color _color = const Color(0x00000000);
  Radius _radius = Radius.zero;
  bool _active = false;

  void update({
    required Color color,
    required Radius radius,
    required bool active,
  }) {
    if (color == _color && radius == _radius && active == _active) return;
    _color = color;
    _radius = radius;
    _active = active;
    notifyListeners();
  }

  /// Repaints, e.g. when focus changes.
  void refresh() => notifyListeners();

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    final selection = renderEditable.selection;
    if (!_active ||
        !renderEditable.hasFocus ||
        selection == null ||
        !selection.isValid ||
        !selection.isCollapsed) {
      return;
    }
    final rect = renderEditable.getLocalRectForCaret(selection.extent);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, _radius),
      Paint()..color = _color,
    );
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) => true;
}

/// The character counter ("12 / 100"), following the text. Screen readers
/// hear the count with the field, so it is not read again here.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.controller,
    required this.maxLength,
    required this.style,
    required this.overStyle,
  });

  final TextEditingController controller;
  final int maxLength;
  final TextStyle? style;
  final TextStyle? overStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = DsLocalizations.of(context);
    return ExcludeSemantics(
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final count = value.text.characters.length;
          final over = count > maxLength;
          return Text.rich(
            numericSpan(
              l10n.characterCount(count, maxLength),
              style: over ? style?.merge(overStyle) ?? overStyle : style,
            ),
            maxLines: 1,
          );
        },
      ),
    );
  }
}

/// A search field's shortcut hint (⌘K) on a soft chip.
/// Whether a slot holds text (a unit, a prefix) rather than an icon:
/// a [Text] or [RichText], also under [ExcludeSemantics] or [Semantics]
/// (a number field's unit, which its value already reads).
bool _isText(Widget? slot) => switch (slot) {
  Text() || RichText() => true,
  ExcludeSemantics(:final child?) => _isText(child),
  Semantics(:final child?) => _isText(child),
  _ => false,
};

class _ShortcutHint extends StatelessWidget {
  const _ShortcutHint({
    required this.keys,
    required this.style,
    required this.borderRadius,
  });

  final String keys;
  final DsTextFieldStyle style;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: DsBoxDecoration(
      color: style.shortcutBackground,
      borderRadius: borderRadius,
    ),
    child: Padding(
      padding: style.shortcutPadding ?? EdgeInsets.zero,
      child: DsShortcut(keys, textStyle: style.shortcutStyle),
    ),
  );
}

/// An inline button (clear, show password) that keeps its full tap target
/// without making the field taller: it takes [visual] space in the row
/// and lets its larger hit area ([DsMinTapTarget] inside the button)
/// overflow it, centered.
class _ActionTapArea extends SingleChildRenderObjectWidget {
  const _ActionTapArea({required this.visual, super.child});

  /// The button's drawn width and height.
  final double visual;

  @override
  _RenderActionTapArea createRenderObject(BuildContext context) =>
      _RenderActionTapArea(visual);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderActionTapArea renderObject,
  ) => renderObject.visual = visual;
}

class _RenderActionTapArea extends RenderShiftedBox {
  _RenderActionTapArea(this._visual) : super(null);

  double _visual;
  set visual(double value) {
    if (value == _visual) return;
    _visual = value;
    markNeedsLayout();
  }

  Size get _own => Size.square(_visual);

  @override
  double computeMinIntrinsicWidth(double height) => _visual;

  @override
  double computeMaxIntrinsicWidth(double height) => _visual;

  @override
  double computeMinIntrinsicHeight(double width) => _visual;

  @override
  double computeMaxIntrinsicHeight(double width) => _visual;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_own);

  @override
  void performLayout() {
    size = constraints.constrain(_own);
    final child = this.child;
    if (child == null) return;
    child.layout(const BoxConstraints(), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    // The larger target around the drawn button, not just its own box.
    if (!(offset & child.size).contains(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
