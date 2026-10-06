// Denetim-2 regressions: row checkbox names and announced table states.
import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Row3 {
  const Row3(this.id, this.name);
  final int id;
  final String name;
}

const rows = [Row3(1, 'Kuzey Lojistik'), Row3(2, 'Atlas'), Row3(3, 'Ege')];

class Host extends StatefulWidget {
  const Host({super.key});

  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  List<Row3> data = rows;
  bool loading = false;
  Widget? error;

  void update(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 400,
    height: 300,
    child: DsTable<Row3>(
      rows: data,
      rowKey: (r) => r.id,
      loading: loading,
      errorView: error,
      onSelectionChanged: (_) {},
      columns: [
        DsTableColumn<Row3>(id: 'name', label: 'Ad', value: (r) => r.name),
      ],
    ),
  );
}

HostState state(WidgetTester tester) =>
    tester.state<HostState>(find.byType(Host));

bool liveRegionAround(WidgetTester tester, Finder finder) {
  SemanticsNode? node = tester.getSemantics(finder);
  while (node != null) {
    if (node.getSemanticsData().flagsCollection.isLiveRegion) return true;
    node = node.parent;
  }
  return false;
}

void main() {
  testWidgets('each row checkbox is named by its first cell', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DsApp(home: Host()));
    for (final r in rows) {
      expect(find.bySemanticsLabel('Select ${r.name}'), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Select row'), findsNothing);
    handle.dispose();
  });

  testWidgets('the name follows the language', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DsApp(locale: Locale('tr'), home: Host()));
    expect(
      find.bySemanticsLabel('Kuzey Lojistik satırını seç'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('loading, "No results" and errors are polite live regions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DsApp(home: Host()));
    state(tester).update(() {
      state(tester).data = const [];
      state(tester).loading = true;
    });
    await tester.pump();
    expect(liveRegionAround(tester, find.bySemanticsLabel('Loading')), isTrue);

    state(tester).update(() => state(tester).loading = false);
    await tester.pump();
    expect(liveRegionAround(tester, find.text('No results')), isTrue);

    state(tester).update(() => state(tester).error = const Text('Failed'));
    await tester.pump();
    expect(liveRegionAround(tester, find.text('Failed')), isTrue);
    handle.dispose();
  });

  testWidgets('a changed row count is said once the rows settle', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DsApp(home: Host()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeAnnouncements(), isEmpty, reason: 'not on first show');

    // Typing in a filter: 3 → 2 → 1 rows within the delay.
    state(tester).update(() => state(tester).data = rows.sublist(0, 2));
    await tester.pump(const Duration(milliseconds: 200));
    state(tester).update(() => state(tester).data = rows.sublist(0, 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeAnnouncements(), isEmpty);
    await tester.pump(const Duration(milliseconds: 700));
    final said = tester.takeAnnouncements();
    expect(said, hasLength(1));
    expect(said.single.message, '1 row');
    expect(said.single.assertiveness, Assertiveness.polite);

    // A rebuild with the same rows says nothing.
    state(tester).update(() {});
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeAnnouncements(), isEmpty);
    handle.dispose();
  });
}
