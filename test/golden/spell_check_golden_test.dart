@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Spell check in DsTextField on iOS and Android, light and dark: the
/// misspelled underline (dotted on iOS, wavy on Android) in a field at
/// rest, and a multi-line field with the suggestions toolbar open over a
/// tapped word (on iOS the word is selected on the danger tint).
void main() {
  const misspellings = {
    'Ths': ['This', 'The', 'Thus'],
    'speling': ['spelling', 'spieling', 'sapling'],
    'mistke': ['mistake'],
    'Helo': ['Hello', 'Help', 'Hero'],
    'wrold': ['world'],
  };

  /// Says the platform has a spell checker and answers it with
  /// [misspellings], as the platform would.
  void fakeSpellChecker(WidgetTester tester) {
    tester.platformDispatcher.nativeSpellCheckServiceDefinedTestValue = true;
    addTearDown(tester.platformDispatcher.clearNativeSpellCheckServiceDefined);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.spellCheck,
      (call) async {
        final text = (call.arguments as List)[1] as String;
        return [
          for (final m in RegExp(r'\w+').allMatches(text))
            if (misspellings[m[0]] case final suggestions?)
              {
                'startIndex': m.start,
                'endIndex': m.end,
                'suggestions': suggestions,
              },
        ];
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.spellCheck,
        null,
      ),
    );
  }

  for (final (name, platform) in [
    ('ios', TargetPlatform.iOS),
    ('android', TargetPlatform.android),
  ]) {
    for (final brightness in Brightness.values) {
      final mode = brightness.name;
      testWidgets('spell check $name $mode', (tester) async {
        fakeSpellChecker(tester);
        final theme = DsThemeData(
          seed: DsSeed.blue,
          brightness: brightness,
          platform: platform,
          // Tests have no San Francisco: the bundled face stands in on iOS.
          typography: DsTypography(family: 'SchibstedGrotesk'),
        );
        const note = Key('note'), title = Key('title');
        await pumpGolden(
          tester,
          theme: theme,
          Localizations(
            // The checker is asked in the app's locale.
            locale: const Locale('en'),
            delegates: const [DefaultWidgetsLocalizations.delegate],
            child: SizedBox(
              width: 420,
              height: 250,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => const Padding(
                      // Room above the note for its toolbar, which
                      // centers on the word and must stay inside this
                      // overlay (an app's overlay fills the window).
                      padding: EdgeInsets.only(left: 40, top: 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [
                          SizedBox(
                            width: 340,
                            child: DsTextField.multiline(
                              key: note,
                              minLines: 2,
                            ),
                          ),
                          SizedBox(width: 340, child: DsTextField(key: title)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.enterText(find.byKey(title), 'Helo wrold, a title');
        await tester.enterText(
          find.byKey(note),
          'Ths note has a speling mistke in it.',
        );
        await tester.pump();
        // Tap the middle of "speling" (offsets 13 to 20).
        final render = tester
            .state<EditableTextState>(
              find.descendant(
                of: find.byKey(note),
                matching: find.byType(EditableText),
              ),
            )
            .renderEditable;
        final at = render.localToGlobal(
          render.getLocalRectForCaret(const TextPosition(offset: 16)).center,
        );
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(DsSpellCheckSuggestionsToolbar), findsOneWidget);
        await expectGolden(tester, 'goldens/spell_check_${name}_$mode.png');
        // Leave no keyboard connection behind.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
      }, variant: TargetPlatformVariant.only(platform));
    }
  }
}
