import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regression tests for DsAccordion.
void main() {
  DsAccordionItem<String> item(String v) =>
      DsAccordionItem(value: v, title: Text(v), child: Text('$v body'));

  testWidgets('open state follows the item, not the index', (tester) async {
    Widget tree(List<String> order) => host(
      DsAccordion<String>(
        initialValue: const {'b'},
        items: [for (final v in order) item(v)],
      ),
    );
    await tester.pumpWidget(tree(['a', 'b']));
    expect(find.text('b body'), findsOneWidget);
    await tester.pumpWidget(tree(['new', 'a', 'b']));
    await tester.pumpAndSettle();
    expect(find.text('b body'), findsOneWidget);
    expect(find.text('a body'), findsNothing);
  });

  testWidgets('opens under reduce motion without an animation', (tester) async {
    await tester.pumpWidget(
      host(
        DsAccordion<String>(items: [item('a'), item('b')]),
        theme: DsThemeData(motion: const DsMotion(reduced: true)),
      ),
    );
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('a body'), findsOneWidget);
  });

  testWidgets('controlled state reports values', (tester) async {
    Set<String>? reported;
    await tester.pumpWidget(
      host(
        DsAccordion<String>(
          value: const {'a'},
          onChanged: (v) => reported = v,
          items: [item('a'), item('b')],
        ),
      ),
    );
    await tester.tap(find.text('b'));
    expect(reported, {'b'});
  });

  testWidgets('each header is a heading around the button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(DsAccordion<String>(items: [item('a')])));
    final button = tester.getSemantics(find.text('a'));
    expect(button.flagsCollection.isButton, isTrue);
    expect(button.flagsCollection.isExpanded, Tristate.isFalse);
    var heading = false;
    for (SemanticsNode? n = button.parent; n != null; n = n.parent) {
      if (n.flagsCollection.isHeader) heading = true;
    }
    expect(heading, isTrue);
    handle.dispose();
  });

  testWidgets('the focus ring is drawn inside the header', (tester) async {
    final theme = DsThemeData();
    final style = DsAccordion.defaultStyle(theme);
    expect(style.focusShadows, isNotEmpty);
    expect(style.focusShadows!.every((s) => s.inset), isTrue);
  });

  testWidgets('single open keeps a disabled open section open (site)', (
    tester,
  ) async {
    Set<String>? reported;
    await tester.pumpWidget(
      host(
        DsAccordion<String>(
          initialValue: const {'a'},
          onChanged: (v) => reported = v,
          items: [
            const DsAccordionItem(
              value: 'a',
              enabled: false,
              title: Text('a'),
              child: Text('a body'),
            ),
            item('b'),
            item('c'),
          ],
        ),
      ),
    );
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(reported, {'a', 'b'});
    expect(find.text('a body'), findsOneWidget);
    // Opening another section still closes the enabled one.
    await tester.tap(find.text('c'));
    await tester.pumpAndSettle();
    expect(reported, {'a', 'c'});
    expect(find.text('b body'), findsNothing);
  });
}
