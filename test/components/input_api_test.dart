import 'dart:ui' show Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The normalized input API (API_SPEC rules 1, 2, 4, 5, 6): one way to
/// say value, disabled, read-only, error, focus and the screen reader name
/// on every input and selection control.
void main() {
  /// An app root with an overlay, for the controls with popups.
  Widget app(Widget child) => DsApp(
    theme: DsThemeData(),
    themeMode: DsThemeMode.light,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );

  const fruits = [
    DsSelectOption(value: 'apple', label: 'Apple'),
    DsSelectOption(value: 'banana', label: 'Banana'),
    DsSelectOption(value: 'cherry', label: 'Cherry'),
  ];
  group('DsChip', () {
    testWidgets('onChanged toggles; semanticLabel names it', (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsChip(
              label: const Text('UX'),
              semanticLabel: 'User experience',
              selected: on,
              onChanged: (v) => set(() => on = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsChip));
      await tester.pump();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(DsChip)),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          label: 'User experience',
        ),
      );
      semantics.dispose();
    });
  });

  group('DsToolbarToggle', () {
    testWidgets('takes a focusNode and autofocus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          DsToolbarToggle(
            icon: const DsIcon(DsIcons.bold),
            semanticLabel: 'Bold',
            selected: false,
            onChanged: (_) {},
            focusNode: node,
            autofocus: true,
          ),
        ),
      );
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });
  });

  group('DsRadio', () {
    testWidgets('semanticLabel replaces the label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsRadioGroup<int>(
            value: 1,
            onChanged: (_) {},
            child: const DsRadio(
              value: 1,
              label: Text('S'),
              semanticLabel: 'Small',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Small'), findsOneWidget);
      expect(find.bySemanticsLabel('S'), findsNothing);
      semantics.dispose();
    });

    testWidgets('a group error marks every radio invalid', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsRadioGroup<int>(
            value: null,
            onChanged: (_) {},
            error: true,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsRadio(value: 1, label: Text('One')),
                DsRadio(value: 2, label: Text('Two')),
              ],
            ),
          ),
        ),
      );
      for (final label in ['One', 'Two']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)).validationResult,
          SemanticsValidationResult.invalid,
        );
      }
      semantics.dispose();
    });

    testWidgets('enabled turns off one option only', (tester) async {
      int? chosen;
      await tester.pumpWidget(
        host(
          DsRadioGroup<int>(
            value: null,
            onChanged: (v) => chosen = v,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsRadio(value: 1, label: Text('One'), enabled: false),
                DsRadio(value: 2, label: Text('Two')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('One'));
      expect(chosen, isNull);
      await tester.tap(find.text('Two'));
      expect(chosen, 2);
    });
  });

  group('DsSwitch', () {
    testWidgets('error: invalid for screen readers, error outline', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Widget build({required bool error}) => host(
        DsSwitch(
          value: false,
          onChanged: (_) {},
          semanticLabel: 'Terms',
          error: error,
        ),
      );
      await tester.pumpWidget(build(error: false));
      expect(
        tester.getSemantics(find.byType(DsSwitch)).validationResult,
        SemanticsValidationResult.none,
      );
      await tester.pumpWidget(build(error: true));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byType(DsSwitch)).validationResult,
        SemanticsValidationResult.invalid,
      );
      final style = DsSwitch.defaultStyle(DsThemeData())
          .resolve({WidgetState.error});
      expect(style.trackShadows, isNotEmpty);
      semantics.dispose();
    });

    testWidgets('a DsField error marks the switch', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsField(
            errorText: 'Required',
            child: DsSwitch(
              value: false,
              onChanged: (_) {},
              semanticLabel: 'Terms',
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(DsSwitch)).validationResult,
        SemanticsValidationResult.invalid,
      );
      semantics.dispose();
    });
  });

  group('DsCalendar', () {
    final today = DateTime(2026, 10, 5);

    testWidgets('focusNode moves focus to the day the keyboard is on', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      DateTime? chosen;
      await tester.pumpWidget(
        host(
          DsCalendar(
            value: DateTime(2026, 10, 12),
            currentDate: today,
            onChanged: (d) => chosen = d,
            focusNode: node,
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(node.hasPrimaryFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, DateTime(2026, 10, 13));
    });

    testWidgets('semanticLabel names the calendar', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsCalendar(
            value: null,
            currentDate: today,
            onChanged: (_) {},
            semanticLabel: 'Check-in',
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('^Check-in, ')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('range: value and onChanged', (tester) async {
      DsDateRange? range;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsRangeCalendar(
              value: range,
              currentDate: today,
              onChanged: (r) => set(() => range = r),
            ),
          ),
        ),
      );
      await tester.tap(find.text('6'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      expect(range?.start, DateTime(2026, 10, 6));
      expect(range?.end, DateTime(2026, 10, 9));
    });
  });

  group('DsAutocomplete and DsMultiSelect', () {
    testWidgets('readOnly: focusable, shows the value, does not open', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var changes = 0;
      await tester.pumpWidget(
        app(
          DsAutocomplete<String>(
            value: 'banana',
            onChanged: (_) => changes++,
            options: fruits,
            semanticLabel: 'Fruit',
            readOnly: true,
            focusNode: node,
          ),
        ),
      );
      expect(find.text('Banana'), findsOneWidget);
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(find.text('Apple'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);
      await tester.enterText(find.byType(EditableText), 'Ch');
      await tester.pumpAndSettle();
      expect(find.text('Cherry'), findsNothing);
      expect(changes, 0);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.readOnly, isTrue);
    });

    testWidgets('DsMultiSelect takes value; readOnly drops tag removal', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Widget build({required bool readOnly}) => app(
        DsMultiSelect<String>(
          value: const ['apple', 'cherry'],
          onChanged: (_) {},
          options: fruits,
          semanticLabel: 'Fruits',
          readOnly: readOnly,
        ),
      );
      await tester.pumpWidget(build(readOnly: false));
      expect(find.bySemanticsLabel('Remove Apple'), findsOneWidget);
      await tester.pumpWidget(build(readOnly: true));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove Apple'), findsNothing);
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      semantics.dispose();
    });
  });

  group('DsSelect', () {
    Widget select({
      required String? value,
      required ValueChanged<String?>? onChanged,
      bool clearable = false,
      bool readOnly = false,
      FocusNode? focusNode,
    }) => app(
      DsSelect<String>(
        value: value,
        onChanged: onChanged,
        options: fruits,
        semanticLabel: 'Fruit',
        clearable: clearable,
        readOnly: readOnly,
        focusNode: focusNode,
      ),
    );

    testWidgets('clearable: the clear button reports null', (tester) async {
      String? value = 'apple';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => select(
            value: value,
            onChanged: (v) => set(() => value = v),
            clearable: true,
          ),
        ),
      );
      final clear = find.byWidgetPredicate(
        (w) => w is DsButton && w.semanticLabel == 'Clear',
      );
      expect(clear, findsOneWidget);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(value, isNull);
      // No menu opened by the tap on the button.
      expect(find.text('Banana'), findsNothing);
      expect(clear, findsNothing);
    });

    testWidgets('clearable: Delete clears; an unbounded trigger keeps its '
        'width', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      String? value = 'apple';
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, set) => DsSelect<String>(
                  value: value,
                  onChanged: (v) => set(() => value = v),
                  options: fruits,
                  semanticLabel: 'Fruit',
                  clearable: true,
                  focusNode: node,
                ),
              ),
            ],
          ),
        ),
      );
      final width = tester.getSize(find.byType(DsSelect<String>)).width;
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(value, isNull);
      expect(tester.getSize(find.byType(DsSelect<String>)).width, width);
    });

    testWidgets('clearable: screen readers get a Clear action', (tester) async {
      final semantics = tester.ensureSemantics();
      String? value = 'apple';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => select(
            value: value,
            onChanged: (v) => set(() => value = v),
            clearable: true,
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Fruit'));
      final actions = node.getSemanticsData().customSemanticsActionIds!;
      expect(actions, hasLength(1));
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.customAction,
        actions.single,
      );
      await tester.pumpAndSettle();
      expect(value, isNull);
      semantics.dispose();
    });

    testWidgets('readOnly: a Tab stop that does not open or change', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final node = FocusNode();
      addTearDown(node.dispose);
      var changes = 0;
      await tester.pumpWidget(
        select(
          value: 'banana',
          onChanged: (_) => changes++,
          readOnly: true,
          clearable: true,
          focusNode: node,
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is DsButton && w.semanticLabel == 'Clear',
        ),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isTrue);
      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);
      for (final key in [
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.delete,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }
      expect(find.text('Apple'), findsNothing);
      expect(changes, 0);
      final data = tester
          .getSemantics(find.bySemanticsLabel('Fruit'))
          .getSemanticsData();
      expect(data.flagsCollection.isReadOnly, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      semantics.dispose();
    });

    testWidgets('Ctrl+C copies the chosen label', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        select(
          value: 'cherry',
          onChanged: (_) {},
          readOnly: true,
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(copied, 'Cherry');
    });

    testWidgets('a null onChanged disables it', (tester) async {
      await tester.pumpWidget(select(value: 'apple', onChanged: null));
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
    });
  });

  group('read-only typed fields', () {
    Finder buttons(String label) => find.byWidgetPredicate(
      (w) => w is DsButton && w.semanticLabel == label,
    );

    EditableText editable(WidgetTester tester) =>
        tester.widget(find.byType(EditableText));

    testWidgets('DsDatePicker: focusable, fixed, no calendar', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var changes = 0;
      await tester.pumpWidget(
        app(
          DsDatePicker(
            value: DateTime(2026, 10, 5),
            onChanged: (_) => changes++,
            semanticLabel: 'Date',
            readOnly: true,
            focusNode: node,
          ),
        ),
      );
      // A read-only field drops its popup button (it edits the value).
      expect(buttons('Choose date'), findsNothing);
      expect(find.byType(DsButton), findsNothing);
      expect(editable(tester).readOnly, isTrue);
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DsCalendar), findsNothing);
      node.unfocus();
      await tester.pump();
      expect(changes, 0);
    });

    testWidgets('DsDateRangePicker: readOnly', (tester) async {
      await tester.pumpWidget(
        app(
          DsDateRangePicker(
            value: DsDateRange(
              start: DateTime(2026, 10, 5),
              end: DateTime(2026, 10, 9),
            ),
            onChanged: (_) {},
            semanticLabel: 'Stay',
            readOnly: true,
          ),
        ),
      );
      // A read-only field drops its popup button (it edits the value).
      expect(buttons('Choose date'), findsNothing);
      expect(find.byType(DsButton), findsNothing);
      expect(editable(tester).controller.text, '10/5/2026 – 10/9/2026');
      expect(editable(tester).readOnly, isTrue);
    });

    testWidgets('DsTimePicker: readOnly', (tester) async {
      await tester.pumpWidget(
        app(
          DsTimePicker(
            value: const DsTime(14, 30),
            onChanged: (_) {},
            semanticLabel: 'Time',
            readOnly: true,
          ),
        ),
      );
      // A read-only field drops its popup button (it edits the value).
      expect(buttons('Choose time'), findsNothing);
      expect(editable(tester).readOnly, isTrue);
    });

    testWidgets('DsSearchField: error and readOnly', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'kitten');
      addTearDown(controller.dispose);
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(
          DsSearchField(
            controller: controller,
            focusNode: node,
            error: true,
            readOnly: true,
          ),
        ),
      );
      expect(editable(tester).readOnly, isTrue);
      expect(
        find.byWidgetPredicate(
          (w) => w is DsButton && w.semanticLabel == 'Clear',
        ),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.byType(EditableText)).validationResult,
        SemanticsValidationResult.invalid,
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.text, 'kitten');
      semantics.dispose();
    });
  });
}
