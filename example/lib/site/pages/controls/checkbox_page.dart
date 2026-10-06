import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class CheckboxPage extends StatelessWidget {
  const CheckboxPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Selection controls',
    title: 'Checkbox',
    lead:
        'Turns one option on or off, or picks any number of items from a '
        'list. Use a [Switch](/components/switch) for a setting that takes '
        'effect at once, and a [Radio](/components/radio) group when only one '
        'choice is allowed.',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          Example(snippet: 'checkbox-overview', child: _OverviewDemo()),
          DocText(
            'The `label` is any widget. When it runs to more than one line, '
            'the box lines up with the first line.',
          ),
        ],
      ),
      const DocSection(
        title: 'Descriptions',
        children: [
          DocText(
            '`description` adds secondary text under the label, in the muted '
            'text color: what the option means or what follows from it. '
            'Tapping it toggles too, and screen readers read it with the '
            'label.',
          ),
          Example(snippet: 'checkbox-description', child: _DescriptionDemo()),
        ],
      ),
      const DocSection(
        title: 'Select all',
        children: [
          DocText(
            'With `tristate`, a null `value` shows a dash: the mixed state. '
            'A parent checkbox uses it when some of its items are checked. '
            'Here `_all` is true when every file is checked, false when none '
            'is, and null otherwise.',
          ),
          DocText(
            'A tristate checkbox cycles from unchecked to checked to mixed. '
            'A "select all" box should not follow that cycle, so it ignores '
            'the value it is given: from mixed or unchecked it checks every '
            'item, and from checked it clears them.',
          ),
          Example(snippet: 'checkbox-select-all', child: _SelectAllDemo()),
        ],
      ),
      const DocSection(
        title: 'Error',
        children: [
          DocText(
            'Wrap a required checkbox in a [Field](/components/field) with an '
            '`errorText`. The box takes a 2px error outline, the message '
            'appears below it, and screen readers hear the box as invalid. '
            'Show the error after the person tries to continue, not before.',
          ),
          Example(snippet: 'checkbox-error', child: _ErrorDemo()),
        ],
      ),
      DocSection(
        title: 'Disabled',
        children: [
          const DocText(
            'A null `onChanged` disables the checkbox. It keeps its shape: an '
            'unchecked box keeps its edge and a checked one its fill, so the '
            'value stays readable.',
          ),
          Example(
            snippet: 'checkbox-disabled',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region checkbox-disabled
                const DsCheckbox(
                  value: true,
                  onChanged: null,
                  label: Text('Included in plan'),
                ),
                const DsCheckbox(
                  value: false,
                  onChanged: null,
                  label: Text('Single sign-on'),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one checkbox with `style`, or every checkbox in a subtree '
            'with `DsCheckboxTheme`. State styles nest: `selected` is the '
            'checked look, and `selected: DsCheckboxStyle(hovered: …)` is '
            'checked and hovered. See [Theming](/theming) for app-wide '
            'tokens.',
          ),
          Example(
            snippet: 'checkbox-custom',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region checkbox-custom
                DsCheckbox(
                  value: true,
                  onChanged: (v) {},
                  style: DsCheckboxStyle(
                    size: 20,
                    borderRadius: BorderRadius.circular(999),
                    selected: const DsCheckboxStyle(
                      background: Color(0xFF0B6E4F),
                    ),
                  ),
                  label: const Text('Round and green'),
                ),
                DsCheckboxTheme(
                  data: const DsCheckboxThemeData(
                    style: DsCheckboxStyle(gap: 8),
                  ),
                  child: DsCheckbox(
                    value: false,
                    onChanged: (v) {},
                    label: const Text('Tighter label gap'),
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
              'Moves focus to the checkbox; a ring shows for keyboard focus '
                  'only.',
            ),
            ('Space / Enter', 'Toggles the checkbox.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a checkbox with its label (and description) and '
                'its state: checked, unchecked or mixed.',
            'The box and its label are one control: tapping the label '
                'toggles it too.',
            'Without a visible label, give a `semanticLabel`.',
            'With an error, the checkbox is announced as invalid. The state '
                'does not rest on color: the outline gets thicker.',
            'Tap area: 24px on desktop, 44px on iOS and Android.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'value',
              'bool?',
              'Checked or unchecked; null shows the mixed state and needs '
                  '`tristate`.',
            ),
            (
              'onChanged',
              'ValueChanged<bool?>?',
              'Called with the next value. Null disables the checkbox.',
            ),
            ('label', 'Widget?', 'Text after the box, usually a `Text`.'),
            (
              'description',
              'Widget?',
              'Secondary text under the label (13, muted).',
            ),
            ('tristate', 'bool', 'Allows the mixed (null) value.'),
            (
              'error',
              'bool',
              'Marks the box invalid. A surrounding `DsField` with an error '
                  'sets it too.',
            ),
            ('style', 'DsCheckboxStyle?', 'Laid over the theme and defaults.'),
            (
              'semanticLabel',
              'String?',
              'Names the checkbox when there is no `label`.',
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
  bool _digest = true, _mentions = true, _assigned = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      // #region checkbox-overview
      DsCheckbox(
        value: _digest,
        onChanged: (v) => setState(() => _digest = v!),
        label: const Text('Weekly summary email'),
      ),
      DsCheckbox(
        value: _mentions,
        onChanged: (v) => setState(() => _mentions = v!),
        label: const Text('When someone mentions me'),
      ),
      DsCheckbox(
        value: _assigned,
        onChanged: (v) => setState(() => _assigned = v!),
        label: const Text('When a task is assigned to me'),
      ),
      // #endregion
    ],
  );
}

class _DescriptionDemo extends StatefulWidget {
  const _DescriptionDemo();

  @override
  State<_DescriptionDemo> createState() => _DescriptionDemoState();
}

class _DescriptionDemoState extends State<_DescriptionDemo> {
  bool _public = false, _comments = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // #region checkbox-description
        DsCheckbox(
          value: _public,
          onChanged: (v) => setState(() => _public = v!),
          label: const Text('Public profile'),
          description: const Text(
            'Anyone with the link can see your name and projects.',
          ),
        ),
        DsCheckbox(
          value: _comments,
          onChanged: (v) => setState(() => _comments = v!),
          label: const Text('Allow comments'),
          description: const Text('Members of the workspace can reply.'),
        ),
        // #endregion
      ],
    ),
  );
}

