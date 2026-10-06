@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the range slider: its states in light and dark,
/// and its touch band on a phone.
void main() {
  void noop(DsRangeValues _) {}

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('range slider states $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final focus = FocusNode();
      addTearDown(focus.dispose);
      const hoverKey = Key('hover');

      await pumpGolden(
        tester,
        theme: theme,
        GoldenGrid(
          columns: const ['Range'],
          cellWidth: 280,
          labelWidth: 88,
          rows: [
            (
              'default',
              [
                DsRangeSlider(
                  values: const DsRangeValues(start: .2, end: .7),
                  onChanged: noop,
                ),
              ],
            ),
            (
              'steps',
              [
                DsRangeSlider(
                  values: const DsRangeValues(start: 1, end: 3),
                  max: 4,
                  divisions: 4,
                  onChanged: noop,
                ),
              ],
            ),
            (
              'met',
              [
                DsRangeSlider(
                  values: const DsRangeValues(start: .5, end: .5),
                  onChanged: noop,
                ),
              ],
            ),
            (
              'hover',
              [
                DsRangeSlider(
                  key: hoverKey,
                  values: const DsRangeValues(start: .2, end: .7),
                  onChanged: noop,
                ),
              ],
            ),
            (
              'focus',
              [
                DsRangeSlider(
                  values: const DsRangeValues(start: .2, end: .7),
                  endFocusNode: focus,
                  onChanged: noop,
                ),
              ],
            ),
            (
              'disabled',
              [
                const DsRangeSlider(
                  values: DsRangeValues(start: .2, end: .7),
                  onChanged: null,
                ),
              ],
            ),
          ],
        ),
      );
      focus.requestFocus();
      final rect = tester.getRect(find.byKey(hoverKey));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      // Over the start thumb (at 0.2 of the travel).
      await mouse.moveTo(
        Offset(rect.left + 10 + .2 * (rect.width - 20), rect.center.dy),
      );
      await tester.pump();
      await expectGolden(tester, 'goldens/range_slider_states_$mode.png');
    });
  }

  testWidgets('range slider touch band', (tester) async {
    final desktop = DsThemeData(platform: goldenPlatform);
    final phone = DsThemeData(
      platform: TargetPlatform.iOS,
      density: DsDensity.compact,
    );
    // Tints the slider's touch band; what is painted is the same.
    Widget cell(DsThemeData theme) => DsTheme(
      data: theme,
      child: ColoredBox(
        color: theme.colors.accentTint,
        child: DsRangeSlider(
          values: const DsRangeValues(start: .3, end: .6),
          onChanged: noop,
        ),
      ),
    );
    await pumpGolden(
      tester,
      theme: desktop,
      GoldenGrid(
        columns: const ['macOS · 24', 'iOS · 44'],
        cellWidth: 240,
        cellHeight: 64,
        labelWidth: 72,
        rows: [
          ('range', [cell(desktop), cell(phone)]),
        ],
      ),
    );
    await expectGolden(tester, 'goldens/range_slider_touch.png');
  });
}
