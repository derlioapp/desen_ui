import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/color_utils.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/modal_route.dart';
import '../../overlay/scroll_keys.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/motion.dart';
import '../../theme/sizes.dart';
import '../../theme/status.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import 'toast_style.dart';

/// Why a toast closed; [DsToastController.closed] completes with it.
enum DsToastClosedReason {
  /// Its action was pressed.
  action,

  /// The close button, Escape, a swipe or [DsToastController.dismiss]
  /// took it away, or its overlay left the tree.
  dismissed,

  /// Its time ran out.
  timeout,

  /// A newer toast took its place.
  replaced,
}

/// A shown toast; [dismiss] takes it away early and [closed] tells when it
/// is gone.
class DsToastController {
  DsToastController._(this._host, this._request);

  final _ToastHostState _host;
  final _ToastRequest _request;

  /// Whether the toast is still on screen (not dismissed or replaced).
  bool get isShowing => !_request.dismissed;

  /// Completes when the toast closes, with the reason, as it starts to
  /// leave: from then on its action no longer runs.
  ///
  /// An undo flow commits here unless the action was pressed:
  ///
  /// ```dart
  /// final toast = showDsToast(
  ///   context: context,
  ///   title: 'Task deleted',
  ///   actionLabel: 'Undo',
  ///   onAction: restoreTask,
  /// );
  /// if (await toast.closed != DsToastClosedReason.action) {
  ///   deleteTaskForGood();
  /// }
  /// ```
  Future<DsToastClosedReason> get closed => _request.closed.future;

  /// Hides the toast; [closed] completes with
  /// [DsToastClosedReason.dismissed].
  void dismiss() => _host._dismiss(_request, DsToastClosedReason.dismissed);
}

/// The look of a toast's content, for previews and custom hosts. Usually
/// shown with [showDsToast].
class DsToast extends StatelessWidget {
  /// Creates toast content.
  const DsToast({
    super.key,
    required this.title,
    this.description,
    this.status,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.style,
  });

  /// What happened ("Changes saved").
  final String title;

  /// Context in a few words ("Derlio Web · just now").
  final String? description;

  /// Adds a status icon; the shape tells the status, not only the color.
  /// Screen readers hear the status by name ("Error").
  final DsStatus? status;

  /// A short action, e.g. undo ("Undo").
  final String? actionLabel;

  /// Runs the action.
  final VoidCallback? onAction;

  /// Shows a close button that runs this.
  final VoidCallback? onDismiss;

  /// Style laid over the theme and defaults.
  final DsToastStyle? style;

