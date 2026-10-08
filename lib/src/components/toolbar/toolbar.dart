import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/edge_fade_scroll.dart';
import '../../behavior/focus_forward.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../overlay/anchored_overlay.dart';
import '../../overlay/placement.dart';
import '../../painting/decoration.dart';
import '../../painting/line.dart';
import '../../painting/surface.dart';
import '../../painting/shadow.dart';
import '../../theme/haptics.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../button/button.dart';
import '../button/button_style.dart';
import '../button/button_theme.dart';
import '../menu/menu.dart';
import '../tooltip/tooltip.dart';
import 'toolbar_style.dart';
import 'toolbar_toggle_style.dart';

/// What a [DsToolbar] does with items that do not fit its width.
enum DsToolbarOverflow {
  /// The items that do not fit, taken from the end, move into a menu that
  /// a "More actions" (⋯) button at the bar's end opens. The bar never
  /// scrolls and never cuts an item in half; when the room grows, the
  /// items come back.
  menu,

  /// The items keep their place and the row scrolls sideways, the edge
  /// that hides them faded. Every item stays in the bar, but on a narrow
  /// screen some are reached only by scrolling.
  scroll,
}

/// An opaque bar floating above the content. Holds
/// [DsToolbarToggle]s, icon buttons (`DsButton.icon` with the ghost
/// variant), [DsToolbarDivider]s and at most one primary button.
///
/// ```dart
/// DsToolbar(
///   children: [
///     DsToolbarToggle(icon: const DsIcon(DsIcons.bold), semanticLabel: 'Bold',
///         selected: bold, onChanged: (v) => setState(() => bold = v)),
///     const DsToolbarDivider(),
///     DsButton(variant: .primary, size: .sm, onPressed: send, child: const Text('Send')),
///   ],
/// )
/// ```
///
/// **Overflow:** by default ([DsToolbarOverflow.menu]) the items that do
/// not fit (a narrow window, large text) move, from the end, into a menu
/// opened by a "More actions" (⋯) button at the bar's end, which takes
/// their place in the bar. Each item has a menu form:
///
/// - a [DsToolbarToggle] is a menu item named by its `semanticLabel`, led
///   by its icon and checked while the toggle is on (announced as a
///   checkbox item); choosing it calls `onChanged` with the opposite
///   value;
/// - a [DsButton] is a menu item named by its text, or by its
///   `semanticLabel` when its label is not a [Text] (an icon button, whose
///   [DsIcon] leads the item). Choosing it runs `onPressed`; a danger
///   variant makes the item destructive, and a disabled or loading button
///   gives a disabled item;
/// - a [DsTooltip] around either adds its `shortcut` to the item;
/// - a [DsToolbarDivider] is a menu divider. A divider is never left at
///   the end of the bar, at either end of the menu, or doubled.
///
/// Any other item needs a [DsToolbarItem] that gives its menu form, or
/// says it has none (a "3 selected" label). A bar with a child that has no
/// menu form scrolls as with [DsToolbarOverflow.scroll], so no item ever
/// disappears: wrap custom children in [DsToolbarItem] to let them
/// collapse. [DsToolbarOverflow.scroll] keeps every item in the bar and
/// scrolls the row sideways.
///
/// **Keyboard:** every item is its own Tab stop, and Left and
/// Right (mirrored in RTL), Home and End also move focus between the items,
/// as in the WAI-ARIA toolbar pattern. Tab goes through all the items
/// before it moves on to what is beside the toolbar. The pattern's single Tab stop is not
/// used: Flutter 3.47 has no toolbar semantics role, so screen-reader users
/// would not be told that the other items are reached with arrows.
///
/// The ⋯ button is one more item, the last. Enter or Space opens its menu,
/// which has the keyboard of a [DsMenu], and focus comes back to the
/// button when the menu closes. Screen readers hear it as "More actions"
/// (from [DsLocalizations]), a button that is collapsed or expanded, as
/// every menu button is. The items in the menu leave the bar's Tab order.
class DsToolbar extends StatefulWidget {
  /// Creates a toolbar.
  const DsToolbar({
    super.key,
    required this.children,
    this.style,
    this.semanticLabel,
    this.overflow = DsToolbarOverflow.menu,
  });

