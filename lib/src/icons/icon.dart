import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/svg_path.dart';

/// A stroke icon described by SVG path data on a square canvas.
///
/// With [fill], each path is also filled: a play triangle or pause bars
/// become solid, the way `fill="currentColor"` fills a Lucide icon on the
/// web. The stroke still runs around the fill, so corners stay round and
/// the solid icon matches the outlined one in size. Open lines have no
/// area and look the same either way.
@immutable
class DsIconData {
  /// Creates icon data from SVG path strings.
  const DsIconData(
    this.paths, {
    this.viewBox = 24,
    this.strokeWidth = 2,
    this.matchTextDirection = false,
    this.fill = false,
  });

  /// SVG `d` strings, drawn as strokes.
  final List<String> paths;

  /// Width and height of the coordinate space.
  final double viewBox;

  /// Stroke width in [viewBox] units.
  final double strokeWidth;

  /// Mirror the icon in right-to-left text.
  final bool matchTextDirection;

  /// Fill each path as well as stroking it. [DsIcon.fill] overrides it.
  final bool fill;

  static final Expando<Path> _cache = Expando('DsIconData.path');
  static final Expando<List<Path>> _shapes = Expando('DsIconData.shapes');

  /// The combined path, parsed once per icon.
  Path get path => _cache[this] ??= () {
    final p = Path();
    for (final shape in _shapesOf(this)) {
      p.addPath(shape, Offset.zero);
    }
    return p;
  }();

  /// Each of [paths], parsed once per icon. They fill one by one, as
  /// separate SVG elements do: as one path, a shape inside another that
  /// winds the other way would cut a hole.
  static List<Path> _shapesOf(DsIconData icon) =>
      _shapes[icon] ??= [for (final d in icon.paths) dsParseSvgPath(d)];

  @override
  bool operator ==(Object other) =>
      other is DsIconData &&
      other.viewBox == viewBox &&
      other.strokeWidth == strokeWidth &&
      other.matchTextDirection == matchTextDirection &&
      other.fill == fill &&
      listEquals(other.paths, paths);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(paths),
    viewBox,
    strokeWidth,
    matchTextDirection,
    fill,
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
    this.fill,
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

  /// Fill the paths as well as stroking them; overrides [DsIconData.fill].
  /// A selected tab, for example, can show the same icon solid.
  final bool? fill;

  /// Read by screen readers. Without it the icon is decorative and hidden
  /// from the semantics tree.
  final String? semanticLabel;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderDsIcon(
    icon: icon,
    size: _size(context),
    color: _color(context),
    strokeWidth: strokeWidth ?? icon.strokeWidth,
    fill: fill ?? icon.fill,
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
      ..fill = fill ?? icon.fill
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
      ..add(FlagProperty('fill', value: fill, ifTrue: 'filled'))
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
    required this._fill,
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

  bool _fill;

  /// Fill the paths as well as stroking them.
  set fill(bool v) {
    if (v == _fill) return;
    _fill = v;
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
      ..scale(mirror ? -scale : scale, scale);
    if (_fill) {
      final fill = Paint()
        ..color = _color
        ..isAntiAlias = true;
      for (final shape in DsIconData._shapesOf(_icon)) {
        canvas.drawPath(shape, fill);
      }
    }
    canvas
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
