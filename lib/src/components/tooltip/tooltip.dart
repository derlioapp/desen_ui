import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../overlay/anchored_overlay.dart';
import '../../overlay/placement.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/motion.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../menu/shortcut.dart';
import 'tooltip_style.dart';

/// A small dark label for a control, with an optional shortcut (concept
/// card 20). Meets WCAG 1.4.13:
///
/// - **shows** after the pointer rests on the trigger ([DsMotion.hoverDelay];
///   at once when another tooltip just closed), on keyboard focus, or on a
///   long press on touch screens;
/// - **stays** while the pointer moves onto the tooltip itself;
/// - **hides** on Escape, on a press on the trigger, or when pointer and
///   focus leave. That Escape stops at the tooltip: a dialog behind it
///   stays open. With no tooltip showing, Escape goes on as usual.
///
/// Screen readers get [message] as the trigger's own tooltip: the tooltip
/// and the trigger are merged into one node, so [child] should be a single
/// control (a button, not a toolbar). The floating label itself is not
/// read twice. When [message] repeats the control's own label (an icon
/// rail that shows its labels as tooltips), set [excludeFromSemantics] so
/// it is not announced twice.
///
/// The label floats in the nearest [Overlay]. With none above it
/// (no app root), the tooltip does nothing visible: the control shows
/// alone, and screen readers still get [message].
///
/// ```dart
/// DsTooltip(
///   message: 'Bağlantıyı kopyala',
///   shortcut: '⌘C',
///   child: DsButton.icon(icon: const DsIcon(DsIcons.link),
///       semanticLabel: 'Kopyala', onPressed: copy),
/// )
/// ```
class DsTooltip extends StatefulWidget {
  /// Creates a tooltip.
  const DsTooltip({
    super.key,
    required this.message,
    required this.child,
    this.shortcut,
    this.side = DsSide.top,
    this.excludeFromSemantics = false,
    this.style,
  });

  /// The label.
  final String message;

  /// A keyboard shortcut shown muted after the message ("⌘C"); key symbols
  /// are drawn as icons ([DsShortcut]).
  final String? shortcut;

  /// The control it describes.
  final Widget child;

  /// Preferred side; flips when it does not fit.
  final DsSide side;

  /// Leaves [message] out of the semantics tree, for a message that
  /// repeats the label [child] already announces.
  final bool excludeFromSemantics;

  /// Style laid over the theme and defaults.
  final DsTooltipStyle? style;

  /// Desen's default tooltip style under [theme].
  static DsTooltipStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsTooltipStyle(
      height: theme.sizes.sm,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s6,
      ),
      background: k.tooltip,
      shadows: theme.shadows.tooltip,
      // No radius: the corners follow the resolved height.
      textStyle: theme.typography.label.copyWith(color: k.onTooltip),
      // The scale's smallest size, the overline's (11, touch 12).
      shortcutStyle: theme.typography.caption.copyWith(
        fontSize: theme.typography.overline.fontSize,
        color: k.onTooltipMuted,
      ),
      gap: DsSpace.s8,
      maxWidth: 280,
    );
  }

  @override
  State<DsTooltip> createState() => _DsTooltipState();
}

class _DsTooltipState extends State<DsTooltip> {
  /// When the last tooltip anywhere closed: the next one inside the grace
  /// window shows without delay, as on macOS.
  static DateTime? _lastClosed;

