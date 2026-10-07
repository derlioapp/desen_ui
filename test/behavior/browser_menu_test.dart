import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/behavior/browser_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// On the web, the browser's own context menu is off while the pointer is
/// over a table row that opens Desen's menu, and back on afterwards, also
/// when the row goes away under the pointer.
void main() {
  late bool enabled;
  late List<bool> calls;
  setUp(() {
    enabled = true;
    calls = [];
    DsBrowserMenuHold.debugBrowser = (
      enabled: () => enabled,
      set: (on) {
        calls.add(on);
        enabled = on;
      },
    );
  });
  tearDown(() => DsBrowserMenuHold.debugBrowser = null);

  Widget table({required bool shown}) => DsApp(
    home: shown
        ? DsTable<int>(
            columns: [
              DsTableColumn(id: 'n', label: 'Name', text: (i) => 'Item $i'),
            ],
            rows: const [1, 2],
            rowKey: (i) => i,
            onRowPressed: (_) {},
            rowMenuBuilder: (context, i) => [
              DsMenuItem(label: const Text('Delete'), onPressed: () {}),
            ],
          )
        : const SizedBox(),
  );

  testWidgets('a row removed under the pointer gives the menu back', (
    tester,
  ) async {
    await tester.pumpWidget(table(shown: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Item 1')));
    await tester.pump();
    expect(calls, [false]);
    // Moving to the next row keeps it off without turning it on between.
    await mouse.moveTo(tester.getCenter(find.text('Item 2')));
    await tester.pump();
    expect(calls, [false]);
    await tester.pumpWidget(table(shown: false));
    await tester.pump();
    expect(calls, [false, true]);
    expect(enabled, isTrue);
  });

  testWidgets('an app that turned the menu off keeps it off', (tester) async {
    enabled = false;
    await tester.pumpWidget(table(shown: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Item 1')));
    await tester.pump();
    await tester.pumpWidget(table(shown: false));
    await tester.pump();
    expect(calls, isEmpty);
    expect(enabled, isFalse);
  });
}
