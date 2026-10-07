import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/numeric_span.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import 'pagination_slots.dart';
import 'pagination_style.dart';

/// Page navigation: previous, numbered pages with gaps, next. The current
/// page takes the theme's selection style; numbers are in tabular figures
/// so the row does not jump; the arrows turn inactive at the ends.
///
/// ```dart
/// DsPagination(
///   page: page,
///   pageCount: 12,
///   onChanged: (p) => setState(() => page = p),
/// )
/// ```
///
/// When the pages do not fit the width (a phone, touch density, large
/// text) it collapses to "‹ 6 / 24 ›". With `pageCount: 0` (no results)
/// only the inactive arrows show. Screen readers hear a navigation named
/// "Pagination", pages as "Page 4" and the current one as the current
/// page (all localized).
///
/// Every page and arrow is a Tab stop. [focusNode] stands for the whole
/// control: it has focus while a page or arrow does, and focusing it (or
/// [autofocus]) focuses the current page.
class DsPagination extends StatefulWidget {
  /// Creates pagination. [page] counts from 1; it is ignored when
  /// [pageCount] is 0, and shows as the last page when it is past
  /// [pageCount].
  const DsPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.style,
    this.previousLabel,
    this.nextLabel,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(pageCount >= 0),
       assert(pageCount == 0 || page >= 1);

  /// The current page, from 1.
  ///
  /// A page past [pageCount] (a filter left fewer pages while the app
  /// still holds the old page) shows as the last page. [onChanged] is not
  /// called for that: the app's page stays as it is until it sets one.
  final int page;

  /// Number of pages; 0 for an empty result.
  final int pageCount;

  /// Called with the chosen page. Null disables the control.
  final ValueChanged<int>? onChanged;

  /// Style laid over the theme and defaults.
  final DsPaginationStyle? style;

  /// Screen reader label of the previous button. Defaults to the
  /// localized "Previous page".
  final String? previousLabel;

  /// Screen reader label of the next button. Defaults to the localized
  /// "Next page".
  final String? nextLabel;

  /// Focus node for the control; one is created when null. See the class
  /// docs.
  final FocusNode? focusNode;

  /// Whether to focus the current page when first built.
  final bool autofocus;

  /// Names the navigation for screen readers. Defaults to the localized
  /// "Pagination".
  final String? semanticLabel;

  /// Desen's default pagination style under [theme].
  static DsPaginationStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsPaginationStyle(
      itemSize: theme.sizes.sm,
      // No radius: the corners follow the resolved item size.
      background: const Color(0x00000000),
      foreground: k.text,
      textStyle: theme.typography.numeric(theme.typography.small),
      ellipsisColor: k.textSubtle,
      gap: DsSpace.s4,
      focusShadows: theme.focusShadows,
      hovered: DsPaginationStyle(background: k.hover),
      pressed: DsPaginationStyle(background: k.press),
      selected: DsPaginationStyle(
        background: theme.selectedFill,
        borderColor: theme.selectedEdge,
        foreground: theme.onSelectedFill,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        // Hover stays visible on a selected item.
        hovered: DsPaginationStyle(background: theme.selectedHoverFill),
      ),
      disabled: DsPaginationStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsPagination> createState() => _DsPaginationState();

  /// The page shown: [page] kept within 1 and [pageCount]; 0 for no pages.
  int get _shownPage => pageCount <= 0 ? 0 : page.clamp(1, pageCount);

  /// Builds the control with the stops' [nodes].
  Widget _build(BuildContext context, _Nodes nodes) {
    final t = dsThemeOf(context);
    final layers = [
      defaultStyle(t),
      DsPaginationTheme.of(context).style,
      style,
    ];
    final s = DsPaginationStyle.resolveLayers(layers, const {});
    final enabled = onChanged != null;
    final size = s.itemSize!;
    final gap = s.gap ?? DsSpace.s4;
    final l10n = DsLocalizations.of(context);
    final count = math.max(0, pageCount);
    final page = _shownPage;
    final pages = paginationSlots(page, count);
    final textStyle = DefaultTextStyle.of(context).style.merge(s.textStyle);
    // The current page's look, the widest case when measuring.
    final selectedText = textStyle.merge(
      DsPaginationStyle.resolveLayers(layers, const {
        WidgetState.selected,
      }).textStyle,
    );

    Widget arrow(bool next) => DsButton.icon(
      focusNode: next ? nodes.next : nodes.previous,
      variant: DsButtonVariant.ghost,
      size: DsSize.sm,
      icon: DsIcon(next ? DsIcons.chevronRight : DsIcons.chevronLeft),
      semanticLabel: next
          ? nextLabel ?? l10n.nextPage
          : previousLabel ?? l10n.previousPage,
      onPressed: !enabled
          ? null
          : next && page < count
          ? () => onChanged!(page + 1)
          : !next && page > 1
          ? () => onChanged!(page - 1)
          : null,
    );

    // The full row's width: every slot at least the tap target, numbers
    // at their measured width (bold, the widest case) plus padding.
    double fullWidth() {
      final target = math.max(size, t.sizes.minTapTarget);
      var w = 2 * target + gap * (pages.length + 1);
      for (final slot in pages) {
        if (slot == null) {
          w += size;
          continue;
        }
        final painter = TextPainter(
          text: TextSpan(text: '$slot', style: selectedText),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        w += math.max(target, painter.width + 2 * DsSpace.s4);
        painter.dispose();
      }
      return w;
    }

    return Semantics(
      container: true,
      role: SemanticsRole.navigation,
      label: semanticLabel ?? l10n.pagination,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, c) {
          // Too narrow for every page (a phone, touch density, large
          // text): "‹ 6 / 24 ›".
          if (count > 0 && c.hasBoundedWidth && fullWidth() > c.maxWidth) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                arrow(false),
                Flexible(
                  child: Semantics(
                    label: l10n.pageOf(page, count),
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpace.s4,
                      ),
                      child: Text.rich(
                        numericSpan(
                          l10n.pageCounter(page, count),
                          style: textStyle.copyWith(color: s.foreground),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                arrow(true),
              ],
            );
          }
          return _row(pages, page, enabled, layers, s, size, gap, arrow, nodes);
        },
      ),
    );
  }

