@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsTextField: rest,
/// hover, focused with a selection, filled, error, read-only, disabled and a
/// multi-line field, light and dark. The second golden holds
/// part 2: slots, clear, password, counters (normal and over the limit),
/// the text area and the search field.
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('text field $mode', (tester) async {
      final focused = TextEditingController(text: 'Derlio brave world');
      final focus = FocusNode();
      addTearDown(focused.dispose);
      addTearDown(focus.dispose);
      const width = 260.0;
      Widget cell(String label, Widget field) => Column(
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
          SizedBox(width: width, child: field),
        ],
      );
      await pumpGolden(
        tester,
        Wrap(
          spacing: 32,
          runSpacing: 24,
          children: [
            cell('rest', const DsTextField(placeholder: 'ad@ornek.com')),
            cell(
              'hover',
              const DsTextField(
                key: ValueKey('hover'),
                placeholder: 'ad@ornek.com',
              ),
            ),
            cell(
              'focused + selection',
              DsTextField(controller: focused, focusNode: focus),
            ),
            cell('filled', const DsTextField(initialValue: 'Emre Candan')),
            cell(
              'error',
              const DsField(
                errorText: 'Geçerli bir adres girin.',
                child: DsTextField(initialValue: 'emre@'),
              ),
            ),
            cell(
              'read-only',
              const DsTextField(initialValue: 'Salt okunur', readOnly: true),
            ),
            cell(
              'disabled',
              const DsTextField(initialValue: 'Devre dışı', enabled: false),
            ),
            cell(
              'disabled, empty',
              const DsTextField(placeholder: 'Pasif', enabled: false),
            ),
            cell(
              'multi-line',
              const DsTextField.multiline(
                maxLines: 4,
                minLines: 3,
                initialValue:
                    'Toplantı notları:\n- Tasarım gözden geçirildi\n'
                    '- Sonraki adım: metin alanı',
              ),
            ),
          ],
        ),
        theme: theme,
      );
      focus.requestFocus();
      await tester.pump();
      focused.selection = const TextSelection(baseOffset: 7, extentOffset: 12);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('hover'))));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectGolden(tester, 'goldens/text_field_$mode.png');
      // Leave no keyboard connection behind.
      focus.unfocus();
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      );
    });
  }

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('text field parts $mode', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      const width = 300.0;
      Widget cell(String label, Widget field) => Column(
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
          SizedBox(width: width, child: field),
        ],
      );
      await pumpGolden(
        tester,
        Wrap(
          spacing: 32,
          runSpacing: 24,
          children: [
            cell(
              'leading, focused',
              DsTextField(
                focusNode: focus,
                initialValue: 'deniz@derlio.app',
                leading: const DsIcon(DsIcons.mail),
              ),
            ),
            cell(
              'clear + unit',
              const DsTextField(
                initialValue: '72',
                trailing: Text('kg'),
                clearable: true,
              ),
            ),
            cell(
              'password, reveal',
              const DsTextField(
                initialValue: 'hunter22',
                obscureText: true,
                revealable: true,
              ),
            ),
            cell(
              'password in field, error',
              const DsField(
                label: Text('Şifre'),
                errorText: 'En az 8 karakter olmalı.',
                child: DsTextField(
                  initialValue: 'abcde',
                  obscureText: true,
                  revealable: true,
                ),
              ),
            ),
            cell(
              'counter in field',
              const DsField(
                label: Text('Kullanıcı adı'),
                description: Text('Profilinizde görünür.'),
                child: DsTextField(initialValue: 'deniz', maxLength: 20),
              ),
            ),
            cell(
              'counter over (soft limit)',
              const DsTextField(
                initialValue: 'Toplantı notları ve sonraki adımlar',
                maxLength: 24,
                maxLengthEnforcement: MaxLengthEnforcement.none,
              ),
            ),
            cell(
              'text area',
              const DsField(
                label: Text('Açıklama'),
                description: Text('Markdown desteklenir'),
                child: DsTextField.multiline(
                  maxLength: 280,
                  initialValue:
                      'Yeni onboarding akışı için ekran taslakları. '
                      'Haftaya Perşembe incelemeye hazır olmalı',
                ),
              ),
            ),
            cell(
              'search, empty',
              const DsSearchField(
                placeholder: 'Görev, kişi veya dosya ara',
                shortcut: '⌘K',
              ),
            ),
            cell(
              'search, filled',
              const DsSearchField(initialValue: 'fatura şablonu'),
            ),
            cell(
              'search, disabled',
              const DsSearchField(placeholder: 'Ara', enabled: false),
            ),
          ],
        ),
        theme: theme,
      );
      focus.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectGolden(tester, 'goldens/text_field_parts_$mode.png');
      focus.unfocus();
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      );
    });
  }
}
