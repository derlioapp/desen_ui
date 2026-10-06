import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Lists sit in a column no wider than a phone screen, as they would in
/// a settings page.
Widget _phone(Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 360),
  child: child,
);

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'List',
    lead:
        'Groups settings-style rows in a card: an icon, a title, a detail '
        'and a chevron. Use it for settings, account pages and menus that '
        'open other pages. For records people sort and compare, use a '
        '[Table](/components/table).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'list-overview',
            child: _phone(
              // #region list-overview
              DsListSection(
                header: const Text('PREFERENCES'),
                children: [
                  DsListRow(
                    leading: const DsIcon(DsIcons.bell),
                    title: const Text('Notifications'),
                    detail: const Text('On'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.sun),
                    title: const Text('Appearance'),
                    detail: const Text('Automatic'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.globe),
                    title: const Text('Language'),
                    detail: const Text('English'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Rows',
        children: [
          const DocText(
            'A `DsListRow` has a `title` and, optionally, a `leading` icon, '
            'a muted `detail` and a `trailing` widget. `showChevron` says the '
            'row opens another page. With `onPressed` the row is a button '
            'with a hover fill; without it, the row only shows information.',
          ),
          const DocText(
            'Long titles wrap to two lines before they are cut. A long detail '
            'takes at most half the row, so the title always keeps room.',
          ),
          Example(
            snippet: 'list-rows',
            child: _phone(
              // #region list-rows
              DsListSection(
                children: [
                  const DsListRow(
                    leading: DsIcon(DsIcons.user),
                    title: Text('Name'),
                    detail: Text('Deniz Aksoy'),
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.mail),
                    title: const Text('Email'),
                    detail: const Text('deniz@northwind.co'),
                    showChevron: true,
                    onPressed: () {},
                  ),
                  DsListRow(
                    leading: const DsIcon(DsIcons.folder),
                    title: const Text('Storage'),
                    trailing: const DsBadge(
                      status: .warning,
                      label: Text('92% full'),
                    ),
                    showChevron: true,
                    onPressed: () {},
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Switches and controls',
        children: [
          const DocText(
            'Put a [Switch](/components/switch) in `trailing` and leave the '
            'row without `onPressed`. The switch stays the only control, '
            'and a static row merges its text with the switch, so screen '
            'readers hear the title and the switch state as one item.',
          ),
          Example(snippet: 'list-switches', child: _phone(const _SwitchDemo())),
        ],
      ),
      DocSection(
        title: 'Sections and destructive rows',
        children: [
          const DocText(
            'Stack sections with space between them; each gets an optional '
            '`header`. The header shows as written, so type it in capitals '
            'if you want capitals: automatic upper-casing gets the Turkish '
            '"i" wrong. `destructive` colors a row as a danger action, such '
            'as signing out.',
          ),
          Example(
            snippet: 'list-sections',
            child: _phone(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  // #region list-sections
                  DsListSection(
                    header: const Text('ACCOUNT'),
                    children: [
                      DsListRow(
                        leading: const DsIcon(DsIcons.user),
                        title: const Text('Profile'),
                        showChevron: true,
                        onPressed: () {},
                      ),
                      DsListRow(
                        leading: const DsIcon(DsIcons.settings),
                        title: const Text('Security'),
                        detail: const Text('2FA on'),
                        showChevron: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  DsListSection(
                    children: [
                      DsListRow(
                        leading: const DsIcon(DsIcons.logOut),
                        title: const Text('Sign out'),
                        destructive: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Selected rows',
        children: [
          const DocText(
            'In a master-detail list, such as mail or files, `selected` marks '
            'the row whose detail is open. It takes the theme\'s selection '
            'style, a soft tint or a filled accent (see '
            '[Theming](/theming)), and its icon, detail and chevron take '
            'the selected label color. Hover still shows on it, and its '
            'corners follow the section card.',
          ),
          Example(snippet: 'list-selected', child: _phone(const _MailDemo())),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Style one row with `style`, or every row and section below a '
            'point with `DsListRowTheme` and `DsListSectionTheme`. The '
            'section reads the row theme to place its dividers, so dividers '
            'still start where the text starts after you change the padding '
            'or icon size.',
          ),
          Example(
            snippet: 'list-custom',
            child: _phone(
              // #region list-custom
              DsListRowTheme(
                data: const DsListRowThemeData(
                  style: DsListRowStyle(height: 52, iconSize: 20, gap: 16),
                ),
                child: DsListSection(
                  style: const DsListSectionStyle(padding: EdgeInsets.all(8)),
                  children: [
                    DsListRow(
                      leading: const DsIcon(DsIcons.calendar),
                      title: const Text('Calendar'),
                      showChevron: true,
                      onPressed: () {},
                    ),
                    DsListRow(
                      leading: const DsIcon(DsIcons.clock),
                      title: const Text('Reminders'),
                      showChevron: true,
                      onPressed: () {},
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
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves to the next pressable row or control. Static rows are '
                  'skipped.',
            ),
            ('Enter / Space', 'Presses the focused row.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'A pressable row is announced as a button with its title, detail '
                'and trailing text. `semanticLabel` replaces that label.',
            'A static row is read as one item: title, detail and any control '
                'in it.',
            'The section header is announced as a heading.',
            'A `selected` row is announced as selected; other rows announce '
                'no selection state.',
            'Keyboard focus draws a ring inside the row, so the rounded '
                'section does not clip it.',
            'Rows are at least 40px tall, 48px with touch density.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsListSection'),
          ApiTable([
            (
              'children',
              'List<Widget>',
              'The rows, usually `DsListRow` widgets.',
            ),
            ('header', 'Widget?', 'A short label above the card.'),
            (
              'style',
              'DsListSectionStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsListRow'),
          ApiTable([
            ('title', 'Widget', 'The row\'s name.'),
            ('leading', 'Widget?', 'An icon before the title.'),
            (
              'detail',
              'Widget?',
              'A detail such as the current setting, muted, on the end side.',
            ),
            (
              'trailing',
              'Widget?',
              'A switch, badge or count on the end side.',
            ),
            ('showChevron', 'bool', 'Shows that the row opens a page.'),
            (
              'onPressed',
              'VoidCallback?',
              'Makes the row a button. Null leaves it static.',
            ),
            ('destructive', 'bool', 'Colors the row as a danger action.'),
            (
              'selected',
              'bool',
              'Marks the current row of a list, e.g. the open message.',
            ),
            ('semanticLabel', 'String?', 'Replaces the announced label.'),
            ('style', 'DsListRowStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo();

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _digest = true;
  bool _mentions = false;

  @override
  Widget build(BuildContext context) {
    // #region list-switches
    return DsListSection(
      header: const Text('EMAIL'),
      children: [
        DsListRow(
          leading: const DsIcon(DsIcons.inbox),
          title: const Text('Email digest'),
          trailing: DsSwitch(
            value: _digest,
            onChanged: (v) => setState(() => _digest = v),
          ),
        ),
        DsListRow(
          leading: const DsIcon(DsIcons.bell),
          title: const Text('Mentions only'),
          trailing: DsSwitch(
            value: _mentions,
            onChanged: (v) => setState(() => _mentions = v),
          ),
        ),
      ],
    );
    // #endregion
  }
}

class _MailDemo extends StatefulWidget {
  const _MailDemo();

  @override
  State<_MailDemo> createState() => _MailDemoState();
}

class _MailDemoState extends State<_MailDemo> {
  int _open = 1;

  static const _mails = [
    ('Weekly report', '09:41'),
    ('Design review notes', 'Yesterday'),
    ('Invoice #2041', 'Mon'),
  ];

  @override
  Widget build(BuildContext context) {
    // #region list-selected
    return DsListSection(
      children: [
        for (final (i, (subject, time)) in _mails.indexed)
          DsListRow(
            leading: const DsIcon(DsIcons.mail),
            title: Text(subject),
            detail: Text(time),
            selected: _open == i,
            onPressed: () => setState(() => _open = i),
          ),
      ],
    );
    // #endregion
  }
}
