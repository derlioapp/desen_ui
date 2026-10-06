import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../behavior/tap_band.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../menu/menu.dart';
import '../pane_header/pane_header.dart';
import 'breadcrumb_style.dart';

/// What a [DsBreadcrumb] does when its path is wider than the space.
enum DsBreadcrumbOverflow {
  /// The path wraps onto more lines; a separator stays with the level
  /// before it, so no line starts with one.
  wrap,

  /// The path stays on one line: the middle levels collapse into a "…"
  /// button that lists them in a menu (the first level and as many of the
  /// last as fit stay), and the current page is ellipsized when it alone
  /// does not fit.
  collapse,
}

/// One level of a [DsBreadcrumb].
@immutable
class DsBreadcrumbItem {
  /// Creates an item. The last item of a breadcrumb is the current page and
  /// is not pressable.
  const DsBreadcrumbItem({required this.label, this.icon, this.onPressed});

  /// The level's name.
  final String label;

  /// An icon before the label, e.g. a house on the first level, usually a
  /// `DsIcon`. It takes the label's color and the style's `iconSize`, and
  /// is decoration: screen readers hear the [label].
  final Widget? icon;

  /// Navigates to the level.
  final VoidCallback? onPressed;
}

/// A path of pages: upper levels in muted ink and pressable, the current
/// page in full ink, chevrons between (mirrored in RTL).
///
/// Each upper level is a link and a Tab stop, activated by a click, a tap
/// or Enter (not Space, as in browsers). [focusNode] stands for the
/// whole path: it has focus while a level does, and focusing it (or
/// [autofocus]) focuses the first level.
///
/// A path wider than its space wraps, or keeps to one line by collapsing
/// its middle levels into a "…" menu button ([overflow]), as in a
/// [DsPaneHeader] title. The "…" button is a Tab stop named "More levels"
/// (localized) and opens a menu of the hidden levels.
class DsBreadcrumb extends StatelessWidget {
  /// Creates a breadcrumb.
  const DsBreadcrumb({
    super.key,
    required this.items,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.overflow,
    this.style,
  });

  /// The levels, top first; the last one is the current page.
  final List<DsBreadcrumbItem> items;

  /// Focus node for the path; one is created when null. See the class docs.
  final FocusNode? focusNode;

  /// Whether to focus the first level when first built.
  final bool autofocus;

  /// Names the navigation for screen readers. Defaults to the localized
  /// "Breadcrumb".
  final String? semanticLabel;

  /// Wrap or collapse when the path is wider than its space. Null
  /// collapses where text keeps to one line (the ambient
  /// [DefaultTextStyle.maxLines] is 1, as in a [DsPaneHeader] title) and
  /// wraps elsewhere.
  final DsBreadcrumbOverflow? overflow;

  /// Style laid over the theme and defaults.
  final DsBreadcrumbStyle? style;

