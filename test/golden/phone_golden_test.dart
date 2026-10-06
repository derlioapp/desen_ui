@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// K-43 (S-32): the same compact controls on a desktop and on a phone. On
/// the phone each small control sits in an invisible 44px tap area, shown
/// here with a faint tint; what is painted is identical in both columns.
void main() {
  testWidgets('phone tap areas', (tester) async {
    final desktop = DsThemeData(platform: goldenPlatform);
    final phone = DsThemeData(
      platform: TargetPlatform.iOS,
      density: DsDensity.compact,
    );

    // Tints every tap area (each pressable's layout box) in a cell.
    Widget area(Widget child) => Builder(
      builder: (context) =>
          ColoredBox(color: DsTheme.colorsOf(context).accentTint, child: child),
    );

    List<Widget> row(Widget Function() build) => [
      for (final theme in [desktop, phone])
        DsTheme(data: theme, child: build()),
    ];

    await pumpGolden(
      tester,
      theme: desktop,
      GoldenGrid(
        columns: const ['macOS · 24', 'iOS · 44'],
        cellWidth: 300,
        cellHeight: 64,
        labelWidth: 96,
        rows: [
          (
            'icon xs/sm/md',
            row(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  for (final size in [DsSize.xs, DsSize.sm, DsSize.md])
                    area(
                      DsButton.icon(
                        size: size,
                        variant: DsButtonVariant.secondary,
                        icon: const DsIcon(DsIcons.settings),
                        semanticLabel: 'Ayarlar',
                        onPressed: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
          (
            'button sm',
            row(
              () => area(
                DsButton(
                  size: DsSize.sm,
                  onPressed: () {},
                  child: const Text('Kaydet'),
                ),
              ),
            ),
          ),
          (
            'controls',
            row(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  area(DsCheckbox(value: true, onChanged: (_) {})),
                  area(DsSwitch(value: true, onChanged: (_) {})),
                  area(
                    DsChip(
                      label: const Text('Çip'),
                      selected: true,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          (
            'toolbar',
            row(
              () => DsToolbar(
                children: [
                  for (final (icon, label) in [
                    (DsIcons.bold, 'Kalın'),
                    (DsIcons.italic, 'İtalik'),
                    (DsIcons.underline, 'Altı çizili'),
                  ])
                    DsToolbarToggle(
                      icon: DsIcon(icon),
                      semanticLabel: label,
                      selected: icon == DsIcons.bold,
                      onChanged: (_) {},
                    ),
                ],
              ),
            ),
          ),
          (
            'pagination',
            row(() => DsPagination(page: 2, pageCount: 4, onChanged: (_) {})),
          ),
        ],
      ),
    );
    // The drawn page button keeps its square in the taller cell on both
    // platforms; only the tap area grows (it used to stretch to 32×64).
    final pages = find.ancestor(
      of: find.text('2'),
      matching: find.byType(AnimatedContainer),
    );
    expect(pages, findsNWidgets(2));
    for (final box in pages.evaluate()) {
      expect(tester.getSize(find.byWidget(box.widget)), const Size(32, 32));
    }
    await expectGolden(tester, 'goldens/phone_tap_areas.png');
  });
}
