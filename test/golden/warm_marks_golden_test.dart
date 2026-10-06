@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Marks without a label under warm and bright brand colors, light and
/// dark: progress and slider fill, tab underline, the date range band and
/// the chosen days, today's ring and the avatar tones, next to the filled
/// controls (primary button, checked box). None of them may turn olive,
/// mustard, khaki or brown.
void main() {
  final seeds = {
    'yellow': const DsSeed.oklch(.85, .17, 95),
    'mcdonalds': DsSeed.color(const Color(0xFFFFC72C)),
    'orange': const DsSeed.oklch(.7, .19, 50),
    'oxblood': DsSeed.oxblood,
    'forest': DsSeed.forest,
    'blue': DsSeed.blue,
  };
  final today = DateTime(2026, 10, 5);

  Widget cell(String name, DsThemeData theme) {
    final k = theme.colors;
    return DsTheme(
      data: theme,
      child: ColoredBox(
        color: k.canvas,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DefaultTextStyle(
            style: theme.typography.body.copyWith(color: k.text),
            child: SizedBox(
              width: 296,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    '$name · ${theme.isDark ? 'dark' : 'light'}',
                    style: theme.typography.caption.copyWith(
                      color: k.textSubtle,
                    ),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      DsButton(
                        variant: DsButtonVariant.primary,
                        onPressed: () {},
                        child: const Text('Kaydet'),
                      ),
                      DsCheckbox(value: true, onChanged: (_) {}),
                      Expanded(
                        child: DsTabs<int>(
                          value: 0,
                          onChanged: (_) {},
                          tabs: const [
                            DsTab(value: 0, label: Text('Genel')),
                            DsTab(value: 1, label: Text('Ayar')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 296, child: DsProgressBar(value: .6)),
                  SizedBox(
                    width: 296,
                    child: DsSlider(value: .4, onChanged: (_) {}),
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      for (var i = 0; i < DsAvatar.toneCount; i++)
                        DsAvatar(
                          initials: String.fromCharCode(65 + i),
                          toneIndex: i,
                          size: DsSize.sm,
                        ),
                    ],
                  ),
                  DecoratedBox(
                    decoration: DsBoxDecoration(
                      color: k.overlay,
                      borderRadius: BorderRadius.circular(theme.radii.overlay),
                      shadows: theme.shadows.overlay,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DsRangeCalendar(
                        value: DsDateRange(
                          start: DateTime(2026, 10, 12),
                          end: DateTime(2026, 10, 18),
                        ),
                        currentDate: today,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('warm marks', (tester) async {
    final light = themesFor(DsSeed.blue)['light']!;
    await pumpGolden(
      tester,
      size: const Size(2000, 1300),
      DsLocalizationScope(
        localizations: const DsLocalizationsTr(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final mode in ['light', 'dark'])
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final MapEntry(key: name, value: seed) in seeds.entries)
                    cell(name, themesFor(seed)[mode]!),
                ],
              ),
          ],
        ),
      ),
      theme: light,
    );
    await expectGolden(tester, 'goldens/warm_marks.png');
  });
}
