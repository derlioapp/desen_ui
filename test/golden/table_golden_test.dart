@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

class _Invoice {
  const _Invoice(this.id, this.customer, this.status, this.amount, this.date);
  final int id;
  final String customer;
  final DsStatus status;
  final int amount;
  final String date;
}

const _rows = [
  _Invoice(1, 'Kuzey Lojistik', DsStatus.success, 1248000, '12.10.2026'),
  _Invoice(2, 'Atlas Yazılım', DsStatus.warning, 825000, '09.10.2026'),
  _Invoice(3, 'Mavi Tasarım', DsStatus.success, 490000, '03.10.2026'),
  _Invoice(4, 'Ege Gıda', DsStatus.danger, 217500, '28.09.2026'),
];

String _money(int kurus) {
  final lira = (kurus ~/ 100).toString();
  final grouped = lira.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '$grouped,${(kurus % 100).toString().padLeft(2, '0')}';
}

String _label(DsStatus s) => switch (s) {
  DsStatus.success => 'Ödendi',
  DsStatus.warning => 'Bekliyor',
  _ => 'Gecikti',
};

final _columns = [
  DsTableColumn<_Invoice>(
    id: 'customer',
    label: 'Müşteri',
    value: (i) => i.customer,
    sortable: true,
  ),
  DsTableColumn<_Invoice>(
    id: 'status',
    label: 'Durum',
    width: const .fixed(96),
    cell: (_, i) => DsBadge(status: i.status, label: Text(_label(i.status))),
  ),
  DsTableColumn<_Invoice>(
    id: 'date',
    label: 'Tarih',
    text: (i) => i.date,
    numeric: true,
    width: const .fixed(88),
  ),
  DsTableColumn<_Invoice>(
    id: 'amount',
    label: 'Tutar',
    value: (i) => i.amount,
    text: (i) => _money(i.amount),
    numeric: true,
    sortable: true,
    width: const .fixed(88),
  ),
];

/// Visual regression for DsTable (concept card 28), light and dark (K-24):
/// a column sorted descending with a selected row; RTL; loading (first
/// load and "loading more"); the compact empty state.
void main() {
  Map<String, DsThemeData> frozen() => {
    for (final MapEntry(:key, :value) in themesFor(DsSeed.blue).entries)
      key: value.copyWith(motion: const DsMotion(reduced: true)),
  };

  Widget caption(DsThemeData theme, String text) => Text(
    text,
    style: theme.typography.caption.copyWith(color: theme.colors.textSubtle),
  );

  Widget table({
    List<_Invoice> rows = _rows,
    bool loading = false,
    Widget? empty,
    bool menuButton = false,
  }) => SizedBox(
    width: 520,
    child: DsTable<_Invoice>(
      columns: _columns,
      rows: rows,
      rowKey: (i) => i.id,
      sort: const DsTableSort('amount', DsTableSortDirection.descending),
      onSortChanged: (_) {},
      selected: const {2},
      onSelectionChanged: (_) {},
      loading: loading,
      loadingRowCount: 3,
      emptyView: empty,
      rowMenuBuilder: menuButton ? (_, _) => const [] : null,
      showRowMenuButton: menuButton,
    ),
  );

  for (final MapEntry(key: mode, value: theme) in frozen().entries) {
    testWidgets('table $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        size: const Size(1200, 1000),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            caption(theme, 'sorted by amount, row 2 selected'),
            table(),
            const SizedBox(height: 8),
            caption(theme, 'RTL'),
            Directionality(textDirection: TextDirection.rtl, child: table()),
            const SizedBox(height: 8),
            caption(theme, 'row menu button'),
            table(menuButton: true),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/table_$mode.png');
    });

    testWidgets('table states $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        size: const Size(1200, 1000),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            caption(theme, 'loading'),
            table(rows: const [], loading: true),
            const SizedBox(height: 8),
            caption(theme, 'loading more'),
            table(rows: _rows.sublist(0, 2), loading: true),
            const SizedBox(height: 8),
            caption(theme, 'empty'),
            table(
              rows: const [],
              empty: DsEmptyState(
                icon: const DsIcon(DsIcons.search),
                title: const Text('Sonuç bulunamadı'),
                description: const Text(
                  '“Ödendi” filtresiyle eşleşen kayıt yok.',
                ),
                actions: [
                  DsButton(
                    variant: .ghost,
                    size: .xs,
                    onPressed: () {},
                    child: const Text('Filtreleri temizle'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/table_states_$mode.png');
    });

    // D2: the card layout of a narrow table, with a selected card (its
    // badge keeps its own color) and the loading cards.
    testWidgets('table cards $mode', (tester) async {
      Widget cards({List<_Invoice> rows = _rows, bool loading = false}) =>
          SizedBox(
            width: 360,
            child: DsTable<_Invoice>(
              layout: const DsTableLayout.auto(),
              columns: _columns,
              rows: rows,
              rowKey: (i) => i.id,
              sort: const DsTableSort(
                'amount',
                DsTableSortDirection.descending,
              ),
              onSortChanged: (_) {},
              selected: const {2},
              onSelectionChanged: (_) {},
              rowMenuBuilder: (_, _) => const [],
              showRowMenuButton: true,
              loading: loading,
              loadingRowCount: 1,
            ),
          );
      await pumpGolden(
        tester,
        theme: theme,
        size: const Size(900, 1000),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                caption(theme, 'auto, 360 wide: cards, row 2 selected'),
                cards(rows: _rows.sublist(0, 3)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                caption(theme, 'loading'),
                cards(rows: const [], loading: true),
                caption(theme, 'RTL'),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: cards(rows: _rows.sublist(0, 2)),
                ),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/table_cards_$mode.png');
    });
  }
}
