@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Keyboard focus, by kind of control, at standard and soft contrast:
/// - fields: one 2px focus edge, no ring;
/// - bordered, unfilled controls: the tight ring over the border;
/// - filled controls: the gapped ring;
/// - full-width rows: the ring inside.
///
/// Only one widget holds focus at a time, so each focused field and row is
/// drawn on its own with real focus, then laid into the grid as an image.
void main() {
  final controllers = <WidgetStatesController>[];
  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
  });
  WidgetStatesController focused() {
    final c = WidgetStatesController({WidgetState.focused});
    controllers.add(c);
    return c;
  }

  for (final MapEntry(key: mode, value: base) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('focus ring mode $mode', (tester) async {
      final soft = base.copyWith(contrast: DsContrast.soft);
      final images = <ui.Image>[];
      addTearDown(() {
        for (final i in images) {
          i.dispose();
        }
      });
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      /// [build] drawn alone under [theme], with its node focused from the
      /// keyboard; shown at its own size (with the harness margin).
      Future<Widget> shot(
        DsThemeData theme,
        Widget Function(FocusNode) build,
      ) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        // A fresh subtree each time, so no field keeps the last one's text.
        await pumpGolden(
          tester,
          KeyedSubtree(key: UniqueKey(), child: build(node)),
          theme: theme,
        );
        node.requestFocus();
        // Any key marks keyboard modality.
        await tester.sendKeyEvent(LogicalKeyboardKey.f12);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        final boundary =
            goldenKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = (await tester.runAsync(
          () => boundary.toImage(pixelRatio: tester.view.devicePixelRatio),
        ))!;
        images.add(image);
        node.unfocus();
        await tester.pump();
        return RawImage(image: image, scale: tester.view.devicePixelRatio);
      }

      final fields = <Widget Function(FocusNode)>[
        (n) => SizedBox(
          width: 168,
          child: DsTextField(focusNode: n, initialValue: 'Emre Candan'),
        ),
        (n) => SizedBox(
          width: 168,
          child: DsTextField(focusNode: n, initialValue: 'emre@', error: true),
        ),
        (n) => SizedBox(
          width: 168,
          child: DsSelect<int>(
            value: 1,
            focusNode: n,
            options: const [DsSelectOption(value: 1, label: 'Tasarım')],
            onChanged: (_) {},
          ),
        ),
        (n) => SizedBox(
          width: 168,
          child: DsTextField(
            focusNode: n,
            initialValue: 'Salt okunur',
            readOnly: true,
          ),
        ),
      ];
      Widget row(FocusNode n) => SizedBox(
        width: 200,
        child: DsListSection(
          children: [
            DsListRow(
              title: const Text('Bildirimler'),
              showChevron: true,
              focusNode: n,
              onPressed: () {},
            ),
          ],
        ),
      );

      final fieldShots = [
        for (final theme in [base, soft])
          [for (final f in fields) await shot(theme, f)],
      ];
      final rowShots = [
        for (final t in [base, soft]) await shot(t, row),
      ];

      List<Widget> tight() => [
        DsButton(
          variant: DsButtonVariant.secondary,
          statesController: focused(),
          onPressed: () {},
          child: const Text('Vazgeç'),
        ),
        DsChip(
          label: const Text('Çip'),
          selected: false,
          statesController: focused(),
          onChanged: (_) {},
        ),
      ];
      List<Widget> gapped() => [
        DsButton(
          variant: DsButtonVariant.primary,
          statesController: focused(),
          onPressed: () {},
          child: const Text('Kaydet'),
        ),
        DsButton(
          variant: DsButtonVariant.danger,
          statesController: focused(),
          onPressed: () {},
          child: const Text('Sil'),
        ),
        DsChip(
          label: const Text('Çip'),
          selected: true,
          statesController: focused(),
          onChanged: (_) {},
        ),
        DsCheckbox(value: true, statesController: focused(), onChanged: (_) {}),
        DsSwitch(value: true, statesController: focused(), onChanged: (_) {}),
      ];
      List<Widget> inSoft(List<Widget> cells) => [
        for (final c in cells) DsTheme(data: soft, child: c),
      ];

      await pumpGolden(
        tester,
        theme: base,
        size: const Size(1200, 1000),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            GoldenGrid(
              columns: const ['Alan', 'Hata', 'Seçim', 'Salt okunur'],
              cellWidth: 220,
              cellHeight: 80,
              rows: [('alan', fieldShots[0]), ('alan soft', fieldShots[1])],
            ),
            GoldenGrid(
              columns: const ['İkincil', 'Çip'],
              cellWidth: 140,
              rows: [('sıkı', tight()), ('sıkı soft', inSoft(tight()))],
            ),
            GoldenGrid(
              columns: const [
                'Birincil',
                'Tehlike',
                'Seçili çip',
                'Onay',
                'Anahtar',
              ],
              cellWidth: 140,
              rows: [
                ('aralıklı', gapped()),
                ('aralıklı soft', inSoft(gapped())),
              ],
            ),
            GoldenGrid(
              columns: const ['Satır'],
              cellWidth: 260,
              cellHeight: 92,
              rows: [
                ('satır', [rowShots[0]]),
                ('satır soft', [rowShots[1]]),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/focus_ring_$mode.png');
    });
  }
}
