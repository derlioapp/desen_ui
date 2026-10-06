import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_visibility.dart';
import '../../behavior/focus_visibility_state.dart' show notePressed;
import '../../behavior/haptic_feedback.dart';
import '../../behavior/pressable.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/theme.dart';
import 'link.dart';
import 'link_style.dart';

/// A link inside running text: one of a [DsParagraph]'s spans.
///
/// ```dart
/// DsParagraph(
///   children: [
///     const TextSpan(text: 'Your trial ends in 3 days. '),
///     DsLinkSpan(label: 'Choose a plan', onPressed: openPlans),
///     const TextSpan(text: ' to keep your projects.'),
///   ],
/// )
/// ```
///
/// The label is part of the paragraph's text, so a long one wraps with the
/// sentence, as an `<a>` in a `<p>` does on the web: the first words end
/// one line and the rest start the next. A [DsLink] in a `WidgetSpan`
/// wraps inside its own box instead.
///
/// It looks and behaves like a [DsLink]: the theme's link color, an
/// underline on every line of the label, a pointing hand and a thicker
/// underline on hover, Tab to reach it and Enter to activate it, and a
/// focus ring around each line of the label for keyboard users. It takes
/// the same [DsLinkStyle] layers, from [DsLink.defaultStyle] through
/// [DsLinkTheme] to [linkStyle], except that the line height stays the
/// paragraph's.
///
/// The span only describes the link: the [DsParagraph] around it handles
/// the pointer, keyboard focus, painting and semantics. In a `Text.rich`
/// or a `RichText` it would be plain text, so debug builds report it there.
///
/// The span has no external arrow: for a link that leaves the app, use a
/// [DsLink] with `external: true`.
class DsLinkSpan extends TextSpan {
  /// Creates a link span. [label] must not be empty.
  const DsLinkSpan({
    required String label,
    required this.onPressed,
    this.url,
    String? semanticLabel,
    this.linkStyle,
    this.focusNode,
  }) : assert(label != ''),
       super(text: label, semanticsLabel: semanticLabel);

  /// The link text.
  String get label => text!;

  /// Called when activated: a tap, a click, Enter or a screen reader's
  /// activation. Space does not activate a link, as in browsers. Null
  /// disables the link.
  final VoidCallback? onPressed;

  /// The address, for link semantics: on the web the link then carries an
  /// `href`. Opening it is up to [onPressed].
  final Uri? url;

  /// Overrides the label screen readers announce (default: [label]).
  String? get semanticLabel => semanticsLabel;

  /// Style laid over the theme and defaults.
  final DsLinkStyle? linkStyle;

  /// Focus node; the paragraph creates one when null.
  final FocusNode? focusNode;

  @override
  void build(
    ui.ParagraphBuilder builder, {
    TextScaler textScaler = TextScaler.noScaling,
    List<PlaceholderDimensions>? dimensions,
  }) {
    assert(() {
      throw FlutterError.fromParts([
        ErrorSummary('A DsLinkSpan was laid out outside a DsParagraph.'),
        ErrorDescription(
          'A DsLinkSpan only describes a link. The DsParagraph around it '
          'makes it one: pointer, keyboard focus, painting and semantics. '
          'In other text it would be plain, unreachable text.',
        ),
        ErrorHint(
          'Put the spans in DsParagraph(children: [...]) instead of '
          'Text.rich or RichText.',
        ),
      ]);
    }());
    super.build(builder, textScaler: textScaler, dimensions: dimensions);
  }

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is DsLinkSpan &&
      other.onPressed == onPressed &&
      other.url == url &&
      other.linkStyle == linkStyle &&
      other.focusNode == focusNode;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, onPressed, url, linkStyle, focusNode);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
    );
    properties.add(DiagnosticsProperty('url', url, defaultValue: null));
  }
}