  /// Desen's default breadcrumb style under [theme].
  static DsBreadcrumbStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsBreadcrumbStyle(
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s4, vertical: 2),
      background: const Color(0x00000000),
      foreground: k.textMuted,
      textStyle: theme.typography.label.copyWith(fontWeight: FontWeight.w400),
      // A crumb is a line of text with a little padding: a control of
      // that height.
      borderRadius: BorderRadius.circular(theme.radii.control(20)),
      separatorColor: k.textSubtle,
      separatorSize: 14,
      gap: DsSpace.s4,
      iconSize: theme.sizes.iconXs,
      iconGap: DsSpace.s4,
      focusShadows: theme.focusShadows,
      hovered: DsBreadcrumbStyle(background: k.hover, foreground: k.text),
      // The current page.
      selected: DsBreadcrumbStyle(
        foreground: k.text,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final layers = [
      defaultStyle(t),
      DsBreadcrumbTheme.of(context).style,
      style,
    ];
    final base = DsBreadcrumbStyle.resolveLayers(layers, const {});
    final gap = base.gap ?? 0;
    final collapse = switch (overflow) {
      DsBreadcrumbOverflow.collapse => true,
      DsBreadcrumbOverflow.wrap => false,
      null => DefaultTextStyle.of(context).maxLines == 1,
    };

    Widget separator() => ExcludeSemantics(
      child: DsIcon(
        DsIcons.chevronRight,
        size: base.separatorSize,
        color: base.separatorColor,
      ),
    );

    // A level and the separator after it are one piece, so a wrapped path
    // never starts a line with a separator.
    // In a bounded width (a wrapping path) a long level may wrap itself.
    Widget withSeparator(Widget level, {bool bounded = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        if (bounded) Flexible(child: level) else level,
        separator(),
      ],
    );

    Widget current({required bool fit}) {
      final item = items.last;
      final s = DsBreadcrumbStyle.resolveLayers(layers, const {
        WidgetState.selected,
      });
      // The current page says so (aria-current).
      return Semantics(
        container: true,
        label: item.label,
        value: l10n.currentPage,
        excludeSemantics: true,
        child: Padding(
          padding: s.padding ?? EdgeInsets.zero,
          child: _label(item, s, fit: fit),
        ),
      );
    }

    Widget link(DsBreadcrumbItem item) => _Level(
      layers: layers,
      onPressed: item.onPressed,
      isLink: true,
      builder: (s) => _label(item, s),
    );

    Widget wrap() => Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final item in items.take(items.length - 1))
          withSeparator(link(item), bounded: true),
        if (items.isNotEmpty) current(fit: false),
      ],
    );

    Widget line(BoxConstraints constraints) {
      final n = items.length;
      if (n == 0) return const SizedBox();
      final hidden = _hidden(context, layers, constraints.maxWidth);
      // One line never wraps, so levels and separators are flat children:
      // the "…" tap band then reaches over the separators on both sides.
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: [
          for (var i = 0; i < n - 1; i++)
            if (!hidden.contains(i)) ...[
              link(items[i]),
              separator(),
            ] else if (i == hidden.first) ...[
              _MoreLevels(
                layers: layers,
                iconSize: base.separatorSize,
                items: [for (final h in hidden) items[h]],
              ),
              separator(),
            ],
          if (constraints.hasBoundedWidth)
            Flexible(child: current(fit: true))
          else
            current(fit: true),
        ],
      );
    }

    return Semantics(
      container: true,
      role: SemanticsRole.navigation,
      label: semanticLabel ?? l10n.breadcrumb,
      explicitChildNodes: true,
      child: FocusForward(
        focusNode: focusNode,
        autofocus: autofocus,
        child: collapse
            ? LayoutBuilder(builder: (context, c) => line(c))
            : wrap(),
      ),
    );
  }

  /// A level's label in [s], after its icon when it has one. The icon is
  /// an inline span, so a long label wraps or ellipsizes as plain text
  /// does.
  static Widget _label(
    DsBreadcrumbItem item,
    DsBreadcrumbStyle s, {
    bool fit = false,
  }) {
    final style = (s.textStyle ?? const TextStyle()).copyWith(
      color: s.foreground,
    );
    final icon = item.icon;
    return Text.rich(
      TextSpan(
        children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: s.iconGap ?? 0),
                child: ExcludeSemantics(
                  child: IconTheme.merge(
                    data: IconThemeData(color: s.foreground, size: s.iconSize),
                    child: icon,
                  ),
                ),
              ),
            ),
          TextSpan(text: item.label),
        ],
      ),
      maxLines: fit ? 1 : null,
      softWrap: !fit,
      overflow: fit ? TextOverflow.ellipsis : null,
      style: style,
    );
  }

  /// The levels (indices) collapsed into "…" so the path fits [maxWidth]
  /// on one line: the middle ones first, keeping the first level and as
  /// many of the last as fit; when even "first › … › current" does not
  /// fit, the first level too. The current page is never hidden; it is
  /// ellipsized when it alone does not fit.
  List<int> _hidden(
    BuildContext context,
    List<DsBreadcrumbStyle?> layers,
    double maxWidth,
  ) {
    final n = items.length;
    if (n < 2 || !maxWidth.isFinite) return const [];
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final ambient = DefaultTextStyle.of(context).style;
    final link = DsBreadcrumbStyle.resolveLayers(layers, const {});
    final selected = DsBreadcrumbStyle.resolveLayers(layers, const {
      WidgetState.selected,
    });
    final gap = link.gap ?? 0;
    double textWidth(String text, DsBreadcrumbStyle s) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: ambient.merge(s.textStyle)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    double pad(DsBreadcrumbStyle s) =>
        (s.padding ?? EdgeInsets.zero).resolve(direction).horizontal;
    // A leading icon and the space after it.
    double icon(DsBreadcrumbItem item, DsBreadcrumbStyle s) =>
        item.icon == null ? 0 : (s.iconSize ?? 0) + (s.iconGap ?? 0);
    // A level with its separator and the gaps around it.
    final after = gap + (link.separatorSize ?? 0) + gap;
    final widths = [
      for (var i = 0; i < n - 1; i++)
        pad(link) +
            icon(items[i], link) +
            textWidth(items[i].label, link) +
            after,
      pad(selected) +
          icon(items.last, selected) +
          textWidth(items.last.label, selected),
    ];
    final more = pad(link) + (link.separatorSize ?? 0) + after;
    // Rounding slack, as the text layout rounds up.
    bool fits(double w) => w <= maxWidth + .5;
    if (fits(widths.fold(0.0, (a, b) => a + b))) return const [];
    // first › … › levels k..n-1, with k as small as fits.
    for (var k = 2; k < n; k++) {
      final w = widths[0] + more + widths.sublist(k).fold(0.0, (a, b) => a + b);
      if (fits(w)) return [for (var i = 1; i < k; i++) i];
    }
    // first › … › current did not fit: … › current.
    if (n == 2) return const [];
    return [for (var i = 0; i < n - 1; i++) i];
  }
}

