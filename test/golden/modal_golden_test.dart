@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the dialog, panel, toast and select, light and dark.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('modals $mode', (tester) async {
      final k = theme.colors;
      await pumpGolden(
        tester,
        theme: theme,
        size: const Size(1300, 900),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            // A dialog over its scrim, on page content.
            Container(
              width: 400,
              height: 330,
              decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: k.scrim)),
                  DsDialog(
                    alert: true,
                    destructive: true,
                    icon: const DsIcon(DsIcons.trash),
                    title: const Text('Projeyi sil?'),
                    description: const Text(
                      'Derlio Web ve 48 görev kalıcı olarak silinir. Bu işlem '
                      'geri alınamaz.',
                    ),
                    actions: [
                      DsButton(
                        variant: DsButtonVariant.secondary,
                        onPressed: () {},
                        child: const Text('Vazgeç'),
                      ),
                      DsButton(
                        variant: DsButtonVariant.danger,
                        onPressed: () {},
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              height: 330,
              child: DecoratedBox(
                decoration: DsBoxDecoration(
                  color: k.overlay,
                  borderRadius: BorderRadius.circular(theme.radii.card),
                  shadows: theme.shadows.overlay,
                ),
                child: DsPanel(
                  title: const Text('Ayrıntılar'),
                  footer: DsButton(
                    variant: DsButtonVariant.primary,
                    onPressed: () {},
                    child: const Text('Kaydet'),
                  ),
                  child: const Text(
                    'Sprint 14 · 18 / 25 görev. Teslim cuma günü.',
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 420,
              child: Column(
                spacing: 16,
                children: [
                  for (final (status, title, action) in [
                    (DsStatus.success, 'Değişiklikler kaydedildi', 'Geri al'),
                    (DsStatus.warning, 'Bağlantı yavaş', null),
                    (DsStatus.danger, 'Yükleme başarısız', 'Tekrar dene'),
                    (null, 'Bağlantı kopyalandı', null),
                  ])
                    DsToast(
                      title: title,
                      description: 'Derlio Web · az önce',
                      status: status,
                      actionLabel: action,
                      onAction: () {},
                      onDismiss: () {},
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/modals_$mode.png');
    });

    testWidgets('select $mode', (tester) async {
      const options = [
        DsSelectOption(
          value: 'web',
          label: 'Derlio Web',
          leading: DsIcon(DsIcons.folder),
        ),
        DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
        DsSelectOption(value: 'marketing', label: 'Pazarlama sitesi'),
        DsSelectOption(
          value: 'archive',
          label: 'Arşiv',
          detail: 'salt okunur',
          enabled: false,
        ),
      ];
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 560,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  spacing: 12,
                  children: [
                    DsSelect<String>(
                      value: null,
                      onChanged: (_) {},
                      options: options,
                    ),
                    DsSelect<String>(
                      value: 'web',
                      onChanged: (_) {},
                      options: options,
                    ),
                    DsSelect<String>(
                      value: 'mobile',
                      error: true,
                      onChanged: (_) {},
                      options: options,
                    ),
                    const DsSelect<String>(
                      value: 'mobile',
                      onChanged: null,
                      options: options,
                    ),
                  ],
                ),
              ),
              // The open menu, as the select builds it.
              SizedBox(
                width: 260,
                child: DsMenu(
                  children: [
                    for (final o in options)
                      DsMenuItem(
                        label: Text(o.label),
                        // The select keeps an icon column
                        // after the menu's check column.
                        leading: o.leading ?? const SizedBox(width: 16),
                        checked: o.value == 'web',
                        onPressed: o.enabled ? () {} : null,
                        trailing: o.detail == null
                            ? null
                            : Text(
                                o.detail!,
                                style: theme.typography.caption.copyWith(
                                  color: theme.colors.textSubtle,
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
      await expectGolden(tester, 'goldens/select_$mode.png');
    });
  }
}
