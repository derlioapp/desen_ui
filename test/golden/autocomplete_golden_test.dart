@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsAutocomplete and DsMultiSelect (concept card
/// 27), light and dark (K-24): closed with a value, tags that wrap, error
/// and disabled; the open popup with the typed letters in bold and the
/// keyboard-active row (hover fill + inset ring, K-54); "No results";
/// free text offered as "Use “Ardahan”";
/// and the tags at both contrasts: neutral, the arrow keys' active one in
/// the accent, disabled ones filled in the disabled colors; collapsed tags
/// with their "+N" (editable, read-only, disabled; S-40).
void main() {
  DsSelectOption<String> person(String id, String name, String role) =>
      DsSelectOption(
        value: id,
        label: name,
        detail: role,
        leading: DsAvatar(
          initials: name.split(' ').map((w) => w[0]).join(),
          size: DsSize.xs,
          toneIndex: DsAvatar.toneFor(id),
        ),
      );
  final people = [
    person('ayse', 'Ayşe Kaya', 'Ürün'),
    person('mehmet', 'Mehmet Demir', 'Tasarım'),
    person('melis', 'Melis Arslan', 'Ürün'),
    person('meryem', 'Meryem Öz', 'Geliştirme'),
    person('isil', 'Işıl Şahin', 'Pazarlama'),
    person('ilker', 'İlker Yıldız', 'Destek'),
  ];
  const cities = [
    DsSelectOption(value: 'ist', label: 'İstanbul'),
    DsSelectOption(value: 'izm', label: 'İzmir'),
    DsSelectOption(value: 'esk', label: 'Eskişehir'),
  ];

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  void releaseKeyboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      null,
    );
  }

  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('autocomplete $mode', (tester) async {
      Widget cell(Widget child) => SizedBox(width: 300, child: child);
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 660,
          height: 470,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 28,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 20,
                      children: [
                        cell(
                          DsField(
                            label: const Text('Şehir'),
                            child: DsAutocomplete<String>(
                              value: 'ist',
                              onChanged: (_) {},
                              options: cities,
                            ),
                          ),
                        ),
                        cell(
                          DsField(
                            label: const Text('Ekip'),
                            child: DsMultiSelect<String>(
                              value: const ['ayse', 'mehmet', 'melis', 'isil'],
                              onChanged: (_) {},
                              options: people,
                            ),
                          ),
                        ),
                        cell(
                          DsField(
                            label: const Text('Şehir'),
                            errorText: 'Bir şehir seçin.',
                            child: DsAutocomplete<String>(
                              value: null,
                              onChanged: (_) {},
                              options: cities,
                              placeholder: 'Şehir ara',
                            ),
                          ),
                        ),
                        cell(
                          DsField(
                            label: const Text('Gözlemciler'),
                            child: DsMultiSelect<String>(
                              value: const ['ilker'],
                              onChanged: null,
                              options: people,
                            ),
                          ),
                        ),
                      ],
                    ),
                    cell(
                      DsField(
                        label: const Text('Atanan kişiler'),
                        child: DsMultiSelect<String>(
                          key: const ValueKey('open'),
                          value: const ['ayse'],
                          onChanged: (_) {},
                          options: people,
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
      final open = find.descendant(
        of: find.byKey(const ValueKey('open')),
        matching: find.byType(EditableText),
      );
      await tester.showKeyboard(open);
      await tester.enterText(open, 'Me');
      await settle(tester);
      // From the first match to the second: the keyboard's row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      await expectGolden(tester, 'goldens/autocomplete_$mode.png');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      releaseKeyboard(tester);
    });

    testWidgets('autocomplete tags $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 316,
          height: 160,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    spacing: 12,
                    children: [
                      DsMultiSelect<String>(
                        key: const ValueKey('active'),
                        value: const ['ayse', 'mehmet', 'isil'],
                        onChanged: (_) {},
                        options: people,
                        semanticLabel: 'Ekip',
                      ),
                      DsMultiSelect<String>(
                        value: const ['ilker', 'meryem'],
                        onChanged: null,
                        options: people,
                        semanticLabel: 'Gözlemciler',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final text = find.descendant(
        of: find.byKey(const ValueKey('active')),
        matching: find.byType(EditableText),
      );
      await tester.showKeyboard(text);
      await settle(tester);
      // Left twice from the empty text: the middle tag is active.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      await expectGolden(tester, 'goldens/autocomplete_tags_$mode.png');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      releaseKeyboard(tester);
    });

    testWidgets('autocomplete collapsed $mode', (tester) async {
      final everyone = [for (final p in people) p.value];
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 316,
          height: 250,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    spacing: 12,
                    children: [
                      DsField(
                        label: const Text('Ekip'),
                        child: DsMultiSelect<String>(
                          value: everyone,
                          onChanged: (_) {},
                          options: people,
                          collapseTags: true,
                        ),
                      ),
                      DsField(
                        label: const Text('İzleyenler'),
                        child: DsMultiSelect<String>(
                          value: everyone.take(4).toList(),
                          onChanged: (_) {},
                          readOnly: true,
                          options: people,
                          collapseTags: true,
                        ),
                      ),
                      DsField(
                        label: const Text('Gözlemciler'),
                        child: DsMultiSelect<String>(
                          value: everyone.skip(2).toList(),
                          onChanged: null,
                          options: people,
                          collapseTags: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      await expectGolden(tester, 'goldens/autocomplete_collapsed_$mode.png');
    });

    testWidgets('autocomplete no results $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 316,
          height: 130,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DsAutocomplete<String>(
                      value: null,
                      onChanged: (_) {},
                      options: cities,
                      semanticLabel: 'Şehir',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ardahan');
      await settle(tester);
      await expectGolden(tester, 'goldens/autocomplete_empty_$mode.png');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      releaseKeyboard(tester);
    });

    testWidgets('autocomplete free text $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        SizedBox(
          width: 316,
          height: 130,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DsAutocomplete<String>(
                      value: null,
                      onChanged: (_) {},
                      onCreate: (_) {},
                      options: cities,
                      semanticLabel: 'Şehir',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ardahan');
      await settle(tester);
      await expectGolden(tester, 'goldens/autocomplete_custom_$mode.png');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      releaseKeyboard(tester);
    });
  }
}
