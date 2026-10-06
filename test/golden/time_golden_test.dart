@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsTimePicker (concept card 35): the open columns
/// on a 24-hour clock (Turkish) and on a 12-hour clock with the AM/PM
/// column (US English); light and dark (KALITE K-24).
void main() {
  Widget picker(DsTime value, {required bool tr}) {
    Widget child = Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 200,
        child: DsField(
          label: Text(tr ? 'Başlangıç' : 'Start'),
          child: DsTimePicker(value: value, minuteStep: 15, onChanged: (_) {}),
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
      height: 340,
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
  }
}
