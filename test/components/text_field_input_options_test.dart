import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The text field passes the platform's input options through: autocorrect
/// and suggestions (off by default for text that must stay exactly as
/// typed), capitalization, alignment and onEditingComplete.
void main() {
  Widget host(Widget child) => DsScope(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );

  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));

  group('autocorrect and suggestions', () {
    testWidgets('on for ordinary text', (tester) async {
      await tester.pumpWidget(host(const DsTextField()));
      expect(editable(tester).autocorrect, isTrue);
      expect(editable(tester).enableSuggestions, isTrue);
      expect(editable(tester).smartDashesType, SmartDashesType.enabled);
    });

    for (final type in [
      TextInputType.emailAddress,
      TextInputType.url,
      TextInputType.visiblePassword,
    ]) {
      testWidgets('off for the ${type.toJson()['name']} keyboard', (
        tester,
      ) async {
        await tester.pumpWidget(host(DsTextField(keyboardType: type)));
        expect(editable(tester).autocorrect, isFalse);
        expect(editable(tester).enableSuggestions, isFalse);
        expect(editable(tester).smartDashesType, SmartDashesType.disabled);
        expect(editable(tester).smartQuotesType, SmartQuotesType.disabled);
      });
    }

    testWidgets('off for a password', (tester) async {
      await tester.pumpWidget(host(const DsTextField(obscureText: true)));
      expect(editable(tester).autocorrect, isFalse);
      expect(editable(tester).enableSuggestions, isFalse);
    });

    testWidgets('off for an email autofill hint without a keyboard type', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const DsTextField(autofillHints: [AutofillHints.email])),
      );
      expect(editable(tester).autocorrect, isFalse);
      expect(editable(tester).enableSuggestions, isFalse);
    });

    testWidgets('an explicit value wins either way', (tester) async {
      await tester.pumpWidget(
        host(
          const DsTextField(
            keyboardType: TextInputType.emailAddress,
            autocorrect: true,
            enableSuggestions: true,
          ),
        ),
      );
      expect(editable(tester).autocorrect, isTrue);
      expect(editable(tester).enableSuggestions, isTrue);
      await tester.pumpWidget(
        host(const DsTextField(autocorrect: false, enableSuggestions: false)),
      );
      expect(editable(tester).autocorrect, isFalse);
      expect(editable(tester).enableSuggestions, isFalse);
    });

    testWidgets('the multi-line field takes them too', (tester) async {
      await tester.pumpWidget(
        host(
          const DsTextField.multiline(
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.sentences,
            textAlign: TextAlign.center,
          ),
        ),
      );
      expect(editable(tester).autocorrect, isFalse);
      expect(editable(tester).enableSuggestions, isFalse);
      expect(editable(tester).textCapitalization, TextCapitalization.sentences);
      expect(editable(tester).textAlign, TextAlign.center);
    });
  });

  testWidgets('capitalization and alignment reach the editor and the '
      'placeholder', (tester) async {
    await tester.pumpWidget(
      host(
        const DsTextField(
          textCapitalization: TextCapitalization.words,
          textAlign: TextAlign.end,
          placeholder: '0,00',
        ),
      ),
    );
    expect(editable(tester).textCapitalization, TextCapitalization.words);
    expect(editable(tester).textAlign, TextAlign.end);
    expect(tester.widget<Text>(find.text('0,00')).textAlign, TextAlign.end);
  });

  testWidgets('onEditingComplete replaces moving focus on Next', (
    tester,
  ) async {
    var completed = 0;
    String? submitted;
    final second = FocusNode();
    addTearDown(second.dispose);
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsTextField(
              autofocus: true,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => completed++,
              onSubmitted: (v) => submitted = v,
            ),
            DsTextField(focusNode: second),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, 'Ada');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(completed, 1);
    expect(submitted, 'Ada');
    // The callback took over: focus did not move on by itself.
    expect(second.hasFocus, isFalse);
  });

  testWidgets('without onEditingComplete, Next still moves focus', (
    tester,
  ) async {
    final second = FocusNode();
    addTearDown(second.dispose);
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DsTextField(
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            DsTextField(focusNode: second),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(second.hasFocus, isTrue);
  });

  testWidgets('DsTextFormField passes the options through', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      host(
        Form(
          child: DsTextFormField(
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            textAlign: TextAlign.end,
            onEditingComplete: () => completed++,
            autofocus: true,
          ),
        ),
      ),
    );
    expect(editable(tester).autocorrect, isFalse);
    expect(editable(tester).enableSuggestions, isFalse);
    expect(editable(tester).textAlign, TextAlign.end);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(completed, 1);
    await tester.pumpWidget(
      host(
        Form(
          child: DsTextFormField.multiline(
            autocorrect: false,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
    );
    expect(editable(tester).autocorrect, isFalse);
    expect(editable(tester).textCapitalization, TextCapitalization.sentences);
  });
}
