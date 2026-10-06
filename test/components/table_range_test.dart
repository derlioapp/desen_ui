import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Range selection runs from an anchor, as in a file list: Shift with the
/// arrows or a click moves the range's far end, and moving it back toward
/// the anchor shrinks the range.
void main() {
  late Set<Object> selected;

  Future<void> pumpTable(WidgetTester tester) async {
    selected = {};
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('en', 'US'),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 500,
            child: StatefulBuilder(
              builder: (context, setState) => DsTable<int>(
                columns: [
                  DsTableColumn<int>(
                    id: 't',
                    label: 'Text',
                    value: (r) => 'Row $r',
                  ),
                ],
                rows: List.generate(10, (r) => r),
                rowKey: (r) => r,
                selected: selected,
                onSelectionChanged: (s) => setState(() => selected = s),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tabs past "select all" to the rows' stop, the first row.
  Future<void> tabToRows(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      if (FocusManager.instance.primaryFocus?.debugLabel == 'DsTable row') {
        return;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'DsTable row');
  }

  /// Tabs into the rows, moves down [down] rows and selects that row.
  Future<void> anchorAt(WidgetTester tester, int down) async {
    await tabToRows(tester);
    for (var i = 0; i < down; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
  }

  testWidgets('Shift+Down grows the range, Shift+Up shrinks it back', (
    tester,
  ) async {
    await pumpTable(tester);
    await anchorAt(tester, 2);
    expect(selected, {2});
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, {2, 3, 4});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(selected, {2, 3});
    // Past the anchor, the range flips to the other side.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(selected, {1, 2});
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  });

  testWidgets('Shift+End and Shift+Home move the range end', (tester) async {
    await pumpTable(tester);
    await anchorAt(tester, 5);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(selected, {5, 6, 7, 8, 9});
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(selected, {0, 1, 2, 3, 4, 5});
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  });

  testWidgets('Shift with an arrow and no anchor starts at the focused row', (
    tester,
  ) async {
    await pumpTable(tester);
    await tabToRows(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selected, {0, 1});
  });

  testWidgets('Shift-click after Shift+arrows replaces the range', (
    tester,
  ) async {
    await pumpTable(tester);
    await anchorAt(tester, 5);
    expect(selected, {5});
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selected, {5, 6, 7});
    await tester.tap(find.text('Row 3'));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selected, {3, 4, 5});
  });

  testWidgets('a selection made before the range is kept', (tester) async {
    await pumpTable(tester);
    await anchorAt(tester, 0);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(selected, {0, 5});
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selected, {0, 5});
  });

  testWidgets('Shift-click selects from the anchor and replaces the last '
      'Shift-click range', (tester) async {
    await pumpTable(tester);
    await tester.tap(find.text('Row 2'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('Row 6'));
    await tester.pump();
    expect(selected, {2, 3, 4, 5, 6});
    await tester.tap(find.text('Row 4'));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selected, {2, 3, 4});
  });
}
