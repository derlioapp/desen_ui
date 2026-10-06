import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shape.dart';
import '../../theme/radii.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'progress_bar_style.dart';
import 'progress_ring_style.dart';

/// [v] (0–1) as the progress bar value. Not a localized text: Flutter's
/// progress-bar role requires a number or "N%" (it becomes aria-valuenow on
/// the web), and screen readers speak it in the user's language, together
/// with the 0–100 range.
String _percent(double v) => '${(v.clamp(0, 1) * 100).round()}%';

/// [v] as shown: null (indeterminate) for null or NaN, otherwise held to
/// 0–1, an infinity at its end.
double? _progress(double? v) =>
    v == null || v.isNaN ? null : v.clamp(0.0, 1.0);

/// A linear progress bar: an accent fill on a recessed track, the fill
/// 3:1 off the track.
///
/// A null [value] shows an indeterminate sweep (a static partial bar when
/// the platform asks to reduce motion).
class DsProgressBar extends StatefulWidget {
  /// Creates a progress bar. [value] is 0–1, or null for indeterminate.
  const DsProgressBar({
    super.key,
    this.value,
    this.animate = true,
    this.semanticLabel,
    this.style,
  });

  /// Progress, 0–1. Null means indeterminate, and so does NaN (`0 / 0`
  /// before a total is known): it is never shown or announced as done.
  /// Values outside 0–1, infinities included, are held to the nearer end.
  final double? value;

  /// Whether a change of [value] moves briefly into place. True by default,
  /// so a value that arrives in steps (a download) travels instead of
  /// jumping.
  ///
  /// Turn it off when [value] follows a gesture or a scroll position: it
  /// changes every frame, and each change would restart the move, so the
  /// fill would trail behind. The fill then draws each value as given. The
  /// indeterminate sweep is not affected.
  final bool animate;

  /// What is progressing, for screen readers.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsProgressBarStyle? style;

  /// Desen's default progress bar style under [theme].
  static DsProgressBarStyle defaultStyle(DsThemeData theme) {
    return DsProgressBarStyle(
      height: 6,
      trackColor: theme.colors.channelStrong,
      trackShadows: theme.shadows.channel,
      fillColor: theme.colors.indicator,
      borderRadius: BorderRadius.circular(DsRadii.pill),
    );
  }

  @override
  State<DsProgressBar> createState() => _DsProgressBarState();
}

class _DsProgressBarState extends State<DsProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this);

  double? get _value => _progress(widget.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSweep();
  }

  @override
  void didUpdateWidget(DsProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSweep();
  }

  void _syncSweep() {
    final motion = DsTheme.motionOf(context);
    _sweep.duration = motion.indeterminate;
    final run = _value == null && !motion.reduced;
    if (run && !_sweep.isAnimating) _sweep.repeat();
    if (!run && _sweep.isAnimating) _sweep.stop();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsProgressBarStyle.resolveLayers([
      DsProgressBar.defaultStyle(t),
      DsProgressBarTheme.of(context).style,
      widget.style,
    ], const {});
    final radius = s.borderRadius ?? BorderRadius.zero;
    final fill = DecoratedBox(
      decoration: DsBoxDecoration(color: s.fillColor, borderRadius: radius),
    );

    Widget filled(double v) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: v,
      heightFactor: 1,
      child: fill,
    );

    Widget bar;
    if (_value case final value? when !widget.animate) {
      bar = filled(value);
    } else if (_value case final value?) {
      bar = TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: t.motion.toneDuration,
        curve: t.motion.toneCurve,
        builder: (context, v, _) => filled(v),
      );
    } else {
      bar = AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => LayoutBuilder(
          builder: (context, c) {
            const segment = 0.35;
            final x = t.motion.reduced
                ? 0.0
                : (-segment + _sweep.value * (1 + segment)) * c.maxWidth;
            return Stack(
              children: [
                PositionedDirectional(
                  start: x,
                  top: 0,
                  bottom: 0,
                  width: c.maxWidth * segment,
                  child: fill,
                ),
              ],
            );
          },
        ),
      );
    }

    return Semantics(
      // Determinate: a progress bar with a 0–100 range. Indeterminate: a
      // loading indicator, which has no value to report.
      role: _value == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      // Indeterminate progress says it is loading (S-14).
      label:
          widget.semanticLabel ??
          (_value == null ? DsLocalizations.of(context).loading : null),
      value: _value == null ? null : _percent(_value!),
      minValue: _value == null ? null : '0',
      maxValue: _value == null ? null : '100',
      // Its own layer: the indeterminate sweep repaints every frame and
      // must not repaint what is around it (denetim-2 eng P6).
      child: RepaintBoundary(
        child: DsShapeClip(
          borderRadius: radius,
          child: Container(
            height: s.height,
            // The fill paints over any inner line the track draws.
            decoration: DsBoxDecoration(
              color: s.trackColor,
              borderRadius: radius,
              shadows: s.trackShadows ?? const [],
            ),
            child: bar,
          ),
        ),
      ),
    );
  }
}

