@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsReorderableList, light and dark: favorites in a
/// card with a handle per row, the keyboard focus ring on a handle, and a
/// row lifted mid-drag over the others making room; plus the touch size.
void main() {
  const stations = ['Radio Nova', 'Jazz FM', 'KEXP', 'NTS 1', 'FIP'];

  Widget list({FocusNode? focus}) => SizedBox(
    width: 320,
    child: DsCard(
      style: const DsCardStyle(padding: EdgeInsets.zero),
      child: DsReorderableList(
        shrinkWrap: true,
        itemCount: stations.length,
        itemBuilder: (context, i) => DsListRow(
          key: ValueKey(stations[i]),
          leading: const DsIcon(DsIcons.radio),
          title: Text(stations[i]),
        ),
        onReorder: (_, _) {},
      ),
    ),
  );

  Widget host(DsThemeData theme, Widget child) => SizedBox(
    width: 360,
    height: 360,
    child: Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) =>
              Align(alignment: Alignment.topLeft, child: child),
        ),
      ],
    ),
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('reorderable list $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pumpGolden(tester, theme: theme, host(theme, list()));
      // Keyboard focus on the second row's handle.
      final scope = FocusScope.of(
        tester.element(find.byType(DsReorderableList)),
      );
      scope.nextFocus();
      scope.nextFocus();
      // Any key marks keyboard modality.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/reorderable_list_$mode.png');
    });

    testWidgets('reorderable list dragging $mode', (tester) async {
      await pumpGolden(tester, theme: theme, host(theme, list()));
      final handle = find.byWidgetPredicate(
        (w) => w is DsIcon && w.icon == DsIcons.gripVertical,
      );
      final g = await tester.startGesture(tester.getCenter(handle.at(1)));
      await tester.pump();
      await g.moveBy(const Offset(0, 30));
      await tester.pump();
      await g.moveBy(const Offset(0, 40));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/reorderable_list_dragging_$mode.png');
      await g.up();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('reorderable list touch', (tester) async {
    final theme = DsThemeData(platform: TargetPlatform.iOS);
    await pumpGolden(tester, theme: theme, host(theme, list()));
    await expectGolden(tester, 'goldens/reorderable_list_touch.png');
  });
}