/// Running text that holds [DsLinkSpan]s, like a `<p>` with `<a>`s in it.
///
/// ```dart
/// DsParagraph(
///   children: [
///     const TextSpan(text: 'Read the '),
///     DsLinkSpan(label: 'user guide', onPressed: openGuide),
///     const TextSpan(text: ' before you start.'),
///   ],
/// )
/// ```
///
/// Use it in place of `Text.rich` when the text has links. Each link's
/// label flows with the text and wraps with it. The paragraph gives every
/// link what a [DsLink] has:
/// - Pointer: a pointing hand over the label, the hover and pressed
///   styles, a tap that activates it.
/// - Keyboard: Tab reaches each enabled link in text order, Enter
///   activates it, Space does nothing (as in browsers). Keyboard focus
///   shows as a ring around each line of the label; a click never shows
///   it.
/// - Screen readers: the text around the links is read as text, each link
///   as a link with its label (and its [DsLinkSpan.url]), enabled or not,
///   focusable, and activated by the screen reader's gesture.
///
/// [children] may mix `TextSpan`s (nested, styled) and [DsLinkSpan]s at
/// any depth. They must not hold a `WidgetSpan`: the paragraph builds the
/// semantics of its text itself, and a widget inside it would be skipped.
///
/// The paragraph takes the surrounding `DefaultTextStyle`, [style] laid
/// over it, the ambient text direction and the `MediaQuery` text scale.
/// It always shows all its text: no line limit, no ellipsis.
class DsParagraph extends StatefulWidget {
  /// Creates a paragraph.
  const DsParagraph({
    super.key,
    required this.children,
    this.style,
    this.textAlign,
  });

  /// The text: `TextSpan`s and [DsLinkSpan]s.
  final List<InlineSpan> children;

  /// Laid over the surrounding `DefaultTextStyle`.
  final TextStyle? style;

  /// How lines line up; defaults to the `DefaultTextStyle`'s, then to
  /// [TextAlign.start].
  final TextAlign? textAlign;

  @override
  State<DsParagraph> createState() => _DsParagraphState();
}

/// The paragraph's state for one link: its recognizer, focus node and
/// pointer states, kept by position across rebuilds.
class _Link {
  _Link(this._owner) {
    recognizer
      ..onTapDown = ((_) => _owner._setPressed(this, true))
      ..onTapUp = ((_) => _owner._setPressed(this, false))
      ..onTapCancel = (() => _owner._setPressed(this, false))
      ..onTap = (() => _owner._activate(this, pointer: true));
  }

  final _DsParagraphState _owner;
  late final recognizer = TapGestureRecognizer(debugOwner: this);

  // Methods, not closures: a method torn off the same object is equal
  // each time, so the span stays equal across rebuilds and the mouse
  // tracker does not see it leave and enter again.
  void onEnter(PointerEnterEvent _) => _owner._setHovered(this, true);
  void onExit(PointerExitEvent _) => _owner._setHovered(this, false);
  void onSemanticTap() => _owner._activate(this);
  void onSemanticFocus() => node.requestFocus();
  KeyEventResult onKey(FocusNode _, KeyEvent event) =>
      _owner._onKey(this, event);

  DsLinkSpan? _span;
  DsLinkSpan get span => _span!;

  FocusNode? _own;
  FocusNode? _listened;
  bool hovered = false;
  bool pressed = false;

  FocusNode get node =>
      span.focusNode ?? (_own ??= FocusNode(debugLabel: 'DsLinkSpan'));

  bool get enabled => span.onPressed != null;

  void update(DsLinkSpan next) {
    _span = next;
    final n = node;
    if (n != _listened) {
      _listened?.removeListener(_owner._onFocusChanged);
      if (next.focusNode != null) {
        _own?.dispose();
        _own = null;
      }
      n.addListener(_owner._onFocusChanged);
      _listened = n;
    }
    if (!enabled) {
      // A link disabled mid-interaction keeps no stale states.
      hovered = false;
      pressed = false;
    }
  }

  void dispose() {
    _listened?.removeListener(_owner._onFocusChanged);
    _own?.dispose();
    recognizer.dispose();
  }
}

class _DsParagraphState extends State<DsParagraph> {
  final _links = <_Link>[];

  @override
  void initState() {
    super.initState();
    _syncLinks();
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
    DsFocusVisibility.keyboard.addListener(_onModalityChanged);
  }

