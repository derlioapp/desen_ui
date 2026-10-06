import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class SwitchPage extends StatelessWidget {
  const SwitchPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Switch',
    lead:
        'Turns a setting on or off, and the change applies right away. When '
        'the choice is saved later with a form, or is one of several items '
        'to pick, use a [Checkbox](/components/checkbox).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'With a `label` and a `description`, the switch becomes a '
            'settings row: the text on the start side, the switch at the end '
            'of the width it gets. The whole row toggles. The switch lines up '
            'with the label\'s first line, above the description.',
          ),
          Example(snippet: 'switch-overview', child: _SettingsDemo()),
        ],
      ),
      const DocSection(
        title: 'Label only',
        children: [
          DocText(
            'Without a `description` the row has one line. Inside a `Row` '
            'or another unbounded width, the row shrinks to its content '
            'instead of stretching.',
          ),
          Example(snippet: 'switch-label', child: _LabelDemo()),
        ],
      ),
      const DocSection(
        title: 'Without a label',
        children: [
          DocText(
            'A bare switch fits table rows and toolbars, where the label is '
            'elsewhere on screen. Give it a `semanticLabel` so screen readers '
            'can name it.',
          ),
          Example(snippet: 'switch-bare', child: _BareDemo()),
        ],
      ),
      DocSection(
        title: 'Disabled and error',
        children: [
          const DocText(
            'A null `onChanged` disables the switch and mutes its text. '
            '`error` marks a required switch left off, such as a consent: '
            'the track gets a 2px error outline. Inside a '
            '[Field](/components/field) with an `errorText`, the field sets '
            'it and shows the message.',
          ),
          Example(
            snippet: 'switch-states',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  // #region switch-states
                  const DsSwitch(
                    value: true,
                    onChanged: null,
                    label: Text('Audit log'),
                    description: Text('Included in the Business plan'),
                  ),
                  DsSwitch(
                    value: false,
                    error: true,
                    onChanged: (v) {},
                    label: const Text('Share usage data'),
                    description: const Text('Required for the beta program'),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one switch with `style`, or every switch in a subtree '
            'with `DsSwitchTheme`. `width`, `height` and `inset` size the '
            'track; the knob fills the height inside the inset. '
            '`selected` is the on look.',
          ),
          Example(
            snippet: 'switch-custom',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region switch-custom
                DsSwitch(
                  value: true,
                  onChanged: (v) {},
                  semanticLabel: 'Compact',
                  style: const DsSwitchStyle(width: 34, height: 20, inset: 2),
                ),
                DsSwitch(
                  value: true,
                  onChanged: (v) {},
                  semanticLabel: 'Green',
                  style: const DsSwitchStyle(
                    selected: DsSwitchStyle(trackColor: Color(0xFF0B6E4F)),
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves focus to the switch; a ring shows for keyboard focus '
                  'only.',
            ),
            ('Space / Enter', 'Toggles the switch.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a switch that is on or off, with the label and the '
                'description as its name.',
            'Without a visible label, give a `semanticLabel`.',
            'The off track stands at least 3:1 against the surface, and the '
                'knob at least 3:1 against the track while hovered.',
            'With an error the switch is announced as invalid; the outline '
                'gets thicker so the error does not rest on color.',
            'Tap area: 24px on desktop, 44px on iOS and Android.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'bool', 'On or off.'),
            (
              'onChanged',
              'ValueChanged<bool>?',
              'Called with the new value. Null disables the switch.',
            ),
            ('label', 'Widget?', 'The row title, usually a `Text`.'),
            ('description', 'Widget?', 'Muted text under the title.'),
            ('error', 'bool', 'Marks the switch invalid.'),
            ('style', 'DsSwitchStyle?', 'Laid over the theme and defaults.'),
            (
              'semanticLabel',
              'String?',
              'Names the switch when there is no `label`.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _SettingsDemo extends StatefulWidget {
  const _SettingsDemo();

  @override
  State<_SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<_SettingsDemo> {
  bool _push = true, _focus = false;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: DsCard(
        style: const DsCardStyle(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              // #region switch-overview
              child: DsSwitch(
                value: _push,
                onChanged: (v) => setState(() => _push = v),
                label: const Text('Push notifications'),
                description: const Text('On your phone and desktop'),
              ),
              // #endregion
            ),
            Container(height: 1, color: k.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: DsSwitch(
                value: _focus,
                onChanged: (v) => setState(() => _focus = v),
                label: const Text('Focus mode'),
                description: const Text('Mutes everything until 6 PM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelDemo extends StatefulWidget {
  const _LabelDemo();

  @override
  State<_LabelDemo> createState() => _LabelDemoState();
}

class _LabelDemoState extends State<_LabelDemo> {
  bool _autosave = true;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // #region switch-label
      DsSwitch(
        value: _autosave,
        onChanged: (v) => setState(() => _autosave = v),
        label: const Text('Autosave'),
      ),
      // #endregion
    ],
  );
}

class _BareDemo extends StatefulWidget {
  const _BareDemo();

  @override
  State<_BareDemo> createState() => _BareDemoState();
}

class _BareDemoState extends State<_BareDemo> {
  bool _live = true;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          'Production webhook',
          style: t.typography.body.copyWith(color: t.colors.text),
        ),
        // #region switch-bare
        DsSwitch(
          value: _live,
          onChanged: (v) => setState(() => _live = v),
          semanticLabel: 'Production webhook',
        ),
        // #endregion
      ],
    );
  }
}
