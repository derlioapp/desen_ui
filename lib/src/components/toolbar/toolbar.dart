import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/surface.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import 'toolbar_style.dart';
import 'toolbar_toggle_style.dart';

/// An opaque bar floating above the content. Holds
/// [DsToolbarToggle]s, icon buttons (`DsButton.icon` with the ghost
/// variant), [DsToolbarDivider]s and at most one primary button.
///
/// ```dart
/// DsToolbar(
///   children: [
///     DsToolbarToggle(icon: const DsIcon(DsIcons.bold), semanticLabel: 'Kalın',
///         selected: bold, onChanged: (v) => setState(() => bold = v)),
///     const DsToolbarDivider(),
///     DsButton(variant: .primary, size: .sm, onPressed: send, child: const Text('Gönder')),
///   ],
/// )
/// ```
///
/// **Keyboard:** every item is its own Tab stop, and Left and
/// Right (mirrored in RTL), Home and End also move focus between the items,
/// as in the WAI-ARIA toolbar pattern. Tab goes through all the items
/// before it moves on to what is beside the toolbar. The pattern's single Tab stop is not
/// used: Flutter has no toolbar semantics role, so screen-reader users
/// would not be told that the other items are reached with arrows.
class DsToolbar extends StatelessWidget {
  /// Creates a toolbar.
  const DsToolbar({
    super.key,
    required this.children,
    this.style,
    this.semanticLabel,
  });

  /// The items, start to end.
  final List<Widget> children;

  /// Style laid over the theme and defaults.
  final DsToolbarStyle? style;

  /// Names the toolbar for screen readers.
  final String? semanticLabel;

  /// Desen's default toolbar style under [theme].
  ///
  /// The corners are left unset: the bar is rounded as a control as tall
  /// as its toggles (their size from the toggle theme) and its padding, so
  /// a theme that resizes the toggles keeps the bar and its items
  /// concentric. A radius set in a style wins.
  static DsToolbarStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsToolbarStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      padding: const EdgeInsets.all(DsSpace.s5),
      gap: 2,
      dividerColor: k.border,
      dividerHeight: 18,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsToolbarStyle.resolveLayers([
      defaultStyle(t),
      DsToolbarTheme.of(context).style,
      style,
    ], const {});
    final toggleTheme = DsToolbarToggleTheme.of(context);
    // The items' size: the toggles' as the theme leaves it.
    final item = DsToolbarToggleStyle.resolveLayers([
      DsToolbarToggle.defaultStyle(t),
      toggleTheme.style,
    ], const {}).size!;
    final padding = s.padding ?? EdgeInsets.zero;
    final reach = math.max(0.0, (t.sizes.minTapTarget - item) / 2);
    // How far the items' visuals sit from the bar's edge: the padding, or
    // the reach of their tap areas when that is larger (see [_padding]).
    final inset = math.max(
      padding.resolve(Directionality.of(context)).top,
      reach,
    );
    // A bar of controls is rounded as a control as tall as its items and
    // their inset; the items nest in it.
    final corners = t.radii.controlCorners(s.borderRadius, item + 2 * inset);
    final nested = t.radii.nestedCorners(null, corners, inset);
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: DsSurface(
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: corners,
          shadows: s.shadows ?? const [],
        ),
        backdropFilter: s.backdropFilter,
        child: Padding(
          padding: _padding(padding, reach),
          child: DsToolbarTheme(
            data: DsToolbarThemeData(style: s),
            // Toggles nest in the bar: its concentric corner, under any
            // radius the toggle theme sets.
            child: DsToolbarToggleTheme(
              data: DsToolbarToggleThemeData(
                style: DsToolbarToggleStyle(borderRadius: nested)
                    .merge(toggleTheme.style),
              ),
              // Buttons in the bar are nested in it like its toggles, so
              // they take the same concentric corner, under any radius the
              // button theme sets.
              child: DsButtonTheme(
                data: DsButtonThemeData(
                  style: DsButtonStyle(borderRadius: nested)
                      .merge(DsButtonTheme.of(context).style),
                ),
                child: FocusStops(
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: _onKey,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: s.gap!,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [padding] less the [reach] of the items' tap areas past their visuals:
/// on a phone each 44px tap area reaches into the padding instead of
/// making the bar taller, so the bar keeps its desktop size and only the
/// items' spacing grows.
EdgeInsetsGeometry _padding(EdgeInsetsGeometry padding, double reach) {
  if (reach == 0) return padding;
  return padding
      .subtract(EdgeInsets.all(reach))
      .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity);
}

/// Arrow keys, Home and End move focus between the toolbar's items.
KeyEventResult _onKey(FocusNode toolbar, KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  final key = event.logicalKey;
  final keys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
  };
  final focused = FocusManager.instance.primaryFocus;
  if (!keys.contains(key) || focused == null) return KeyEventResult.ignored;
  final items = toolbar.traversalDescendants.toList();
  if (items.isEmpty) return KeyEventResult.ignored;
  final context = toolbar.context;
  final rtl =
      context != null && Directionality.of(context) == TextDirection.rtl;
  // Visual order, start to end.
  items.sort((a, b) => a.rect.center.dx.compareTo(b.rect.center.dx));
  if (rtl) items.setAll(0, items.reversed.toList());
  final i = items.indexWhere(
    (n) => n == focused || focused.ancestors.contains(n),
  );
  if (i < 0) return KeyEventResult.ignored;
  final forward = rtl
      ? LogicalKeyboardKey.arrowLeft
      : LogicalKeyboardKey.arrowRight;
  final next = switch (key) {
    LogicalKeyboardKey.home => 0,
    LogicalKeyboardKey.end => items.length - 1,
    _ when key == forward => (i + 1) % items.length,
    _ => (i - 1 + items.length) % items.length,
  };
  items[next].requestFocus();
  return KeyEventResult.handled;
}

/// A thin vertical line between groups in a [DsToolbar].
class DsToolbarDivider extends StatelessWidget {
  /// Creates a divider.
  const DsToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsToolbarStyle.resolveLayers([
      DsToolbar.defaultStyle(t),
      DsToolbarTheme.of(context).style,
    ], const {});
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s4),
      child: SizedBox(
        height: s.dividerHeight!,
        child: DsLine(
          color: s.dividerColor ?? const Color(0x00000000),
          axis: Axis.vertical,
        ),
      ),
    );
  }
}

/// An on/off icon button for a [DsToolbar] (bold, italic…). The pressed
/// state takes the theme's selection style and is announced as toggled.
class DsToolbarToggle extends StatefulWidget {
  /// Creates a toolbar toggle.
  const DsToolbarToggle({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.selected,
    required this.onChanged,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  });

