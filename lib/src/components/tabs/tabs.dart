import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/haptic_feedback.dart';
import '../../foundation/color_utils.dart';
import '../../behavior/focus_visibility.dart';
import '../../behavior/pressable.dart';
import '../../behavior/spring_value.dart';
import '../../behavior/tap_band.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../badge/badge.dart';
import 'tabs_style.dart';

/// One tab of a [DsTabs] bar.
@immutable
class DsTab<T> {
  /// Creates a tab.
  const DsTab({
    required this.value,
    required this.label,
    this.count,
    this.countSemanticLabel,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The value this tab selects.
  final T value;

  /// The label, usually a short [Text].
  final Widget label;

  /// A neutral count after the label (e.g. members). Screen readers hear
  /// it after the label, as the number ("Members, 12"), unless
  /// [countSemanticLabel] says what it counts.
  final int? count;

  /// What screen readers hear for [count] instead of the bare number,
  /// e.g. "12 members"; the app words it, since only it knows what is
  /// counted. Null reads the number ("99+" above 99).
  final String? countSemanticLabel;

  /// Whether the tab can be selected.
  final bool enabled;

  /// Overrides the label screen readers announce.
  final String? semanticLabel;
}

/// A tab bar with an underline indicator.
///
/// The bar only selects; show the matching content below it yourself. The
/// underline grows in with a spring, and every label keeps the same weight
/// so nothing shifts when the selection moves.
///
/// Keyboard (WAI-ARIA tabs): the bar is one Tab stop; arrow keys move the
/// selection (mirrored in RTL) and skip disabled tabs; Home and End jump to
/// the first and last tab.
///
/// Screen readers hear a tab bar of tabs, each with its label, whether it
/// is selected and, on iOS and Android, its position ("Tab 2 of 4",
/// localized); on the web the tab role tells the position.
///
/// Tabs that do not fit scroll; the edge that hides tabs fades out, and a
/// newly selected tab scrolls into view.
///
/// A tab answers taps across its whole cell: its label and half the gap
/// on each side, so the gaps between tabs are never dead and a short
/// label ("Me") is still easy to hit. Where the gap alone leaves a cell
/// narrower than the theme's [DsSizes.minTapTarget] (44 on iOS and
/// Android), a short tab is widened to make up the difference.
///
/// ```dart
/// DsTabs<String>(
///   value: tab,
///   onChanged: (v) => setState(() => tab = v),
///   tabs: const [
///     DsTab(value: 'general', label: Text('General')),
///     DsTab(value: 'members', label: Text('Members'), count: 12),
///   ],
/// )
/// ```
class DsTabs<T> extends StatefulWidget {
  /// Creates a tab bar.
  const DsTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tabs,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The selected value.
  final T value;

  /// Called with the newly selected value. Null disables the bar.
  final ValueChanged<T>? onChanged;

  /// The tabs, start to end.
  final List<DsTab<T>> tabs;

  /// Style laid over the theme and defaults.
  final DsTabsStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Names the tab bar for screen readers.
  final String? semanticLabel;

  /// Desen's default tabs style under [theme].
  static DsTabsStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsTabsStyle(
      height: 46,
      gap: DsSpace.s20,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: DsSpace.s20),
      foreground: k.textMuted,
      textStyle: theme.typography.bodyStrong,
      // The underline has no label on it: the indicator role, which stands
      // 3:1 off the surface even under a bright accent.
      indicatorColor: k.indicator,
      indicatorHeight: 2,
      dividerColor: k.border,
      // The label has no padding of its own, so the ring stands a little
      // further off than the usual 2px to clear accents (Ü, Ş).
      focusShadows: [
        for (final x in theme.focusShadows)
          x.isOutline ? x.copyWith(gap: DsSpace.s4) : x,
      ],
      hovered: DsTabsStyle(foreground: k.text),
      selected: DsTabsStyle(foreground: k.text),
      disabled: DsTabsStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsTabs<T>> createState() => _DsTabsState<T>();
}

class _DsTabsState<T> extends State<DsTabs<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  int? _hovered;
  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app.
  void _onModality() {
    if (_highlight) setState(() {});
  }

  final _scroll = ScrollController();
  final _tabKeys = <GlobalKey>[];
  final _scrollerKey = GlobalKey();

  /// Whether tabs are hidden past the start or the end: those edges fade.
  bool _moreBefore = false, _moreAfter = false;

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
    _revealSelected(animate: false);
  }

