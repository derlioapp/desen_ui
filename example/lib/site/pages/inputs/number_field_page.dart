import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Numbers with steps, limits, decimals, units and the locale's format.
class NumberFieldPage extends StatelessWidget {
  const NumberFieldPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Inputs',
    title: 'Number field',
    lead:
        'A text field for a number, with decrease and increase buttons and '
        'an optional unit. Use it for quantities, amounts and measurements '
        'that people type or nudge. For a value on a fixed scale where the '
        'exact number matters less, use a slider.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'number-field-overview',
            child: _Demo(_Part.overview),
          ),
          DocText(
            '`value` is null while the field is empty, and `onChanged` gets '
            'an `int` when the format has no decimals, a `double` otherwise. '
            '`onChanged: null` disables the field.',
          ),
        ],
      ),
      DocSection(
        title: 'Steps',
        children: [
          DocText(
            'The buttons, the arrow keys and Page Up and Page Down (ten '
            'steps) move by `step`, 1 by default. Holding a button repeats, '
            'faster the longer it is held. Steps land on a grid counted from '
            '`min` (or 0): with a step of 5, a 7 steps up to 10.',
          ),
          Example(snippet: 'number-field-steps', child: _Demo(_Part.steps)),
        ],
      ),
      DocSection(
        title: 'Minimum and maximum',
        children: [
          DocText(
            'A button at a limit turns inactive, and Home and End jump to '
            '`min` and `max` when they are set. Typing is free; on Enter or '
            'when focus leaves, the number is kept in range. A number that '
            'more digits cannot bring back into range, such as 120 with a '
            'maximum of 100, shows the error at once.',
          ),
          DocText(
            'A negative or null `min` lets a minus sign be typed; with '
            '`min: 0` the minus key does nothing.',
          ),
          Example(snippet: 'number-field-range', child: _Demo(_Part.range)),
        ],
      ),
      DocSection(
        title: 'Decimals and units',
        children: [
          DocText(
            '`format` sets the fraction digits: `DsNumberFormat(decimals: 2)` '
            'always shows two and allows no more to be typed. On commit the '
            'number is rounded and shown in the format, so "12.5" becomes '
            '"12.50". `unit` goes after the number and `prefix` before it, '
            '4px from it. The unit follows the number as you type, and '
            'screen readers hear both with the value ("72.5 kg").',
          ),
          Example(snippet: 'number-field-units', child: _Demo(_Part.units)),
        ],
      ),
      DocSection(
        title: 'Locale formatting',
        children: [
          DocText(
            'Separators come from the app\'s locale unless you set them: '
            '`12,500.50` in English, `12.500,50` in Turkish and German, '
            '`12 500,50` in French. Change the examples\' language in the '
            'settings at the top to see the first field follow it. Either '
            '`.` or `,` typed where the decimal separator goes becomes the '
            'right one, so a keypad works in every locale. Digits of other '
            'scripts are read too.',
          ),
          Example(snippet: 'number-field-locale', child: _Demo(_Part.locale)),
          DocText(
            'The second field fixes its separators, so it reads the same in '
            'every language. Do this only when the number belongs to one '
            'place, like a price in a local currency.',
          ),
        ],
      ),
      DocSection(
        title: 'Invalid input',
        children: [
          DocText(
            'Typing lets through only what can become a number, so letters '
            'never get in. Text that is still not a number, such as a lone '
            'minus sign, stays in the field with the error look so people can '
            'fix it, and the value is null. A number that more digits cannot '
            'bring back into range shows the error at once. Inside a '
            '`DsField` the field shows a message that says how to fix it: '
            '"Enter a number.", "Enter 100 or less."',
          ),
          DocText(
            '`onInputIssueChanged` reports that issue, and null once it is '
            'fixed. With `onChanged(null)` it tells an empty field from an '
            'invalid one, '
            'so you can ask for a value only when the field is empty. Clear '
            'the field below, then type 120. When focus leaves, 120 becomes '
            '100.',
          ),
          Example(snippet: 'number-field-invalid', child: _Demo(_Part.invalid)),
        ],
      ),
      DocSection(
        title: 'Read-only and disabled',
        children: [
          DocText(
            '`readOnly` keeps the number selectable but fixed, in the text '
            'field\'s read-only look and without the buttons. A null '
            '`onChanged` disables the field.',
          ),
          Example(snippet: 'number-field-states', child: _Demo(_Part.states)),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one field with `style`, or every number field in a '
            'subtree with `DsNumberFieldTheme`. `fieldStyle` styles the text '
            'field inside; the rest styles the buttons, the unit and the dividers.',
          ),
          Example(snippet: 'number-field-custom', child: _Demo(_Part.custom)),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves focus to the field. The buttons are not Tab stops.'),
            ('Up / Down', 'Steps up or down.'),
            ('Page Up / Page Down', 'Ten steps up or down.'),
            (
              'Home / End',
              'Goes to `min` or `max` when set; otherwise moves the caret.',
            ),
            ('Enter', 'Commits: keeps the number in range and formats it.'),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'One node, as a WAI-ARIA spinbutton: a text field whose value '
                'carries the unit ("72 kg"), with increase and decrease '
                'actions and the next and previous values.',
            'Screen reader users step with a swipe up or down on iOS and the '
                'volume keys on Android.',
            'Invalid text is marked invalid and, inside a `DsField`, '
                'explained in words.',
            'The buttons are the field\'s height tall and at least the tap '
                'target wide (24px on desktop, 44px on iOS and Android), '
                'inside the field, so the field does not grow. They mirror in '
                'right-to-left layouts.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'num?', 'The number; null when the field is empty.'),
            (
              'onChanged',
              'ValueChanged<num?>?',
              'Called with each number in range. Null disables the field.',
            ),
            (
              'onInputIssueChanged',
              'ValueChanged<DsInputIssue?>?',
              'What is wrong with the text, or null once it is fixed.',
            ),
            (
              'onSubmitted',
              'ValueChanged<num?>?',
              'Called on Enter, after the text is committed.',
            ),
            ('min / max', 'num?', 'The range; null for no limit.'),
            ('step', 'num', 'What a button or arrow key adds; 1 by default.'),
            (
              'format',
              'DsNumberFormat',
              'Fraction digits, grouping and separators.',
            ),
            ('unit', 'String?', 'Text after the number, such as "kg".'),
            ('prefix', 'String?', 'Text before the number, such as "\$".'),
            ('placeholder', 'String?', 'Shown while the field is empty.'),
            ('readOnly', 'bool', 'Fixed and selectable, without buttons.'),
            (
              'semanticLabel',
              'String?',
              'Names the field when no `DsField` label does.',
            ),
            (
              'style',
              'DsNumberFieldStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
        ],
      ),
    ],
  );
}

