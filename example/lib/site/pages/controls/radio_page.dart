import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Radio',
    lead:
        'Picks exactly one option from a short list that stays in view. '
        'For four or more options in a tight space use a '
        '[Select](/components/select); for two to five options that switch '
        'a view, a [Segmented control](/components/segmented-control).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'A `DsRadioGroup` holds the selected value; each `DsRadio` below '
            'it stands for one value. The radios can sit anywhere in the '
            'group\'s subtree, in any layout.',
          ),
          Example(snippet: 'radio-overview', child: _OverviewDemo()),
        ],
      ),
      const DocSection(
        title: 'With descriptions',
        children: [
          DocText(
            '`description` adds secondary text under the label, such as a '
            'delivery time, in the muted text color. The whole row selects, '
            'the circle lines up with the first line, and screen readers '
            'read the description with the label.',
          ),
          Example(snippet: 'radio-descriptions', child: _ShippingDemo()),
        ],
      ),
      const DocSection(
        title: 'Cards',
        children: [
          DocText(
            '`DsRadioCard` draws an option as a card: plans, themes, '
            'shipping methods. It is a radio in the same group, so the group '
            'keeps one Tab stop and arrow keys move the selection. The whole '
            'card selects; the selected one takes the theme\'s selection '
            'style, and a circle on the first line shows the choice beyond '
            'the fill. `child` holds extra content under the text, such as a '
            'price.',
          ),
          Example(snippet: 'radio-cards', child: _PlanDemo()),
          DocText(
            'Cards fill the width they are given; lay them out in a `Row` '
            'with `Expanded`, a `Column` with `stretch`, or a `Wrap`.',
          ),
        ],
      ),
      const DocSection(
        title: 'Disabled',
        children: [
          DocText(
            '`enabled: false` turns off one option; arrow keys skip it. A '
            'null `onChanged` on the group disables every radio in it.',
          ),
          Example(snippet: 'radio-disabled', child: _DisabledDemo()),
        ],
      ),
      const DocSection(
        title: 'Error',
        children: [
          DocText(
            'For a required choice, wrap the group in a '
            '[Field](/components/field) with `group: true` and an '
            '`errorText`. Every radio takes the error outline and the '
            'message shows once, below the group. `DsRadioGroup(error: true)` '
            'marks the radios without a message, when you show it yourself.',
          ),
          Example(snippet: 'radio-error', child: _ErrorDemo()),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one radio with `style`, or every radio in a subtree with '
            '`DsRadioTheme`. `selected` is the chosen look; `dotSize` and '
            '`dotColor` draw the inner dot.',
          ),
          Example(snippet: 'radio-custom', child: _CustomDemo()),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves focus into the group, to the selected radio or card (or '
                  'the first one when none is selected), and out again.',
            ),
            (
              'Down / Right',
              'Selects the next enabled radio; from the last it wraps to the '
                  'first. In right-to-left layouts, Left selects the next.',
            ),
            (
              'Up / Left',
              'Selects the previous enabled radio; from the first it wraps to '
                  'the last. In right-to-left layouts, Right selects the '
                  'previous.',
            ),
            ('Home / End', 'Selects the first or last enabled radio.'),
            ('Space', 'Selects the focused radio.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Each radio or radio card is announced with its label (and '
                'description), as checked or not, in a group where only one '
                'can be checked.',
            'The circle and its label are one control: tapping the label '
                'selects it.',
            'A `semanticLabel` replaces the visible label for screen '
                'readers; give one when the label is not plain text.',
            'With an error, each radio is announced as invalid, and the '
                'outline gets thicker so the error does not rest on color.',
            'Tap area: 24px on desktop, 44px on iOS and Android.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsRadioGroup'),
          ApiTable([
            ('value', 'T?', 'The selected value, or null for none.'),
            (
              'onChanged',
              'ValueChanged<T?>?',
              'Called with the newly selected value. Null disables every '
                  'radio.',
            ),
            ('error', 'bool', 'Marks every radio in the group invalid.'),
            ('child', 'Widget', 'The subtree that holds the radios.'),
          ]),
          DocHeading('DsRadio'),
          ApiTable([
            ('value', 'T', 'The value this radio stands for.'),
            ('label', 'Widget?', 'Content after the circle, usually a `Text`.'),
            (
              'description',
              'Widget?',
              'Secondary text under the label (13, muted).',
            ),
            ('enabled', 'bool', 'Whether this one option can be selected.'),
            ('error', 'bool', 'Marks this radio invalid.'),
            ('style', 'DsRadioStyle?', 'Laid over the theme and defaults.'),
            (
              'semanticLabel',
              'String?',
              'Replaces the label for screen readers.',
            ),
          ]),
          DocHeading('DsRadioCard'),
          ApiTable([
            ('value', 'T', 'The value this card stands for.'),
            ('label', 'Widget', 'The title, usually a short `Text`.'),
            ('description', 'Widget?', 'Secondary text under the title.'),
            ('child', 'Widget?', 'Extra content under the text.'),
            ('enabled', 'bool', 'Whether this one option can be selected.'),
            ('error', 'bool', 'Marks this card invalid.'),
            (
              'style',
              'DsRadioCardStyle?',
              'Laid over the theme and defaults; `radioStyle` styles the '
                  'circle, `showRadio: false` hides it.',
            ),
            (
              'semanticLabel',
              'String?',
              'Replaces the card\'s text for screen readers.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _OverviewDemo extends StatefulWidget {
  const _OverviewDemo();

  @override
  State<_OverviewDemo> createState() => _OverviewDemoState();
}

class _OverviewDemoState extends State<_OverviewDemo> {
  String _visibility = 'team';

  @override
  Widget build(BuildContext context) =>
      // #region radio-overview
      DsRadioGroup<String>(
        value: _visibility,
        onChanged: (v) => setState(() => _visibility = v!),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            DsRadio(value: 'everyone', label: Text('Everyone')),
            DsRadio(value: 'team', label: Text('Only the team')),
            DsRadio(value: 'me', label: Text('Only me')),
          ],
        ),
      );
  // #endregion
}

class _ShippingDemo extends StatefulWidget {
  const _ShippingDemo();

  @override
  State<_ShippingDemo> createState() => _ShippingDemoState();
}

class _ShippingDemoState extends State<_ShippingDemo> {
  String _shipping = 'standard';

  @override
  Widget build(BuildContext context) => DsRadioGroup<String>(
    value: _shipping,
    onChanged: (v) => setState(() => _shipping = v!),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // #region radio-descriptions
        DsRadio(
          value: 'standard',
          label: Text('Standard · Free'),
          description: Text('3 to 5 business days'),
        ),
        DsRadio(
          value: 'express',
          label: Text('Express · \$12'),
          description: Text('Next business day'),
        ),
        // #endregion
      ],
    ),
  );
}