  @override
  void didUpdateWidget(DsTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _revealSelected(animate: true);
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownNode?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the selected tab into view after this frame's layout.
  void _revealSelected({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final i = _index;
      if (i < 0 || i >= _tabKeys.length) return;
      final tab = _tabKeys[i].currentContext?.findRenderObject();
      if (tab == null || !_scroll.hasClients) return;
      final motion = DsTheme.motionOf(context);
      // The strip's own position only: `Scrollable.ensureVisible` would
      // also scroll every scrollable around the tabs, so a page opened on
      // a selected tab jumped to it.
      _scroll.position.ensureVisible(
        tab,
        alignment: .5,
        duration: animate && !motion.reduced
            ? motion.toneDuration
            : Duration.zero,
        curve: motion.toneCurve,
      );
    });
  }

  bool _onMetrics(ScrollMetrics m) {
    final before = m.extentBefore > .5, after = m.extentAfter > .5;
    if (before != _moreBefore || after != _moreAfter) {
      void apply() {
        if (!mounted) return;
        setState(() {
          _moreBefore = before;
          _moreAfter = after;
        });
      }

      // Metrics can be reported during layout; wait for the frame then.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      } else {
        apply();
      }
    }
    return false;
  }

  bool get _enabled => widget.onChanged != null;

  int get _index => widget.tabs.indexWhere((t) => t.value == widget.value);

  /// Selects tab [i]. A [touch] (a tap) ticks; keys and assistive
  /// actions are silent, as on iOS.
  void _select(int i, {bool touch = false}) {
    final tab = widget.tabs[i];
    if (!_enabled || !tab.enabled || tab.value == widget.value) return;
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    widget.onChanged!(tab.value);
  }

  void _move(int step) {
    final n = widget.tabs.length;
    // From no selection, forward starts at the first, back at the last
    // (forward used to skip the first tab).
    var i = _index < 0 ? (step > 0 ? -1 : n) : _index;
    for (var tries = 0; tries < n; tries++) {
      i = (i + step) % n;
      if (i < 0) i += n;
      if (widget.tabs[i].enabled) return _select(i);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      _move(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _move(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      final first = widget.tabs.indexWhere((t) => t.enabled);
      if (first >= 0) _select(first);
    } else if (key == LogicalKeyboardKey.end) {
      final last = widget.tabs.lastIndexWhere((t) => t.enabled);
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
      DsTabs.defaultStyle(t),
      DsTabsTheme.of(context).style,
      widget.style,
    ];
    final base = DsTabsStyle.resolveLayers(layers, const {});
    final selected = _index;
    // The tab that stands for the bar's focus: the selected one, or the
    // first enabled one when none is (APG tabs: focus is on the active tab).
    final focusTarget = selected >= 0
        ? selected
        : widget.tabs.indexWhere((t) => t.enabled);
    while (_tabKeys.length < widget.tabs.length) {
      _tabKeys.add(GlobalKey());
    }
    final l10n = DsLocalizations.of(context);
    final gap = base.gap ?? DsSpace.s20;
    // Each tab takes half the gap on either side; a tab too short for the
    // smallest tap target with that is widened (its label stays centered).
    final halfGap = gap / 2;
    final reach = EdgeInsets.symmetric(horizontal: halfGap);
    final minTap = DsTheme.sizesOf(context).minTapTarget;
    final minWidth = math.max(0.0, minTap - gap);

    Widget tab(int i) {
      final tab = widget.tabs[i];
      final interactive = _enabled && tab.enabled;
      final states = <WidgetState>{
        if (!interactive) WidgetState.disabled,
        if (i == selected) WidgetState.selected,
        if (_hovered == i && interactive) WidgetState.hovered,
        if (i == selected && _focusVisible) WidgetState.focused,
      };
      final s = DsTabsStyle.resolveLayers(layers, states);
      final fg = s.foreground ?? t.colors.text;
      final label = TweenAnimationBuilder<Color?>(
        tween: DsColorTween(end: fg),
        duration: t.motion.toneDuration,
        curve: t.motion.toneCurve,
        builder: (context, color, _) => DefaultTextStyle(
          style: (s.textStyle ?? const TextStyle()).copyWith(color: color),
          maxLines: 1,
          softWrap: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: DsSpace.s8,
            children: [
              tab.label,
              if (tab.count != null)
                DsCount(
                  tab.count!,
                  tone: DsCountTone.neutral,
                  semanticLabel: tab.countSemanticLabel,
                ),
            ],
          ),
        ),
      );
      return TapBand(
        size: minTap,
        outset: reach,
        child: Semantics(
          key: _tabKeys[i],
          container: true,
          role: SemanticsRole.tab,
          selected: i == selected,
          enabled: interactive,
          label: tab.semanticLabel,
          onTap: interactive ? () => _select(i) : null,
          // The bar holds one focus node (one Tab stop); its focus is
          // reported on the selected tab, so a screen reader announces the
          // tab, not an unnamed group.
          focusable: _enabled && i == focusTarget ? true : null,
          focused: _enabled && i == focusTarget ? _node.hasPrimaryFocus : null,
          onFocus: _enabled && i == focusTarget && _semanticFocusAction
              ? _node.requestFocus
              : null,
          child: MouseRegion(
            cursor: interactive
                ? s.cursor ?? DsPressable.defaultCursor.resolve(const {})
                : DsPressable.defaultCursor.resolve(const {
                    WidgetState.disabled,
                  }),
            onEnter: (_) => setState(() => _hovered = i),
            onExit: (_) => setState(() => _hovered = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: interactive ? () => _select(i, touch: true) : null,
              child: Container(
                height: s.height!,
                constraints: BoxConstraints(minWidth: minWidth),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: DsBoxDecoration(
                        // The ring hugs the label, a line of text about 20
                        // tall: rounded as a control of that height.
                        borderRadius: BorderRadius.circular(
                          t.radii.control(20),
                        ),
                        shadows: [
                          if (states.contains(WidgetState.focused))
                            ...?s.focusShadows,
                        ],
                      ),
                      child: label,
                    ),
                    // The position, read after the label; on the web the tab
                    // role tells it.
                    if (!kIsWeb)
                      Semantics(label: l10n.tabOf(i + 1, widget.tabs.length)),
                    // The underline grows from the center when selected.
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: DsSpringValue(
                        value: i == selected ? 1 : 0,
                        spring: t.motion.moveSpringOrNull,
                        builder: (context, v, child) => Transform.scale(
                          // Grows in; never wider than its tab (no spill
                          // flash).
                          scaleX: v.clamp(0, 1).toDouble(),
                          child: child,
                        ),
                        child: AnimatedContainer(
                          duration: t.motion.toneDuration,
                          curve: t.motion.toneCurve,
                          height: s.indicatorHeight!,
                          decoration: BoxDecoration(
                            color: s.indicatorColor,
                            borderRadius: BorderRadius.circular(
                              s.indicatorHeight!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          focusNode: _node,
          autofocus: widget.autofocus,
          enabled: _enabled,
          // Focus semantics sit on the selected tab instead.
          includeFocusSemantics: false,
          onFocusChange: (_) => setState(() {}),
          onShowFocusHighlight: (v) => setState(() => _highlight = v),
          // The hairline spans the full width; tabs scroll when they do
          // not fit.
          child: DecoratedBox(
            decoration: DsBoxDecoration(
              shadows: [
                if (base.dividerColor case final line?)
                  DsShadow.bottomLine(line, hairline: true),
              ],
            ),
            child: _fade(
              SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: base.padding,
                // The tab bar role sits inside the scroll view, so its direct
                // children are the tabs.
                child: Semantics(
                  container: true,
                  role: SemanticsRole.tabBar,
                  explicitChildNodes: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: gap,
                    children: [
                      for (var i = 0; i < widget.tabs.length; i++) tab(i),
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

  /// Fades the edges that hide tabs, so a clipped bar reads as scrollable.
  Widget _fade(Widget scroller) {
    // Keyed, so turning the fade on or off keeps the scroll position.
    final listened = NotificationListener<ScrollMetricsNotification>(
      key: _scrollerKey,
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: scroller,
      ),
    );
    if (!_moreBefore && !_moreAfter) return listened;
    const opaque = Color(0xFF000000); // ds-raw: a mask, only alpha counts
    const clear = Color(0x00000000);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final edge = rect.width <= 0 ? 0.0 : (_fadeWidth / rect.width);
        return LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            _moreBefore ? clear : opaque,
            opaque,
            opaque,
            _moreAfter ? clear : opaque,
          ],
          stops: [0, edge.clamp(0, .5), 1 - edge.clamp(0, .5), 1],
        ).createShader(rect, textDirection: Directionality.of(context));
      },
      child: listened,
    );
  }

  static const _fadeWidth = 24.0;
}

/// Whether a semantics focus action may move input focus. Flutter's own
/// [Focus] leaves it out on iOS (flutter/flutter#150030).
bool get _semanticFocusAction => defaultTargetPlatform != TargetPlatform.iOS;
