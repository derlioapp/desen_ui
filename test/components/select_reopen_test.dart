import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A select opened again while its menu fades out focuses the chosen
/// option, not the one focused when it closed.
const opts = [
  DsSelectOption(value: 'a', label: 'Apple'),
  DsSelectOption(value: 'b', label: 'Banana'),
  DsSelectOption(value: 'c', label: 'Cherry'),
];

void main() {
  testWidgets('select reopened while its menu fades: focus is on the chosen '
      'option', (tester) async {
    String? value = 'a';
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      DsApp(
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 240,
            child: StatefulBuilder(
              builder: (context, setState) => DsSelect<String>(
                value: value,
                focusNode: node,
                onChanged: (v) => setState(() => value = v),
                options: opts,
              ),
            ),
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // open on Apple
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape); // closing
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC); // Cherry, closed
    await tester.pump();
    expect(value, 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // reopen
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus!.context!;
    final item = focused.findAncestorWidgetOfExactType<DsMenuItem>();
    expect((item?.label as Text?)?.data, 'Cherry');
  });
}
