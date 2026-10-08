@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsSectionIndex, light and dark: the Turkish
/// alphabet with a current section, a hovered letter, the keyboard focus
/// ring, a column too short for its letters (dots), a disabled one; and
/// the bubble beside a list while a finger is down, left to right and
/// right to left, at touch size.
void main() {
  const turkish = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ', 'J', 'K', //
    'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', //
    'Z',
  ];

  const cities = [
    'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', //
  ];

  Widget bar({
    String? value = 'K',
    double height = 480,
    bool enabled = true,
    FocusNode? node,
    Key? key,
  }) => SizedBox(
    key: key,
    height: height,
    child: DsSectionIndex(
      sections: turkish,
      value: value,
      focusNode: node,
      onChanged: enabled ? (_) {} : null,
    ),
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('section index $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      const hover = Key('hover');
      await pumpGolden(
        tester,
        theme: theme,
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 32,
          children: [
            bar(),
            bar(key: hover, value: null),
            bar(node: node, value: 'Ş'),
            bar(height: 200),
            bar(enabled: false),
          ],
        ),
      );
      node.requestFocus();
      // Any key marks keyboard modality.
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      final r = tester.getRect(find.byKey(hover));
      // The fourth letter's row, Ç.
      await mouse.moveTo(
        Offset(r.center.dx, r.center.dy - 29 / 2 * 16 + 3.5 * 16),
      );
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/section_index_$mode.png');
    });

    for (final direction in TextDirection.values) {
      testWidgets('section index bubble $mode ${direction.name}', (
        tester,
      ) async {
        final touch = DsThemeData(
          seed: DsSeed.blue,
          brightness: theme.colors.canvas.computeLuminance() < .5
              ? Brightness.dark
              : Brightness.light,
          platform: TargetPlatform.iOS,
        );
        const column = Key('column');
        await pumpGolden(
          tester,
          theme: touch,
          direction: direction,
          SizedBox(
            width: 320,
            height: 420,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final city in cities)
                              DsListRow(title: Text(city)),
                          ],
                        ),
                      ),
                      DsSectionIndex(
                        key: column,
                        sections: turkish,
                        value: 'M',
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        final r = tester.getRect(find.byKey(column));
        await tester.startGesture(Offset(r.center.dx, r.center.dy));
        await tester.pump();
        await expectGolden(
          tester,
          'goldens/section_index_bubble_${mode}_${direction.name}.png',
        );
      });
    }
  }
}
