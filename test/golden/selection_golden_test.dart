@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the selection controls (checkbox, radio, switch,
/// chip, segmented control, slider), light and dark.
void main() {
  final controllers = <WidgetStatesController>[];
  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
  });
  WidgetStatesController forced(Set<WidgetState> s) {
    final c = WidgetStatesController(s);
    controllers.add(c);
    return c;
  }

  const columns = ['Normal', 'Hover', 'Odak', 'Hata', 'Pasif'];

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('checkbox, switch and chip states $mode', (tester) async {
      List<Widget> checkbox(bool? v) => [
        DsCheckbox(value: v, tristate: true, onChanged: (_) {}),
        DsCheckbox(
          value: v,
          tristate: true,
          statesController: forced({WidgetState.hovered}),
          onChanged: (_) {},
        ),
        DsCheckbox(
          value: v,
          tristate: true,
          statesController: forced({WidgetState.focused}),
          onChanged: (_) {},
        ),
        DsCheckbox(value: v, tristate: true, error: true, onChanged: (_) {}),
        DsCheckbox(value: v, tristate: true, onChanged: null),
      ];
      List<Widget> toggle(bool v) => [
        DsSwitch(value: v, onChanged: (_) {}),
        DsSwitch(
          value: v,
          statesController: forced({WidgetState.hovered}),
          onChanged: (_) {},
        ),
        DsSwitch(
          value: v,
          statesController: forced({WidgetState.focused}),
          onChanged: (_) {},
        ),
        const SizedBox(),
        DsSwitch(value: v, onChanged: null),
      ];
      List<Widget> chip(bool v) => [
        DsChip(label: const Text('Çip'), selected: v, onChanged: (_) {}),
        DsChip(
          label: const Text('Çip'),
          selected: v,
          statesController: forced({WidgetState.hovered}),
          onChanged: (_) {},
        ),
        DsChip(
          label: const Text('Çip'),
          selected: v,
          statesController: forced({WidgetState.focused}),
          onChanged: (_) {},
        ),
        const SizedBox(),
        DsChip(label: const Text('Çip'), selected: v, onChanged: null),
      ];
      await pumpGolden(
        tester,
        theme: theme,
        GoldenGrid(
          columns: columns,
          cellWidth: 104,
          rows: [
            ('checkbox off', checkbox(false)),
            ('checkbox on', checkbox(true)),
            ('checkbox mixed', checkbox(null)),
            ('switch off', toggle(false)),
            ('switch on', toggle(true)),
            ('chip off', chip(false)),
            ('chip on', chip(true)),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/selection_states_$mode.png');
    });

    testWidgets('radio, segmented and slider $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              DsRadioGroup<int>(
                value: 2,
                onChanged: (_) {},
                child: const Row(
                  spacing: 16,
                  children: [
                    DsRadio(value: 1, label: Text('Bir')),
                    DsRadio(value: 2, label: Text('İki')),
                    DsRadio(value: 3, label: Text('Hata'), error: true),
                    DsRadio(value: 4, label: Text('Pasif'), enabled: false),
                  ],
                ),
              ),
              for (final style in DsSelectionStyle.values)
                DsTheme(
                  data: theme.copyWith(selectionStyle: style),
                  child: DsSegmentedControl<int>(
                    value: 1,
                    onChanged: (_) {},
                    segments: const [
                      DsSegment(value: 0, label: Text('Gün')),
                      DsSegment(value: 1, label: Text('Hafta')),
                      DsSegment(value: 2, label: Text('Ay')),
                      DsSegment(value: 3, label: Text('Yıl'), enabled: false),
                    ],
                  ),
                ),
              DsSegmentedControl<int>(
                value: 0,
                onChanged: (_) {},
                segments: const [
                  DsSegment(
                    value: 0,
                    icon: DsIcon(DsIcons.layoutGrid),
                    semanticLabel: 'a',
                  ),
                  DsSegment(
                    value: 1,
                    icon: DsIcon(DsIcons.list),
                    semanticLabel: 'b',
                  ),
                ],
              ),
              DsSlider(value: .62, onChanged: (_) {}),
              DsSlider(
                value: 2,
                min: 0,
                max: 4,
                divisions: 4,
                onChanged: (_) {},
              ),
              const DsSlider(value: .3, onChanged: null),
            ],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/selection_controls_$mode.png');
    });

    // Labels of two lines: each control sits on the first line, as on the
    // web, not between the lines.
    testWidgets('two-line labels $mode', (tester) async {
      Widget lines(String title, String detail) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Text(
            detail,
            style: theme.typography.small.copyWith(
              color: theme.colors.textMuted,
            ),
          ),
        ],
      );
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              DsCheckbox(
                value: true,
                onChanged: (_) {},
                label: lines('Kargo takibi', 'Her adımda e-posta gönder'),
              ),
              DsRadioGroup<String>(
                value: 'a',
                onChanged: (_) {},
                child: DsRadio<String>(
                  value: 'a',
                  label: lines('Standart · Ücretsiz', '3–5 iş günü'),
                ),
              ),
              DsSwitch(
                value: true,
                onChanged: (_) {},
                label: const Text('Anlık bildirimler'),
                description: const Text('Mobil ve masaüstü'),
              ),
            ],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/selection_two_lines_$mode.png');
    });
  }
}
