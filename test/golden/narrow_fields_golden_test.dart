@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Fields too narrow for their buttons. Each row is one field at
/// 64, 96, 120, 160 and 240px: the extras give way in order (clear, error
/// icon, unit, picker and step buttons, show password) and the text keeps
/// about three characters; light and dark.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('narrow fields $mode', (tester) async {
      final rows = <String, Widget Function()>{
        'password · clear · error': () => const DsTextField(
          initialValue: 'hunter2',
          obscureText: true,
          revealable: true,
          clearable: true,
          error: true,
        ),
        'text · unit · clear': () => const DsTextField(
          initialValue: '1250',
          clearable: true,
          leading: DsIcon(DsIcons.search),
          trailing: Text('unit'),
        ),
        'number · prefix · unit': () => DsNumberField(
          value: 12,
          prefix: r'$',
          unit: 'kg',
          onChanged: (_) {},
        ),
        'date · error': () => DsDatePicker(
          value: DateTime(2026, 10, 14),
          error: true,
          onChanged: (_) {},
        ),
        'time': () =>
            DsTimePicker(value: const DsTime(9, 30), onChanged: (_) {}),
      };
      await pumpGolden(
        tester,
        theme: theme,
        DsLocalizationScope(
          localizations: const DsLocalizationsEn(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              for (final MapEntry(key: label, value: build) in rows.entries)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      label,
                      style: theme.typography.caption.copyWith(
                        color: theme.colors.textSubtle,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        for (final width in [64.0, 96.0, 120.0, 160.0, 240.0])
                          SizedBox(width: width, child: build()),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/narrow_fields_$mode.png');
    });
  }
}
