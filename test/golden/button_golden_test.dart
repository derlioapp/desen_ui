@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsButton, light and dark.
void main() {
  // States forced through a controller so every cell is deterministic.
  final controllers = <WidgetStatesController>[];
  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
  });
  WidgetStatesController forced(Set<WidgetState> states) =>
      WidgetStatesController(states)..also(controllers.add);

  Widget onAccent(Widget child) => Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DsTheme.colorsOf(context).accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    ),
  );

  List<Widget> states(DsButtonVariant v, {bool icon = false}) {
    Widget b({
      Set<WidgetState> s = const {},
      bool enabled = true,
      bool loading = false,
    }) => icon
        ? DsButton.icon(
            variant: v,
            statesController: forced(s),
            loading: loading,
            semanticLabel: 'x',
            icon: const DsIcon(DsIcons.settings),
            onPressed: enabled ? () {} : null,
          )
        : DsButton(
            variant: v,
            statesController: forced(s),
            loading: loading,
            onPressed: enabled ? () {} : null,
            child: const Text('Kaydet'),
          );
    final cells = [
      b(),
      b(s: {WidgetState.hovered}),
      b(s: {WidgetState.focused}),
      b(s: {WidgetState.pressed}),
      b(enabled: false),
      b(loading: true),
    ];
    // The inverse button is made for an accent ground: shown there, its
    // focus ring and disabled look read as they will in an app.
    return v == DsButtonVariant.inverse
        ? [for (final c in cells) onAccent(c)]
        : cells;
  }

  const stateColumns = [
    'Normal',
    'Hover',
    'Odak',
    'Basılı',
    'Pasif',
    'Yükleniyor',
  ];

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    for (final dpr in [1.0, 2.0]) {
      testWidgets('states $mode ${dpr.toInt()}x', (tester) async {
        await pumpGolden(
          tester,
          dpr: dpr,
          theme: theme,
          GoldenGrid(
            columns: stateColumns,
            rows: [
              for (final v in DsButtonVariant.values) (v.name, states(v)),
              ('icon/ghost', states(.ghost, icon: true)),
            ],
          ),
        );
        await expectGolden(
          tester,
          'goldens/button_states_${mode}_${dpr.toInt()}x.png',
        );
      });
    }

    testWidgets('sizes $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        GoldenGrid(
          columns: const ['xs', 'sm', 'md', 'lg'],
          cellWidth: 140,
          cellHeight: 64,
          rows: [
            for (final v in [
              DsButtonVariant.primary,
              DsButtonVariant.secondary,
            ])
              (
                v.name,
                [
                  for (final s in DsSize.values)
                    DsButton(
                      variant: v,
                      size: s,
                      onPressed: () {},
                      child: const Text('Kaydet'),
                    ),
                ],
              ),
            (
              'leading icon',
              [
                for (final s in DsSize.values)
                  DsButton(
                    size: s,
                    leading: const DsIcon(DsIcons.plus),
                    onPressed: () {},
                    child: const Text('Yeni'),
                  ),
              ],
            ),
            (
              'icon/secondary',
              [
                for (final s in DsSize.values)
                  DsButton.icon(
                    variant: .secondary,
                    size: s,
                    semanticLabel: 'x',
                    icon: const DsIcon(DsIcons.settings),
                    onPressed: () {},
                  ),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/button_sizes_$mode.png');
    });

    testWidgets('tones $mode', (tester) async {
      Widget row(DsSeed seed) {
        final t = mode == 'dark'
            ? DsThemeData(
                seed: seed,
                brightness: Brightness.dark,
                platform: goldenPlatform,
              )
            : DsThemeData(seed: seed, platform: goldenPlatform);
        return DsTheme(
          data: t,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in DsButtonVariant.values)
                SizedBox(
                  width: 132,
                  child: Center(
                    child:
                        (v == DsButtonVariant.inverse
                        ? onAccent
                        : (Widget w) => w)(
                          DsButton(
                            variant: v,
                            onPressed: () {},
                            child: const Text('Kaydet'),
                          ),
                        ),
                  ),
                ),
              SizedBox(
                width: 132,
                child: Center(
                  child: DsButton(
                    statesController: forced({WidgetState.focused}),
                    onPressed: () {},
                    child: const Text('Odak'),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      await pumpGolden(
        tester,
        theme: theme,
        size: const Size(1400, 900),
        GoldenGrid(
          columns: const [],
          cellWidth: 1188, // 9 cells of 132: every variant and the focus ring
          rows: [
            for (final (name, seed) in [
              ('blue', DsSeed.blue),
              ('navy', DsSeed.navy),
              ('graphite', DsSeed.graphite),
              ('oxblood', DsSeed.oxblood),
              ('forest', DsSeed.forest),
              ('indigo', DsSeed.indigo),
            ])
              (name, [row(seed)]),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/button_tones_$mode.png');
    });
  }

  testWidgets('corner styles', (tester) async {
    Widget row(DsCornerStyle style) => DsTheme(
      data: DsThemeData(cornerStyle: style, platform: goldenPlatform),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final w in [
            DsButton(onPressed: () {}, child: const Text('Kaydet')),
            DsButton(
              variant: .secondary,
              onPressed: () {},
              child: const Text('Vazgeç'),
            ),
            DsButton(
              variant: .secondary,
              statesController: forced({WidgetState.focused}),
              onPressed: () {},
              child: const Text('Odak'),
            ),
            DsButton.icon(
              variant: .secondary,
              semanticLabel: 'x',
              icon: const DsIcon(DsIcons.settings),
              onPressed: () {},
            ),
          ])
            SizedBox(width: 132, child: Center(child: w)),
        ],
      ),
    );
    await pumpGolden(
      tester,
      theme: DsThemeData(platform: goldenPlatform),
      GoldenGrid(
        columns: const [],
        cellWidth: 528,
        rows: [
          for (final s in DsCornerStyle.values) (s.name, [row(s)]),
        ],
      ),
    );
    await expectGolden(tester, 'goldens/button_corners.png');
  });

  testWidgets('touch density, RTL and large text', (tester) async {
    await pumpGolden(
      tester,
      theme: DsThemeData(density: DsDensity.touch, platform: goldenPlatform),
      direction: TextDirection.rtl,
      textScale: 1.6,
      GoldenGrid(
        columns: const ['xs', 'sm', 'md', 'lg'],
        cellWidth: 160,
        cellHeight: 80,
        rows: [
          (
            'touch rtl 1.6x',
            [
              for (final s in DsSize.values)
                DsButton(
                  size: s,
                  leading: const DsIcon(DsIcons.plus),
                  onPressed: () {},
                  child: const Text('Yeni'),
                ),
            ],
          ),
          (
            'secondary',
            [
              for (final s in DsSize.values)
                DsButton(
                  variant: .secondary,
                  size: s,
                  trailing: const DsIcon(DsIcons.chevronRight),
                  onPressed: () {},
                  child: const Text('İleri'),
                ),
            ],
          ),
        ],
      ),
    );
    await expectGolden(tester, 'goldens/button_touch_rtl_text.png');
  });
}

extension<T> on T {
  T also(void Function(T) f) {
    f(this);
    return this;
  }
}