  /// Usually a [DsIcon].
  final Widget icon;

  /// What the toggle does ("Kalın"); icon-only controls need a name.
  final String semanticLabel;

  /// Whether the toggle is on.
  final bool selected;

  /// Called with the new value. Null disables the toggle.
  final ValueChanged<bool>? onChanged;

  /// Style laid over the theme and defaults.
  final DsToolbarToggleStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Desen's default toolbar toggle style under [theme].
  ///
  /// The corners are left unset: in a [DsToolbar] the toggle nests in the
  /// bar, concentric with its corners; on its own it is rounded as a
  /// control of its size. A radius set in a style wins.
  static DsToolbarToggleStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsToolbarToggleStyle(
      size: theme.sizes.sm,
      background: const Color(0x00000000),
      shadows: const [],
      foreground: k.textMuted,
      iconSize: 16,
      focusShadows: theme.focusShadows,
      hovered: DsToolbarToggleStyle(background: k.hover, foreground: k.text),
      pressed: DsToolbarToggleStyle(background: k.press),
      selected: DsToolbarToggleStyle(
        background: theme.selectedFill,
        shadows: [
          if (theme.selectedEdge case final edge?) DsShadow.innerRing(edge),
        ],
        foreground: theme.onSelectedFill,
        // Hover stays visible on a selected item (K-61).
        hovered: DsToolbarToggleStyle(background: theme.selectedHoverFill),
      ),
      disabled: DsToolbarToggleStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsToolbarToggle> createState() => _DsToolbarToggleState();
}

class _DsToolbarToggleState extends State<DsToolbarToggle> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsToolbarToggle.defaultStyle(t),
      DsToolbarToggleTheme.of(context).style,
      widget.style,
    ];
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onChanged == null
          ? null
          : () => widget.onChanged!(!widget.selected),
      haptic: DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      toggled: widget.selected,
      semanticLabel: widget.semanticLabel,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsToolbarToggleStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
        };
        final s = DsToolbarToggleStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final size = s.size!;
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: t.radii.controlCorners(s.borderRadius, size),
            shadows: [
              ...?s.shadows,
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: s.foreground, size: s.iconSize),
            child: widget.icon,
          ),
        );
      },
    );
  }
}
