import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../behavior/focus_forward.dart';
import '../../behavior/focus_visibility.dart';
import '../../foundation/case.dart';
import '../../behavior/pressable.dart';
import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../painting/decoration.dart';
import '../../painting/numeric_span.dart';
import '../../painting/shadow.dart';
import '../../painting/shape.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import '../empty_state/empty_state.dart';
import '../empty_state/empty_state_style.dart';
import '../../overlay/anchored_overlay.dart';
import '../../overlay/placement.dart';
import '../menu/menu.dart';
import '../selection/checkbox.dart';
import '../badge/badge.dart';
import '../badge/badge_style.dart';
import '../button/button.dart';
import '../button/button_theme.dart';
import '../../theme/status.dart';
import '../skeleton/skeleton.dart';
import 'table_column.dart';
import 'table_style.dart';

export 'table_column.dart';

/// How many rows an intrinsic column measures.
const _measureSample = 200;

/// A data table: a sticky header with sort buttons, rows that select with
/// a soft fill, numbers in tabular figures and end-aligned, a loading skeleton and an
/// empty state.
///
/// ```dart
/// DsTable<Invoice>(
///   semanticLabel: 'Faturalar',
///   rows: invoices,
///   rowKey: (i) => i.id,
///   columns: [
///     DsTableColumn(id: 'customer', label: 'Müşteri', value: (i) => i.customer, sortable: true),
///     DsTableColumn(id: 'status', label: 'Durum', cell: (_, i) => StatusBadge(i.status)),
///     DsTableColumn(id: 'amount', label: 'Tutar', value: (i) => i.amount,
///         text: (i) => money(i.amount), numeric: true, sortable: true),
///   ],
///   sort: sort,
///   onSortChanged: (s) => setState(() => sort = s),
///   selected: selected,
///   onSelectionChanged: (s) => setState(() => selected = s),
///   onRowPressed: open,
/// )
/// ```
///
/// **Anatomy.** A surface card holding a header row and the rows. With
/// [onSelectionChanged] a checkbox column leads, with a tri-state
/// "select all" in the header. Rows are separated by hairlines.
///
/// **Sorting.** A [DsTableColumn.sortable] header is a button that cycles
/// ascending → descending → unsorted; the sorted header shows an arrow.
/// The sort is controlled ([sort], [onSortChanged]); with [sortLocally] the
/// table also orders [rows] itself (stable, by the column's comparator or
/// value). Without [onSortChanged] the headers are plain labels. The order
/// is worked out once and kept until the rows, the sort or the language
/// change, so a rebuild costs nothing; see [columns] and [rows] for what
/// counts as a change.
///
/// **Selection.** Controlled by [selected] (row keys, see [rowKey]) and
/// [onSelectionChanged]. Selection follows the item, not its position, so
/// it survives sorting and new data. "Select all" covers [rows] and keeps
/// keys of rows not in them (other pages). Shift-click selects a range
/// from the row last clicked or toggled with Space, its anchor; Shift with
/// the arrow keys does too, and moving back toward the anchor shrinks the
/// range, as in a file list.
///
/// **Size.** In a bounded height the header stays put while the rows scroll
/// under it, and rows are built lazily, so 10,000 rows scroll smoothly. In
/// an unbounded height (a [Column], a scroll view) the table is as tall as
/// its rows and builds them all: page long data ([DsPagination]). When the
/// columns' minimum widths do not fit, the table scrolls sideways.
///
/// **Narrow tables.** By default a narrow table keeps its columns and
/// scrolls sideways, with a fade at the edge hiding columns. With
/// `layout: const .auto()` it shows one card per row below 480 px (or with
/// `.cards()` always): each column on a "label  value" line, and a bar
/// above with "select all" and a "Sort by" menu button that lists the
/// sortable columns (one line at any width). Everything else works as in
/// rows.
///
/// **Row actions.** [rowMenuBuilder] gives each row a context menu (right
/// click, long press, Shift+F10, the Menu key); [showRowMenuButton] also
/// shows a "⋯" button at the end of each row that opens it.
///
/// **States.** [loading] with no rows shows skeleton rows; with rows, one
/// skeleton row at the end ("loading more"). No rows shows [emptyView] (a
/// compact "No results" by default); [errorView] replaces the rows. These
/// slots get a compact [DsEmptyState] theme, so an app's own
/// [DsEmptyState] fits in.
///
/// **Keyboard** (row navigation; WAI-ARIA grid in row mode):
///
/// | Key | Action |
/// |---|---|
/// | Tab | Sort buttons and "select all", then one stop for the rows (the last active row), then the active row's own buttons |
/// | ↑ / ↓ | Previous / next row; with Shift, extends the range from the anchor row to it (back toward the anchor, shrinks it) |
/// | Home / End | First / last row |
/// | Page Up / Page Down | A screenful up / down |
/// | Space | Selects or deselects the row |
/// | Enter | [onRowPressed]; without it, Space's action |
/// | Ctrl/⌘ + A | Selects every row |
/// | Shift + F10, Menu | Opens the row's menu ([rowMenuBuilder]) |
///
/// **Screen readers** hear a table (named by [semanticLabel], with its row
/// count) of rows and cells, or a list of cards; column headers carry their
/// sort direction, selected rows are announced as selected, and each row's
/// checkbox is named by the row's first text cell ("Select Kuzey
/// Lojistik"), as is the "⋯" row menu button ("Actions for Kuzey
/// Lojistik"). Loading, "No results" and errors are polite live regions,
/// and a changed row count (after a filter) is said once the rows settle.
class DsTable<T> extends StatefulWidget {
  /// Creates a table.
  const DsTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.rowsVersion,
    this.layout = const DsTableLayout.rows(),
    this.sort,
    this.onSortChanged,
    this.sortLocally = true,
    this.selected = const {},
    this.onSelectionChanged,
    this.onRowPressed,
    this.rowMenuBuilder,
    this.showRowMenuButton = false,
    this.loading = false,
    this.loadingRowCount = 5,
    this.emptyView,
    this.errorView,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.scrollController,
    this.style,
  }) : assert(columns.length > 0, 'A table needs at least one column'),
       assert(loadingRowCount > 0),
       assert(
         !showRowMenuButton || rowMenuBuilder != null,
         'showRowMenuButton opens rowMenuBuilder',
       );

  /// The columns, in reading order.
  ///
  /// Build them inline or keep them in a field, either is cheap: the table
  /// knows a column by its [DsTableColumn.id], not by the list or its
  /// closures. So a column keeps its id only while it shows and sorts the
  /// same way; when what a column sorts by changes, give it a new id (or
  /// change [rowsVersion]).
  final List<DsTableColumn<T>> columns;

  /// The data, one row per item.
  ///
  /// The table sorts and measures again when the rows change: a new list
  /// with other rows, or a row replaced in place (`rows[i] = updated`).
  /// Rows are compared by identity, one check per row, so passing the same
  /// rows again (a filter rebuilt inline) costs nothing. A field changed
  /// inside a mutable item cannot be seen: change [rowsVersion] then.
  final List<T> rows;

  /// Rows of cells (the default), or one card per row, always or below a
  /// breakpoint ([DsTableLayout.auto]): see the class docs.
  final DsTableLayout layout;

  /// Tells the table that the rows changed inside: change it (a counter, a
  /// timestamp) after editing a field of a mutable item in place, and the
  /// table sorts and measures again. Not needed for immutable items or a
  /// new list (see [rows]).
  final Object? rowsVersion;

  /// A stable identity for each item, e.g. its database id. Selection,
  /// hover and focus follow it, so they stay with the item when the rows
  /// are sorted or replaced. Keys must be unique.
  final Object Function(T item) rowKey;

  /// The sorted column, or null for the rows' own order.
  final DsTableSort? sort;

  /// Called with the next sort when a sortable header is pressed; null when
  /// the user returns the column to unsorted. Null makes the headers plain
  /// labels.
  final ValueChanged<DsTableSort?>? onSortChanged;

  /// Orders [rows] by [sort] inside the table. Turn off when the rows come
  /// sorted (e.g. from a server).
  final bool sortLocally;

  /// The keys ([rowKey]) of the selected rows.
  final Set<Object> selected;

  /// Called with the new selection. Non-null adds the checkbox column and
  /// makes rows selectable by click, Space and Shift-click.
  final ValueChanged<Set<Object>>? onSelectionChanged;

  /// Called when a row is clicked, tapped or activated with Enter. Without
  /// it, a click selects the row (when selectable).
  final ValueChanged<T>? onRowPressed;

  /// Builds the context menu of the row showing `item`: [DsMenuItem]s and
  /// [DsMenuDivider]s, opened by right click, long press, Shift+F10 or the
  /// Menu key. `context` is the menu's. Needs an `Overlay` above the table,
  /// like every menu.
  final List<Widget> Function(BuildContext context, T item)? rowMenuBuilder;

  /// Adds a trailing column with a "⋯" button on every row (or card) that
  /// opens [rowMenuBuilder]'s menu below it, so the row's actions are
  /// visible, not only on right click. The button is named with the row
  /// ("Actions for Kuzey Lojistik") and, like the row's other controls, is
  /// in the Tab order of the active row. Needs [rowMenuBuilder].
  final bool showRowMenuButton;

  /// Data is loading: skeleton rows (see the class docs).
  final bool loading;

  /// How many skeleton rows show while [loading] with no rows.
  final int loadingRowCount;

  /// Shown when there are no rows, e.g. a [DsEmptyState] with a "clear
  /// filters" action. Defaults to a compact localized "No results".
  final Widget? emptyView;

  /// Shown instead of the rows when loading failed, e.g. a [DsEmptyState]
  /// with a retry action. Non-null puts the table in the error state.
  final Widget? errorView;

  /// Names the table for screen readers ("Faturalar").
  final String? semanticLabel;

  /// Focus node for the table; one is created when null. It is not a Tab
  /// stop of its own: it has focus while anything in the table does, and
  /// focusing it focuses the active row (the rows' one Tab stop).
  final FocusNode? focusNode;

  /// Whether to focus the active row when first built.
  final bool autofocus;

  /// Scrolls the rows in a bounded height; one is created when null.
  final ScrollController? scrollController;

  /// Style laid over the theme and defaults.
  final DsTableStyle? style;

  /// Desen's default table style under [theme].
  static DsTableStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    final type = theme.typography;
    const clear = Color(0x00000000);
    return DsTableStyle(
      background: k.surface,
      shadows: theme.shadows.surface,
      borderRadius: BorderRadius.circular(theme.radii.card),
      headerHeight: theme.sizes.listRow - DsSpace.s4,
      headerStyle: type.caption.copyWith(
        fontWeight: FontWeight.w500,
        color: k.textSubtle,
      ),
      headerActiveColor: k.text,
      sortIconSize: 12,
      rowHeight: theme.sizes.listRow,
      rowBackground: clear,
      textStyle: type.body.copyWith(color: k.text),
      numericStyle: type.numeric(type.small),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DsSpace.s12,
        vertical: DsSpace.s4,
      ),
      columnGap: DsSpace.s12,
      minColumnWidth: 96,
      // The checkbox's tap area fits: 44 on touch.
      selectionColumnWidth: math.max(36, theme.sizes.minTapTarget),
      dividerColor: k.border,
      // The compact empty state: a small icon without the tone disk.
      emptyStateStyle: DsEmptyStateStyle(
        padding: const EdgeInsets.all(DsSpace.s20),
        iconBoxSize: 20,
        iconBoxColor: clear,
        iconColor: k.textSubtle,
        iconSize: 20,
        titleStyle: type.bodyStrong.copyWith(color: k.text),
        descriptionStyle: type.caption.copyWith(color: k.textMuted),
        gap: DsSpace.s8,
      ),
      // Inside the row: rows run edge to edge in a clipped card.
      focusShadows: [DsShadow.innerRing(k.focus, width: 2)],
      hovered: DsTableStyle(rowBackground: k.hover),
      pressed: DsTableStyle(rowBackground: k.press),
      // Always the soft pair, whatever the theme's selection style: a
      // strong fill would recolor every cell and badge (as the multi-select's tags).
      // Hover and keyboard focus take one visible step. The row's
      // checkbox carries the state too.
      selected: DsTableStyle(
        rowBackground: k.selection,
        hovered: DsTableStyle(rowBackground: k.selectionHover),
        pressed: DsTableStyle(rowBackground: k.selectionHover),
      ),
    );
  }

  @override
  State<DsTable<T>> createState() => _DsTableState<T>();
}