  /// Desen's default toast style under [theme].
  static DsToastStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsToastStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      borderRadius: BorderRadius.circular(theme.radii.overlay),
      padding: const EdgeInsetsDirectional.fromSTEB(
        DsSpace.s16,
        DsSpace.s12,
        DsSpace.s12,
        DsSpace.s12,
      ),
      maxWidth: 420,
      gap: DsSpace.s12,
      iconSize: 20,
      closeIconSize: 14,
      titleStyle: theme.typography.bodyStrong.copyWith(color: k.text),
      descriptionStyle: theme.typography.caption.copyWith(color: k.textMuted),
      textGap: 1,
    );
  }

  static DsIconData _icon(DsStatus status) => switch (status) {
    DsStatus.success => DsIcons.circleCheck,
    DsStatus.warning => DsIcons.triangleAlert,
    DsStatus.danger => DsIcons.circleAlert,
    DsStatus.info || DsStatus.neutral => DsIcons.info,
  };

  static String? _statusLabel(DsLocalizations l10n, DsStatus status) =>
      switch (status) {
        DsStatus.success => l10n.success,
        DsStatus.warning => l10n.warning,
        DsStatus.danger => l10n.error,
        DsStatus.info => l10n.info,
        DsStatus.neutral => null,
      };

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final k = t.colors;
    final l10n = DsLocalizations.of(context);
    final s = DsToastStyle.resolveLayers([
      defaultStyle(t),
      DsToastTheme.of(context).style,
      style,
    ], const {});
    final bg = s.background ?? k.overlay;
    Color? iconColor;
    if (status case final st?) {
      final c = k.status(st);
      // The vivid signal when it reads at 3:1 on the toast (it does on the
      // default floating layer), else the status text color (as in
      // DsAlert).
      iconColor =
          DsColorUtils.contrastRatio(c.signal, bg, backdrop: k.surface) >= 3
          ? c.signal
          : c.text;
    }
    return DsSurface(
      constraints: BoxConstraints(maxWidth: s.maxWidth ?? double.infinity),
      padding: s.padding,
      decoration: DsBoxDecoration(
        color: bg,
        borderRadius: s.borderRadius ?? BorderRadius.zero,
        shadows: s.shadows ?? const [],
      ),
      backdropFilter: s.backdropFilter,
      // With focus on the action or the close button, the keyboard scrolls
      // the text when it is capped.
      child: LayerScrollKeys(
        builder: (context, controller) => LayoutBuilder(
          builder: (context, constraints) => Row(
            spacing: s.gap ?? DsSpace.s12,
            children: [
              if (status case final st?)
                DsIcon(
                  _icon(st),
                  size: s.iconSize!,
                  color: iconColor,
                  semanticLabel: _statusLabel(l10n, st),
                ),
              Expanded(
                // Scrolls when the toast is capped (long text at large scale).
                // The text is read as part of the toast, not as a scroll area
                // of its own, so the live region still says it.
                child: Semantics(
                  label: [title, ?description].join('\n'),
                  child: ExcludeSemantics(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: s.textGap!,
                        children: [
                          Text(title, style: s.titleStyle),
                          if (description != null)
                            Text(description!, style: s.descriptionStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (actionLabel != null)
                // A long action on a narrow screen shortens instead of pushing
                // the toast past its edge.
                // At most two fifths of the toast; its label then ends in an
                // ellipsis (screen readers get it whole).
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth.isFinite
                        ? constraints.maxWidth * 0.4
                        : double.infinity,
                  ),
                  child: DsButton(
                    variant: DsButtonVariant.ghost,
                    size: DsSize.sm,
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              if (onDismiss != null)
                DsButton.icon(
                  variant: DsButtonVariant.ghost,
                  size: DsSize.sm,
                  icon: DsIcon(DsIcons.x, size: s.closeIconSize),
                  semanticLabel: l10n.dismissNotification,
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a toast at the bottom of the screen: a status
/// icon, a title, an optional action such as undo, and a close button.
///
/// - **Timing (WCAG 2.2.1):** it goes away after [DsMotion.toastDuration]
///   (twice that with an action), paused while the pointer, a finger or
///   keyboard focus is on it. While a screen reader navigates
///   ([MediaQueryData.accessibleNavigation]) a toast with an action stays
///   until it is dismissed, as Material's snack bar does, so the action
///   can be reached.
/// - **Keyboard:** F8 moves focus into the toast (as in Radix) and Escape
///   inside it dismisses it; focus then returns to where it was. With focus
///   inside, Page Up, Page Down, Arrow Up, Arrow Down, Home and End scroll
///   text too long for the screen.
/// - **Dismissal:** the close button, the action, a sideways swipe, or a
///   newer toast: one shows at a time and a new one replaces it, even
///   within the same frame. The returned controller's
///   [DsToastController.closed] completes with the reason, so an undo flow
///   knows when to commit.
/// - **Screen readers** hear it as a live region, the status by name. A
///   [DsStatus.danger] toast is announced assertively instead (it
///   interrupts), where the platform supports announcements
///   ([MediaQueryData.supportsAnnounce]); it is then not a live region too,
///   so it is heard once. Without announcement support (Android) it stays
///   a polite live region.
/// - **Context:** it follows the theme above the [Overlay] live and keeps
///   the theme, component themes, direction and localization scope that
///   [context] has below it ([DsCapturedThemes]). It stays above the
///   on-screen keyboard and below the status bar: long text at a large
///   text scale scrolls inside the toast.
///
/// [actionLabel] and [onAction] come together: a label alone would show a
/// button that does nothing.
///
/// Needs an [Overlay] above [context].
DsToastController showDsToast({
  required BuildContext context,
  required String title,
  String? description,
  DsStatus? status,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  assert(
    (actionLabel == null) == (onAction == null),
    'actionLabel and onAction come together.',
  );
  final overlay = Overlay.of(context, rootOverlay: true);
  final host = _ToastHostState._hosts[overlay] ??= _ToastHostState._(overlay);
  final l10n = DsLocalizations.of(context);
  return host._show(
    _ToastRequest(
      captured: DsCapturedThemes.capture(from: context, to: overlay.context),
      hasAction: actionLabel != null,
      // What an assertive announcement says: the status, title and
      // description, as the live region would read them.
      urgent: status == DsStatus.danger
          ? (
              [l10n.error, title, ?description].join('\n'),
              Directionality.maybeOf(context) ?? TextDirection.ltr,
            )
          : null,
      toast: (close) => DsToast(
        title: title,
        description: description,
        status: status,
        actionLabel: actionLabel,
        // Closed first, so the reason is the action even when the action
        // shows a new toast; a toast already leaving runs no action.
        onAction: onAction == null
            ? null
            : () {
                if (close(DsToastClosedReason.action)) onAction();
              },
        onDismiss: () => close(DsToastClosedReason.dismissed),
      ),
      duration: duration,
    ),
  );
}

class _ToastRequest {
  _ToastRequest({
    required this.captured,
    required this.hasAction,
    required this.toast,
    required this.duration,
    this.urgent,
  });

  final DsCapturedThemes captured;
  final bool hasAction;

  /// For a danger toast: the assertive announcement and its direction.
  final (String, TextDirection)? urgent;

  /// Builds the content; `close` returns whether it closed the toast (false
  /// when it was already closing).
  final Widget Function(bool Function(DsToastClosedReason reason) close) toast;

  /// Null: the theme's notice duration (twice that with an action).
  final Duration? duration;

  /// Dismissed or replaced: it leaves as soon as it can.
  bool dismissed = false;

  /// Completed with the reason when it is dismissed or replaced.
  final closed = Completer<DsToastClosedReason>();

  /// The view once mounted. A toast replaced before its first frame has
  /// none yet; it leaves as soon as it mounts.
  _ToastViewState? view;

  OverlayEntry? entry;
}

/// One per overlay: shows one toast at a time.
class _ToastHostState {
  _ToastHostState._(this._overlay);

  static final _hosts = Expando<_ToastHostState>();

  final OverlayState _overlay;
  _ToastRequest? _current;

  DsToastController _show(_ToastRequest request) {
    if (_current case final old?) {
      _dismiss(old, DsToastClosedReason.replaced);
    }
    _current = request;
    final entry = OverlayEntry(
      builder: (context) => _ToastView(
        request: request,
        // A toast's own timer, swipe and close button always take that
        // toast away, whether it is the current one or not.
        onClose: (reason) => _dismiss(request, reason),
        onGone: () {
          // Removed and disposed: an entry is the host's to free.
          request.entry
            ?..remove()
            ..dispose();
          request.entry = null;
        },
      ),
    );
    request.entry = entry;
    _overlay.insert(entry);
    return DsToastController._(this, request);
  }

  /// Closes [request] for [reason]; false when it was already closing.
  bool _dismiss(_ToastRequest request, DsToastClosedReason reason) {
    if (request.dismissed) return false;
    request.dismissed = true;
    request.closed.complete(reason);
    if (_current == request) _current = null;
    request.view?._leave();
    return true;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.request,
    required this.onClose,
    required this.onGone,
  });

  final _ToastRequest request;
  final bool Function(DsToastClosedReason reason) onClose;
  final VoidCallback onGone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final _reveal = AnimationController.unbounded(vsync: this);
  final _region = FocusNode(
    debugLabel: 'DsToast',
    canRequestFocus: false,
    skipTraversal: true,
  );
  Timer? _timer;
  bool _hovered = false, _focused = false, _held = false, _leaving = false;
  bool _accessible = false, _started = false;

  /// Announced assertively rather than through the polite live region.
  bool _assertive = false;
  double _swipe = 0;
  DsMotion _motion = const DsMotion();

  /// Where focus was before F8 moved it into the toast.
  FocusNode? _returnFocus;

  @override
  void initState() {
    super.initState();
    widget.request.view = this;
    FocusManager.instance.addEarlyKeyEventHandler(_onHotkey);
    if (widget.request.dismissed) {
      // Replaced before its first frame: it never shows, it just goes.
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onGone());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion =
        widget.request.captured.theme?.motion ?? DsTheme.motionOf(context);
    final accessible = MediaQuery.accessibleNavigationOf(context);
    final changed = accessible != _accessible;
    _accessible = accessible;
    if (!_started && !_leaving) {
      _started = true;
      if (widget.request.urgent case (final message, final direction)
          when MediaQuery.supportsAnnounceOf(context)) {
        // Danger interrupts. Once, when it shows; a toast replaced
        // before its first frame never shows and is not announced.
        _assertive = true;
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            message,
            direction,
            assertiveness: Assertiveness.assertive,
          ),
        );
      }
      _reveal.animateWith(
        (_motion.reduced ? _motion.toneSpring : _motion.moveSpring).simulate(
          to: 1,
        ),
      );
      _restart();
    } else if (changed) {
      _restart();
    }
  }

  @override
  void dispose() {
    if (widget.request.view == this) widget.request.view = null;
    // Its overlay left the tree with the toast still up.
    widget.onClose(DsToastClosedReason.dismissed);
    FocusManager.instance.removeEarlyKeyEventHandler(_onHotkey);
    _timer?.cancel();
    _reveal.dispose();
    _region.dispose();
    super.dispose();
  }

  Duration get _duration =>
      widget.request.duration ??
      _motion.toastDuration * (widget.request.hasAction ? 2 : 1);

  void _restart() {
    _timer?.cancel();
    if (_hovered || _focused || _held || _leaving) return;
    // A screen reader user must be able to reach the action (WCAG 2.2.1).
    if (_accessible && widget.request.hasAction) return;
    _timer = Timer(
      _duration,
      () => widget.onClose(DsToastClosedReason.timeout),
    );
  }

  /// F8 moves focus into the toast, to its first control. It runs before
  /// the focused widgets, and only F8 that moved focus stops there.
  KeyEventResult _onHotkey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.f8 ||
        _leaving ||
        _region.hasFocus) {
      return KeyEventResult.ignored;
    }
    // The first control in reading order.
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final nodes = _region.traversalDescendants.toList()
      ..sort((a, b) {
        final byRow = a.rect.top.compareTo(b.rect.top);
        if (byRow != 0) return byRow;
        final byX = a.rect.left.compareTo(b.rect.left);
        return rtl ? -byX : byX;
      });
    final first = nodes.firstOrNull;
    if (first == null) return KeyEventResult.ignored;
    _returnFocus = FocusManager.instance.primaryFocus;
    first.requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose(DsToastClosedReason.dismissed);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _release() {
    _held = false;
    _restart();
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    if (_region.hasFocus) {
      final back = _returnFocus;
      if (back != null && back.context != null) back.requestFocus();
    }
    _returnFocus = null;
    _reveal
        .animateWith(
          _motion.toneSpring.simulate(
            from: _reveal.value,
            to: 0,
            velocity: _reveal.velocity,
          ),
        )
        .then((_) => widget.onGone());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final travel = _motion.reduced ? 0.0 : 16.0;
    // Above the home indicator and the on-screen keyboard.
    final bottom = media.viewInsets.bottom + media.padding.bottom + DsSpace.s16;
    // Below the status bar: a long toast at large text scrolls its text
    // instead of growing off the top of the screen.
    final room = media.size.height - bottom - media.padding.top - DsSpace.s16;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: widget.request.captured.wrap(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: DsSpace.s16),
            constraints: BoxConstraints(maxHeight: math.max(0, room)),
            child: Semantics(
              container: true,
              // Not both: a danger toast already announced itself.
              liveRegion: !_assertive,
              child: MouseRegion(
                onEnter: (_) {
                  _hovered = true;
                  _restart();
                },
                onExit: (_) {
                  _hovered = false;
                  _restart();
                },
                child: Focus(
                  focusNode: _region,
                  onKeyEvent: _onKey,
                  // Focus anywhere inside pauses the timer.
                  onFocusChange: (focused) {
                    _focused = focused;
                    if (!focused) _returnFocus = null;
                    _restart();
                  },
                  child: Listener(
                    // A finger resting on the toast pauses it too, as the
                    // pointer does (WCAG 2.2.1).
                    onPointerDown: (_) {
                      _held = true;
                      _restart();
                    },
                    onPointerUp: (_) => _release(),
                    onPointerCancel: (_) => _release(),
                    // Screen readers get no scroll action from the swipe,
                    // which would dismiss the toast: the close button and
                    // Escape do that.
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onHorizontalDragUpdate: (d) =>
                          setState(() => _swipe += d.delta.dx),
                      onHorizontalDragEnd: (d) {
                        if (_swipe.abs() > 80 ||
                            (d.primaryVelocity ?? 0).abs() > 700) {
                          widget.onClose(DsToastClosedReason.dismissed);
                        } else {
                          setState(() => _swipe = 0);
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _reveal,
                        builder: (context, child) {
                          final v = _reveal.value;
                          return Opacity(
                            opacity: v.clamp(0, 1),
                            child: Transform.translate(
                              offset: Offset(_swipe, travel * (1 - v)),
                              child: child,
                            ),
                          );
                        },
                        child: widget.request.toast(widget.onClose),
                      ),
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
