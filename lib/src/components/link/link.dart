import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'link_style.dart';

/// A text link: link color, medium weight, a 1px underline.
///
/// ```dart
/// DsLink(label: 'the user guide', onPressed: openGuide)
/// DsLink(label: 'Contact support', external: true, url: supportUri, onPressed: …)
/// ```
///
/// For a link inside running text, use a `DsLinkSpan` in a `DsParagraph`:
/// its label flows and wraps with the sentence.
///
/// A [DsLink] can also sit in running text, in a `WidgetSpan` with
/// `PlaceholderAlignment.baseline` and [inline] set, so it keeps the
/// paragraph's line height; that is the way to show the external arrow
/// there. A label longer than the width wraps inside the link, underlined
/// line by line, with the external arrow after the last word; it does not
/// flow with the surrounding paragraph.
///
/// Give [url] when the link has a real address: on the web, screen readers
/// and the browser then treat it as a genuine `<a href>`.
class DsLink extends StatelessWidget {
  /// Creates a link.
  const DsLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.url,
    this.external = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
    this.inline = false,
  });

  /// The link text.
  final String label;

  /// Called when activated: a tap, a click or Enter. Space does not
  /// activate a link, as in browsers.
  final VoidCallback? onPressed;

  /// The address, for link semantics.
  final Uri? url;

  /// Leaves the app: adds an up-right arrow.
  final bool external;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Overrides the label screen readers announce (default: [label]).
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsLinkStyle? style;

  /// Sits inside running text (a `WidgetSpan`): the hit area is the text
  /// itself, not grown to the minimum tap target, so the line keeps its
  /// height. WCAG 2.5.8 exempts targets in a sentence.
  final bool inline;

  /// Desen's default link style under [theme].
  static DsLinkStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsLinkStyle(
      foreground: k.link,
      textStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.2),
      underlineWidth: 1,
      iconSize: 14,
      iconGap: 2,
      // The focus ring hugs a line of text, about 20 tall: rounded as a
      // control of that height.
      borderRadius: BorderRadius.circular(theme.radii.control(20)),
      focusShadows: theme.focusShadows,
      // Hover (and quiet keyboard focus) thickens the underline.
      hovered: const DsLinkStyle(underlineWidth: 2),
      disabled: DsLinkStyle(foreground: k.onDisabled, underlineWidth: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [defaultStyle(t), DsLinkTheme.of(context).style, style];
    return _EnterOnly(
      focusNode: focusNode,
      builder: (node) => _pressable(t, layers, node),
    );
  }

  Widget _pressable(
    DsThemeData t,
    List<DsLinkStyle?> layers,
    FocusNode focusNode,
  ) {
    return DsPressable(
      onPressed: onPressed,
      isButton: false,
      isLink: true,
      minTapTarget: inline ? 0 : null,
      linkUrl: url,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsLinkStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, states, _) {
        final s = DsLinkStyle.resolveLayers(layers, states);
        final color = s.foreground ?? t.colors.link;
        final textStyle = DefaultTextStyle.of(context).style
            .merge(s.textStyle)
            .copyWith(color: color);
        return DecoratedBox(
          decoration: DsBoxDecoration(
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: [
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: _Underline(
            color: color,
            width: s.underlineWidth!,
            length: label.length,
            child: Text.rich(
              TextSpan(
                text: label,
                style: textStyle,
                children: [
                  if (external)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: s.iconGap ?? 0,
                        ),
                        child: DsIcon(
                          DsIcons.arrowUpRight,
                          size: s.iconSize,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps Space from activating the link: browser links take Enter only,
/// and Space belongs to the page. It hooks the link's focus node (the
/// caller's, or one of its own), which sees keys before the pressable, and
/// stops Space there so neither the pressable nor an ancestor shortcut
/// (`ActivateIntent`) acts on it. A handler the caller set on its node
/// still runs first.
class _EnterOnly extends StatefulWidget {
  const _EnterOnly({required this.focusNode, required this.builder});

  final FocusNode? focusNode;
  final Widget Function(FocusNode node) builder;

  @override
  State<_EnterOnly> createState() => _EnterOnlyState();
}

class _EnterOnlyState extends State<_EnterOnly> {
  FocusNode? _own;
  FocusNode? _hooked;
  FocusOnKeyEventCallback? _previous;

  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'DsLink'));

  @override
  void initState() {
    super.initState();
    _hook();
  }

  @override
  void didUpdateWidget(_EnterOnly oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unhook();
      if (widget.focusNode != null) {
        _own?.dispose();
        _own = null;
      }
      _hook();
    }
  }

  @override
  void dispose() {
    _unhook();
    _own?.dispose();
    super.dispose();
  }

  void _hook() {
    final node = _node;
    _hooked = node;
    _previous = node.onKeyEvent;
    node.onKeyEvent = _onKey;
  }

  void _unhook() {
    final node = _hooked;
    if (node != null && node.onKeyEvent == _onKey) {
      node.onKeyEvent = _previous;
    }
    _hooked = null;
    _previous = null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final previous = _previous?.call(node, event) ?? KeyEventResult.ignored;
    if (previous != KeyEventResult.ignored) return previous;
    return event.logicalKey == LogicalKeyboardKey.space
        ? KeyEventResult.skipRemainingHandlers
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => widget.builder(_node);
}

/// Draws a line along the bottom of every line of the first [length]
/// characters of its [Text] child: the bottom of the line box
/// (baseline plus descent), close to CSS `text-underline-offset: 3px`, so
/// it clears descenders such as "ğ" and "g", unlike a text decoration. It
/// follows the text when it wraps; the external arrow, a
/// placeholder after the text, is not underlined.
class _Underline extends SingleChildRenderObjectWidget {
  const _Underline({
    required this.color,
    required this.width,
    required this.length,
    required Text super.child,
  });

  final Color color;
  final double width;
  final int length;

  @override
  _RenderUnderline createRenderObject(BuildContext context) =>
      _RenderUnderline(color, width, length);

  @override
  void updateRenderObject(BuildContext context, _RenderUnderline render) {
    render
      ..color = color
      ..width = width
      ..length = length;
  }
}

class _RenderUnderline extends RenderProxyBox {
  _RenderUnderline(this._color, this._width, this._length);

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  double _width;
  set width(double v) {
    if (v == _width) return;
    _width = v;
    markNeedsPaint();
  }

  int _length;
  set length(int v) {
    if (v == _length) return;
    _length = v;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    // The paragraph, under any proxies Text adds (e.g. a selection area's
    // mouse region); they all share its offset.
    RenderObject? text = child;
    while (text is RenderProxyBox) {
      text = text.child;
    }
    if (text is! RenderParagraph || _length == 0) return;
    final paint = Paint()..color = _color;
    for (final box in text.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: _length),
      boxHeightStyle: ui.BoxHeightStyle.max,
    )) {
      context.canvas.drawRect(
        Rect.fromLTRB(
          box.left,
          box.bottom - _width,
          box.right,
          box.bottom,
        ).shift(offset),
        paint,
      );
    }
  }
}
