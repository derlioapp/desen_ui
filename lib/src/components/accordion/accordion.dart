import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../behavior/spring_value.dart';
import '../../foundation/shrink_wrap.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../painting/decoration.dart';
import '../../painting/shadow.dart';
import '../../painting/shape.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'accordion_style.dart';

/// One section of a [DsAccordion].
@immutable
class DsAccordionItem<T> {
  /// Creates a section identified by [value].
  const DsAccordionItem({
    required this.value,
    required this.title,
    required this.child,
    this.enabled = true,
  });

  /// Identifies the section in [DsAccordion.value]. Unique in the
  /// accordion; open state follows it when sections are added, removed or
  /// reordered.
  final T value;

  /// The header, usually a short [Text].
  final Widget title;

  /// The content shown while the section is open.
  final Widget child;

  /// Whether the section can be opened and closed. A disabled section
  /// keeps its state: opening another one in a single-open accordion does
  /// not close it.
  final bool enabled;
}

/// Sections in one container with dividers; a chevron turns as a section
/// opens.
///
/// Sections are identified by their [DsAccordionItem.value], like
/// [DsTabs] and [DsSegmentedControl]. [value] is the set of open
/// sections. Uncontrolled by default ([initialValue], with [onChanged] to
/// hear about changes); pass [value] and [onChanged] to control it. A
/// controlled accordion without [onChanged] cannot change, so its headers
/// are disabled. With [allowMultiple] off, opening a section closes the
/// others, except disabled ones ([DsAccordionItem.enabled]), which keep
/// their state.
///
/// ```dart
/// DsAccordion<String>(
///   initialValue: const {'billing'},
///   items: const [
///     DsAccordionItem(value: 'billing', title: Text('Fatura'), child: …),
///     DsAccordionItem(value: 'team', title: Text('Ekip'), child: …),
///   ],
/// )
/// ```
///
/// Each header is a button (Enter or Space toggles) that announces whether
/// its section is expanded, inside a heading, as in the WAI-ARIA accordion
/// pattern. The keyboard focus ring is drawn inside the header, so the
/// rounded container never clips it. Each header is a Tab stop; [focusNode]
/// stands for the whole accordion: it has focus while a header does, and
/// focusing it (or [autofocus]) focuses the first header that can be
/// pressed.
class DsAccordion<T> extends StatefulWidget {
  /// Creates an accordion.
  const DsAccordion({
    super.key,
    required this.items,
    this.value,
    this.initialValue = const {},
    this.onChanged,
    this.allowMultiple = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The sections, top to bottom.
  final List<DsAccordionItem<T>> items;

  /// Values of the open sections, when controlled; null leaves the
  /// accordion to keep its own, starting from [initialValue].
  final Set<T>? value;

  /// Values of the sections open at first build, when uncontrolled.
  final Set<T> initialValue;

  /// Called with the new set of open section values. When [value] is set
  /// (controlled), null disables the headers.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether several sections may be open at once.
  final bool allowMultiple;

  /// Style laid over the theme and defaults.
  final DsAccordionStyle? style;

  /// Focus node for the accordion; one is created when null. See the class
  /// docs.
  final FocusNode? focusNode;

  /// Whether to focus the first header when first built.
  final bool autofocus;

  /// Names the group of sections for screen readers.
  final String? semanticLabel;

  /// Desen's default accordion style under [theme].
  static DsAccordionStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    const clear = Color(0x00000000);
    return DsAccordionStyle(
      background: k.surface,
      shadows: theme.shadows.surface,
      borderRadius: BorderRadius.circular(theme.radii.card),
      dividerColor: k.border,
      headerHeight: theme.sizes.listRow,
      headerPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s16,
      ),
      headerBackground: clear,
      titleStyle: theme.typography.bodyStrong.copyWith(color: k.text),
      iconColor: k.textSubtle,
      iconSize: 16,
      bodyPadding: const EdgeInsetsDirectional.fromSTEB(
        DsSpace.s16,
        0,
        DsSpace.s16,
        DsSpace.s16,
      ),
      bodyStyle: theme.typography.body.copyWith(color: k.textMuted),
      // Inside the header: the container's rounded clip would cut an
      // outside ring (ux V23).
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      hovered: DsAccordionStyle(headerBackground: k.hover),
      pressed: DsAccordionStyle(headerBackground: k.press),
      disabled: DsAccordionStyle(
        headerBackground: clear,
        titleStyle: TextStyle(color: k.onDisabled),
        iconColor: k.onDisabled,
      ),
    );
  }

  @override
  State<DsAccordion<T>> createState() => _DsAccordionState<T>();
}

class _DsAccordionState<T> extends State<DsAccordion<T>> {
  late Set<T> _open = {...widget.initialValue};

  Set<T> get _current => widget.value ?? _open;

  /// Controlled without onChanged: nothing can change.
  bool get _enabled => widget.value == null || widget.onChanged != null;

  /// One header node per section, by value.
  final _nodes = <T, FocusNode>{};

  FocusNode _nodeFor(T value) =>
      _nodes[value] ??= FocusNode(debugLabel: 'DsAccordion header');

  void _focusFirst() {
    if (!_enabled) return;
    for (final item in widget.items) {
      if (item.enabled) return _nodeFor(item.value).requestFocus();
    }
  }

