import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/spring.dart';
import '../theme/motion.dart';
import '../theme/theme.dart';

/// Which back gesture is driving a [DsPageRoute].
enum _BackGesture { swipe, predictive }

/// A page transition: the new page fades in while rising 8px.
///
/// Motion follows the theme: the rise is the movement spring, the
/// fade the tone spring, and leaving is a quick fade. With reduce motion
/// on, only the fade remains. The motion comes from the [DsTheme] above the
/// navigator (`DsApp` puts one there), or the defaults without one.
///
/// **Back gestures.** On iOS a drag from the start edge (the left edge, the
/// right one in RTL) takes the page back: it follows the finger and pops
/// when released past [backSwipeDistance] of the width or flung toward the
/// end faster than [backSwipeFlingVelocity]; otherwise it settles back. On
/// Android 14+ the system's predictive back gesture previews the pop: the
/// page shrinks toward [predictiveBackScale] and drifts [rise] pixels away
/// from the swiped edge, then fades out when the gesture commits. Both
/// settle on a spring without bounce (a page edge that overshoots would
/// uncover the screen edge), and with reduce motion both only fade.
///
/// Neither gesture starts when the route cannot pop by itself: the first
/// route, a `PopScope(canPop: false)` (or any route whose
/// [popDisposition] is not [RoutePopDisposition.pop]), a route with local
/// history, or while it is still animating ([popGestureEnabled]). Full
/// screen dialogs ([fullscreenDialog]) have no edge swipe, as on iOS;
/// Android's back gesture still closes them.
class DsPageRoute<T> extends PageRoute<T> {
  /// Creates a route that shows [builder]'s widget.
  DsPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  /// How far the page rises while it comes in, in pixels.
  static const double rise = 8;

  /// Width of the strip along the start edge where the iOS back swipe
  /// begins, in pixels. A wider safe area inset (a notch in landscape)
  /// widens it.
  static const double backSwipeEdgeWidth = 20;

  /// Fraction of the width a released back swipe must have crossed to pop.
  static const double backSwipeDistance = .5;

  /// Release speed, in page widths per second, above which a back swipe
  /// follows the fling's direction regardless of [backSwipeDistance].
  static const double backSwipeFlingVelocity = 1;

  /// Scale the page shrinks to at the end of Android's predictive back.
  static const double predictiveBackScale = .9;

  DsMotion get _motion =>
      navigator?.context
          .getInheritedWidgetOfExactType<DsTheme>()
          ?.data
          .motion ??
      const DsMotion();

  @override
  Duration get transitionDuration =>
      _motion.reduced ? _motion.toneDuration : _motion.moveDuration;

  @override
  Duration get reverseTransitionDuration => _motion.toneDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  // The curved animations live as long as the route, not one build: they
  // listen to the route's animation and must be disposed (eng L4).
  Animation<double>? _parent;
  DsMotion? _curvesMotion;
  CurvedAnimation? _fade, _move;

  void _curves(Animation<double> parent, DsMotion motion) {
    if (identical(parent, _parent) && motion == _curvesMotion) return;
    _disposeCurves();
    _parent = parent;
    _curvesMotion = motion;
    final total = transitionDuration.inMicroseconds;
    // The fade settles on the tone spring's own time, inside the longer
    // movement.
    final fadeEnd = total == 0
        ? 1.0
        : (motion.toneDuration.inMicroseconds / total).clamp(0.0, 1.0);
    final leave = motion.toneCurve.flipped;
    _fade = CurvedAnimation(
      parent: parent,
      curve: Interval(0, fadeEnd, curve: motion.toneCurve),
      reverseCurve: leave,
    );
    _move = CurvedAnimation(
      parent: parent,
      curve: motion.moveCurve,
      reverseCurve: leave,
    );
  }

  void _disposeCurves() {
    _fade?.dispose();
    _move?.dispose();
    _fade = _move = null;
  }

