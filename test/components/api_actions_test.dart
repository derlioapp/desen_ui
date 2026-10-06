import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The pre-1.0 API round for actions, navigation and display: every
/// interactive widget takes `focusNode` and `autofocus` (rule 5) and a
/// `semanticLabel` (rule 6); value controls use `value` + `onChanged`
/// (rule 1).
void main() {
  bool focused(FocusNode node) => node.hasFocus;

  group('focusNode and autofocus', () {
    testWidgets('pressable rows, items, cards and links take them', (
      tester,
    ) async {
      final nodes = List.generate(4, (i) => FocusNode());
      addTearDown(() {
        for (final n in nodes) {
          n.dispose();
        }
      });
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsListRow(
                title: const Text('Row'),
                focusNode: nodes[0],
                autofocus: true,
                onPressed: () {},
              ),
              DsSidebarItem(
                label: const Text('Item'),
                focusNode: nodes[1],
                onPressed: () {},
              ),
              DsCard(
                focusNode: nodes[2],
                onPressed: () {},
                child: const Text('Card'),
              ),
              DsLink(label: 'Link', focusNode: nodes[3], onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(focused(nodes[0]), isTrue, reason: 'autofocus');
      for (final node in nodes.skip(1)) {
        node.requestFocus();
        await tester.pump();
        expect(focused(node), isTrue);
      }
    });

    testWidgets('a menu item takes an outside node', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsMenu(
            children: [
              DsMenuItem(
                label: const Text('Edit'),
                focusNode: node,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('bottom nav: the bar node focuses the current item', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      String? chosen;
      await tester.pumpWidget(
        host(
          DsBottomNav<String>(
            value: 'b',
            focusNode: node,
            onChanged: (v) => chosen = v,
            items: const [
              DsBottomNavItem(
                value: 'a',
                icon: DsIcon(DsIcons.house),
                label: Text('A'),
              ),
              DsBottomNavItem(
                value: 'b',
                icon: DsIcon(DsIcons.user),
                label: Text('B'),
              ),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(node.hasPrimaryFocus, isFalse, reason: 'moved on to an item');
      expect(Focus.of(tester.element(find.text('B'))).hasPrimaryFocus, isTrue);
      await tester.tap(find.text('A'));
      expect(chosen, 'a');
    });

    testWidgets('pagination: autofocus lands on the current page and stays '
        'on a page button when the page changes', (tester) async {
      var page = 3;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsPagination(
              page: page,
              pageCount: 5,
              autofocus: true,
              onChanged: (p) => set(() => page = p),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Focus.of(tester.element(find.text('3'))).hasPrimaryFocus, isTrue);
      // Focus page 4 and choose it: focus stays on it.
      Focus.of(tester.element(find.text('4'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(page, 4);
      expect(Focus.of(tester.element(find.text('4'))).hasPrimaryFocus, isTrue);
    });

    testWidgets('accordion: the node focuses the first header that can be '
        'pressed', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsAccordion<int>(
            focusNode: node,
            semanticLabel: 'FAQ',
            items: const [
              DsAccordionItem(
                value: 0,
                title: Text('Zero'),
                enabled: false,
                child: Text('0'),
              ),
              DsAccordionItem(value: 1, title: Text('One'), child: Text('1')),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('One'))).hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('table: the node focuses the active row', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        DsApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: DsTable<String>(
              focusNode: node,
              rows: const ['Ada', 'Ece'],
              rowKey: (r) => r,
              onRowPressed: (_) {},
              columns: [
                DsTableColumn(id: 'name', label: 'Name', value: (r) => r),
              ],
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(node.hasPrimaryFocus, isFalse, reason: 'moved on to a row');
    });
  });

  testWidgets('breadcrumb: autofocus focuses the first level', (tester) async {
    await tester.pumpWidget(
      host(
        DsBreadcrumb(
          autofocus: true,
          items: [
            DsBreadcrumbItem(label: 'Home', onPressed: () {}),
            DsBreadcrumbItem(label: 'Docs', onPressed: () {}),
            const DsBreadcrumbItem(label: 'Page'),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Home'))).hasPrimaryFocus, isTrue);
  });

  group('semanticLabel', () {
    testWidgets('a menu item announces its override', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsMenu(
            children: [
              DsMenuItem(
                label: const Text('⌘E'),
                semanticLabel: 'Edit',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Edit'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an accordion names its group', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DsAccordion<int>(
            semanticLabel: 'FAQ',
            items: [
              DsAccordionItem(value: 0, title: Text('Zero'), child: Text('0')),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('FAQ'), findsOneWidget);
      handle.dispose();
    });
  });

  group('accordion value', () {
    const items = [
      DsAccordionItem(value: 0, title: Text('Zero'), child: Text('0 body')),
      DsAccordionItem(value: 1, title: Text('One'), child: Text('1 body')),
    ];

    testWidgets('uncontrolled: starts from initialValue, reports changes', (
      tester,
    ) async {
      Set<int>? reported;
      await tester.pumpWidget(
        host(
          DsAccordion<int>(
            initialValue: const {0},
            onChanged: (v) => reported = v,
            items: items,
          ),
        ),
      );
      expect(find.text('0 body'), findsOneWidget);
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(reported, {1});
      expect(find.text('1 body'), findsOneWidget);
    });

    testWidgets('controlled without onChanged: headers are disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DsAccordion<int>(value: {0}, items: items)),
      );
      final header = tester.getSemantics(find.text('One'));
      expect(header.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });
}