  /// The items, start to end.
  final List<Widget> children;

  /// Style laid over the theme and defaults.
  final DsToolbarStyle? style;

  /// Names the toolbar for screen readers.
  final String? semanticLabel;

  /// What happens to the items that do not fit: they move into a "More
  /// actions" menu (the default), or the row scrolls. See
  /// [DsToolbarOverflow].
  ///
  /// The menu needs a menu form for every child (see [DsToolbar]). When a
  /// child has none, such as a custom widget not wrapped in a
  /// [DsToolbarItem], the bar scrolls instead, keeping every child: wrap
  /// custom children in [DsToolbarItem] to let them collapse.
  final DsToolbarOverflow overflow;

  /// Desen's default toolbar style under [theme].
  ///
  /// The corners are left unset: the bar is rounded as a control as tall
  /// as its toggles (their size from the toggle theme) and its padding, so
  /// a theme that resizes the toggles keeps the bar and its items
  /// concentric. A radius set in a style wins.
  static DsToolbarStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsToolbarStyle(
      background: k.overlay,
      shadows: theme.shadows.overlay,
      padding: const EdgeInsets.all(DsSpace.s5),
      gap: 2,
      dividerColor: k.border,
      dividerHeight: 18,
    );
  }

  @override
  State<DsToolbar> createState() => _DsToolbarState();
}

class _DsToolbarState extends State<DsToolbar> {
  /// The first item the last layout left out of the bar; null while every
  /// item shows.
  int? _hiddenFrom;

  /// Whether the last layout showed the ⋯ button.
  bool _more = false;

  final _menu = DsOverlayController();
  final _moreFocus = FocusNode(debugLabel: 'DsToolbar more');

  @override
  void dispose() {
    _menu.dispose();
    _moreFocus.dispose();
    super.dispose();
  }

