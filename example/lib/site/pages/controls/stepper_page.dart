import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class StepperPage extends StatelessWidget {
  const StepperPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Stepper',
    lead:
        'Changes a small number one step at a time with minus and plus '
        'buttons: guests, seats, copies, half a kilo. When people type the '
        'number or it can be large, use a '
        '[Number field](/components/number-field).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'Put the stepper at the end of a row that says what it counts. '
            'The button at a limit turns inactive.',
          ),
          Example(snippet: 'stepper-overview', child: _GuestsDemo()),
        ],
      ),
      const DocSection(
        title: 'Limits and steps',
        children: [
          DocText(
            '`min` and `max` default to 0 and 99; `step` adds or removes more '
            'than one. The value slot is as wide as the widest of `min` and '
            '`max`, so the control never jumps as the number grows.',
          ),
          Example(snippet: 'stepper-step', child: _ReminderDemo()),
        ],
      ),
      const DocSection(
        title: 'Decimal values',
        children: [
          DocText(
            'Give a `double` value and the stepper reports doubles; the type '
            'follows `value`, so an `int` stepper keeps reporting ints. It '
            'shows as many fraction digits as `step` and `min` need, with '
            'the locale\'s decimal separator (`2,5` in Turkish), and rounds '
            'float dust away, so `0.1 + 0.2` reports `0.3`.',
          ),
          Example(snippet: 'stepper-decimal', child: _WeightDemo()),
          DocText(
            '`format` takes a `DsNumberFormat`, as the number field does: '
            'fixed fraction digits, thousands grouping, separators. A limit '
            'with more digits than are shown rounds inward: with one digit, '
            '`max: 9.99` stops at 9.9.',
          ),
          DocText(
            '`unit` follows the number and `prefix` leads it, smaller and '
            'quieter, as in the number field. Both mirror in right-to-left '
            'layouts and are read with the value ("2.5 kg"). Give the order '
            'the language writes in: a Turkish percentage is `prefix: \'%\'`, '
            'an English one `unit: \'%\'`.',
          ),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText(
            'A null `onChanged` disables the stepper: the buttons lose their '
            'raised look and the value is muted.',
          ),
          Example(
            snippet: 'stepper-disabled',
            // #region stepper-disabled
            child: const DsStepper(
              value: 4,
              onChanged: null,
              semanticLabel: 'Seats',
            ),
            // #endregion
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one stepper with `style`, or every stepper in a subtree '
            'with `DsStepperTheme`. `buttonWidth`, `valueWidth` and `height` '
            'set the proportions.',
          ),
          const Example(snippet: 'stepper-custom', child: _CustomDemo()),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'The stepper is one Tab stop; the buttons are for the pointer.',
          ),
          KeyboardTable([
            ('Tab', 'Moves focus to the stepper.'),
            (
              'Up / Right',
              'Adds one step. In right-to-left layouts, Left adds.',
            ),
            (
              'Down / Left',
              'Removes one step. In right-to-left layouts, Right removes.',
            ),
            ('Home / End', 'Jumps to `min` or `max`.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced with its `semanticLabel` and the value, with increase '
                'and decrease actions that say the next value.',
            'Always give a `semanticLabel`: the number alone does not say '
                'what it counts.',
            'The minus and plus buttons mirror in right-to-left layouts.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'value',
              'T (int or double)',
              'The current value, between `min` and `max`. Its type is the '
                  'stepper\'s.',
            ),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the new value. Null disables the stepper.',
            ),
            (
              'min / max',
              'num',
              'The limits; default 0 and 99. Whole for an `int` stepper.',
            ),
            (
              'step',
              'num',
              'Added or removed per press; default 1. Whole for an `int` '
                  'stepper.',
            ),
            (
              'unit / prefix',
              'String?',
              'Text after or before the number, read with the value.',
            ),
            (
              'format',
              'DsNumberFormat?',
              'Fraction digits, grouping and separators. Null shows the '
                  'digits `step` and `min` need.',
            ),
            (
              'semanticLabel',
              'String?',
              'What the number counts, for screen readers.',
            ),
            ('style', 'DsStepperStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

/// A row with a title and a hint on the start side and a control at the end.
class _Row extends StatelessWidget {
  const _Row({required this.title, required this.hint, required this.child});

  final String title, hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: t.typography.bodyStrong.copyWith(color: t.colors.text),
              ),
              Text(
                hint,
                style: t.typography.small.copyWith(color: t.colors.textMuted),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _GuestsDemo extends StatefulWidget {
  const _GuestsDemo();

  @override
  State<_GuestsDemo> createState() => _GuestsDemoState();
}

class _GuestsDemoState extends State<_GuestsDemo> {
  int _adults = 2, _children = 0;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: DsCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row(
              title: 'Adults',
              hint: 'Age 13 or above',
              // #region stepper-overview
              child: DsStepper(
                value: _adults,
                min: 1,
                max: 12,
                semanticLabel: 'Adults',
                onChanged: (v) => setState(() => _adults = v),
              ),
              // #endregion
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(height: 1, color: k.border),
            ),
            _Row(
              title: 'Children',
              hint: 'Ages 2 to 12',
              child: DsStepper(
                value: _children,
                max: 6,
                semanticLabel: 'Children',
                onChanged: (v) => setState(() => _children = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderDemo extends StatefulWidget {
  const _ReminderDemo();

  @override
  State<_ReminderDemo> createState() => _ReminderDemoState();
}

class _ReminderDemoState extends State<_ReminderDemo> {
  int _minutes = 15;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: _Row(
      title: 'Remind me before',
      hint: 'Minutes, in steps of 5',
      // #region stepper-step
      child: DsStepper(
        value: _minutes,
        min: 5,
        max: 120,
        step: 5,
        semanticLabel: 'Minutes before the meeting',
        onChanged: (v) => setState(() => _minutes = v),
      ),
      // #endregion
    ),
  );
}

class _WeightDemo extends StatefulWidget {
  const _WeightDemo();

  @override
  State<_WeightDemo> createState() => _WeightDemoState();
}

class _WeightDemoState extends State<_WeightDemo> {
  double _weight = 2.5;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: _Row(
      title: 'Parcel weight',
      hint: 'In steps of 0.5',
      // #region stepper-decimal
      child: DsStepper(
        value: _weight,
        min: 0.5,
        max: 30,
        step: 0.5,
        unit: 'kg',
        semanticLabel: 'Parcel weight',
        onChanged: (v) => setState(() => _weight = v),
      ),
      // #endregion
    ),
  );
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  int _copies = 2;

  @override
  Widget build(BuildContext context) =>
      // #region stepper-custom
      DsStepper(
        value: _copies,
        min: 1,
        max: 20,
        semanticLabel: 'Copies',
        onChanged: (v) => setState(() => _copies = v),
        style: DsStepperStyle(
          height: 40,
          buttonWidth: 40,
          borderRadius: BorderRadius.circular(999),
          buttonRadius: BorderRadius.circular(999),
        ),
      );
  // #endregion
}
