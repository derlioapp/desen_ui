import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// K-43 (S-32): on iOS and Android the default theme puts an invisible
/// 44px tap area around every small control; what is painted does not
/// change. Desktop keeps 24px.
void main() {
  Widget buttons() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DsButton.icon(
        size: DsSize.xs,
        icon: const DsIcon(DsIcons.settings),
        semanticLabel: 'Ayarlar',
        onPressed: () {},
      ),
      DsButton(size: DsSize.sm, onPressed: () {}, child: const Text('Kaydet')),
    ],
  );

  for (final (platform, phone) in [
    (TargetPlatform.iOS, true),
    (TargetPlatform.android, true),
    (TargetPlatform.macOS, false),
  ]) {
    testWidgets('${platform.name}: buttons paint the same; the layout box is '
        '${phone ? 44 : 'the painted box'}', (tester) async {
      await tester.pumpWidget(
        host(buttons(), theme: DsThemeData(platform: platform)),
      );
      // Painted: the compact sizes everywhere.
      expect(buttonBoxSize(tester), const Size(28, 28));
      expect(buttonBoxSize(tester, 1).height, 32);
      // Laid out: grown to the tap area on a phone.
      final icon = tester.getSize(find.byType(DsButton).first);
      final text = tester.getSize(find.byType(DsButton).last);
      expect(icon, phone ? const Size(44, 44) : const Size(28, 28));
      expect(text.height, phone ? 44 : 32);
      expect(text.width, buttonBoxSize(tester, 1).width);
    });
  }

  testWidgets('a tap in the added area activates on a phone', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        theme: DsThemeData(platform: TargetPlatform.iOS),
        DsButton.icon(
          size: DsSize.xs,
          icon: const DsIcon(DsIcons.settings),
          semanticLabel: 'Ayarlar',
          onPressed: () => taps++,
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsButton));
    // 2px inside the 44px area, 6px outside the painted 28px button.
    await tester.tapAt(box.topLeft + const Offset(2, 2));
    expect(taps, 1);
  });

  testWidgets(
    'without a theme, the fallback follows the platform',
    (tester) async {
      await tester.pumpWidget(
        host(
          DsButton.icon(
            size: DsSize.xs,
            icon: const DsIcon(DsIcons.settings),
            semanticLabel: 'Ayarlar',
            onPressed: () {},
          ),
        ),
      );
      final phone = defaultTargetPlatform == TargetPlatform.iOS;
      expect(
        tester.getSize(find.byType(DsButton)),
        phone ? const Size(44, 44) : const Size(28, 28),
      );
      expect(buttonBoxSize(tester), const Size(28, 28));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets('rows are their own tap surface and keep their height on a '
      'phone', (tester) async {
    await tester.pumpWidget(
      host(
        theme: DsThemeData(
          platform: TargetPlatform.iOS,
          density: DsDensity.compact,
        ),
        SizedBox(
          width: 300,
          child: DsListSection(
            children: [DsListRow(title: const Text('Dil'), onPressed: () {})],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DsListRow)).height, 40);
  });

  testWidgets('a toolbar keeps its height on a phone: the tap areas reach '
      'into its padding', (tester) async {
    Future<Size> toolbar(TargetPlatform platform) async {
      await tester.pumpWidget(
        host(
          theme: DsThemeData(platform: platform),
          DsToolbar(
            children: [
              DsToolbarToggle(
                icon: const DsIcon(DsIcons.bold),
                semanticLabel: 'Kalın',
                selected: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      return tester.getSize(find.byType(DsToolbar));
    }

    final desktop = await toolbar(TargetPlatform.macOS);
    final phone = await toolbar(TargetPlatform.iOS);
    expect(phone.height, 44, reason: 'the tap area itself');
    expect(phone.height - desktop.height, lessThanOrEqualTo(2));
  });
}
