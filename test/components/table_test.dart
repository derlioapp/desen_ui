import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class Invoice {
  const Invoice(this.id, this.customer, this.status, this.amount);
  final int id;
  final String customer;
  final String status;
  final int? amount;
}

const invoices = [
  Invoice(1, 'Kuzey Lojistik', 'Ödendi', 12480),
  Invoice(2, 'Atlas Yazılım', 'Bekliyor', 8250),
  Invoice(3, 'Mavi Tasarım', 'Ödendi', 4900),
  Invoice(4, 'Ege Gıda', 'Gecikti', 2175),
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
    text: (i) => i.status,
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

/// A controlled table: sort and selection live here.
class Harness extends StatefulWidget {
  const Harness({
    super.key,
    this.rows = invoices,
    this.selectable = true,
    this.onRowPressed,
    this.width = 480,
    this.height,
    this.loading = false,
    this.empty,
    this.error,
    this.sortLocally = true,
    this.menu = false,
    this.columns,
  });

  final List<Invoice> rows;
  final bool selectable;
  final ValueChanged<Invoice>? onRowPressed;
  final double? width;
  final double? height;
  final bool loading;
  final Widget? empty;
  final Widget? error;
  final bool sortLocally;
  final bool menu;
  final List<DsTableColumn<Invoice>>? columns;

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  DsTableSort? sort;
  Set<Object> selected = {};
  late List<Invoice> rows = widget.rows;

  void update(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) {
    final table = DsTable<Invoice>(
      semanticLabel: 'Faturalar',
      columns: widget.columns ?? columns(),
      rows: rows,
      rowKey: (i) => i.id,
      sort: sort,
      sortLocally: widget.sortLocally,
      onSortChanged: (s) => setState(() => sort = s),
      selected: selected,
      onSelectionChanged: widget.selectable
          ? (s) => setState(() => selected = s)
          : null,
      onRowPressed: widget.onRowPressed,
      loading: widget.loading,
      emptyView: widget.empty,
      errorView: widget.error,
      rowMenuBuilder: widget.menu
          ? (_, i) => [DsMenuItem(onPressed: () {}, label: Text('Sil ${i.id}'))]
          : null,
    );
    return SizedBox(width: widget.width, height: widget.height, child: table);
  }
}

HarnessState harness(WidgetTester tester) =>
    tester.state<HarnessState>(find.byType(Harness));

/// The customer names in on-screen order, top to bottom.
List<String> order(WidgetTester tester) {
  final names = {for (final i in invoices) i.customer};
  final found =
      [
        for (final name in names)
          if (find.text(name).evaluate().isNotEmpty) name,
      ]..sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
  return found;
}

/// The fill painted behind the row that shows [text].
Color? rowFill(WidgetTester tester, String text) {
  final box = tester.widget<AnimatedContainer>(
    find
        .ancestor(of: find.text(text), matching: find.byType(AnimatedContainer))
        .first,
  );
  return (box.decoration! as DsBoxDecoration).color;
}

/// The checkbox in the header (select all).
DsCheckbox headerCheckbox(WidgetTester tester) =>
    tester.widget<DsCheckbox>(find.byType(DsCheckbox).first);

Future<void> key(
  WidgetTester tester,
  LogicalKeyboardKey k, {
  bool shift = false,
  bool control = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(k);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

bool hasFocus(WidgetTester tester, String rowText) {
  final primary = FocusManager.instance.primaryFocus;
  final context = primary?.context;
  if (context == null || primary!.debugLabel != 'DsTable row') return false;
  return find
      .descendant(
        of: find.byElementPredicate((e) => identical(e, context)),
        matching: find.text(rowText),
      )
      .evaluate()
      .isNotEmpty;
}

/// An app root: Tab and the other default keys work.
Widget app(Widget child, {DsThemeData? theme}) => DsApp(
  theme: theme,
  home: Center(child: child),
);

void main() {
  testWidgets('renders header and rows without a wrapper (R3)', (tester) async {
    await tester.pumpWidget(host(const Harness()));
    expect(find.text('Müşteri'), findsOneWidget);
    expect(find.text('Kuzey Lojistik'), findsOneWidget);
    expect(find.text('12480'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('sorting', () {
    testWidgets('a header cycles ascending → descending → unsorted', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Harness()));
      final original = order(tester);
      expect(original, [
        'Kuzey Lojistik',
        'Atlas Yazılım',
        'Mavi Tasarım',
        'Ege Gıda',
      ]);

      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      expect(harness(tester).sort, const DsTableSort('customer'));
      expect(order(tester), [
        'Atlas Yazılım',
        'Ege Gıda',
        'Kuzey Lojistik',
        'Mavi Tasarım',
      ]);

      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      expect(
        harness(tester).sort,
        const DsTableSort('customer', DsTableSortDirection.descending),
      );
      expect(order(tester), [
        'Mavi Tasarım',
        'Kuzey Lojistik',
        'Ege Gıda',
        'Atlas Yazılım',
      ]);

      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      expect(harness(tester).sort, isNull);
      expect(order(tester), original);
    });

    testWidgets('another column starts ascending again', (tester) async {
      await tester.pumpWidget(host(const Harness()));
      await tester.tap(find.text('Müşteri'));
      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      await tester.tap(find.text('Tutar'));
      await tester.pump();
      expect(harness(tester).sort, const DsTableSort('amount'));
      expect(order(tester).first, 'Ege Gıda');
    });

    testWidgets('numbers sort by value; empty values stay last both ways', (
      tester,
    ) async {
      const rows = [
        Invoice(1, 'Kuzey Lojistik', 'Ödendi', 900),
        Invoice(2, 'Atlas Yazılım', 'Bekliyor', null),
        Invoice(3, 'Mavi Tasarım', 'Ödendi', 10000),
        Invoice(4, 'Ege Gıda', 'Gecikti', 25),
      ];
      await tester.pumpWidget(host(const Harness(rows: rows)));
      await tester.tap(find.text('Tutar'));
      await tester.pump();
      // 25 < 900 < 10000 by value (not "10000" < "25" < "900" as text).
      expect(order(tester), [
        'Ege Gıda',
        'Kuzey Lojistik',
        'Mavi Tasarım',
        'Atlas Yazılım',
      ]);
      await tester.tap(find.text('Tutar'));
      await tester.pump();
      expect(order(tester), [
        'Mavi Tasarım',
        'Kuzey Lojistik',
        'Ege Gıda',
        'Atlas Yazılım',
      ]);
    });

    testWidgets('equal values keep their order (stable)', (tester) async {
      const rows = [
        Invoice(1, 'B', 'x', 1),
        Invoice(2, 'A', 'x', 1),
        Invoice(3, 'C', 'x', 0),
      ];
      final cols = [
        DsTableColumn<Invoice>(
          id: 'name',
          label: 'Ad',
          value: (i) => i.customer,
        ),
        DsTableColumn<Invoice>(
          id: 'amount',
          label: 'Tutar',
          value: (i) => i.amount,
          sortable: true,
        ),
      ];
      await tester.pumpWidget(host(Harness(rows: rows, columns: cols)));
      await tester.tap(find.text('Tutar'));
      await tester.pump();
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('C') < y('B') && y('B') < y('A'), isTrue);
    });

    testWidgets('a custom comparator wins over the value', (tester) async {
      final cols = [
        DsTableColumn<Invoice>(
          id: 'customer',
          label: 'Müşteri',
          value: (i) => i.customer,
          sortable: true,
          // By name length.
          comparator: (a, b) => a.customer.length.compareTo(b.customer.length),
        ),
      ];
      await tester.pumpWidget(host(Harness(columns: cols)));
      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      expect(order(tester).first, 'Ege Gıda');
      expect(order(tester).last, 'Kuzey Lojistik');
    });

    testWidgets('sortLocally: false leaves the order to the app', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Harness(sortLocally: false)));
      await tester.tap(find.text('Müşteri'));
      await tester.pump();
      expect(harness(tester).sort, const DsTableSort('customer'));
      expect(order(tester).first, 'Kuzey Lojistik');
    });

    testWidgets('without onSortChanged the headers are plain labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 480,
            child: DsTable<Invoice>(
              columns: columns(),
              rows: invoices,
              rowKey: (i) => i.id,
            ),
          ),
        ),
      );
      expect(find.byType(DsPressable), findsNothing);
    });

    testWidgets('the sorted header announces its direction', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const Harness()));
      await tester.tap(find.text('Tutar'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Tutar')),
        matchesSemantics(
          label: 'Tutar',
          value: 'Sorted ascending',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('selection', () {
    testWidgets('a click on a row toggles it; the fill is the soft '
        'selection', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(host(const Harness(), theme: theme));
      await tester.tap(find.text('Atlas Yazılım'));
      await tester.pump();
      expect(harness(tester).selected, {2});
      await tester.pump(const Duration(milliseconds: 400));
      expect(rowFill(tester, 'Atlas Yazılım'), theme.colors.selection);
      await tester.tap(find.text('Atlas Yazılım'));
      await tester.pump();
      expect(harness(tester).selected, isEmpty);
    });

    testWidgets('the soft fill stays soft under the fill selection style', (
      tester,
    ) async {
      final theme = DsThemeData(
        platform: TargetPlatform.macOS,
        selectionStyle: DsSelectionStyle.strong,
      );
      await tester.pumpWidget(host(const Harness(), theme: theme));
      harness(tester).update(() => harness(tester).selected = {1});
      await tester.pump();
      expect(rowFill(tester, 'Kuzey Lojistik'), theme.colors.selection);
    });

    testWidgets('with onRowPressed, a click opens and the checkbox selects', (
      tester,
    ) async {
      Invoice? opened;
      await tester.pumpWidget(host(Harness(onRowPressed: (i) => opened = i)));
      await tester.tap(find.text('Mavi Tasarım'));
      await tester.pump();
      expect(opened?.id, 3);
      expect(harness(tester).selected, isEmpty);
      await tester.tap(find.byType(DsCheckbox).at(3));
      await tester.pump();
      expect(harness(tester).selected, {3});
    });

    testWidgets('select all is tri-state', (tester) async {
      await tester.pumpWidget(host(const Harness()));
      expect(headerCheckbox(tester).value, isFalse);
      await tester.tap(find.byType(DsCheckbox).at(2));
      await tester.pump();
      expect(headerCheckbox(tester).value, isNull); // mixed
      // Mixed → all.
      await tester.tap(find.byType(DsCheckbox).first);
      await tester.pump();
      expect(harness(tester).selected, {1, 2, 3, 4});
      expect(headerCheckbox(tester).value, isTrue);
      // All → none.
      await tester.tap(find.byType(DsCheckbox).first);
      await tester.pump();
      expect(harness(tester).selected, isEmpty);
    });

    testWidgets('select all keeps keys from other pages', (tester) async {
      await tester.pumpWidget(host(const Harness()));
      harness(tester).update(() => harness(tester).selected = {99});
      await tester.pump();
      await tester.tap(find.byType(DsCheckbox).first);
      await tester.pump();
      expect(harness(tester).selected, {99, 1, 2, 3, 4});
      await tester.tap(find.byType(DsCheckbox).first);
      await tester.pump();
      expect(harness(tester).selected, {99});
    });

    testWidgets('selection follows the item after a re-sort', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(host(const Harness(), theme: theme));
      await tester.tap(find.text('Ege Gıda'));
      await tester.pump();
      await tester.tap(find.text('Tutar'));
      await tester.pump(const Duration(milliseconds: 400));
      // Ege Gıda (2175) is now first, and still the selected one.
      expect(order(tester).first, 'Ege Gıda');
      expect(harness(tester).selected, {4});
      expect(rowFill(tester, 'Ege Gıda'), theme.colors.selection);
      expect(rowFill(tester, 'Kuzey Lojistik'), isNot(theme.colors.selection));
      // The checkbox moved with it.
      final boxes = tester.widgetList<DsCheckbox>(find.byType(DsCheckbox));
      expect(
        [for (final b in boxes) b.value],
        [null, true, false, false, false],
      );
    });

    testWidgets('shift-click selects a range', (tester) async {
      await tester.pumpWidget(host(const Harness()));
      await tester.tap(find.text('Kuzey Lojistik'));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('Mavi Tasarım'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(harness(tester).selected, {1, 2, 3});
    });

    testWidgets('selected rows are announced as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const Harness()));
      await tester.tap(find.text('Ege Gıda'));
      await tester.pump();
      final row = tester.getSemantics(find.text('Ege Gıda')).parent!;
      expect(row.role, SemanticsRole.row);
      expect(row.flagsCollection.isSelected.toBoolOrNull(), isTrue);
      final other = tester.getSemantics(find.text('Atlas Yazılım')).parent!;
      expect(other.flagsCollection.isSelected.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('keyboard', () {
    Future<void> tabToRows(WidgetTester tester) async {
      // Select all, Müşteri, Tutar, then the rows.
      for (var i = 0; i < 4; i++) {
        await key(tester, LogicalKeyboardKey.tab);
      }
    }

    testWidgets('Tab order: select all, sort buttons, one stop for the '
        'rows', (tester) async {
      await tester.pumpWidget(app(const Harness()));
      await key(tester, LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<DsCheckbox>()
            ?.semanticLabel,
        'Select all rows',
      );
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      expect(hasFocus(tester, 'Kuzey Lojistik'), isTrue);
      // One stop: the next Tab leaves the rows.
      await key(tester, LogicalKeyboardKey.tab);
      expect(hasFocus(tester, 'Atlas Yazılım'), isFalse);
    });

    testWidgets('arrows, Home and End move between rows', (tester) async {
      await tester.pumpWidget(app(const Harness()));
      await tabToRows(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(hasFocus(tester, 'Atlas Yazılım'), isTrue);
      await key(tester, LogicalKeyboardKey.end);
      expect(hasFocus(tester, 'Ege Gıda'), isTrue);
      await key(tester, LogicalKeyboardKey.arrowDown); // stays
      expect(hasFocus(tester, 'Ege Gıda'), isTrue);
      await key(tester, LogicalKeyboardKey.home);
      expect(hasFocus(tester, 'Kuzey Lojistik'), isTrue);
      await key(tester, LogicalKeyboardKey.arrowUp); // stays
      expect(hasFocus(tester, 'Kuzey Lojistik'), isTrue);
    });

    testWidgets('Space selects, Enter activates', (tester) async {
      Invoice? opened;
      await tester.pumpWidget(app(Harness(onRowPressed: (i) => opened = i)));
      await tabToRows(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.space);
      expect(harness(tester).selected, {2});
      expect(opened, isNull);
      await key(tester, LogicalKeyboardKey.enter);
      expect(opened?.id, 2);
      await key(tester, LogicalKeyboardKey.space);
      expect(harness(tester).selected, isEmpty);
    });

    testWidgets('Shift+arrow extends, Ctrl+A selects all', (tester) async {
      await tester.pumpWidget(app(const Harness()));
      await tabToRows(tester);
      await key(tester, LogicalKeyboardKey.arrowDown, shift: true);
      expect(harness(tester).selected, {1, 2});
      expect(hasFocus(tester, 'Atlas Yazılım'), isTrue);
      await key(tester, LogicalKeyboardKey.keyA, control: true);
      expect(harness(tester).selected, {1, 2, 3, 4});
    });

    testWidgets('Tab returns to the last active row', (tester) async {
      await tester.pumpWidget(app(const Harness()));
      await tabToRows(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.tab, shift: true);
      expect(hasFocus(tester, 'Mavi Tasarım'), isFalse);
      await key(tester, LogicalKeyboardKey.tab);
      expect(hasFocus(tester, 'Mavi Tasarım'), isTrue);
    });

    testWidgets('a click moves the Tab stop without showing focus', (
      tester,
    ) async {
      await tester.pumpWidget(app(Harness(onRowPressed: (_) {})));
      await tester.tap(find.text('Mavi Tasarım'));
      await tester.pump();
      expect(hasFocus(tester, 'Mavi Tasarım'), isFalse); // K-42
      await tabToRows(tester);
      expect(hasFocus(tester, 'Mavi Tasarım'), isTrue);
    });

    testWidgets('the focused row draws an inner ring', (tester) async {
      useTraditionalHighlights();
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(app(const Harness(), theme: theme));
      await tabToRows(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final box = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Kuzey Lojistik'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final shadows = (box.decoration! as DsBoxDecoration).shadows;
      expect(
        shadows.any((s) => s.inset && s.color == theme.colors.focus),
        isTrue,
      );
    });
  });

  group('pointer', () {
    testWidgets('hover fills the row', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      useTraditionalHighlights();
      await tester.pumpWidget(host(const Harness(), theme: theme));
      await hover(tester, find.text('Mavi Tasarım'));
      expect(rowFill(tester, 'Mavi Tasarım'), theme.colors.hover);
      expect(rowFill(tester, 'Ege Gıda'), isNot(theme.colors.hover));
    });

    testWidgets('a selected row hovers one step deeper (K-61)', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      useTraditionalHighlights();
      await tester.pumpWidget(host(const Harness(), theme: theme));
      harness(tester).update(() => harness(tester).selected = {3});
      await tester.pump();
      await hover(tester, find.text('Mavi Tasarım'));
      expect(rowFill(tester, 'Mavi Tasarım'), theme.colors.selectionHover);
    });

    testWidgets('right click opens the row menu', (tester) async {
      await tester.pumpWidget(
        const DsApp(home: Center(child: Harness(menu: true))),
      );
      await tester.tap(
        find.text('Atlas Yazılım'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sil 2'), findsOneWidget);
    });

    testWidgets('Shift+F10 opens the focused row menu', (tester) async {
      await tester.pumpWidget(
        const DsApp(home: Center(child: Harness(menu: true))),
      );
      for (var i = 0; i < 4; i++) {
        await key(tester, LogicalKeyboardKey.tab);
      }
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.f10, shift: true);
      await tester.pumpAndSettle();
      expect(find.text('Sil 2'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('loading with no rows shows skeleton rows and one '
        '"Loading"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const Harness(rows: [], loading: true)));
      await tester.pump(const Duration(milliseconds: 100));
      // 5 rows × 3 columns.
      expect(find.byType(DsSkeleton), findsNWidgets(15));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(headerCheckbox(tester).onChanged, isNull);
      handle.dispose();
    });

    testWidgets('loading with rows adds one skeleton row at the end', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Harness(loading: true)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Ege Gıda'), findsOneWidget);
      expect(find.byType(DsSkeleton), findsNWidgets(3));
      expect(
        tester.getTopLeft(find.byType(DsSkeleton).first).dy,
        greaterThan(tester.getTopLeft(find.text('Ege Gıda')).dy),
      );
    });

    testWidgets('no rows shows a compact "No results"', (tester) async {
      await tester.pumpWidget(host(const Harness(rows: [])));
      expect(find.text('No results'), findsOneWidget);
      expect(find.byType(DsEmptyState), findsOneWidget);
    });

    testWidgets('the empty slot takes the app\'s DsEmptyState, compact', (
      tester,
    ) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        host(
          Harness(
            rows: const [],
            empty: DsEmptyState(
              title: const Text('Sonuç bulunamadı'),
              description: const Text(
                '“Ödendi” filtresiyle eşleşen kayıt yok.',
              ),
              actions: [
                DsButton(
                  variant: .ghost,
                  size: .sm,
                  onPressed: () {},
                  child: const Text('Filtreleri temizle'),
                ),
              ],
            ),
          ),
          theme: theme,
        ),
      );
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
      expect(find.text('No results'), findsNothing);
      // The table's compact title: 14 / 600, not the 16px heading.
      final title = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Sonuç bulunamadı'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(title.style.fontSize, theme.typography.bodyStrong.fontSize);
    });

    testWidgets('the error slot replaces the rows', (tester) async {
      await tester.pumpWidget(
        host(
          const Harness(
            error: DsEmptyState(title: Text('Veriler yüklenemedi')),
          ),
        ),
      );
      expect(find.text('Veriler yüklenemedi'), findsOneWidget);
      expect(find.text('Kuzey Lojistik'), findsNothing);
    });
  });

  testWidgets('semantics: table → rows → cells and column headers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const Harness(height: 300)));
    final cell = tester.getSemantics(find.text('Kuzey Lojistik'));
    expect(cell.role, SemanticsRole.cell);
    final row = cell.parent!;
    expect(row.role, SemanticsRole.row);
    final table = row.parent!;
    expect(table.role, SemanticsRole.table);
    expect(table.label, 'Faturalar');
    expect(table.hint, '4 rows');
    final roles = <SemanticsRole>[];
    table.visitChildren((n) {
      roles.add(n.role);
      return true;
    });
    expect(roles, everyElement(SemanticsRole.row));
    expect(roles, hasLength(5)); // header + 4 rows
    final header = tester.getSemantics(find.text('Durum'));
    expect(header.role, SemanticsRole.columnHeader);
    expect(header.parent!.role, SemanticsRole.row);
    handle.dispose();
  });

  testWidgets('semantics stay valid while loading, empty and in error', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final h in const [
      Harness(rows: [], loading: true, height: 300),
      Harness(loading: true, height: 300),
      Harness(rows: [], height: 300),
      Harness(error: Text('Hata'), height: 300),
    ]) {
      await tester.pumpWidget(host(h));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
    handle.dispose();
  });

  group('layout', () {
    testWidgets('numbers are tabular and end-aligned', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(host(const Harness(), theme: theme));
      final amount = tester.getRect(find.text('12480'));
      final small = tester.getRect(find.text('2175'));
      expect(amount.right, moreOrLessEquals(small.right, epsilon: 0.5));
      final style = DefaultTextStyle.of(tester.element(find.text('12480')))
          .style
          .merge(tester.widget<Text>(find.text('12480')).textSpan!.style);
      expect(style.fontFamily, contains(theme.typography.family));
      expect(style.fontFeatures, [const FontFeature.tabularFigures()]);
    });

    testWidgets('columns wider than the table scroll sideways', (tester) async {
      await tester.pumpWidget(host(const Harness(width: 240, height: 300)));
      expect(tester.takeException(), isNull);
      final scroll = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      await tester.drag(find.text('Kuzey Lojistik'), const Offset(-400, 0));
      await tester.pump();
      expect(scroll.position.pixels, greaterThan(0));
      // The header scrolls with the rows.
      expect(
        tester.getTopLeft(find.text('Müşteri')).dx,
        moreOrLessEquals(
          tester.getTopLeft(find.text('Kuzey Lojistik')).dx,
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('hidden columns fade the edge they hide behind', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Harness(width: 240, height: 300)));
      await tester.pump();
      expect(find.byType(ShaderMask), findsOneWidget, reason: 'more after');
      final scroll = tester.state<ScrollableState>(
        find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(find.byType(ShaderMask), findsOneWidget, reason: 'more before');
      await tester.pumpWidget(host(const Harness(width: 900, height: 300)));
      await tester.pump();
      expect(find.byType(ShaderMask), findsNothing, reason: 'all columns fit');
    });

    testWidgets('in a bounded height the header sticks while rows scroll', (
      tester,
    ) async {
      final rows = [
        for (var i = 0; i < 60; i++) Invoice(i, 'Müşteri $i', 'Ödendi', i),
      ];
      await tester.pumpWidget(host(Harness(rows: rows, height: 300)));
      final headerTop = tester.getTopLeft(find.text('Müşteri')).dy;
      await tester.drag(find.text('Müşteri 3'), const Offset(0, -200));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Müşteri')).dy, headerTop);
      expect(find.text('Müşteri 0'), findsNothing);
    });

    testWidgets('10,000 rows build lazily', (tester) async {
      var built = 0;
      final rows = [
        for (var i = 0; i < 10000; i++) Invoice(i, 'Satır $i', 'Ödendi', i),
      ];
      final cols = [
        DsTableColumn<Invoice>(
          id: 'name',
          label: 'Ad',
          cell: (context, i) {
            built++;
            return Text(i.customer);
          },
          value: (i) => i.customer,
        ),
        DsTableColumn<Invoice>(
          id: 'n',
          label: 'No',
          value: (i) => i.amount,
          numeric: true,
          sortable: true,
        ),
      ];
      await tester.pumpWidget(
        app(Harness(rows: rows, columns: cols, height: 400)),
      );
      // A screenful plus the cache extent, not ten thousand.
      expect(built, lessThan(40));
      expect(find.text('Satır 9999'), findsNothing);

      // End jumps to the last row and focuses it.
      for (var i = 0; i < 3; i++) {
        await key(tester, LogicalKeyboardKey.tab);
      }
      expect(hasFocus(tester, 'Satır 0'), isTrue);
      await key(tester, LogicalKeyboardKey.end);
      await tester.pump();
      await tester.pump();
      expect(find.text('Satır 9999'), findsOneWidget);
      expect(hasFocus(tester, 'Satır 9999'), isTrue);
      expect(built, lessThan(120));

      // Sorting 10,000 rows descending puts the last one first.
      built = 0;
      await tester.tap(find.text('No'));
      await tester.tap(find.text('No'));
      await tester.pump();
      expect(built, lessThan(80));
    });

    testWidgets('Page Down moves a screenful', (tester) async {
      final rows = [
        for (var i = 0; i < 100; i++) Invoice(i, 'Satır $i', 'Ödendi', i),
      ];
      await tester.pumpWidget(app(Harness(rows: rows, height: 400)));
      for (var i = 0; i < 4; i++) {
        await key(tester, LogicalKeyboardKey.tab);
      }
      expect(hasFocus(tester, 'Satır 0'), isTrue);
      await key(tester, LogicalKeyboardKey.pageDown);
      await tester.pump();
      final focused = [
        for (var i = 1; i < 20; i++)
          if (hasFocus(tester, 'Satır $i')) i,
      ];
      expect(focused.single, greaterThan(3));
    });

    testWidgets('RTL mirrors the columns', (tester) async {
      await tester.pumpWidget(
        host(const Harness(), direction: TextDirection.rtl),
      );
      final name = tester.getRect(find.text('Kuzey Lojistik'));
      final amount = tester.getRect(find.text('12480'));
      final box = tester.getRect(find.byType(DsCheckbox).at(1));
      expect(
        box.left,
        greaterThanOrEqualTo(name.right),
      ); // checkbox at the right
      expect(amount.right, lessThan(name.left)); // numbers at the left
      // End alignment in RTL is the left edge.
      final small = tester.getRect(find.text('2175'));
      expect(amount.left, moreOrLessEquals(small.left, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('text scale 2.0 grows rows without clipping', (tester) async {
      final theme = DsThemeData(platform: TargetPlatform.macOS);
      await tester.pumpWidget(
        host(const Harness(width: 700), theme: theme, textScale: 2),
      );
      expect(tester.takeException(), isNull);
      final text = tester.getRect(find.text('Atlas Yazılım'));
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text('Atlas Yazılım'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(row.height, greaterThan(theme.sizes.listRow));
      expect(row.top, lessThanOrEqualTo(text.top));
      expect(row.bottom, greaterThanOrEqualTo(text.bottom));
      // The name still fits: widths grow with the text.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Atlas Yazılım'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('an unbounded parent sizes the table to its rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SingleChildScrollView(child: Harness(height: null))),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ege Gıda'), findsOneWidget);
    });

    testWidgets('in a Row (unbounded width) it takes the minimum widths', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Row(children: [Harness(width: null)])),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Ege Gıda'), findsOneWidget);
    });
  });

  testWidgets('touch density keeps rows at the list row height', (
    tester,
  ) async {
    final theme = DsThemeData(
      platform: TargetPlatform.macOS,
      density: DsDensity.touch,
    );
    await tester.pumpWidget(host(const Harness(), theme: theme));
    final row = tester.getSize(
      find
          .ancestor(
            of: find.text('Atlas Yazılım'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(row.height, theme.sizes.listRow);
  });

  testWidgets('the active row stays alive off screen; Tab scrolls back', (
    tester,
  ) async {
    final rows = [
      for (var i = 0; i < 200; i++) Invoice(i, 'Satır $i', 'Ödendi', i),
    ];
    await tester.pumpWidget(
      app(
        Harness(rows: rows, height: 300),
        theme: DsThemeData(density: DsDensity.compact),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await key(tester, LogicalKeyboardKey.tab);
    }
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(hasFocus(tester, 'Satır 2'), isTrue);
    // Leave the rows, then scroll far away with the pointer.
    await key(tester, LogicalKeyboardKey.tab, shift: true);
    await tester.drag(find.text('Satır 5'), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Satır 2', skipOffstage: true), findsNothing);
    await key(tester, LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, 'Satır 2'), isTrue);
    expect(find.text('Satır 2'), findsOneWidget);
    expect(tester.getRect(find.text('Satır 2')).top, greaterThan(0));
  });

  testWidgets('Enter on a sort button sorts', (tester) async {
    await tester.pumpWidget(app(const Harness()));
    await key(tester, LogicalKeyboardKey.tab); // select all
    await key(tester, LogicalKeyboardKey.tab); // Müşteri
    await key(tester, LogicalKeyboardKey.enter);
    expect(harness(tester).sort, const DsTableSort('customer'));
    await key(tester, LogicalKeyboardKey.enter);
    expect(
      harness(tester).sort,
      const DsTableSort('customer', DsTableSortDirection.descending),
    );
  });

  testWidgets('a selected row takes the soft tint, no edge', (tester) async {
    final theme = DsThemeData(platform: TargetPlatform.macOS);
    await tester.pumpWidget(host(const Harness(), theme: theme));
    harness(tester).update(() => harness(tester).selected = {2});
    await tester.pump(const Duration(milliseconds: 400));
    DsBoxDecoration deco(String text) =>
        tester
                .widget<AnimatedContainer>(
                  find
                      .ancestor(
                        of: find.text(text),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as DsBoxDecoration;
    bool edged(String text) =>
        deco(text).shadows
            .any((s) => s.inset && s.offset == Offset.zero && s.color.a > 0);
    expect(edged('Atlas Yazılım'), isFalse);
    expect(deco('Atlas Yazılım').color, theme.colors.selection);
  });

  testWidgets('rows of a large text scale stay one height', (tester) async {
    final theme = DsThemeData(platform: TargetPlatform.macOS);
    await tester.pumpWidget(
      host(const Harness(height: 400), theme: theme, textScale: 2),
    );
    double h(String t) => tester
        .getSize(
          find
              .ancestor(
                of: find.text(t),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .height;
    expect(h('Kuzey Lojistik'), h('Ege Gıda'));
    expect(h('Kuzey Lojistik'), greaterThan(theme.sizes.listRow));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a theme style reaches every table (Ö2)', (tester) async {
    const fill = Color(0xFF123456);
    await tester.pumpWidget(
      host(
        const DsTableTheme(
          data: DsTableThemeData(
            style: DsTableStyle(selected: DsTableStyle(rowBackground: fill)),
          ),
          child: Harness(),
        ),
      ),
    );
    harness(tester).update(() => harness(tester).selected = {1});
    await tester.pump();
    expect(rowFill(tester, 'Kuzey Lojistik'), fill);
  });
}
