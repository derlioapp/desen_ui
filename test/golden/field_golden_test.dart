@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsField: label, required mark, description and
/// error around a select, a checkbox group and a radio group, light and
/// dark.
void main() {
  const options = [
    DsSelectOption(value: 'web', label: 'Derlio Web'),
    DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
  ];

  Widget fields() => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 32,
    children: [
      SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            DsField(
              label: const Text('Proje'),
              description: const Text('Raporlar bu projeye bağlanır.'),
              required: true,
              child: DsSelect<String>(
                value: 'web',
                onChanged: (_) {},
                options: options,
              ),
            ),
            DsField(
              label: const Text('Ülke'),
              errorText: 'Zorunlu alan',
              required: true,
              child: DsSelect<String>(
                value: null,
                error: true,
                onChanged: (_) {},
                options: options,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            DsField(
              group: true,
              label: const Text('Bildirimler'),
              errorText: 'En az birini seçin.',
              required: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  for (final l in ['Bahsedilince', 'Görev atandığında'])
                    DsCheckbox(
                      value: false,
                      error: true,
                      onChanged: (_) {},
                      label: Text(l),
                    ),
                ],
              ),
            ),
            DsField(
              group: true,
              label: const Text('Görünürlük'),
              description: const Text('Sonradan değiştirebilirsiniz.'),
              child: DsRadioGroup<String>(
                value: 'team',
                onChanged: (_) {},
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    DsRadio(value: 'team', label: Text('Yalnızca ekip')),
                    DsRadio(value: 'all', label: Text('Herkes')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('fields $mode', (tester) async {
      await pumpGolden(tester, fields(), theme: theme);
      await expectGolden(tester, 'goldens/field_$mode.png');
    });
  }
}
