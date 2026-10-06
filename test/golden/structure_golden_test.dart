@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the Faz 5c components, light and dark (K-24).
void main() {
  // A card with the component on top and placeholder content below, as in
  // the concept (the divider separates the two).
  Widget card(Widget child, {double width = 380}) => SizedBox(
    width: width,
    child: DsCard(
      style: const DsCardStyle(padding: EdgeInsets.zero),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child,
          const Padding(
            padding: EdgeInsets.all(16),
            child: DsSkeleton(width: 220, height: 8),
          ),
        ],
      ),
    ),
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('navigation $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            card(
              DsTabs<int>(
                value: 1,
                onChanged: (_) {},
                tabs: const [
                  DsTab(value: 0, label: Text('Genel')),
                  DsTab(value: 1, label: Text('Üyeler'), count: 12),
                  DsTab(value: 2, label: Text('Faturalar')),
                  DsTab(value: 3, label: Text('Güvenlik'), enabled: false),
                ],
              ),
            ),
            card(
              DsPaneHeader(
                title: DsBreadcrumb(
                  items: [
                    DsBreadcrumbItem(label: 'Derlio Web', onPressed: () {}),
                    const DsBreadcrumbItem(label: 'Ayarlar'),
                  ],
                ),
                actions: [
                  DsButton.icon(
                    icon: const DsIcon(DsIcons.share),
                    semanticLabel: 'Paylaş',
                    onPressed: () {},
                  ),
                  DsButton(
                    variant: DsButtonVariant.primary,
                    size: DsSize.sm,
                    onPressed: () {},
                    child: const Text('Yayınla'),
                  ),
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
                DsToolbarToggle(
                  icon: const DsIcon(DsIcons.underline),
                  semanticLabel: 'Altı çizili',
                  selected: false,
                  onChanged: (_) {},
                ),
                const DsToolbarDivider(),
                DsButton.icon(
                  icon: const DsIcon(DsIcons.link),
                  semanticLabel: 'Bağlantı',
                  onPressed: () {},
                ),
                const DsToolbarDivider(),
                DsButton(
                  variant: DsButtonVariant.primary,
                  size: DsSize.sm,
                  onPressed: () {},
                  child: const Text('Gönder'),
                ),
              ],
            ),
            DsPagination(page: 1, pageCount: 12, onChanged: (_) {}),
            DsPagination(page: 6, pageCount: 12, onChanged: (_) {}),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/structure_navigation_$mode.png');
    });

    testWidgets('content $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  const DsAccordion(
                    initialValue: {0},
                    items: [
                      DsAccordionItem(
                        value: 0,
                        title: Text('Hesap nasıl silinir?'),
                        child: Text(
                          'Ayarlar → Güvenlik bölümünden hesabınızı '
                          'silebilirsiniz.',
                        ),
                      ),
                      DsAccordionItem(
                        value: 1,
                        title: Text('Faturamı nereden indiririm?'),
                        child: Text('Faturalar sekmesinde.'),
                      ),
                    ],
                  ),
                  DsListSection(
                    header: const Text('TERCİHLER'),
                    children: [
                      DsListRow(
                        leading: const DsIcon(DsIcons.bell),
                        title: const Text('Bildirimler'),
                        detail: const Text('Açık'),
                        showChevron: true,
                        onPressed: () {},
                      ),
                      DsListRow(
                        leading: const DsIcon(DsIcons.globe),
                        title: const Text('Dil'),
                        detail: const Text('Türkçe'),
                        showChevron: true,
                        onPressed: () {},
                      ),
                      DsListRow(
                        leading: const DsIcon(DsIcons.logOut),
                        title: const Text('Oturumu kapat'),
                        destructive: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  DsCard(
                    style: const DsCardStyle(padding: EdgeInsets.zero),
                    child: DsEmptyState(
                      icon: const DsIcon(DsIcons.inbox),
                      title: const Text('Henüz görev yok'),
                      description: const Text(
                        'İlk görevi ekleyin ya da hazır bir şablonla başlayın.',
                      ),
                      actions: [
                        DsButton(
                          variant: DsButtonVariant.primary,
                          size: DsSize.sm,
                          onPressed: () {},
                          child: const Text('Görev ekle'),
                        ),
                        DsButton(
                          variant: DsButtonVariant.ghost,
                          size: DsSize.sm,
                          onPressed: () {},
                          child: const Text('Şablonlar'),
                        ),
                      ],
                    ),
                  ),
                  DsCard(
                    child: Row(
                      children: [
                        const Expanded(child: Text('Misafir')),
                        DsStepper(value: 0, max: 12, onChanged: (_) {}),
                      ],
                    ),
                  ),
                  DsCard(
                    child: Row(
                      children: [
                        const Expanded(child: Text('Oda')),
                        DsStepper(value: 3, max: 12, onChanged: (_) {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/structure_content_$mode.png');
    });

    testWidgets('shell $mode', (tester) async {
      const items = [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Ana sayfa'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Gelen'),
        ),
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Takvim'),
        ),
        DsBottomNavItem(
          value: 3,
          icon: DsIcon(DsIcons.user),
          label: Text('Profil'),
        ),
      ];
      await pumpGolden(
        tester,
        theme: theme,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            SizedBox(
              height: 340,
              child: DsSidebar(
                children: [
                  DsSidebarItem(
                    leading: const DsIcon(DsIcons.inbox),
                    label: const Text('Gelen kutusu'),
                    count: 4,
                    selected: true,
                    onPressed: () {},
                  ),
                  DsSidebarItem(
                    leading: const DsIcon(DsIcons.sun),
                    label: const Text('Bugün'),
                    onPressed: () {},
                  ),
                  DsSidebarItem(
                    leading: const DsIcon(DsIcons.folder),
                    label: const Text('Projeler'),
                    onPressed: () {},
                  ),
                  const DsSidebarSection(label: Text('EKİPLER')),
                  DsSidebarItem(
                    leading: const DsIcon(DsIcons.calendar),
                    label: const Text('Takvim'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                DsBottomNav(items: items, value: 1, onChanged: (_) {}),
                SizedBox(
                  width: 380,
                  child: DsBottomNav(
                    variant: DsBottomNavVariant.bar,
                    items: items,
                    value: 0,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/structure_shell_$mode.png');
    });
  }
}
