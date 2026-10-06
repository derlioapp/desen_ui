import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays tags in lines and gives the last child, the text, the rest of the
/// last line, or a line of its own when less than [inputMinWidth] is left
/// (an HTML tag input: the text follows the tags). Children are centered
/// in their line.
///
/// [collapsed] keeps it to one line. The first [tagCount] children are the
/// tags, then come the "+N" chips (the one at `tagCount + N - 1` counts N
/// hidden tags), then the text. Only the tags that fit, measured, beside
/// their chip and the text's [inputMinWidth] show, with the one chip that
/// counts the rest; the other children are not painted, hit or in the
/// semantics tree. A tag is never clipped to make room, except the first:
/// rather than leave the chip alone it shrinks (its label ellipsized)
/// while it keeps at least twice the chip's width.
class TagFlow extends MultiChildRenderObjectWidget {
  /// Creates the flow; the last of [children] is the text.
  const TagFlow({
    super.key,
    required this.gap,
    required this.inputGap,
    required this.inputMinWidth,
    this.collapsed = false,
    this.tagCount = 0,
    super.children,
  });

  /// Space between children, along a line and between lines.
  final double gap;

  /// Extra space before the text when tags precede it.
  final double inputGap;

  /// Narrowest the text may get after tags on a line.
  final double inputMinWidth;

  /// Whether the tags stay on one line, the rest counted by a chip.
  final bool collapsed;

  /// How many of the children are tags; used when [collapsed].
  final int tagCount;

  @override
  RenderTagFlow createRenderObject(BuildContext context) => RenderTagFlow(
    gap: gap,
    inputGap: inputGap,
    inputMinWidth: inputMinWidth,
    collapsed: collapsed,
    tagCount: tagCount,
    direction: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderTagFlow renderObject) {
    renderObject
      ..gap = gap
      ..inputGap = inputGap
      ..inputMinWidth = inputMinWidth
      ..collapsed = collapsed
      ..tagCount = tagCount
      ..direction = Directionality.of(context);
  }
}

/// Parent data of a [TagFlow] child.
class TagFlowParentData extends ContainerBoxParentData<RenderBox> {}

/// One run of a [TagFlow], in child order: each child's size and offset
/// (zero for those not shown), which children show, and the height.
typedef _Flow = ({
  List<Size> sizes,
  List<Offset> offsets,
  List<bool> shown,
  double height,
});

/// Measures a child for constraints: a layout or a dry layout.
typedef _Measure = Size Function(RenderBox child, BoxConstraints constraints);

/// The render object of a [TagFlow].
class RenderTagFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TagFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TagFlowParentData> {
  /// Creates the render object.
  RenderTagFlow({
    required this._gap,
    required this._inputGap,
    required this._inputMinWidth,
    required this._direction,
    this._collapsed = false,
    this._tagCount = 0,
  });

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _inputGap;
  set inputGap(double value) {
    if (value == _inputGap) return;
    _inputGap = value;
    markNeedsLayout();
  }

  double _inputMinWidth;
  set inputMinWidth(double value) {
    if (value == _inputMinWidth) return;
    _inputMinWidth = value;
    markNeedsLayout();
  }

  bool _collapsed;
  set collapsed(bool value) {
    if (value == _collapsed) return;
    _collapsed = value;
    markNeedsLayout();
  }

  int _tagCount;
  set tagCount(int value) {
    if (value == _tagCount) return;
    _tagCount = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  /// Which children the last layout showed, in child order.
  List<bool> _shown = const [];

  bool _isShown(int index) => index >= _shown.length || _shown[index];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TagFlowParentData) {
      child.parentData = TagFlowParentData();
    }
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

  /// The tags among [children] (all but the text, at most [_tagCount]).
  int _tags(List<RenderBox> children) =>
      math.min(_tagCount, math.max(0, children.length - 1));

