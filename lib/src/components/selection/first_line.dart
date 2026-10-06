import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives [control] (a checkbox box, a radio circle, a switch track) a text
/// baseline such that, laid out on the baseline of a label in [lineStyle],
/// it sits centered on the label's first line box, as a browser centers an
/// input on the first line of its label. A label that wraps or carries a
/// description below keeps the control on its first line.
///
/// Use it in a `Row(crossAxisAlignment: .baseline)` beside the label.
class FirstLineControl extends StatelessWidget {
  /// Centers [control], [height] tall, on the first line of [lineStyle].
  const FirstLineControl({
    super.key,
    required this.height,
    required this.lineStyle,
    required this.child,
  });

  /// The control's height.
  final double height;

  /// The style of the label's first line (merged over the ambient
  /// [DefaultTextStyle]).
  final TextStyle? lineStyle;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(lineStyle);
    final painter = TextPainter(
      // ds-raw: measures one line's height, never painted
      text: TextSpan(text: 'Hg', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final line = painter.height;
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.dispose();
    // The control's center on the line box's center.
    return _SyntheticBaseline(
      baseline: height / 2 + baseline - line / 2,
      child: child,
    );
  }
}

/// Reports [baseline] as its child's alphabetic baseline.
class _SyntheticBaseline extends SingleChildRenderObjectWidget {
  const _SyntheticBaseline({required this.baseline, super.child});

  final double baseline;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSyntheticBaseline(baseline);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSyntheticBaseline renderObject,
  ) => renderObject.baseline = baseline;
}

class _RenderSyntheticBaseline extends RenderProxyBox {
  _RenderSyntheticBaseline(this._baseline);

  double _baseline;
  set baseline(double value) {
    if (value == _baseline) return;
    _baseline = value;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _baseline;
}
