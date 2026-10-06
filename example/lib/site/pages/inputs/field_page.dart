import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The frame around every input: label, description, error and the
/// required mark.
class FieldPage extends StatelessWidget {
  const FieldPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Field',
    lead:
        'Frames a form control with a label above it, a description or an '
        'error message below it, and a required mark. Wrap every input in a '
        '`DsField` instead of placing labels by hand: the control inside '
        'takes its name, its error look and its required state from it.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'field-overview',
            child: _Narrow(
              // #region field-overview
              child: DsField(
                label: const Text('Workspace name'),
                description: const Text('Shown in invites and the sidebar.'),
                required: true,
                child: DsTextField(initialValue: 'Northwind Studio'),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Description and error',
        children: [
          const DocText(
            'The `description` is a hint under the control: a format, a '
            'limit, or why you ask. A non-null `errorText` takes its place '
            'with an icon and the message in the danger color, so the error '
            'is told in words and not by color alone. The control inside '
            'switches to its error look by itself; it needs no `error: true` '
            'of its own.',
          ),
          const DocText(
            'The message area resizes on a spring that does not overshoot, '
            'so the content below moves once and does not bounce. Press '
            '**Create report** without choosing a project.',
          ),
          Example(snippet: 'field-error', child: const _ErrorDemo()),
        ],
      ),
      const DocSection(
        title: 'Required',
        children: [
          DocText(
            '`required: true` adds a mark after the label in the danger text '
            'color and marks the control required for screen readers, which '
            'hear "Required" rather than "asterisk". The mark does not check '
            'anything: validate the value yourself, or let a '
            '[form](/components/forms) do it with `DsValidators.required`.',
          ),
        ],
      ),
      DocSection(
        title: 'Groups',
        children: [
          const DocText(
            'A field around several controls, such as checkboxes or radios, '
            'sets `group: true`. Each control keeps its own label for screen '
            'readers, which read the field label first, then each control, '
            'then the message.',
          ),
          Example(
            snippet: 'field-group',
            alignment: AlignmentDirectional.topStart,
            child: const _GroupDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'How controls read the field',
        children: [
          const DocText(
            'Every Desen input looks for the nearest `DsField` through '
            '`DsFieldScope`: the text, search and number fields, select, '
            'autocomplete, multi-select, date and time pickers, file upload, '
            'checkbox, radio and switch. From it they take:',
          ),
          const DocList([
            '**Their name.** The field label names the control, so it needs '
                'no `semanticLabel`. A text label is read once, not twice.',
            '**The error look.** A field with `errorText` gives the control '
                'its error edge and icon.',
            '**The required state**, for screen readers.',
            '**A place in the message row.** A text field with `maxLength` '
                'puts its counter at the end of the row, beside the '
                'description or the error.',
          ]),
          const DocText(
            'It also works the other way. A number, date or time field whose '
            'text is not a value tells the field how to fix it, and the field '
            'shows that message as its error when you have not set one. Type '
            'a day that does not exist, such as February 30, and press Enter.',
          ),
          Example(snippet: 'field-issue', child: const _IssueDemo()),
          const Callout(
            'An `errorText` you pass always wins over the control\'s own '
            'message.',
          ),
        ],
      ),
      DocSection(
        title: 'Field-like controls',
        children: [
          const DocText(
            'A control of your own can sit among fields and look like one. '
            '`DsFieldSurface` draws the box a text field draws (its fill, '
            'edge and corners, and its focus, error, read-only and disabled '
            'looks) around any content, from the text field\'s style and '
            'theme. Pass it the states of a `DsPressable`; inside a '
            '`DsField` with an error it shows the error by itself. Press the '
            'box to change the color; Tab to it to see the focus edge.',
          ),
          Example(
            snippet: 'field-surface',
            child: const _Narrow(child: _SurfaceDemo()),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one field with `style`, a part of the app with '
            '`DsFieldTheme`, or the whole app through `DsComponentThemes`. '
            'The `error` style applies while the field shows an error.',
          ),
          Example(
            snippet: 'field-custom',
            child: _Narrow(
              // #region field-custom
              child: DsFieldTheme(
                data: DsFieldThemeData(
                  style: DsFieldStyle(
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    labelGap: 8,
                  ),
                ),
                child: Column(
                  spacing: 16,
                  children: [
                    DsField(
                      label: const Text('First name'),
                      child: DsTextField(initialValue: 'Ada'),
                    ),
                    DsField(
                      label: const Text('Last name'),
                      child: DsTextField(initialValue: 'Lovelace'),
                    ),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'By default the label, the control and the message are one node: '
                'the label, the control\'s value, then the description or the '
                'error. The node is marked required and, with an error, '
                'invalid.',
            'A control with buttons of its own (a clear or show password '
                'button) keeps them as separate nodes. The control is then '
                'named by the label text and the message is its own node.',
            'The error is read as "Error", then the message. A new or '
                'changed error is announced politely; on Android, where '
                'announcements are not supported, the message area is a '
                'polite live region instead.',
            'The field adds no focus stop of its own: Tab goes straight to '
                'the control.',
            'Works in right-to-left layouts and with large text.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('child', 'Widget', 'The control, or the controls of a `group`.'),
            ('label', 'Widget?', 'Above the control; usually a `Text`.'),
            (
              'description',
              'Widget?',
              'A hint below the control, hidden while there is an error.',
            ),
            (
              'errorText',
              'String?',
              'The validation message, or null when the value is valid.',
            ),
            (
              'required',
              'bool',
              'Shows the required mark and marks the control required.',
            ),
            (
              'group',
              'bool',
              'The child holds several controls with their own labels.',
            ),
            ('style', 'DsFieldStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

/// Keeps a form-width example from stretching across the page.
class _Narrow extends StatelessWidget {
  const _Narrow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: child,
  );
}

class _ErrorDemo extends StatefulWidget {
  const _ErrorDemo();

  @override
  State<_ErrorDemo> createState() => _ErrorDemoState();
}

class _ErrorDemoState extends State<_ErrorDemo> {
  String? _project;
  bool _checked = false;

  @override
  Widget build(BuildContext context) => _Narrow(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // #region field-error
        DsField(
          label: const Text('Project'),
          description: const Text('The report is filed under this project.'),
          errorText: _checked && _project == null ? 'Choose a project.' : null,
          required: true,
          child: DsSelect<String>(
            value: _project,
            onChanged: (v) => setState(() => _project = v),
            placeholder: 'Choose a project',
            options: const [
              DsSelectOption(value: 'web', label: 'Website redesign'),
              DsSelectOption(value: 'ios', label: 'iOS app'),
              DsSelectOption(value: 'api', label: 'Public API'),
            ],
          ),
        ),
        DsButton(
          onPressed: () => setState(() => _checked = true),
          child: const Text('Create report'),
        ),
        // #endregion
      ],
    ),
  );
}

class _GroupDemo extends StatefulWidget {
  const _GroupDemo();

  @override
  State<_GroupDemo> createState() => _GroupDemoState();
}

class _GroupDemoState extends State<_GroupDemo> {
  bool _mentions = false;
  bool _assigned = false;
  String _visibility = 'team';

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 48,
    runSpacing: 24,
    children: [
      // #region field-group
      DsField(
        group: true,
        label: const Text('Email me when'),
        errorText: _mentions || _assigned ? null : 'Choose at least one.',
        required: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            DsCheckbox(
              value: _mentions,
              onChanged: (v) => setState(() => _mentions = v!),
              label: const Text('Someone mentions me'),
            ),
            DsCheckbox(
              value: _assigned,
              onChanged: (v) => setState(() => _assigned = v!),
              label: const Text('A task is assigned to me'),
            ),
          ],
        ),
      ),
      DsField(
        group: true,
        label: const Text('Visibility'),
        description: const Text('You can change this later.'),
        child: DsRadioGroup<String>(
          value: _visibility,
          onChanged: (v) => setState(() => _visibility = v!),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              DsRadio(value: 'team', label: Text('Only my team')),
              DsRadio(value: 'org', label: Text('Everyone in the company')),
            ],
          ),
        ),
      ),
      // #endregion
    ],
  );
}

class _IssueDemo extends StatefulWidget {
  const _IssueDemo();

  @override
  State<_IssueDemo> createState() => _IssueDemoState();
}

class _IssueDemoState extends State<_IssueDemo> {
  DateTime? _due;

  @override
  Widget build(BuildContext context) => _Narrow(
    // #region field-issue
    child: DsField(
      label: const Text('Due date'),
      description: const Text('Type a date or pick one.'),
      child: DsDatePicker(
        value: _due,
        onChanged: (v) => setState(() => _due = v),
      ),
    ),
    // #endregion
  );
}

class _SurfaceDemo extends StatefulWidget {
  const _SurfaceDemo();

  @override
  State<_SurfaceDemo> createState() => _SurfaceDemoState();
}

class _SurfaceDemoState extends State<_SurfaceDemo> {
  static const _colors = [
    (null, 'No color'),
    (Color(0xFF0A84FF), 'Ocean'),
    (Color(0xFF30A46C), 'Forest'),
    (Color(0xFFF76B15), 'Sunset'),
  ];

  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final (color, name) = _colors[_index];
    // #region field-surface
    return DsField(
      label: const Text('Label color'),
      errorText: color == null ? 'Pick a color.' : null,
      child: DsPressable(
        onPressed: () => setState(() => _index = (_index + 1) % _colors.length),
        semanticLabel: name,
        builder: (context, states, _) => DsFieldSurface(
          states: states,
          child: Row(
            spacing: 8,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color ?? const Color(0x00000000),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Text(name)),
              const DsIcon(DsIcons.chevronDown),
            ],
          ),
        ),
      ),
    );
    // #endregion
  }
}