  Widget _row(
    List<int?> pages,
    int page,
    bool enabled,
    List<DsPaginationStyle?> layers,
    DsPaginationStyle s,
    double size,
    double gap,
    Widget Function(bool next) arrow,
    _Nodes nodes,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: [
      arrow(false),
      for (final slot in pages)
        if (slot == null)
          ExcludeSemantics(
            child: SizedBox(
              width: size,
              child: Text(
                // ds-raw: a gap mark, hidden from screen readers
                '…',
                textAlign: TextAlign.center,
                style: (s.textStyle ?? const TextStyle()).copyWith(
                  color: s.ellipsisColor,
                ),
              ),
            ),
          )
        else
          _Page(
            number: slot,
            selected: slot == page,
            onPressed: enabled ? () => onChanged!(slot) : null,
            focusNode: nodes.page(slot),
            layers: layers,
          ),
      arrow(true),
    ],
  );
}

/// The stops' focus nodes, each kept by what it stands for, so focus stays
/// on a page button when the current page changes.
class _Nodes {
  final previous = FocusNode(debugLabel: 'DsPagination previous');
  final next = FocusNode(debugLabel: 'DsPagination next');
  final _pages = <int, FocusNode>{};

  FocusNode page(int number) =>
      _pages[number] ??= FocusNode(debugLabel: 'DsPagination page $number');

  /// Disposes the nodes of pages no longer shown.
  void keep(Iterable<int?> shown) {
    final keep = shown.toSet();
    _pages.removeWhere((number, node) {
      if (keep.contains(number)) return false;
      node.dispose();
      return true;
    });
  }

  void dispose() {
    previous.dispose();
    next.dispose();
    for (final node in _pages.values) {
      node.dispose();
    }
  }
}

class _DsPaginationState extends State<DsPagination> {
  final _nodes = _Nodes();

  @override
  void dispose() {
    _nodes.dispose();
    super.dispose();
  }

  /// The current page, or in the narrow form the arrow that can move.
  void _focusCurrent() {
    final w = widget;
    final page = w._shownPage;
    // A page node outlives its button for a frame, and its context then
    // belongs to an element that is gone (the row narrowed to "‹ 6 / 24 ›").
    final current = _nodes._pages[page];
    if (current != null && (current.context?.mounted ?? false)) {
      current.requestFocus();
    } else if (page < w.pageCount) {
      _nodes.next.requestFocus();
    } else {
      _nodes.previous.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Once the frame is built, pages no longer shown let go of their nodes.
    final shown = paginationSlots(widget._shownPage, widget.pageCount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.keep(shown);
    });
    return FocusForward(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocused: _focusCurrent,
      child: widget._build(context, _nodes),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page({
    required this.number,
    required this.selected,
    required this.onPressed,
    required this.focusNode,
    required this.layers,
  });

  final int number;
  final bool selected;
  final VoidCallback? onPressed;
  final FocusNode focusNode;
  final List<DsPaginationStyle?> layers;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    return DsPressable(
      // The current page stays a Tab stop that does nothing; in a disabled
      // control it is disabled as the others are.
      onPressed: widget.selected && widget.onPressed != null
          ? () {}
          : widget.onPressed,
      // The current page does nothing, so it plays nothing either.
      haptic: widget.selected ? null : DsHapticEvent.command,
      focusNode: widget.focusNode,
      selected: widget.selected,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsPaginationStyle.resolveLayers(widget.layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
          if (widget.onPressed == null) WidgetState.disabled,
        };
        final s = DsPaginationStyle.resolveLayers(widget.layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final size = s.itemSize!;
        // The drawn button keeps its own size in a taller row or cell: the
        // number is centered by an Align that hugs it, never by filling the
        // parent. Only the invisible tap area grows.
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          padding: const EdgeInsets.symmetric(horizontal: DsSpace.s4),
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: t.radii.controlCorners(s.borderRadius, size),
            shadows: [
              if (s.borderColor case final edge? when edge.a > 0)
                DsShadow.innerRing(edge),
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          // "Page 4", and the current page says so.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Semantics(
              label: l10n.page(widget.number),
              value: widget.selected ? l10n.currentPage : null,
              child: ExcludeSemantics(
                child: Text(
                  '${widget.number}',
                  style: (s.textStyle ?? const TextStyle()).copyWith(
                    color: s.foreground,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