  /// The left edge of a child [childWidth] wide that starts [start] from
  /// the start edge of a line [width] wide.
  double _left(double start, double childWidth, double width) =>
      _direction == TextDirection.ltr ? start : width - start - childWidth;

  /// Runs the flow for [width].
  _Flow _flow(double width, _Measure measure) {
    final children = _children;
    final tags = _tags(children);
    if (_collapsed && tags > 0) {
      return _oneLine(width, children, tags, measure);
    }
    final sizes = <Size>[];
    final starts = <double>[]; // along the line, from the start edge
    final lineOf = <int>[];
    final lineHeights = <double>[];
    var x = 0.0;
    var line = 0;
    var lineHeight = 0.0;
    var hasTags = false;
    for (final child in children) {
      final isInput = child == children.last;
      Size size;
      double start;
      if (isInput) {
        final inset = hasTags ? _inputGap : 0.0;
        var room = width - x - (x > 0 ? _gap : 0);
        if (x > 0 && room - inset < _inputMinWidth) {
          lineHeights.add(lineHeight);
          line++;
          lineHeight = 0;
          x = 0;
          room = width;
        }
        start = x + (x > 0 ? _gap : 0) + inset;
        final w = math.max(0.0, room - inset);
        size = measure(child, BoxConstraints.tightFor(width: w));
      } else {
        hasTags = true;
        size = measure(child, BoxConstraints(maxWidth: width));
        if (x > 0 && x + _gap + size.width > width) {
          lineHeights.add(lineHeight);
          line++;
          lineHeight = 0;
          x = 0;
        }
        start = x + (x > 0 ? _gap : 0);
        x = start + size.width;
      }
      sizes.add(size);
      starts.add(start);
      lineOf.add(line);
      lineHeight = math.max(lineHeight, size.height);
    }
    lineHeights.add(lineHeight);
    final tops = <double>[];
    var y = 0.0;
    for (final h in lineHeights) {
      tops.add(y);
      y += h + _gap;
    }
    return (
      sizes: sizes,
      offsets: [
        for (var i = 0; i < sizes.length; i++)
          Offset(
            _left(starts[i], sizes[i].width, width),
            tops[lineOf[i]] + (lineHeights[lineOf[i]] - sizes[i].height) / 2,
          ),
      ],
      shown: List.filled(sizes.length, true),
      height: lineHeights.isEmpty ? 0.0 : y - _gap,
    );
  }