/// Marks the "loading more" skeleton row's key.
const _loadingKey = _LoadingKey();

class _LoadingKey {
  const _LoadingKey();
}

class _DsTableState<T> extends State<DsTable<T>> {
  ScrollController? _ownVertical;
  ScrollController get _vertical =>
      widget.scrollController ?? (_ownVertical ??= ScrollController());
  final _horizontal = ScrollController();

  /// The row that holds the table's one Tab stop.
  Object? _active;

  /// Where a Shift range starts: the row last clicked or toggled.
  Object? _anchor;

  /// Where the last Shift range from [_anchor] ended. The next one from
  /// the same anchor replaces it, so moving back toward the anchor
  /// shrinks the range.
  Object? _rangeEnd;

  /// Built rows by key.
  final _rows = <Object, _TableRowState>{};

  // The rows as last seen, one by one: a replaced row, a new row or a
  // version change bumps the generation; the same rows in a new list (a
  // filter rebuilt inline) do not.
  List<T> _seenRows = const [];
  Object? _seenVersion;
  int _generation = 0;

  // The sorted rows, their keys and each key's place, cached by what
  // decides the order (see DsTable.columns): the rows' generation, the
  // sorted column's id and direction, and the language. Never by the
  // columns list itself, which an app usually builds inline.
  Object? _sortedFor;
  List<T> _sorted = const [];
  List<Object> _keys = const [];
  Map<Object, int> _indexOf = const {};

  /// The height of every data row: the style's row height, grown to one
  /// line of cell text at the current text scale.
  double _extent = 0;

  // Measured intrinsic widths by column id, cached while the rows, the
  // text scale and the styles stay the same, and while the column's own
  // label and width stay the same.
  Object? _measuredFor;
  final _measured = <Object, (Object, double)>{};

  /// A selection handed to onSelectionChanged in this frame. The app's
  /// answer arrives with the next build, so a second key press in the same
  /// frame builds on this one instead of on the stale [DsTable.selected].
  Set<Object>? _pendingSelection;

