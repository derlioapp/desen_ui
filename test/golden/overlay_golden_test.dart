@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the popover, tooltip and menu, light and dark.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('layers $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final popover = DsOverlayController();
      final menu = DsOverlayController();
      addTearDown(popover.dispose);
      addTearDown(menu.dispose);
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 820,
          height: 380,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 20,
                      child: DsMenuAnchor(
                        controller: menu,
                        items: [
                          DsMenuItem(
                            label: const Text('Düzenle'),
                            shortcut: '⌘E',
                            onPressed: () {},
                          ),
                          DsMenuItem(
                            label: const Text('Çoğalt'),
                            shortcut: '⌘D',
                            onPressed: () {},
                          ),
                          DsMenuItem(
                            label: const Text('Paylaş…'),
                            onPressed: () {},
                          ),
                          const DsMenuItem(
                            label: Text('Arşivle'),
                            onPressed: null,
                          ),
                          const DsMenuDivider(),
                          DsMenuItem(
                            label: const Text('Sil'),
                            shortcut: '⌘⌫',
                            destructive: true,
                            onPressed: () {},
                          ),
                        ],
                        child: DsButton(
                          onPressed: menu.toggle,
                          child: const Text('Menü'),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 300,
                      top: 20,
                      width: 340,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: DsPopover(
                          controller: popover,
                          align: DsAlign.end,
                          contentBuilder: (context) {
                            final t = DsTheme.of(context);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 12,
                              children: [
                                Text(
                                  'Bağlantıyla paylaş',
                                  style: t.typography.bodyStrong,
                                ),
                                Text(
                                  'Bağlantıya sahip olan herkes '
                                  'görüntüleyebilir.',
                                  style: t.typography.caption.copyWith(
                                    color: t.colors.textMuted,
                                  ),
                                ),
                                DsButton(
                                  variant: DsButtonVariant.primary,
                                  size: DsSize.sm,
                                  onPressed: () {},
                                  child: const Text('Kopyala'),
                                ),
                              ],
                            );
                          },
                          child: DsButton(
                            onPressed: popover.toggle,
                            child: const Text('Paylaş'),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 680,
                      top: 300,
                      child: DsTooltip(
                        message: 'Bağlantıyı kopyala',
                        shortcut: '⌘C',
                        child: DsButton.icon(
                          icon: const DsIcon(DsIcons.link),
                          semanticLabel: 'Kopyala',
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      menu.open();
      popover.open();
      await tester.pumpAndSettle();
      // The menu's first item takes keyboard focus: its highlight shows.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(1100, 800));
      await mouse.moveTo(tester.getCenter(find.byType(DsTooltip)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/layers_$mode.png');
    });
  }
}