  /// The bar was laid out: [hiddenFrom] is the first item it left out
  /// (null for none) and [more] whether it shows the ⋯ button. Called
  /// during layout when either changes. The items left out leave the focus
  /// order and fill the menu once the frame is done; layout never reads
  /// this, so the next layout comes out the same.
  void _onLayout(int? hiddenFrom, bool more) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (hiddenFrom == _hiddenFrom && more == _more)) return;
      final focused = _focusedItem();
      setState(() {
        _hiddenFrom = hiddenFrom;
        _more = more;
      });
      if (!more && _menu.isOpen) _menu.close();
      // The focused item left the bar: focus moves to the button that
      // now holds it.
      if (more && focused != null && focused >= (hiddenFrom ?? focused + 1)) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _more) _moreFocus.requestFocus();
        });
      }
    });
  }

  /// The index of the item that holds the primary focus, if any.
  int? _focusedItem() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || !context.mounted) return null;
    final slot = context.findAncestorWidgetOfExactType<_Slot>();
    return slot != null && slot.owner == this ? slot.index : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsToolbarStyle.resolveLayers([
      DsToolbar.defaultStyle(t),
      DsToolbarTheme.of(context).style,
      widget.style,
    ], const {});
    final toggleTheme = DsToolbarToggleTheme.of(context);
    // The items' size: the toggles' as the theme leaves it.
    final item = DsToolbarToggleStyle.resolveLayers([
      DsToolbarToggle.defaultStyle(t),
      toggleTheme.style,
    ], const {}).size!;
    final padding = s.padding ?? EdgeInsets.zero;
    final reach = math.max(0.0, (t.sizes.minTapTarget - item) / 2);
    // How far the items' visuals sit from the bar's edge: the padding, or
    // the reach of their tap areas when that is larger (see [_padding]).
    final inset = math.max(
      padding.resolve(Directionality.of(context)).top,
      reach,
    );
    // A bar of controls is rounded as a control as tall as its items and
    // their inset; the items nest in it.
    final corners = t.radii.controlCorners(s.borderRadius, item + 2 * inset);
    final nested = t.radii.nestedCorners(null, corners, inset);
    // Each child's menu form; with one that has none, the bar scrolls, so
    // that child never disappears.
    final forms = widget.overflow == DsToolbarOverflow.menu
        ? [for (final child in widget.children) _mapItem(child)]
        : null;
    final menu = forms != null && !forms.contains(null);
    final content = DsToolbarTheme(
      data: DsToolbarThemeData(style: s),
      // Toggles nest in the bar: its concentric corner, under any
      // radius the toggle theme sets.
      child: DsToolbarToggleTheme(
        data: DsToolbarToggleThemeData(
          style: DsToolbarToggleStyle(borderRadius: nested)
              .merge(toggleTheme.style),
        ),
        // Buttons in the bar are nested in it like its toggles, so
        // they take the same concentric corner, under any radius the
        // button theme sets.
        child: DsButtonTheme(
          data: DsButtonThemeData(
            style: DsButtonStyle(borderRadius: nested)
                .merge(DsButtonTheme.of(context).style),
          ),
          child: FocusStops(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: menu
                  ? _overflowRow(context, s.gap!, item, [
                      for (final f in forms) f!,
                    ])
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: s.gap!,
                      children: widget.children,
                    ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: DsSurface(
        decoration: DsBoxDecoration(
          color: s.background,
          borderRadius: corners,
          shadows: s.shadows ?? const [],
        ),
        backdropFilter: s.backdropFilter,
        child: menu
            ? Padding(padding: _padding(padding, reach), child: content)
            // Items that do not fit scroll, the edge that hides them
            // faded. The padding scrolls along, so the items' focus rings
            // in it are not clipped.
            : DsEdgeFadeScrollView(
                padding: _padding(padding, reach),
                child: content,
              ),
      ),
    );
  }

  /// The items, those that do not fit left out from the end, and the ⋯
  /// button that opens a menu of them; the button is as tall as the
  /// toggles ([item]). [forms] are the items' menu forms.
  Widget _overflowRow(
    BuildContext context,
    double gap,
    double item,
    List<List<Widget>> forms,
  ) {
    final children = widget.children;
    final n = children.length;
    final hiddenFrom = math.min(_hiddenFrom ?? n, n);
    final label = DsLocalizations.of(context).moreActions;
    return _OverflowRow(
      gap: gap,
      textDirection: Directionality.of(context),
      separators: [for (final f in forms) f.isNotEmpty && f.every(_isDivider)],
      menuless: [for (final f in forms) f.every(_isDivider)],
      onLayout: _onLayout,
      children: [
        for (var i = 0; i < n; i++)
          _Slot(
            key: switch (children[i].key) {
              final key? => ValueKey<Key>(key),
              null => null,
            },
            owner: this,
            index: i,
            hidden: i >= hiddenFrom,
            child: children[i],
          ),
        ExcludeFocus(
          key: const ValueKey(_DsToolbarState),
          excluding: !_more,
          child: DsMenuAnchor(
            controller: _menu,
            align: DsAlign.end,
            semanticLabel: label,
            items: _menuItems(forms, hiddenFrom),
            builder: (context, controller, _) => DsButton.icon(
              variant: DsButtonVariant.ghost,
              size: DsSize.sm,
              style: DsButtonStyle(height: item),
              focusNode: _moreFocus,
              icon: const DsIcon(DsIcons.ellipsis),
              semanticLabel: label,
              onPressed: controller.toggle,
            ),
          ),
        ),
      ],
    );
  }
}

bool _isDivider(Widget entry) => entry is DsMenuDivider;

/// The menu of the items from [from] on: their menu forms, with no
/// divider at either end or two in a row.
List<Widget> _menuItems(List<List<Widget>> forms, int from) {
  final result = <Widget>[];
  Widget? divider;
  for (var i = from; i < forms.length; i++) {
    for (final entry in forms[i]) {
      if (_isDivider(entry)) {
        if (result.isNotEmpty) divider ??= entry;
        continue;
      }
      if (divider != null) result.add(divider);
      divider = null;
      result.add(entry);
    }
  }
  return result;
}

/// The entries [child] stands for in the overflow menu (see [DsToolbar]),
/// or null when it has no menu form.
List<Widget>? _mapItem(Widget child, {String? shortcut}) => switch (child) {
  DsToolbarItem(:final menuItems) => menuItems,
  DsToolbarDivider() => const [DsMenuDivider()],
  DsTooltip(child: final inner, shortcut: final keys) => _mapItem(
    inner,
    shortcut: keys ?? shortcut,
  ),
  DsToolbarToggle(:final onChanged) => [
    DsMenuItem(
      label: Text(child.semanticLabel),
      leading: child.icon,
      shortcut: shortcut,
      checked: child.selected,
      checkRole: DsMenuCheckRole.checkbox,
      onPressed: onChanged == null ? null : () => onChanged(!child.selected),
    ),
  ],
  DsButton() => _buttonForm(child, shortcut),
  _ => null,
};

List<Widget>? _buttonForm(DsButton button, String? shortcut) {
  final text = button.child is Text;
  final name = button.semanticLabel;
  if (!text && name == null) return null;
  return [
    DsMenuItem(
      label: text ? button.child : Text(name!),
      // An icon button's icon leads its item.
      leading: button.leading ?? (button.child is DsIcon ? button.child : null),
      shortcut: shortcut,
      destructive:
          button.variant == DsButtonVariant.danger ||
          button.variant == DsButtonVariant.dangerSoft,
      semanticLabel: text ? name : null,
      onPressed: button.loading ? null : button.onPressed,
    ),
  ];
}

/// Gives an item of a [DsToolbar] its form in the overflow menu: the
/// entries it stands for there while it does not fit in the bar.
///
/// The toolbar knows the menu form of its toggles, buttons and dividers
/// (see [DsToolbar]); any other item needs one, or an empty [menuItems]
/// to say it has none. Wrap custom children in [DsToolbarItem] to let them
/// collapse: a bar with a child that has no menu form scrolls instead
/// ([DsToolbarOverflow.scroll]), so that child never disappears. A toggle
/// or button can take a form of its own here too, e.g. view toggles that
/// are one choice of a set:
///
/// ```dart
/// DsToolbarItem(
///   menuItems: [
///     DsMenuItem(
///       label: const Text('Grid'),
///       checked: view == 'grid',
///       onPressed: () => setState(() => view = 'grid'),
///     ),
///   ],
///   child: DsToolbarToggle(
///     icon: const DsIcon(DsIcons.layoutGrid),
///     semanticLabel: 'Grid',
///     selected: view == 'grid',
///     onChanged: (_) => setState(() => view = 'grid'),
///   ),
/// )
/// ```
///
/// With [DsToolbarOverflow.scroll] the menu form is not used.
class DsToolbarItem extends StatelessWidget {
  /// Shows [child] in the bar and [menuItems] in the overflow menu.
  const DsToolbarItem({
    super.key,
    required this.menuItems,
    required this.child,
  });

  /// The [DsMenuItem]s (submenus too) and [DsMenuDivider]s the item stands
  /// for in the overflow menu, start to end. Empty for an item that only
  /// shows something, such as "3 selected": while it does not fit, it is
  /// left out, and it never brings in the ⋯ button on its own.
  final List<Widget> menuItems;

  /// The item in the bar.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// One item of the bar; [hidden] while it is in the overflow menu, which
/// takes it out of the focus order.
class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.owner,
    required this.index,
    required this.hidden,
    required this.child,
  });

  final _DsToolbarState owner;
  final int index;
  final bool hidden;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ExcludeFocus(excluding: hidden, child: child);
}

