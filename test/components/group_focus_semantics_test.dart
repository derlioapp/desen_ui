import 'dart:ui' show CheckedState, SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Denetim-2 ux H1: tabs and the segmented control are one Tab stop, but a
/// screen reader must hear the selected item ("Tab, Paid, selected"), not an
/// unnamed focused group.
void main() {
  /// Every semantics node that reports input focus.
  List<SemanticsNode> focusedNodes(WidgetTester tester) {
    final out = <SemanticsNode>[];
    void walk(SemanticsNode n) {
      if (n.getSemanticsData().flagsCollection.isFocused == Tristate.isTrue) {
        out.add(n);
      }
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(
      tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!,
    );
    return out;
  }

  Widget tabs({
    required int? value,
    required ValueChanged<int?> onChanged,
    FocusNode? node,
  }) => DsTabs<int?>(
    value: value,
    onChanged: onChanged,
    focusNode: node,
    semanticLabel: 'Invoices',
    tabs: const [
      DsTab(value: 0, label: Text('Draft')),
      DsTab(value: 1, label: Text('Paid')),
      DsTab(value: 2, label: Text('Overdue')),
    ],
  );

  testWidgets('tabs: focus is reported on the selected tab', (tester) async {
    final handle = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    int? value = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => tabs(
            value: value,
            onChanged: (v) => set(() => value = v),
            node: node,
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 1);

    final focused = focusedNodes(tester);
    expect(focused, hasLength(1));
    final data = focused.single.getSemanticsData();
    expect(data.label, 'Paid\nTab 2 of 3');
    expect(data.role, SemanticsRole.tab);
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    // No other node carries focus semantics: the group is not a stop of its
    // own for a screen reader.
    expect(
      tester
          .getSemantics(find.text('Draft'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      isNot(Tristate.isTrue),
    );

    // Leaving the bar clears it.
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    expect(focusedNodes(tester), isEmpty);
    handle.dispose();
  });

  testWidgets('tabs: the focus action on the tab focuses the bar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(tabs(value: 1, onChanged: (_) {})));
    final paid = tester.getSemantics(find.text('Paid'));
    expect(paid.getSemanticsData().hasAction(SemanticsAction.focus), isTrue);
    expect(
      tester
          .getSemantics(find.text('Draft'))
          .getSemanticsData()
          .hasAction(SemanticsAction.focus),
      isFalse,
    );
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      paid.id,
      SemanticsAction.focus,
    );
    await tester.pump();
    expect(
      focusedNodes(tester).single.getSemanticsData().label,
      'Paid\nTab 2 of 3',
    );
    handle.dispose();
  });

  testWidgets('tabs: with nothing selected, the first tab stands for focus '
      'and ArrowRight selects it (bugs L6)', (tester) async {
    final handle = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    int? value;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => tabs(
            value: value,
            onChanged: (v) => set(() => value = v),
            node: node,
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    expect(
      focusedNodes(tester).single.getSemanticsData().label,
      'Draft\nTab 1 of 3',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 0);

    value = null;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => tabs(
            value: value,
            onChanged: (v) => set(() => value = v),
            node: node,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 2, reason: 'back from no selection starts at the last');
    handle.dispose();
  });

  testWidgets('segmented: focus is reported on the selected segment, '
      'announced as a radio', (tester) async {
    final handle = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    var value = 'list';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => DsSegmentedControl<String>(
            value: value,
            semanticLabel: 'View',
            focusNode: node,
            onChanged: (v) => set(() => value = v),
            segments: const [
              DsSegment(value: 'list', label: Text('List')),
              DsSegment(value: 'board', label: Text('Board')),
              DsSegment(value: 'week', label: Text('Week')),
            ],
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'board');

    final data = focusedNodes(tester).single.getSemanticsData();
    expect(data.label, 'Board');
    final flags = data.flagsCollection;
    expect(flags.isChecked, CheckedState.isTrue);
    expect(flags.isInMutuallyExclusiveGroup, isTrue);
    expect(flags.isButton, isFalse);
    handle.dispose();
  });
}
