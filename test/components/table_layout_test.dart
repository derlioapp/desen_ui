// Denetim-2 regressions: badges on selected rows, and the card layout for
// narrow tables.
import 'package:desen_ui/desen_ui.dart';

import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Invoice {
  const Invoice(this.id, this.customer, this.status, this.amount);
  final int id;
  final String customer;
  final DsStatus status;
  final int amount;
}

const invoices = [
  Invoice(1, 'Kuzey Lojistik', DsStatus.success, 12480),
  Invoice(2, 'Atlas Yazılım', DsStatus.warning, 8250),
  Invoice(3, 'Mavi Tasarım', DsStatus.success, 4900),
];

List<DsTableColumn<Invoice>> columns() => [
  DsTableColumn(
    id: 'customer',
    label: 'Müşteri',
    value: (i) => i.customer,
    sortable: true,
  ),
  DsTableColumn(
    id: 'status',
    label: 'Durum',
    value: (i) => i.status.index,
    cell: (_, i) => DsBadge(status: i.status, label: Text('S${i.id}')),
    width: const .fixed(96),
  ),
  DsTableColumn(
    id: 'amount',
    label: 'Tutar',
    value: (i) => i.amount,
    numeric: true,
    sortable: true,
    width: const .fixed(88),
  ),
];

class Harness extends StatefulWidget {
  const Harness({
    super.key,
    this.width = 600,
    this.layout = const DsTableLayout.rows(),
    this.onRowPressed,
    this.menu = false,
  });

  final double width;
  final DsTableLayout layout;
  final ValueChanged<Invoice>? onRowPressed;
  final bool menu;

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  DsTableSort? sort;
  Set<Object> selected = {2};

  void setSort(DsTableSort? value) => setState(() => sort = value);

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: widget.width,
      height: 400,
      child: DsTable<Invoice>(
        semanticLabel: 'Faturalar',
        layout: widget.layout,
        columns: columns(),
        rows: invoices,
        rowKey: (i) => i.id,
        sort: sort,
        onSortChanged: (s) => setState(() => sort = s),
        selected: selected,
        onSelectionChanged: (s) => setState(() => selected = s),
        onRowPressed: widget.onRowPressed,
        rowMenuBuilder: widget.menu
            ? (_, i) => [
                DsMenuItem(onPressed: () {}, label: Text('Sil ${i.id}')),
              ]
            : null,
      ),
    ),
  );
}

HarnessState harness(WidgetTester tester) =>
    tester.state<HarnessState>(find.byType(Harness));

/// The pill color painted behind badge [label].
Color badgeFill(WidgetTester tester, String label) {
  final box = tester.widget<Container>(
    find
        .descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(DsBadge),
          ),
          matching: find.byType(Container),
        )
        .first,
  );
  return (box.decoration! as DsBoxDecoration).color!;
}