/// A pressable level of the path: muted, with hover and focus.
class _Level extends StatefulWidget {
  const _Level({
    required this.layers,
    required this.onPressed,
    required this.builder,
    this.isLink = false,
    this.semanticLabel,
    this.minTapTarget,
  });

  final List<DsBreadcrumbStyle?> layers;
  final VoidCallback? onPressed;

  /// The content in the resolved style of the current states.
  final Widget Function(DsBreadcrumbStyle style) builder;
  final bool isLink;
  final String? semanticLabel;

  /// Overrides the pressable's minimum tap target.
  final double? minTapTarget;

  @override
  State<_Level> createState() => _LevelState();
}

class _LevelState extends State<_Level> {
  // A link takes Enter only, as in browsers: Space belongs to the page
  // (it scrolls). The node sees keys before the pressable and stops
  // Space there, so neither the pressable nor an ancestor shortcut acts
  // on it. The "…" button is a button and keeps Space.
  late final _node = FocusNode(
    debugLabel: 'DsBreadcrumb level',
    onKeyEvent: (node, event) =>
        widget.isLink && event.logicalKey == LogicalKeyboardKey.space
        ? KeyEventResult.skipRemainingHandlers
        : KeyEventResult.ignored,
  );

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = widget.layers;
    return DsPressable(
      onPressed: widget.onPressed,
      focusNode: _node,
      isButton: !widget.isLink,
      isLink: widget.isLink,
      semanticLabel: widget.semanticLabel,
      minTapTarget: widget.minTapTarget,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsBreadcrumbStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, states, _) {
        final s = DsBreadcrumbStyle.resolveLayers(layers, states);
        return AnimatedContainer(
          duration: t.motion.toneDuration,
          curve: t.motion.toneCurve,
          padding: s.padding,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: s.borderRadius ?? BorderRadius.zero,
            shadows: [
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: widget.builder(s),
        );
      },
    );
  }
}

/// The "…" level that stands for the collapsed levels: a button that opens
/// a menu of them (WAI-ARIA menu button, announced expanded or collapsed).
class _MoreLevels extends StatelessWidget {
  const _MoreLevels({
    required this.layers,
    required this.iconSize,
    required this.items,
  });

  final List<DsBreadcrumbStyle?> layers;
  final double? iconSize;
  final List<DsBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = DsLocalizations.of(context);
    // An icon-only level would grow to the tap target and push the
    // separators away from it; its taps reach the target without growing
    // the layout, so "…" sits like any other level. The band is outermost,
    // so the row asks it directly.
    return TapBand(
      size: DsTheme.sizesOf(context).minTapTarget,
      child: DsMenuAnchor(
        semanticLabel: l10n.breadcrumbMore,
        items: [
          for (final item in items)
            DsMenuItem(
              leading: item.icon,
              label: Text(item.label),
              onPressed: item.onPressed,
            ),
        ],
        builder: (context, controller, _) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Semantics(
            expanded: controller.isOpen,
            child: _Level(
              layers: layers,
              onPressed: controller.toggle,
              semanticLabel: l10n.breadcrumbMore,
              minTapTarget: 0,
              builder: (s) =>
                  DsIcon(DsIcons.ellipsis, size: iconSize, color: s.foreground),
            ),
          ),
        ),
      ),
    );
  }
}
