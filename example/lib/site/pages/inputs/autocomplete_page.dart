import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The autocomplete page: a text field that filters a list.
class AutocompletePage extends StatefulWidget {
  const AutocompletePage({super.key});

  @override
  State<AutocompletePage> createState() => _AutocompletePageState();
}

class _AutocompletePageState extends State<AutocompletePage> {
  String? _city = 'lis';
  String? _airport;
  String? _customer;
  String? _jobTitle = 'Product designer';
  String? _office;

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Autocomplete',
    lead:
        'A text field that filters a list of options as people type. Use '
        'it for long lists people know their way around, such as cities, '
        'customers or labels, and when typed text may be a new value. For '
        'several values use [Multi-select](/components/multi-select); for a '
        'short list with no typing, [Select](/components/select).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'autocomplete-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region autocomplete-overview
              child: DsField(
                label: const Text('City'),
                child: DsAutocomplete<String>(
                  value: _city,
                  onChanged: (v) => setState(() => _city = v),
                  placeholder: 'Search cities',
                  options: [
                    for (final (id, name) in cities)
                      DsSelectOption(value: id, label: name),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Filtering',
        children: [
          DocText(
            'By default an option matches when its label contains the typed '
            'text. Case is folded, also for the Turkish dotted and dotless '
            'i and the German ß: `ist` finds "İstanbul" and `strasse` finds '
            '"Straße". Accents are kept, so `sao` does not find "São Paulo". '
            'The matched letters are drawn in bold.',
          ),
          DocText(
            'Typing opens the list and makes the first match active; Enter, '
            'Tab or a click chooses it. Leaving the field with text that is '
            'not an option puts the chosen label back. Emptying the text and '
            'leaving clears the value. The clear button is on by default; '
            'set `clearable` to false to hide it.',
          ),
        ],
      ),
      DocSection(
        title: 'Custom filter',
        children: [
          const DocText(
            'Pass `filter` for another rule. Here an airport also matches '
            'its code, which sits in the option\'s `detail`. Use `dsFoldCase` '
            'to compare the way the default does.',
          ),
          Example(
            snippet: 'autocomplete-filter',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region autocomplete-filter
              child: DsField(
                label: const Text('Departure airport'),
                description: const Text('Type a city or a code, like LHR.'),
                child: DsAutocomplete<String>(
                  value: _airport,
                  onChanged: (v) => setState(() => _airport = v),
                  placeholder: 'City or code',
                  options: [
                    for (final (code, name) in airports)
                      DsSelectOption(value: code, label: name, detail: code),
                  ],
                  filter: (option, query) =>
                      dsFoldCase(option.label).contains(dsFoldCase(query)) ||
                      dsFoldCase(option.detail!).startsWith(dsFoldCase(query)),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Async options',
        children: [
          const DocText(
            '`optionsBuilder` looks options up for the typed text, for '
            'example on a server. While it runs the list shows a spinner and '
            '"Loading", or your `loadingText`. Only the answer to the latest text is used, so a '
            'slow reply never replaces a newer one. `options` are still '
            'what shows before anything is typed, such as recent picks. An '
            '`optionsBuilder` does its own matching, so it cannot be '
            'combined with `filter`. A value no option names, such as a '
            'saved record\'s customer before any search, shows no text '
            'until `labelOf` names it.',
          ),
          Example(
            snippet: 'autocomplete-async',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region autocomplete-async
              child: DsField(
                label: const Text('Customer'),
                child: DsAutocomplete<String>(
                  value: _customer,
                  onChanged: (v) => setState(() => _customer = v),
                  placeholder: 'Search customers',
                  loadingText: 'Searching customers',
                  emptyText: 'No customers match',
                  // Recent customers, shown before anything is typed.
                  options: [
                    for (final c in customers.take(3))
                      DsSelectOption(
                        value: c.id,
                        label: c.name,
                        detail: c.city,
                      ),
                  ],
                  optionsBuilder: (query) async {
                    // A pretend server that answers after half a second.
                    await Future<void>.delayed(
                      const Duration(milliseconds: 500),
                    );
                    final q = dsFoldCase(query);
                    return [
                      for (final c in customers)
                        if (dsFoldCase(c.name).contains(q))
                          DsSelectOption(
                            value: c.id,
                            label: c.name,
                            detail: c.city,
                          ),
                    ];
                  },
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Free text',
        children: [
          const DocText(
            'With `onCreate`, text that matches no option can become the '
            'value. It is called when people commit the text with Enter, Tab '
            'or by leaving the field. Text that spells out an option\'s label '
            'chooses that option instead. Add the new value to `options` so '
            'the field can show its label.',
          ),
          const DocText(
            'When nothing matches, the list offers the typed text as one '
            'highlighted row with a plus icon, "Use “Staff designer”", in '
            'place of "No results". Enter or a click on it takes the text. '
            'Type a title that is not in the list to see it.',
          ),
          Example(
            snippet: 'autocomplete-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region autocomplete-custom
              child: DsField(
                label: const Text('Job title'),
                description: const Text('Pick one or type your own.'),
                child: DsAutocomplete<String>(
                  value: _jobTitle,
                  onChanged: (v) => setState(() => _jobTitle = v),
                  options: [
                    for (final title in jobTitles)
                      DsSelectOption(value: title, label: title),
                    if (_jobTitle case final custom?
                        when !jobTitles.contains(custom))
                      DsSelectOption(value: custom, label: custom),
                  ],
                  onCreate: (text) => setState(() => _jobTitle = text),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Empty and loading text',
        children: [
          DocText(
            'When nothing matches, the list shows "No results" in the '
            'app\'s language, and screen readers hear it. A failed '
            '`optionsBuilder` shows the same. Try `xyz` in the city field '
            'above.',
          ),
          DocText(
            '`emptyText` says something more specific, such as "No '
            'customers match", and `loadingText` replaces "Loading" next to '
            'the spinner. Try `xyz` in the customer field above. Both are '
            'plain strings because screen readers announce them too.',
          ),
        ],
      ),
      DocSection(
        title: 'Error, read-only and disabled',
        children: [
          const DocText(
            'Inside a `DsField` with an `errorText` the field takes the error '
            'look; on its own, set `error`. `readOnly` keeps the text '
            'focusable, selectable and copyable, but the list does not open '
            'and typing does nothing. A null `onChanged` disables it.',
          ),
          Example(
            snippet: 'autocomplete-states',
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // #region autocomplete-states
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Office'),
                    required: true,
                    errorText: _office == null ? 'Choose an office.' : null,
                    child: DsAutocomplete<String>(
                      value: _office,
                      onChanged: (v) => setState(() => _office = v),
                      options: [
                        for (final (id, name) in cities.take(6))
                          DsSelectOption(value: id, label: name),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Language'),
                    child: DsAutocomplete<String>(
                      value: 'en',
                      onChanged: (v) {},
                      readOnly: true,
                      options: const [
                        DsSelectOption(value: 'en', label: 'English'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DsField(
                    label: const Text('Country'),
                    child: DsAutocomplete<String>(
                      value: 'pt',
                      onChanged: null,
                      options: const [
                        DsSelectOption(value: 'pt', label: 'Portugal'),
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
        title: 'Customizing',
        children: [
          const DocText(
            'Change one field with `style`, a part of the app with '
            '`DsAutocompleteTheme`, or the whole app through '
            '`DsComponentThemes`. The same style and theme apply to '
            '[Multi-select](/components/multi-select). `fieldStyle` styles '
            'the text field, `panelStyle` and `optionStyle` the list, and '
            '`maxHeight` caps the list (280 by default).',
          ),
          Example(
            snippet: 'autocomplete-custom-style',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // #region autocomplete-custom-style
              child: DsAutocomplete<String>(
                value: _city,
                onChanged: (v) => setState(() => _city = v),
                semanticLabel: 'City',
                style: const DsAutocompleteStyle(
                  maxHeight: 200,
                  matchStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B6E4F),
                  ),
                ),
                options: [
                  for (final (id, name) in cities)
                    DsSelectOption(value: id, label: name),
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
          DocText(
            'Focus stays in the text the whole time. The active option is '
            'highlighted, not focused, as in native and web comboboxes.',
          ),
          KeyboardTable([
            ('Down / Up', 'Opens the list; moves the active option (wraps).'),
            ('Alt+Down / Alt+Up', 'Opens or closes the list without moving.'),
            ('Enter', 'Chooses the active option, or takes free text.'),
            ('Tab', 'Chooses the active option and moves on.'),
            (
              'Escape',
              'Closes the list. Again: puts the chosen label back over typed '
                  'text. With nothing to undo, it goes on (a dialog closes).',
            ),
            ('Home / End / Left / Right', 'Move the caret in the text.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The field is a text field marked expanded or collapsed (Flutter '
                'has no combobox role yet); its value is the text.',
            'The list is a menu of radio items; the chosen one is checked.',
            'Where the platform supports announcements, the active option is '
                'announced as it moves. Once typing pauses, screen readers '
                'hear the number of results, the empty text or the offered '
                '"Use “…”" row. Where the platform cannot announce, the empty '
                'text is a live region.',
            'The "Use “…”" row is a menu item with its text as the name.',
            'It is named by the `DsField` label or `semanticLabel`; the '
                'placeholder is read as a hint.',
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
                  'disables the field.',
            ),
            (
              'options',
              'List<DsSelectOption<T>>',
              'The choices. With `optionsBuilder`, what shows before typing.',
            ),
            (
              'optionsBuilder',
              'DsOptionsBuilder<T>?',
              'Looks options up for the typed text, e.g. on a server.',
            ),
            (
              'labelOf',
              'String Function(T)?',
              'Labels a value no option names, e.g. a saved record\'s. '
                  'Without it the field shows no text for it.',
            ),
            (
              'filter',
              'DsOptionFilter<T>?',
              'Replaces the default "label contains the text" rule.',
            ),
            (
              'onCreate',
              'ValueChanged<String>?',
              'Creates a value from committed text that matches no option; '
                  'an empty list offers it as "Use “…”".',
            ),
            ('placeholder', 'String?', 'Shown while the text is empty.'),
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
              'clearable',
              'bool',
              'Adds a clear button while there is a value. Default true.',
            ),
            ('readOnly', 'bool', 'Shows the value; does not open or type.'),
            (
              'error',
              'bool',
              'The error look; a `DsField` with an error sets it too.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the field when no `DsField` label does.',
            ),
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

/// Cities for the examples, alphabetical.
const cities = [
  ('ams', 'Amsterdam'),
  ('ath', 'Athens'),
  ('bcn', 'Barcelona'),
  ('ber', 'Berlin'),
  ('bog', 'Bogotá'),
  ('cai', 'Cairo'),
  ('chi', 'Chicago'),
  ('dub', 'Dublin'),
  ('ham', 'Hamburg'),
  ('hel', 'Helsinki'),
  ('ist', 'İstanbul'),
  ('izm', 'İzmir'),
  ('lis', 'Lisbon'),
  ('lon', 'London'),
  ('mad', 'Madrid'),
  ('mel', 'Melbourne'),
  ('mex', 'Mexico City'),
  ('mtl', 'Montréal'),
  ('nyc', 'New York'),
  ('osa', 'Osaka'),
  ('par', 'Paris'),
  ('sao', 'São Paulo'),
  ('seo', 'Seoul'),
  ('sgp', 'Singapore'),
  ('sto', 'Stockholm'),
  ('tok', 'Tokyo'),
  ('tor', 'Toronto'),
  ('vie', 'Vienna'),
  ('zrh', 'Zürich'),
];

/// Airports by code, for the custom filter example.
const airports = [
  ('AMS', 'Amsterdam Schiphol'),
  ('ATL', 'Atlanta Hartsfield-Jackson'),
  ('CDG', 'Paris Charles de Gaulle'),
  ('DXB', 'Dubai International'),
  ('FRA', 'Frankfurt am Main'),
  ('HND', 'Tokyo Haneda'),
  ('IST', 'İstanbul Airport'),
  ('JFK', 'New York John F. Kennedy'),
  ('LAX', 'Los Angeles International'),
  ('LHR', 'London Heathrow'),
  ('MAD', 'Madrid Barajas'),
  ('ORD', 'Chicago O\'Hare'),
  ('SIN', 'Singapore Changi'),
  ('SYD', 'Sydney Kingsford Smith'),
];

/// Customers a pretend server searches.
const customers = [
  (id: 'acme', name: 'Acme Corporation', city: 'Chicago'),
  (id: 'bluebird', name: 'Bluebird Logistics', city: 'Rotterdam'),
  (id: 'cedar', name: 'Cedar & Pine Studio', city: 'Portland'),
  (id: 'delta', name: 'Delta Dental Group', city: 'Austin'),
  (id: 'evergreen', name: 'Evergreen Foods', city: 'Vancouver'),
  (id: 'fjord', name: 'Fjord Analytics', city: 'Oslo'),
  (id: 'granite', name: 'Granite Health', city: 'Denver'),
  (id: 'harbor', name: 'Harbor Freight Lines', city: 'Hamburg'),
  (id: 'ion', name: 'Ion Robotics', city: 'Seoul'),
  (id: 'juniper', name: 'Juniper Books', city: 'Dublin'),
  (id: 'kestrel', name: 'Kestrel Air', city: 'Nairobi'),
  (id: 'lumen', name: 'Lumen Energy', city: 'Lisbon'),
];

/// Suggested job titles for the free text example.
const jobTitles = [
  'Product designer',
  'Product manager',
  'Frontend engineer',
  'Backend engineer',
  'Data analyst',
  'Support specialist',
];
