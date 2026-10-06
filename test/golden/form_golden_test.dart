@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for a validated form in its error state (DsFormField
/// and the typed form fields): validator messages, a typed number's own
/// message, a required checkbox with its mark, and a valid field with its
/// description, light and dark.
void main() {
  Widget form(GlobalKey<FormState> key) => DsLocalizationScope(
    localizations: const DsLocalizationsTr(),
    child: SizedBox(
      width: 360,
      child: Form(
        key: key,
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              DsTextFormField(
                label: const Text('Ad soyad'),
                required: true,
                validator: DsValidators.required(context),
              ),
              DsTextFormField(
                key: const Key('email'),
                label: const Text('E-posta'),
                initialValue: 'ayse@',
                validator: DsValidators.email(context),
              ),
              DsNumberFormField(
                key: const Key('count'),
                label: const Text('Kişi sayısı'),
                initialValue: 2,
              ),
              DsSelectFormField<String>(
                label: const Text('Proje'),
                required: true,
                options: const [
                  DsSelectOption(value: 'web', label: 'Derlio Web'),
                  DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
                ],
                validator: DsValidators.required(context),
              ),
              DsDateFormField(
                label: const Text('Başlangıç'),
                description: const Text('Proje bu tarihte açılır.'),
                initialValue: DateTime(2026, 10, 5),
              ),
              DsCheckboxFormField(
                label: const Text('Şartları kabul ediyorum'),
                required: true,
                validator: DsValidators.required(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('form errors $mode', (tester) async {
      final key = GlobalKey<FormState>();
      await pumpGolden(tester, form(key), theme: theme);
      // A number field holding text that is not a number.
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('count')),
          matching: find.byType(EditableText),
        ),
        '-',
      );
      key.currentState!.validate();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectGolden(tester, 'goldens/form_errors_$mode.png');
    });
  }
}
