import 'package:flutter/widgets.dart';

import '../foundation/spring.dart';

/// Animates a number toward [value] with real spring physics.
///
/// Unlike an implicit animation, a new target taken mid-flight keeps the
/// current velocity, so quick repeated toggles flow instead of restarting
/// from rest (the iOS feel). The first build shows [value] without
/// animating. With [spring] null (reduce motion), the value jumps.
///
/// The value may overshoot the target when the spring bounces; clamp it in
/// [builder] where that would be wrong (e.g. a scale below zero).
class DsSpringValue extends StatefulWidget {
  /// Creates a spring-animated value.
  const DsSpringValue({
    super.key,
    required this.value,
    required this.spring,
    required this.builder,
    this.child,
  });

  /// The target value.
  final double value;

  /// The spring to move with; null jumps to [value].
  final DsSpring? spring;

  /// Builds with the current animated value.
  final ValueWidgetBuilder<double> builder;

  /// A subtree that does not depend on the value, passed to [builder].
  final Widget? child;

  @override
  State<DsSpringValue> createState() => _DsSpringValueState();
}

class _DsSpringValueState extends State<DsSpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(DsSpringValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    final spring = widget.spring;
    if (spring == null) {
      _controller.value = widget.value;
      return;
    }
    final target = widget.value;
    _controller
        .animateWith(
          spring.simulate(
            from: _controller.value,
            to: target,
            velocity: _controller.velocity,
          ),
        )
        // The simulation stops within its tolerance; land exactly.
        .then((_) {
          if (mounted && widget.value == target) _controller.value = target;
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        widget.builder(context, _controller.value, child),
    child: widget.child,
  );
}
