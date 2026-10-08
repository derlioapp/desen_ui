import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/edge_fade_scroll.dart';
import '../../behavior/focus_visibility.dart';
import '../../behavior/haptic_feedback.dart';
import '../../behavior/min_tap_target.dart';
import '../../behavior/pressable.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../field/field_group.dart';
import 'chip.dart';
import 'chip_face.dart';
import 'chip_style.dart';

/// One option of a [DsChoiceChips] row.
@immutable
class DsChipOption<T> {
  /// Creates an option.
  const DsChipOption({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The value this chip stands for.
  final T value;

  /// The text, usually a short [Text].
  final Widget label;

  /// An icon before the label; the check takes its place while selected.
  final Widget? leading;

  /// Whether this option can be chosen.
  final bool enabled;

  /// Replaces the label for screen readers, e.g. when it is abbreviated.
  final String? semanticLabel;
}

/// A row of chips with exactly one selected: a filter such as
/// "All / Unread / Flagged".
///
/// The chips look like [DsChip]s (the same [DsChipStyle], defaults and
/// [DsChipTheme]), so single-choice and multi-choice filters match. The
/// selected chip takes the theme's selection style and a check.
///
/// A row wider than its space scrolls sideways, and an edge that hides
/// chips fades out, so the cut reads as more to scroll. The selected chip
/// is brought into view, clear of the fade, when the row is first built
/// and whenever [value] changes, moving the row the least distance that
/// shows it: a chip already in view does not move the row.
///
/// Keyboard (WAI-ARIA radio group): the row is one Tab stop, on the
/// selected chip (or the first enabled one when none is selected). Arrow
/// keys move the selection to the next or previous enabled chip, wrapping
/// around; Left and Right mirror in RTL. Home and End select the first and
/// last enabled chip. Screen readers hear a radio group of radios.
///
/// A [value] that matches no option selects none. A null [onChanged]
/// disables the row.
///
/// ```dart
/// DsChoiceChips<Filter>(
///   value: filter,
///   onChanged: (v) => setState(() => filter = v),
///   semanticLabel: 'Show',
///   options: const [
///     DsChipOption(value: Filter.all, label: Text('All')),
///     DsChipOption(value: Filter.unread, label: Text('Unread')),
///     DsChipOption(value: Filter.flagged, label: Text('Flagged')),
///   ],
/// )
/// ```
class DsChoiceChips<T> extends StatefulWidget {
  /// Creates a single-choice chip row.
  const DsChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The chips, in order.
  final List<DsChipOption<T>> options;

  /// The selected value.
  final T value;

  /// Called with the newly selected value. Null disables the row.
  /// Choosing the value that is already selected does not call it.
  final ValueChanged<T>? onChanged;

  /// Chip style laid over the theme and defaults, for every chip.
  final DsChipStyle? style;

  /// Focus node of the row; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Names the group for screen readers ("Show").
  final String? semanticLabel;

  @override
  State<DsChoiceChips<T>> createState() => _DsChoiceChipsState<T>();
}

class _DsChoiceChipsState<T> extends State<DsChoiceChips<T>> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  int? _hovered, _pressed;
  final _naming = FieldGroupNaming();

  /// One key per chip, so a chip can be scrolled into view by its own
  /// laid-out box.
  final _keys = <GlobalKey>[];

  /// Flutter's focus highlight, before the keyboard check.
  bool _highlight = false;
  bool get _focusVisible => _highlight && DsFocusVisibility.keyboard.value;
  // Input modality only changes how focus looks: rebuild only while
  // focused, not on every pointer or key event in the app.
  void _onModality() {
    if (_highlight) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DsFocusVisibility.keyboard.addListener(_onModality);
    // A row restored with a selection past the edge opens on it, without
    // sliding: nothing was tapped.
    _reveal(() => _index, animate: false);
  }

  @override
  void didUpdateWidget(DsChoiceChips<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _reveal(() => _index, animate: true);
  }

  @override
  void dispose() {
    DsFocusVisibility.keyboard.removeListener(_onModality);
    _naming.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;

  /// The selected chip, or -1 when [DsChoiceChips.value] matches none.
  int get _index => widget.options.indexWhere((o) => o.value == widget.value);

  /// The chip that stands for the row's focus: the selected one, or the
  /// first enabled one when none is (APG radio group).
  int get _focusTarget {
    final i = _index;
    return i >= 0 ? i : widget.options.indexWhere((o) => o.enabled);
  }

  /// Selects chip [i]. A [touch] (a tap) ticks; keys and assistive
  /// technology change it silently.
  void _select(int i, {bool touch = false}) {
    final o = widget.options[i];
    if (!_enabled || !o.enabled || o.value == widget.value) return;
    if (touch) DsHapticFeedback.play(context, DsHapticEvent.selection);
    widget.onChanged!(o.value);
  }

  /// Moves the selection by [step], skipping disabled chips.
  void _move(int step) {
    final n = widget.options.length;
    // From no selection, forward starts at the first, back at the last.
    var i = _index < 0 ? (step > 0 ? -1 : n) : _index;
    for (var tries = 0; tries < n; tries++) {
      i = (i + step) % n;
      if (i < 0) i += n;
      if (widget.options[i].enabled) return _select(i);
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
      final first = widget.options.indexWhere((o) => o.enabled);
      if (first >= 0) _select(first);
    } else if (key == LogicalKeyboardKey.end) {
      final last = widget.options.lastIndexWhere((o) => o.enabled);
      if (last >= 0) _select(last);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// After this frame's layout, scrolls the chip [index] gives the least
  /// distance that shows it whole and clear of the faded edges: to just
  /// inside the start edge when it is cut or faded there, to just inside
  /// the end edge when it is cut or faded there, not at all when it is in
  /// view. Next to the row's own start or end nothing fades, so the first
  /// and last chips reach the edge.
  void _reveal(int Function() index, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final i = index();
      if (i < 0 || i >= _keys.length) return;
      final chip = _keys[i].currentContext?.findRenderObject();
      final scrollable = _keys[i].currentContext == null
          ? null
          : Scrollable.maybeOf(_keys[i].currentContext!);
      if (chip == null || !chip.attached || scrollable == null) return;
      final viewport = RenderAbstractViewport.maybeOf(chip);
      if (viewport == null) return;
      final position = scrollable.position;
      const fade = DsEdgeFade.defaultWidth;
      final atStart = viewport.getOffsetToReveal(chip, 0).offset - fade;
      final atEnd = viewport.getOffsetToReveal(chip, 1).offset + fade;
      final min = position.minScrollExtent, max = position.maxScrollExtent;
      final double target;
      if (position.pixels > atStart.clamp(min, max)) {
        target = atStart;
      } else if (position.pixels < atEnd.clamp(min, max)) {
        target = atEnd;
      } else {
        return;
      }
      final to = target.clamp(min, max);
      final motion = DsTheme.motionOf(context);
      if (!animate || motion.reduced) {
        position.jumpTo(to);
      } else {
        position.animateTo(
          to,
          duration: motion.toneDuration,
          curve: motion.toneCurve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsChip.defaultStyle(t),
      DsChipTheme.of(context).style,
      widget.style,
    ];
    final n = widget.options.length;
    while (_keys.length < n) {
      _keys.add(GlobalKey());
    }
    if (_keys.length > n) _keys.removeRange(n, _keys.length);
    final selected = _index;
    final focusTarget = _focusTarget;
    // In a DsField the chips stay apart; the field's label names them.
    final field = _naming.read(context, semanticLabel: widget.semanticLabel);

    Widget chip(int i) {
      final option = widget.options[i];
      final interactive = _enabled && option.enabled;
      final stands = _enabled && i == focusTarget;
      final states = <WidgetState>{
        if (!interactive) WidgetState.disabled,
        if (i == selected) WidgetState.selected,
        if (interactive && _hovered == i) WidgetState.hovered,
        if (interactive && _pressed == i) WidgetState.pressed,
        if (stands && _focusVisible) WidgetState.focused,
      };
      return Semantics(
        key: _keys[i],
        container: true,
        // A radio: checked in a mutually exclusive group, no button flag.
        inMutuallyExclusiveGroup: true,
        checked: i == selected,
        enabled: interactive,
        label: option.semanticLabel,
        onTap: interactive ? () => _select(i) : null,
        // The row holds one focus node (one Tab stop); its focus is
        // reported on the chip that stands for it, so a screen reader
        // announces that chip, not an unnamed node.
        focusable: stands ? true : null,
        focused: stands ? _node.hasPrimaryFocus : null,
        onFocus: stands && defaultTargetPlatform != TargetPlatform.iOS
            ? _node.requestFocus
            : null,
        child: MouseRegion(
          cursor:
              DsChipStyle.resolveLayers(layers, states).cursor ??
              DsPressable.defaultCursor.resolve(states),
          onEnter: (_) => setState(() => _hovered = i),
          onExit: (_) => setState(() => _hovered = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: interactive ? (_) => setState(() => _pressed = i) : null,
            onTapCancel: () => setState(() => _pressed = null),
            onTapUp: (_) => setState(() => _pressed = null),
            onTap: interactive ? () => _select(i, touch: true) : null,
            child: DsMinTapTarget(
              size: t.sizes.minTapTarget,
              // A semantic label replaces the text instead of adding to it.
              child: ExcludeSemantics(
                excluding: option.semanticLabel != null,
                child: ChipFace(
                  layers: layers,
                  states: states,
                  leading: option.leading,
                  label: option.label,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The scroll view clips at its edges; the focus ring is drawn around
    // the chip, so the clip leaves it that much room.
    final ring = math.max(
      _outset(DsChipStyle.resolveLayers(layers, {WidgetState.focused})),
      _outset(
        DsChipStyle.resolveLayers(layers, {
          WidgetState.focused,
          WidgetState.selected,
        }),
      ),
    );

    return Focus(
      // Key events travel up from the focused node, so the handler sits
      // above the detector that owns focus.
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: FocusableActionDetector(
        focusNode: _node,
        autofocus: widget.autofocus,
        enabled: _enabled,
        // Focus semantics sit on the chip that stands for the row instead.
        includeFocusSemantics: false,
        onFocusChange: (focused) {
          setState(() {});
          // Tabbing in reveals the chip that shows the focus.
          if (focused) _reveal(() => _focusTarget, animate: true);
        },
        onShowFocusHighlight: (v) => setState(() => _highlight = v),
        child: ClipRect(
          clipper: _OutsetClipper(ring),
          child: DsEdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              // The radio group role sits inside the scroll view, so its
              // direct children are the chips.
              child: Semantics(
                container: true,
                role: SemanticsRole.radioGroup,
                label: field.label,
                hint: field.hint,
                isRequired: field.isRequired,
                validationResult: field.validationResult,
                explicitChildNodes: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: DsSpace.s8,
                  children: [for (var i = 0; i < n; i++) chip(i)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How far [style]'s focus ring reaches past the chip's edge.
double _outset(DsChipStyle style) {
  var out = 0.0;
  for (final s in style.focusShadows ?? const <DsShadow>[]) {
    if (s.inset) continue;
    final gap = s.gap < 0 ? 0.0 : s.gap;
    final reach =
        gap +
        s.spread +
        s.blur +
        math.max(s.offset.dx.abs(), s.offset.dy.abs());
    out = math.max(out, reach);
  }
  return out;
}

/// Clips to the box grown by [outset] on every side.
class _OutsetClipper extends CustomClipper<Rect> {
  const _OutsetClipper(this.outset);

  final double outset;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(outset);

  @override
  bool shouldReclip(_OutsetClipper oldClipper) => oldClipper.outset != outset;
}
