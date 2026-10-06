import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Site findings on DsTable: numeric headers line up with their values,
/// the cards' "select all" has a visible label, and an opt-in "⋯" button
/// opens the row menu.
class Task {
  const Task(this.id, this.title, this.points);
  final int id;
  final String title;
  final int points;
}

const tasks = [
  Task(1, 'Write the brief', 3),
  Task(2, 'Review the draft', 120),
  Task(3, 'Ship it', 8),
];

class _Host extends StatefulWidget {
  const _Host({
    this.width = 480,
    this.layout = const DsTableLayout.rows(),
    this.menuButton = false,
    this.sortable = true,
  });

  final double width;
  final DsTableLayout layout;
  final bool menuButton;
  final bool sortable;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  DsTableSort? sort;
  Set<Object> selected = {};
  final pressed = <String>[];

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: widget.width,
      child: DsTable<Task>(
        layout: widget.layout,
        columns: [
          DsTableColumn(
            id: 'title',
            label: 'Title',
            value: (t) => t.title,
            sortable: widget.sortable,
          ),
          DsTableColumn(
            id: 'points',
            label: 'Points',
            value: (t) => t.points,
            numeric: true,
            sortable: widget.sortable,
            width: const .fixed(96),
          ),
        ],
        rows: tasks,
        rowKey: (t) => t.id,
        sort: sort,
        onSortChanged: (s) => setState(() => sort = s),
        selected: selected,
        onSelectionChanged: (s) => setState(() => selected = s),
        rowMenuBuilder: (_, t) => [
          DsMenuItem(
            onPressed: () => pressed.add('edit ${t.id}'),
            label: Text('Edit ${t.id}'),
          ),
        ],
        showRowMenuButton: widget.menuButton,
      ),
    ),
  );
}

_HostState _state(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host));

void main() {
  group('numeric headers', () {
    for (final direction in TextDirection.values) {
      testWidgets('end at their values (${direction.name})', (tester) async {
        await tester.pumpWidget(
          DsApp(
            builder: (context, child) =>
                Directionality(textDirection: direction, child: child!),
            home: const _Host(),
          ),
        );
        final header = tester.getRect(find.text('Points'));
        final value = tester.getRect(find.text('120'));
        if (direction == TextDirection.ltr) {
          expect(header.right, moreOrLessEquals(value.right, epsilon: .5));
        } else {
          expect(header.left, moreOrLessEquals(value.left, epsilon: .5));
        }
        // A start-aligned header keeps its arrow after the label.
        final title = tester.getRect(find.text('Title'));
        final cell = tester.getRect(find.text('Ship it'));
        if (direction == TextDirection.ltr) {
          expect(title.left, moreOrLessEquals(cell.left, epsilon: .5));
        } else {
          expect(title.right, moreOrLessEquals(cell.right, epsilon: .5));
        }
      });
    }
  });

  group('cards', () {
    testWidgets('"select all" has a visible label that toggles', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const DsApp(
          home: _Host(
            width: 360,
            layout: DsTableLayout.cards(),
            sortable: false,
          ),
        ),
      );
      expect(find.text('Select all'), findsOneWidget);
      // The box is named like its label.
      expect(
        tester
            .getSemantics(find.byType(DsCheckbox).first)
            .getSemanticsData()
            .label,
        'Select all',
      );
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(_state(tester).selected, {1, 2, 3});
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(_state(tester).selected, isEmpty);
      handle.dispose();
    });
  });

  group('row menu button', () {
    testWidgets('is off by default', (tester) async {
      await tester.pumpWidget(const DsApp(home: _Host()));
      expect(find.byType(DsButton), findsNothing);
    });

    testWidgets('each row gets a named "⋯" button that opens its menu', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const DsApp(home: _Host(menuButton: true)));
      expect(find.byType(DsButton), findsNWidgets(tasks.length));
      expect(
        find.bySemanticsLabel('Actions for Review the draft'),
        findsOneWidget,
      );
      // The column is named for screen readers, with nothing to see.
      expect(find.bySemanticsLabel('Actions'), findsOneWidget);
      // It sits at the row's end, past the last column.
      final button = tester.getRect(find.byType(DsButton).at(1));
      expect(
        button.left,
        greaterThanOrEqualTo(tester.getRect(find.text('120')).right),
      );
      await tester.tap(find.byType(DsButton).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Edit 2'), findsOneWidget);
      // Below the button.
      expect(
        tester.getRect(find.text('Edit 2')).top,
        greaterThanOrEqualTo(button.bottom),
      );
      expect(
        tester
            .getSemantics(find.byType(DsButton).at(1))
            .flagsCollection
            .isExpanded,
        Tristate.isTrue,
      );
      await tester.tap(find.text('Edit 2'));
      await tester.pumpAndSettle();
      expect(_state(tester).pressed, ['edit 2']);
      handle.dispose();
    });

    testWidgets('the keyboard reaches it after the active row', (tester) async {
      await tester.pumpWidget(const DsApp(home: _Host(menuButton: true)));
      // Header sort buttons and "select all", then the rows' stop, then the
      // active row's own button.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Edit 1'), findsOneWidget);
    });

    testWidgets('cards show it on their first line', (tester) async {
      await tester.pumpWidget(
        const DsApp(
          home: _Host(
            width: 360,
            layout: DsTableLayout.cards(),
            menuButton: true,
          ),
        ),
      );
      // The bar's sort menu button, then one per card.
      expect(find.byType(DsButton), findsNWidgets(tasks.length + 1));
      final first = find.byType(DsButton).at(1);
      final button = tester.getRect(first);
      final title = tester.getRect(find.text('Write the brief'));
      expect(button.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1));
      expect(button.left, greaterThan(title.right));
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(find.text('Edit 1'), findsOneWidget);
    });
  });
}