  final _controller = DsOverlayController();
  Timer? _showTimer, _hideTimer;
  bool _keyboardListening = false;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _stopEscape();
    _controller.dispose();
    super.dispose();
  }

  DsMotion get _motion => DsTheme.motionOf(context);

  void _scheduleShow({Duration? delay}) {
    _hideTimer?.cancel();
    if (_controller.isOpen) return;
    final warm =
        _lastClosed != null &&
        DateTime.now().difference(_lastClosed!) < _motion.hoverGrace * 4;
    _showTimer?.cancel();
    _showTimer = Timer(
      warm ? Duration.zero : delay ?? _motion.hoverDelay,
      _show,
    );
  }

  void _show() {
    if (!mounted) return;
    _controller.open();
    _listenEscape();
  }

  void _scheduleHide({Duration? after}) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hideTimer = Timer(after ?? _motion.hoverGrace, _hide);
  }

  void _hide() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (_controller.isOpen) {
      _lastClosed = DateTime.now();
      _controller.close();
    }
    _stopEscape();
  }

  // Escape dismisses the tooltip even when focus is elsewhere (hover).
  // It runs before the focused widgets and stops there: the Escape that
  // hides a tooltip does not also close the dialog behind it (eng L2).
  void _listenEscape() {
    if (_keyboardListening) return;
    _keyboardListening = true;
    FocusManager.instance.addEarlyKeyEventHandler(_onKey);
  }

  void _stopEscape() {
    if (!_keyboardListening) return;
    _keyboardListening = false;
    FocusManager.instance.removeEarlyKeyEventHandler(_onKey);
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _controller.isOpen) {
      _hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPointerDown(PointerDownEvent event) {
    // A press on the trigger hides the tooltip; a long touch shows it.
    _hide();
    if (event.kind == PointerDeviceKind.touch) {
      _showTimer = Timer(kLongPressTimeout, _show);
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _showTimer?.cancel();
    if (_controller.isOpen) _scheduleHide(after: kLongPressTimeout * 3);
  }

  @override
  Widget build(BuildContext context) {
    // The trigger's own node carries the tooltip (ux V14): a plain
    // Semantics around a control that is its own node would hand it to
    // an ancestor instead.
    Widget trigger(Widget child) => widget.excludeFromSemantics
        ? child
        : MergeSemantics(
            child: Semantics(tooltip: widget.message, child: child),
          );
    // No Overlay to float in (no app root): the control alone, still
    // described for screen readers (K-52).
    if (Overlay.maybeOf(context) == null) return trigger(widget.child);
    return DsAnchoredOverlay(
      controller: _controller,
      side: widget.side,
      align: DsAlign.center,
      focusOnOpen: false,
      onDismissed: _hide,
      overlayBuilder: (context) {
        final t = dsThemeOf(context);
        final s = DsTooltipStyle.resolveLayers([
          DsTooltip.defaultStyle(t),
          DsTooltipTheme.of(context).style,
          widget.style,
        ], const {});
        return ExcludeSemantics(
          // Hoverable: moving onto the tooltip keeps it open.
          child: MouseRegion(
            onEnter: (_) => _hideTimer?.cancel(),
            onExit: (_) => _scheduleHide(),
            child: DsSurface(
              constraints: BoxConstraints(
                minHeight: s.height!,
                maxWidth: s.maxWidth ?? double.infinity,
              ),
              padding: s.padding,
              decoration: DsBoxDecoration(
                color: s.background,
                borderRadius: t.radii.controlCorners(s.borderRadius, s.height!),
                shadows: s.shadows ?? const [],
              ),
              backdropFilter: s.backdropFilter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: s.gap ?? DsSpace.s8,
                children: [
                  Flexible(child: Text(widget.message, style: s.textStyle)),
                  if (widget.shortcut case final keys?)
                    DsShortcut(keys, textStyle: s.shortcutStyle),
                ],
              ),
            ),
          ),
        );
      },
      child: trigger(
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          // Keyboard focus on the trigger shows the tooltip.
          // Not while the focus manager notifies: showing and hiding
          // change the layer's focus scope.
          onFocusChange: (focused) => scheduleMicrotask(() {
            if (!mounted) return;
            focused && DsFocusVisibility.keyboard.value ? _show() : _hide();
          }),
          child: MouseRegion(
            onEnter: (_) => _scheduleShow(),
            onExit: (_) => _scheduleHide(),
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
