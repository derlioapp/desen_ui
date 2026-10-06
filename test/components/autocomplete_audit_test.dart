import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The combobox's typed text, input methods and Escape
/// in a dialog (regression tests).
void main() {
  const cities = [
    DsSelectOption(value: 'ank', label: 'Ankara'),
    DsSelectOption(value: 'ant', label: 'Antalya'),
    DsSelectOption(value: 'ist', label: 'İstanbul'),
  ];

  Widget app(Widget child) => DsApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );

  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));

  group('an option typed out in full is that option', () {
    testWidgets('autocomplete with onCreate: Enter chooses it', (tester) async {
      final custom = <String>[];
      String? value;
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => DsAutocomplete<String>(
                value: value,
                onChanged: (v) => setState(() => value = v),
                options: cities,
                onCreate: custom.add,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ankara');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(custom, isEmpty);
      expect(value, 'ank');
      expect(editable(tester).controller.text, 'Ankara');
    });

    testWidgets('autocomplete with onCreate: other text is still custom', (
      tester,
    ) async {
      final custom = <String>[];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: DsAutocomplete<String>(
              value: null,
              onChanged: (_) {},
              options: cities,
              onCreate: custom.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ankar');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(custom, ['Ankar']);
    });

    for (final how in ['Enter', 'leaving']) {
      testWidgets('multi-select with onCreate: $how adds the option', (
        tester,
      ) async {
        final custom = <String>[];
        var values = <String>[];
        await tester.pumpWidget(
          app(
            Column(
              children: [
                SizedBox(
                  width: 300,
                  child: StatefulBuilder(
                    builder: (context, setState) => DsMultiSelect<String>(
                      value: values,
                      onChanged: (v) => setState(() => values = v),
                      options: cities,
                      onCreate: custom.add,
                    ),
                  ),
                ),
                DsButton(onPressed: () {}, child: const Text('next')),
              ],
            ),
          ),
        );
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Ankara');
        await tester.pumpAndSettle();
        if (how == 'Enter') {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await tester.pumpAndSettle();
        expect(custom, isEmpty, reason: 'not reported as free text');
        expect(values, ['ank']);
        expect(editable(tester).controller.text, '');
      });
    }

    testWidgets('multi-select: an option already in is not removed', (
      tester,
    ) async {
      var values = <String>['ank'];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => DsMultiSelect<String>(
                value: values,
                onChanged: (v) => setState(() => values = v),
                options: cities,
                onCreate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ankara');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(values, ['ank']);
    });
  });

  group('input method composing', () {
    const kana = [
      DsSelectOption(value: 'kan', label: 'かんじ'),
      DsSelectOption(value: 'kat', label: 'かたかな'),
    ];

    void compose(WidgetTester tester, String text) =>
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
            composing: TextRange(start: 0, end: text.length),
          ),
        );

    testWidgets('arrows and Enter belong to the input method', (tester) async {
      final chosen = <String?>[];
      final custom = <String>[];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: DsAutocomplete<String>(
              value: null,
              onChanged: chosen.add,
              options: kana,
              onCreate: custom.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      compose(tester, 'かん');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      expect(custom, isEmpty);
      // Composition done: the keys are the combobox's again.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'かんじ',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, ['kan']);
    });

    testWidgets('multi-select: Backspace while composing keeps the tags', (
      tester,
    ) async {
      var values = <String>['kan'];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => DsMultiSelect<String>(
                value: values,
                onChanged: (v) => setState(() => values = v),
                options: kana,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      compose(tester, 'ㅎ');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(values, ['kan']);
    });
  });

  group('Escape in a dialog', () {
    Future<void> openDialog(
      WidgetTester tester,
      Widget Function(StateSetter setState) field,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(
        showDsDialog<void>(
          context: ctx,
          builder: (_) => DsDialog(
            title: const Text('Edit'),
            description: StatefulBuilder(
              builder: (c, setState) =>
                  SizedBox(width: 260, child: field(setState)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a chosen value survives: the first Escape closes the '
        'dialog', (tester) async {
      String? value = 'ank';
      await openDialog(
        tester,
        (setState) => DsField(
          label: const Text('City'),
          child: DsAutocomplete<String>(
            autofocus: true,
            value: value,
            onChanged: (v) => setState(() => value = v),
            options: cities,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(value, 'ank');
      expect(find.byType(DsDialog), findsNothing);
    });

    testWidgets('typed text: Escape closes the list, reverts, then closes '
        'the dialog', (tester) async {
      String? value;
      await openDialog(
        tester,
        (setState) => DsAutocomplete<String>(
          autofocus: true,
          value: value,
          onChanged: (v) => setState(() => value = v),
          options: cities,
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Ank');
      await tester.pumpAndSettle();
      expect(find.text('Antalya'), findsNothing, reason: 'filtered');
      expect(find.text('Ankara'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape); // the list
      await tester.pumpAndSettle();
      expect(find.text('Ankara'), findsNothing, reason: 'list closed');
      expect(find.text('Edit'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape); // the text
      await tester.pumpAndSettle();
      expect(editable(tester).controller.text, '');
      expect(find.text('Edit'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape); // the dialog
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
    });
  });
}
