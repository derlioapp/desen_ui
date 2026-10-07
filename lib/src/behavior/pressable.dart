import 'dart:ui' show SemanticsRole, SemanticsValidationResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../l10n/localizations.dart';
import '../theme/haptics.dart';
import '../theme/theme.dart';
import 'focus_visibility.dart';
import 'focus_visibility_state.dart' show notePressed;
import 'haptic_feedback.dart';
import 'menu_action.dart';
import 'min_tap_target.dart';

/// Builds a pressable's visuals from its current interaction states.
typedef DsStatesWidgetBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
);

/// Headless behavior for anything that can be pressed: buttons, chips, menu
/// rows, list items.
///
/// Handles pointer, touch and keyboard input, focus, cursor and semantics,
/// and reports interaction states to [builder]. It draws nothing itself, so
/// it can back any visual design.
///
/// States reported:
/// - [WidgetState.hovered]: a mouse is over it. Never set by touch, so hover
///   styles do not stick on phones.
/// - [WidgetState.focused]: it has focus **and** the user is navigating with
///   a keyboard, the equivalent of CSS `:focus-visible` (see
///   [DsFocusVisibility]). A click or tap never shows focus, and pressing
///   does not take focus, as in Safari and macOS. A modal it opens still
///   gives focus back to it on close (`DsModalRoute`).
/// - [WidgetState.pressed]: a pointer is down on it.
/// - [WidgetState.disabled]: both [onPressed] and [onLongPress] are null.
///
/// While [busy] (e.g. a button that is saving), it stays focusable and
/// enabled for assistive technology, announces the localized "loading" as
/// its value, and ignores presses: the `aria-disabled` + `aria-busy`
/// pattern, so keyboard focus is not lost mid-task.
///
/// Inside a `DsContextMenuRegion`, the outermost pressable's node opens
/// the region's menu for screen readers: with a long press (unless
/// [onLongPress] takes it) and with a localized "Show menu" action.
///
/// Keyboard activation follows native and web buttons, even without an app
/// root that installs default shortcuts:
/// - Enter and numpad Enter fire on key down.
/// - Space shows the pressed state while held and fires on release, so
///   moving focus away mid-press cancels it.
/// - Holding a key never fires again: repeats are swallowed.
///
/// The hit area is at least [minTapTarget] on each axis; the visuals stay
/// the size the builder draws them (WCAG 2.5.8).
///
/// A tap plays its [haptic] event through the theme's
/// `DsThemeData.haptics` setting, so a control built on it answers a touch
/// as the platform does without asking for it. Keyboard and assistive
/// activation stay silent, as on iOS.
///
/// A control that shrinks while pressed should scale by
/// `DsPressEffect.scaleOf`, so a `DsPressEffect` scope can turn that motion
/// off, and draw its keyboard focus with `DsFocusRing` around its box.
class DsPressable extends StatefulWidget {
  /// Creates a pressable.
  const DsPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.child,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.mouseCursor,
    this.semanticLabel,
    this.isButton = true,
    this.isLink = false,
    this.linkUrl,
    this.selected,
    this.checked,
    this.mixed,
    this.toggled,
    this.expanded,
    this.role,
    this.minTapTarget,
    this.busy = false,
    this.validationResult = SemanticsValidationResult.none,
    this.haptic = DsHapticEvent.command,
  });

  /// Called on tap or keyboard activation. Null (with a null
  /// [onLongPress]) disables the pressable.
  final VoidCallback? onPressed;

  /// Called on long press. A pressable with only [onLongPress] is enabled,
  /// as in Flutter's buttons; tap and keyboard activation then do nothing.
  final VoidCallback? onLongPress;

  /// Builds the visuals for the current states.
  final DsStatesWidgetBuilder builder;

  /// A subtree that does not depend on states, passed through to [builder].
  final Widget? child;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// Lets the owner observe states or add its own (e.g. selected, error).
  /// One is created when null.
  final WidgetStatesController? statesController;

  /// Cursor, which may depend on states (see [WidgetStateMouseCursor]).
  /// Defaults to a pointing hand when enabled and "forbidden" when disabled.
  final MouseCursor? mouseCursor;

  /// Overrides the label screen readers announce. By default the label is
  /// merged from the text inside.
  final String? semanticLabel;

  /// Announce as a button.
  final bool isButton;

  /// Announce as a link. Set [isButton] to false with it.
  final bool isLink;

  /// The link target. On the web this produces a real `<a href>`, so the
  /// browser can open it in a new tab and show the address.
  final Uri? linkUrl;

  /// Announces a selected state, e.g. a filter chip.
  final bool? selected;

  /// Announces a checked state, for checkboxes.
  final bool? checked;

  /// Announces a mixed (indeterminate) state, for tristate checkboxes.
  final bool? mixed;

  /// Announces an on/off state, for switches.
  final bool? toggled;

  /// Announces an expanded or collapsed state, for disclosure headers.
  final bool? expanded;

  /// A semantics role, e.g. [SemanticsRole.menuItem]. Set [isButton] to
  /// false with it.
  final SemanticsRole? role;

  /// The smallest hit area on each axis. Defaults to the theme's
  /// [DsSizes.minTapTarget]: 24 for compact density on desktop, 44 on iOS
  /// and Android and for touch density. Pass 0
  /// to opt out, e.g. for a row that is already tall enough by design.
  final double? minTapTarget;

  /// Working on something: keeps focus and the enabled semantics, ignores
  /// presses, reports no hover or pressed state, and announces the
  /// localized "loading" (see the class docs).
  final bool busy;

  /// Announces a validation result, e.g. a required checkbox left
  /// unchecked ([SemanticsValidationResult.invalid]).
  final SemanticsValidationResult validationResult;

  /// What an activation means for haptic feedback: a command
  /// ([DsHapticEvent.command], the default), which only plays under
  /// `DsHaptics.full`, or a state change ([DsHapticEvent.selection]: a
  /// toggle, a chosen option), which also plays under the platform default
  /// `DsHaptics.subtle`. Null keeps this pressable silent.
  ///
  /// It plays on a tap (touch, mouse or stylus), before [onPressed] runs.
  /// Haptics answer a touch: activation from the keyboard or a screen
  /// reader action plays nothing, and neither does a long press.
  final DsHapticEvent? haptic;

  /// The default cursor policy: pointing hand when enabled, forbidden when
  /// disabled.
  static const WidgetStateMouseCursor defaultCursor = _DefaultCursor();

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DefaultCursor extends WidgetStateMouseCursor {
  const _DefaultCursor();

  @override
  MouseCursor resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? SystemMouseCursors.forbidden
      : SystemMouseCursors.click;

  @override
  String get debugDescription => 'DsPressable.defaultCursor';
}

