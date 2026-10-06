import 'dart:ui' show SemanticsRole;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widgets made of several Tab stops keep them together in the Tab order
/// instead of interleaving them with what sits beside them, and
/// the sidebar is a navigation landmark.
void main() {
  /// The label of [labels] whose text sits in the focused node's box.
  String? focused(WidgetTester tester, List<String> labels) {
    final rect = FocusManager.instance.primaryFocus?.rect;
    if (rect == null) return null;
    for (final label in labels) {
      if (rect.contains(tester.getCenter(find.text(label)))) return label;
    }
    return null;
  }

  Future<List<String?>> tabThrough(
    WidgetTester tester,
    List<String> labels,
  ) async {
    final order = <String?>[];
    for (var i = 0; i < labels.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      order.add(focused(tester, labels));
    }
    return order;
  }

  Widget content(List<String> labels) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final label in labels)
        Padding(
          padding: const EdgeInsets.all(DsSpace.s4),
          child: DsButton(onPressed: () {}, child: Text(label)),
        ),
    ],
  );

  const nav = ['Inbox', 'Drafts', 'Sent', 'Trash'];
  const page = ['Compose', 'Search', 'Refresh', 'Archive'];

  Widget sidebarPage({bool collapsed = false, String? label}) => DsApp(
    home: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSidebar<String>(
          value: 'Inbox',
          onChanged: (_) {},
          collapsed: collapsed,
          semanticLabel: label,
          children: [
            for (final item in nav)
              DsSidebarItem(
                value: item,
                leading: const DsIcon(DsIcons.inbox),
                label: Text(item),
              ),
          ],
        ),
        Expanded(child: content(page)),
      ],
    ),
  );

  testWidgets('Tab goes through the sidebar, then the page beside it', (
    tester,
  ) async {
    await tester.pumpWidget(sidebarPage());
    expect(await tabThrough(tester, [...nav, ...page]), [...nav, ...page]);
  });

  testWidgets('an accordion keeps its headers together beside a column', (
    tester,
  ) async {
    const headers = ['One', 'Two', 'Three'];
    const side = ['Alpha', 'Beta', 'Gamma'];
    await tester.pumpWidget(
      DsApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DsAccordion(
                items: [
                  for (final (i, h) in headers.indexed)
                    DsAccordionItem(
                      value: i,
                      title: Text(h),
                      child: Text('$h body'),
                    ),
                ],
              ),
            ),
            Expanded(child: content(side)),
          ],
        ),
      ),
    );
    expect(await tabThrough(tester, [...headers, ...side]), [
      ...headers,
      ...side,
    ]);
  });

  testWidgets('toolbars, pagination, breadcrumbs and tables group their '
      'stops', (tester) async {
    await tester.pumpWidget(
      DsApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              DsToolbar(
                children: [
                  DsButton(onPressed: () {}, child: const Text('Bold')),
                  DsButton(onPressed: () {}, child: const Text('Italic')),
                ],
              ),
              DsPagination(page: 2, pageCount: 5, onChanged: (_) {}),
              DsBreadcrumb(
                items: [
                  DsBreadcrumbItem(label: 'Home', onPressed: () {}),
                  const DsBreadcrumbItem(label: 'Here'),
                ],
              ),
              SizedBox(
                height: 200,
                child: DsTable<int>(
                  columns: [
                    DsTableColumn<int>(
                      id: 'n',
                      label: 'Num',
                      value: (r) => r,
                      sortable: true,
                    ),
                  ],
                  rows: const [1, 2, 3],
                  rowKey: (r) => r,
                  onSortChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (final type in [DsToolbar, DsPagination, DsBreadcrumb, DsTable<int>]) {
      expect(
        find.descendant(
          of: find.byType(type),
          matching: find.byType(FocusTraversalGroup),
        ),
        findsWidgets,
        reason: '$type',
      );
    }
  });

  group('sidebar landmark', () {
    SemanticsData landmark(WidgetTester tester, String name) =>
        tester.getSemantics(find.bySemanticsLabel(name)).getSemanticsData();

    testWidgets('a navigation named "Navigation" by default', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(sidebarPage());
      expect(landmark(tester, 'Navigation').role, SemanticsRole.navigation);
      handle.dispose();
    });

    testWidgets('named by semanticLabel, collapsed too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(sidebarPage(label: 'Main', collapsed: true));
      await tester.pumpAndSettle();
      expect(landmark(tester, 'Main').role, SemanticsRole.navigation);
      handle.dispose();
    });
  });
}
