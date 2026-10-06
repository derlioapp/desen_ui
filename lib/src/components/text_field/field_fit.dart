/// Internal: how a field's parts give way when it is too narrow for them.
/// Not exported from the package.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The order in which a field's extras give way when the field is too
/// narrow: lower goes first. The text keeps [fieldMinTextWidth] until
/// every extra is gone; the leading slot goes only when even an empty
/// text area would not fit beside it.
abstract final class FieldYield {
  /// The clear button (the text can still be cleared from the keyboard
  /// and by the semantics action).
  static const clear = 0;

  /// The error icon (the edge and the field's message still carry the
  /// error, and the field reads as invalid).
  static const error = 1;

  /// The trailing slot: a unit or a short text, and a search field's
  /// shortcut hint.
  static const trailing = 2;

  /// A picker's popup button and a number field's step buttons (Alt+Down,
  /// typing, the arrow keys and the semantics actions remain).
  static const action = 3;

  /// The show-password button: the last button to go.
  static const reveal = 4;

  /// The leading slot, only so that nothing overflows.
  static const leading = 5;
}

/// The smallest width a field's text area keeps while extras can still
/// give way: about three or four characters of [style].
double fieldMinTextWidth(TextStyle style, TextScaler scaler) =>
    // (A style without a size draws at Flutter's default.)
    scaler.scale(style.fontSize ?? kDefaultFontSize) * 2;

/// What a child of a [FieldFitRow] is.
sealed class FieldPart {
  const FieldPart();
}

/// The text (or the part holding it): fills the room the others leave.
/// [minWidth] is what it keeps before the last-resort parts give way; a
/// nested [FieldFitRow] in it adds its own parts.
///
/// With [hug] it takes only the width its content asks (its max intrinsic
/// width, up to the room left), so the part after it follows the text, as
/// a unit follows a value ("72 kg"); the rest of the row stays empty.
final class FieldMain extends FieldPart {
  /// Creates the main part.
  const FieldMain({this.minWidth = 0, this.hug = false});

  /// The width the text keeps while extras can give way.
  final double minWidth;

  /// Whether it takes its content's width instead of all the room.
  final bool hug;

  @override
  bool operator ==(Object other) =>
      other is FieldMain && other.minWidth == minWidth && other.hug == hug;

  @override
  int get hashCode => Object.hash(minWidth, hug);
}

/// A part that gives way at [order] (see [FieldYield]). A [lastResort]
/// part gives way only when an empty text area would not fit beside it.
///
/// An [affix] (text that belongs to the value, such as a unit or
/// "https://") sits [FieldFitRow.affixSpacing] from the main part instead
/// of [FieldFitRow.spacing].
final class FieldExtra extends FieldPart {
  /// Creates an extra.
  const FieldExtra(this.order, {this.lastResort = false, this.affix = false});

  /// When it gives way; lower goes first.
  final int order;

  /// Whether it gives way only to avoid an overflow.
  final bool lastResort;

  /// Whether it is text that belongs to the value, set close to it.
  final bool affix;

  @override
  bool operator ==(Object other) =>
      other is FieldExtra &&
      other.order == order &&
      other.lastResort == lastResort &&
      other.affix == affix;

  @override
  int get hashCode => Object.hash(order, lastResort, affix);
}

/// A row of a field's parts that never overflows: when the parts do not
/// fit, extras give way in [FieldYield] order (they are not painted, hit
/// or read) and the text keeps its room. Laid out like a `Row` with
/// [spacing] between the shown parts, and [affixSpacing] between the main
/// part and an affix beside it.
///
/// A [FieldFitRow] under the [FieldMain] child (through single-child
/// wrappers such as `Semantics`) takes part in the same order: the outer
/// row plans with the inner one's parts, and the inner one hides its own
/// as the room it is given asks.
class FieldFitRow extends MultiChildRenderObjectWidget {
  /// Creates the row; [parts] matches [children] one to one.
  const FieldFitRow({
    super.key,
    required this.parts,
    required this.spacing,
    double? affixSpacing,
    this.mainRightInset = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.onLevel,
    super.children,
  }) : affixSpacing = affixSpacing ?? spacing,
       assert(parts.length == children.length);

  /// What each child is.
  final List<FieldPart> parts;

  /// Space between two shown parts.
  final double spacing;

  /// Space between the main part and an affix ([FieldExtra.affix]) beside
  /// it.
  final double affixSpacing;

  /// Empty space the main part keeps at its right edge, such as a text
  /// editor's caret margin. An affix on that side sits this much closer,
  /// so it reads [affixSpacing] from the text on both sides.
  final double mainRightInset;

  /// Center or start.
  final CrossAxisAlignment crossAxisAlignment;

  /// Called after a frame whose layout changed which parts give way: the
  /// highest [FieldYield] order given way, or -1 for none.
  final ValueChanged<int>? onLevel;

