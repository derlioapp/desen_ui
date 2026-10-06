import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('revealing the selected tab scrolls only the tab strip', (
    tester,
  ) async {
    // Tabs far down a scrolling page, the last one selected: the strip may
    // scroll to it, the page around it must not move.
    final page = ScrollController();
    addTearDown(page.dispose);
    await tester.pumpWidget(
      host(
        theme: DsThemeData(density: DsDensity.compact),
        SizedBox(
          width: 320,
          height: 400,
          child: SingleChildScrollView(
            controller: page,
            child: Column(
              children: [
                const SizedBox(height: 900),
                DsTabs<int>(
                  value: 7,
                  onChanged: (_) {},
                  tabs: [
                    for (var i = 0; i < 8; i++)
                      DsTab(value: i, label: Text('Section $i')),
                  ],
                ),
                const SizedBox(height: 900),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(page.offset, 0);
  });
}
