// Regression tests: the table's sort cache, the order of mixed
// values and selection changes made within one frame.
import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class Item {
  Item(this.id, this.name, this.amount);
  final int id;
  String name;
  final Object? amount;
}

/// How often the table called each column closure.
class Calls {
  int value = 0;
  int text = 0;
  int key = 0;

  void reset() => value = text = key = 0;
}

/// A controlled table whose columns are built inline on every build, as
/// the DsTable docs show.
class Inline extends StatefulWidget {
  const Inline({
    super.key,
    required this.rows,
    required this.calls,
    this.sort,
    this.rowsVersion,
    this.height = 400,
  });

  final List<Item> rows;
  final Calls calls;
  final DsTableSort? sort;
  final Object? rowsVersion;
  final double height;

  @override
  State<Inline> createState() => InlineState();
}

class InlineState extends State<Inline> {
  late DsTableSort? sort = widget.sort;
  Set<Object> selected = {};
  late List<Item> rows = widget.rows;
  Object? rowsVersion;

  void update(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) {
    final calls = widget.calls;
    return SizedBox(
      width: 600,
      height: widget.height,
      child: DsTable<Item>(
        rows: rows,
        rowsVersion: rowsVersion ?? widget.rowsVersion,
        rowKey: (i) {
          calls.key++;
          return i.id;
        },
        sort: sort,
        onSortChanged: (s) => setState(() => sort = s),
        selected: selected,
        onSelectionChanged: (s) => setState(() => selected = s),
        columns: [
          DsTableColumn<Item>(
            id: 'name',
            label: 'Name',
            value: (i) {
              calls.value++;
              return i.name;
            },
            text: (i) {
              calls.text++;
              return i.name;
            },
            sortable: true,
          ),
          DsTableColumn<Item>(
            id: 'amount',
            label: 'Amount',
            value: (i) => i.amount,
            text: (i) {
              calls.text++;
              return '${i.amount}';
            },
            numeric: true,
            sortable: true,
            width: const .intrinsic(),
          ),
        ],
      ),
    );
  }
}

InlineState inline(WidgetTester tester) =>
    tester.state<InlineState>(find.byType(Inline));

/// The texts of [names] in on-screen order, top to bottom.
List<String> shown(WidgetTester tester, Iterable<String> names) {
  final found = [
    for (final n in names)
      if (find.text(n).evaluate().isNotEmpty) n,
  ];
  return found..sort(
    (a, b) => tester
        .getTopLeft(find.text(a))
        .dy
        .compareTo(tester.getTopLeft(find.text(b)).dy),
  );
}

List<Item> people(int n) => [
  for (var i = 0; i < n; i++)
    Item(i, 'Müşteri ${(i * 7919) % n} Çağlar', (i * 31) % 100000),
];

