@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for a single-choice chip row too narrow for its
/// chips, light and dark: the row opened on its first, a middle and its
/// last chip (left to right and right to left), a row that fits, and the
/// keyboard focus ring on the first chip at the start edge.
void main() {
  const labels = ['All', 'Unread', 'Flagged', 'Archived', 'Drafts', 'Sent'];

  Widget row(
    String value, {
    double width = 220,
    List<String> options = labels,
    TextDirection? direction,
    FocusNode? node,
  }) {
    Widget chips = SizedBox(
      width: width,
      child: DsChoiceChips<String>(
        value: value,
        onChanged: (_) {},
        focusNode: node,
        semanticLabel: 'Show',
        options: [
          for (final o in options) DsChipOption(value: o, label: Text(o)),
        ],
      ),
    );
    if (direction != null) {
      chips = Directionality(textDirection: direction, child: chips);
    }
    return chips;
  }

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('choice chips overflow $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            row('All'),
            row('Flagged'),
            row('Sent'),
            row('Flagged', direction: TextDirection.rtl),
            row('Unread', options: const ['All', 'Unread']),
            row('All', node: node),
          ],
        ),
      );
      node.requestFocus();
      // Any key marks keyboard modality.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/choice_chips_overflow_$mode.png');
    });
  }
}
