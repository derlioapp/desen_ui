import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'scrollbar_style.dart';

/// A thin, fully rounded scrollbar thumb in theme colors, with no track.
///
/// The thumb shows while [child] scrolls and fades away after, unless
/// [alwaysVisible]. It gets stronger under the pointer and stronger still
/// while dragged. It can be dragged, and a click on the bar's lane pages
/// toward it, unless [interactive] is false.
///
/// `DsScrollBehavior` (which `DsApp` installs) puts one on every
/// scrollable on desktop, so most apps never build one. Build one to
/// change a single scrollable, or put a [DsScrollbarTheme] around a part
/// of the app to change every scrollbar in it (including those the scroll
/// behavior adds).
///
/// ```dart
/// DsScrollbar(
///   controller: controller,
///   alwaysVisible: true,
///   child: ListView(controller: controller, children: rows),
/// )
/// ```
class DsScrollbar extends StatelessWidget {
  /// Creates a scrollbar for the scrollable [child].
  const DsScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.alwaysVisible,
    this.interactive = true,
    this.notificationPredicate,
    this.scrollbarOrientation,
    this.style,
  });

  /// The scrollable the bar reports on (a `ListView`, a
  /// `SingleChildScrollView`, …), or a widget that contains one.
  final Widget child;

  /// The scrollable's controller. Needed when the thumb is
  /// [alwaysVisible] and there is no primary scroll controller, since the
  /// thumb shows before any scroll.
  final ScrollController? controller;

  /// Whether the thumb stays visible while the content is at rest. Null
  /// takes [DsScrollbarThemeData.alwaysVisible], then false: the thumb
  /// shows while scrolling and fades away after.
  final bool? alwaysVisible;

  /// Whether the thumb can be dragged and the lane clicked.
  final bool interactive;

  /// Which scroll notifications the bar follows; by default those of the
  /// nearest scrollable (depth 0).
  final ScrollNotificationPredicate? notificationPredicate;

  /// Which edge the bar runs along; by default the end edge of a vertical
  /// scrollable (right in left-to-right text) and the bottom of a
  /// horizontal one.
  final ScrollbarOrientation? scrollbarOrientation;

  /// Style laid over the theme and defaults.
  final DsScrollbarStyle? style;

  /// Desen's default scrollbar style under [theme].
  static DsScrollbarStyle defaultStyle(DsThemeData theme) {
    // Translucent subtle ink: it reads on every layer and lets the content
    // show through as it slides under.
    final ink = theme.colors.textSubtle;
    return DsScrollbarStyle(
      thumbColor: ink.withValues(alpha: .35),
      thickness: 6,
      crossAxisMargin: 2,
      mainAxisMargin: 2,
      minThumbLength: DsSpace.s24,
      hovered: DsScrollbarStyle(thumbColor: ink.withValues(alpha: .55)),
      pressed: DsScrollbarStyle(thumbColor: ink.withValues(alpha: .7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final theme = DsScrollbarTheme.of(context);
    return _DsRawScrollbar(
      controller: controller,
      thumbVisibility: alwaysVisible ?? theme.alwaysVisible ?? false,
      interactive: interactive,
      notificationPredicate:
          notificationPredicate ?? defaultScrollNotificationPredicate,
      scrollbarOrientation: scrollbarOrientation,
      fadeDuration: t.motion.toneDuration,
      layers: [defaultStyle(t), theme.style, style],
      child: child,
    );
  }
}

/// A [RawScrollbar] whose thumb follows [layers], for its hover and drag
/// states too. The painter takes every value from them on each build.
class _DsRawScrollbar extends RawScrollbar {
  const _DsRawScrollbar({
    required super.child,
    required this.layers,
    super.controller,
    super.thumbVisibility,
    super.interactive,
    super.notificationPredicate,
    super.scrollbarOrientation,
    super.fadeDuration,
  });

  final List<DsScrollbarStyle?> layers;

  @override
  RawScrollbarState<_DsRawScrollbar> createState() => _DsRawScrollbarState();
}

class _DsRawScrollbarState extends RawScrollbarState<_DsRawScrollbar> {
  bool _hovered = false;
  bool _dragging = false;

  Set<WidgetState> get _states => {
    if (_hovered) WidgetState.hovered,
    if (_dragging) WidgetState.pressed,
  };

  @override
  void updateScrollbarPainter() {
    final s = DsScrollbarStyle.resolveLayers(widget.layers, _states);
    final thickness = s.thickness ?? 0;
    final direction = Directionality.of(context);
    scrollbarPainter
      ..color = s.thumbColor ?? const Color(0x00000000)
      ..textDirection = direction
      ..thickness = thickness
      ..radius = Radius.circular(thickness / 2)
      ..padding = MediaQuery.paddingOf(context).resolve(direction)
      ..scrollbarOrientation = widget.scrollbarOrientation
      ..crossAxisMargin = s.crossAxisMargin ?? 0
      ..mainAxisMargin = s.mainAxisMargin ?? 0
      ..minLength = s.minThumbLength ?? 0
      ..minOverscrollLength = s.minThumbLength ?? 0
      ..ignorePointer = !enableGestures;
  }

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    setState(() => _dragging = true);
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    super.handleThumbPressEnd(localPosition, velocity);
    setState(() => _dragging = false);
  }

  @override
  void handleHover(PointerHoverEvent event) {
    super.handleHover(event);
    final over = isPointerOverThumb(event.position, event.kind);
    if (over != _hovered) setState(() => _hovered = over);
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    if (_hovered) setState(() => _hovered = false);
  }
}
