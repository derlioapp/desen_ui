import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A list row's description: a muted line under the title, read after it.
void main() {
  final theme = DsThemeData();

  testWidgets('sits under the title, muted, and is read after it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 360,
          child: DsListRow(
            title: const Text('Weekly summary'),
            description: const Text('Every Monday'),
            trailing: DsSwitch(value: true, onChanged: (_) {}),
          ),
        ),
        theme: theme,
      ),
    );
    final title = tester.getRect(find.text('Weekly summary'));
    final description = tester.getRect(find.text('Every Monday'));
    expect(description.top, greaterThanOrEqualTo(title.bottom));
    expect(description.left, title.left);
    final style = tester
        .widget<RichText>(
          find.descendant(
            of: find.text('Every Monday'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    expect(style.color, theme.colors.textMuted);
    expect(
      tester.getSemantics(find.text('Weekly summary')).label,
      contains('Weekly summary\nEvery Monday'),
    );
    handle.dispose();
  });

  testWidgets('a selected row inks its description in the selection color', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 360,
          child: DsListRow(
            title: const Text('Invoice'),
            description: const Text('Due Friday'),
            selected: true,
            onPressed: () {},
          ),
        ),
        theme: theme,
      ),
    );
    final style = tester
        .widget<RichText>(
          find.descendant(
            of: find.text('Due Friday'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    expect(style.color, theme.onSelectedFill);
  });
}
