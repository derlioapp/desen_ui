import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'sample_data.dart';

/// Room for a table: less padding than the default example frame, so
/// columns get the width.
const _tablePadding = EdgeInsets.all(16);

class TablePage extends StatelessWidget {
  const TablePage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Data display',
    title: 'Table',
    lead:
        'Shows records in rows and columns that people compare, sort and '
        'select: invoices, orders, members. For a short settings-style list '
        'use a [List](/components/list); for a few rich items, '
        '[Cards](/components/card).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          DocText(
            'Forty invoices in a 360px box. The header stays put while the '
            'rows scroll under it. Customer and amount sort; the checkbox '
            'column selects.',
          ),
          Example(
            snippet: 'table-overview',
            padding: _tablePadding,
            child: _OverviewDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Columns',
        children: [
          DocText(
            'A `DsTableColumn` says what its cells show. `value` is the data '
            'the column sorts by; `text` is what the cell says, such as a '
            'formatted amount; `cell` builds any widget, such as a badge. '
            'Without `cell` or `text`, the cell shows the value as a string '
            'on one line, cut with an ellipsis. With large text, a column '
            'keeps the text it showed at normal size and the table scrolls '
            'sideways instead.',
          ),
          DocText(
            '`numeric: true` sets tabular figures and aligns the column to '
            'the reading end, so digits line up. Alignment follows the '
            'reading direction, so in Arabic numbers sit on the left. In a '
            'sortable numeric column the sort arrow sits before the label, '
            'so the label ends where the values end.',
          ),
          DocList([
            '`.flex(flex, min)` (the default) shares the space left over, '
                'never narrower than `min`.',
            '`.fixed(width)` is exactly that wide: badges, icons, short '
                'codes.',
            '`.intrinsic(min:, max:)` measures the header and the first 200 '
                'cells: dates, amounts, IDs.',
            'Widths grow with the text scale. When the minimums do not fit, '
                'the table scrolls sideways and fades the edge that hides '
                'columns.',
          ]),
        ],
      ),
      DocSection(
        title: 'Sorting',
        children: [
          DocText(
            'A `sortable` header is a button that cycles ascending, '
            'descending and unsorted. The sort is controlled: keep a '
            '`DsTableSort` in state and set it in `onSortChanged`. By '
            'default the table orders the rows itself; turn `sortLocally` '
            'off when they come sorted from a server.',
          ),
          DocText(
            'Text sorts in the dictionary order of the current language. '
            'Switch to Turkish below: "Ç", "Ş" and "Ö" become letters of '
            'their own after "C", "S" and "O", and dotless "I" comes before '
            '"İ". Empty values go last in both directions.',
          ),
          Example(
            snippet: 'table-sorting',
            padding: _tablePadding,
            child: _SortingDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Selection',
        children: [
          DocText(
            'Pass `onSelectionChanged` and a checkbox column leads, with '
            '"select all" in the header. `selected` holds row keys from '
            '`rowKey`, so a selection follows the invoice through sorting, '
            'filtering and paging. Click a row to select it, Shift-click to '
            'select a range, or press Space on the focused row.',
          ),
          Example(
            snippet: 'table-selection',
            padding: _tablePadding,
            child: _SelectionDemo(),
          ),
          Callout(
            'With `onRowPressed` a click opens the row and only the '
            'checkbox selects. Without it, a click selects.',
          ),
        ],
      ),
      DocSection(
        title: 'Height and scrolling',
        children: [
          DocList([
            'In a bounded height (a `SizedBox`, an `Expanded`) the header '
                'stays put and rows are built as they scroll in, so 10,000 '
                'rows scroll smoothly.',
            'In an unbounded height (a `Column`, a scroll view) the table is '
                'as tall as its rows and builds them all. Page long data '
                'with [Pagination](/components/pagination).',
            'Rows are as tall as `rowHeight` in the style, and grow to fit '
                'one line of text at large text sizes.',
          ]),
        ],
      ),
      DocSection(
        title: 'Loading, empty and error',
        children: [
          DocText(
            '`loading` with no rows shows skeleton rows; with rows, one '
            'skeleton row at the end for "loading more". No rows shows '
            '`emptyView`, a compact "No results" by default. A non-null '
            '`errorView` replaces the rows. These slots get a compact '
            '[Empty state](/components/empty-state) theme, so your own '
            '`DsEmptyState` fits in.',
          ),
          Example(
            snippet: 'table-states',
            padding: _tablePadding,
            child: _StatesDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'With pagination',
        children: [
          DocText(
            '236 invoices, 20 a page. The example sorts the whole list '
            'itself, as a server would, and passes the table one page with '
            '`sortLocally: false`. Changing the page loads for a moment. '
            'Selection survives sorting and paging. Each row has a "…" '
            'button for its menu.',
          ),
          Example(
            snippet: 'table-pagination',
            padding: _tablePadding,
            child: _PaginationDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Row menus',
        children: [
          DocText(
            '`rowMenuBuilder` gives each row a menu of `DsMenuItem`s. A '
            'right-click, a long press, Shift+F10 or the Menu key opens it. '
            '`showRowMenuButton: true` also adds a "…" button at the end of '
            'every row, as in the table above, so the actions are visible '
            'without a right-click. The button opens the same menu below '
            'itself. Its column is as wide as the checkbox column and takes '
            'the place of the end padding.',
          ),
        ],
      ),
      DocSection(
        title: 'Narrow widths',
        children: [
          DocText(
            'By default a narrow table keeps its columns and scrolls '
            'sideways. With `layout: const .auto()` it shows one card per '
            'row while the table itself is narrower than 480px: each column '
            'on a "label  value" line, with a "Select all" checkbox and a '
            '"Sort by" menu button in a bar above; the bar keeps one line at '
            'any width. `.cards()` always shows cards. '
            'Selection, row presses, menus and the keyboard work the same; '
            'the "…" button sits at the top end of each card.',
          ),
          Example(
            snippet: 'table-layout',
            padding: _tablePadding,
            child: _LayoutDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one table with `style`, a part of the app with '
            '`DsTableTheme`, or the whole app through `DsComponentThemes`. '
            'Row states such as `hovered` and `selected` nest like CSS '
            'blocks. This table is denser, with darker dividers and header '
            'text.',
          ),
          Example(
            snippet: 'table-custom',
            padding: _tablePadding,
            child: _CustomDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'The rows are one Tab stop, like a WAI-ARIA grid: focus returns '
            'to the last active row.',
          ),
          KeyboardTable([
            (
              'Tab',
              'Sort buttons and "select all", then the rows, then the active '
                  'row\'s own buttons.',
            ),
            ('↑ / ↓', 'Previous or next row. With Shift, also selects it.'),
            ('Home / End', 'First or last row.'),
            ('Page Up / Page Down', 'A screenful up or down.'),
            ('Space', 'Selects or deselects the row.'),
            (
              'Enter',
              'Calls `onRowPressed`; without it, does what Space does.',
            ),
            ('Ctrl+A / Cmd+A', 'Selects every row.'),
            ('Shift+F10 / Menu', 'Opens the row\'s menu.'),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a table named by `semanticLabel`, with its row '
                'count; in the card layout, as a list.',
            'Headers carry their sort direction. Selected rows are '
                'announced as selected.',
            'Each row checkbox is named by the row\'s first text cell, such '
                'as "Select Atlas Software", so a list of checkboxes tells '
                'rows apart. The "…" button is named the same way: "Actions '
                'for Atlas Software". It is announced as expanded while its '
                'menu is open.',
            'In the card layout the "Select all" checkbox has a visible '
                'label; clicking the label toggles it too.',
            'Loading, "No results" and errors are polite live regions. '
                'After a filter, the new row count is announced once the '
                'rows settle.',
            'A selected row\'s checkbox carries its state, so selection '
                'does not rest on the tint.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsTable'),
          ApiTable([
            ('columns', 'List<DsTableColumn<T>>', 'The columns, in order.'),
            ('rows', 'List<T>', 'The data, one row per item.'),
            (
              'rowKey',
              'Object Function(T item)',
              'A stable, unique key per item. Selection and focus follow it.',
            ),
            ('sort', 'DsTableSort?', 'The sorted column and its direction.'),
            (
              'onSortChanged',
              'ValueChanged<DsTableSort?>?',
              'Called with the next sort. Null makes headers plain labels.',
            ),
            (
              'sortLocally',
              'bool',
              'Orders `rows` by `sort` inside the table. Default `true`.',
            ),
            ('selected', 'Set<Object>', 'The keys of the selected rows.'),
            (
              'onSelectionChanged',
              'ValueChanged<Set<Object>>?',
              'Called with the new selection. Adds the checkbox column.',
            ),
            (
              'onRowPressed',
              'ValueChanged<T>?',
              'Called on click, tap or Enter.',
            ),
            (
              'rowMenuBuilder',
              'List<Widget> Function(BuildContext, T item)?',
              'Builds the row\'s context menu from `DsMenuItem` and '
                  '`DsMenuDivider` widgets.',
            ),
            (
              'showRowMenuButton',
              'bool',
              'Adds a "…" button that opens the row menu. Needs '
                  '`rowMenuBuilder`. Default `false`.',
            ),
            (
              'layout',
              'DsTableLayout',
              '`.rows()` (default), `.cards()` or `.auto(breakpoint: 480)`.',
            ),
            ('loading', 'bool', 'Shows skeleton rows.'),
            ('emptyView', 'Widget?', 'Shown when there are no rows.'),
            (
              'errorView',
              'Widget?',
              'Replaces the rows; non-null means loading failed.',
            ),
            (
              'rowsVersion',
              'Object?',
              'Change it after editing a mutable row in place.',
            ),
            (
              'scrollController',
              'ScrollController?',
              'Scrolls the rows in a bounded height.',
            ),
            ('semanticLabel', 'String?', 'Names the table.'),
            ('style', 'DsTableStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsTableColumn'),
          ApiTable([
            ('id', 'Object', 'Identifies the column in a `DsTableSort`.'),
            ('label', 'String', 'The header text.'),
            (
              'value',
              'Object? Function(T item)?',
              'The data to sort by; the cell text when there is no `text`.',
            ),
            ('text', 'String Function(T item)?', 'The cell text.'),
            (
              'cell',
              'Widget Function(BuildContext, T)?',
              'Builds the cell. Wins over `text` and `value`.',
            ),
            ('numeric', 'bool', 'Tabular figures, aligned to the reading end.'),
            (
              'width',
              'DsTableColumnWidth',
              '`.flex()` (default), `.fixed()` or `.intrinsic()`.',
            ),
            ('sortable', 'bool', 'Makes the header a sort button.'),
            (
              'comparator',
              'Comparator<T>?',
              'A custom ascending order. Defaults to comparing values.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _OverviewDemo extends StatefulWidget {
  const _OverviewDemo();

  @override
  State<_OverviewDemo> createState() => _OverviewDemoState();
}

class _OverviewDemoState extends State<_OverviewDemo> {
  DsTableSort? _sort = const DsTableSort('amount', .descending);
  Set<Object> _selected = {1003};

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 360,
    // #region table-overview
    child: DsTable<Invoice>(
      semanticLabel: 'Invoices',
      rows: invoices.take(40).toList(),
      rowKey: (i) => i.id,
      columns: [
        DsTableColumn(
          id: 'customer',
          label: 'Customer',
          value: (i) => i.customer,
          sortable: true,
          width: const .flex(1, 140),
        ),
        DsTableColumn(
          id: 'status',
          label: 'Status',
          value: (i) => i.status.index,
          cell: (_, i) =>
              DsBadge(status: i.status.tone, label: Text(i.status.label)),
          width: const .fixed(104),
        ),
        DsTableColumn(
          id: 'due',
          label: 'Due',
          value: (i) => i.due,
          text: (i) => shortDate(i.due),
          numeric: true,
          sortable: true,
          width: const .intrinsic(),
        ),
        DsTableColumn(
          id: 'amount',
          label: 'Amount',
          value: (i) => i.amount,
          text: (i) => money(i.amount),
          numeric: true,
          sortable: true,
          width: const .intrinsic(),
        ),
      ],
      sort: _sort,
      onSortChanged: (s) => setState(() => _sort = s),
      selected: _selected,
      onSelectionChanged: (s) => setState(() => _selected = s),
    ),
    // #endregion
  );
}

class _SortingDemo extends StatefulWidget {
  const _SortingDemo();

  @override
  State<_SortingDemo> createState() => _SortingDemoState();
}

class _SortingDemoState extends State<_SortingDemo> {
  String _language = 'en';
  DsTableSort? _sort = const DsTableSort('name');

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      DsSegmentedControl<String>(
        semanticLabel: 'Sort language',
        value: _language,
        segments: const [
          DsSegment(value: 'en', label: Text('English')),
          DsSegment(value: 'tr', label: Text('Turkish')),
        ],
        onChanged: (v) => setState(() => _language = v),
      ),
      // #region table-sorting
      Localizations.override(
        context: context,
        locale: Locale(_language),
        child: DsTable<Person>(
          semanticLabel: 'Team',
          rows: team,
          rowKey: (p) => p.name,
          columns: [
            DsTableColumn(
              id: 'name',
              label: 'Name',
              value: (p) => p.name,
              sortable: true,
            ),
            DsTableColumn(
              id: 'city',
              label: 'City',
              value: (p) => p.city,
              sortable: true,
            ),
          ],
          sort: _sort,
          onSortChanged: (s) => setState(() => _sort = s),
        ),
      ),
      // #endregion
    ],
  );
}

class _SelectionDemo extends StatefulWidget {
  const _SelectionDemo();

  @override
  State<_SelectionDemo> createState() => _SelectionDemoState();
}

class _SelectionDemoState extends State<_SelectionDemo> {
  Set<Object> _selected = {1001, 1004};

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  _selected.isEmpty
                      ? 'No invoices selected'
                      : '${_selected.length} selected',
                  style: t.typography.small.copyWith(color: t.colors.textMuted),
                ),
              ),
              if (_selected.isNotEmpty)
                DsButton(
                  variant: .ghost,
                  size: .sm,
                  onPressed: () => setState(() => _selected = {}),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        // #region table-selection
        DsTable<Invoice>(
          semanticLabel: 'Invoices',
          rows: invoices.take(6).toList(),
          rowKey: (i) => i.id,
          columns: [
            DsTableColumn(
              id: 'number',
              label: 'Invoice',
              value: (i) => i.number,
              width: const .intrinsic(),
            ),
            DsTableColumn(
              id: 'customer',
              label: 'Customer',
              value: (i) => i.customer,
            ),
            DsTableColumn(
              id: 'amount',
              label: 'Amount',
              value: (i) => i.amount,
              text: (i) => money(i.amount),
              numeric: true,
              width: const .intrinsic(),
            ),
          ],
          selected: _selected,
          onSelectionChanged: (s) => setState(() => _selected = s),
        ),
        // #endregion
      ],
    );
  }
}

enum _TableState { data, loading, empty, error }

class _StatesDemo extends StatefulWidget {
  const _StatesDemo();

  @override
  State<_StatesDemo> createState() => _StatesDemoState();
}

class _StatesDemoState extends State<_StatesDemo> {
  _TableState _state = .loading;

  void _retry() => setState(() => _state = .data);

  @override
  Widget build(BuildContext context) {
    final loading = _state == .loading;
    final failed = _state == .error;
    final rows = _state == .data ? invoices.take(4).toList() : <Invoice>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        DsSegmentedControl<_TableState>(
          semanticLabel: 'Table state',
          value: _state,
          segments: const [
            DsSegment(value: .data, label: Text('Data')),
            DsSegment(value: .loading, label: Text('Loading')),
            DsSegment(value: .empty, label: Text('Empty')),
            DsSegment(value: .error, label: Text('Error')),
          ],
          onChanged: (v) => setState(() => _state = v),
        ),
        // #region table-states
        DsTable<Invoice>(
          semanticLabel: 'Invoices',
          rows: rows,
          rowKey: (i) => i.id,
          loading: loading,
          loadingRowCount: 4,
          columns: [
            DsTableColumn(
              id: 'customer',
              label: 'Customer',
              value: (i) => i.customer,
            ),
            DsTableColumn(
              id: 'amount',
              label: 'Amount',
              value: (i) => i.amount,
              text: (i) => money(i.amount),
              numeric: true,
              width: const .intrinsic(),
            ),
          ],
          emptyView: const DsEmptyState(
            icon: DsIcon(DsIcons.inbox),
            title: Text('No invoices yet'),
            description: Text('Invoices you send will show up here.'),
          ),
          errorView: failed
              ? DsEmptyState(
                  icon: const DsIcon(DsIcons.circleAlert),
                  title: const Text('Could not load invoices'),
                  description: const Text('Check your connection.'),
                  actions: [
                    DsButton(
                      variant: .secondary,
                      size: .xs,
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  ],
                )
              : null,
        ),
        // #endregion
      ],
    );
  }
}

class _PaginationDemo extends StatefulWidget {
  const _PaginationDemo();

  @override
  State<_PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<_PaginationDemo> {
  static const perPage = 20;

  DsTableSort? _sort = const DsTableSort('due', .descending);
  Set<Object> _selected = {};
  int _page = 1;
  bool _loading = false;
  Timer? _timer;

  late final List<DsTableColumn<Invoice>> _columns = [
    DsTableColumn(
      id: 'number',
      label: 'Invoice',
      value: (i) => i.number,
      sortable: true,
      width: const .intrinsic(),
    ),
    DsTableColumn(
      id: 'customer',
      label: 'Customer',
      value: (i) => i.customer,
      sortable: true,
      width: const .flex(1, 140),
    ),
    DsTableColumn(
      id: 'status',
      label: 'Status',
      value: (i) => i.status.index,
      sortable: true,
      cell: (_, i) =>
          DsBadge(status: i.status.tone, label: Text(i.status.label)),
      width: const .fixed(104),
    ),
    DsTableColumn(
      id: 'due',
      label: 'Due',
      value: (i) => i.due,
      text: (i) => shortDate(i.due),
      numeric: true,
      sortable: true,
      width: const .intrinsic(),
    ),
    DsTableColumn(
      id: 'amount',
      label: 'Amount',
      value: (i) => i.amount,
      text: (i) => money(i.amount),
      numeric: true,
      sortable: true,
      width: const .intrinsic(),
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// A short pretend fetch, so the skeleton rows show.
  void _goTo(int page) {
    _timer?.cancel();
    setState(() {
      _page = page;
      _loading = true;
    });
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  /// The whole list in [_sort] order, as a server would send it.
  List<Invoice> get _sorted {
    final s = _sort;
    if (s == null) return invoices;
    final column = _columns.firstWhere((c) => c.id == s.columnId);
    final sign = s.ascending ? 1 : -1;
    return [...invoices]..sort((a, b) => sign * column.compare(a, b));
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final all = _sorted;
    final pageCount = (all.length / perPage).ceil();
    final from = (_page - 1) * perPage;
    final pageRows = all.sublist(from, (from + perPage).clamp(0, all.length));
    final meta = t.typography.small.copyWith(color: t.colors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SizedBox(
          height: 360,
          // #region table-pagination
          child: DsTable<Invoice>(
            semanticLabel: 'Invoices',
            columns: _columns,
            rows: _loading ? const [] : pageRows,
            rowKey: (i) => i.id,
            loading: _loading,
            sort: _sort,
            sortLocally: false,
            onSortChanged: (s) => setState(() {
              _sort = s;
              _page = 1;
            }),
            selected: _selected,
            onSelectionChanged: (s) => setState(() => _selected = s),
            showRowMenuButton: true,
            rowMenuBuilder: (_, i) => [
              DsMenuItem(
                leading: const DsIcon(DsIcons.eye),
                label: const Text('View'),
                onPressed: () {},
              ),
              DsMenuItem(
                leading: const DsIcon(DsIcons.copy),
                label: Text('Copy ${i.number}'),
                onPressed: () {},
              ),
              const DsMenuDivider(),
              DsMenuItem(
                leading: const DsIcon(DsIcons.trash),
                label: const Text('Delete'),
                destructive: true,
                onPressed: () {},
              ),
            ],
          ),
          // #endregion
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${from + 1}–${from + pageRows.length} of ${all.length}'
              '${_selected.isEmpty ? '' : ' · ${_selected.length} selected'}',
              style: t.typography.numeric(meta),
            ),
            DsPagination(page: _page, pageCount: pageCount, onChanged: _goTo),
          ],
        ),
      ],
    );
  }
}

class _LayoutDemo extends StatefulWidget {
  const _LayoutDemo();

  @override
  State<_LayoutDemo> createState() => _LayoutDemoState();
}

class _LayoutDemoState extends State<_LayoutDemo> {
  DsTableLayout _layout = const .auto();
  DsTableSort? _sort;
  Set<Object> _selected = {};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      DsSegmentedControl<DsTableLayout>(
        semanticLabel: 'Layout',
        value: _layout,
        segments: const [
          DsSegment(value: DsTableLayout.auto(), label: Text('Auto')),
          DsSegment(value: DsTableLayout.rows(), label: Text('Rows')),
          DsSegment(value: DsTableLayout.cards(), label: Text('Cards')),
        ],
        onChanged: (v) => setState(() => _layout = v),
      ),
      // #region table-layout
      DsTable<Invoice>(
        semanticLabel: 'Invoices',
        layout: _layout,
        rows: invoices.take(3).toList(),
        rowKey: (i) => i.id,
        columns: [
          DsTableColumn(
            id: 'customer',
            label: 'Customer',
            value: (i) => i.customer,
            sortable: true,
          ),
          DsTableColumn(
            id: 'status',
            label: 'Status',
            value: (i) => i.status.index,
            cell: (_, i) =>
                DsBadge(status: i.status.tone, label: Text(i.status.label)),
            width: const .fixed(104),
          ),
          DsTableColumn(
            id: 'amount',
            label: 'Amount',
            value: (i) => i.amount,
            text: (i) => money(i.amount),
            numeric: true,
            sortable: true,
            width: const .intrinsic(),
          ),
        ],
        sort: _sort,
        onSortChanged: (s) => setState(() => _sort = s),
        selected: _selected,
        onSelectionChanged: (s) => setState(() => _selected = s),
        showRowMenuButton: true,
        rowMenuBuilder: (_, i) => [
          DsMenuItem(
            leading: const DsIcon(DsIcons.eye),
            label: const Text('View'),
            onPressed: () {},
          ),
          DsMenuItem(
            leading: const DsIcon(DsIcons.fileText),
            label: const Text('Download PDF'),
            onPressed: () {},
          ),
        ],
      ),
      // #endregion
    ],
  );
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) {
    // #region table-custom
    // Theme colors:
    final k = DsTheme.colorsOf(context);
    return DsTable<Invoice>(
      semanticLabel: 'Invoices',
      rows: invoices.take(4).toList(),
      rowKey: (i) => i.id,
      columns: [
        DsTableColumn(
          id: 'customer',
          label: 'Customer',
          value: (i) => i.customer,
        ),
        DsTableColumn(
          id: 'amount',
          label: 'Amount',
          value: (i) => i.amount,
          text: (i) => money(i.amount),
          numeric: true,
          width: const .intrinsic(),
        ),
      ],
      style: DsTableStyle(
        rowHeight: 32,
        headerHeight: 28,
        dividerColor: k.borderControl,
        headerStyle: TextStyle(color: k.text),
      ),
    );
    // #endregion
  }
}
