import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// A spring, described the way iOS describes one: a perceptual [duration]
/// and a [bounce].
///
/// Every Desen animation is a spring. Tone changes (color,
/// opacity, shadow) use a spring without bounce, which never overshoots its
/// target: an overshooting color would flash. Movement (position, size,
/// scale) bounces a little.
///
/// Use [simulate] to drive an [AnimationController] directly, which keeps
/// the current velocity when the target changes mid-flight (see
/// `DsSpringValue`). Use [curve] and [settleDuration] for implicit
/// animations such as [AnimatedContainer]; they follow the same physics
/// but restart from rest when interrupted.
@immutable
class DsSpring {
  /// Creates a spring.
  const DsSpring({required this.duration, this.bounce = 0})
    : assert(bounce >= 0 && bounce < 1);

  /// Perceptual duration: the period of the undamped spring. The spring
  /// rests somewhat later; see [settleDuration].
  final Duration duration;

  /// 0 is critically damped (no overshoot); 0.15 overshoots slightly; 0.3
  /// is lively.
  final double bounce;

  /// A simulation from [from] to [to], starting with [velocity] (units per
  /// second). It counts as at rest within 0.2% of the distance travelled,
  /// so small moves (a 0.955 press scale) are judged as finely as large
  /// ones.
  SpringSimulation simulate({
    double from = 0,
    double to = 1,
    double velocity = 0,
  }) {
    final distance = (to - from).abs();
    final scale = distance > 1e-6 ? distance : 1e-3;
    return SpringSimulation(
      description,
      from,
      to,
      velocity,
      tolerance: Tolerance(distance: scale * .002, velocity: scale * .02),
    );
  }

  /// The physical spring. A zero (or negative) [duration] means "no
  /// animation": it is treated as a 1ms spring, which settles at once,
  /// instead of failing deep inside the physics.
  SpringDescription get description => SpringDescription.withDurationAndBounce(
    duration: duration > _instant ? duration : _instant,
    bounce: bounce,
  );

  static const _instant = Duration(milliseconds: 1);

  static final _settle = <DsSpring, Duration>{};

  /// How long the spring takes to come to rest from 0 to 1, starting still.
  ///
  /// Cached per spring; the cache is bounded, so an app generating springs
  /// on the fly does not grow it forever.
  Duration get settleDuration {
    if (duration <= Duration.zero) return Duration.zero;
    final cached = _settle[this];
    if (cached != null) return cached;
    if (_settle.length >= 64) _settle.clear();
    return _settle[this] = _computeSettle();
  }

  Duration _computeSettle() {
    final s = simulate();
    var ms = 1;
    while (ms < 5000 && !s.isDone(ms / 1000)) {
      ms++;
    }
    return Duration(milliseconds: ms);
  }

  /// This spring as a curve over [settleDuration], for implicit animations.
  Curve get curve => _DsSpringCurve(this);

  @override
  bool operator ==(Object other) =>
      other is DsSpring && other.duration == duration && other.bounce == bounce;

  @override
  int get hashCode => Object.hash(duration, bounce);

  @override
  String toString() =>
      'DsSpring(${duration.inMilliseconds}ms, bounce: $bounce)';
}

class _DsSpringCurve extends Curve {
  _DsSpringCurve(this.spring)
    : _simulation = spring.simulate(),
      _seconds = spring.settleDuration.inMicroseconds / 1e6;

  final DsSpring spring;
  final SpringSimulation _simulation;
  final double _seconds;

  @override
  double transformInternal(double t) =>
      _seconds == 0 ? 1 : _simulation.x(t * _seconds);

  @override
  bool operator ==(Object other) =>
      other is _DsSpringCurve && other.spring == spring;

  @override
  int get hashCode => spring.hashCode;
}