  @override
  void dispose() {
    _disposeCurves();
    super.dispose();
  }

  // --- Back gestures -------------------------------------------------------

  /// The gesture driving the transition, from its start until the page has
  /// settled (popped or back in place).
  _BackGesture? _gesture;

  /// Android's swipe edge: the page drifts away from it.
  SwipeEdge _predictiveEdge = SwipeEdge.left;

  /// The controller value when a predictive back committed; the page fades
  /// out from there.
  double? _commitFrom;

  bool get _swipeEnabled =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      !fullscreenDialog &&
      popGestureEnabled;

  void _startSwipe() {
    assert(popGestureEnabled);
    _gesture = _BackGesture.swipe;
    _commitFrom = null;
    navigator!.didStartUserGesture();
  }

  /// [delta] is the drag toward the end edge, in page widths.
  void _updateSwipe(double delta) {
    if (!isCurrent) return;
    controller!.value -= delta;
  }

  /// [velocity] is toward the end edge, in page widths per second.
  void _endSwipe(double velocity) {
    final bool pop;
    if (velocity.abs() >= backSwipeFlingVelocity) {
      pop = velocity > 0;
    } else {
      pop = controller!.value < 1 - backSwipeDistance;
    }
    _settle(pop: pop, velocity: -velocity);
  }

  @override
  void handleStartBackGesture({double progress = 0.0}) {
    _gesture = _BackGesture.predictive;
    _commitFrom = null;
    super.handleStartBackGesture(progress: progress);
  }

  @override
  void handleCommitBackGesture() {
    _commitFrom = controller?.value;
    _settle(pop: true);
  }

  @override
  void handleCancelBackGesture() => _settle(pop: false);

  /// Ends a back gesture: pops or settles the page back, on a spring that
  /// keeps the release [velocity] (controller units per second), then ends
  /// the navigator's user gesture.
  ///
  /// Modeled on Cupertino's back gesture controller: when the route stopped
  /// being current mid-gesture (a programmatic pop or push), the direction
  /// follows whether it is still in the stack, not the gesture.
  void _settle({required bool pop, double velocity = 0}) {
    final c = controller!;
    final nav = navigator!;
    final motion = _motion;
    // No bounce: an overshooting page would uncover the screen edge
    // (K-46, like the accordion's height). Reduce motion: a fade on the
    // tone spring.
    final spring = motion.reduced
        ? motion.toneSpring
        : DsSpring(duration: motion.moveSpring.duration);
    final forward = isCurrent ? !pop : isActive;
    if (forward) {
      if (!c.isCompleted) {
        c.animateWith(spring.simulate(from: c.value, velocity: velocity));
      }
    } else {
      // Popping starts the controller's own reverse; take it over below.
      if (isCurrent) nav.pop();
      if (c.isAnimating) {
        c.animateBackWith(
          spring.simulate(from: c.value, to: 0, velocity: velocity),
        );
      }
    }
    void stop() {
      _gesture = null;
      if (nav.mounted) nav.didStopUserGesture();
    }

    if (c.isAnimating) {
      // The gesture's transition stays until the page has settled.
      late final AnimationStatusListener done;
      done = (status) {
        if (status.isAnimating) return;
        c.removeStatusListener(done);
        stop();
      };
      c.addStatusListener(done);
    } else {
      stop();
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final motion = DsTheme.motionOf(context);
    _curves(animation, motion);
    Widget page;
    if (motion.reduced) {
      // Only fades; a gesture fades with the finger.
      page = AnimatedBuilder(
        animation: animation,
        builder: (context, child) => FadeTransition(
          opacity: _gesture == null ? _fade! : animation,
          child: child,
        ),
        child: child,
      );
    } else {
      final dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
      page = AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final v = animation.value;
          var slide = 0.0, rising = 0.0, drift = 0.0;
          var scale = 1.0, opacity = 1.0;
          switch (_gesture) {
            case null:
              rising = rise * (1 - _move!.value);
              opacity = _fade!.value;
            case _BackGesture.swipe:
              // The page follows the finger toward the end edge.
              slide = (1 - v) * dir;
            case _BackGesture.predictive:
              final progress = 1 - v;
              scale = 1 - (1 - predictiveBackScale) * progress;
              drift =
                  rise *
                  progress *
                  (_predictiveEdge == SwipeEdge.left ? 1 : -1);
              if (_commitFrom case final from? when from > 0) {
                opacity = (v / from).clamp(0.0, 1.0);
              }
          }
          return FractionalTranslation(
            translation: Offset(slide, 0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(drift, rising, 0)
                ..scaleByDouble(scale, scale, 1, 1),
              child: Opacity(opacity: opacity, child: child),
            ),
          );
        },
        child: child,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && !fullscreenDialog) {
      page = _BackSwipeDetector(route: this, child: page);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      page = _PredictiveBackListener(route: this, child: page);
    }
    return page;
  }
}