/// A circular progress ring with an optional centered label: an accent
/// arc on a recessed track, the arc 3:1 off the track.
///
/// A null [value] turns a quarter arc continuously; with reduced motion
/// the arc stays still and slowly pulses instead.
class DsProgressRing extends StatefulWidget {
  /// Creates a progress ring. [value] is 0–1, or null for indeterminate.
  const DsProgressRing({
    super.key,
    this.value,
    this.animate = true,
    this.child,
    this.semanticLabel,
    this.style,
  });

  /// Progress, 0–1. Null and NaN mean indeterminate, as on
  /// [DsProgressBar.value]; values outside 0–1 are held to the nearer end.
  final double? value;

  /// Whether a change of [value] moves briefly into place. True by default.
  /// Turn it off when [value] follows a gesture or a scroll position, so
  /// the arc does not trail behind; see [DsProgressBar.animate].
  final bool animate;

  /// Centered content, e.g. a percentage in `DsTypography.numeric`.
  final Widget? child;

  /// What is progressing, for screen readers.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsProgressRingStyle? style;

  /// Desen's default progress ring style under [theme].
  static DsProgressRingStyle defaultStyle(DsThemeData theme) {
    return DsProgressRingStyle(
      size: 46,
      strokeWidth: 5,
      trackColor: theme.colors.channelStrong,
      trackEdgeColor:
          theme.shadows.channel.firstOrNull?.color ?? const Color(0x00000000),
      fillColor: theme.colors.indicator,
      foreground: theme.colors.text,
    );
  }

  @override
  State<DsProgressRing> createState() => _DsProgressRingState();
}

class _DsProgressRingState extends State<DsProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this);

  double? get _value => _progress(widget.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DsProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool _reduced = false;

  void _sync() {
    final motion = DsTheme.motionOf(context);
    final reduced = motion.reduced;
    final period = reduced ? motion.spinner * 3 : motion.spinner;
    final changed = reduced != _reduced || _spin.duration != period;
    _reduced = reduced;
    _spin.duration = period;
    if (_value == null && (changed || !_spin.isAnimating)) {
      _spin.repeat(reverse: reduced);
    }
    if (_value != null && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsProgressRingStyle.resolveLayers([
      DsProgressRing.defaultStyle(t),
      DsProgressRingTheme.of(context).style,
      widget.style,
    ], const {});
    final size = s.size ?? 0;
    final edge = s.trackEdgeColor;
    Widget ring(double value, double start) => CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        value: value,
        start: start,
        track: s.trackColor ?? const Color(0x00000000),
        trackEdge: edge != null && edge.a > 0 ? edge : null,
        fill: s.fillColor ?? const Color(0x00000000),
        stroke: s.strokeWidth ?? 0,
      ),
    );

    final Widget painted = _value != null
        ? widget.animate
              ? TweenAnimationBuilder<double>(
                  tween: Tween(end: _value!),
                  duration: t.motion.toneDuration,
                  curve: t.motion.toneCurve,
                  builder: (context, v, _) => ring(v, 0),
                )
              : ring(_value!, 0)
        : RepaintBoundary(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => _reduced
                  // Still, pulsing between 35% and full opacity.
                  ? Opacity(
                      // ds-raw: the reduced-motion pulse, DsSpinner's floor
                      opacity: .35 + .65 * _spin.value,
                      child: ring(0.25, 0),
                    )
                  : ring(0.25, _spin.value),
            ),
          );

    return Semantics(
      // Determinate: a progress bar with a 0–100 range. Indeterminate: a
      // loading indicator, which has no value to report.
      role: _value == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      // Indeterminate progress says it is loading (S-14).
      label:
          widget.semanticLabel ??
          (_value == null ? DsLocalizations.of(context).loading : null),
      value: _value == null ? null : _percent(_value!),
      minValue: _value == null ? null : '0',
      maxValue: _value == null ? null : '100',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            painted,
            if (widget.child != null)
              DefaultTextStyle.merge(
                style: TextStyle(color: s.foreground),
                child: widget.child!,
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.start,
    required this.track,
    required this.trackEdge,
    required this.fill,
    required this.stroke,
  });

  final double value, start, stroke;
  final Color track, fill;

  /// The channel's edge lines, or null for none.
  final Color? trackEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (trackEdge case final edge?) {
      // Hairlines just inside the channel's outer and inner edges.
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            1 // ds-raw: a hairline
        ..color = edge;
      final inset = (stroke - 1) / 2; // ds-raw: half a hairline
      canvas
        ..drawOval(rect.inflate(inset), line)
        ..drawOval(rect.deflate(inset), line);
    }
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2 + start * math.pi * 2,
      value * math.pi * 2,
      false,
      paint
        ..color = fill
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.start != start ||
      old.track != track ||
      old.trackEdge != trackEdge ||
      old.fill != fill ||
      old.stroke != stroke;
}