class _SelectAllDemo extends StatefulWidget {
  const _SelectAllDemo();

  @override
  State<_SelectAllDemo> createState() => _SelectAllDemoState();
}

class _SelectAllDemoState extends State<_SelectAllDemo> {
  final _files = {
    'Invoice-March.pdf': true,
    'Contract-v2.docx': false,
    'Brand-guide.pdf': true,
  };

  bool? get _all {
    if (_files.values.every((on) => on)) return true;
    if (_files.values.any((on) => on)) return null;
    return false;
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      // #region checkbox-select-all
      DsCheckbox(
        tristate: true,
        value: _all,
        onChanged: (_) => setState(() {
          final next = _all != true;
          _files.updateAll((name, on) => next);
        }),
        label: const Text('Select all'),
      ),
      for (final name in _files.keys)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 30),
          child: DsCheckbox(
            value: _files[name]!,
            onChanged: (v) => setState(() => _files[name] = v!),
            label: Text(name),
          ),
        ),
      // #endregion
    ],
  );
}

class _ErrorDemo extends StatefulWidget {
  const _ErrorDemo();

  @override
  State<_ErrorDemo> createState() => _ErrorDemoState();
}

class _ErrorDemoState extends State<_ErrorDemo> {
  bool _accepted = false, _tried = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      // #region checkbox-error
      DsField(
        errorText: _tried && !_accepted
            ? 'Accept the terms to create your workspace.'
            : null,
        child: DsCheckbox(
          value: _accepted,
          onChanged: (v) => setState(() => _accepted = v!),
          label: const Text('I accept the terms of service'),
        ),
      ),
      DsButton(
        onPressed: () => setState(() => _tried = true),
        child: const Text('Create workspace'),
      ),
      // #endregion
    ],
  );
}
