import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a field's description and error are read: on the control's own
/// node (as its hint, after the name and the state), also when the
/// control keeps buttons of its own as separate nodes.
void main() {
  const cities = [
    DsSelectOption(value: 'ist', label: 'İstanbul'),
    DsSelectOption(value: 'ank', label: 'Ankara'),
  ];

  /// A root with an overlay; [announce] is whether the platform supports
  /// announcements (Android does not: errors are live regions there).
  /// Pumping another [child] updates the tree in place ([Overlay.wrap]
  /// rebuilds its entry; an [Overlay]'s initial entries would keep the
  /// first child).
  Widget app(Widget child, {bool announce = true}) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQueryData.fromView(View.of(context))
          .copyWith(supportsAnnounce: announce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay.wrap(
          child: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  );

  /// The text field's node as platforms see it (merged).
  SemanticsData input(WidgetTester tester) =>
      tester.getSemantics(find.byType(EditableText).first).getSemanticsData();

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is DsButton && w.semanticLabel == label);

  group('fields with buttons of their own', () {
    testWidgets('clearable: the error is the input\'s hint, buttons apart', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Name'),
            required: true,
            errorText: 'Enter your name.',
            child: DsTextField(initialValue: 'x', clearable: true),
          ),
        ),
      );
      await tester.pump();
      final data = input(tester);
      expect(data.label, 'Name');
      expect(data.hint, 'Error\nEnter your name.');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      // The clear button is still its own node.
      final clear = tester.getSemantics(button('Clear'));
      expect(
        clear,
        isNot(same(tester.getSemantics(find.byType(EditableText)))),
      );
      expect(clear.getSemanticsData().label, 'Clear');
      // The message is not read a second time after the button.
      expect(find.bySemanticsLabel(RegExp('Enter your name')), findsNothing);
      handle.dispose();
    });

    testWidgets('revealable: the description is the input\'s hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Password'),
            description: Text('At least 8 characters.'),
            child: DsTextField(obscureText: true, revealable: true),
          ),
        ),
      );
      await tester.pump();
      final data = input(tester);
      expect(data.label, 'Password');
      expect(data.hint, endsWith('At least 8 characters.'));
      expect(
        tester.getSemantics(button('Show password')).getSemanticsData().label,
        'Show password',
      );
      handle.dispose();
    });

    testWidgets('date picker: the error is on the input, not after the '
        'calendar button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('Birthday'),
            errorText: 'This field is required.',
            child: DsDatePicker(value: null, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump();
      final data = input(tester);
      expect(data.label, 'Birthday');
      expect(data.hint, endsWith('Error\nThis field is required.'));
      expect(
        find.bySemanticsLabel(RegExp('This field is required')),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('time picker: the description is on the input', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('Start'),
            description: const Text('Local time.'),
            child: DsTimePicker(value: null, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump();
      expect(input(tester).hint, endsWith('Local time.'));
      handle.dispose();
    });

    testWidgets('autocomplete and multi-select: the message is on the text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('City'),
            errorText: 'Pick a city.',
            child: DsAutocomplete<String>(
              value: 'ist',
              onChanged: (_) {},
              options: cities,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(input(tester).label, contains('City'));
      expect(input(tester).hint, endsWith('Error\nPick a city.'));
      expect(find.bySemanticsLabel(RegExp('Pick a city')), findsNothing);

      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('Cities'),
            description: const Text('Up to three.'),
            child: DsMultiSelect<String>(
              value: const ['ist'],
              onChanged: (_) {},
              options: cities,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(input(tester).label, contains('Cities'));
      expect(input(tester).hint, endsWith('Up to three.'));
      handle.dispose();
    });

    testWidgets('file upload: the error is the drop zone\'s hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('Attachments'),
            errorText: 'Add at least one file.',
            child: DsFileUpload(
              onBrowse: () {},
              files: [DsFileItem(name: 'a.pdf', size: 1000, onRemove: () {})],
            ),
          ),
        ),
      );
      await tester.pump();
      final zone = tester
          .getSemantics(find.byType(DsDashedBorder))
          .getSemanticsData();
      expect(zone.label, startsWith('Attachments'));
      expect(zone.hint, 'Error\nAdd at least one file.');
      expect(find.bySemanticsLabel(RegExp('Add at least one')), findsNothing);
      handle.dispose();
    });

    testWidgets('without announcements the error stays a live region too', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          announce: false,
          const DsField(
            label: Text('Name'),
            errorText: 'Enter your name.',
            child: DsTextField(initialValue: 'x', clearable: true),
          ),
        ),
      );
      await tester.pump();
      expect(input(tester).hint, 'Error\nEnter your name.');
      final message = tester
          .getSemantics(find.bySemanticsLabel(RegExp('Enter your name')))
          .getSemanticsData();
      expect(message.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('a description that is not a Text keeps its own node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Name'),
            description: Text.rich(TextSpan(text: 'Shown on your profile.')),
            child: DsTextField(clearable: true),
          ),
        ),
      );
      await tester.pump();
      // Text.rich is still a Text: read on the input.
      expect(input(tester).hint, endsWith('Shown on your profile.'));

      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Name'),
            description: Row(children: [Text('Shown on your profile.')]),
            child: DsTextField(clearable: true),
          ),
        ),
      );
      await tester.pump();
      expect(input(tester).hint, isNot(contains('Shown')));
      expect(
        find.bySemanticsLabel(RegExp('Shown on your profile')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('order: name, state, description, error', () {
    testWidgets('one-node field: the message is the hint, after the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Email'),
            required: true,
            description: Text('We never share it.'),
            child: DsTextField(placeholder: 'you@example.com'),
          ),
        ),
      );
      await tester.pump();
      final data = input(tester);
      expect(data.label, 'Email\nRequired');
      // The control's own hint first, then the field's description.
      expect(data.hint, 'you@example.com\nWe never share it.');
      handle.dispose();
    });

    testWidgets('checkbox, switch and radio descriptions are hints', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsCheckbox(
                value: true,
                onChanged: (_) {},
                label: const Text('All'),
                description: const Text('Select every row'),
              ),
              DsSwitch(
                value: true,
                onChanged: (_) {},
                label: const Text('Sync'),
                description: const Text('Over Wi-Fi only'),
              ),
              DsRadioGroup<int>(
                value: 1,
                onChanged: (_) {},
                child: const DsRadio(
                  value: 1,
                  label: Text('Express'),
                  description: Text('Next business day'),
                ),
              ),
            ],
          ),
        ),
      );
      for (final (label, description) in [
        ('All', 'Select every row'),
        ('Sync', 'Over Wi-Fi only'),
        ('Express', 'Next business day'),
      ]) {
        final data = tester.getSemantics(find.text(label)).getSemanticsData();
        expect(data.label, label);
        expect(data.hint, description);
      }
      handle.dispose();
    });

    testWidgets('a description alone still names the checkbox', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsCheckbox(
            value: false,
            onChanged: (_) {},
            description: const Text('Remember me'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Remember me')).getSemanticsData().label,
        'Remember me',
      );
      handle.dispose();
    });

    testWidgets('checkbox form field: its name first, the error last', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Form(
            key: form,
            child: Builder(
              builder: (context) => DsCheckboxFormField(
                label: const Text('Accept terms'),
                required: true,
                validator: DsValidators.required(context),
              ),
            ),
          ),
        ),
      );
      form.currentState!.validate();
      await tester.pumpAndSettle();
      final data = tester
          .getSemantics(find.byType(DsCheckbox))
          .getSemanticsData();
      expect(data.label, 'Accept terms\nRequired');
      expect(data.hint, 'Error\nThis field is required.');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      handle.dispose();
    });
  });
}