  @override
  void dispose() {
    _countTimer?.cancel();
    _ownVertical?.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  bool get _selectable => widget.onSelectionChanged != null;

  bool get _interactive => _selectable || widget.onRowPressed != null;

  Object _keyOf(T item) => widget.rowKey(item);

  /// The selection to build the next one on.
  Set<Object> get _selection => _pendingSelection ?? widget.selected;

  // ---- Data ---------------------------------------------------------------

  /// Whether [DsTable.rows] holds other rows than last time; one identity
  /// check per row, so it is cheap at any size.
  bool _rowsChanged() {
    final rows = widget.rows;
    final seen = _seenRows;
    var changed =
        rows.length != seen.length || widget.rowsVersion != _seenVersion;
    for (var i = 0; !changed && i < rows.length; i++) {
      changed = !identical(rows[i], seen[i]);
    }
    if (changed) {
      _seenRows = List<T>.of(rows, growable: false);
      _seenVersion = widget.rowsVersion;
      _generation++;
    }
    return changed;
  }

  void _sortRows() {
    final w = widget;
    final language = Localizations.maybeLocaleOf(context)?.languageCode;
    final changed = _rowsChanged();
    final sort = w.sort;
    final column = sort == null || !w.sortLocally
        ? null
        : w.columns
              .where((c) => c.id == sort.columnId && c.sortable)
              .firstOrNull;
    final key = (
      _generation,
      column == null ? null : sort,
      column?.comparator != null,
      language,
    );
    if (!changed && key == _sortedFor) return;
    _sortedFor = key;
    _sorted = column == null
        ? _seenRows
        : _order(_seenRows, column, sort!.ascending, language);
    _keys = [for (final item in _sorted) _keyOf(item)];
    _indexOf = {for (var i = 0; i < _keys.length; i++) _keys[i]: i};
    assert(
      _indexOf.length == _sorted.length,
      'DsTable.rowKey must give every row a unique key',
    );
  }

  /// [rows] ordered by [column]: stable (equal rows keep their order), empty
  /// values last in both directions. Each row's value and its collation key
  /// are worked out once, not once per comparison.
  static List<T> _order<T>(
    List<T> rows,
    DsTableColumn<T> column,
    bool ascending,
    String? language,
  ) {
    final sign = ascending ? 1 : -1;
    final order = List<int>.generate(rows.length, (i) => i);
    final comparator = column.comparator;
    if (comparator != null) {
      order.sort((i, j) {
        final c = sign * comparator(rows[i], rows[j]);
        return c != 0 ? c : i - j;
      });
    } else {
      final value = column.value!;
      final keys = [
        for (final item in rows) _SortValue.of(value(item), language),
      ];
      order.sort((i, j) {
        final a = keys[i], b = keys[j];
        final int c;
        if (a == null || b == null) {
          c = a == null ? (b == null ? 0 : 1) : -1;
        } else {
          c = sign * a.compareTo(b);
        }
        return c != 0 ? c : i - j;
      });
    }
    return [for (final i in order) rows[i]];
  }

  /// The active row's key: the last one used, or, when it is gone, the
  /// first row on screen (so Tab lands where the user is looking).
  Object? _resolveActive() {
    if (_active != null && _indexOf.containsKey(_active)) return _active;
    if (_sorted.isEmpty) return null;
    var best = _sorted.length;
    for (final key in _rows.keys) {
      final i = _indexOf[key];
      if (i != null && i < best) best = i;
    }
    return _keys[best == _sorted.length ? 0 : best];
  }

  /// The name of a row's checkbox: "Select" and the row's first text cell
  /// ("Select Kuzey Lojistik"), so a screen reader's list of checkboxes
  /// tells the rows apart.
  String _rowName(T item, DsLocalizations l10n) => switch (_rowText(item)) {
    final name? => l10n.selectRowNamed(name),
    null => l10n.tableSelectRow,
  };

  /// The row's first text cell, or null when it has none.
  String? _rowText(T item) {
    for (final c in widget.columns) {
      if (c.text == null && c.value == null) continue;
      final name = c.textOf(item).trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  bool get _menuButton =>
      widget.showRowMenuButton && widget.rowMenuBuilder != null;

  /// The "⋯" button that opens the row menu of [key].
  Widget _rowMenuButton(Object key, T item, DsLocalizations l10n) => Builder(
    builder: (context) => DsButton.icon(
      variant: DsButtonVariant.ghost,
      size: DsSize.xs,
      semanticExpanded: _rows[key]?._menu?.isOpen ?? false,
      semanticLabel: switch (_rowText(item)) {
        final name? => l10n.rowActionsFor(name),
        null => l10n.rowActions,
      },
      onPressed: () {
        _setActive(key);
        _rows[key]?.openMenuBelow(context);
      },
      icon: const DsIcon(DsIcons.ellipsis),
    ),
  );

  // ---- Announcements ------------------------------------------------------

  /// The row count last said (or first seen); null before any rows.
  int? _countSaid;
  Timer? _countTimer;

  /// How long the count waits for the rows to settle, so typing in a
  /// filter says the count once.
  // ds-raw: a pause in speech, as the autocomplete count
  static const _countDelay = Duration(milliseconds: 600);

  /// Says the row count when it changes, e.g. after a filter: politely and
  /// once the rows have settled. Loading, "No results" and errors are
  /// live regions of their own (see [_message], [_skeleton]).
  void _watchCount() {
    if (_state != _BodyState.rows || widget.loading) return;
    final count = _sorted.length;
    if (_countSaid == null) {
      // The first rows are what the table opens with, not a change.
      _countSaid = count;
      return;
    }
    if (count == _countSaid) {
      _countTimer?.cancel();
      return;
    }
    _countTimer?.cancel();
    _countTimer = Timer(_countDelay, () {
      if (!mounted || _state != _BodyState.rows || widget.loading) return;
      final count = _sorted.length;
      if (count == _countSaid) return;
      _countSaid = count;
      if (!MediaQuery.supportsAnnounceOf(context)) return;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          DsLocalizations.of(context).rowCount(count),
          Directionality.of(context),
        ),
      );
    });
  }

  // ---- Selection ----------------------------------------------------------

  void _setSelection(Set<Object> next) {
    final changed = widget.onSelectionChanged;
    if (changed == null) return;
    if (_pendingSelection == null) {
      // Forget it once the frame is done: by then the app has answered
      // (or ignored it, and the table shows its own selection again).
      SchedulerBinding.instance
        ..addPostFrameCallback((_) => _pendingSelection = null)
        ..ensureVisualUpdate();
    }
    _pendingSelection = next;
    changed(next);
  }

  void _toggle(Object key) {
    if (!_selectable) return;
    _anchor = key;
    _rangeEnd = null;
    final next = {..._selection};
    if (!next.remove(key)) next.add(key);
    _setSelection(next);
  }

  /// Selects (or, when the anchor row is not selected, deselects) every row
  /// from the anchor to [key], like a file list. A range selected before
  /// from the same anchor gives way to the new one: rows it held past [key]
  /// are deselected. [select] decides instead of the anchor row's state.
  void _selectRange(Object key, {bool? select}) {
    final from = _indexOf[_anchor];
    final to = _indexOf[key];
    if (from == null || to == null) return _toggle(key);
    final selection = _selection;
    final on = select ?? selection.contains(_anchor);
    final next = {...selection};
    final end = on ? _indexOf[_rangeEnd] : null;
    if (end != null) {
      for (var i = math.min(from, end); i <= math.max(from, end); i++) {
        next.remove(_keys[i]);
      }
    }
    for (var i = math.min(from, to); i <= math.max(from, to); i++) {
      on ? next.add(_keys[i]) : next.remove(_keys[i]);
    }
    _rangeEnd = key;
    _setSelection(next);
  }

  /// Select-all: all of [DsTable.rows], keeping keys from elsewhere. Counts
  /// over the smaller of the selection and the rows.
  bool? _allStateOf(Set<Object> selection) {
    if (_sorted.isEmpty) return false;
    var count = 0;
    if (selection.length < _indexOf.length) {
      for (final key in selection) {
        if (_indexOf.containsKey(key)) count++;
      }
    } else {
      for (final key in _keys) {
        if (selection.contains(key)) count++;
      }
    }
    if (count == 0) return false;
    return count == _keys.length ? true : null;
  }

  void _toggleAll() {
    final next = {..._selection};
    _allStateOf(next) == true ? next.removeAll(_keys) : next.addAll(_keys);
    _setSelection(next);
  }

  void _selectAll() => _setSelection({..._selection, ..._keys});
  // ---- Rows ---------------------------------------------------------------

  void _setActive(Object key) {
    if (_active == key) return;
    setState(() => _active = key);
  }

  void _onRowPressed(T item) {
    final key = _keyOf(item);
    _setActive(key);
    if (_selectable &&
        _anchor != null &&
        HardwareKeyboard.instance.isShiftPressed) {
      _selectRange(key);
    } else if (widget.onRowPressed != null) {
      widget.onRowPressed!(item);
    } else {
      _toggle(key);
    }
  }

  void _onCheckbox(Object key) {
    _setActive(key);
    if (_anchor != null && HardwareKeyboard.instance.isShiftPressed) {
      _selectRange(key);
    } else {
      _toggle(key);
    }
  }

  Object? get _focusedRow {
    final primary = FocusManager.instance.primaryFocus;
    for (final MapEntry(:key, :value) in _rows.entries) {
      if (identical(value.node, primary)) return key;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = _focusedRow;
    final index = key == null ? null : _indexOf[key];
    if (key == null || index == null) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final shift = keyboard.isShiftPressed;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final last = _sorted.length - 1;
    final k = event.logicalKey;
    int? target;
    if (k == LogicalKeyboardKey.arrowDown) {
      target = index + 1;
    } else if (k == LogicalKeyboardKey.arrowUp) {
      target = index - 1;
    } else if (k == LogicalKeyboardKey.home) {
      target = 0;
    } else if (k == LogicalKeyboardKey.end) {
      target = last;
    } else if (k == LogicalKeyboardKey.pageDown) {
      target = index + _pageRows();
    } else if (k == LogicalKeyboardKey.pageUp) {
      target = index - _pageRows();
    }
    if (target != null) {
      target = target.clamp(0, last);
      if (shift && _selectable && target != index) {
        // The range runs from the anchor to the row focus lands on, and
        // selects; without an anchor it starts at the focused row.
        if (_indexOf[_anchor] == null) {
          _anchor = key;
          _rangeEnd = null;
        }
        _selectRange(_keys[target], select: true);
      }
      _moveTo(target, down: target >= index);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space && _selectable) {
      _toggle(key);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (!_interactive) return KeyEventResult.ignored;
      final item = _sorted[index];
      widget.onRowPressed != null ? widget.onRowPressed!(item) : _toggle(key);
      return KeyEventResult.handled;
    }
    if ((k == LogicalKeyboardKey.f10 && shift) ||
        k == LogicalKeyboardKey.contextMenu) {
      if (widget.rowMenuBuilder == null) return KeyEventResult.ignored;
      _rows[key]?.openMenu();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyA && command && _selectable) {
      _selectAll();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Rows in one screenful, for Page Up / Page Down.
  int _pageRows() {
    if (!_vertical.hasClients || _extent <= 0) return 1;
    return math.max(1, _vertical.position.viewportDimension ~/ _extent - 1);
  }

  /// Scrolls the row with [key] into view when it gains focus. A row kept
  /// alive off screen (the active one, reached with Tab after scrolling
  /// away) has no place in the viewport for `ensureVisible`, but rows are
  /// one height, so its place is its index.
  void _reveal(Object key) {
    final i = _indexOf[key];
    if (i == null || !_vertical.hasClients) return;
    final p = _vertical.position;
    final top = i * _extent;
    final bottom = top + _extent;
    double? to;
    if (top < p.pixels) {
      to = top;
    } else if (bottom > p.pixels + p.viewportDimension) {
      to = bottom - p.viewportDimension;
    }
    if (to != null) p.jumpTo(to.clamp(p.minScrollExtent, p.maxScrollExtent));
  }

  void _moveTo(int index, {required bool down}) {
    setState(() => _active = _keys[index]);
    _focusRow(index, down: down);
  }

  /// Focuses the row at [index], first scrolling it into view when it is
  /// not built yet (rows are lazy). Rows are one height, so its place is
  /// known without building the rows before it.
  void _focusRow(int index, {required bool down, bool retry = true}) {
    if (!mounted || index >= _sorted.length) return;
    final row = _rows[_keys[index]];
    final position = _vertical.hasClients ? _vertical.position : null;
    if (row != null && row.mounted) {
      row.node.requestFocus();
      final box = row.context.findRenderObject();
      if (box == null || !box.attached) return;
      if (position != null) {
        position.ensureVisible(
          box,
          alignmentPolicy: down
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      } else {
        // Unbounded: an outer scroll view shows it.
        box.showOnScreen();
      }
      return;
    }
    if (position == null || !retry) return;
    final top = index * _extent;
    final offset = down ? top + _extent - position.viewportDimension : top;
    position.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusRow(index, down: down, retry: false),
    );
  }

  // ---- Layout -------------------------------------------------------------

  List<DsTableStyle?> _layers(DsThemeData t) => [
    DsTable.defaultStyle(t),
    DsTableTheme.of(context).style,
    widget.style,
  ];

  double _textWidth(String text, TextStyle style, TextScaler scaler) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      // Laid out as the cell shows it (see [_cell]).
      text: numericSpan(text, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double _lineHeight(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      // ds-raw: measures one line's height, never painted
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Column widths for [available] (infinite in an unbounded parent).
  List<double> _columnWidths(
    DsTableStyle s,
    double available,
    TextScaler scaler,
    double chrome,
  ) {
    final columns = widget.columns;
    final cellStyle = s.textStyle ?? const TextStyle();
    // Not keyed by the columns list (usually built inline): each column's
    // width is kept under its id while its label and width stay the same.
    final measureKey = (
      _generation,
      scaler,
      cellStyle,
      s.numericStyle,
      s.headerStyle,
      Localizations.maybeLocaleOf(context),
    );
    if (measureKey != _measuredFor) {
      _measuredFor = measureKey;
      _measured.clear();
    }
    double minAt100(DsTableColumnWidth w) => w.min ?? s.minColumnWidth ?? 0;

    // The measured width of column i's header and sampled cells.
    double measured(int i) {
      final c = columns[i];
      final signature = (c.label, c.numeric, c.sortable, c.width);
      final cached = _measured[c.id];
      final width = cached != null && cached.$1 == signature
          ? cached.$2
          : _measure(c, s, cellStyle, scaler);
      _measured[c.id] = (signature, width);
      return width;
    }

    final widths = List<double>.filled(columns.length, 0);
    final flexible = <int>[];
    for (var i = 0; i < columns.length; i++) {
      final w = columns[i].width;
      if (w.isFixed) {
        widths[i] = scaler.scale(w.width!);
      } else if (w.isFlex) {
        flexible.add(i);
      } else {
        widths[i] = measured(i);
      }
    }
    final others = widths.fold(0.0, (a, b) => a + b);

    // Large text never cuts a flex column's text that shows whole at 100%:
    // the column keeps the width its sampled text needs, up to its width
    // at 100% grown by the text scale. When that does not fit, the table
    // scrolls sideways, as a page zoomed in a browser does (WCAG 1.4.4).
    final fontSize = cellStyle.fontSize;
    final factor = fontSize == null
        ? scaler.scale(1)
        : scaler.scale(fontSize) / fontSize;
    final keep = <int, double>{};
    if (available.isFinite && factor > 1 && flexible.isNotEmpty) {
      // The 100% layout, near enough: the other columns at their width
      // over the factor.
      final at100 = _flexWidths(
        flexible,
        available - chrome - others / factor,
        minAt100,
      );
      for (final i in flexible) {
        keep[i] = math.min(measured(i), at100[i]! * factor);
      }
    }
    // An unbounded table gives its flex columns their minimum.
    final flex = _flexWidths(
      flexible,
      available.isFinite ? available - chrome - others : 0.0,
      (w) => scaler.scale(minAt100(w)),
      floor: keep,
    );
    for (final i in flexible) {
      widths[i] = flex[i]!;
    }
    return widths;
  }

  /// Shares [space] among the [flexible] columns (indices) by their flex,
  /// none narrower than [minOf] its width or its [floor].
  Map<int, double> _flexWidths(
    List<int> flexible,
    double space,
    double Function(DsTableColumnWidth) minOf, {
    Map<int, double> floor = const {},
  }) {
    final columns = widget.columns;
    double least(int i) => math.max(minOf(columns[i].width), floor[i] ?? 0);
    final widths = <int, double>{};
    var pending = [...flexible];
    while (pending.isNotEmpty) {
      final total = pending.fold(0.0, (a, i) => a + columns[i].width.flex!);
      final under = [
        for (final i in pending)
          if (space * columns[i].width.flex! / total < least(i)) i,
      ];
      if (under.isEmpty) {
        for (final i in pending) {
          widths[i] = space * columns[i].width.flex! / total;
        }
        break;
      }
      for (final i in under) {
        widths[i] = least(i);
        space -= widths[i]!;
      }
      pending = [
        for (final i in pending)
          if (!under.contains(i)) i,
      ];
    }
    return widths;
  }

  /// The width an intrinsic column needs: its header and the cell texts of
  /// the first rows.
  double _measure(
    DsTableColumn<T> c,
    DsTableStyle s,
    TextStyle cellStyle,
    TextScaler scaler,
  ) {
    final w = c.width;
    final style = c.numeric ? cellStyle.merge(s.numericStyle) : cellStyle;
    var width = _textWidth(c.label, s.headerStyle ?? cellStyle, scaler);
    if (c.sortable) width += DsSpace.s4 + s.sortIconSize!;
    if (c.text != null || c.value != null) {
      final rows = _seenRows;
      final n = math.min(rows.length, _measureSample);
      for (var r = 0; r < n; r++) {
        width = math.max(width, _textWidth(c.textOf(rows[r]), style, scaler));
      }
    }
    // A pixel of slack against subpixel rounding.
    // ds-raw: rounding slack
    width = width.ceilToDouble() + 1;
    final min = w.min == null ? 0.0 : scaler.scale(w.min!);
    final max = w.max == null ? double.infinity : scaler.scale(w.max!);
    return width.clamp(min, math.max(min, max));
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final layers = _layers(t);
    final s = DsTableStyle.resolveLayers(layers, const {});
    _badges = _opaqueBadges(t, s);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    _sortRows();
    _active = _resolveActive();
    _watchCount();

    final padding = (s.padding ?? EdgeInsets.zero).resolve(direction);
    final padStart = direction == TextDirection.ltr
        ? padding.left
        : padding.right;
    // The row menu button column takes the end padding's place, as the
    // checkbox column takes the start's.
    final padEnd = _menuButton
        ? s.selectionColumnWidth!
        : direction == TextDirection.ltr
        ? padding.right
        : padding.left;
    final lead = _selectable ? s.selectionColumnWidth! : padStart;
    final cellStyle = s.textStyle ?? const TextStyle();
    final line = math.max(
      _lineHeight(cellStyle, scaler),
      _lineHeight(cellStyle.merge(s.numericStyle), scaler),
    );
    // Whole pixels, so dividers and fills stay crisp.
    final rowExtent = math
        .max(s.rowHeight ?? 0, line + padding.vertical)
        .ceilToDouble();
    final headerExtent = math
        .max(
          s.headerHeight ?? 0,
          _lineHeight(cellStyle.merge(s.headerStyle), scaler) +
              padding.vertical,
        )
        .ceilToDouble();
    final gap = s.columnGap ?? 0;
    final chrome = lead + padEnd + gap * (widget.columns.length - 1);

    final table = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight.isFinite;
        final cards = widget.layout.showsCards(constraints.maxWidth);
        final _Geometry geometry;
        final double width;
        if (cards) {
          final card = _cardGeometry(
            s,
            scaler,
            line: line,
            available: constraints.maxWidth - lead - padEnd,
          );
          _extent = card.extent;
          width = constraints.maxWidth;
          geometry = _Geometry(
            widths: const [],
            lead: lead,
            padEnd: padEnd,
            gap: gap,
            vertical: EdgeInsets.zero,
            header: headerExtent,
            card: card,
          );
        } else {
          _extent = rowExtent;
          final widths = _columnWidths(s, constraints.maxWidth, scaler, chrome);
          final contentWidth = widths.fold(chrome, (a, b) => a + b);
          width = constraints.maxWidth.isFinite
              ? math.max(constraints.maxWidth, contentWidth)
              : contentWidth;
          geometry = _Geometry(
            widths: widths,
            lead: lead,
            padEnd: padEnd,
            gap: gap,
            vertical: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
            header: headerExtent,
          );
        }

        final header = cards
            ? _cardHeader(t, s, l10n, geometry)
            : _header(t, s, l10n, geometry);
        final count = _bodyCount();
        Widget body;
        if (bounded) {
          body = Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: _onKey,
            child: Scrollable(
              controller: _vertical,
              // The table node lists the rows itself; a scroll node in
              // between would break the table → row → cell structure.
              excludeFromSemantics: true,
              viewportBuilder: (context, offset) => Viewport(
                offset: offset,
                slivers: [
                  if (_state case _BodyState.empty || _BodyState.error)
                    SliverToBoxAdapter(
                      child: _bodyRow(context, 0, t, s, l10n, geometry),
                    )
                  else
                    SliverFixedExtentList(
                      itemExtent: _extent,
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _bodyRow(context, i, t, s, l10n, geometry),
                        childCount: count,
                        // An index node would sit between table and row.
                        addSemanticIndexes: false,
                        findChildIndexCallback: (key) {
                          final value = (key as ValueKey<Object>).value;
                          if (value == _loadingKey) return _sorted.length;
                          return _indexOf[value];
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          body = Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onKeyEvent: _onKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < count; i++)
                  _bodyRow(context, i, t, s, l10n, geometry),
              ],
            ),
          );
        }

        Widget named(Widget child, SemanticsRole role) => Semantics(
          container: true,
          explicitChildNodes: true,
          role: role,
          label: widget.semanticLabel,
          hint: _sorted.isEmpty ? null : l10n.rowCount(_sorted.length),
          // The rows' own scroll node is left out (see above), so the
          // table offers the scroll actions for screen readers.
          onScrollUp: bounded ? () => _scrollBy(1) : null,
          onScrollDown: bounded ? () => _scrollBy(-1) : null,
          child: child,
        );

        Widget table;
        if (cards) {
          // Cards are a list of items, not rows of cells: the sort and
          // select-all bar stands before the list, outside it.
          body = named(body, SemanticsRole.list);
          table = Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              if (bounded) Expanded(child: body) else body,
            ],
          );
        } else {
          table = named(
            Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                if (bounded) Expanded(child: body) else body,
              ],
            ),
            SemanticsRole.table,
          );
        }
        final radius = s.borderRadius ?? BorderRadius.zero;
        return DecoratedBox(
          decoration: DsBoxDecoration(
            color: s.background,
            borderRadius: radius,
            shadows: s.shadows ?? const [],
          ),
          child: DsShapeClip(
            borderRadius: radius.resolve(direction),
            child: cards
                // Cards fit the width: nothing to scroll sideways.
                ? SizedBox(
                    width: width,
                    height: bounded ? constraints.maxHeight : null,
                    child: table,
                  )
                : _fade(
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontal,
                      child: SizedBox(
                        width: width,
                        height: bounded ? constraints.maxHeight : null,
                        child: table,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
    return FocusForward(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocused: _focusActive,
      child: table,
    );
  }

  /// Focuses the active row, the rows' one Tab stop.
  void _focusActive() {
    final i = _active == null ? null : _indexOf[_active];
    if (i != null) _focusRow(i, down: true);
  }

  // ---- Cards --------------------------------------------------------------

  /// Where the lines of a card go: a label column as wide as the widest
  /// label (at most two fifths of the card), then the values.
  _CardGeometry _cardGeometry(
    DsTableStyle s,
    TextScaler scaler, {
    required double line,
    required double available,
  }) {
    final labelStyle = (s.textStyle ?? const TextStyle()).merge(s.headerStyle);
    var label = 0.0;
    for (final c in widget.columns) {
      label = math.max(label, _textWidth(c.label, labelStyle, scaler));
    }
    // A line holds a text line and a badge-high cell with a little air.
    final lineExtent = (line + DsSpace.s4).ceilToDouble();
    const pad = DsSpace.s12;
    return _CardGeometry(
      line: lineExtent,
      pad: pad,
      labelWidth: math.min(label.ceilToDouble(), math.max(0, available) * .4),
      gap: DsSpace.s12,
      extent: pad * 2 + lineExtent * widget.columns.length,
    );
  }

  /// The bar above the cards: "select all" and the sort menu; null
  /// when the table has neither.
  Widget? _cardHeader(
    DsThemeData t,
    DsTableStyle s,
    DsLocalizations l10n,
    _Geometry g,
  ) {
    final sortable = [
      if (widget.onSortChanged != null)
        for (final c in widget.columns)
          if (c.sortable) c,
    ];
    if (!_selectable && sortable.isEmpty) return null;
    return Container(
      constraints: BoxConstraints(minHeight: g.header),
      decoration: DsBoxDecoration(
        shadows: [
          if (s.dividerColor != null)
            DsShadow.bottomLine(s.dividerColor!, hairline: true),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: s.headerStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: Row(
          children: [
            SizedBox(
              width: g.lead,
              child: _selectable
                  ? Center(child: _selectAllBox(l10n, card: true))
                  : null,
            ),
            // The box's visible label; a click on it toggles too, as on a
            // web <label>. Screen readers hear the box's own name.
            if (_selectable) ...[
              ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _selectAllEnabled ? _toggleAll : null,
                  child: MouseRegion(
                    cursor: _selectAllEnabled
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: Text(
                      l10n.selectAll,
                      style: TextStyle(
                        color: _selectAllEnabled ? s.headerActiveColor : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: sortable.isEmpty
                  ? const SizedBox()
                  : Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _sortMenu(l10n, sortable),
                    ),
            ),
            SizedBox(width: g.padEnd),
          ],
        ),
      ),
    );
  }

  /// One card: each column on a line, its label before its value.
  Widget _card(
    DsTableStyle s,
    _Geometry g,
    T item, {
    required Widget? lead,
    required bool active,
    Widget? trail,
  }) {
    final card = g.card!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: g.lead,
          // The box sits on the first line; its tap area may reach into
          // the card's padding.
          height: card.pad * 2 + card.line,
          child: lead == null ? null : Center(child: lead),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: card.pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in widget.columns)
                  Semantics(
                    container: true,
                    child: SizedBox(
                      height: card.line,
                      child: Row(
                        spacing: card.gap,
                        children: [
                          SizedBox(
                            width: card.labelWidth,
                            child: Text(
                              c.label,
                              style: s.headerStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ExcludeFocus(
                                excluding: !active,
                                child: _cell(s, c, item, card: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The row menu button, on the first line like the checkbox.
        SizedBox(
          width: g.padEnd,
          height: card.pad * 2 + card.line,
          child: trail == null ? null : Center(child: trail),
        ),
      ],
    );
  }

  /// Whether columns are hidden before or after the horizontal viewport.
  bool _moreBefore = false, _moreAfter = false;
  final _scrollerKey = GlobalKey();

  bool _onMetrics(ScrollMetrics m) {
    if (m.axis != Axis.horizontal) return false;
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

  /// Fades the edges that hide columns, so a wide table reads as
  /// scrollable sideways (as the tab bar does).
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

  static const _fadeWidth = DsSpace.s24;

  /// Screen reader paging: scrolls a screenful (forward when [pages] > 0).
  void _scrollBy(int pages) {
    if (!_vertical.hasClients) return;
    final p = _vertical.position;
    p.jumpTo(
      (p.pixels + pages * p.viewportDimension * 0.9).clamp(
        p.minScrollExtent,
        p.maxScrollExtent,
      ),
    );
  }

  _BodyState get _state {
    if (widget.errorView != null) return _BodyState.error;
    if (widget.rows.isEmpty) {
      return widget.loading ? _BodyState.loading : _BodyState.empty;
    }
    return _BodyState.rows;
  }

  int _bodyCount() => switch (_state) {
    _BodyState.error || _BodyState.empty => 1,
    _BodyState.loading => widget.loadingRowCount,
    _BodyState.rows => _sorted.length + (widget.loading ? 1 : 0),
  };

  Widget _bodyRow(
    BuildContext context,
    int i,
    DsThemeData t,
    DsTableStyle s,
    DsLocalizations l10n,
    _Geometry g,
  ) {
    switch (_state) {
      case _BodyState.error:
        return _message(s, g, widget.errorView!, key: 'error');
      case _BodyState.empty:
        return _message(
          s,
          g,
          widget.emptyView ??
              DsEmptyState(
                icon: const DsIcon(DsIcons.searchX),
                title: Text(l10n.tableNoResults),
              ),
          key: 'empty',
        );
      case _BodyState.loading:
        return _skeleton(s, g, i, label: i == 0 ? l10n.loading : null);
      case _BodyState.rows:
        if (i == _sorted.length) {
          return _skeleton(s, g, i, label: l10n.loading, key: _loadingKey);
        }
    }
    final item = _sorted[i];
    final key = _keyOf(item);
    final selected = widget.selected.contains(key);
    // The row takes Space; the box is for the pointer and for screen
    // readers, not a Tab stop of its own.
    final box = _selectable
        ? ExcludeFocus(
            child: DsCheckbox(
              value: selected,
              onChanged: (_) => _onCheckbox(key),
              semanticLabel: _rowName(item, l10n),
            ),
          )
        : null;
    return _TableRow(
      key: ValueKey<Object>(key),
      rowKey: key,
      table: this,
      active: key == _active,
      selected: selected,
      divider: i > 0,
      card: g.card != null,
      interactive: _interactive,
      layers: _layers(t),
      extent: _extent,
      onPressed: () => _onRowPressed(item),
      menuItems: widget.rowMenuBuilder == null
          ? null
          : (context) => widget.rowMenuBuilder!(context, item),
      builder: (context, active) => g.card != null
          ? _card(
              s,
              g,
              item,
              lead: box,
              trail: _menuButton
                  ? ExcludeFocus(
                      excluding: !active,
                      child: _rowMenuButton(key, item, l10n),
                    )
                  : null,
              active: active,
            )
          : _cells(
              s,
              g,
              lead: box,
              trail: _menuButton
                  ? ExcludeFocus(
                      excluding: !active,
                      child: _rowMenuButton(key, item, l10n),
                    )
                  : null,
              // Only the active row's own controls are in the Tab order.
              cells: [
                for (final c in widget.columns)
                  ExcludeFocus(excluding: !active, child: _cell(s, c, item)),
              ],
              cellRole: SemanticsRole.cell,
            ),
    );
  }

  /// Badge colors for cells, see [_opaqueBadges].
  DsBadgeThemeData _badges = const DsBadgeThemeData();

  /// Badges in cells keep their own look whatever the row's fill.
  /// Their tints are see-through, so over a selected or hovered row they
  /// took on the row's color (a warning badge turned olive on the soft
  /// selection). Here each tint is laid over the table's surface first,
  /// which is what an unselected row shows.
  DsBadgeThemeData _opaqueBadges(DsThemeData t, DsTableStyle s) {
    final outer = DsBadgeTheme.of(context);
    var under = s.background ?? t.colors.surface;
    if (under.a < 1) under = Color.alphaBlend(under, t.colors.surface);
    return DsBadgeThemeData(
      statuses: {
        for (final status in DsStatus.values)
          if (DsBadgeStyle.resolveLayers([
                DsBadge.defaultStyle(t, status: status),
                outer.style,
                outer.statuses[status],
              ], const {}).background
              case final tint? when tint.a < 1)
            status: DsBadgeStyle(background: Color.alphaBlend(tint, under)),
      },
    );
  }

  /// A cell's content. In a [card] text keeps to the reading start, after
  /// its label.
  Widget _cell(
    DsTableStyle s,
    DsTableColumn<T> c,
    T item, {
    bool card = false,
  }) {
    final style = c.numeric ? s.numericStyle : null;
    if (c.cell != null) {
      return DefaultTextStyle.merge(
        style: style,
        child: DsBadgeTheme(
          data: _badges,
          child: Builder(builder: (context) => c.cell!(context, item)),
        ),
      );
    }
    // Tabular digits, proportional separators: "12.480,00".
    return Text.rich(
      numericSpan(c.textOf(item), style: style),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: card ? TextAlign.start : _textAlign(c),
    );
  }

  static TextAlign _textAlign(DsTableColumn<Object?> c) =>
      switch (c.effectiveAlignment) {
        DsTableCellAlignment.start => TextAlign.start,
        DsTableCellAlignment.center => TextAlign.center,
        DsTableCellAlignment.end => TextAlign.end,
      };

  static AlignmentDirectional _align(DsTableColumn<Object?> c) =>
      switch (c.effectiveAlignment) {
        DsTableCellAlignment.start => AlignmentDirectional.centerStart,
        DsTableCellAlignment.center => AlignmentDirectional.center,
        DsTableCellAlignment.end => AlignmentDirectional.centerEnd,
      };

  /// A row of cells laid out on the column widths.
  Widget _cells(
    DsTableStyle s,
    _Geometry g, {
    required List<Widget> cells,
    required SemanticsRole cellRole,
    Widget? lead,
    Widget? trail,
  }) {
    final columns = widget.columns;
    // The checkbox's tap area is the row's height, so it takes no
    // vertical padding: a 44px touch target fits a 48px row.
    return Row(
      children: [
        SizedBox(
          width: g.lead,
          child: lead == null
              ? null
              : Semantics(
                  container: true,
                  role: cellRole,
                  child: Center(child: lead),
                ),
        ),
        for (var i = 0; i < columns.length; i++) ...[
          if (i > 0) SizedBox(width: g.gap),
          SizedBox(
            width: g.widths[i],
            child: Semantics(
              container: true,
              role: cellRole,
              // A sort button takes the cell's padding inside it, so the
              // whole header height answers its taps.
              child: cells[i] is _SortButton
                  ? Align(alignment: _align(columns[i]), child: cells[i])
                  : Padding(
                      padding: g.vertical,
                      child: Align(
                        alignment: _align(columns[i]),
                        child: cells[i],
                      ),
                    ),
            ),
          ),
        ],
        SizedBox(
          width: g.padEnd,
          child: trail == null
              ? null
              : Semantics(
                  container: true,
                  role: cellRole,
                  child: Center(child: trail),
                ),
        ),
      ],
    );
  }

  bool get _selectAllEnabled => _sorted.isNotEmpty && _state == _BodyState.rows;

  /// The tri-state "select all" box of the header, or of the cards' bar
  /// ([card]), where it is named like its visible label.
  Widget _selectAllBox(DsLocalizations l10n, {bool card = false}) => DsCheckbox(
    tristate: true,
    value: _allStateOf(widget.selected),
    onChanged: _selectAllEnabled ? (_) => _toggleAll() : null,
    semanticLabel: card ? l10n.selectAll : l10n.tableSelectAll,
  );

  /// Among cards, sorting is one menu button, so the bar keeps one line at
  /// any width: it shows the sorted column and its direction, and its menu
  /// lists the sortable columns. Choosing one sorts as its header would
  /// (ascending → descending → unsorted).
  Widget _sortMenu(DsLocalizations l10n, List<DsTableColumn<T>> sortable) {
    final sort = widget.sort;
    DsTableColumn<T>? sorted;
    for (final c in sortable) {
      if (c.id == sort?.columnId) sorted = c;
    }
    final direction = sorted == null ? null : sort!.direction;
    DsIconData? arrow(DsTableSortDirection? d) => switch (d) {
      DsTableSortDirection.ascending => DsIcons.arrowUp,
      DsTableSortDirection.descending => DsIcons.arrowDown,
      null => null,
    };
    final said = switch (direction) {
      DsTableSortDirection.ascending => l10n.sortedAscending,
      DsTableSortDirection.descending => l10n.sortedDescending,
      null => null,
    };
    return DsMenuAnchor(
      align: DsAlign.end,
      semanticLabel: l10n.sortBy,
      items: [
        for (final c in sortable)
          DsMenuItem(
            label: Text(c.label),
            checked: c == sorted,
            trailing: c == sorted ? DsIcon(arrow(direction)!) : null,
            onPressed: () => widget.onSortChanged!(_nextSort(c)),
          ),
      ],
      // Sorted, a muted "Sort by" before the button says what it is; the
      // button's own name says it to screen readers.
      builder: (context, controller, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: DsSpace.s4,
        children: [
          if (sorted != null)
            Flexible(child: ExcludeSemantics(child: Text(l10n.sortBy))),
          Flexible(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => DsButton(
                variant: DsButtonVariant.ghost,
                size: DsSize.sm,
                semanticExpanded: controller.isOpen,
                semanticLabel: [l10n.sortBy, ?sorted?.label, ?said].join(', '),
                trailing: DsIcon(arrow(direction) ?? DsIcons.chevronDown),
                onPressed: controller.toggle,
                child: Text(sorted?.label ?? l10n.sortBy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(
    DsTableStyle s,
    DsTableColumn<T> c, {
    bool card = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) => _SortButton(
    label: c.label,
    padding: padding,
    alignment: card ? AlignmentDirectional.centerStart : _align(c),
    textAlign: card ? TextAlign.start : _textAlign(c),
    direction: widget.sort?.columnId == c.id ? widget.sort!.direction : null,
    style: s,
    onPressed: () => widget.onSortChanged!(_nextSort(c)),
  );

  Widget _header(
    DsThemeData t,
    DsTableStyle s,
    DsLocalizations l10n,
    _Geometry g,
  ) {
    final sortable = widget.onSortChanged != null;
    return Semantics(
      container: true,
      role: SemanticsRole.row,
      child: Container(
        height: g.header,
        decoration: DsBoxDecoration(
          shadows: [
            if (s.dividerColor != null)
              DsShadow.bottomLine(s.dividerColor!, hairline: true),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: s.headerStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: _cells(
            s,
            g,
            cellRole: SemanticsRole.columnHeader,
            lead: _selectable ? _selectAllBox(l10n) : null,
            trail: _menuButton
                ? Semantics(label: l10n.rowActions, child: const SizedBox())
                : null,
            cells: [
              for (final c in widget.columns)
                sortable && c.sortable
                    ? _sortButton(s, c, padding: g.vertical)
                    : Text(c.label, textAlign: _textAlign(c)),
            ],
          ),
        ),
      ),
    );
  }

  /// Ascending → descending → unsorted.
  DsTableSort? _nextSort(DsTableColumn<T> c) {
    final current = widget.sort;
    if (current?.columnId != c.id) return DsTableSort(c.id);
    return current!.ascending
        ? DsTableSort(c.id, DsTableSortDirection.descending)
        : null;
  }

  /// A row (or, among cards, an item) and cell around [child], for the
  /// loading, empty and error states.
  Widget _stateNode({
    required bool card,
    required Widget child,
    String? label,
    Key? key,
  }) => Semantics(
    key: key,
    container: true,
    role: card ? null : SemanticsRole.row,
    child: Semantics(
      container: true,
      role: card ? null : SemanticsRole.cell,
      label: label,
      // Said when it shows, politely: "Loading", "No results", the error.
      liveRegion: true,
      child: child,
    ),
  );

  Widget _message(
    DsTableStyle s,
    _Geometry g,
    Widget child, {
    required String key,
  }) => _stateNode(
    key: ValueKey<Object>(key),
    card: g.card != null,
    child: DsEmptyStateTheme(
      data: DsEmptyStateThemeData(style: s.emptyStateStyle),
      child: Center(child: child),
    ),
  );

  Widget _skeleton(
    DsTableStyle s,
    _Geometry g,
    int i, {
    String? label,
    Object? key,
  }) {
    final columns = widget.columns;
    final card = g.card;
    Widget line(AlignmentGeometry alignment, double factor) =>
        FractionallySizedBox(
          widthFactor: factor,
          alignment: alignment,
          child: const DsSkeleton(),
        );
    Widget row = Container(
      height: _extent,
      decoration: DsBoxDecoration(
        shadows: [
          if (i > 0 && s.dividerColor != null)
            DsShadow.topLine(s.dividerColor!, hairline: true),
        ],
      ),
      child: DsShimmer(
        child: card != null
            ? Padding(
                padding: EdgeInsetsDirectional.only(
                  start: g.lead,
                  end: g.padEnd,
                  top: card.pad,
                  bottom: card.pad,
                ),
                child: Column(
                  children: [
                    for (final _ in columns)
                      SizedBox(
                        height: card.line,
                        child: Row(
                          spacing: card.gap,
                          children: [
                            SizedBox(
                              width: card.labelWidth,
                              // ds-raw: a label is shorter than its value
                              child: line(AlignmentDirectional.centerStart, .7),
                            ),
                            Expanded(
                              // ds-raw: as the cell lines below
                              child: line(AlignmentDirectional.centerStart, .6),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            : _cells(
                s,
                g,
                cellRole: SemanticsRole.cell,
                lead: null,
                cells: [
                  for (final c in columns)
                    // ds-raw: a line covers most of the cell
                    line(_align(c), 0.6),
                ],
              ),
      ),
    );
    // One "Loading" for screen readers, not one per placeholder row.
    row = label == null
        ? ExcludeSemantics(child: row)
        : _stateNode(
            card: card != null,
            label: label,
            child: ExcludeSemantics(child: row),
          );
    return KeyedSubtree(key: ValueKey<Object>(key ?? i), child: row);
  }
}

enum _BodyState { rows, loading, empty, error }

/// One row's value, ready to compare: its collation key worked out once.
/// Orders as [DsTableColumn.compareValues]: numbers, then strings,
/// then other comparables by type, then the rest by their text.
final class _SortValue implements Comparable<_SortValue> {
  _SortValue._(this.rank, this.value, this.text);

  /// Null for an empty value (kept last by the caller).
  static _SortValue? of(Object? value, String? language) {
    if (value == null) return null;
    final rank = DsTableColumn.rankOf(value);
    return _SortValue._(rank, value, switch (rank) {
      1 => DsCollationKey(value as String, language: language),
      3 => DsCollationKey(value.toString(), language: language),
      _ => null,
    });
  }

  final int rank;
  final Object value;
  final DsCollationKey? text;

  @override
  int compareTo(_SortValue other) {
    if (rank != other.rank) return rank - other.rank;
    return switch (rank) {
      0 => (value as num).compareTo(other.value as num),
      1 || 3 => text!.compareTo(other.text!),
      _ => DsTableColumn.compareValues(value, other.value),
    };
  }
}

/// Where cells go in a row.
class _Geometry {
  const _Geometry({
    required this.widths,
    required this.lead,
    required this.padEnd,
    required this.gap,
    required this.vertical,
    required this.header,
    this.card,
  });

  final List<double> widths;
  final double lead;
  final double padEnd;
  final double gap;
  final EdgeInsets vertical;
  final double header;

  /// Set in the card layout.
  final _CardGeometry? card;
}

/// Where the lines go in a card.
class _CardGeometry {
  const _CardGeometry({
    required this.line,
    required this.pad,
    required this.labelWidth,
    required this.gap,
    required this.extent,
  });

  /// The height of one "label  value" line.
  final double line;

  /// Above the first line and below the last.
  final double pad;

  /// The label column.
  final double labelWidth;

  /// Between label and value.
  final double gap;

  /// The whole card.
  final double extent;
}

TextDirection _flip(TextDirection d) =>
    d == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;

/// A sortable column header: a button with an arrow. It spans the header
/// row's height, the cell's [padding] inside it, so the whole row answers
/// taps (a touch target) while the label and the focus ring stay where
/// the padding puts them.
class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.padding,
    required this.alignment,
    required this.textAlign,
    required this.direction,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final EdgeInsetsGeometry padding;
  final AlignmentDirectional alignment;
  final TextAlign textAlign;
  final DsTableSortDirection? direction;
  final DsTableStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final s = style;
    final size = s.sortIconSize!;
    return DsPressable(
      onPressed: onPressed,
      // The button spans the header row, tall enough to hit.
      minTapTarget: 0,
      mouseCursor: s.cursor,
      builder: (context, states, _) {
        final active =
            direction != null ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        // Unsorted, a hover previews the first direction.
        final icon = switch (direction) {
          DsTableSortDirection.descending => DsIcons.arrowDown,
          _ => DsIcons.arrowUp,
        };
        final color = active ? s.headerActiveColor : null;
        return Semantics(
          value: switch (direction) {
            DsTableSortDirection.ascending => l10n.sortedAscending,
            DsTableSortDirection.descending => l10n.sortedDescending,
            null => null,
          },
          child: Padding(
            padding: padding,
            child: DecoratedBox(
              decoration: DsBoxDecoration(
                // The ring spans the header row: a control of its height.
                borderRadius: BorderRadius.circular(
                  t.radii.control(s.headerHeight!),
                ),
                shadows: [
                  if (states.contains(WidgetState.focused)) ...?s.focusShadows,
                ],
              ),
              child: Align(
                alignment: alignment,
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: DsSpace.s4,
                  // In an end-aligned (numeric) column the arrow goes before
                  // the label, so the label's end lines up with the values,
                  // as in most data grids.
                  textDirection: alignment == AlignmentDirectional.centerEnd
                      ? _flip(Directionality.of(context))
                      : null,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: textAlign,
                        style: TextStyle(color: color),
                      ),
                    ),
                    // The arrow's place is kept, so the label never shifts.
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: active ? 1 : 0,
                        child: DsIcon(icon, size: size, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One data row: its fill, divider and focus, and the roving Tab stop.
class _TableRow extends StatefulWidget {
  const _TableRow({
    super.key,
    required this.rowKey,
    required this.table,
    required this.active,
    required this.selected,
    required this.divider,
    required this.card,
    required this.interactive,
    required this.layers,
    required this.extent,
    required this.onPressed,
    required this.menuItems,
    required this.builder,
  });

  final Object rowKey;
  final _DsTableState<Object?> table;
  final bool active;
  final bool selected;
  final bool divider;

  /// A card of the card layout: a list item rather than a row.
  final bool card;
  final bool interactive;
  final List<DsTableStyle?> layers;
  final double extent;
  final VoidCallback onPressed;
  final List<Widget> Function(BuildContext context)? menuItems;
  final Widget Function(BuildContext context, bool active) builder;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow>
    with AutomaticKeepAliveClientMixin {
  final node = FocusNode(debugLabel: 'DsTable row');
  bool _hovered = false;
  bool _pressed = false;
  bool _highlight = false;
  Set<WidgetState>? _lastStates;

  /// The active row stays alive off screen, so Tab can always return to it.
  @override
  bool get wantKeepAlive => widget.active;

  @override
  void initState() {
    super.initState();
    widget.table._rows[widget.rowKey] = this;
    DsFocusVisibility.keyboard.addListener(_rebuild);
    node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_TableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowKey != widget.rowKey) {
      _unregister(oldWidget);
      widget.table._rows[widget.rowKey] = this;
    }
    if (oldWidget.active != widget.active) updateKeepAlive();
  }

  void _unregister(_TableRow w) {
    if (identical(w.table._rows[w.rowKey], this)) {
      w.table._rows.remove(w.rowKey);
    }
  }

  @override
  void dispose() {
    _unregister(widget);
    DsFocusVisibility.keyboard.removeListener(_rebuild);
    node.removeListener(_onFocus);
    _menu?.dispose();
    node.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onFocus() {
    if (node.hasPrimaryFocus) widget.table._reveal(widget.rowKey);
  }

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  DsOverlayController? _menu;
  Offset _menuAt = Offset.zero;

  /// Opens the row menu below [button] (the "⋯" row menu button), its end
  /// edge under the button's end.
  void openMenuBelow(BuildContext button) {
    final box = button.findRenderObject() as RenderBox?;
    final row = context.findRenderObject() as RenderBox?;
    if (box == null || row == null) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    openMenu(
      box.localToGlobal(
        rtl
            ? box.size.bottomRight(Offset.zero)
            : box.size.bottomLeft(Offset.zero),
        ancestor: row,
      ),
    );
  }

  /// Opens the row menu at [at] (row coordinates), or at the row's bottom
  /// start corner for the keyboard (Shift+F10, the Menu key).
  void openMenu([Offset? at]) {
    final menu = _menu;
    if (menu == null || !mounted) return;
    final size = context.size ?? Size.zero;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    setState(
      () => _menuAt =
          at ??
          (rtl ? size.bottomRight(Offset.zero) : size.bottomLeft(Offset.zero)),
    );
    menu
      ..close()
      ..open();
  }

  void _browserMenu({required bool enabled}) {
    if (!kIsWeb) return;
    enabled
        ? BrowserContextMenu.enableContextMenu()
        : BrowserContextMenu.disableContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = dsThemeOf(context);
    node.skipTraversal = !widget.active;
    final focused = _highlight && DsFocusVisibility.keyboard.value;
    final states = <WidgetState>{
      if (_hovered) WidgetState.hovered,
      if (_pressed) WidgetState.pressed,
      if (focused) WidgetState.focused,
      if (widget.selected) WidgetState.selected,
    };
    final s = DsTableStyle.resolveLayers(widget.layers, states);
    final animate = _lastStates != null && !setEquals(_lastStates, states);
    _lastStates = states;
    final cursor = widget.interactive
        ? s.cursor ?? SystemMouseCursors.click
        : s.cursor ?? MouseCursor.defer;

    Widget row = FocusableActionDetector(
      focusNode: node,
      mouseCursor: cursor,
      onShowHoverHighlight: (v) => _set(() => _hovered = v),
      onShowFocusHighlight: (v) => _set(() => _highlight = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: widget.interactive
            ? (_) => _set(() => _pressed = true)
            : null,
        onTapUp: widget.interactive
            ? (_) => _set(() => _pressed = false)
            : null,
        onTapCancel: widget.interactive
            ? () => _set(() => _pressed = false)
            : null,
        onTap: widget.interactive ? widget.onPressed : null,
        onSecondaryTapUp: widget.menuItems == null
            ? null
            : (d) => openMenu(d.localPosition),
        onLongPressStart: widget.menuItems == null
            ? null
            : (d) => openMenu(d.localPosition),
        child: AnimatedContainer(
          duration: animate ? t.motion.toneDuration : Duration.zero,
          curve: t.motion.toneCurve,
          height: widget.extent,
          decoration: DsBoxDecoration(
            color: s.rowBackground,
            shadows: [
              if (widget.divider && s.dividerColor != null)
                DsShadow.topLine(s.dividerColor!, hairline: true),
              if (s.rowBorderColor != null)
                DsShadow.innerRing(s.rowBorderColor!),
              if (states.contains(WidgetState.focused)) ...?s.focusShadows,
            ],
          ),
          child: DefaultTextStyle.merge(
            style: s.textStyle,
            child: widget.builder(context, widget.active),
          ),
        ),
      ),
    );
    if (widget.menuItems != null) {
      // The menu is built here rather than with DsContextMenuRegion, whose
      // own focus node would add a semantics node between row and cells.
      // The row menu button shows whether the menu is open.
      final menu = _menu ??= DsOverlayController()..addListener(_rebuild);
      row = DsAnchoredOverlay(
        controller: menu,
        anchorPoint: _menuAt,
        gap: 2, // ds-raw: just off the pointer, as DsContextMenuRegion
        tab: DsOverlayTab.close,
        overlayBuilder: (context) => DsMenu(
          autofocus: true,
          onDone: menu.close,
          children: widget.menuItems!(context),
        ),
        child: MouseRegion(
          onEnter: (_) => _browserMenu(enabled: false),
          onExit: (_) => _browserMenu(enabled: true),
          child: row,
        ),
      );
    }
    return Semantics(
      container: true,
      role: widget.card ? SemanticsRole.listItem : SemanticsRole.row,
      selected: widget.table._selectable ? widget.selected : null,
      onTap: widget.interactive ? widget.onPressed : null,
      onLongPress: widget.menuItems == null ? null : openMenu,
      child: row,
    );
  }
}
