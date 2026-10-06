@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for a toolbar too narrow for its items, light and
/// dark: the bar at several widths (left to right and right to left), the
/// "More actions" button at its end, and the open menu with a checked
/// toggle, an icon button's shortcut and a destructive action.
void main() {
  List<Widget> items() => [
    DsToolbarToggle(
      icon: const DsIcon(DsIcons.bold),
      semanticLabel: 'Bold',
      selected: true,
      onChanged: (_) {},
    ),
    DsToolbarToggle(
      icon: const DsIcon(DsIcons.italic),
      semanticLabel: 'Italic',
      selected: false,
      onChanged: (_) {},
    ),
    DsToolbarToggle(
      icon: const DsIcon(DsIcons.underline),
      semanticLabel: 'Underline',
      selected: true,
      onChanged: (_) {},
    ),
    const DsToolbarDivider(),
    DsTooltip(
      message: 'Add link',
      shortcut: '⌘K',
      child: DsButton.icon(
        variant: DsButtonVariant.ghost,
        size: DsSize.sm,
        icon: const DsIcon(DsIcons.link),
        semanticLabel: 'Add link',
        onPressed: () {},
      ),
    ),
    DsButton.icon(
      variant: DsButtonVariant.dangerSoft,
      size: DsSize.sm,
      icon: const DsIcon(DsIcons.trash),
      semanticLabel: 'Delete',
      onPressed: () {},
    ),
    const DsToolbarDivider(),
    DsButton(size: DsSize.sm, onPressed: () {}, child: const Text('Comment')),
  ];

  Widget bar(double maxWidth, {TextDirection? direction}) {
    Widget toolbar = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DsToolbar(semanticLabel: 'Formatting', children: items()),
    );
    if (direction != null) {
      toolbar = Directionality(textDirection: direction, child: toolbar);
    }
    return toolbar;
  }

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('toolbar overflow collapsed $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            bar(1000),
            bar(240),
            bar(170),
            bar(100),
            bar(170, direction: TextDirection.rtl),
          ],
        ),
      );
      // The bars settle once their items have left the focus order.
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/toolbar_overflow_$mode.png');
    });

    testWidgets('toolbar overflow menu $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 360,
          height: 320,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Stack(
                  children: [Positioned(left: 20, top: 20, child: bar(100))],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is DsButton && w.semanticLabel == 'More actions',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DsMenu), findsOneWidget);
      await expectGolden(tester, 'goldens/toolbar_overflow_menu_$mode.png');
    });
  }
}
