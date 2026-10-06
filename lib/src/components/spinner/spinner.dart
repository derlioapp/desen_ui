import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'spinner_style.dart';

/// An indeterminate loading indicator: a ring with its top quarter open,
/// turning once per `DsMotion.spinner`.
///
/// Size and color default to the ambient [IconTheme], so inside a button it
/// takes the label color; a [DsSpinnerStyle] sets them otherwise.
///
/// With reduced motion (`DsMotion.reduced`) it does not turn: the ring
/// stays still and slowly pulses its opacity, so it still reads as working
/// (WCAG 2.2.2).
class DsSpinner extends StatefulWidget {
  /// Creates a spinner.
  const DsSpinner({super.key, this.semanticLabel, this.style});

  /// Announced by screen readers. Null keeps the spinner decorative, for
  /// when surrounding text already says something is loading.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsSpinnerStyle? style;

  /// Desen's default spinner style under [theme]: size and color follow
  /// the ambient icon theme.
  static DsSpinnerStyle defaultStyle(DsThemeData theme) {
    return const DsSpinnerStyle(strokeWidth: 2);
  }

  @override
  State<DsSpinner> createState() => _DsSpinnerState();
}

class _DsSpinnerState extends State<DsSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(vsync: this);
  late final Animation<double> _pulse = Tween<double>(
    begin: .35,
    end: 1,
  ).animate(_turns);
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = DsTheme.motionOf(context);
    // Reduced motion: a slow pulse, three turns long, back and forth.
    final period = motion.reduced ? motion.spinner * 3 : motion.spinner;
    if (_turns.duration != period || _reduced != motion.reduced) {
      _reduced = motion.reduced;
      _turns.duration = period;
      _turns.repeat(reverse: _reduced);
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsSpinnerStyle.resolveLayers([
      DsSpinner.defaultStyle(t),
      DsSpinnerTheme.of(context).style,
      widget.style,
    ], const {});
    final icon = IconTheme.of(context);
    final size = s.size ?? (icon.size != null ? icon.size! * 14 / 16 : 14);
    final color = s.color ?? icon.color ?? t.colors.text;
    final ring = CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(color, s.strokeWidth ?? 0),
    );
    // Its own layer: the animation repaints the spinner only (eng M13).
    Widget spinner = RepaintBoundary(
      child: _reduced
          ? FadeTransition(opacity: _pulse, child: ring)
          : RotationTransition(turns: _turns, child: ring),
    );
    if (widget.semanticLabel != null) {
      spinner = Semantics(
        label: widget.semanticLabel,
        liveRegion: true,
        child: spinner,
      );
    } else {
      spinner = ExcludeSemantics(child: spinner);
    }
    return spinner;
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // CSS draws a 2px border inside the box; the stroke centerline sits half
    // a stroke in from the edge.
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 4,
      math.pi * 3 / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