enum _Part { overview, steps, range, units, locale, invalid, states, custom }

class _Demo extends StatefulWidget {
  const _Demo(this.part);

  final _Part part;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  num? _seats = 4;
  num? _discount = 15;
  num? _weight = 72.5;
  num? _score = 80;
  num? _price = 49.9;
  num? _budget = 12500.5;
  num? _rent = 1450;
  num? _tip = 15;
  DsInputIssue? _tipIssue;
  num? _servings = 4;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: switch (widget.part) {
      _Part.overview =>
        // #region number-field-overview
        DsField(
          label: const Text('Seats'),
          description: const Text('Billed per seat, every month.'),
          child: DsNumberField(
            value: _seats,
            min: 1,
            max: 50,
            onChanged: (v) => setState(() => _seats = v),
          ),
        ),
      // #endregion
      _Part.steps => Column(
        spacing: 16,
        children: [
          // #region number-field-steps
          DsField(
            label: const Text('Discount'),
            child: DsNumberField(
              value: _discount,
              min: 0,
              max: 100,
              step: 5,
              unit: '%',
              onChanged: (v) => setState(() => _discount = v),
            ),
          ),
          DsField(
            label: const Text('Weight'),
            child: DsNumberField(
              value: _weight,
              min: 0,
              max: 300,
              step: 0.5,
              format: const DsNumberFormat(decimals: 1),
              unit: 'kg',
              onChanged: (v) => setState(() => _weight = v),
            ),
          ),
          // #endregion
        ],
      ),
      _Part.range =>
        // #region number-field-range
        DsField(
          label: const Text('Passing score'),
          description: const Text('From 0 to 100.'),
          child: DsNumberField(
            value: _score,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _score = v),
          ),
        ),
      // #endregion
      _Part.units => Column(
        spacing: 16,
        children: [
          // #region number-field-units
          DsField(
            label: const Text('Price'),
            child: DsNumberField(
              value: _price,
              min: 0,
              step: 0.5,
              format: const DsNumberFormat(decimals: 2),
              prefix: r'$',
              onChanged: (v) => setState(() => _price = v),
            ),
          ),
          DsField(
            label: const Text('Servings'),
            child: DsNumberField(
              value: _servings,
              min: 1,
              max: 24,
              unit: 'people',
              onChanged: (v) => setState(() => _servings = v),
            ),
          ),
          // #endregion
        ],
      ),
      _Part.locale => Column(
        spacing: 16,
        children: [
          // #region number-field-locale
          DsField(
            label: const Text('Annual budget'),
            child: DsNumberField(
              value: _budget,
              min: 0,
              step: 100,
              format: const DsNumberFormat(decimals: 2, grouping: true),
              onChanged: (v) => setState(() => _budget = v),
            ),
          ),
          DsField(
            label: const Text('Monthly rent in Berlin'),
            child: DsNumberField(
              value: _rent,
              min: 0,
              step: 50,
              format: const DsNumberFormat(
                decimals: 2,
                grouping: true,
                decimalSeparator: ',',
                groupSeparator: '.',
              ),
              unit: '€',
              onChanged: (v) => setState(() => _rent = v),
            ),
          ),
          // #endregion
        ],
      ),
      _Part.invalid =>
        // #region number-field-invalid
        DsField(
          label: const Text('Tip'),
          // Empty asks for a value; invalid text keeps the field's message.
          errorText: _tip == null && _tipIssue == null
              ? 'Enter a tip, or 0 for none.'
              : null,
          child: DsNumberField(
            value: _tip,
            min: 0,
            max: 100,
            unit: '%',
            onChanged: (v) => setState(() => _tip = v),
            onInputIssueChanged: (issue) => setState(() => _tipIssue = issue),
          ),
        ),
      // #endregion
      _Part.states => Column(
        spacing: 16,
        children: [
          // #region number-field-states
          DsField(
            label: const Text('Storage used'),
            child: DsNumberField(
              value: 18.4,
              format: const DsNumberFormat(decimals: 1),
              unit: 'GB',
              readOnly: true,
              onChanged: (v) {},
            ),
          ),
          DsField(
            label: const Text('API rate limit'),
            description: const Text('Available on the Team plan.'),
            child: const DsNumberField(
              value: 600,
              unit: 'per minute',
              onChanged: null,
            ),
          ),
          // #endregion
        ],
      ),
      _Part.custom =>
        // #region number-field-custom
        DsNumberFieldTheme(
          data: const DsNumberFieldThemeData(
            style: DsNumberFieldStyle(
              buttonWidth: 40,
              iconSize: 16,
              fieldStyle: DsTextFieldStyle(
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: DsField(
            label: const Text('Guests'),
            child: DsNumberField(
              value: _seats,
              min: 1,
              max: 12,
              onChanged: (v) => setState(() => _seats = v),
            ),
          ),
        ),
      // #endregion
    },
  );
}
