import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spell check in DsTextField: when it is on by default, the misspelled
/// underline, and the suggestions toolbar (replace, delete, close,
/// keyboard and screen readers).
///
/// Widget tests have no platform spell checker. These tests say the
/// platform has one (`nativeSpellCheckServiceDefinedTestValue`) and answer
/// the checker's channel themselves, so the field runs Flutter's own
/// `DefaultSpellCheckService`, as on a phone.
void main() {
  /// The fake checker's dictionary: misspelled word to its suggestions.
  const misspellings = {
    'helo': ['hello', 'help', 'hero', 'halo'],
    'wrold': ['world'],
    'xyzzy': <String>[],
  };

  /// Answers `SpellCheck.initiateSpellCheck` as the platform does: the
  /// range and suggestions of every misspelled word in the text.
  void fakeSpellChecker(WidgetTester tester, {bool available = true}) {
    tester.platformDispatcher.nativeSpellCheckServiceDefinedTestValue =
        available;
    addTearDown(tester.platformDispatcher.clearNativeSpellCheckServiceDefined);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.spellCheck,
      (call) async {
        if (call.method != 'SpellCheck.initiateSpellCheck') return null;
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

  Widget app(Widget child, {Locale? locale}) => DsApp(
    theme: DsThemeData(),
    themeMode: DsThemeMode.light,
    locale: locale,
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  EditableTextState editable(WidgetTester tester) =>
      tester.state<EditableTextState>(find.byType(EditableText));

  Offset textOffset(WidgetTester tester, int offset) {
    final render = editable(tester).renderEditable;
    final caret = render.getLocalRectForCaret(TextPosition(offset: offset));
    return render.localToGlobal(caret.center);
  }

  /// Types [text] as the keyboard does, which is what Flutter checks.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(DsTextField), text);
    await tester.pumpAndSettle();
  }

  Finder toolbar() => find.byType(DsSpellCheckSuggestionsToolbar);

  /// The style of the text span holding [word] in the field.
  TextStyle? styleOf(WidgetTester tester, String word) {
    TextStyle? found;
    editable(tester).renderEditable.text!.visitChildren((span) {
      if (span is TextSpan && span.text == word) found = span.style;
      return found == null;
    });
    return found;
  }

  group('defaults', () {
    Future<bool> enabled(WidgetTester tester, Widget field) async {
      await tester.pumpWidget(app(field));
      return editable(tester).spellCheckEnabled;
    }

    testWidgets(
      'on for prose on iOS and Android, off for literal text and searches',
      (tester) async {
        fakeSpellChecker(tester);
        expect(await enabled(tester, const DsTextField()), isTrue);
        expect(await enabled(tester, const DsTextField.multiline()), isTrue);
        expect(
          await enabled(
            tester,
            const DsTextField(keyboardType: TextInputType.text),
          ),
          isTrue,
        );
        for (final off in [
          const DsTextField(keyboardType: TextInputType.emailAddress),
          const DsTextField(keyboardType: TextInputType.url),
          const DsTextField(keyboardType: TextInputType.visiblePassword),
          const DsTextField(keyboardType: TextInputType.number),
          const DsTextField(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const DsTextField(keyboardType: TextInputType.phone),
          const DsTextField(keyboardType: TextInputType.datetime),
          const DsTextField(keyboardType: TextInputType.name),
          const DsTextField(obscureText: true),
          const DsTextField(autofillHints: [AutofillHints.email]),
          const DsTextField(autofillHints: [AutofillHints.username]),
          const DsTextField(autocorrect: false),
          const DsTextField.multiline(autocorrect: false),
          const DsTextField(spellCheck: false),
          const DsSearchField(),
        ]) {
          expect(await enabled(tester, off), isFalse, reason: '$off');
        }
        // An explicit true wins over what the field holds, except for a
        // password, which Flutter never checks.
        expect(
          await enabled(
            tester,
            const DsTextField(
              keyboardType: TextInputType.emailAddress,
              spellCheck: true,
            ),
          ),
          isTrue,
        );
        expect(
          await enabled(
            tester,
            const DsTextField(obscureText: true, spellCheck: true),
          ),
          isFalse,
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets(
      'off on desktop unless asked for',
      (tester) async {
        fakeSpellChecker(tester);
        expect(await enabled(tester, const DsTextField()), isFalse);
        expect(await enabled(tester, const DsTextField.multiline()), isFalse);
        expect(
          await enabled(tester, const DsTextField(spellCheck: true)),
          isTrue,
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }),
    );

    testWidgets(
      'off without a platform service, even when asked for, and quietly',
      (tester) async {
        fakeSpellChecker(tester, available: false);
        expect(await enabled(tester, const DsTextField()), isFalse);
        expect(
          await enabled(tester, const DsTextField(spellCheck: true)),
          isFalse,
        );
        // Flutter reports an error for spell check without a service; the
        // field never asks for it then.
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets('off outside Localizations, where it has no locale', (
      tester,
    ) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(),
            child: Center(child: SizedBox(width: 300, child: DsTextField())),
          ),
        ),
      );
      expect(editable(tester).spellCheckEnabled, isFalse);
      await tester.enterText(find.byType(DsTextField), 'helo');
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('form fields pass it on', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(
        app(Form(child: DsTextFormField.multiline(spellCheck: false))),
      );
      expect(editable(tester).spellCheckEnabled, isFalse);
      await tester.pumpWidget(app(Form(child: DsTextFormField())));
      expect(editable(tester).spellCheckEnabled, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('an autocomplete does not check its query', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(
        app(
          DsAutocomplete<String>(
            value: null,
            onChanged: (_) {},
            options: const [
              DsSelectOption(value: 'ada', label: 'Ada'),
              DsSelectOption(value: 'grace', label: 'Grace'),
            ],
          ),
        ),
      );
      expect(editable(tester).spellCheckEnabled, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('underline', () {
    testWidgets('a wavy danger underline on Android', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo wrold ok');
      final signal = DsThemeData().colors.danger.signal;
      for (final word in ['helo', 'wrold']) {
        final style = styleOf(tester, word)!;
        expect(style.decoration, TextDecoration.underline, reason: word);
        expect(style.decorationStyle, TextDecorationStyle.wavy);
        expect(style.decorationColor, signal);
      }
      // Correct words keep the plain text style.
      expect(styleOf(tester, ' ')?.decoration, isNot(TextDecoration.underline));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a dotted danger underline on iOS', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo wrold ok');
      final style = styleOf(tester, 'helo')!;
      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationStyle, TextDecorationStyle.dotted);
      expect(style.decorationColor, DsThemeData().colors.danger.signal);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the style customizes it', (tester) async {
      fakeSpellChecker(tester);
      const color = Color(0xFF7A00FF);
      await tester.pumpWidget(
        app(
          const DsTextField(
            style: DsTextFieldStyle(
              misspelledStyle: TextStyle(
                decorationColor: color,
                decorationStyle: TextDecorationStyle.solid,
              ),
            ),
          ),
        ),
      );
      await type(tester, 'helo');
      final style = styleOf(tester, 'helo')!;
      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationColor, color);
      expect(style.decorationStyle, TextDecorationStyle.solid);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('no underline where spell check is off', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField(spellCheck: false)));
      await type(tester, 'helo wrold');
      expect(styleOf(tester, 'helo'), isNull);
      expect(editable(tester).renderEditable.text!.toPlainText(), 'helo wrold');
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('suggestions toolbar', () {
    testWidgets(
      'Android: a tap on a misspelled word offers three suggestions and '
      'Delete; one replaces the word',
      (tester) async {
        fakeSpellChecker(tester);
        final changes = <String>[];
        await tester.pumpWidget(app(DsTextField(onChanged: changes.add)));
        await type(tester, 'helo wrold ok');
        await tester.tapAt(textOffset(tester, 2));
        await tester.pumpAndSettle();
        expect(toolbar(), findsOneWidget);
        for (final label in ['hello', 'help', 'hero', 'Delete']) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        // At most three suggestions, as on the platforms.
        expect(find.text('halo'), findsNothing);
        await tester.tap(find.text('help'));
        await tester.pumpAndSettle();
        final value = editable(tester).textEditingValue;
        expect(value.text, 'help wrold ok');
        expect(value.selection, const TextSelection.collapsed(offset: 4));
        expect(changes.last, 'help wrold ok');
        expect(toolbar(), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('Android: Delete removes the word', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'ok wrold');
      await tester.tapAt(textOffset(tester, 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(editable(tester).textEditingValue.text, 'ok ');
      expect(toolbar(), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets(
      'iOS: a tap selects the word, on the danger tint, and offers its '
      'suggestions',
      (tester) async {
        fakeSpellChecker(tester);
        await tester.pumpWidget(app(const DsTextField()));
        await type(tester, 'helo wrold ok');
        await tester.tapAt(textOffset(tester, 7));
        await tester.pumpAndSettle();
        final s = editable(tester).textEditingValue.selection;
        expect((s.start, s.end), (5, 10));
        expect(toolbar(), findsOneWidget);
        expect(find.text('world'), findsOneWidget);
        // No Delete on iOS.
        expect(find.text('Delete'), findsNothing);
        final render = editable(tester).renderEditable;
        expect(render.selectionColor, DsThemeData().colors.danger.tintPress);
        await tester.tap(find.text('world'));
        await tester.pumpAndSettle();
        final value = editable(tester).textEditingValue;
        expect(value.text, 'helo world ok');
        expect(value.selection, const TextSelection.collapsed(offset: 10));
        expect(toolbar(), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('iOS: a word without suggestions says so, disabled', (
      tester,
    ) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'ok xyzzy');
      await tester.tapAt(textOffset(tester, 5));
      await tester.pumpAndSettle();
      expect(find.text('No replacements found'), findsOneWidget);
      final pressable = tester.widget<DsPressable>(
        find.ancestor(
          of: find.text('No replacements found'),
          matching: find.byType(DsPressable),
        ),
      );
      expect(pressable.onPressed, isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a tap on a correct word shows no suggestions', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo ok');
      await tester.tapAt(textOffset(tester, 6));
      await tester.pumpAndSettle();
      expect(toolbar(), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a tap outside the field and the toolbar closes it', (
      tester,
    ) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo ok');
      await tester.tapAt(textOffset(tester, 2));
      await tester.pumpAndSettle();
      expect(toolbar(), findsOneWidget);
      await tester.tapAt(const Offset(4, 590));
      await tester.pumpAndSettle();
      expect(toolbar(), findsNothing);
      expect(editable(tester).textEditingValue.text, 'helo ok');
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('Escape closes it from the field', (tester) async {
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo ok');
      await tester.tapAt(textOffset(tester, 2));
      await tester.pumpAndSettle();
      expect(toolbar(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(toolbar(), findsNothing);
      expect(editable(tester).widget.focusNode.hasPrimaryFocus, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets(
      'keyboard: a focused suggestion keeps the toolbar open; Enter picks '
      'it, Escape closes, and focus returns to the field',
      (tester) async {
        fakeSpellChecker(tester);
        await tester.pumpWidget(app(const DsTextField()));
        await type(tester, 'helo ok');
        final fieldNode = editable(tester).widget.focusNode;

        Future<void> open() async {
          await tester.tapAt(textOffset(tester, 2));
          await tester.pumpAndSettle();
          expect(toolbar(), findsOneWidget);
        }

        FocusNode nodeOf(String label) =>
            Focus.of(tester.element(find.text(label)));

        await open();
        nodeOf('hello').requestFocus();
        await tester.pumpAndSettle();
        expect(nodeOf('hello').hasPrimaryFocus, isTrue);
        // The field still counts as focused, so the toolbar stays.
        expect(fieldNode.hasFocus, isTrue);
        expect(toolbar(), findsOneWidget);
        // Tab moves on to the next suggestion.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(nodeOf('help').hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(toolbar(), findsNothing);
        expect(fieldNode.hasPrimaryFocus, isTrue);
        expect(editable(tester).textEditingValue.text, 'helo ok');

        await open();
        nodeOf('hero').requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(editable(tester).textEditingValue.text, 'hero ok');
        expect(toolbar(), findsNothing);
        expect(fieldNode.hasPrimaryFocus, isTrue);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('screen readers hear a named toolbar of buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      fakeSpellChecker(tester);
      await tester.pumpWidget(app(const DsTextField()));
      await type(tester, 'helo ok');
      await tester.tapAt(textOffset(tester, 2));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Spelling suggestions'), findsOneWidget);
      for (final label in ['hello', 'help', 'hero', 'Delete']) {
        expect(
          tester.getSemantics(find.text(label)),
          isSemantics(
            label: label,
            isButton: true,
            isFocusable: true,
            hasTapAction: true,
          ),
          reason: label,
        );
      }
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('its words are localized', (tester) async {
      final semantics = tester.ensureSemantics();
      fakeSpellChecker(tester);
      await tester.pumpWidget(
        app(const DsTextField(), locale: const Locale('tr')),
      );
      await type(tester, 'helo ok');
      await tester.tapAt(textOffset(tester, 2));
      await tester.pumpAndSettle();
      expect(find.text('Sil'), findsOneWidget);
      expect(find.bySemanticsLabel('Yazım önerileri'), findsOneWidget);
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