/// Starts an iOS back swipe from the start edge and feeds it to the route.
///
/// A widgets-only port of Cupertino's back gesture detector: a strip along
/// the start edge listens for pointers and hands them to a horizontal drag
/// recognizer; the drag is converted to logical (end-ward) page widths.
class _BackSwipeDetector extends StatefulWidget {
  const _BackSwipeDetector({required this.route, required this.child});

  final DsPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackSwipeDetector> createState() => _BackSwipeDetectorState();
}

class _BackSwipeDetectorState extends State<_BackSwipeDetector> {
  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _onStart
        ..onUpdate = _onUpdate
        ..onEnd = _onEnd
        ..onCancel = _onCancel;

  bool _dragging = false;

  @override
  void dispose() {
    _recognizer.dispose();
    // Disposed mid-drag: end the navigator's user gesture after the frame.
    if (_dragging) {
      final nav = widget.route.navigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nav?.mounted ?? false) nav!.didStopUserGesture();
      });
    }
    super.dispose();
  }

  void _onStart(DragStartDetails details) {
    _dragging = true;
    widget.route._startSwipe();
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    widget.route._updateSwipe(_logical(details.primaryDelta! / _width));
  }

  void _onEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    widget.route._endSwipe(
      _logical(details.velocity.pixelsPerSecond.dx / _width),
    );
  }

  void _onCancel() {
    // Also called for a pointer that never started a drag.
    if (!_dragging) return;
    _dragging = false;
    widget.route._endSwipe(0);
  }

  double get _width => context.size!.width;

  double _logical(double value) =>
      Directionality.of(context) == TextDirection.rtl ? -value : value;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.route._swipeEnabled) _recognizer.addPointer(event);
  }

  @override
  Widget build(BuildContext context) {
    // A notch on the start side (landscape) widens the strip.
    final padding = MediaQuery.paddingOf(context);
    final inset = Directionality.of(context) == TextDirection.rtl
        ? padding.right
        : padding.left;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: math.max(inset, DsPageRoute.backSwipeEdgeWidth),
          child: Listener(
            onPointerDown: _onPointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Hands Android's predictive back gesture to the route while it is the
/// current one.
///
/// The binding offers the gesture to every observer; only the current,
/// poppable route takes it. A back button press is not a gesture: it pops
/// the usual way.
class _PredictiveBackListener extends StatefulWidget {
  const _PredictiveBackListener({required this.route, required this.child});

  final DsPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_PredictiveBackListener> createState() =>
      _PredictiveBackListenerState();
}

class _PredictiveBackListenerState extends State<_PredictiveBackListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    if (backEvent.isButtonEvent ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    route._predictiveEdge = backEvent.swipeEdge;
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) => widget
      .route
      .handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);

  @override
  void handleCancelBackGesture() => widget.route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() => widget.route.handleCommitBackGesture();

  @override
  Widget build(BuildContext context) => widget.child;
}
