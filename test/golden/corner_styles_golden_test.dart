@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// The corner rule across the four corner styles: one row of controls
/// (buttons of every size, a field, a chip, a segmented control, a
/// checkbox, a stepper) and one row of containers with the pieces nested
/// in them (a list section with a highlighted row, a card with media, a
/// menu with a highlighted row, a toolbar with a selected toggle).
void main() {
  testWidgets('corner styles', (tester) async {
    Widget controls() => Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 12,
        children: [
          for (final size in DsSize.values)
            DsButton(
              variant: .secondary,
              size: size,
              onPressed: () {},
              child: Text(size.name),
            ),
          const SizedBox(
            width: 150,
            child: DsTextField(initialValue: 'Ekip toplantısı'),
          ),
          DsChip(
            label: const Text('Haftalık'),
            selected: true,
            onChanged: (_) {},
          ),
          DsSegmentedControl<int>(
            value: 0,
            onChanged: (_) {},
            segments: const [
              DsSegment(value: 0, label: Text('Gün')),
              DsSegment(value: 1, label: Text('Hafta')),
            ],
          ),
          DsCheckbox(value: true, onChanged: (_) {}, semanticLabel: 'x'),
          DsStepper(value: 2, onChanged: (_) {}, semanticLabel: 'Misafir'),
        ],
      ),
    );

    Widget containers() => Builder(
      builder: (context) {
        final t = DsTheme.of(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            SizedBox(
              width: 220,
              child: DsListSection(
                children: [
                  DsListRow(
                    leading: const DsIcon(DsIcons.bell),
                    title: const Text('Bildirimler'),
                    showChevron: true,
                    style: DsListRowStyle(background: t.colors.hover),
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.globe),
                    title: const Text('Dil'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    const DsSkeleton.block(height: 56, strong: true),
                    Text('Kapak', style: t.typography.bodyStrong),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: DsMenu(
                children: [
                  DsMenuItem(
                    label: const Text('Düzenle'),
                    style: DsMenuItemStyle(background: t.colors.hover),
                    onPressed: () {},
                  ),
                  DsMenuItem(label: const Text('Çoğalt'), onPressed: () {}),
                ],
              ),
            ),
            DsToolbar(
              children: [
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.bold),
                  semanticLabel: 'Kalın',
                  selected: true,
                  onChanged: (_) {},
                ),
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.italic),
                  semanticLabel: 'İtalik',
                  selected: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        );
      },
    );

    await pumpGolden(
      tester,
      theme: DsThemeData(platform: goldenPlatform),
      size: const Size(1100, 1100),
      Builder(
        builder: (context) {
          final t = DsTheme.of(context);
          final label = t.typography
              .mono(t.typography.caption)
              .copyWith(color: t.colors.textSubtle, fontSize: 11);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              for (final style in DsCornerStyle.values)
                DsTheme(
                  data: DsThemeData(
                    cornerStyle: style,
                    platform: goldenPlatform,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(style.name, style: label),
                      controls(),
                      containers(),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
    await expectGolden(tester, 'goldens/corner_styles_light.png');
  });
}