class _DsPressableState extends State<DsPressable> {
  WidgetStatesController? _internalController;
  WidgetStatesController get _states =>
      widget.statesController ??
      (_internalController ??= WidgetStatesController());

  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  /// Space went down while this had focus; its release activates.
  bool _spaceHeld = false;

  /// Flutter's focus highlight (focused, traditional mode), before the
  /// keyboard check.
  bool _highlight = false;

  void _updateFocused() => _sync(
    WidgetState.focused,
    _enabled && _highlight && DsFocusVisibility.keyboard.value,
  );

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => _activate(),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => _activate(),
    ),
  };

  bool get _enabled => widget.onPressed != null || widget.onLongPress != null;

  /// Enabled and not [DsPressable.busy]: presses do something.
  bool get _active => _enabled && !widget.busy;

  @override
  void initState() {
    super.initState();
    // Seed initial states before listening, so no setState runs in initState.
    _sync(WidgetState.disabled, !_enabled);
    if (widget.selected != null) _sync(WidgetState.selected, widget.selected!);
    _states.addListener(_onStatesChanged);
    _focusNode.addListener(_onFocusChanged);
    DsFocusVisibility.keyboard.addListener(_updateFocused);
  }

  @override
  void didUpdateWidget(DsPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      (oldWidget.statesController ?? _internalController)?.removeListener(
        _onStatesChanged,
      );
      if (widget.statesController != null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _states.addListener(_onStatesChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _onFocusChanged,
      );
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_onFocusChanged);
    }
    if (!_active) {
      _spaceHeld = false;
      // A pressable disabled (or busy) mid-interaction must not keep stale
      // states. A busy one keeps focus.
      _sync(WidgetState.pressed, false);
      _sync(WidgetState.hovered, false);
      if (!_enabled) _sync(WidgetState.focused, false);
    }
    _sync(WidgetState.disabled, !_enabled);
    if (widget.selected != null) {
      _sync(WidgetState.selected, widget.selected!);
    } else if (oldWidget.selected != null) {
      // Going back to "not announced" must not leave the state set.
      _sync(WidgetState.selected, false);
    }
  }

  @override
  void dispose() {
    _states.removeListener(_onStatesChanged);
    _internalController?.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    DsFocusVisibility.keyboard.removeListener(_updateFocused);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _spaceHeld) {
      // Focus left mid-press: release without activating.
      _spaceHeld = false;
      _sync(WidgetState.pressed, false);
    }
  }

  /// Button-style keys (see the class docs). Listens above the focus node,
  /// so it only acts when this pressable itself has primary focus, not a
  /// focusable inside it.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_enabled || !_focusNode.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    // A busy pressable swallows its activation keys, so Enter does not
    // reach an enclosing form while it works.
    final key = event.logicalKey;
    final isSpace = key == LogicalKeyboardKey.space;
    if (!isSpace &&
        key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (widget.busy) return KeyEventResult.handled;
    switch (event) {
      case KeyRepeatEvent():
        return KeyEventResult.handled;
      case KeyDownEvent() when isSpace:
        _spaceHeld = true;
        _sync(WidgetState.pressed, true);
        return KeyEventResult.handled;
      case KeyDownEvent():
        _activate();
        return KeyEventResult.handled;
      case KeyUpEvent() when isSpace && _spaceHeld:
        _spaceHeld = false;
        _sync(WidgetState.pressed, false);
        _activate();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _onStatesChanged() {
    if (mounted) setState(() {});
  }

  void _sync(WidgetState state, bool on) {
    if (_states.value.contains(state) != on) _states.update(state, on);
  }

  /// Runs [DsPressable.onPressed]; a [pointer] tap also plays the haptic.
  void _activate({bool pointer = false}) {
    if (!_active) return;
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    // Played before the callback: it may rebuild, dispose or navigate, and
    // the feedback belongs to the touch that caused it.
    final haptic = widget.haptic;
    if (pointer && haptic != null) DsHapticFeedback.play(context, haptic);
    // A click does not focus, so a modal this opens learns its opener here.
    notePressed(_focusNode);
    onPressed();
  }

  void _tap() => _activate(pointer: true);

  void _longPress() {
    if (!_active) return;
    notePressed(_focusNode);
    widget.onLongPress?.call();
  }

  void _hover(bool on) => _sync(WidgetState.hovered, on && !widget.busy);

  @override
  Widget build(BuildContext context) {
    final states = _states.value;
    final cursor = WidgetStateProperty.resolveAs<MouseCursor>(
      widget.mouseCursor ?? DsPressable.defaultCursor,
      states,
    );
    // A context menu around it (DsContextMenuRegion) opens from this node:
    // with a long press, unless the pressable has its own, and by name.
    final showMenu = DsMenuActionScope.of(context);
    Widget content = widget.builder(context, states, widget.child);
    if (showMenu != null) {
      content = DsMenuActionScope(onShowMenu: null, child: content);
    }
    return Semantics(
      container: true,
      button: widget.isButton,
      link: widget.isLink,
      linkUrl: widget.linkUrl,
      enabled: _enabled,
      validationResult: widget.validationResult,
      value: widget.busy ? DsLocalizations.of(context).loading : null,
      selected: widget.selected,
      checked: widget.checked,
      mixed: widget.mixed,
      toggled: widget.toggled,
      expanded: widget.expanded,
      role: widget.role,
      label: widget.semanticLabel,
      onTap: _active && widget.onPressed != null ? _activate : null,
      onLongPress: _active && widget.onLongPress != null
          ? _longPress
          : showMenu,
      customSemanticsActions: showMenu == null
          ? null
          : {
              CustomSemanticsAction(
                label: DsLocalizations.of(context).showMenu,
              ): showMenu,
            },
      child: DsMinTapTarget(
        size: widget.minTapTarget ?? DsTheme.sizesOf(context).minTapTarget,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: FocusableActionDetector(
            enabled: _enabled,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            mouseCursor: cursor,
            actions: _actions,
            onShowHoverHighlight: _hover,
            onShowFocusHighlight: (v) {
              _highlight = v;
              _updateFocused();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown: _active
                  ? (_) => _sync(WidgetState.pressed, true)
                  : null,
              onTapUp: _active
                  ? (_) => _sync(WidgetState.pressed, false)
                  : null,
              onTapCancel: _active
                  ? () => _sync(WidgetState.pressed, false)
                  : null,
              onTap: _active ? _tap : null,
              onLongPress: _active && widget.onLongPress != null
                  ? _longPress
                  : null,
              // A semantic label replaces the text inside instead of adding
              // to it, so nothing is read twice.
              child: ExcludeSemantics(
                excluding: widget.semanticLabel != null,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('states', _states.value));
  }
}