void main() {
  group('badges', () {
    for (final mode in [Brightness.light, Brightness.dark]) {
      testWidgets('keep their own look on a selected row ($mode)', (
        tester,
      ) async {
        final theme = DsThemeData(brightness: mode);
        await tester.pumpWidget(DsApp(theme: theme, home: const Harness()));
        final k = theme.colors;
        // A badge's own fill: the status tint, or in dark mode the neutral
        // control fill (a deep status tint there reads brown).
        Color fill(DsStatusColors st) =>
            mode == Brightness.dark ? k.control : st.tint;
        // Row 2 (warning) is selected; the same fill over the surface.
        final expected = Color.alphaBlend(fill(k.warning), k.surface);
        expect(badgeFill(tester, 'S2'), expected);
        expect(badgeFill(tester, 'S2').a, 1);
        expect(
          badgeFill(tester, 'S1'),
          Color.alphaBlend(fill(k.success), k.surface),
        );
        // A badge outside a table is unchanged.
        await tester.pumpWidget(
          DsApp(
            theme: theme,
            home: const Center(
              child: DsBadge(status: DsStatus.warning, label: Text('S2')),
            ),
          ),
        );
        expect(badgeFill(tester, 'S2'), fill(k.warning));
      });
    }

    testWidgets('an app badge theme still applies', (tester) async {
      const red = Color(0xFFFF0000);
      await tester.pumpWidget(
        const DsApp(
          home: DsBadgeTheme(
            data: DsBadgeThemeData(
              statuses: {DsStatus.warning: DsBadgeStyle(background: red)},
            ),
            child: Harness(),
          ),
        ),
      );
      expect(badgeFill(tester, 'S2'), red);
    });
  });

  group('cards', () {
    bool scrollsSideways(WidgetTester tester) => find
        .descendant(
          of: find.byType(DsTable<Invoice>),
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        )
        .evaluate()
        .isNotEmpty;

    testWidgets('the default keeps rows and scrolls sideways when narrow', (
      tester,
    ) async {
      await tester.pumpWidget(const DsApp(home: Harness(width: 300)));
      expect(scrollsSideways(tester), isTrue);
      // One header per column, one line per row.
      expect(find.text('Müşteri'), findsOneWidget);
    });

    testWidgets('auto shows cards below its breakpoint only', (tester) async {
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 600, layout: DsTableLayout.auto())),
      );
      expect(scrollsSideways(tester), isTrue);
      expect(find.text('Müşteri'), findsOneWidget);
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 360, layout: DsTableLayout.auto())),
      );
      expect(scrollsSideways(tester), isFalse);
      // Every card labels its lines; the bar has one sort menu button.
      expect(find.text('Durum'), findsNWidgets(invoices.length));
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Müşteri'), findsNWidgets(invoices.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a card puts each label before its value, on one line', (
      tester,
    ) async {
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 360, layout: DsTableLayout.cards())),
      );
      final value = tester.getRect(find.text('Atlas Yazılım'));
      final labels = find.text('Müşteri');
      final label = tester.getRect(
        labels.evaluate().length == 1 ? labels : labels.at(1),
      );
      expect(label.right, lessThan(value.left));
      expect(label.center.dy, moreOrLessEquals(value.center.dy, epsilon: 1));
      // Lines stack: the amount sits below the customer.
      expect(tester.getRect(find.text('8250')).top, greaterThan(value.bottom));
      // Numbers keep to the start in a card, after their label.
      expect(tester.getRect(find.text('8250')).left, value.left);
    });

    testWidgets('selection, row tap and the row menu work on cards', (
      tester,
    ) async {
      Invoice? opened;
      await tester.pumpWidget(
        DsApp(
          home: Harness(
            width: 360,
            layout: const DsTableLayout.cards(),
            onRowPressed: (i) => opened = i,
            menu: true,
          ),
        ),
      );
      await tester.tap(find.text('Mavi Tasarım'));
      await tester.pumpAndSettle();
      expect(opened?.id, 3);
      // The checkbox selects.
      await tester.tap(find.byType(DsCheckbox).at(1));
      await tester.pumpAndSettle();
      expect(harness(tester).selected, {1, 2});
      // Select all in the bar.
      await tester.tap(find.byType(DsCheckbox).first);
      await tester.pumpAndSettle();
      expect(harness(tester).selected, {1, 2, 3});
      // Sort from the bar's menu.
      await tester.tap(find.text('Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(DsMenu), matching: find.text('Tutar')),
      );
      await tester.pumpAndSettle();
      expect(harness(tester).sort, const DsTableSort('amount'));
      expect(
        tester.getRect(find.text('Mavi Tasarım')).top,
        lessThan(tester.getRect(find.text('Kuzey Lojistik')).top),
      );
      // Right click opens the row menu.
      await tester.tap(
        find.text('Atlas Yazılım'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sil 2'), findsOneWidget);
    });

    testWidgets('the bar keeps one line: sorting is one menu button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 300, layout: DsTableLayout.cards())),
      );
      final bar = tester.getRect(find.text('Select all'));
      final sort = find.widgetWithText(DsButton, 'Sort by');
      expect(
        tester.getRect(sort).center.dy,
        moreOrLessEquals(bar.center.dy, epsilon: 1),
      );
      // Sorted, the button names the column and says the direction.
      harness(
        tester,
      ).setSort(const DsTableSort('amount', DsTableSortDirection.descending));
      await tester.pump();
      expect(find.widgetWithText(DsButton, 'Tutar'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sort by, Tutar, Sorted descending'),
        findsOneWidget,
      );
      // Its menu checks the sorted column; choosing it again unsorts, as
      // its header would.
      await tester.tap(find.widgetWithText(DsButton, 'Tutar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(DsMenu), matching: find.text('Tutar')),
      );
      await tester.pumpAndSettle();
      expect(harness(tester).sort, isNull);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('the keyboard moves between cards and selects', (tester) async {
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 360, layout: DsTableLayout.cards())),
      );
      // Select all, the sort menu button, then the cards.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'DsTable row');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(harness(tester).selected, {2, 3});
    });

    testWidgets('screen readers hear a list of cards', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const DsApp(home: Harness(width: 360, layout: DsTableLayout.cards())),
      );
      expect(tester.takeException(), isNull);
      final box = tester.getSemantics(
        find.bySemanticsLabel('Select Atlas Yazılım'),
      );
      SemanticsNode? item = box;
      while (item != null && item.role != SemanticsRole.listItem) {
        item = item.parent;
      }
      expect(item, isNotNull);
      expect(
        item!.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(item.parent!.role, SemanticsRole.list);
      expect(item.parent!.label, 'Faturalar');
      handle.dispose();
    });

    testWidgets('loading and empty stay valid as cards', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (rows, loading) in [
        (const <Invoice>[], true),
        (invoices, true),
        (const <Invoice>[], false),
      ]) {
        await tester.pumpWidget(
          DsApp(
            home: SizedBox(
              width: 360,
              height: 400,
              child: DsTable<Invoice>(
                layout: const DsTableLayout.cards(),
                columns: columns(),
                rows: rows,
                loading: loading,
                rowKey: (i) => i.id,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      handle.dispose();
    });
  });
}