  @override
  void didUpdateWidget(DsParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLinks();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    DsFocusVisibility.keyboard.removeListener(_onModalityChanged);
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  /// Matches the [DsLinkSpan]s in the children, in text order, with the
  /// link states, creating and disposing states as links come and go.
  void _syncLinks() {
    final spans = <DsLinkSpan>[];
    for (final child in widget.children) {
      child.visitChildren((span) {
        if (span is DsLinkSpan) spans.add(span);
        return true;
      });
    }
    while (_links.length > spans.length) {
      _links.removeLast().dispose();
    }
    while (_links.length < spans.length) {
      _links.add(_Link(this));
    }
    for (var i = 0; i < spans.length; i++) {
      _links[i].update(spans[i]);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onHighlightModeChanged(FocusHighlightMode _) => _onModalityChanged();

  /// Keyboard or pointer input changes only how a focused link looks.
  void _onModalityChanged() {
    if (_links.any((l) => l.node.hasFocus)) _onFocusChanged();
  }

  // A span stays a mouse annotation after the paragraph is gone (the
  // pointer leaving it then still reports an exit), hence the mounted
  // checks.
  void _setHovered(_Link link, bool on) {
    on = on && link.enabled;
    if (!mounted || link.hovered == on) return;
    setState(() => link.hovered = on);
  }

  void _setPressed(_Link link, bool on) {
    on = on && link.enabled;
    if (!mounted || link.pressed == on) return;
    setState(() => link.pressed = on);
  }

  /// Runs the link's `onPressed`; a [pointer] tap also plays the haptic.
  void _activate(_Link link, {bool pointer = false}) {
    final onPressed = link.span.onPressed;
    if (onPressed == null) return;
    if (pointer) DsHapticFeedback.play(context, DsHapticEvent.command);
    // A click does not focus, so a modal this opens learns its opener here.
    notePressed(link.node);
    onPressed();
  }

  /// Enter activates on key down, a held Enter does not repeat, and Space
  /// is stopped here, so neither the link nor an ancestor shortcut acts on
  /// it: browser links take Enter only.
  KeyEventResult _onKey(_Link link, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      return KeyEventResult.skipRemainingHandlers;
    }
    if (!link.enabled ||
        (key != LogicalKeyboardKey.enter &&
            key != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }
    switch (event) {
      case KeyDownEvent():
        _activate(link);
        return KeyEventResult.handled;
      case KeyRepeatEvent():
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Set<WidgetState> _states(_Link link) => {
    if (!link.enabled) WidgetState.disabled,
    if (link.hovered) WidgetState.hovered,
    if (link.pressed) WidgetState.pressed,
    if (link.enabled &&
        link.node.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
        DsFocusVisibility.keyboard.value)
      WidgetState.focused,
  };

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final direction = Directionality.of(context);
    final defaults = DsLink.defaultStyle(t);
    final themed = DsLinkTheme.of(context).style;
    final base = DefaultTextStyle.of(context);
    var style = base.style.merge(widget.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }

    final paints = <_LinkPaint>[];
    var offset = 0;
    var index = 0;

    /// [span] with its links turned into styled, interactive text spans;
    /// records each link's range of the plain text on the way.
    InlineSpan convert(InlineSpan span) {
      if (span is DsLinkSpan) {
        final link = _links[index++];
        final states = _states(link);
        final s = DsLinkStyle.resolveLayers([
          defaults,
          themed,
          span.linkStyle,
        ], states);
        final color = s.foreground ?? t.colors.link;
        final start = offset;
        offset += span.label.length;
        paints.add(
          _LinkPaint(
            link: link,
            start: start,
            end: offset,
            color: color,
            underlineWidth: s.underlineWidth!,
            focusVisible: states.contains(WidgetState.focused),
            borderRadius: (s.borderRadius ?? BorderRadius.zero).resolve(
              direction,
            ),
            focusShadows: s.focusShadows ?? const [],
            enabled: link.enabled,
            focused: link.node.hasPrimaryFocus,
            url: span.url,
          ),
        );
        return TextSpan(
          text: span.label,
          style: _withoutHeight(s.textStyle).copyWith(color: color),
          recognizer: link.enabled ? link.recognizer : null,
          mouseCursor: s.cursor ?? DsPressable.defaultCursor.resolve(states),
          onEnter: link.onEnter,
          onExit: link.onExit,
          semanticsLabel: span.semanticsLabel,
        );
      }
      if (span is TextSpan) {
        offset += span.text?.length ?? 0;
        final children = span.children;
        if (children == null) return span;
        final converted = [for (final c in children) convert(c)];
        if (listEquals(converted, children)) return span;
        return TextSpan(
          text: span.text,
          children: converted,
          style: span.style,
          recognizer: span.recognizer,
          mouseCursor: span.mouseCursor,
          onEnter: span.onEnter,
          onExit: span.onExit,
          semanticsLabel: span.semanticsLabel,
          semanticsIdentifier: span.semanticsIdentifier,
          locale: span.locale,
          spellOut: span.spellOut,
        );
      }
      assert(
        span is! PlaceholderSpan,
        'A DsParagraph does not take a WidgetSpan: it builds the semantics '
        'of its text itself, and the widget would be skipped.',
      );
      offset += span.toPlainText().length;
      return span;
    }

    final text = TextSpan(
      style: style,
      children: [for (final c in widget.children) convert(c)],
    );
    Widget result = _LinkParagraph(
      links: paints,
      children: [
        RichText(
          text: text,
          textAlign: widget.textAlign ?? base.textAlign ?? TextAlign.start,
          textDirection: direction,
          textScaler: MediaQuery.textScalerOf(context),
          textWidthBasis: base.textWidthBasis,
          textHeightBehavior:
              base.textHeightBehavior ??
              DefaultTextHeightBehavior.maybeOf(context),
        ),
        // One focus target per link, laid over the first line of its
        // label: Tab order, scrolling into view and focus restoration
        // use it like any focusable widget's.
        for (final (i, link) in _links.indexed)
          FocusTraversalOrder(
            order: NumericFocusOrder(i.toDouble()),
            child: Focus(
              focusNode: link.node,
              canRequestFocus: link.enabled,
              skipTraversal: !link.enabled,
              // The paragraph announces focus on the link's text instead.
              includeSemantics: false,
              onKeyEvent: link.onKey,
              child: const SizedBox(),
            ),
          ),
      ],
    );
    if (_links.isNotEmpty) {
      // Links in text order, which is reading order in either direction.
      result = FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: result,
      );
    }
    return result;
  }
}

/// [style] without a line height: a link takes the paragraph's, so a line
/// that holds one is as tall as the others.
TextStyle _withoutHeight(TextStyle? style) {
  if (style == null) return const TextStyle();
  if (style.height == null) return style;
  return TextStyle(
    inherit: style.inherit,
    color: style.color,
    backgroundColor: style.backgroundColor,
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    fontStyle: style.fontStyle,
    letterSpacing: style.letterSpacing,
    wordSpacing: style.wordSpacing,
    textBaseline: style.textBaseline,
    leadingDistribution: style.leadingDistribution,
    locale: style.locale,
    foreground: style.foreground,
    background: style.background,
    shadows: style.shadows,
    fontFeatures: style.fontFeatures,
    fontVariations: style.fontVariations,
    decoration: style.decoration,
    decorationColor: style.decorationColor,
    decorationStyle: style.decorationStyle,
    decorationThickness: style.decorationThickness,
    debugLabel: style.debugLabel,
    fontFamily: style.fontFamily,
    fontFamilyFallback: style.fontFamilyFallback,
    overflow: style.overflow,
  );
}

/// What the render object needs to paint one link and describe it to
/// screen readers.
@immutable
class _LinkPaint {
  const _LinkPaint({
    required this.link,
    required this.start,
    required this.end,
    required this.color,
    required this.underlineWidth,
    required this.focusVisible,
    required this.borderRadius,
    required this.focusShadows,
    required this.enabled,
    required this.focused,
    required this.url,
  });

  final _Link link;

  /// The label's range in the paragraph's plain text.
  final int start, end;

  final Color color;
  final double underlineWidth;

  /// Keyboard focus to show: draws the ring.
  final bool focusVisible;
  final BorderRadius borderRadius;
  final List<DsShadow> focusShadows;

  final bool enabled;

  /// Holds input focus, shown or not: for semantics.
  final bool focused;
  final Uri? url;

  @override
  bool operator ==(Object other) =>
      other is _LinkPaint &&
      other.link == link &&
      other.start == start &&
      other.end == end &&
      other.color == color &&
      other.underlineWidth == underlineWidth &&
      other.focusVisible == focusVisible &&
      other.borderRadius == borderRadius &&
      listEquals(other.focusShadows, focusShadows) &&
      other.enabled == enabled &&
      other.focused == focused &&
      other.url == url;

  @override
  int get hashCode => Object.hash(
    link,
    start,
    end,
    color,
    underlineWidth,
    focusVisible,
    borderRadius,
    Object.hashAll(focusShadows),
    enabled,
    focused,
    url,
  );
}

/// The paragraph (first child) and one focus target per link (the other
/// children, laid over the first line of each label).
class _LinkParagraph extends MultiChildRenderObjectWidget {
  const _LinkParagraph({required this.links, required super.children});

  final List<_LinkPaint> links;

  @override
  _RenderLinkParagraph createRenderObject(BuildContext context) =>
      _RenderLinkParagraph(links, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLinkParagraph renderObject,
  ) {
    renderObject
      ..links = links
      ..textDirection = Directionality.of(context);
  }
}

class _LinkParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderLinkParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _LinkParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _LinkParentData> {
  _RenderLinkParagraph(this._links, this._textDirection);

  List<_LinkPaint> _links;
  set links(List<_LinkPaint> value) {
    if (listEquals(value, _links)) return;
    final moved =
        value.length != _links.length ||
        [
          for (var i = 0; i < value.length; i++)
            value[i].start != _links[i].start || value[i].end != _links[i].end,
        ].any((m) => m);
    _links = value;
    if (moved) markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  RenderParagraph get _text => firstChild! as RenderParagraph;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LinkParentData) {
      child.parentData = _LinkParentData();
    }
  }

  /// Per link, one rectangle per line its label sits on, in paragraph
  /// coordinates; set by [performLayout].
  List<List<Rect>> _lines = const [];

  /// One rectangle per line [link]'s label sits on: the glyph boxes of
  /// each line joined. A space where the label breaks onto the next line
  /// is left out, so neither the underline nor the ring runs past the
  /// last word, as in browsers.
  List<Rect> _measure(_LinkPaint link) {
    final label = _text.text.toPlainText().substring(link.start, link.end);
    final tokens = _tokens.allMatches(label).toList();
    List<Rect> boxes(Match m) => [
      for (final box in _text.getBoxesForSelection(
        TextSelection(
          baseOffset: link.start + m.start,
          extentOffset: link.start + m.end,
        ),
        boxHeightStyle: ui.BoxHeightStyle.tight,
      ))
        box.toRect(),
    ];
    bool sameLine(Rect a, Rect b) => a.top < b.bottom && a.bottom > b.top;

    final lines = <Rect>[];
    for (var i = 0; i < tokens.length; i++) {
      final rects = boxes(tokens[i]);
      if (rects.isEmpty) continue;
      if (tokens[i][0]!.trim().isEmpty && i + 1 < tokens.length) {
        final next = boxes(tokens[i + 1]);
        if (next.isNotEmpty && !sameLine(rects.last, next.first)) continue;
      }
      for (final rect in rects) {
        if (lines.isNotEmpty && sameLine(lines.last, rect)) {
          lines.last = lines.last.expandToInclude(rect);
        } else {
          lines.add(rect);
        }
      }
    }
    return lines;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _text.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _text.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _text.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _text.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _text.getDryLayout(constraints);

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _text.getDryBaseline(constraints, baseline);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _text.getDistanceToActualBaseline(baseline);

  @override
  void performLayout() {
    final text = _text..layout(constraints, parentUsesSize: true);
    size = constraints.constrain(text.size);
    _lines = [for (final link in _links) _measure(link)];
    var child = childAfter(text);
    for (final lines in _lines) {
      final rect = lines.isEmpty ? Rect.zero : lines.first;
      child!.layout(BoxConstraints.tight(rect.size));
      (child.parentData! as _LinkParentData).offset = rect.topLeft;
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _text.hitTest(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    // The ring goes under the text, as a link's box decoration does.
    for (final (i, link) in _links.indexed) {
      if (!link.focusVisible || link.focusShadows.isEmpty) continue;
      final painter = DsBoxDecoration(
        borderRadius: link.borderRadius,
        shadows: link.focusShadows,
      ).createBoxPainter();
      for (final line in _lines[i]) {
        painter.paint(
          canvas,
          offset + line.topLeft,
          ImageConfiguration(size: line.size, textDirection: _textDirection),
        );
      }
      painter.dispose();
    }
    context.paintChild(_text, offset);
    // The underline sits at the bottom of the glyph box (the font's
    // descent), below descenders such as "g", as a DsLink's does.
    for (final (i, link) in _links.indexed) {
      if (link.underlineWidth <= 0) continue;
      final paint = Paint()..color = link.color;
      for (final line in _lines[i]) {
        canvas.drawRect(
          Rect.fromLTRB(
            line.left,
            line.bottom - link.underlineWidth,
            line.right,
            line.bottom,
          ).shift(offset),
          paint,
        );
      }
    }
  }

  // Semantics. RenderParagraph gives a span with a tap recognizer a link
  // node with a tap action, but no focus state, no enabled state and no
  // address, and a disabled link (no recognizer) none at all. With links
  // inside, this render object describes the text itself, in the same
  // shape: one node per run of text and one per link, in text order.

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    // The focus targets add nothing; the text is described here when it
    // holds links.
    if (_links.isEmpty) visitor(_text);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_links.isEmpty) return;
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true;
  }

  /// The child nodes from the last assembly, reused in order so their ids
  /// stay stable.
  List<SemanticsNode> _nodes = const [];

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    if (_links.isEmpty) {
      super.assembleSemanticsNode(node, config, children);
      return;
    }
    final runs = <(InlineSpanSemanticsInformation, int, _LinkPaint?)>[];
    var offset = 0;
    var linkIndex = 0;
    var pending = <InlineSpanSemanticsInformation>[];
    var pendingStart = 0;
    void flush() {
      var start = pendingStart;
      for (final info in combineSemanticsInfo(pending)) {
        runs.add((info, start, null));
        start += info.text.length;
      }
      pending = [];
    }

    for (final info in _text.text.getSemanticsInformation()) {
      final link = linkIndex < _links.length ? _links[linkIndex] : null;
      if (link != null &&
          link.start == offset &&
          link.end - link.start == info.text.length) {
        flush();
        runs.add((info, offset, link));
        linkIndex++;
      } else {
        if (pending.isEmpty) pendingStart = offset;
        pending.add(info);
      }
      offset += info.text.length;
    }
    flush();

    final reuse = _nodes.iterator;
    final nodes = <SemanticsNode>[];
    var ordinal = 0.0;
    for (final (info, start, link) in runs) {
      final boxes = _text.getBoxesForSelection(
        TextSelection(
          baseOffset: start,
          extentOffset: start + info.text.length,
        ),
      );
      if (boxes.isEmpty) continue;
      var rect = boxes.first.toRect();
      for (final box in boxes.skip(1)) {
        rect = rect.expandToInclude(box.toRect());
      }
      // As RenderParagraph does: finite, rounded, padded so neighbors'
      // rectangles do not overlap the text.
      rect = Rect.fromLTWH(
        math.max(0, rect.left),
        math.max(0, rect.top),
        math.min(rect.width, constraints.maxWidth),
        math.min(rect.height, constraints.maxHeight),
      );
      rect = Rect.fromLTRB(
        rect.left.floorToDouble() - _semanticsPadding,
        rect.top.floorToDouble() - _semanticsPadding,
        rect.right.ceilToDouble() + _semanticsPadding,
        rect.bottom.ceilToDouble() + _semanticsPadding,
      );
      final c = SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(ordinal++)
        ..textDirection = boxes.first.direction
        ..identifier = info.semanticsIdentifier ?? ''
        ..attributedLabel = AttributedString(
          info.semanticsLabel ?? info.text,
          attributes: info.stringAttributes,
        );
      if (link != null) {
        c
          ..isLink = true
          ..linkUrl = link.url
          ..isEnabled = link.enabled
          ..isFocused = link.enabled ? link.focused : null;
        if (link.enabled) {
          c.onTap = link.link.onSemanticTap;
          // As the Focus widget does: iOS does not send the focus action.
          if (defaultTargetPlatform != TargetPlatform.iOS) {
            c.onFocus = link.link.onSemanticFocus;
          }
        }
      } else if (info.recognizer case TapGestureRecognizer(
        onTap: final VoidCallback onTap,
      )) {
        // A tappable span of the caller's own, as RenderParagraph treats it.
        c
          ..isLink = true
          ..onTap = onTap;
      }
      if (node.parentPaintClipRect case final clip?) {
        c.isHidden = clip.intersect(rect).isEmpty && !rect.isEmpty;
      }
      final child = reuse.moveNext() ? reuse.current : _newNode();
      child
        ..updateWith(config: c)
        ..rect = rect;
      nodes.add(child);
    }
    _nodes = nodes;
    node.updateWith(config: config, childrenInInversePaintOrder: nodes);
  }

  SemanticsNode _newNode() {
    late final SemanticsNode node;
    return node = SemanticsNode(
      showOnScreen: () => showOnScreen(rect: node.rect),
    );
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _nodes = const [];
  }
}

/// Runs of white space and runs of anything else.
final _tokens = RegExp(r'\s+|\S+');

/// Space around each text node's rectangle, as RenderParagraph leaves.
const double _semanticsPadding = 4;
