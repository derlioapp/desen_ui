@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for a menu with an open submenu, light and
/// dark: the item keeps its highlight, the chevron points to the
/// submenu, whose first item lines up with it and has keyboard focus.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('submenu $mode', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final menu = DsOverlayController();
      addTearDown(menu.dispose);
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 560,
          height: 300,
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
                          DsMenuItem.submenu(
                            label: const Text('Taşı'),
                            leading: const DsIcon(DsIcons.folder),
                            submenu: [
                              DsMenuItem(
                                label: const Text('Arşiv'),
                                onPressed: () {},
                              ),
                              DsMenuItem(
                                label: const Text('Belgeler'),
                                onPressed: () {},
                              ),
                              DsMenuItem(
                                label: const Text('Sprint 14'),
                                onPressed: () {},
                              ),
                              const DsMenuDivider(),
                              DsMenuItem(
                                label: const Text('Yeni klasör…'),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const DsMenuItem.submenu(
                            label: Text('Paylaş'),
                            enabled: false,
                            submenu: [],
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
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      menu.open();
      await tester.pumpAndSettle();
      // Down twice to "Taşı", Right opens it with focus on "Arşiv".
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/submenu_$mode.png');
    });
  }
}
