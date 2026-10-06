import 'package:flutter/widgets.dart';

import 'shadow.dart';

/// A straight decorative line, such as a separator in a list, menu or
/// toolbar.
///
/// It takes one logical pixel across [axis] and fills its constraints
/// along it. As a [hairline] it paints one device pixel, centered in that
/// space and snapped to the pixel grid, in a color strengthened to carry
/// the same ink as the full pixel (see [DsShadow.hairlineColor]): crisp
/// rather than soft on high-density screens, like an iOS separator.
class DsLine extends LeafRenderObjectWidget {
  /// A line of [color] along [axis].
  const DsLine({
    super.key,
    required this.color,
    this.axis = Axis.horizontal,
    this.hairline = true,
  });

  /// Line color.
  final Color color;

  /// The direction the line runs: horizontal for a line between rows.
  final Axis axis;

  /// Whether the line is one device pixel wide instead of one logical
  /// pixel.
  final bool hairline;

  double _ratio(BuildContext context) =>
      MediaQuery.maybeDevicePixelRatioOf(context) ??
      // ds-raw: identity
      View.maybeOf(context)?.devicePixelRatio ??
      1;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLine(color, axis, hairline, _ratio(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderLine)
      ..color = color
      ..axis = axis
      ..hairline = hairline
      ..devicePixelRatio = _ratio(context);
  }
}

class _RenderLine extends RenderBox {
  _RenderLine(this._color, this._axis, this._hairline, this._dpr);

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  Axis _axis;
  set axis(Axis v) {
    if (v == _axis) return;
    _axis = v;
    markNeedsLayout();
  }

  bool _hairline;
  set hairline(bool v) {
    if (v == _hairline) return;
    _hairline = v;
    markNeedsPaint();
  }

  double _dpr;
  set devicePixelRatio(double v) {
    if (v == _dpr) return;
    _dpr = v;
    markNeedsPaint();
  }

  // The line's slot: one logical pixel across, the available length along.
  Size _size(BoxConstraints c) {
    double along(double max) => max.isFinite ? max : 0;
    return c.constrain(
      _axis == Axis.horizontal
          ? Size(along(c.maxWidth), 1)
          : Size(1, along(c.maxHeight)),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _size(constraints);

  @override
  void performLayout() => size = _size(constraints);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _axis == Axis.vertical ? 1 : 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _axis == Axis.horizontal ? 1 : 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_color.a == 0 || size.isEmpty) return;
    final thin = _hairline && _dpr > 1;
    final width = thin ? 1 / _dpr : 1.0;
    final color = thin ? DsShadow.hairlineColor(_color, _dpr) : _color;
    double snap(double v) => (v * _dpr).roundToDouble() / _dpr;
    final box = offset & size;
    final Rect line;
    if (_axis == Axis.horizontal) {
      final top = snap(box.center.dy - width / 2);
      line = Rect.fromLTRB(snap(box.left), top, snap(box.right), top + width);
    } else {
      final left = snap(box.center.dx - width / 2);
      line = Rect.fromLTRB(left, snap(box.top), left + width, snap(box.bottom));
    }
    context.canvas.drawRect(line, Paint()..color = color);
  }
}
