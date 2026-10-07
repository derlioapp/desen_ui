import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The multi-select page: several values as tags in a filtering field.
class MultiSelectPage extends StatefulWidget {
  const MultiSelectPage({super.key});

  @override
  State<MultiSelectPage> createState() => _MultiSelectPageState();
}

class _MultiSelectPageState extends State<MultiSelectPage> {
  List<String> _assignees = ['maya', 'omar'];
  List<String> _labels = ['bug', 'design', 'mobile'];
  List<String> _watchers = ['maya', 'omar', 'lena', 'sam', 'ines', 'kenji'];
  List<String> _topics = ['billing', 'security'];

  static DsSelectOption<String> _person(String id, String name, String team) =>
      DsSelectOption(
        value: id,
        label: name,
        detail: team,
        leading: DsAvatar(
          initials: name.split(' ').map((w) => w[0]).join(),
          size: DsSize.xs,
          toneIndex: DsAvatar.toneFor(id),
        ),
      );

  /// The team, with avatars.
  late final people = [
    for (final (id, name, team) in teamMembers) _person(id, name, team),
  ];

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Multi-select',
    lead:
        'Chooses several values from a list. The chosen values show as tags '
        'inside the field, and typing filters the rest. It is an '
        '[Autocomplete](/components/autocomplete) that keeps a list, so '
        'matching, async options and the popup work the same way. For a '
        'handful of options that all fit on screen, a group of checkboxes '
        'is often clearer.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'multi-select-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              // #region multi-select-overview
              child: DsField(
                label: const Text('Assignees'),
                child: DsMultiSelect<String>(
                  value: _assignees,
                  onChanged: (v) => setState(() => _assignees = v),
                  options: people,
                  placeholder: 'Add people',
                  emptyText: 'No one on the team matches',
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Tags',
        children: [
          DocText(
            'Choosing an option adds it, or removes it if it is chosen '
            'already. The list stays open for the next choice and the text '
            'empties. Chosen options show a check in the list.',
          ),
          DocText(
            'Each value is a small neutral tag with a remove button. Tags '
            'wrap onto more lines and the field grows; a label wider than the '
            'field wraps inside its tag. The text follows the '
            'last tag on its line and moves to a line of its own only when '
            'typed text runs out of room. With `clearable` (the default) a '
            'button at the end removes every value.',
          ),
        ],
      ),
      DocSection(
        title: 'Keyboard walk through tags',
        children: [
          const DocText(
            'The remove buttons are not Tab stops, so a field with many tags '
            'is still one stop. Press Left at the start of the text to make '
            'the last tag active; it takes the accent while focus stays in '
            'the text. Left and Right move along the tags, and past the '
            'last one back to the text. Backspace or Delete removes the '
            'active tag. Backspace in empty text removes the last tag. In a '
            'right-to-left layout Right reaches the tags.',
          ),
        ],
      ),
      DocSection(
        title: 'New values',
        children: [
          const DocText(
            'With `onCreate`, typed text that matches no option can become a '
            'value: it is called on Enter or when focus leaves, and adds the '
            'value itself. When nothing matches, the list offers the text as '
            'a highlighted row, "Use “ios”"; Enter or a click on it adds the '
            'tag and empties the text. Here new labels can be created.',
          ),
          Example(
            snippet: 'multi-select-labels',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              // #region multi-select-labels
              child: DsField(
                label: const Text('Labels'),
                description: const Text(
                  'Type a new label and press Enter to create it.',
                ),
                child: DsMultiSelect<String>(
                  value: _labels,
                  onChanged: (v) => setState(() => _labels = v),
                  placeholder: 'Add labels',
                  options: [
                    for (final label in {...issueLabels, ..._labels})
                      DsSelectOption(value: label, label: label),
                  ],
                  onCreate: (text) => setState(() {
                    if (!_labels.contains(text)) _labels = [..._labels, text];
                  }),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Collapsed tags',
        children: [
          const DocText(
            'With `collapseTags` the field keeps to one line while it does '
            'not have focus. The tags that fit show, then a "+N" tag counts '
            'the rest; screen readers hear "N more" with their names. Focus '
            'the field and every tag shows and wraps again, so the arrow '
            'keys reach each one. Use it in dense forms and filter bars.',
          ),
          Example(
            snippet: 'multi-select-collapse',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region multi-select-collapse
              child: DsField(
                label: const Text('Watchers'),
                child: DsMultiSelect<String>(
                  value: _watchers,
                  onChanged: (v) => setState(() => _watchers = v),
                  options: people,
                  placeholder: 'Add people',
                  collapseTags: true,
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Read-only and disabled',
        children: [
          const DocText(
            '`readOnly` shows the tags without remove buttons; the field can '
            'be focused but does not open or take typing. A null `onChanged` '
            'disables it, and a disabled field with `collapseTags` stays '
            'collapsed. Inside a `DsField` with an `errorText` it takes the '
            'error look, as every field does.',
          ),
          Example(
            snippet: 'multi-select-states',
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // #region multi-select-states
                SizedBox(
                  width: 260,
                  child: DsField(
                    label: const Text('Reviewers'),
                    child: DsMultiSelect<String>(
                      value: const ['maya', 'lena'],
                      onChanged: (v) {},
                      readOnly: true,
                      options: people,
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DsField(
                    label: const Text('Approvers'),
                    child: DsMultiSelect<String>(
                      value: const ['omar', 'sam', 'ines'],
                      onChanged: null,
                      collapseTags: true,
                      options: people,
                    ),
                  ),
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
            'A multi-select takes `DsAutocompleteStyle`, the same as '
            '[Autocomplete](/components/autocomplete), and follows '
            '`DsAutocompleteTheme`. The tag parts are `tagBackground`, '
            '`tagForeground`, `tagBorderRadius`, `tagHeight`, `tagTextStyle` '
            'and `tagRemoveStyle`; the active tag nests under `selected`.',
          ),
          Example(
            snippet: 'multi-select-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              // #region multi-select-custom
              child: DsMultiSelect<String>(
                value: _topics,
                onChanged: (v) => setState(() => _topics = v),
                semanticLabel: 'Topics',
                style: DsAutocompleteStyle(
                  tagBorderRadius: BorderRadius.circular(999),
                  tagBackground: const Color(0xFFE3F2EC),
                  tagForeground: const Color(0xFF0B6E4F),
                ),
                options: const [
                  DsSelectOption(value: 'billing', label: 'Billing'),
                  DsSelectOption(value: 'security', label: 'Security'),
                  DsSelectOption(value: 'releases', label: 'Releases'),
                  DsSelectOption(value: 'outages', label: 'Outages'),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Down / Up', 'Opens the list; moves the active option (wraps).'),
            (
              'Enter',
              'Adds or removes the active option; the list stays open.',
            ),
            (
              'Backspace',
              'In empty text: removes the last tag. On an active tag: '
                  'removes it, and the one before becomes active.',
            ),
            (
              'Delete',
              'On an active tag: removes it, and the one after becomes '
                  'active.',
            ),
            (
              'Left / Right',
              'At the start of the text: makes the last tag active, then '
                  'moves along the tags; past the last, back to the text.',
            ),
            (
              'Escape',
              'Leaves an active tag; closes the list. Again: clears typed '
                  'text. With none, it goes on (a dialog closes).',
            ),
            ('Tab', 'Closes the list and moves on. It does not add a value.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The field is a text field marked expanded or collapsed; the '
                'list is a menu of checkable items, and chosen options are '
                'checked.',
            'Each remove button is named with its tag ("Remove Maya Chen"). '
                'Removing a tag is announced.',
            'The "+N" tag is read as "N more" followed by the hidden names. '
                'It is not a Tab stop or a button; a tap on it focuses the '
                'field.',
            'The active tag is filled with the accent under a light label, '
                'a clear step from the gray tags, not a hue change alone.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'List<T>', 'The chosen values, in the order added.'),
            (
              'onChanged',
              'ValueChanged<List<T>>?',
              'Called with the new list. Null disables the field.',
            ),
            (
              'options',
              'List<DsSelectOption<T>>',
              'The choices; the tags take their labels from here.',
            ),
            (
              'optionsBuilder',
              'DsOptionsBuilder<T>?',
              'Looks options up for the typed text.',
            ),
            (
              'labelOf',
              'String Function(T)?',
              'Labels the tag of a value no option names.',
            ),
            ('filter', 'DsOptionFilter<T>?', 'Replaces the default matching.'),
            (
              'onCreate',
              'ValueChanged<String>?',
              'Creates a value from typed text that matches no option; adds '
                  'it itself. An empty list offers it as "Use “…”".',
            ),
            (
              'emptyText',
              'String?',
              'Replaces "No results" when nothing matches.',
            ),
            (
              'loadingText',
              'String?',
              'Replaces "Loading" while `optionsBuilder` runs.',
            ),
            (
              'collapseTags',
              'bool',
              'Keeps the tags to one line with "+N" while unfocused.',
            ),
            (
              'clearable',
              'bool',
              'Adds a button that removes every value. Default true.',
            ),
            ('readOnly', 'bool', 'Tags without remove buttons; no typing.'),
            ('placeholder', 'String?', 'Shown while there are no values.'),
            (
              'style',
              'DsAutocompleteStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// The team for the examples: id, name and team.
const teamMembers = [
  ('maya', 'Maya Chen', 'Design'),
  ('omar', 'Omar Haddad', 'Engineering'),
  ('lena', 'Lena Fischer', 'Product'),
  ('sam', 'Sam Okafor', 'Support'),
  ('ines', 'Inês Costa', 'Engineering'),
  ('kenji', 'Kenji Watanabe', 'Design'),
  ('priya', 'Priya Nair', 'Data'),
  ('lucas', 'Lucas Moreau', 'Sales'),
];

/// Issue labels a project starts with.
const issueLabels = [
  'bug',
  'design',
  'docs',
  'feature',
  'mobile',
  'performance',
  'security',
];
