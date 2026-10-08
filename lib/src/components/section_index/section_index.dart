import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_ring.dart';
import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../foundation/case.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/surface.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'section_index_style.dart';

/// A column of section letters beside a long sorted list, such as
/// contacts, stations or countries: tap a letter, or drag along the
/// column, to jump the list to that section. The iOS list index and
/// Android's fast scroller work this way.
///
/// The app supplies the [sections] (usually only the letters that have
/// items, in the list's own order and alphabet, e.g. Turkish Ç Ğ İ Ö Ş Ü)
/// and does the scrolling in [onChanged]. Jump rather than animate when
/// `DsTheme.motionOf(context).reduced` is set. [value] is the section the
/// list shows now; the app updates it as the list scrolls, and it is
/// marked with the theme's selection style. Null marks none.
///
/// It fills the height it is given (beside a list in a [Row], or
/// [Positioned] over one in a [Stack]) and centers the letters in it.
/// When the letters do not all fit, some give way to dots, and a drag
/// still reaches every section. While a pointer is down, a bubble beside
/// the column shows the section under it, on the side facing the list
/// (left in left-to-right layouts); it needs an [Overlay] above, as
/// `DsApp` provides.
///
/// Keyboard: the column is one Tab stop. Up and Down move to the previous
/// and next section, Home and End to the first and last, and typing a
/// letter jumps to the first section that starts with it. Screen readers
/// get one adjustable control: swipe up or down to step through the
/// sections, and the current one is read as its value.
///
/// A tap or a drag ticks once per section as the platform's selection
/// haptic; keys and screen readers change it silently. A null [onChanged]
/// disables the column.
///
/// ```dart
/// Row(
///   children: [
///     Expanded(child: stationList),
///     DsSectionIndex(
///       sections: letters,
///       value: visibleLetter,
///       onChanged: (letter) => jumpTo(letter),
///       semanticLabel: 'Stations by letter',
///     ),
///   ],
/// )
/// ```
class DsSectionIndex extends StatefulWidget {
  /// Creates a section index.
  const DsSectionIndex({
    super.key,
    required this.sections,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The sections, top to bottom, shown as given: write them in capitals
  /// yourself if you want them (automatic upper-casing gets Turkish "i"
  /// wrong).
  final List<String> sections;

  /// The section the list shows now, or null for none.
  final String? value;

  /// Called with the section to jump to. A tap calls it even for [value]:
  /// tapping the current section goes back to its start. A drag calls it
  /// once per section it crosses. Null disables the column.
  final ValueChanged<String>? onChanged;

  /// Names the column for screen readers; defaults to "Section index" in
  /// the app's language.
  final String? semanticLabel;

  /// Style laid over the theme and defaults.
  final DsSectionIndexStyle? style;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Desen's default section index style under [theme].
  static DsSectionIndexStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final type = theme.typography;
    const clear = Color(0x00000000);
    return DsSectionIndexStyle(
      width: 20,
      letterHeight: 16,
      textStyle: type.caption.copyWith(
        fontWeight: type.labelStrong.fontWeight,
        height: 1,
      ),
      // The accent, as on iOS: the letters read as a control, not as a
      // caption.
      color: k.accentText,
      background: clear,
      markerSize: 18,
      dotSize: 4,
      bubbleSize: 56,
      bubbleGap: DsSpace.s12,
      // A transient label over the content, like a tooltip.
      bubbleColor: k.tooltip,
      bubbleTextStyle: type.title.copyWith(color: k.onTooltip),
      bubbleShadows: theme.shadows.tooltip,
      focusShadows: theme.focusShadows,
      hovered: DsSectionIndexStyle(background: k.hover),
      pressed: DsSectionIndexStyle(background: k.press),
      selected: DsSectionIndexStyle(
        background: k.selection,
        color: k.onSelection,
        hovered: DsSectionIndexStyle(background: k.selectionHover),
      ),
      disabled: DsSectionIndexStyle(color: k.onDisabled, background: clear),
    );
  }

  @override
  State<DsSectionIndex> createState() => _DsSectionIndexState();
}

/// One place in the column: a section's letter, or a dot that stands for
/// letters that do not fit.
typedef _Slot = ({int section, bool dot});

class _DsSectionIndexState extends State<DsSectionIndex> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  final _link = LayerLink();
  final _bubble = OverlayPortalController();

  /// The section under the pointer while it is down, else null.
  int? _active;

  /// The section under the mouse, else null.
  int? _hovered;

  /// The latest section this column reported or was given: the start for
  /// keys and screen readers. A quick tap ends before the parent rebuilds,
  /// so [DsSectionIndex.value] can be stale.
  late int? _latest = _valueIndex;

  /// Flutter's focus highlight, before the keyboard check.
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app.
  void _onModality() {
    if (_highlight) setState(() {});
  }

  bool get _enabled => widget.onChanged != null && widget.sections.isNotEmpty;