  /// The collapsed flow of [n] tags: those that fit on one line, the chip
  /// for the rest, then the text.
  _Flow _oneLine(
    double width,
    List<RenderBox> children,
    int n,
    _Measure measure,
  ) {
    final count = children.length;
    final sizes = List.filled(count, Size.zero);
    final shown = List.filled(count, false);
    final chips = count - 1 - n;
    // What the text keeps after the last item of the line.
    final reserve = _gap + _inputGap + _inputMinWidth;
    for (var i = 0; i < n; i++) {
      sizes[i] = measure(children[i], BoxConstraints(maxWidth: width));
    }
    // ends[k]: how wide the first k tags are side by side.
    final ends = <double>[0];
    for (var i = 0; i < n; i++) {
      ends.add(ends.last + (i > 0 ? _gap : 0) + sizes[i].width);
    }
    // Where an item after the first k tags starts.
    double after(int k) => k > 0 ? ends[k] + _gap : 0;
    Size chip(int hidden) {
      final i = n + hidden - 1;
      return sizes[i] = measure(
        children[i],
        BoxConstraints(maxWidth: math.max(0.0, width - reserve)),
      );
    }

    var k = n;
    if (ends[n] + reserve > width && (chips >= 1 || n == 1)) {
      // Never "+0": at least one tag hides, at most as many as there are
      // chips for.
      final least = math.max(0, n - chips);
      k = n - 1;
      while (k > least && after(k) + reserve > width) {
        k--;
      }
      while (k > least && after(k) + chip(n - k).width + reserve > width) {
        k--;
      }
      if (k == 0) {
        // Nothing fits beside the chip: the first tag shrinks rather than
        // leave the chip alone, while it keeps a useful width. A single
        // tag has no chip and just shrinks.
        final more = n > 1 && chips >= n - 1 ? chip(n - 1) : null;
        final room = width - reserve - (more == null ? 0 : _gap + more.width);
        if (n == 1 ||
            (more != null &&
                room >= math.min(sizes[0].width, 2 * more.width))) {
          k = 1;
          sizes[0] = measure(
            children[0],
            BoxConstraints(maxWidth: math.max(0.0, room)),
          );
          ends[1] = sizes[0].width;
        }
      }
    }
    final starts = List.filled(count, 0.0);
    for (var i = 0; i < k; i++) {
      shown[i] = true;
      starts[i] = after(i);
    }
    var end = ends[k];
    if (k < n) {
      final i = n + (n - k) - 1;
      chip(n - k);
      shown[i] = true;
      starts[i] = after(k);
      end = starts[i] + sizes[i].width;
    }
    final input = count - 1;
    shown[input] = true;
    starts[input] = end + (end > 0 ? _gap + _inputGap : 0);
    sizes[input] = measure(
      children[input],
      BoxConstraints.tightFor(width: math.max(0.0, width - starts[input])),
    );
    var height = 0.0;
    for (var i = 0; i < count; i++) {
      if (shown[i]) height = math.max(height, sizes[i].height);
    }
    return (
      sizes: sizes,
      offsets: [
        for (var i = 0; i < count; i++)
          shown[i]
              ? Offset(
                  _left(starts[i], sizes[i].width, width),
                  (height - sizes[i].height) / 2,
                )
              : Offset.zero,
      ],
      shown: shown,
      height: height,
    );
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final measured = <RenderBox>{};
    final flow = _flow(width, (child, c) {
      measured.add(child);
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    var child = firstChild;
    var i = 0;
    while (child != null) {
      // The chips the flow did not try get an empty size: every child has
      // one (for finders and the inspector), though it does not show.
      if (!measured.contains(child)) {
        child.layout(BoxConstraints.tight(Size.zero));
      }
      (child.parentData! as TagFlowParentData).offset = flow.offsets[i++];
      child = childAfter(child);
    }
    if (!listEquals(_shown, flow.shown)) {
      _shown = flow.shown;
      markNeedsSemanticsUpdate();
    }
    size = constraints.constrain(Size(width, flow.height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final flow = _flow(
      constraints.maxWidth,
      (child, c) => child.getDryLayout(c),
    );
    return constraints.constrain(Size(constraints.maxWidth, flow.height));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final children = _children;
    var widest = _inputMinWidth;
    for (var i = 0; i < _tags(children); i++) {
      widest = math.max(widest, children[i].getMinIntrinsicWidth(height));
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // Every tag and the text on one line; no chip is needed then.
    final children = _children;
    if (children.isEmpty) return 0;
    var total = math.max(
      _inputMinWidth,
      children.last.getMaxIntrinsicWidth(height),
    );
    for (var i = 0; i < _tags(children); i++) {
      total += children[i].getMaxIntrinsicWidth(height) + _gap;
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      width.isFinite ? _flow(width, (c, k) => c.getDryLayout(k)).height : 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    var i = childCount - 1;
    while (child != null) {
      final data = child.parentData! as TagFlowParentData;
      if (_isShown(i)) {
        final box = child;
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) =>
              box.hitTest(result, position: transformed),
        );
        if (hit) return true;
      }
      child = data.previousSibling;
      i--;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    var i = 0;
    while (child != null) {
      final data = child.parentData! as TagFlowParentData;
      if (_isShown(i)) context.paintChild(child, offset + data.offset);
      child = data.nextSibling;
      i++;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    var i = 0;
    while (child != null) {
      if (_isShown(i)) visitor(child);
      child = childAfter(child);
      i++;
    }
  }
}

/// Sizes its child exactly as wide as the incoming minimum width, or
/// [minWidth] if that is wider (within the maximum): a popup as wide as
/// its trigger, even when its content would stretch (a list).
class MatchWidth extends SingleChildRenderObjectWidget {
  /// Creates the box.
  const MatchWidth({super.key, this.minWidth = 0, super.child});

  /// The narrowest width.
  final double minWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMatchWidth(minWidth);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderMatchWidth).minWidth = minWidth;
}

class _RenderMatchWidth extends RenderProxyBox {
  _RenderMatchWidth(this._minWidth);

  double _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) {
    final width = math.max(c.minWidth, _minWidth).clamp(0.0, c.maxWidth);
    return c.copyWith(minWidth: width, maxWidth: width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(_inner(constraints)) ?? _inner(constraints).smallest;

  @override
  void performLayout() {
    final inner = _inner(constraints);
    final child = this.child;
    if (child == null) {
      size = inner.smallest;
      return;
    }
    child.layout(inner, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

/// A trailing button's box: it takes [visual] square in the layout while
/// the button inside keeps its full tap target, centered on it, so the
/// field does not grow. As the text field's own buttons.
class ActionTapArea extends SingleChildRenderObjectWidget {
  /// Creates the area.
  const ActionTapArea({super.key, required this.visual, super.child});

  /// The button's drawn width and height.
  final double visual;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderActionTapArea(visual);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderActionTapArea).visual = visual;
}

class _RenderActionTapArea extends RenderShiftedBox {
  _RenderActionTapArea(this._visual) : super(null);

  double _visual;
  set visual(double value) {
    if (value == _visual) return;
    _visual = value;
    markNeedsLayout();
  }

  Size get _own => Size.square(_visual);

  @override
  double computeMinIntrinsicWidth(double height) => _visual;

  @override
  double computeMaxIntrinsicWidth(double height) => _visual;

  @override
  double computeMinIntrinsicHeight(double width) => _visual;

  @override
  double computeMaxIntrinsicHeight(double width) => _visual;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_own);

  @override
  void performLayout() {
    size = constraints.constrain(_own);
    final child = this.child;
    if (child == null) return;
    child.layout(const BoxConstraints(), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    // The button's own tap target reaches past this box.
    if (!(offset & child.size).contains(position)) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// The node of a "+N" tag: [label] ("2 more") with the hidden tags' labels
/// as its value, the last [hidden] of [labels]. The value is joined only
/// for the chip in the semantics tree, not for every chip built.
class HiddenTagsSemantics extends SingleChildRenderObjectWidget {
  /// Creates the node.
  const HiddenTagsSemantics({
    super.key,
    required this.label,
    required this.labels,
    required this.hidden,
    super.child,
  });

  /// What the chip reads as.
  final String label;

  /// Every chosen value's label, in order.
  final List<String> labels;

  /// How many of [labels], from the end, the chip stands for.
  final int hidden;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHiddenTagsSemantics(
        label,
        labels,
        hidden,
        Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHiddenTagsSemantics)
      ..label = label
      ..labels = labels
      ..hidden = hidden
      ..direction = Directionality.of(context);
  }
}

class _RenderHiddenTagsSemantics extends RenderProxyBox {
  _RenderHiddenTagsSemantics(
    this._label,
    this._labels,
    this._hidden,
    this._direction,
  );

  String _label;
  set label(String value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  List<String> _labels;
  set labels(List<String> value) {
    if (identical(value, _labels)) return;
    _labels = value;
    markNeedsSemanticsUpdate();
  }

  int _hidden;
  set hidden(int value) {
    if (value == _hidden) return;
    _hidden = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final from = math.max(0, _labels.length - _hidden);
    config
      ..isSemanticBoundary = true
      ..label = _label
      ..value = _labels.sublist(from).join(', ')
      ..textDirection = _direction;
  }
}
