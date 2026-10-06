@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsTimePicker: the open columns
/// on a 24-hour clock (Turkish) and on a 12-hour clock with the AM/PM
/// column (US English); light and dark. Then items out of range (office
/// hours 09:30–18:00: hours 07–08 and minutes 00–15 struck through) in
/// both densities, and the seconds column.
void main() {
  Widget picker(
    DsTime value, {
    required bool tr,
    DsTime? firstTime,
    DsTime? lastTime,
    bool showSeconds = false,
    double height = 340,
  }) {
    Widget child = Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 200,
        child: DsField(
          label: Text(tr ? 'Başlangıç' : 'Start'),
          child: DsTimePicker(
            value: value,
            minuteStep: 15,
            firstTime: firstTime,
            lastTime: lastTime,
            showSeconds: showSeconds,
            secondStep: 5,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    child = tr
        ? DsLocalizationScope(
            localizations: const DsLocalizationsTr(),
            child: child,
          )
        : Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [DefaultWidgetsLocalizations.delegate],
            child: child,
          );
    return SizedBox(
      width: 260,
      height: height,
      child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
    );
  }

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    for (final (name, tr) in [('24h', true), ('12h', false)]) {
      testWidgets('time picker open $name $mode', (tester) async {
        await pumpGolden(
          tester,
          theme: theme,
          picker(const DsTime(14, 30), tr: tr),
        );
        await tester.tap(find.byType(DsButton).first);
        await tester.pumpAndSettle();
        await expectGolden(tester, 'goldens/time_picker_${name}_$mode.png');
      });
    }
    testWidgets('time picker seconds $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        picker(const DsTime(14, 30, 5), tr: true, showSeconds: true),
      );
      await tester.tap(find.byType(DsButton).first);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/time_picker_seconds_$mode.png');
    });
  }

  final limits = {
    ...themesFor(DsSeed.blue),
    'touch': DsThemeData(
      seed: DsSeed.blue,
      density: DsDensity.touch,
      platform: goldenPlatform,
    ),
  };
  for (final MapEntry(key: mode, value: theme) in limits.entries) {
    testWidgets('time picker limits $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        picker(
          const DsTime(9, 30),
          tr: true,
          firstTime: const DsTime(9, 30),
          lastTime: const DsTime(18, 0),
          height: mode == 'touch' ? 460 : 340,
        ),
      );
      await tester.tap(find.byType(DsButton).first);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/time_picker_limits_$mode.png');
    });
  }
}
