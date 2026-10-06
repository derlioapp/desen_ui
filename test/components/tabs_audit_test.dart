import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regression tests for DsTabs overflow.
void main() {
  Widget bar(int value, ValueChanged<int> onChanged, FocusNode node) =>
      SizedBox(
        width: 300,
        child: DsTabs<int>(
          value: value,
          focusNode: node,
          onChanged: onChanged,
          tabs: [
            for (var i = 0; i < 30; i++) DsTab(value: i, label: Text('Tab $i')),
          ],
        ),
      );

  testWidgets('End scrolls the selected tab into view', (tester) async {
    useTraditionalHighlights();
    final node = FocusNode();
    addTearDown(node.dispose);
    var value = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              bar(value, (v) => setState(() => value = v), node),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(value, 29);
    final barRect = tester.getRect(find.byType(DsTabs<int>));
    final tabRect = tester.getRect(find.text('Tab 29'));
    expect(
      barRect.left <= tabRect.left && tabRect.right <= barRect.right,
      isTrue,
      reason: 'tab at $tabRect, bar at $barRect',
    );
  });

  testWidgets('a clipped bar fades the hidden edge', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(bar(0, (_) {}, node)));
    await tester.pump();
    expect(find.byType(ShaderMask), findsOneWidget);
    // A bar that fits has no fade.
    await tester.pumpWidget(
      host(
        DsTabs<int>(
          value: 0,
          onChanged: (_) {},
          tabs: const [DsTab(value: 0, label: Text('Genel'))],
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('the fade does not reset the scroll position', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(bar(29, (_) {}, node)));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      tester.getRect(find.text('Tab 29')).right,
      lessThanOrEqualTo(tester.getRect(find.byType(DsTabs<int>)).right),
    );
    expect(RendererBinding.instance, isNotNull);
  });
}
