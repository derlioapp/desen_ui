import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The select page: one value from a short, fixed list.
class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  String? _project = 'web';
  String? _owner = 'maya';
  String? _region = 'fra';
  String? _reviewer;
  String? _plan;
  String? _timeZone = 'Europe/Lisbon';
  String _sort = 'updated';
  String _view = 'board';

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Select',
    lead:
        'Chooses one value from a short, fixed list. It looks like a field '
        'and opens a menu of options. For a list people search, use '
        '[Autocomplete](/components/autocomplete); for two to five options '
        'that should all stay visible, use a '
        '[Segmented control](/components/segmented-control).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'select-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region select-overview
              child: DsField(
                label: const Text('Project'),
                description: const Text('Reports are filed under it.'),
                child: DsSelect<String>(
                  value: _project,
                  onChanged: (v) => setState(() => _project = v),
                  options: const [
                    DsSelectOption(value: 'web', label: 'Northwind Web'),
                    DsSelectOption(value: 'ios', label: 'Northwind iOS'),
                    DsSelectOption(value: 'api', label: 'Northwind API'),
                    DsSelectOption(value: 'docs', label: 'Help Center'),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'When to use',
        children: [
          DocTable(
            columns: ['Component', 'Use it when'],
            flex: [2, 5],
            rows: [
              [
                DocText('**Select**'),
                DocText(
                  'There are about 5 to 15 options, people pick rather than '
                  'search, and the choice is not the main thing on the '
                  'page.',
                ),
              ],
              [
                DocText('[Segmented control](/components/segmented-control)'),
                DocText(
                  'There are two to five short options and seeing them all '
                  'helps, such as a view switch.',
                ),
              ],
              [
                DocText('[Autocomplete](/components/autocomplete)'),
                DocText(
                  'The list is long, people know what they want, or typed '
                  'text may be a new value.',
                ),
              ],
              [
                DocText('[Multi-select](/components/multi-select)'),
                DocText('People choose several values.'),
              ],
            ],
          ),
        ],
      ),
      DocSection(
        title: 'Options with icons and details',
        children: [
          const DocText(
            'An option can have a `leading` widget, such as an avatar or an '
            'icon. The trigger shows the chosen option\'s leading widget too. '
            'Options without one keep the column, so labels line up.',
          ),
          Example(
            snippet: 'select-options',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region select-options
              child: DsField(
                label: const Text('Owner'),
                child: DsSelect<String>(
                  value: _owner,
                  onChanged: (v) => setState(() => _owner = v),
                  options: [
                    for (final (id, name, team) in const [
                      ('maya', 'Maya Chen', 'Design'),
                      ('omar', 'Omar Haddad', 'Engineering'),
                      ('lena', 'Lena Fischer', 'Product'),
                      ('sam', 'Sam Okafor', 'Support'),
                    ])
                      DsSelectOption(
                        value: id,
                        label: name,
                        detail: team,
                        leading: DsAvatar(
                          initials: name.split(' ').map((w) => w[0]).join(),
                          size: .xs,
                          toneIndex: DsAvatar.toneFor(id),
                        ),
                      ),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
          const DocText(
            'A `detail` is a short muted note at the end of the row. The '
            'chosen option shows a check before its label, as in a '
            '[Menu](/components/menu); every row keeps room for it, so the '
            'labels line up. `enabled: false` '
            'keeps an option visible but out of reach. The select\'s own '
            '`leading` shows before the value when the chosen option has '
            'none, as the globe does here.',
          ),
          Example(
            snippet: 'select-details',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region select-details
              child: DsField(
                label: const Text('Region'),
                child: DsSelect<String>(
                  value: _region,
                  onChanged: (v) => setState(() => _region = v),
                  leading: const DsIcon(DsIcons.globe),
                  options: const [
                    DsSelectOption(
                      value: 'fra',
                      label: 'Frankfurt',
                      detail: 'eu-central',
                    ),
                    DsSelectOption(
                      value: 'iad',
                      label: 'Virginia',
                      detail: 'us-east',
                    ),
                    DsSelectOption(
                      value: 'sin',
                      label: 'Singapore',
                      detail: 'ap-southeast',
                    ),
                    DsSelectOption(
                      value: 'gru',
                      label: 'São Paulo',
                      detail: 'Full',
                      enabled: false,
                    ),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Placeholder and clearing',
        children: [
          const DocText(
            'While nothing is chosen the trigger shows the `placeholder`, '
            'by default the localized "Select". With `clearable`, a clear '
            'button appears while there is a value, and Delete or Backspace '
            'on the focused trigger clears it too. Both report null to '
            '`onChanged`. The clear button is not a Tab stop.',
          ),
          Example(
            snippet: 'select-clear',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region select-clear
              child: DsField(
                label: const Text('Reviewer'),
                child: DsSelect<String>(
                  value: _reviewer,
                  onChanged: (v) => setState(() => _reviewer = v),
                  placeholder: 'Choose a reviewer',
                  clearable: true,
                  options: const [
                    DsSelectOption(value: 'maya', label: 'Maya Chen'),
                    DsSelectOption(value: 'omar', label: 'Omar Haddad'),
                    DsSelectOption(value: 'lena', label: 'Lena Fischer'),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Error, read-only and disabled',
        children: [
          const DocText(
            'Inside a `DsField` with an `errorText` the select takes the '
            'error look: a 2px edge and an error icon, so the error is not '
            'told by color alone. On its own, set `error`. `readOnly` shows '
            'the value at full contrast with a faint edge and no chevron; '
            'it stays a Tab stop and its label can be copied. A null '
            '`onChanged` disables it.',
          ),
          Example(
            snippet: 'select-states',
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // #region select-states
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Billing plan'),
                    required: true,
                    errorText: _plan == null ? 'Choose a plan.' : null,
                    child: DsSelect<String>(
                      value: _plan,
                      onChanged: (v) => setState(() => _plan = v),
                      placeholder: 'Choose a plan',
                      options: const [
                        DsSelectOption(value: 'free', label: 'Free'),
                        DsSelectOption(value: 'team', label: 'Team'),
                        DsSelectOption(value: 'business', label: 'Business'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Workspace plan'),
                    child: DsSelect<String>(
                      value: 'team',
                      onChanged: (v) {},
                      readOnly: true,
                      options: const [
                        DsSelectOption(value: 'team', label: 'Team'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Currency'),
                    child: DsSelect<String>(
                      value: 'eur',
                      onChanged: null,
                      options: const [
                        DsSelectOption(value: 'eur', label: 'Euro (EUR)'),
                      ],
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
        title: 'Long lists',
        children: [
          const DocText(
            'The menu opens on the chosen option, takes the room the window '
            'has and scrolls. Typing a letter jumps to the next option that '
            'starts with it, also while the menu is closed, as in a native '
            'select. A list of more than 100 options builds only the rows '
            'in view, so thousands stay fast. Past about 15 options most '
            'people would rather type: consider '
            '[Autocomplete](/components/autocomplete).',
          ),
          Example(
            snippet: 'select-long',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region select-long
              child: DsField(
                label: const Text('Time zone'),
                description: const Text('Focus it and type a letter.'),
                child: DsSelect<String>(
                  value: _timeZone,
                  onChanged: (v) => setState(() => _timeZone = v),
                  options: [
                    for (final (zone, city, country) in timeZones)
                      DsSelectOption(value: zone, label: city, detail: country),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Width',
        children: [
          const DocText(
            'In a bounded width the trigger fills it, like a field. In an '
            'unbounded one, such as a toolbar `Row`, it is as wide as its '
            'longest option, so it does not jump when the value changes.',
          ),
          Example(
            snippet: 'select-toolbar',
            // #region select-toolbar
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const Text('Sort by'),
                DsSelect<String>(
                  value: _sort,
                  onChanged: (v) => setState(() => _sort = v!),
                  semanticLabel: 'Sort by',
                  options: const [
                    DsSelectOption(value: 'updated', label: 'Last updated'),
                    DsSelectOption(value: 'created', label: 'Created'),
                    DsSelectOption(value: 'priority', label: 'Priority'),
                  ],
                ),
              ],
            ),
            // #endregion
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one select with `style`, a part of the app with '
            '`DsSelectTheme`, or the whole app through `DsComponentThemes`. '
            'State styles (`focused`, `hovered`, `error`, `readOnly`, '
            '`disabled`) nest inside the style. The menu follows '
            '`DsMenuTheme`. See [Theming](/theming) for app-wide tokens.',
          ),
          Example(
            snippet: 'select-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  // #region select-custom
                  DsSelect<String>(
                    value: _view,
                    onChanged: (v) => setState(() => _view = v!),
                    semanticLabel: 'View',
                    style: DsSelectStyle(
                      borderRadius: BorderRadius.circular(999),
                      focused: const DsSelectStyle(
                        borderColor: Color(0xFF0B6E4F),
                      ),
                    ),
                    options: const [
                      DsSelectOption(value: 'board', label: 'Board'),
                      DsSelectOption(value: 'list', label: 'List'),
                      DsSelectOption(value: 'calendar', label: 'Calendar'),
                    ],
                  ),
                  DsSelectTheme(
                    data: const DsSelectThemeData(
                      style: DsSelectStyle(height: 32),
                    ),
                    child: DsSelect<String>(
                      value: _sort,
                      onChanged: (v) => setState(() => _sort = v!),
                      semanticLabel: 'Sort by',
                      options: const [
                        DsSelectOption(value: 'updated', label: 'Last updated'),
                        DsSelectOption(value: 'created', label: 'Created'),
                      ],
                    ),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocHeading('Closed'),
          KeyboardTable([
            ('Tab', 'Moves focus to the trigger. The select is one Tab stop.'),
            ('Down / Up / Enter / Space', 'Opens the menu.'),
            (
              'A letter',
              'Chooses the next option that starts with it, without opening.',
            ),
            (
              'Delete / Backspace',
              'Clears the value when the select is `clearable`.',
            ),
            ('Ctrl+C / Cmd+C', 'Copies the chosen option\'s label.'),
          ]),
          DocHeading('Open'),
          KeyboardTable([
            (
              'Down / Up',
              'Moves to the next or previous option that can be chosen.',
            ),
            ('Home / End', 'Moves to the first or last option.'),
            ('A letter', 'Moves to the next option that starts with it.'),
            ('Enter / Space', 'Chooses the option and closes the menu.'),
            (
              'Tab',
              'Chooses the focused option, closes the menu and moves on.',
            ),
            ('Escape', 'Closes the menu; focus returns to the trigger.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The trigger is announced as a button (Flutter has no combobox '
                'role yet) with its name, the chosen option as its value, '
                'and whether the menu is open.',
            'It is named by the `DsField` label or `semanticLabel`. With '
                'neither, the placeholder names it while nothing is chosen.',
            'The options are radio items of a menu; the chosen one is '
                'checked. In a list of more than 100 options each row says '
                'its place in the list.',
            'An error is announced as an invalid state and drawn with a '
                'thicker edge and an icon, not by color alone.',
            'With `clearable`, screen readers get a "Clear" action on the '
                'trigger.',
            'Keyboard focus turns the edge 2px in the focus color.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('value', 'T?', 'The chosen value, or null for none.'),
            (
              'onChanged',
              'ValueChanged<T?>?',
              'Called with the chosen value, or null when cleared. Null '
                  'disables the select.',
            ),
            (
              'options',
              'List<DsSelectOption<T>>',
              'The choices, top to bottom.',
            ),
            (
              'placeholder',
              'String?',
              'Shown while nothing is chosen. Defaults to the localized '
                  '"Select".',
            ),
            (
              'leading',
              'Widget?',
              'An icon before the value when the chosen option has none.',
            ),
            (
              'clearable',
              'bool',
              'Adds a clear button while there is a value. Default false.',
            ),
            (
              'readOnly',
              'bool',
              'Shows the value, stays focusable, does not open.',
            ),
            (
              'error',
              'bool',
              'The error look; a `DsField` with an error sets it too.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the select when no `DsField` label does.',
            ),
            ('style', 'DsSelectStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsSelectOption'),
          ApiTable([
            ('value', 'T', 'What `onChanged` reports.'),
            ('label', 'String', 'The text in the menu and the trigger.'),
            ('leading', 'Widget?', 'An icon or avatar before the label.'),
            ('detail', 'String?', 'A short muted note at the end of the row.'),
            ('enabled', 'bool', 'Whether it can be chosen. Default true.'),
          ]),
        ],
      ),
    ],
  );
}

/// Time zones by their best-known city, for the long list example.
const timeZones = [
  ('Europe/Amsterdam', 'Amsterdam', 'Netherlands'),
  ('Europe/Athens', 'Athens', 'Greece'),
  ('Pacific/Auckland', 'Auckland', 'New Zealand'),
  ('Asia/Bangkok', 'Bangkok', 'Thailand'),
  ('Europe/Berlin', 'Berlin', 'Germany'),
  ('America/Bogota', 'Bogotá', 'Colombia'),
  ('America/Argentina/Buenos_Aires', 'Buenos Aires', 'Argentina'),
  ('Africa/Cairo', 'Cairo', 'Egypt'),
  ('America/Chicago', 'Chicago', 'United States'),
  ('America/Denver', 'Denver', 'United States'),
  ('Asia/Dubai', 'Dubai', 'United Arab Emirates'),
  ('Europe/Dublin', 'Dublin', 'Ireland'),
  ('Europe/Helsinki', 'Helsinki', 'Finland'),
  ('Asia/Hong_Kong', 'Hong Kong', 'China'),
  ('Pacific/Honolulu', 'Honolulu', 'United States'),
  ('Europe/Istanbul', 'Istanbul', 'Türkiye'),
  ('Asia/Jakarta', 'Jakarta', 'Indonesia'),
  ('Africa/Johannesburg', 'Johannesburg', 'South Africa'),
  ('Asia/Kolkata', 'Kolkata', 'India'),
  ('Africa/Lagos', 'Lagos', 'Nigeria'),
  ('Europe/Lisbon', 'Lisbon', 'Portugal'),
  ('Europe/London', 'London', 'United Kingdom'),
  ('America/Los_Angeles', 'Los Angeles', 'United States'),
  ('Europe/Madrid', 'Madrid', 'Spain'),
  ('America/Mexico_City', 'Mexico City', 'Mexico'),
  ('Africa/Nairobi', 'Nairobi', 'Kenya'),
  ('America/New_York', 'New York', 'United States'),
  ('Europe/Paris', 'Paris', 'France'),
  ('America/Sao_Paulo', 'São Paulo', 'Brazil'),
  ('Asia/Seoul', 'Seoul', 'South Korea'),
  ('Asia/Singapore', 'Singapore', 'Singapore'),
  ('Europe/Stockholm', 'Stockholm', 'Sweden'),
  ('Australia/Sydney', 'Sydney', 'Australia'),
  ('Asia/Tokyo', 'Tokyo', 'Japan'),
  ('America/Toronto', 'Toronto', 'Canada'),
  ('America/Vancouver', 'Vancouver', 'Canada'),
  ('Europe/Warsaw', 'Warsaw', 'Poland'),
  ('Europe/Zurich', 'Zürich', 'Switzerland'),
];
