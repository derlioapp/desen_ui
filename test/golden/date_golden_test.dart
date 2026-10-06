@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the calendar (concept cards 24 and 39): one
/// chosen day with today, a range with its band, Monday-first Turkish next
/// to Sunday-first US English; light and dark (KALITE K-24).
void main() {
  final today = DateTime(2026, 10, 5);

  Widget card(DsThemeData theme, String label, Widget child) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(
        label,
        style: theme.typography.caption.copyWith(
          color: theme.colors.textSubtle,
        ),
      ),
      DecoratedBox(
        decoration: DsBoxDecoration(
          color: theme.colors.overlay,
          borderRadius: BorderRadius.circular(theme.radii.overlay),
          shadows: theme.shadows.overlay,
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ],
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('calendar $mode', (tester) async {
      await pumpGolden(
        tester,
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [
              card(
                theme,
                'single · today 5, chosen 14',
                DsCalendar(
                  value: DateTime(2026, 10, 14),
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
              card(
                theme,
                'range 12–18 · 22–23 off',
                DsRangeCalendar(
                  value: DsDateRange(
                    start: DateTime(2026, 10, 12),
                    end: DateTime(2026, 10, 18),
                  ),
                  currentDate: today,
                  selectableDayPredicate: (d) => d.day != 22 && d.day != 23,
                  onChanged: (_) {},
                ),
              ),
              card(
                theme,
                'range across weeks · outside days',
                DsRangeCalendar(
                  value: DsDateRange(
                    start: DateTime(2026, 10, 8),
                    end: DateTime(2026, 10, 21),
                  ),
                  currentDate: today,
                  showOutsideDays: true,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        theme: theme,
      );
      await expectGolden(tester, 'goldens/calendar_$mode.png');
    });

    // Two months side by side line up (titles, weekday rows, grids),
    // though only the last carries the month buttons; also with touch
    // sizes, where the buttons' tap target is taller.
    testWidgets('calendar two months $mode', (tester) async {
      Widget twoMonths() => DsRangeCalendar(
        value: DsDateRange(
          start: DateTime(2026, 10, 26),
          end: DateTime(2026, 11, 4),
        ),
        currentDate: today,
        months: 2,
        onChanged: (_) {},
      );
      await pumpGolden(
        tester,
        size: const Size(1200, 1000),
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              card(theme, 'two months · desktop', twoMonths()),
              DsTheme(
                data: DsThemeData(
                  brightness: theme.brightness,
                  platform: TargetPlatform.android,
                  density: DsDensity.compact,
                ),
                child: Builder(
                  builder: (context) => card(
                    DsTheme.of(context),
                    'two months · touch',
                    twoMonths(),
                  ),
                ),
              ),
            ],
          ),
        ),
        theme: theme,
      );
      await expectGolden(tester, 'goldens/calendar_two_months_$mode.png');
    });

    testWidgets('date picker open $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: SizedBox(
            width: 380,
            height: 440,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 240,
                      child: DsField(
                        label: const Text('Teslim tarihi'),
                        child: DsDatePicker(
                          value: DateTime(2026, 10, 14),
                          currentDate: today,
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsButton).first);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/date_picker_open_$mode.png');
    });

    testWidgets('date range picker open $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: SizedBox(
            width: 640,
            height: 440,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: DsField(
                      label: const Text('Konaklama'),
                      child: DsDateRangePicker(
                        value: DsDateRange(
                          start: DateTime(2026, 10, 12),
                          end: DateTime(2026, 10, 18),
                        ),
                        currentDate: today,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsButton).first);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/date_range_picker_open_$mode.png');
    });

    testWidgets('calendar week start $mode', (tester) async {
      await pumpGolden(
        tester,
        Wrap(
          spacing: 32,
          children: [
            card(
              theme,
              'tr · Monday first',
              DsLocalizationScope(
                localizations: const DsLocalizationsTr(),
                child: DsCalendar(
                  value: DateTime(2026, 10, 14),
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
            ),
            card(
              theme,
              'en_US · Sunday first',
              Localizations(
                locale: const Locale('en', 'US'),
                delegates: const [DefaultWidgetsLocalizations.delegate],
                child: DsCalendar(
                  value: DateTime(2026, 10, 14),
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        theme: theme,
      );
      await expectGolden(tester, 'goldens/calendar_week_start_$mode.png');
    });
  }

  // A bright accent (K-130): the filled day and range ends wear the dark
  // label and the accent edge; today's ring stands off the card and the
  // band; a chosen today is only filled.
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.color(const Color(0xFFFFC72C)),
  ).entries) {
    testWidgets('calendar bright accent $mode', (tester) async {
      await pumpGolden(
        tester,
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [
              card(
                theme,
                'bright · today 5, chosen 14',
                DsCalendar(
                  value: DateTime(2026, 10, 14),
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
              card(
                theme,
                'bright · range 2–8 over today',
                DsRangeCalendar(
                  value: DsDateRange(
                    start: DateTime(2026, 10, 2),
                    end: DateTime(2026, 10, 8),
                  ),
                  currentDate: today,
                  onChanged: (_) {},
                ),
              ),
              card(
                theme,
                'bright · chosen today',
                DsCalendar(value: today, currentDate: today, onChanged: (_) {}),
              ),
            ],
          ),
        ),
        theme: theme,
      );
      await expectGolden(tester, 'goldens/calendar_bright_accent_$mode.png');
    });
  }
}
