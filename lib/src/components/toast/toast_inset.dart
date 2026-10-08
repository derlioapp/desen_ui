import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Marks bottom chrome that toasts must not cover, such as a mini player
/// or a docked media bar: while it shows, toasts from `showDsToast` sit
/// above it instead of over its controls.
///
/// It measures [child] itself, from its top edge to the bottom of the
/// screen, after every frame, so chrome that slides in or out, grows, or
/// stacks on another bar moves toasts along with it; there is no number
/// to keep in sync. With several marked bars, toasts clear the tallest
/// reach. Chrome that is not showing reserves nothing: zero height, moved
/// off the bottom of the screen, or on a page covered by another route.
///
/// `DsBottomNav` marks itself; wrap only chrome of your own.
///
/// ```dart
/// Column(
///   children: [
///     Expanded(child: page),
///     if (playing) DsToastInset(child: MiniPlayer(track)),
///     DsBottomNav(...),
///   ],
/// )
/// ```
class DsToastInset extends StatefulWidget {
  /// Marks [child] as chrome toasts keep clear of.
  const DsToastInset({super.key, required this.child});

  /// The chrome.
  final Widget child;

  @override
  State<DsToastInset> createState() => _DsToastInsetState();
}

/// How far from the bottom of [overlay] toasts keep clear: the largest
/// reach of the chrome marked under it, 0 with none. For the toast host;
/// not exported.
ValueListenable<double> dsToastInsetOf(OverlayState overlay) =>
    _ToastInsets.of(overlay);

/// The marked chrome under one root overlay, and the largest reach. It
/// lives as long as its overlay (an [Expando] entry), so it is a plain
/// listenable with nothing to dispose, not a [ChangeNotifier].
class _ToastInsets implements ValueListenable<double> {
  static final _all = Expando<_ToastInsets>();

  static _ToastInsets of(OverlayState overlay) =>
      _all[overlay] ??= _ToastInsets();

  final _reach = <Object, double>{};
  final _listeners = <VoidCallback>[];

  @override
  double get value => _reach.values.fold(0.0, math.max);

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void set(Object owner, double reach) {
    final before = value;
    if (reach <= 0) {
      _reach.remove(owner);
    } else {
      _reach[owner] = reach;
    }
    if (value == before) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

class _DsToastInsetState extends State<DsToastInset> {
  OverlayState? _overlay;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != _overlay) {
      if (_overlay case final old?) _ToastInsets.of(old).set(this, 0);
      _overlay = overlay;
    }
    _schedule();
  }

  @override
  void dispose() {
    if (_overlay case final overlay?) {
      // After the frame: the toast host may be building in this one.
      final insets = _ToastInsets.of(overlay);
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => insets.set(this, 0),
      );
    }
    super.dispose();
  }

  /// Measures after the next frame, and after every frame from then on
  /// while mounted. It schedules no frames itself, so a still screen
  /// costs nothing.
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      _measure();
      _schedule();
    });
  }

  void _measure() {
    final overlay = _overlay;
    if (overlay == null || !overlay.mounted) return;
    final insets = _ToastInsets.of(overlay);
    final box = context.findRenderObject();
    final screen = overlay.context.findRenderObject();
    // A page covered by another route stops its tickers.
    final showing = TickerMode.valuesOf(context).enabled;
    if (!showing ||
        box is! RenderBox ||
        screen is! RenderBox ||
        !box.attached ||
        !box.hasSize ||
        !screen.hasSize ||
        box.size.height <= 0) {
      insets.set(this, 0);
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: screen).dy;
    final height = screen.size.height;
    insets.set(this, (height - top).clamp(0, height).toDouble());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