class _PlanDemo extends StatefulWidget {
  const _PlanDemo();

  @override
  State<_PlanDemo> createState() => _PlanDemoState();
}

class _PlanDemoState extends State<_PlanDemo> {
  String _plan = 'team';

  @override
  Widget build(BuildContext context) {
    // No color: text in a card's child takes the title's, so it reads on
    // the selected fill too.
    final price = DsTheme.of(context).typography.heading;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      // #region radio-cards
      child: DsRadioGroup<String>(
        value: _plan,
        onChanged: (v) => setState(() => _plan = v!),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            for (final (value, name, detail, cost) in [
              ('solo', 'Solo', 'One person, unlimited projects', '\$0'),
              ('team', 'Team', 'Up to 20 members and guests', '\$12'),
              ('business', 'Business', 'SSO, audit log, priority help', '\$24'),
            ])
              Expanded(
                child: DsRadioCard(
                  value: value,
                  label: Text(name),
                  description: Text(detail),
                  child: Text(cost, style: price),
                ),
              ),
          ],
        ),
      ),
      // #endregion
    );
  }
}

class _DisabledDemo extends StatefulWidget {
  const _DisabledDemo();

  @override
  State<_DisabledDemo> createState() => _DisabledDemoState();
}

class _DisabledDemoState extends State<_DisabledDemo> {
  String _plan = 'pro';

  @override
  Widget build(BuildContext context) =>
      // #region radio-disabled
      DsRadioGroup<String>(
        value: _plan,
        onChanged: (v) => setState(() => _plan = v!),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            DsRadio(value: 'free', label: Text('Free')),
            DsRadio(value: 'pro', label: Text('Pro')),
            DsRadio(
              value: 'enterprise',
              enabled: false,
              label: Text('Enterprise (contact sales)'),
            ),
          ],
        ),
      );
  // #endregion
}

class _ErrorDemo extends StatefulWidget {
  const _ErrorDemo();

  @override
  State<_ErrorDemo> createState() => _ErrorDemoState();
}

class _ErrorDemoState extends State<_ErrorDemo> {
  String? _size;
  bool _tried = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      // #region radio-error
      DsField(
        label: const Text('Team size'),
        group: true,
        required: true,
        errorText: _tried && _size == null ? 'Choose a team size.' : null,
        child: DsRadioGroup<String>(
          value: _size,
          onChanged: (v) => setState(() => _size = v),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              DsRadio(value: 'small', label: Text('1 to 10 people')),
              DsRadio(value: 'medium', label: Text('11 to 50 people')),
              DsRadio(value: 'large', label: Text('More than 50')),
            ],
          ),
        ),
      ),
      DsButton(
        onPressed: () => setState(() => _tried = true),
        child: const Text('Continue'),
      ),
      // #endregion
    ],
  );
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _billing = 'yearly';

  @override
  Widget build(BuildContext context) =>
      // #region radio-custom
      DsRadioTheme(
        data: const DsRadioThemeData(
          style: DsRadioStyle(
            size: 20,
            dotSize: 8,
            selected: DsRadioStyle(background: Color(0xFF0B6E4F)),
          ),
        ),
        child: DsRadioGroup<String>(
          value: _billing,
          onChanged: (v) => setState(() => _billing = v!),
          child: const Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              DsRadio(value: 'monthly', label: Text('Monthly')),
              DsRadio(value: 'yearly', label: Text('Yearly')),
            ],
          ),
        ),
      );
  // #endregion
}