void main() {
  group('sort cache', () {
    testWidgets('inline columns: parent rebuilds neither sort nor measure '
        '10,000 rows again', (tester) async {
      final calls = Calls();
      await tester.pumpWidget(host(Inline(rows: people(10000), calls: calls)));

      // Baseline: the click that sorts 10,000 rows by text.
      calls.reset();
      final sort = Stopwatch()..start();
      await tester.tap(find.text('Name'));
      await tester.pump();
      sort.stop();
      expect(
        calls.value,
        10000,
        reason:
            'one value() per row, not per '
            'comparison',
      );

      // 20 unrelated parent rebuilds with new inline columns.
      calls.reset();
      final rebuilds = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        inline(tester).update(() {});
        await tester.pump();
      }
      rebuilds.stop();
      expect(calls.value, 0, reason: 'no re-sort');
      // Only the rows built (about 16: two cells and the checkbox name) ask
      // for text; an intrinsic column measuring 200 rows asks 200 more.
      expect(calls.text, lessThan(20 * 100));
      expect(calls.key, lessThan(20 * 30), reason: 'no rowKey() per row');
      // Each rebuild used to cost a full sort (0.55 s at 10,000 rows).
      expect(
        rebuilds.elapsedMicroseconds,
        lessThan(sort.elapsedMicroseconds * 8 + 100000),
        reason:
            '20 rebuilds ${rebuilds.elapsedMilliseconds} ms vs one sort '
            '${sort.elapsedMilliseconds} ms',
      );
    });

    testWidgets('the same rows in a new list are not sorted again', (
      tester,
    ) async {
      final calls = Calls();
      await tester.pumpWidget(
        host(
          Inline(
            rows: people(50),
            calls: calls,
            sort: const DsTableSort('name'),
          ),
        ),
      );
      calls.reset();
      inline(tester).update(() {
        final s = inline(tester);
        s.rows = [...s.rows];
      });
      await tester.pump();
      expect(calls.value, 0);
    });

    testWidgets('a row replaced in place (same list) shows and sorts', (
      tester,
    ) async {
      final rows = [
        Item(1, 'Charlie', 1),
        Item(2, 'Alpha', 2),
        Item(3, 'Bravo', 3),
      ];
      await tester.pumpWidget(
        host(
          Inline(rows: rows, calls: Calls(), sort: const DsTableSort('name')),
        ),
      );
      const names = ['Alpha', 'Bravo', 'Charlie', 'Zulu'];
      expect(shown(tester, names), ['Alpha', 'Bravo', 'Charlie']);
      inline(tester).update(() => rows[1] = Item(2, 'Zulu', 2));
      await tester.pump();
      expect(shown(tester, names), ['Bravo', 'Charlie', 'Zulu']);
    });

    testWidgets('a field edited in place sorts again with rowsVersion', (
      tester,
    ) async {
      final rows = [
        Item(1, 'Charlie', 1),
        Item(2, 'Alpha', 2),
        Item(3, 'Bravo', 3),
      ];
      await tester.pumpWidget(
        host(
          Inline(rows: rows, calls: Calls(), sort: const DsTableSort('name')),
        ),
      );
      const names = ['Alpha', 'Bravo', 'Charlie', 'Zulu'];
      inline(tester).update(() {
        rows[1].name = 'Zulu';
        inline(tester).rowsVersion = 1;
      });
      await tester.pump();
      expect(shown(tester, names), ['Bravo', 'Charlie', 'Zulu']);
    });

    testWidgets('a new sort direction or language sorts again', (tester) async {
      final rows = [Item(1, 'Ilık', 1), Item(2, 'İnce', 2), Item(3, 'Hız', 3)];
      Widget table(Locale locale) => DsApp(
        locale: locale,
        home: Inline(
          rows: rows,
          calls: Calls(),
          sort: const DsTableSort('name'),
        ),
      );
      const names = ['Ilık', 'İnce', 'Hız'];
      await tester.pumpWidget(table(const Locale('tr')));
      expect(shown(tester, names), ['Hız', 'Ilık', 'İnce']);
      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(shown(tester, names), ['İnce', 'Ilık', 'Hız']);
      await tester.tap(find.text('Name'));
      await tester.pump();
      await tester.tap(find.text('Name'));
      await tester.pump();
      // English: İ folds to i, I to i; Hız first either way.
      await tester.pumpWidget(table(const Locale('en')));
      expect(shown(tester, names).first, 'Hız');
    });
  });

  group('mixed values', () {
    testWidgets('a column of numbers, text and nulls sorts without throwing', (
      tester,
    ) async {
      final rows = [
        Item(1, 'a', 30),
        Item(2, 'b', 'n/a'),
        Item(3, 'c', null),
        Item(4, 'd', 4.5),
        Item(5, 'e', DateTime(2026)),
        Item(6, 'f', 10),
      ];
      await tester.pumpWidget(host(Inline(rows: rows, calls: Calls())));
      List<String> order() =>
          shown(tester, [for (final r in rows) '${r.amount}']);
      await tester.tap(find.text('Amount'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Numbers, then text, then other comparables; empty last.
      expect(order(), ['4.5', '10', '30', 'n/a', '${DateTime(2026)}', 'null']);
      await tester.tap(find.text('Amount'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(order(), ['${DateTime(2026)}', 'n/a', '30', '10', '4.5', 'null']);
    });

    test('compareValues is a total order across kinds', () {
      final values = <Object?>[
        3,
        'n/a',
        null,
        1.5,
        DateTime(2020),
        const Duration(days: 1),
        true,
        'Ç',
        -2,
      ];
      for (final a in values) {
        for (final b in values) {
          final ab = DsTableColumn.compareValues(a, b, language: 'tr');
          final ba = DsTableColumn.compareValues(b, a, language: 'tr');
          expect(ab.sign, -ba.sign, reason: '$a vs $b');
          for (final c in values) {
            final bc = DsTableColumn.compareValues(b, c, language: 'tr');
            final ac = DsTableColumn.compareValues(a, c, language: 'tr');
            if (ab <= 0 && bc <= 0) {
              expect(ac, lessThanOrEqualTo(0), reason: '$a ≤ $b ≤ $c');
            }
          }
        }
      }
    });
  });

  testWidgets('10,000 rows: sort both ways and select all quickly', (
    tester,
  ) async {
    final calls = Calls();
    await tester.pumpWidget(host(Inline(rows: people(10000), calls: calls)));
    final sw = Stopwatch()..start();
    await tester.tap(find.text('Amount'));
    await tester.pump();
    await tester.tap(find.text('Amount'));
    await tester.pump();
    await tester.tap(find.text('Name'));
    await tester.pump();
    sw.stop();
    await tester.tap(find.byType(DsCheckbox).first);
    await tester.pump();
    expect(inline(tester).selected, hasLength(10000));
    expect(
      sw.elapsedMilliseconds,
      lessThan(3000),
      reason: 'sorting took ${sw.elapsedMilliseconds} ms',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('two Shift+Down within one frame keep both rows', (tester) async {
    final rows = [for (var i = 0; i < 20; i++) Item(i, 'Row $i', i)];
    await tester.pumpWidget(
      DsApp(
        home: Inline(rows: rows, calls: Calls()),
      ),
    );
    await tester.tap(find.text('Row 0'));
    await tester.pump();
    inline(tester).update(() => inline(tester).selected = {});
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    // Tab: select all, two sort buttons, then the rows.
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'DsTable row');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    // Two presses (or key repeats) before the next frame.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(inline(tester).selected, {0, 1, 2});
  });
}
