import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// DsFormField and the typed form fields: Flutter's Form validates, saves
/// and resets them; the error flows into DsField (K-67, WCAG 3.3.1).
/// No DsApp or DsScope anywhere (R3): a MediaQuery, a Directionality and
/// an Overlay for the popups.
void main() {
  const en = DsLocalizationsEn();
  const options = [
    DsSelectOption(value: 'web', label: 'Web'),
    DsSelectOption(value: 'mobile', label: 'Mobile'),
  ];

  /// A form in an overlay, with announcements supported.
  Widget app(
    Widget child, {
    GlobalKey<FormState>? form,
    AutovalidateMode? mode,
    TextDirection direction = TextDirection.ltr,
  }) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQueryData.fromView(View.of(context))
          .copyWith(supportsAnnounce: true),
      child: Directionality(
        textDirection: direction,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 420,
                  child: Form(
                    key: form,
                    autovalidateMode: mode ?? AutovalidateMode.disabled,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Finder editable(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<EditableText>(editable(key)).controller.text;

  Finder message(String text) => find.textContaining(text);

  group('text', () {
    testWidgets('validate, save and reset', (tester) async {
      final form = GlobalKey<FormState>();
      const name = Key('name');
      String? saved;
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => DsTextFormField(
              key: name,
              label: const Text('Name'),
              initialValue: 'Ada',
              required: true,
              validator: DsValidators.required(context),
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      expect(textOf(tester, name), 'Ada');
      await tester.enterText(editable(name), '   ');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsOneWidget);

      await tester.enterText(editable(name), 'Grace');
      expect(form.currentState!.validate(), isTrue);
      await tester.pump();
      expect(message(en.fieldRequired), findsNothing);
      form.currentState!.save();
      expect(saved, 'Grace');

      form.currentState!.reset();
      await tester.pump();
      expect(textOf(tester, name), 'Ada');
      final state = tester.state<DsFormFieldState<String>>(find.byKey(name));
      expect(state.value, 'Ada');
      state.didChange('Linus');
      await tester.pump();
      expect(textOf(tester, name), 'Linus');
    });

    testWidgets('an external controller stays in step', (tester) async {
      final form = GlobalKey<FormState>();
      const name = Key('name');
      final controller = TextEditingController(text: 'start');
      addTearDown(controller.dispose);
      String? changed;
      await tester.pumpWidget(
        app(
          form: form,
          DsTextFormField(
            key: name,
            controller: controller,
            label: const Text('Name'),
            onChanged: (v) => changed = v,
          ),
        ),
      );
      final state = tester.state<DsFormFieldState<String>>(find.byKey(name));
      expect(state.value, 'start');
      // From the app's controller to the form.
      controller.text = 'from code';
      expect(state.value, 'from code');
      // From typing to the controller and the form.
      await tester.enterText(editable(name), 'typed');
      expect(controller.text, 'typed');
      expect(state.value, 'typed');
      expect(changed, 'typed');
      // From the form to the controller.
      state.didChange('set');
      expect(controller.text, 'set');
      // Reset goes back to the controller's text when the field was made.
      form.currentState!.reset();
      await tester.pump();
      expect(controller.text, 'start');
      expect(state.value, 'start');
    });

    testWidgets('disabled follows enabled', (tester) async {
      const name = Key('name');
      await tester.pumpWidget(
        app(DsTextFormField(key: name, label: const Text('N'), enabled: false)),
      );
      expect(
        tester.widget<DsTextField>(find.byType(DsTextField)).enabled,
        isFalse,
      );
    });
  });

  group('typed text that is not a value', () {
    testWidgets('number: fails with the built-in message, saves null', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      const amount = Key('amount');
      num? saved = -1;
      await tester.pumpWidget(
        app(
          form: form,
          DsNumberFormField(
            key: amount,
            label: const Text('Amount'),
            initialValue: 5,
            max: 10,
            onSaved: (v) => saved = v,
          ),
        ),
      );
      await tester.enterText(editable(amount), '-');
      // Focus is still in the field: validate commits the text first.
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.invalidNumber), findsOneWidget);
      form.currentState!.save();
      expect(saved, isNull);

      // A number over the maximum is an issue at once.
      await tester.enterText(editable(amount), '12');
      await tester.pump();
      expect(message(en.numberTooLarge('10')), findsOneWidget);
      // Committing keeps it in range, as Enter or leaving the field does.
      expect(form.currentState!.validate(), isTrue);
      expect(textOf(tester, amount), '10');

      await tester.enterText(editable(amount), '7');
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, 7);
    });

    testWidgets("the app's validator message wins", (tester) async {
      final form = GlobalKey<FormState>();
      const amount = Key('amount');
      await tester.pumpWidget(
        app(
          form: form,
          DsNumberFormField(
            key: amount,
            label: const Text('Amount'),
            validator: (v) => v == null ? 'Give an amount.' : null,
          ),
        ),
      );
      await tester.enterText(editable(amount), '-');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message('Give an amount.'), findsOneWidget);
      expect(message(en.invalidNumber), findsNothing);
    });

    testWidgets('required: typed text that is not a value keeps its own '
        'message; only empty text is "required"', (tester) async {
      final form = GlobalKey<FormState>();
      const day = Key('day'), time = Key('time'), amount = Key('amount');
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => Column(
              children: [
                DsDateFormField(
                  key: day,
                  label: const Text('Day'),
                  required: true,
                  validator: DsValidators.required(context),
                ),
                DsTimeFormField(
                  key: time,
                  label: const Text('Time'),
                  required: true,
                  validator: DsValidators.all([DsValidators.required(context)]),
                ),
                DsNumberFormField(
                  key: amount,
                  label: const Text('Amount'),
                  required: true,
                  validator: DsValidators.required(context),
                ),
              ],
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsNWidgets(3), reason: 'empty');

      await tester.enterText(editable(day), '2/30/2026');
      await tester.enterText(editable(time), '25:99');
      await tester.enterText(editable(amount), '-');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsNothing);
      expect(message('Enter a date as'), findsOneWidget);
      expect(message(en.invalidNumber), findsOneWidget);
      final timeState = tester.state<DsFormFieldState<DsTime>>(
        find.byKey(time),
      );
      expect(timeState.errorText, timeState.inputIssue!.message);

      // Emptied again: required speaks.
      await tester.enterText(editable(day), '');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsOneWidget);
    });

    testWidgets('required with autovalidate: the typed issue shows, not '
        '"required"', (tester) async {
      const day = Key('day');
      await tester.pumpWidget(
        app(
          mode: AutovalidateMode.always,
          Builder(
            builder: (context) => DsDateFormField(
              key: day,
              label: const Text('Day'),
              required: true,
              validator: DsValidators.required(context),
            ),
          ),
        ),
      );
      await tester.enterText(editable(day), '2/30/2026');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(message(en.fieldRequired), findsNothing);
      expect(message('Enter a date as'), findsOneWidget);
    });

    testWidgets('date: a half-typed edit never saves the stale value', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      const day = Key('day');
      DateTime? saved = DateTime(1999);
      await tester.pumpWidget(
        app(
          form: form,
          DsDateFormField(
            key: day,
            label: const Text('Day'),
            initialValue: DateTime(2026, 10, 5),
            onSaved: (v) => saved = v,
          ),
        ),
      );
      final state = tester.state<DsFormFieldState<DateTime>>(find.byKey(day));
      // No four-digit year yet: while typing the value is left as it was.
      await tester.enterText(editable(day), '13/4');
      expect(state.value, DateTime(2026, 10, 5));
      // Saving commits the text first: no 5 October.
      form.currentState!.save();
      expect(saved, isNull);
      expect(state.inputIssue?.kind, DsInputIssueKind.invalid);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message('Enter a date as'), findsOneWidget);

      // Reset shows the initial date again and drops the issue.
      form.currentState!.reset();
      await tester.pump();
      expect(state.value, DateTime(2026, 10, 5));
      expect(state.inputIssue, isNull);
      expect(textOf(tester, day), '10/5/2026');
      expect(message('Enter a date as'), findsNothing);
      await tester.pump();
      expect(state.inputIssue, isNull);
    });

    testWidgets('time: invalid text fails; reset clears it', (tester) async {
      final form = GlobalKey<FormState>();
      const time = Key('time');
      await tester.pumpWidget(
        app(
          form: form,
          DsTimeFormField(
            key: time,
            label: const Text('Time'),
            use24HourClock: true,
          ),
        ),
      );
      await tester.enterText(editable(time), '25:99');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message('Enter a time such as'), findsOneWidget);
      form.currentState!.reset();
      await tester.pump();
      expect(textOf(tester, time), '');
      expect(form.currentState!.validate(), isTrue);
    });

    testWidgets('date range: validate, save, reset', (tester) async {
      final form = GlobalKey<FormState>();
      const range = Key('range');
      DsDateRange? saved;
      final initial = DsDateRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      );
      await tester.pumpWidget(
        app(
          form: form,
          DsDateRangeFormField(
            key: range,
            label: const Text('Stay'),
            initialValue: initial,
            onSaved: (v) => saved = v,
          ),
        ),
      );
      await tester.enterText(editable(range), 'nope');
      expect(form.currentState!.validate(), isFalse);
      form.currentState!.reset();
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, initial);
    });
  });

  group('value fields', () {
    testWidgets('select: required, save, reset', (tester) async {
      final form = GlobalKey<FormState>();
      const project = Key('project');
      String? saved;
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => DsSelectFormField<String>(
              key: project,
              label: const Text('Project'),
              required: true,
              options: options,
              validator: DsValidators.required(context),
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsOneWidget);
      // The control takes the error look from the field.
      expect(
        DsFieldScope.maybeOf(tester.element(find.byType(DsSelect<String>))),
        isA<DsFieldScope>().having((s) => s.hasError, 'hasError', isTrue),
      );

      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile').last);
      await tester.pumpAndSettle();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, 'mobile');
      form.currentState!.reset();
      await tester.pump();
      expect(
        tester.state<DsFormFieldState<String>>(find.byKey(project)).value,
        isNull,
      );
    });

    testWidgets('autocomplete and multi-select', (tester) async {
      final form = GlobalKey<FormState>();
      const one = Key('one'), many = Key('many');
      String? savedOne;
      List<String>? savedMany;
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => Column(
              children: [
                DsAutocompleteFormField<String>(
                  key: one,
                  label: const Text('One'),
                  options: options,
                  validator: DsValidators.required(context),
                  onSaved: (v) => savedOne = v,
                ),
                DsMultiSelectFormField<String>(
                  key: many,
                  label: const Text('Many'),
                  options: options,
                  initialValue: const ['web'],
                  validator: DsValidators.required(context),
                  onSaved: (v) => savedMany = v,
                ),
              ],
            ),
          ),
        ),
      );
      final invalid = form.currentState!.validateGranularly();
      expect(invalid.map((f) => f.widget.key), [one]);
      tester.state<DsFormFieldState<String>>(find.byKey(one)).didChange('web');
      tester
          .state<DsFormFieldState<List<String>>>(find.byKey(many))
          .didChange(const []);
      await tester.pump();
      expect(form.currentState!.validateGranularly().map((f) => f.widget.key), [
        many,
      ]);
      form.currentState!.reset();
      await tester.pump();
      form.currentState!.save();
      expect(savedOne, isNull);
      expect(savedMany, ['web']);
    });

    testWidgets('checkbox: required mark after its label, must be checked', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      bool? saved;
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => DsCheckboxFormField(
              label: const Text('I accept the terms'),
              required: true,
              validator: DsValidators.required(context),
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      expect(find.text('*'), findsOneWidget);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message(en.fieldRequired), findsOneWidget);
      await tester.tap(find.text('I accept the terms'));
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, isTrue);
      form.currentState!.reset();
      await tester.pump();
      expect(tester.widget<DsCheckbox>(find.byType(DsCheckbox)).value, isFalse);
    });

    testWidgets('switch and radio group', (tester) async {
      final form = GlobalKey<FormState>();
      bool? news;
      String? plan;
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => Column(
              children: [
                DsSwitchFormField(
                  label: const Text('News'),
                  onSaved: (v) => news = v,
                ),
                DsRadioGroupFormField<String>(
                  label: const Text('Plan'),
                  required: true,
                  validator: DsValidators.required(context),
                  onSaved: (v) => plan = v,
                  child: const Column(
                    children: [
                      DsRadio(value: 'free', label: Text('Free')),
                      DsRadio(value: 'pro', label: Text('Pro')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.tap(find.text('News'));
      await tester.tap(find.text('Pro'));
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect((news, plan), (true, 'pro'));
      form.currentState!.reset();
      await tester.pump();
      form.currentState!.save();
      expect((news, plan), (false, null));
    });

    testWidgets('a generic DsFormField wraps any control', (tester) async {
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          form: form,
          DsFormField<double>(
            label: const Text('Volume'),
            initialValue: 0.2,
            validator: (v) => v! < 0.5 ? 'Turn it up.' : null,
            builder: (field) =>
                DsSlider(value: field.value!, onChanged: field.didChange),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(message('Turn it up.'), findsOneWidget);
    });
  });

  group('autovalidate', () {
    Widget field({AutovalidateMode? mode}) => Builder(
      builder: (context) => DsTextFormField(
        key: const Key('f'),
        label: const Text('Code'),
        autovalidateMode: mode,
        validator: DsValidators.minLength(context, 3),
      ),
    );

    testWidgets('disabled: only validate shows the error', (tester) async {
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(app(form: form, field()));
      await tester.enterText(editable(const Key('f')), 'ab');
      await tester.pump();
      expect(message(en.textTooShort(3)), findsNothing);
      form.currentState!.validate();
      await tester.pump();
      expect(message(en.textTooShort(3)), findsOneWidget);
    });

    testWidgets('onUserInteraction: after a change, not before', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(field(mode: AutovalidateMode.onUserInteraction)),
      );
      expect(message(en.textTooShort(3)), findsNothing);
      await tester.enterText(editable(const Key('f')), 'ab');
      await tester.pump();
      expect(message(en.textTooShort(3)), findsOneWidget);
      await tester.enterText(editable(const Key('f')), 'abc');
      await tester.pump();
      expect(message(en.textTooShort(3)), findsNothing);
    });

    testWidgets('always (on the form): from the first frame', (tester) async {
      await tester.pumpWidget(
        app(
          mode: AutovalidateMode.always,
          Builder(
            builder: (context) => DsTextFormField(
              label: const Text('Code'),
              validator: DsValidators.required(context),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(message(en.fieldRequired), findsOneWidget);
    });
  });

  group('focus', () {
    testWidgets('validateAndFocus focuses the first invalid field', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      final nodes = List.generate(3, (_) => FocusNode());
      for (final n in nodes) {
        addTearDown(n.dispose);
      }
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => Column(
              children: [
                DsTextFormField(
                  label: const Text('A'),
                  initialValue: 'ok',
                  focusNode: nodes[0],
                  validator: DsValidators.required(context),
                ),
                DsTextFormField(
                  label: const Text('B'),
                  focusNode: nodes[1],
                  validator: DsValidators.required(context),
                ),
                DsTextFormField(
                  label: const Text('C'),
                  focusNode: nodes[2],
                  validator: DsValidators.required(context),
                ),
              ],
            ),
          ),
        ),
      );
      expect(form.currentState!.validateAndFocus(), isFalse);
      await tester.pump();
      expect([for (final n in nodes) n.hasFocus], [false, true, false]);
    });

    testWidgets('reading order in RTL starts on the right', (tester) async {
      final form = GlobalKey<FormState>();
      final first = FocusNode(), second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        app(
          form: form,
          direction: TextDirection.rtl,
          Builder(
            builder: (context) => Row(
              children: [
                for (final n in [first, second])
                  Expanded(
                    child: DsTextFormField(
                      label: const Text('X'),
                      focusNode: n,
                      validator: DsValidators.required(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      form.currentState!.validateAndFocus();
      await tester.pump();
      final focused = first.hasFocus ? first : second;
      final other = focused == first ? second : first;
      expect(
        tester
            .getCenter(
              find.byWidgetPredicate(
                (w) => w is EditableText && w.focusNode == focused,
              ),
            )
            .dx,
        greaterThan(
          tester
              .getCenter(
                find.byWidgetPredicate(
                  (w) => w is EditableText && w.focusNode == other,
                ),
              )
              .dx,
        ),
      );
      // The error and the required mark mirror too.
      expect(message(en.fieldRequired), findsNWidgets(2));
    });

    testWidgets('a checkbox takes focus and the field scrolls into view', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final box = FocusNode();
      addTearDown(box.dispose);
      await tester.pumpWidget(
        app(
          form: form,
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: scroll,
              child: Builder(
                builder: (context) => Column(
                  children: [
                    DsCheckboxFormField(
                      label: const Text('Terms'),
                      focusNode: box,
                      validator: DsValidators.required(context),
                    ),
                    const SizedBox(height: 1000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      scroll.jumpTo(600);
      await tester.pump();
      form.currentState!.validateAndFocus();
      await tester.pump();
      expect(box.hasFocus, isTrue);
      expect(scroll.offset, 0);
    });

    testWidgets('an invalid field kept alive off screen in a lazy list '
        'takes focus without an error (bugs H2)', (tester) async {
      final form = GlobalKey<FormState>();
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final first = FocusNode(), last = FocusNode();
      addTearDown(first.dispose);
      addTearDown(last.dispose);
      bool? valid;
      await tester.pumpWidget(
        app(
          form: form,
          SizedBox(
            height: 400,
            child: Builder(
              builder: (context) => ListView(
                controller: scroll,
                children: [
                  DsTextFormField(
                    label: const Text('First'),
                    focusNode: first,
                    validator: DsValidators.required(context),
                  ),
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 80, child: Text('Filler $i')),
                  DsTextFormField(
                    label: const Text('Last'),
                    focusNode: last,
                    validator: DsValidators.required(context),
                  ),
                  GestureDetector(
                    onTap: () => valid = form.currentState!.validateAndFocus(),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Focus keeps the first field's item alive while the list scrolls to
      // the end (its paint transform is zeroed, its position NaN).
      first.requestFocus();
      await tester.pump();
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(valid, isFalse);
      expect(first.hasFocus, isTrue, reason: 'the first in reading order');
      expect(last.hasFocus, isFalse);
      expect(scroll.offset, 0, reason: 'scrolled back to it');
    });
  });

  group('restoration', () {
    testWidgets('text and value fields come back', (tester) async {
      await tester.pumpWidget(
        RootRestorationScope(
          restorationId: 'root',
          child: app(
            Column(
              children: [
                DsTextFormField(
                  key: const Key('name'),
                  label: const Text('Name'),
                  restorationId: 'name',
                ),
                DsNumberFormField(
                  key: const Key('count'),
                  label: const Text('Count'),
                  restorationId: 'count',
                ),
                DsDateFormField(
                  key: const Key('day'),
                  label: const Text('Day'),
                  restorationId: 'day',
                ),
                DsSwitchFormField(
                  key: const Key('on'),
                  label: const Text('On'),
                  restorationId: 'on',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(editable(const Key('name')), 'Ayşe');
      await tester.enterText(editable(const Key('count')), '42');
      await tester.enterText(editable(const Key('day')), '10/05/2026');
      await tester.tap(find.text('On'));
      await tester.pump();

      await tester.restartAndRestore();
      expect(textOf(tester, const Key('name')), 'Ayşe');
      expect(
        tester
            .state<DsFormFieldState<String>>(find.byKey(const Key('name')))
            .value,
        'Ayşe',
      );
      expect(
        tester
            .state<DsFormFieldState<num>>(find.byKey(const Key('count')))
            .value,
        42,
      );
      expect(textOf(tester, const Key('count')), '42');
      expect(
        tester
            .state<DsFormFieldState<DateTime>>(find.byKey(const Key('day')))
            .value,
        DateTime(2026, 10, 5),
      );
      expect(tester.widget<DsSwitch>(find.byType(DsSwitch)).value, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('the error is part of the node, which is invalid', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => DsTextFormField(
              key: const Key('name'),
              label: const Text('Name'),
              required: true,
              validator: DsValidators.required(context),
            ),
          ),
        ),
      );
      var data = tester
          .getSemantics(editable(const Key('name')))
          .getSemanticsData();
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, isNot(SemanticsValidationResult.invalid));

      form.currentState!.validate();
      await tester.pumpAndSettle();
      data = tester
          .getSemantics(editable(const Key('name')))
          .getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect('${data.label}\n${data.hint}', contains(en.fieldRequired));
      handle.dispose();
    });

    testWidgets('a form validation is announced once, by the form', (
      tester,
    ) async {
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          form: form,
          Builder(
            builder: (context) => Column(
              children: [
                DsTextFormField(
                  label: const Text('A'),
                  validator: (_) => 'First.',
                ),
                DsTextFormField(
                  label: const Text('B'),
                  validator: (_) => 'Second.',
                ),
              ],
            ),
          ),
        ),
      );
      tester.takeAnnouncements();
      form.currentState!.validate();
      await tester.pumpAndSettle();
      final said = tester.takeAnnouncements();
      expect(said.map((a) => a.message), ['First.']);
    });

    testWidgets('a field validating on its own announces its error', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => DsTextFormField(
              key: const Key('f'),
              label: const Text('Code'),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: DsValidators.minLength(context, 3),
            ),
          ),
        ),
      );
      tester.takeAnnouncements();
      await tester.enterText(editable(const Key('f')), 'ab');
      await tester.pumpAndSettle();
      expect(tester.takeAnnouncements().map((a) => a.message), [
        '${en.error}\n${en.textTooShort(3)}',
      ]);
    });
  });

  group('validators', () {
    testWidgets('messages and rules', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      final required = DsValidators.required<Object>(context);
      for (final empty in <Object?>[
        null,
        '',
        '  ',
        <int>[],
        <int, int>{},
        false,
      ]) {
        expect(required(empty), en.fieldRequired, reason: '$empty');
      }
      for (final full in <Object?>[
        'a',
        0,
        true,
        const [1],
      ]) {
        expect(required(full), isNull, reason: '$full');
      }
      expect(DsValidators.required<String>(context, message: 'X')(''), 'X');

      final min = DsValidators.minLength(context, 2);
      expect(min(''), isNull, reason: 'empty is required()\'s job');
      expect(min('a'), en.textTooShort(2));
      // One grapheme cluster, many code units.
      expect(min('👍🏽'), en.textTooShort(2));
      expect(min('ab'), isNull);
      final max = DsValidators.maxLength(context, 2);
      expect(max('👍🏽👍🏽'), isNull);
      expect(max('abc'), en.textTooLong(2));

      final email = DsValidators.email(context);
      for (final ok in [
        '',
        'ada@example.com',
        ' ada.l@alan.com.tr ',
        'ö@ü.de',
      ]) {
        expect(email(ok), isNull, reason: ok);
      }
      for (final bad in [
        'ada',
        'ada@',
        'ada@example',
        'a b@c.d',
        'a@b..c',
        '@b.c',
      ]) {
        expect(email(bad), en.invalidEmail, reason: bad);
      }

      final both = DsValidators.all([
        DsValidators.required<String>(context),
        DsValidators.email(context),
      ]);
      expect(both(''), en.fieldRequired);
      expect(both('x'), en.invalidEmail);
      expect(both('x@y.z'), isNull);
    });

    testWidgets('messages follow the language', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        DsLocalizationScope(
          localizations: const DsLocalizationsTr(),
          child: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(DsValidators.required<String>(context)(''), 'Bu alan zorunludur.');
      expect(
        DsValidators.minLength(context, 8)('abc'),
        'En az 8 karakter girin.',
      );
      const ru = DsLocalizationsRu();
      expect(ru.textTooShort(1), 'Введите не меньше 1 символа.');
      expect(ru.textTooShort(5), 'Введите не меньше 5 символов.');
      expect(ru.textTooLong(21), 'Введите не больше 21 символа.');
      expect(en.textTooShort(1), 'Enter at least 1 character.');
    });
  });
}
