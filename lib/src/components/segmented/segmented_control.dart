import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/haptic_feedback.dart';
import '../../foundation/color_utils.dart';
import '../../behavior/spring_value.dart';
import '../../behavior/focus_visibility.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'segmented_control_style.dart';

/// One option of a [DsSegmentedControl].
@immutable
class DsSegment<T> {
  /// Creates a segment. Give a [label], an [icon], or both; icon-only
  /// segments need a [semanticLabel].
  const DsSegment({
    required this.value,
    this.label,
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(label != null || icon != null, 'give a label or an icon'),
       assert(
         label != null || semanticLabel != null,
         'icon-only segments need a semanticLabel',
       );

  /// The value this segment stands for.
  final T value;

  /// The text, usually a short [Text].
  final Widget? label;

  /// An icon, alone or before the label.
  final Widget? icon;

  /// Name for screen readers; defaults to the label text.
  final String? semanticLabel;

  /// Whether this segment can be chosen.
  final bool enabled;
}

/// A single choice among a few options, with an indicator that slides in a
/// recessed channel.
///
/// Segments share the width of the widest one. In a narrower space each
/// takes its own width plus an equal share of the rest, so labels are not
/// cut while all of them fit; only narrower still do they shrink and
/// ellipsize (screen readers still get the whole label). The selected label is semibold; every segment reserves
/// that width, so moving the selection never resizes the control. A [value] that matches no
/// segment selects none. The control is one tab stop:
/// arrow keys (mirrored in RTL), Home and End move the selection, as in the
/// WAI-ARIA radio group pattern.
///
/// The indicator follows the theme's selection style: a raised thumb for
/// [DsSelectionStyle.soft], the strong selection fill for
/// [DsSelectionStyle.strong].
class DsSegmentedControl<T> extends StatefulWidget {
  /// Creates a segmented control.
  const DsSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(segments.length >= 2, 'a segmented control needs 2+ segments');

  /// The options, in order.
  final List<DsSegment<T>> segments;

  /// The selected value.
  final T value;

  /// Called with the newly selected value. Null disables the control.
  final ValueChanged<T>? onChanged;

  /// Style laid over the theme and defaults.
  final DsSegmentedControlStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Names the group for screen readers.
  final String? semanticLabel;

  /// Desen's default segmented style under [theme].
  static DsSegmentedControlStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final soft = theme.selectionStyle == DsSelectionStyle.soft;
    // The segments are [height] tall; the channel around them is a
    // control one inset taller on each side, its thumb concentric with it.
    // No radii here: both follow whatever height and inset the layers
    // settle on.
    return DsSegmentedControlStyle(
      height: theme.sizes.sm,
      inset: DsSpace.s3,
      gap: 2,
      trackColor: k.channel,
      trackShadows: theme.shadows.channel,
      thumbColor: soft ? k.channelThumb : k.selectionStrong,
      thumbShadows: [
        // Its own edge.
        if (soft) ...theme.shadows.channelThumb,
        // A bright filled thumb keeps its shape on the channel (denetim-2).
        if (!soft)
          if (theme.selectedEdge case final edge?) DsShadow.innerRing(edge),
      ],
      foreground: k.textMuted,
      textStyle: theme.typography.bodyStrong.copyWith(
        fontWeight: FontWeight.w500,
      ),
      itemPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s12,
      ),
      iconSize: 16,
      focusShadows: theme.focusShadows,
      hovered: DsSegmentedControlStyle(foreground: k.text),
      // The selected label also turns semibold, like iOS: the soft thumb
      // stands only ~1.3:1 off the channel, so the choice must not rest on
      // that and on ink alone (WCAG 1.4.1; denetim-2 ux M6). Every segment
      // reserves the semibold width, so nothing shifts.
      selected: DsSegmentedControlStyle(
        foreground: soft ? k.text : k.onSelectionStrong,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      disabled: DsSegmentedControlStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsSegmentedControl<T>> createState() => _DsSegmentedControlState<T>();
}

class _DsSegmentedControlState<T> extends State<DsSegmentedControl<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  int? _hovered, _pressed;

  /// The selected segment, or -1 when [DsSegmentedControl.value] matches
  /// none (it used to report the first one as checked).
  int get _index => widget.segments.indexWhere((s) => s.value == widget.value);

  bool get _enabled => widget.onChanged != null;

  /// Flutter's focus highlight, before the keyboard check.
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app (eng L6).
  void _onModality() {
    if (_highlight) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownNode?.dispose();
    super.dispose();
  }

  /// Selects segment [i]. A [touch] (a tap) ticks; keys and assistive
  /// actions are silent, as on iOS.
  void _select(int i, {bool touch = false}) {
    final s = widget.segments[i];
    if (!_enabled || !s.enabled || s.value == widget.value) return;
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    widget.onChanged!(s.value);
  }

  /// Moves the selection by [step], skipping disabled segments.
  void _move(int step) {
    final n = widget.segments.length;
    // From no selection, forward starts at the first, back at the last.
    var i = _index < 0 ? (step > 0 ? -1 : n) : _index;
    for (var tries = 0; tries < n; tries++) {
      i = (i + step) % n;
      if (i < 0) i += n;
      if (widget.segments[i].enabled) return _select(i);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _move(rtl && key == LogicalKeyboardKey.arrowRight ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _move(rtl && key == LogicalKeyboardKey.arrowLeft ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      final first = widget.segments.indexWhere((s) => s.enabled);
      if (first >= 0) _select(first);
    } else if (key == LogicalKeyboardKey.end) {
      final last = widget.segments.lastIndexWhere((s) => s.enabled);
      if (last >= 0) _select(last);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsSegmentedControl.defaultStyle(t),
      DsSegmentedControlTheme.of(context).style,
      widget.style,
    ];
    final base = DsSegmentedControlStyle.resolveLayers(layers, {
      if (_focusVisible) WidgetState.focused,
    });
    final n = widget.segments.length;
    final selected = _index;
    // The segment that stands for the group's focus: the selected one, or
    // the first enabled one when none is (APG radio group).
    final focusTarget = selected >= 0
        ? selected
        : widget.segments.indexWhere((s) => s.enabled);
    final gap = base.gap!;
    final height = base.height!;
    final inset = base.inset ?? DsSpace.s3;
    final corners = t.radii.controlCorners(
      base.borderRadius,
      height + 2 * inset,
    );

    Set<WidgetState> itemStates(int i) => {
      if (!_enabled || !widget.segments[i].enabled) WidgetState.disabled,
      if (i == selected) WidgetState.selected,
      if (_hovered == i) WidgetState.hovered,
      if (_pressed == i) WidgetState.pressed,
    };

    Widget item(int i) {
      final seg = widget.segments[i];
      final s = DsSegmentedControlStyle.resolveLayers(layers, itemStates(i));
      final fg = s.foreground ?? t.colors.text;
      final interactive = _enabled && seg.enabled;
      // The label's style when selected: its width is held whatever the
      // selection.
      final widest = DsSegmentedControlStyle.resolveLayers(layers, {
        ...itemStates(i),
        WidgetState.selected,
      }).textStyle;
      return Semantics(
        // A radio: checked in a mutually exclusive group, no button
        // flag (denetim-2 ux H1).
        inMutuallyExclusiveGroup: true,
        checked: i == selected,
        enabled: interactive,
        label: seg.semanticLabel,
        onTap: interactive ? () => _select(i) : null,
        // The group holds one focus node (one Tab stop, K-37); its focus
        // is reported on the selected segment, so a screen reader
        // announces it, not an unnamed node (denetim-2 ux H1).
        focusable: _enabled && i == focusTarget ? true : null,
        focused: _enabled && i == focusTarget ? _node.hasPrimaryFocus : null,
        onFocus:
            _enabled &&
                i == focusTarget &&
                defaultTargetPlatform != TargetPlatform.iOS
            ? _node.requestFocus
            : null,
        child: MouseRegion(
          cursor: interactive
              ? s.cursor ?? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onEnter: (_) => setState(() => _hovered = i),
          onExit: (_) => setState(() => _hovered = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: interactive ? (_) => setState(() => _pressed = i) : null,
            onTapCancel: () => setState(() => _pressed = null),
            onTapUp: (_) => setState(() => _pressed = null),
            onTap: interactive ? () => _select(i, touch: true) : null,
            // A minimum height grows with large text; the label
            // ellipsizes in a narrow control (B14, ux V5).
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              padding: s.itemPadding,
              alignment: Alignment.center,
              child: TweenAnimationBuilder<Color?>(
                tween: DsColorTween(end: fg),
                duration: t.motion.toneDuration,
                curve: t.motion.toneCurve,
                builder: (context, color, _) => IconTheme.merge(
                  data: IconThemeData(color: color, size: s.iconSize),
                  child: DefaultTextStyle(
                    style: (s.textStyle ?? const TextStyle()).copyWith(
                      color: color,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: DsSpace.s6,
                      children: [
                        ?seg.icon,
                        if (seg.label case final label?)
                          Flexible(
                            child: _ReservedWidth(style: widest, child: label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final thumb = DsBoxDecoration(
      color: base.thumbColor,
      borderRadius: t.radii.nestedCorners(base.thumbRadius, corners, inset),
      shadows: [
        ...?base.thumbShadows,
        if (_focusVisible) ...?base.focusShadows,
      ],
    );

    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Focus(
        // Key events travel up from the focused node, so the handler sits
        // above the detector that owns focus.
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _node,
          autofocus: widget.autofocus,
          enabled: _enabled,
          // Focus semantics sit on the selected segment instead.
          includeFocusSemantics: false,
          onFocusChange: (_) => setState(() {}),
          onShowFocusHighlight: (v) => setState(() => _highlight = v),
          child: DecoratedBox(
            decoration: DsBoxDecoration(
              color: base.trackColor,
              borderRadius: corners,
              shadows: base.trackShadows ?? const <DsShadow>[],
            ),
            child: Padding(
              padding: EdgeInsets.all(inset),
              child: DsSpringValue(
                value: selected < 0 ? 0 : selected.toDouble(),
                spring: t.motion.moveSpringOrNull,
                builder: (context, v, _) => _SegmentRow(
                  gap: gap,
                  // No matching value: no thumb.
                  position: selected < 0 ? null : v,
                  textDirection: Directionality.of(context),
                  children: [
                    DecoratedBox(decoration: thumb),
                    for (var i = 0; i < n; i++) item(i),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds the width a plain [Text] child takes in [style] (the selected
/// weight), so moving the selection never resizes the control; the label
/// stays centered in it. Other labels keep their own width.
class _ReservedWidth extends StatelessWidget {
  const _ReservedWidth({required this.style, required this.child});

  final TextStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = child;
    if (style == null || label is! Text || label.data == null) return label;
    final painter = TextPainter(
      text: TextSpan(
        text: label.data,
        style: DefaultTextStyle.of(context).style
            .merge(style)
            .merge(label.style),
      ),
      textDirection: Directionality.of(context),
      textScaler:
          label.textScaler ??
          MediaQuery.maybeTextScalerOf(context) ??
          TextScaler.noScaling,
      locale: label.locale ?? Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: Align(widthFactor: 1, child: label),
    );
  }
}

/// Lays out the thumb (first child) and the segments in a row.
///
/// Segments share the widest one's width when that fits. When it does not
/// but their own widths do, each takes its own width and an equal share of
/// what is left, so no label is cut while there is room for all of them.
/// Only when even that does not fit do they shrink, in proportion, and
/// labels ellipsize.
///
/// The thumb sits under the segment at [position], sliding and resizing
/// between neighbors at fractional values; null hides it.
class _SegmentRow extends MultiChildRenderObjectWidget {
  const _SegmentRow({
    required this.gap,
    required this.position,
    required this.textDirection,
    required super.children,
  });

  final double gap;
  final double? position;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSegmentRow(gap, position, textDirection);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSegmentRow)
      ..gap = gap
      ..position = position
      ..textDirection = textDirection;
  }
}

class _SegmentRowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSegmentRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SegmentRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SegmentRowParentData> {
  _RenderSegmentRow(this._gap, this._position, this._textDirection);

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double? _position;
  set position(double? v) {
    if (v == _position) return;
    _position = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  // Each segment's start offset and width, start to end.
  List<(double, double)> _slots = const [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SegmentRowParentData) {
      child.parentData = _SegmentRowParentData();
    }
  }

  RenderBox get _thumb => firstChild!;

  List<RenderBox> get _segments {
    final list = <RenderBox>[];
    var child = childAfter(_thumb);
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double _gaps(int n) => n > 1 ? _gap * (n - 1) : 0;

  double _equalWidth(double Function(RenderBox) measure) {
    final segments = _segments;
    var widest = 0.0;
    for (final s in segments) {
      final w = measure(s);
      if (w > widest) widest = w;
    }
    return widest * segments.length + _gaps(segments.length);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _equalWidth((s) => s.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _equalWidth((s) => s.getMaxIntrinsicWidth(height));

  double _tallest(double Function(RenderBox) measure) {
    var tallest = 0.0;
    for (final s in _segments) {
      final h = measure(s);
      if (h > tallest) tallest = h;
    }
    return tallest;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest((s) => s.getMinIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest((s) => s.getMaxIntrinsicHeight(double.infinity));

  // Segment widths for a row at most [maxWidth] wide (and at least
  // [minWidth]).
  List<double> _widths(double minWidth, double maxWidth) {
    final segments = _segments;
    final n = segments.length;
    if (n == 0) return const [];
    final own = [
      for (final s in segments) s.getMaxIntrinsicWidth(double.infinity),
    ];
    final gaps = _gaps(n);
    final widest = own.reduce((a, b) => a > b ? a : b);
    final equal = (widest * n + gaps).clamp(minWidth, maxWidth);
    if (widest * n + gaps <= maxWidth) {
      return List.filled(n, (equal - gaps) / n);
    }
    final total = own.fold(0.0, (a, b) => a + b);
    final room = maxWidth - gaps;
    if (total <= room) {
      final extra = (room - total) / n;
      return [for (final w in own) w + extra];
    }
    final scale = total == 0 ? 0.0 : (room > 0 ? room : 0.0) / total;
    return [for (final w in own) w * scale];
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final widths = _widths(constraints.minWidth, constraints.maxWidth);
    final segments = _segments;
    var height = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final c = BoxConstraints.tightFor(width: widths[i]);
      final h = dry
          ? segments[i].getDryLayout(c).height
          : (segments[i]..layout(c, parentUsesSize: true)).size.height;
      if (h > height) height = h;
    }
    height = constraints.constrainHeight(height);
    final width = constraints.constrainWidth(
      widths.fold(0.0, (a, b) => a + b) + _gaps(segments.length),
    );
    if (dry) return Size(width, height);
    final slots = <(double, double)>[];
    var start = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.size.height != height) {
        s.layout(
          BoxConstraints.tightFor(width: widths[i], height: height),
          parentUsesSize: true,
        );
      }
      slots.add((start, widths[i]));
      (s.parentData! as _SegmentRowParentData).offset = Offset(
        _x(start, widths[i], width),
        0,
      );
      start += widths[i] + _gap;
    }
    _slots = slots;
    return Size(width, height);
  }

  // The left edge of a slot at [start] from the start edge.
  double _x(double start, double width, double total) =>
      _textDirection == TextDirection.rtl ? total - start - width : start;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
    final p = _position;
    final thumbData = _thumb.parentData! as _SegmentRowParentData;
    if (p == null || _slots.isEmpty) {
      _thumb.layout(BoxConstraints.tight(Size.zero));
      thumbData.offset = Offset.zero;
      return;
    }
    // The spring overshoots; at the first and last segment that would
    // push the thumb and its shadow past the track, so it is held inside.
    final v = p.clamp(0, _slots.length - 1).toDouble();
    final a = _slots[v.floor()];
    final b = _slots[v.ceil()];
    final f = v - v.floor();
    final start = a.$1 + (b.$1 - a.$1) * f;
    final width = a.$2 + (b.$2 - a.$2) * f;
    _thumb.layout(BoxConstraints.tightFor(width: width, height: size.height));
    thumbData.offset = Offset(_x(start, width, size.width), 0);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final s in _segments.reversed) {
      final offset = (s.parentData! as _SegmentRowParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            s.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