  int? get _valueIndex {
    final i = widget.sections.indexOf(widget.value ?? '');
    return widget.value == null || i < 0 ? null : i;
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
  }

  @override
  void didUpdateWidget(DsSectionIndex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value ||
        widget.sections != oldWidget.sections) {
      _latest = _valueIndex;
    }
    final n = widget.sections.length;
    if (!_enabled || (_active ?? 0) >= n) _release();
    if ((_hovered ?? 0) >= n) _hovered = null;
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _ownNode?.dispose();
    super.dispose();
  }

  /// Reports section [i]. A [touch] ticks; keys and assistive actions are
  /// silent, as on iOS.
  void _emit(int i, {bool touch = false}) {
    if (!_enabled) return;
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    _latest = i;
    widget.onChanged!(widget.sections[i]);
  }

  /// The pointer went down or moved onto section [i].
  void _press(int i) {
    if (!_enabled || i == _active) return;
    setState(() => _active = i);
    if (!_bubble.isShowing) _bubble.show();
    _emit(i, touch: true);
  }

  /// The pointer lifted, or the gesture was lost: the bubble goes.
  void _release() {
    if (_bubble.isShowing) _bubble.hide();
    if (_active != null && mounted) setState(() => _active = null);
    _active = null;
  }

  /// Moves [step] sections from the current one, held at the ends; from
  /// none, forward starts at the first and back at the last.
  void _step(int step) {
    final n = widget.sections.length;
    final from = _latest;
    final next = from == null
        ? (step > 0 ? 0 : n - 1)
        : (from + step).clamp(0, n - 1);
    if (next != from) _emit(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final n = widget.sections.length;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.home) {
      if (_latest != 0) _emit(0);
    } else if (key == LogicalKeyboardKey.end) {
      if (_latest != n - 1) _emit(n - 1);
    } else if (event.character case final c?
        when c.trim().isNotEmpty &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed) {
      // Type to jump: the first section that starts with the letter as
      // typed, then case-folded. Folding makes the Turkish dotless ı and
      // dotted i one letter (right for search), but here both can be
      // sections of their own, so a match that keeps the dot comes first.
      bool dotless(String x) => x.startsWith('ı') || x.startsWith('I');
      final folded = dsFoldCase(c);
      bool loose(String s) => dsFoldCase(s).startsWith(folded);
      final sections = widget.sections;
      var i = sections.indexWhere((s) => s.startsWith(c));
      if (i < 0) {
        i = sections.indexWhere((s) => loose(s) && dotless(s) == dotless(c));
      }
      if (i < 0) i = sections.indexWhere(loose);
      if (i < 0) return KeyEventResult.ignored;
      _emit(i);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// The places shown in [slots] rows for [n] sections: every letter when
  /// they fit, else letters spread evenly from the first to the last with
  /// a dot between each two, as the iOS index does.
  static List<_Slot> _layout(int n, int slots) {
    if (n <= slots) {
      return [for (var i = 0; i < n; i++) (section: i, dot: false)];
    }
    // An odd count, so the column starts and ends on a letter.
    final rows = math.max(1, slots.isOdd ? slots : slots - 1);
    final letters = (rows + 1) ~/ 2;
    if (letters < 2) return [(section: 0, dot: false)];
    final out = <_Slot>[];
    for (var j = 0; j < letters; j++) {
      final i = (j * (n - 1) / (letters - 1)).round();
      if (j > 0) {
        final prev = out.last.section;
        out.add((section: (prev + i) ~/ 2, dot: true));
      }
      out.add((section: i, dot: false));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsSectionIndex.defaultStyle(t),
      DsSectionIndexTheme.of(context).style,
      widget.style,
    ];
    final plain = DsSectionIndexStyle.resolveLayers(layers, {
      if (!_enabled) WidgetState.disabled,
    });
    final n = widget.sections.length;
    final current = _valueIndex;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final width = math.max(plain.width!, t.sizes.minTapTarget);
    final row = MediaQuery.textScalerOf(context).scale(plain.letterHeight!);
    final l10n = DsLocalizations.of(context);

    String? name(int? i) => i == null ? null : widget.sections[i];
    final latest = _latest;
    final next = latest == null ? 0 : latest + 1;
    final previous = latest == null ? n - 1 : latest - 1;

    Widget letter(int i) {
      final s = DsSectionIndexStyle.resolveLayers(layers, {
        if (!_enabled) WidgetState.disabled,
        if (i == current) WidgetState.selected,
        if (_enabled && i == _hovered) WidgetState.hovered,
        if (_enabled && i == _active) WidgetState.pressed,
      });
      final marker = s.markerSize!;
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // The marker may be taller than a row; it overlaps its
          // neighbours' empty space rather than pushing them apart.
          OverflowBox(
            maxWidth: marker,
            maxHeight: marker,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s.background,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: marker),
            ),
          ),
          Text(
            widget.sections[i],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: s.textStyle!.copyWith(color: s.color),
          ),
        ],
      );
    }

    Widget dot() => DecoratedBox(
      decoration: BoxDecoration(color: plain.color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: plain.dotSize!),
    );

    Widget column(BoxConstraints c) {
      final pad = DsSpace.s4;
      final height = c.hasBoundedHeight ? c.maxHeight : n * row + 2 * pad;
      final slots = math.max(0, ((height - 2 * pad) / row).floor());
      final shown = n == 0 ? const <_Slot>[] : _layout(n, slots);
      final block = shown.length * row;
      final top = (height - block) / 2;

      /// The section at [y]: the column's letters share its block evenly
      /// (also the ones a dot stands for); above or below it, the ends.
      int at(double y) {
        if (n == 0 || block <= 0) return 0;
        return ((y - top) / block * n).floor().clamp(0, n - 1);
      }

      /// Where the bubble for section [i] is centered, from the top.
      double centerOf(int i) {
        final k = shown.indexWhere((s) => !s.dot && s.section == i);
        return k >= 0 ? top + (k + .5) * row : top + (i + .5) / n * block;
      }

      final bubbleSize = plain.bubbleSize!;
      final bubble = OverlayPortal(
        controller: _bubble,
        overlayChildBuilder: (context) {
          final i = _active;
          if (i == null || i >= n) return const SizedBox.shrink();
          return Align(
            alignment: AlignmentDirectional.topStart,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              // On the side that faces the list: the start side of the
              // column.
              targetAnchor: rtl ? Alignment.topRight : Alignment.topLeft,
              followerAnchor: rtl ? Alignment.topLeft : Alignment.topRight,
              offset: Offset(
                rtl ? plain.bubbleGap! : -plain.bubbleGap!,
                (centerOf(i) - bubbleSize / 2).clamp(
                  0,
                  math.max(0, height - bubbleSize),
                ),
              ),
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: _Bubble(style: plain, label: widget.sections[i]),
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final s in shown)
                SizedBox(
                  width: width,
                  height: row,
                  child: Center(child: s.dot ? dot() : letter(s.section)),
                ),
            ],
          ),
        ),
      );

      return MouseRegion(
        cursor: !_enabled
            ? SystemMouseCursors.basic
            : plain.cursor ?? SystemMouseCursors.click,
        onHover: _enabled
            ? (e) {
                final i = at(e.localPosition.dy);
                if (i != _hovered) setState(() => _hovered = i);
              }
            : null,
        onExit: (_) {
          if (_hovered != null) setState(() => _hovered = null);
        },
        child: Listener(
          // The column answers the moment it is touched, as the iOS index
          // does, and follows the pointer while it is down; it does not
          // wait for a tap or a drag to win.
          onPointerDown: _enabled
              ? (e) {
                  if (e.kind == PointerDeviceKind.mouse &&
                      e.buttons != kPrimaryMouseButton) {
                    return;
                  }
                  _press(at(e.localPosition.dy));
                }
              : null,
          onPointerMove: _enabled
              ? (e) {
                  if (_active != null) _press(at(e.localPosition.dy));
                }
              : null,
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          // Claims the vertical drag, so a scroll view around the column
          // does not scroll while a finger runs along it.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragUpdate: _enabled ? (_) {} : null,
            child: CompositedTransformTarget(link: _link, child: bubble),
          ),
        ),
      );
    }

    return Semantics(
      slider: true,
      label: widget.semanticLabel ?? l10n.sectionIndex,
      enabled: _enabled,
      value: name(latest) ?? '',
      // With no current section there is no value to step from: the
      // actions still start at an end, but nothing is announced ahead.
      increasedValue: _enabled && latest != null && next < n
          ? name(next)
          : null,
      decreasedValue: _enabled && latest != null && previous >= 0
          ? name(previous)
          : null,
      onIncrease: _enabled && next < n ? () => _step(1) : null,
      onDecrease: _enabled && previous >= 0 ? () => _step(-1) : null,
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
          onShowFocusHighlight: (f) => setState(() => _highlight = f),
          child: DsFocusRing(
            focused: _focusVisible,
            shadows: plain.focusShadows,
            borderRadius: BorderRadius.all(Radius.circular(width / 2)),
            child: ExcludeSemantics(
              child: LayoutBuilder(builder: (context, c) => column(c)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bubble that shows the section under the pointer.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.style, required this.label});

  final DsSectionIndexStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    final size = style.bubbleSize!;
    return DsSurface(
      decoration: DsBoxDecoration(
        color: style.bubbleColor,
        borderRadius: DsTheme.radiiOf(context)
            .controlCorners(style.bubbleRadius, size),
        shadows: style.bubbleShadows ?? const [],
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: style.bubbleTextStyle,
          ),
        ),
      ),
    );
  }
}