class _OverflowParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether the child is in the bar: painted, hit and read.
  bool shown = true;
}

/// The bar's items in a row, start to end, then the ⋯ button (the last
/// child); see [_RenderOverflowRow].
class _OverflowRow extends MultiChildRenderObjectWidget {
  const _OverflowRow({
    required this.gap,
    required this.textDirection,
    required this.separators,
    required this.menuless,
    required this.onLayout,
    required super.children,
  });

  final double gap;
  final TextDirection textDirection;

  /// Per item: a divider, never left at the end of the bar.
  final List<bool> separators;

  /// Per item: it has nothing to show in the menu.
  final List<bool> menuless;

  final void Function(int? hiddenFrom, bool more) onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverflowRow(gap, textDirection, separators, menuless, onLayout);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderOverflowRow)
      ..gap = gap
      ..textDirection = textDirection
      ..separators = separators
      ..menuless = menuless
      ..onLayout = onLayout;
  }
}

/// Which items a bar shows, whether the ⋯ button shows, and its size.
typedef _Plan = ({int shown, bool more, Size size});

/// Lays the items out in a row as `Row` does (centered across, `gap`
/// apart, the row as wide as they are) while they all fit. When they do
/// not, it keeps as many as fit from the start beside the ⋯ button, less
/// dividers that would end the row, and reports where the rest begin
/// ([onLayout]). Those are laid out, to be measured, but not painted, hit
/// or read. Every item is measured at its own width in every layout, so
/// what fits depends only on the room, never on the last layout: nothing
/// jitters, and the items come back as the room grows. Only when not even
/// the button fits is the row clipped.
class _RenderOverflowRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _OverflowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _OverflowParentData> {
  _RenderOverflowRow(
    this._gap,
    this._textDirection,
    this._separators,
    this._menuless,
    this.onLayout,
  );

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  List<bool> _separators;
  set separators(List<bool> v) {
    if (listEquals(v, _separators)) return;
    _separators = v;
    markNeedsLayout();
  }

