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

  testWidgets('a tab bar under a covering page reveals once laid out', (
    tester,
  ) async {
    // A deep link builds [root, detail] at once: the root page is built
    // but never laid out while covered. Revealing must wait, not assert.
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      host(
        theme: DsThemeData(density: DsDensity.compact),
        SizedBox(
          width: 320,
          height: 400,
          child: Navigator(
            key: nav,
            pages: [
              PlainPage(
                key: const ValueKey('root'),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: DsTabs<int>(
                    value: 7,
                    onChanged: (_) {},
                    tabs: [
                      for (var i = 0; i < 8; i++)
                        DsTab(value: i, label: Text('Section $i')),
                    ],
                  ),
                ),
              ),
              const PlainPage(
                key: ValueKey('detail'),
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Section 7'), findsNothing);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final strip = tester.getRect(find.byType(DsTabs<int>));
    final tab = tester.getRect(find.text('Section 7'));
    expect(tab.left >= strip.left && tab.right <= strip.right, isTrue);
  });
}