  @override
  RenderFieldFitRow createRenderObject(BuildContext context) =>
      RenderFieldFitRow(
        parts: parts,
        spacing: spacing,
        affixSpacing: affixSpacing,
        mainRightInset: mainRightInset,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: Directionality.of(context),
        onLevel: onLevel,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFieldFitRow renderObject,
  ) {
    renderObject
      ..parts = parts
      ..spacing = spacing
      ..affixSpacing = affixSpacing
      ..mainRightInset = mainRightInset
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = Directionality.of(context)
      ..onLevel = onLevel;
  }
}

/// Parent data of a [RenderFieldFitRow] child.
class FieldFitParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether the child currently gives way.
  bool hidden = false;
}

/// The render object of [FieldFitRow].
class RenderFieldFitRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FieldFitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FieldFitParentData> {
  /// Creates the render object.
  RenderFieldFitRow({
    required this._parts,
    required this._spacing,
    required this._affixSpacing,
    this._mainRightInset = 0,
    required this._crossAxisAlignment,
    required this._textDirection,
    this._onLevel,
  });

  List<FieldPart> _parts;
  set parts(List<FieldPart> value) {
    if (_listEquals(value, _parts)) return;
    _parts = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _affixSpacing;
  set affixSpacing(double value) {
    if (value == _affixSpacing) return;
    _affixSpacing = value;
    markNeedsLayout();
  }

  double _mainRightInset;
  set mainRightInset(double value) {
    if (value == _mainRightInset) return;
    _mainRightInset = value;
    markNeedsLayout();
  }

  /// The space before the shown part [b] when [a] is the shown part
  /// before it: tight between the main part and an affix, less the main
  /// part's own empty space on its right.
  double _gap(FieldPart a, FieldPart b) {
    bool affix(FieldPart p) => p is FieldExtra && p.affix;
    final ltr = _textDirection == TextDirection.ltr;
    if (a is FieldMain && affix(b)) {
      return ltr ? math.max(0, _affixSpacing - _mainRightInset) : _affixSpacing;
    }
    if (affix(a) && b is FieldMain) {
      return ltr ? _affixSpacing : math.max(0, _affixSpacing - _mainRightInset);
    }
    return _spacing;
  }

  /// The spaces between the parts at [shown] (indices, in order).
  double _gaps(List<int> shown) {
    var width = 0.0;
    for (var i = 1; i < shown.length; i++) {
      width += _gap(_parts[shown[i - 1]], _parts[shown[i]]);
    }
    return width;
  }

  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (value == _crossAxisAlignment) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  ValueChanged<int>? _onLevel;
  set onLevel(ValueChanged<int>? value) => _onLevel = value;

  int? _reportedLevel;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FieldFitParentData) {
      child.parentData = FieldFitParentData();
    }
  }

  static bool _listEquals(List<FieldPart> a, List<FieldPart> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  /// The main child, with its index.
  (RenderBox, FieldMain)? get _main {
    final children = _children;
    for (var i = 0; i < children.length && i < _parts.length; i++) {
      if (_parts[i] case final FieldMain m) return (children[i], m);
    }
    return null;
  }

  /// The [RenderFieldFitRow] under [box] through single-child wrappers.
  static RenderFieldFitRow? _nested(RenderObject box) {
    RenderObject? node = box;
    while (node != null) {
      if (node is RenderFieldFitRow) return node;
      RenderObject? only;
      var count = 0;
      node.visitChildren((child) {
        count++;
        only = child;
      });
      if (count != 1) return null;
      node = only;
    }
    return null;
  }

  double _widthOf(RenderBox child) =>
      child.getMaxIntrinsicWidth(double.infinity);

  /// Every give-way order here and in a nested row: (order, lastResort).
  Set<(int, bool)> get _orders => {
    for (final p in _parts)
      if (p case FieldExtra(:final order, :final lastResort))
        (order, lastResort),
    if (_main case (final box, _)) ...?_nested(box)?._orders,
  };

  bool _hides(FieldPart part, int level) =>
      part is FieldExtra && part.order <= level;

  /// The width every shown part takes at [level], with the text at
  /// [textMin].
  double minWidth(int level, {required bool keepText}) {
    final children = _children;
    var width = 0.0;
    final shown = <int>[];
    for (var i = 0; i < children.length; i++) {
      final part = _parts[i];
      if (_hides(part, level)) continue;
      shown.add(i);
      if (part is FieldMain) {
        final nested = _nested(children[i]);
        width += nested != null
            ? nested.minWidth(level, keepText: keepText)
            : (keepText ? part.minWidth : 0);
      } else {
        width += _widthOf(children[i]);
      }
    }
    return width + _gaps(shown);
  }

  /// The give-way level for [available] width: the highest order hidden.
  int levelFor(double available) {
    final orders = _orders.toList()..sort((a, b) => a.$1.compareTo(b.$1));
    var level = -1;
    for (final (order, lastResort) in orders) {
      if (lastResort) continue;
      if (minWidth(level, keepText: true) <= available) return level;
      level = order;
    }
    for (final (order, lastResort) in orders) {
      if (!lastResort) continue;
      if (minWidth(level, keepText: false) <= available) return level;
      level = order;
    }
    return level;
  }

  ({Size size, List<double> widths, int level}) _plan(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints c) layoutChild,
  ) {
    final children = _children;
    final available = constraints.maxWidth;
    final level = available.isFinite ? levelFor(available) : -1;
    final widths = List<double>.filled(children.length, 0);
    final heights = List<double>.filled(children.length, 0);
    var used = 0.0;
    final shown = <int>[];
    int? mainIndex;
    for (var i = 0; i < children.length; i++) {
      final part = _parts[i];
      if (_hides(part, level)) continue;
      shown.add(i);
      if (part is FieldMain) {
        mainIndex = i;
        continue;
      }
      final w = math.min(
        _widthOf(children[i]),
        math.max(0.0, available - used),
      );
      final size = layoutChild(
        children[i],
        BoxConstraints(maxWidth: w, maxHeight: constraints.maxHeight),
      );
      widths[i] = size.width;
      heights[i] = size.height;
      used += size.width;
    }
    used += _gaps(shown);
    if (mainIndex != null) {
      final main = children[mainIndex];
      final room = math.max(0.0, available - used);
      final hug = (_parts[mainIndex] as FieldMain).hug;
      final w = !available.isFinite
          ? main.getMaxIntrinsicWidth(constraints.maxHeight)
          : hug
          ? math.min(room, main.getMaxIntrinsicWidth(constraints.maxHeight))
          : room;
      final size = layoutChild(
        main,
        BoxConstraints(
          minWidth: w,
          maxWidth: w,
          maxHeight: constraints.maxHeight,
        ),
      );
      widths[mainIndex] = size.width;
      heights[mainIndex] = size.height;
      used += size.width;
    }
    final height = heights.fold(0.0, math.max);
    return (
      size: constraints.constrain(Size(used, height)),
      widths: widths,
      level: level,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _plan(constraints, (child, c) => child.getDryLayout(c)).size;

  @override
  void performLayout() {
    final plan = _plan(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = plan.size;
    final children = _children;
    final rtl = _textDirection == TextDirection.rtl;
    var x = 0.0;
    FieldPart? previous;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final data = child.parentData! as FieldFitParentData;
      data.hidden = _hides(_parts[i], plan.level);
      if (data.hidden) {
        // Kept laid out (its state and focus live on), never shown.
        child.layout(
          BoxConstraints.loose(Size(size.width, size.height)),
          parentUsesSize: false,
        );
        data.offset = Offset.zero;
        continue;
      }
      if (previous != null) x += _gap(previous, _parts[i]);
      previous = _parts[i];
      final w = child.size.width;
      final y = _crossAxisAlignment == CrossAxisAlignment.start
          ? 0.0
          : (size.height - child.size.height) / 2;
      data.offset = Offset(rtl ? size.width - x - w : x, y);
      x += w;
    }
    if (plan.level != _reportedLevel) {
      _reportedLevel = plan.level;
      final report = _onLevel;
      if (report != null) {
        final level = plan.level;
        SchedulerBinding.instance.addPostFrameCallback((_) => report(level));
      }
    }
  }

  Iterable<RenderBox> get _shown =>
      _children.where((c) => !(c.parentData! as FieldFitParentData).hidden);

  @override
  double computeMinIntrinsicWidth(double height) {
    final level = levelFor(0);
    return minWidth(level, keepText: false);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    var width = 0.0;
    for (var i = 0; i < children.length; i++) {
      final part = _parts[i];
      width += part is FieldMain
          ? math.max(part.minWidth, children[i].getMaxIntrinsicWidth(height))
          : _widthOf(children[i]);
    }
    return width + _gaps([for (var i = 0; i < children.length; i++) i]);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _children.fold(
    0.0,
    (h, c) => math.max(h, c.getMinIntrinsicHeight(double.infinity)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _children.fold(
    0.0,
    (h, c) => math.max(h, c.getMaxIntrinsicHeight(double.infinity)),
  );

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    double? result;
    for (final child in _shown) {
      final d = child.getDistanceToActualBaseline(baseline);
      if (d == null) continue;
      final y = d + (child.parentData! as FieldFitParentData).offset.dy;
      result = result == null ? y : math.min(result, y);
    }
    return result;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _shown) {
      context.paintChild(
        child,
        offset + (child.parentData! as FieldFitParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _shown.toList().reversed) {
      final data = child.parentData! as FieldFitParentData;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in _shown) {
      visitor(child);
    }
  }
}

/// Hands a picker's popup button to the [DsTextField] below: the field
/// lays it at its end like its own clear button, and lets it give way at
/// [FieldYield.action] when the field is too narrow.
class FieldEndAction extends InheritedWidget {
  /// Provides [button], drawn [visual] wide, to the field in [child].
  const FieldEndAction({
    super.key,
    required this.button,
    required this.visual,
    required super.child,
  });

  /// The button.
  final Widget button;

  /// The button's drawn width and height.
  final double visual;

  /// The action for the field at [context], if any.
  static FieldEndAction? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FieldEndAction>();

  @override
  bool updateShouldNotify(FieldEndAction oldWidget) =>
      button != oldWidget.button || visual != oldWidget.visual;
}
