import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/svg_path.dart';

/// A stroke icon described by SVG path data on a square canvas.
@immutable
class DsIconData {
  /// Creates icon data from SVG path strings.
  const DsIconData(
    this.paths, {
    this.viewBox = 24,
    this.strokeWidth = 2,
    this.matchTextDirection = false,
  });

  /// SVG `d` strings, drawn as strokes.
  final List<String> paths;

  /// Width and height of the coordinate space.
  final double viewBox;

  /// Stroke width in [viewBox] units.
  final double strokeWidth;

  /// Mirror the icon in right-to-left text.
  final bool matchTextDirection;

  static final Expando<Path> _cache = Expando('DsIconData.path');

  /// The combined path, parsed once per icon.
  Path get path => _cache[this] ??= () {
    final p = Path();
    for (final d in paths) {
      p.addPath(dsParseSvgPath(d), Offset.zero);
    }
    return p;
  }();

  @override
  bool operator ==(Object other) =>
      other is DsIconData &&
      other.viewBox == viewBox &&
      other.strokeWidth == strokeWidth &&
      other.matchTextDirection == matchTextDirection &&
      listEquals(other.paths, paths);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(paths),
    viewBox,
    strokeWidth,
    matchTextDirection,
  );
}

/// Draws a [DsIconData].
///
/// Size and color default to the ambient [IconTheme]. The stroke scales with
/// the size (a 24-unit icon with stroke 2 drawn at 16px has a 1.33px stroke),
/// matching how the icon renders on the web.
class DsIcon extends LeafRenderObjectWidget {
  /// Creates an icon.
  const DsIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// The icon to draw.
  final DsIconData icon;

  /// Width and height. Defaults to [IconThemeData.size], then 16.
  final double? size;

  /// Stroke color. Defaults to [IconThemeData.color].
  final Color? color;

  /// Stroke width in [DsIconData.viewBox] units; overrides the icon's own.
  final double? strokeWidth;

  /// Read by screen readers. Without it the icon is decorative and hidden
  /// from the semantics tree.
  final String? semanticLabel;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderDsIcon(
    icon: icon,
    size: _size(context),
    color: _color(context),
    strokeWidth: strokeWidth ?? icon.strokeWidth,
    semanticLabel: semanticLabel,
    textDirection: Directionality.maybeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderDsIcon renderObject) {
    renderObject
      ..icon = icon
      ..iconSize = _size(context)
      ..color = _color(context)
      ..strokeWidth = strokeWidth ?? icon.strokeWidth
      ..semanticLabel = semanticLabel
      ..textDirection = Directionality.maybeOf(context);
  }

  double _size(BuildContext context) =>
      // ds-raw: unreachable, IconTheme.of fills the size in
      size ?? IconTheme.of(context).size ?? 16;

  Color _color(BuildContext context) {
    if (color != null) return color!;
    final theme = IconTheme.of(context);
    // ds-raw: unreachable, IconTheme.of fills the color in
    final c = theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    return opacity == null || opacity == 1
        ? c
        : c.withValues(alpha: c.a * opacity);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('size', size, defaultValue: null))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

/// The render object behind [DsIcon].
class RenderDsIcon extends RenderBox {
  /// Creates the render object.
  RenderDsIcon({
    required this._icon,
    required this._size,
    required this._color,
    required this._strokeWidth,
    required this._semanticLabel,
    required this._textDirection,
  });

  DsIconData _icon;

  /// The icon.
  set icon(DsIconData v) {
    if (v == _icon) return;
    _icon = v;
    markNeedsPaint();
  }

  double _size;

  /// Width and height.
  set iconSize(double v) {
    if (v == _size) return;
    _size = v;
    markNeedsLayout();
  }

  Color _color;

  /// Stroke color.
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  double _strokeWidth;

  /// Stroke width in view box units.
  set strokeWidth(double v) {
    if (v == _strokeWidth) return;
    _strokeWidth = v;
    markNeedsPaint();
  }

  String? _semanticLabel;

  /// Screen reader label.
  set semanticLabel(String? v) {
    if (v == _semanticLabel) return;
    _semanticLabel = v;
    markNeedsSemanticsUpdate();
  }

  TextDirection? _textDirection;

  /// Used to mirror directional icons.
  set textDirection(TextDirection? v) {
    if (v == _textDirection) return;
    _textDirection = v;
    if (_icon.matchTextDirection) markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  // Report the icon's natural size, so intrinsic layouts (IntrinsicWidth,
  // equal-width segments, tables) can measure it.
  @override
  double computeMinIntrinsicWidth(double height) => _size;

  @override
  double computeMaxIntrinsicWidth(double height) => _size;

  @override
  double computeMinIntrinsicHeight(double width) => _size;

  @override
  double computeMaxIntrinsicHeight(double width) => _size;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(Size.square(_size));

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_color.a == 0) return;
    final canvas = context.canvas;
    final scale = _size / _icon.viewBox;
    final mirror =
        _icon.matchTextDirection && _textDirection == TextDirection.rtl;
    // Center inside the box in case constraints forced a different size.
    final dx = offset.dx + (size.width - _size) / 2;
    final dy = offset.dy + (size.height - _size) / 2;
    canvas
      ..save()
      ..translate(dx + (mirror ? _size : 0), dy)
      ..scale(mirror ? -scale : scale, scale)
      ..drawPath(
        _icon.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _color
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_semanticLabel != null) {
      config
        ..isSemanticBoundary = true
        ..label = _semanticLabel!
        ..textDirection = _textDirection
        ..isImage = true;
    }
  }
}
