import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../foundation/spring.dart';

/// Motion rules. Every animation is a spring.
///
/// Only two kinds of motion exist:
/// - **Tone**: color, opacity and shadow changes ([toneSpring]): no bounce,
///   because an overshooting color flashes. Implicit animations read it as
///   [toneDuration] and [toneCurve].
/// - **Move**: position, size and scale ([moveSpring]), with a slight
///   bounce. Velocity-preserving animations take [moveSpringOrNull];
///   implicit ones read [moveDuration] and [moveCurve].
///
/// With [reduced] on (the platform's reduce-motion setting), movement is
/// disabled and only fades remain. Components must ask [moveDuration] or
/// [moveSpringOrNull] rather than reading [moveSpring] directly.
@immutable
class DsMotion {
  /// Creates motion rules.
  const DsMotion({
    this.toneSpring = const DsSpring(duration: Duration(milliseconds: 200)),
    this.moveSpring = const DsSpring(
      duration: Duration(milliseconds: 380),
      bounce: .28,
    ),
    this.pressScale = 0.97,
    this.pressScaleLarge = 0.955,
    this.overlayOffset = 6,
    this.overlayScale = 0.97,
    this.exitFactor = 0.7,
    this.shimmer = const Duration(milliseconds: 1600),
    this.spinner = const Duration(milliseconds: 800),
    this.indeterminate = const Duration(milliseconds: 1400),
    this.sweepCurve = Curves.easeInOut,
    this.hoverDelay = const Duration(milliseconds: 500),
    this.hoverGrace = const Duration(milliseconds: 120),
    this.submenuDelay = const Duration(milliseconds: 150),
    this.toastDuration = const Duration(seconds: 6),
    this.reduced = false,
  });

  /// Color, opacity and shadow transitions: a spring without bounce.
  final DsSpring toneSpring;

  /// Position, size and scale transitions: a spring with a slight bounce.
  final DsSpring moveSpring;

  /// Duration of a tone transition, for implicit animations.
  Duration get toneDuration => toneSpring.settleDuration;

  /// Curve of a tone transition, for implicit animations.
  Curve get toneCurve => toneSpring.curve;

  /// Curve of a move, for implicit animations: [moveSpring] as a [Curve].
  /// Pair it with [moveDuration].
  Curve get moveCurve => moveSpring.curve;

  /// [moveSpring], or null when [reduced] (the value then jumps).
  DsSpring? get moveSpringOrNull => reduced ? null : moveSpring;

  /// Scale of a pressed small control.
  final double pressScale;

  /// Scale of a pressed medium or large control. Larger controls shrink a
  /// little more so the press reads at the same strength.
  final double pressScaleLarge;

  /// Vertical travel of a menu or popover while it opens, in pixels.
  final double overlayOffset;

  /// Starting scale of a menu or popover while it opens.
  final double overlayScale;

  /// Exit durations are this fraction of the enter durations.
  final double exitFactor;

  /// One skeleton shimmer sweep.
  final Duration shimmer;

  /// One spinner turn.
  final Duration spinner;

  /// One sweep of an indeterminate progress bar.
  final Duration indeterminate;

  /// Easing of looping sweeps: shimmer and indeterminate progress.
  final Curve sweepCurve;

  /// How long the pointer rests on a trigger before a tooltip shows.
  final Duration hoverDelay;

  /// How long a tooltip stays after the pointer leaves, so it can move onto
  /// the tooltip (WCAG 1.4.13); also the window in which the next tooltip
  /// shows without delay.
  final Duration hoverGrace;

  /// How long the pointer rests on a menu item before its submenu opens,
  /// and how long a pointer heading for an open submenu may pause before
  /// the item under it takes over ("menu aim"). Shorter than [hoverDelay]:
  /// a submenu is navigation, not a hint (macOS and web menus open within
  /// about 0.1–0.2s).
  final Duration submenuDelay;

  /// How long a toast stays; twice as long with an action. Paused while
  /// the pointer or focus is on it (WCAG 2.2.1).
  final Duration toastDuration;

  /// Whether the platform asked to reduce motion.
  final bool reduced;

  /// Duration of a move, for implicit animations, or zero when [reduced].
  Duration get moveDuration =>
      reduced ? Duration.zero : moveSpring.settleDuration;

  /// [d] shortened for an exit transition.
  Duration exit(Duration d) => d * exitFactor;

  /// Returns a copy with the given fields replaced.
  DsMotion copyWith({
    DsSpring? toneSpring,
    DsSpring? moveSpring,
    double? pressScale,
    double? pressScaleLarge,
    double? overlayOffset,
    double? overlayScale,
    double? exitFactor,
    Duration? shimmer,
    Duration? spinner,
    Duration? indeterminate,
    Curve? sweepCurve,
    Duration? hoverDelay,
    Duration? hoverGrace,
    Duration? submenuDelay,
    Duration? toastDuration,
    bool? reduced,
  }) => DsMotion(
    toneSpring: toneSpring ?? this.toneSpring,
    moveSpring: moveSpring ?? this.moveSpring,
    pressScale: pressScale ?? this.pressScale,
    pressScaleLarge: pressScaleLarge ?? this.pressScaleLarge,
    overlayOffset: overlayOffset ?? this.overlayOffset,
    overlayScale: overlayScale ?? this.overlayScale,
    exitFactor: exitFactor ?? this.exitFactor,
    shimmer: shimmer ?? this.shimmer,
    spinner: spinner ?? this.spinner,
    indeterminate: indeterminate ?? this.indeterminate,
    sweepCurve: sweepCurve ?? this.sweepCurve,
    hoverDelay: hoverDelay ?? this.hoverDelay,
    hoverGrace: hoverGrace ?? this.hoverGrace,
    submenuDelay: submenuDelay ?? this.submenuDelay,
    toastDuration: toastDuration ?? this.toastDuration,
    reduced: reduced ?? this.reduced,
  );

  @override
  bool operator ==(Object other) =>
      other is DsMotion &&
      other.toneSpring == toneSpring &&
      other.moveSpring == moveSpring &&
      other.pressScale == pressScale &&
      other.pressScaleLarge == pressScaleLarge &&
      other.overlayOffset == overlayOffset &&
      other.overlayScale == overlayScale &&
      other.exitFactor == exitFactor &&
      other.shimmer == shimmer &&
      other.spinner == spinner &&
      other.indeterminate == indeterminate &&
      other.sweepCurve == sweepCurve &&
      other.hoverDelay == hoverDelay &&
      other.hoverGrace == hoverGrace &&
      other.submenuDelay == submenuDelay &&
      other.toastDuration == toastDuration &&
      other.reduced == reduced;

  @override
  int get hashCode => Object.hash(
    toneSpring,
    moveSpring,
    pressScale,
    pressScaleLarge,
    overlayOffset,
    overlayScale,
    exitFactor,
    shimmer,
    spinner,
    indeterminate,
    sweepCurve,
    hoverDelay,
    hoverGrace,
    submenuDelay,
    toastDuration,
    reduced,
  );
}
