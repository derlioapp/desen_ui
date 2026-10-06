import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import '../../snippets.g.dart';

/// Flutter's Form with Desen's form fields and validators.
class FormsPage extends StatelessWidget {
  const FormsPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Forms',
    lead:
        'Desen\'s form fields plug into Flutter\'s own `Form`: it validates, '
        'saves and resets them, and each field shows its result in a '
        '[field](/components/field) frame. Use them when several inputs are '
        'checked and sent together; a single setting that saves on change '
        'needs no form.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          const DocText(
            'A sign-up form. Press **Create workspace** with empty fields: '
            'every error shows, and focus moves to the first one. Fix them '
            'and press again to save.',
          ),
          Example(
            snippet: 'forms-overview',
            alignment: AlignmentDirectional.topCenter,
            padding: const EdgeInsets.all(24),
            child: const _SignUpForm(),
          ),
        ],
      ),
      DocSection(
        title: 'Form fields',
        children: [
          const DocText(
            'Each typed form field is a `DsFormField` with its control built '
            'in. It takes the control\'s common parameters plus the form '
            'ones: `validator`, `onSaved`, `initialValue`, `autovalidateMode` '
            'and `restorationId`, and the field\'s `label`, `description` '
            'and `required`.',
          ),
          DocTable(
            columns: const ['Form field', 'Control', 'Value'],
            flex: const [5, 4, 3],
            rows: [
              for (final (field, control, value) in const [
                ('DsTextFormField', 'DsTextField', 'String'),
                ('DsNumberFormField', 'DsNumberField', 'num'),
                ('DsSelectFormField<T>', 'DsSelect', 'T'),
                ('DsAutocompleteFormField<T>', 'DsAutocomplete', 'T'),
                ('DsMultiSelectFormField<T>', 'DsMultiSelect', 'List<T>'),
                ('DsDateFormField', 'DsDatePicker', 'DateTime'),
                ('DsDateRangeFormField', 'DsDateRangePicker', 'DsDateRange'),
                ('DsTimeFormField', 'DsTimePicker', 'DsTime'),
                ('DsCheckboxFormField', 'DsCheckbox', 'bool'),
                ('DsSwitchFormField', 'DsSwitch', 'bool'),
                ('DsRadioGroupFormField<T>', 'DsRadioGroup', 'T'),
              ])
                [_Mono(field), _Mono(control), _Mono(value)],
            ],
          ),
          const DocText(
            'A checkbox or switch names itself, so its form field puts the '
            'required mark after the control\'s own label instead of above '
            'it. `DsTextFormField` keeps a `TextEditingController` and the '
            'form in step: pass a `controller` to own the text.',
          ),
        ],
      ),
      DocSection(
        title: 'Any control',
        children: [
          const DocText(
            'For a control without a typed form field, or a parameter one '
            'does not pass on, build the control in a `DsFormField`. The '
            'builder gets the field state: show `field.value` and report '
            'changes to `field.didChange`. Set `group: true` when the control '
            'has several parts with their own labels.',
          ),
          Example(snippet: 'forms-any', child: const _AnyControl()),
        ],
      ),
      DocSection(
        title: 'Validators',
        children: [
          const DocText(
            '`DsValidators` builds validators whose messages say how to fix '
            'the value, in the app\'s language: `required`, `minLength`, '
            '`maxLength` and `email`. `DsValidators.all` runs several in '
            'order and returns the first message. Pass `message` for your own '
            'wording, or mix in any `FormFieldValidator` of your own.',
          ),
          const DocText(
            'Only `required` rejects an empty value, so an optional field can '
            'stay empty. Messages are looked up when the validator is made, so '
            'make validators in `build`, with the field\'s `context`.',
          ),
          Example(snippet: 'forms-validators', child: const _Validators()),
        ],
      ),
      DocSection(
        title: 'Validate and focus',
        children: [
          const DocText(
            '`validateAndFocus()` on the `FormState` validates every field, '
            'then moves focus to the first invalid one in reading order and '
            'scrolls it into view, label to message. It returns whether the '
            'form is valid. The sign-up form above submits like this:',
          ),
          CodeBlock(siteSnippets['forms-submit'] ?? ''),
          const DocText(
            '`reset()` puts every field back to its `initialValue` and drops '
            'typed text and errors.',
          ),
        ],
      ),
      const DocSection(
        title: 'Autovalidate',
        children: [
          DocText(
            'By default a field shows its error only after the form '
            'validates. Set `autovalidateMode` on a field, or on the whole '
            '`Form`, to check sooner:',
          ),
          DocList([
            '`onUserInteraction`: after each change, from the first edit on. '
                'The username field above uses it.',
            '`onUnfocus`: when focus leaves the field, so people are not '
                'interrupted while they type.',
            '`onUserInteractionIfError`: after each change, once the field '
                'already shows an error.',
          ]),
        ],
      ),
      const DocSection(
        title: 'Typed text',
        children: [
          DocText(
            'A date, time or number field can hold text that is not a value, '
            'such as a day that does not exist. It reports this, and '
            'validation fails with the control\'s own message, such as "Enter '
            'a date as MM/DD/YYYY." in English, unless your validator returns '
            'one, which wins. Type 2/30/2026 into **Trial starts** above and '
            'submit.',
          ),
          DocText(
            '**Trial starts** is required. `DsValidators.required` gives way '
            'to the control\'s message: it reports "This field is required." '
            'only while the field is empty. Typed text that is not a date '
            'still fails, with the more useful message.',
          ),
          DocText(
            'Before validating or saving, text that was typed but not '
            'committed yet (focus still in the field, no Enter) is committed, '
            'so the form never saves a value the text no longer shows. '
            'Invalid text saves null.',
          ),
        ],
      ),
      const DocSection(
        title: 'Restoration',
        children: [
          DocText(
            'Give a field a `restorationId`, and the app a restoration scope, '
            'to bring values back after the system ends the app in the '
            'background. A `bool`, `num` or `String` value is restored as it '
            'is, and so are dates and times; the error comes back too. A text '
            'form field without a `controller` restores its text and '
            'selection.',
          ),
          CodeBlock(
            'DsApp(\n'
            "  restorationScopeId: 'app',\n"
            '  home: Form(\n'
            '    child: DsTextFormField(\n'
            "      restorationId: 'full-name',\n"
            "      label: const Text('Full name'),\n"
            '    ),\n'
            '  ),\n'
            ')',
          ),
          DocText(
            'For another value type, subclass `DsFormField` and override '
            '`encodeValue` and `decodeValue`.',
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'When a `Form` validates, Flutter announces the first error. The '
                'fields add no announcement of their own for that validation, '
                'so people hear one message, not one per field.',
            'An error that appears otherwise, by autovalidation or from typed '
                'text, is announced politely by its field.',
            '`validateAndFocus` moves focus to the first invalid field, so '
                'keyboard and screen reader users land on what to fix.',
            'Required fields are marked required for screen readers, and '
                'every message is in words, not only in color.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsFormField<T>'),
          ApiTable([
            (
              'builder',
              'DsFormFieldBuilder<T>',
              'Builds the control from the field state.',
            ),
            (
              'validator',
              'FormFieldValidator<T>?',
              'Returns an error message, or null when the value is valid.',
            ),
            ('onSaved', 'FormFieldSetter<T>?', 'Called by `FormState.save`.'),
            ('initialValue', 'T?', 'The value at the start and after a reset.'),
            ('label', 'Widget?', 'The field label.'),
            ('description', 'Widget?', 'The hint below the control.'),
            (
              'required',
              'bool',
              'Shows the required mark; pair it with `DsValidators.required`.',
            ),
            ('group', 'bool', 'The control has parts with their own labels.'),
            (
              'autovalidateMode',
              'AutovalidateMode?',
              'When the field validates on its own.',
            ),
            (
              'forceErrorText',
              'String?',
              'An error from elsewhere, such as the server.',
            ),
            ('restorationId', 'String?', 'Restores the value and the error.'),
            ('enabled', 'bool', 'False disables the control.'),
            ('fieldStyle', 'DsFieldStyle?', 'Style of the field frame.'),
          ]),
          DocHeading('DsFormFieldState<T> and FormState'),
          ApiTable([
            ('value', 'T?', 'The current value.'),
            ('didChange', 'void Function(T?)', 'Reports a new value.'),
            (
              'didChangeInputIssue',
              'void Function(DsInputIssue?)',
              'Reports typed text that is not a value; pass it as '
                  '`onInputIssueChanged`.',
            ),
            (
              'focus',
              'bool Function()',
              'Focuses the control and scrolls the field into view.',
            ),
            (
              'validateAndFocus',
              'bool Function()',
              'On `FormState`: validates and focuses the first invalid field.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _Mono extends StatelessWidget {
  const _Mono(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Text(
      text,
      style: t.typography
          .mono(t.typography.small)
          .copyWith(color: t.colors.text),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _form = GlobalKey<FormState>();
  final _account = <String, Object?>{};

  // #region forms-submit
  void _submit() {
    final form = _form.currentState!;
    if (!form.validateAndFocus()) return;
    form.save();
    showDsToast(
      context: context,
      title: 'Workspace created',
      description: 'We sent a confirmation to ${_account['email']}.',
      status: DsStatus.success,
    );
  }
  // #endregion

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    // #region forms-overview
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          DsTextFormField(
            label: const Text('Full name'),
            required: true,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            validator: DsValidators.required(context),
            onSaved: (v) => _account['name'] = v,
          ),
          DsTextFormField(
            label: const Text('Work email'),
            description: const Text('We send the confirmation here.'),
            required: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: DsValidators.all([
              DsValidators.required(context),
              DsValidators.email(context),
            ]),
            onSaved: (v) => _account['email'] = v,
          ),
          DsTextFormField(
            label: const Text('Password'),
            required: true,
            obscureText: true,
            revealable: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: DsValidators.all([
              DsValidators.required(context),
              DsValidators.minLength(context, 8),
            ]),
            onSaved: (v) => _account['password'] = v,
          ),
          DsSelectFormField<String>(
            label: const Text('Your role'),
            required: true,
            placeholder: 'Choose a role',
            options: const [
              DsSelectOption(value: 'eng', label: 'Engineering'),
              DsSelectOption(value: 'design', label: 'Design'),
              DsSelectOption(value: 'product', label: 'Product'),
              DsSelectOption(value: 'other', label: 'Something else'),
            ],
            validator: DsValidators.required(context),
            onSaved: (v) => _account['role'] = v,
          ),
          DsNumberFormField(
            label: const Text('Team size'),
            initialValue: 5,
            min: 1,
            max: 500,
            unit: 'people',
            onSaved: (v) => _account['team'] = v,
          ),
          DsDateFormField(
            label: const Text('Trial starts'),
            description: const Text('Your 14-day trial begins on this day.'),
            firstDate: DateTime.now(),
            required: true,
            validator: DsValidators.required(context),
            onSaved: (v) => _account['trialStart'] = v,
          ),
          DsCheckboxFormField(
            label: const Text('I agree to the terms of service'),
            required: true,
            validator: DsValidators.required(
              context,
              message: 'Accept the terms to continue.',
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DsButton(
                onPressed: _submit,
                child: const Text('Create workspace'),
              ),
              DsButton(
                variant: .secondary,
                onPressed: () => _form.currentState!.reset(),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    ),
    // #endregion
  );
}

class _AnyControl extends StatelessWidget {
  const _AnyControl();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    // #region forms-any
    child: DsFormField<String>(
      label: const Text('Billing'),
      description: const Text('Yearly saves two months.'),
      group: true,
      initialValue: 'monthly',
      builder: (field) => DsSegmentedControl<String>(
        value: field.value!,
        onChanged: field.didChange,
        semanticLabel: 'Billing',
        segments: const [
          DsSegment(value: 'monthly', label: Text('Monthly')),
          DsSegment(value: 'yearly', label: Text('Yearly')),
        ],
      ),
    ),
    // #endregion
  );
}

class _Validators extends StatelessWidget {
  const _Validators();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    // #region forms-validators
    child: DsTextFormField(
      label: const Text('Username'),
      description: const Text('3 to 20 letters, digits or dashes.'),
      required: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: DsValidators.all([
        DsValidators.required(context),
        DsValidators.minLength(context, 3),
        DsValidators.maxLength(context, 20),
        (v) => RegExp(r'^[a-zA-Z0-9-]*$').hasMatch(v!)
            ? null
            : 'Use only letters, digits and dashes.',
      ]),
    ),
    // #endregion
  );
}
