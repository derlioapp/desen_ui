@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Accent surfaces under real brand colors, light and dark. Light
/// brands (yellow, orange, sky blue, green, mint) keep their own fill with a
/// dark label in both modes (the bright accent); progress,
/// link and focus use the darkened color, and the switch knob takes a dark
/// edge. Mid-tone brands that carry neither label well (Coca-Cola, Figma)
/// are darkened for a white label.
void main() {
  const brands = {
    'varsayılan': null,
    'mcdonalds': Color(0xFFFFC72C),
    'amazon': Color(0xFFFF9900),
    'twitter': Color(0xFF1DA1F2),
    'spotify': Color(0xFF1DB954),
    'coca-cola': Color(0xFFF40009),
    'stripe': Color(0xFF635BFF),
    'figma': Color(0xFFA259FF),
    'tiffany': Color(0xFF81D8D0),
    'snapchat': Color(0xFFFFFC00),
  };

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('brand seeds $mode', (tester) async {
      DsThemeData themeFor(Color? brand) => DsThemeData(
        seed: brand == null ? DsSeed.blue : DsSeed.color(brand),
        brightness: dark ? Brightness.dark : Brightness.light,
        platform: goldenPlatform,
      );
      List<Widget> row(Color? brand) => [
        for (final w in <Widget>[
          DsButton(
            variant: DsButtonVariant.primary,
            onPressed: () {},
            child: const Text('Kaydet'),
          ),
          DsCheckbox(value: true, onChanged: (_) {}),
          DsRadioGroup<int>(
            value: 1,
            onChanged: (_) {},
            child: const DsRadio(value: 1),
          ),
          DsSwitch(value: true, onChanged: (_) {}),
          const SizedBox(width: 96, child: DsProgressBar(value: .6)),
          DsChip(
            label: const Text('Seçili'),
            selected: true,
            onChanged: (_) {},
          ),
          DsLink(onPressed: () {}, label: 'bağlantı'),
        ])
          DsTheme(data: themeFor(brand), child: w),
      ];
      await pumpGolden(
        tester,
        theme: themeFor(null),
        GoldenGrid(
          columns: const [
            'Birincil',
            'Onay',
            'Radyo',
            'Anahtar',
            'İlerleme',
            'Çip',
            'Bağlantı',
          ],
          cellWidth: 112,
          rows: [
            for (final MapEntry(key: name, value: brand) in brands.entries)
              (name, row(brand)),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/brand_seeds_$mode.png');
    });
  }
}