  @override
  void didUpdateWidget(DsAccordion<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = {for (final item in widget.items) item.value};
    _nodes.removeWhere((value, node) {
      if (live.contains(value)) return false;
      node.dispose();
      return true;
    });
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _toggle(T i) {
    final next = {..._current};
    if (!next.remove(i)) {
      // Single open: close the others, but a disabled section keeps its
      // state, since its header cannot reopen it.
      if (!widget.allowMultiple) {
        final locked = {
          for (final item in widget.items)
            if (!item.enabled) item.value,
        };
        next.removeWhere((v) => !locked.contains(v));
      }
      next.add(i);
    }
    if (widget.value == null) setState(() => _open = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsAccordion.defaultStyle(t),
      DsAccordionTheme.of(context).style,
      widget.style,
    ];
    final base = DsAccordionStyle.resolveLayers(layers, const {});
    final radius = base.borderRadius ?? BorderRadius.zero;
    final corners = radius.resolve(Directionality.of(context));
    final open = _current;
    final n = widget.items.length;
    final enabled = _enabled;
    Widget accordion = DecoratedBox(
      decoration: DsBoxDecoration(
        color: base.background,
        borderRadius: radius,
        shadows: base.shadows ?? const [],
      ),
      child: DsShapeClip(
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++)
              _Section<T>(
                // Section state (hover, focus, animation) follows the item.
                key: ValueKey(widget.items[i].value),
                item: widget.items[i],
                open: open.contains(widget.items[i].value),
                divider: i > 0 ? base.dividerColor : null,
                layers: layers,
                // The header's own corners match the container's, so its
                // fill and inner focus ring follow the rounded edge.
                headerRadius: BorderRadius.only(
                  topLeft: i == 0 ? corners.topLeft : Radius.zero,
                  topRight: i == 0 ? corners.topRight : Radius.zero,
                  bottomLeft:
                      i == n - 1 && !open.contains(widget.items[i].value)
                      ? corners.bottomLeft
                      : Radius.zero,
                  bottomRight:
                      i == n - 1 && !open.contains(widget.items[i].value)
                      ? corners.bottomRight
                      : Radius.zero,
                ),
                focusNode: _nodeFor(widget.items[i].value),
                onToggle: enabled && widget.items[i].enabled
                    ? () => _toggle(widget.items[i].value)
                    : null,
              ),
          ],
        ),
      ),
    );
    // Under an unbounded width (in a Row) the accordion takes its
    // content's width instead of throwing.
    accordion = ShrinkWrapUnboundedWidth(child: accordion);
    accordion = FocusForward(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocused: _focusFirst,
      child: accordion,
    );
    if (widget.semanticLabel == null) return accordion;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: accordion,
    );
  }
}

class _Section<T> extends StatefulWidget {
  const _Section({
    super.key,
    required this.item,
    required this.open,
    required this.divider,
    required this.layers,
    required this.headerRadius,
    required this.focusNode,
    required this.onToggle,
  });

  final DsAccordionItem<T> item;
  final bool open;
  final Color? divider;
  final List<DsAccordionStyle?> layers;
  final BorderRadius headerRadius;
  final FocusNode focusNode;
  final VoidCallback? onToggle;

  @override
  State<_Section<T>> createState() => _SectionState<T>();
}

class _SectionState<T> extends State<_Section<T>> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final base = DsAccordionStyle.resolveLayers(widget.layers, const {});
    final header = DsPressable(
      onPressed: widget.onToggle,
      focusNode: widget.focusNode,
      expanded: widget.open,
      minTapTarget: 0,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsAccordionStyle.resolveLayers(widget.layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, states, _) {
        final s = DsAccordionStyle.resolveLayers(widget.layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          constraints: BoxConstraints(minHeight: s.headerHeight!),
          padding: s.headerPadding,
          decoration: DsBoxDecoration(
            color: s.headerBackground,
            borderRadius: widget.headerRadius,
            shadows: [
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: Row(
            spacing: DsSpace.s12,
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: s.titleStyle,
                  child: widget.item.title,
                ),
              ),
              // The chevron turns with the movement spring.
              DsSpringValue(
                value: widget.open ? 1 : 0,
                spring: t.motion.moveSpringOrNull,
                builder: (context, v, child) =>
                    Transform.rotate(angle: v * math.pi, child: child),
                child: DsIcon(
                  DsIcons.chevronDown,
                  size: s.iconSize!,
                  color: s.iconColor,
                ),
              ),
            ],
          ),
        );
      },
    );
    final body = widget.open
        ? Padding(
            padding: base.bodyPadding ?? EdgeInsets.zero,
            child: DefaultTextStyle.merge(
              style: base.bodyStyle,
              child: widget.item.child,
            ),
          )
        : const SizedBox(width: double.infinity);
    return DecoratedBox(
      decoration: DsBoxDecoration(
        shadows: [
          if (widget.divider case final line?)
            DsShadow.topLine(line, hairline: true),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A button inside a heading (WAI-ARIA accordion, ux V23).
          Semantics(container: true, header: true, child: header),
          // A size change that pushes the content below does not bounce
          // (K-46): the tone spring, which never overshoots. Reduced motion
          // jumps: AnimatedSize throws during layout with a zero duration.
          if (t.motion.reduced)
            body
          else
            AnimatedSize(
              duration: t.motion.toneDuration,
              curve: t.motion.toneCurve,
              alignment: AlignmentDirectional.topStart,
              child: body,
            ),
        ],
      ),
    );
  }
}