  List<bool> _menuless;
  set menuless(List<bool> v) {
    if (listEquals(v, _menuless)) return;
    _menuless = v;
    markNeedsLayout();
  }

  void Function(int? hiddenFrom, bool more) onLayout;

  /// What the last layout reported.
  (int?, bool)? _reported;

  /// Whether the shown children are wider than the bar (not even the ⋯
  /// button fits beside the first): they are clipped.
  bool _clips = false;
  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverflowParentData) {
      child.parentData = _OverflowParentData();
    }
  }

  /// The items: every child but the button.
  List<RenderBox> get _items {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null && child != lastChild) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  /// The button.
  RenderBox? get _more => lastChild;

  /// The width of the first [count] of [widths], [_gap] apart.
  double _run(List<double> widths, int count) {
    var total = count > 1 ? _gap * (count - 1) : 0.0;
    for (var i = 0; i < count; i++) {
      total += widths[i];
    }
    return total;
  }

  bool _flag(List<bool> flags, int i) => i < flags.length && flags[i];

  _Plan _plan(BoxConstraints constraints, ChildLayouter layoutChild) {
    final items = _items;
    final n = items.length;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);
    final sizes = [for (final item in items) layoutChild(item, loose)];
    final widths = [for (final s in sizes) s.width];
    final button = _more;
    final more = button == null ? Size.zero : layoutChild(button, loose);
    final room = constraints.maxWidth;
    var shown = n;
    var withMore = false;
    if (_run(widths, n) > room + precisionErrorTolerance) {
      // As many items as fit in [space], less dividers at the end.
      int fit(double space) {
        var k = n;
        while (k > 0 && _run(widths, k) > space + precisionErrorTolerance) {
          k--;
        }
        while (k > 0 && _flag(_separators, k - 1)) {
          k--;
        }
        return k;
      }

      shown = fit(room - more.width - _gap);
      for (var i = shown; i < n && !withMore; i++) {
        withMore = !_flag(_menuless, i);
      }
      // Nothing left out has a menu form: no button, and more room.
      if (!withMore) shown = fit(room);
    }
    var height = withMore ? more.height : 0.0;
    for (var i = 0; i < shown; i++) {
      height = math.max(height, sizes[i].height);
    }
    var width = _run(widths, shown);
    if (withMore) width += (shown > 0 ? _gap : 0) + more.width;
    return (
      shown: shown,
      more: withMore,
      size: constraints.constrain(Size(width, height)),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _plan(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    final size = this.size = plan.size;
    final items = _items;
    double? end;
    void place(RenderBox child, bool shown) {
      final data = child.parentData! as _OverflowParentData;
      data.shown = shown;
      if (!shown) {
        data.offset = Offset.zero;
        return;
      }
      final start = end == null ? 0.0 : end! + _gap;
      final w = child.size.width;
      final x = _textDirection == TextDirection.rtl
          ? size.width - start - w
          : start;
      data.offset = Offset(x, (size.height - child.size.height) / 2);
      end = start + w;
    }

    for (var i = 0; i < items.length; i++) {
      place(items[i], i < plan.shown);
    }
    if (_more case final more?) place(more, plan.more);
    _clips = (end ?? 0) > size.width + precisionErrorTolerance;
    final report = (plan.shown < items.length ? plan.shown : null, plan.more);
    if (report != _reported) {
      _reported = report;
      onLayout(report.$1, report.$2);
    }
  }

  /// The children in the bar, start to end.
  List<RenderBox> get _shown {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _OverflowParentData;
      if (data.shown) list.add(child);
      child = data.nextSibling;
    }
    return list;
  }

  // At its narrowest the bar is the button alone.
  @override
  double computeMinIntrinsicWidth(double height) => math.min(
    computeMaxIntrinsicWidth(height),
    _more?.getMaxIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final items = _items;
    return _run([
      for (final item in items) item.getMaxIntrinsicWidth(height),
    ], items.length);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest((child) => child.getMinIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest((child) => child.getMaxIntrinsicHeight(double.infinity));

  double _tallest(double Function(RenderBox) measure) {
    var tallest = 0.0;
    for (final item in _items) {
      tallest = math.max(tallest, measure(item));
    }
    return tallest;
  }

  void _paintShown(PaintingContext context, Offset offset) {
    for (final child in _shown) {
      final data = child.parentData! as _OverflowParentData;
      context.paintChild(child, data.offset + offset);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_clips) {
      _clip.layer = null;
      _paintShown(context, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintShown,
      oldLayer: _clip.layer,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _shown.reversed) {
      final data = child.parentData! as _OverflowParentData;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      _shown.forEach(visitor);

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

/// [padding] less the [reach] of the items' tap areas past their visuals:
/// on a phone each 44px tap area reaches into the padding instead of
/// making the bar taller, so the bar keeps its desktop size and only the
/// items' spacing grows.
EdgeInsetsGeometry _padding(EdgeInsetsGeometry padding, double reach) {
  if (reach == 0) return padding;
  return padding
      .subtract(EdgeInsets.all(reach))
      .clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity);
}

/// Arrow keys, Home and End move focus between the toolbar's items.
KeyEventResult _onKey(FocusNode toolbar, KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  final key = event.logicalKey;
  final keys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
  };
  final focused = FocusManager.instance.primaryFocus;
  if (!keys.contains(key) || focused == null) return KeyEventResult.ignored;
  final items = toolbar.traversalDescendants.toList();
  if (items.isEmpty) return KeyEventResult.ignored;
  final context = toolbar.context;
  final rtl =
      context != null && Directionality.of(context) == TextDirection.rtl;
  // Visual order, start to end.
  items.sort((a, b) => a.rect.center.dx.compareTo(b.rect.center.dx));
  if (rtl) items.setAll(0, items.reversed.toList());
  final i = items.indexWhere(
    (n) => n == focused || focused.ancestors.contains(n),
  );
  if (i < 0) return KeyEventResult.ignored;
  final forward = rtl
      ? LogicalKeyboardKey.arrowLeft
      : LogicalKeyboardKey.arrowRight;
  final next = switch (key) {
    LogicalKeyboardKey.home => 0,
    LogicalKeyboardKey.end => items.length - 1,
    _ when key == forward => (i + 1) % items.length,
    _ => (i - 1 + items.length) % items.length,
  };
  items[next].requestFocus();
  // An item scrolled out of a bar too narrow for them comes into view.
  if (items[next].context case final item?) {
    Scrollable.ensureVisible(
      item,
      alignmentPolicy: next > i
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }
  return KeyEventResult.handled;
}

/// A thin vertical line between groups in a [DsToolbar].
class DsToolbarDivider extends StatelessWidget {
  /// Creates a divider.
  const DsToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final s = DsToolbarStyle.resolveLayers([
      DsToolbar.defaultStyle(t),
      DsToolbarTheme.of(context).style,
    ], const {});
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.s4),
      child: SizedBox(
        height: s.dividerHeight!,
        child: DsLine(
          color: s.dividerColor ?? const Color(0x00000000),
          axis: Axis.vertical,
        ),
      ),
    );
  }
}

/// An on/off icon button for a [DsToolbar] (bold, italic…). The pressed
/// state takes the theme's selection style and is announced as toggled.
class DsToolbarToggle extends StatefulWidget {
  /// Creates a toolbar toggle.
  const DsToolbarToggle({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.selected,
    required this.onChanged,
    this.style,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  });

  /// Usually a [DsIcon].
  final Widget icon;

  /// What the toggle does ("Bold"); icon-only controls need a name.
  final String semanticLabel;

  /// Whether the toggle is on.
  final bool selected;

  /// Called with the new value. Null disables the toggle.
  final ValueChanged<bool>? onChanged;

  /// Style laid over the theme and defaults.
  final DsToolbarToggleStyle? style;

  /// Observe or force interaction states (hovered, focused, pressed).
  final WidgetStatesController? statesController;

  /// Focus node; one is created when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Desen's default toolbar toggle style under [theme].
  ///
  /// The corners are left unset: in a [DsToolbar] the toggle nests in the
  /// bar, concentric with its corners; on its own it is rounded as a
  /// control of its size. A radius set in a style wins.
  static DsToolbarToggleStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsToolbarToggleStyle(
      size: theme.sizes.sm,
      background: const Color(0x00000000),
      shadows: const [],
      foreground: k.textMuted,
      iconSize: 16,
      focusShadows: theme.focusShadows,
      hovered: DsToolbarToggleStyle(background: k.hover, foreground: k.text),
      pressed: DsToolbarToggleStyle(background: k.press),
      selected: DsToolbarToggleStyle(
        background: theme.selectedFill,
        shadows: [
          if (theme.selectedEdge case final edge?) DsShadow.innerRing(edge),
        ],
        foreground: theme.onSelectedFill,
        // Hover stays visible on a selected item.
        hovered: DsToolbarToggleStyle(background: theme.selectedHoverFill),
      ),
      disabled: DsToolbarToggleStyle(foreground: k.onDisabled),
    );
  }

  @override
  State<DsToolbarToggle> createState() => _DsToolbarToggleState();
}

class _DsToolbarToggleState extends State<DsToolbarToggle> {
  Set<WidgetState>? _lastStates;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final layers = [
      DsToolbarToggle.defaultStyle(t),
      DsToolbarToggleTheme.of(context).style,
      widget.style,
    ];
    return DsPressable(
      statesController: widget.statesController,
      onPressed: widget.onChanged == null
          ? null
          : () => widget.onChanged!(!widget.selected),
      haptic: DsHapticEvent.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      toggled: widget.selected,
      semanticLabel: widget.semanticLabel,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) =>
            DsToolbarToggleStyle.resolveLayers(layers, states).cursor ??
            DsPressable.defaultCursor.resolve(states),
      ),
      builder: (context, interaction, _) {
        final states = {
          ...interaction,
          if (widget.selected) WidgetState.selected,
        };
        final s = DsToolbarToggleStyle.resolveLayers(layers, states);
        final animate = _lastStates != null && !setEquals(_lastStates, states);
        _lastStates = states;
        final size = s.size!;
        return AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: t.radii.controlCorners(s.borderRadius, size),
            shadows: [
              ...?s.shadows,
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: s.foreground, size: s.iconSize),
            child: widget.icon,
          ),
        );
      },
    );
  }
}
