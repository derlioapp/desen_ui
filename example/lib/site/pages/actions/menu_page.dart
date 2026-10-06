import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Menus: from a trigger, inline, with submenus, as context menus, long.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Actions',
    title: 'Menu',
    lead:
        'A list of commands that opens from a button or a right-click. Use '
        'it for actions on something; to pick a value in a form, use a '
        '[Select](/components/select).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'menu-overview', child: _OverviewDemo())],
      ),
      DocSection(
        title: 'Icons, shortcuts and groups',
        children: [
          DocText(
            'Items take a `leading` icon and a `shortcut` hint. When some '
            'items have an icon, the others keep the icon column, so the '
            'labels line up. `DsMenuDivider` separates groups; keep '
            'destructive items in a group of their own at the end. A null '
            '`onPressed` disables an item, and the arrow keys skip it.',
          ),
          DocText(
            'A menu can also sit inline, without a layer, as below. '
            '`DsShortcut` draws the same key hints anywhere else. The Command, '
            'Option, Shift, Delete and Return symbols are icons, so they never '
            'depend on the font.',
          ),
          Example(snippet: 'menu-icons', child: _IconsDemo()),
        ],
      ),
      DocSection(
        title: 'Submenus',
        children: [
          DocText(
            '`DsMenuItem.submenu` opens a menu of its own beside the item, on '
            'the end side, or the start side when the end has no room. '
            'Resting on the item or clicking it opens the submenu. On the '
            'way there, the pointer can cut across the items below without '
            'closing it. Choosing an item in a submenu closes every level.',
          ),
          Example(snippet: 'menu-submenu', child: _SubmenuDemo()),
        ],
      ),
      DocSection(
        title: 'Choice items',
        children: [
          DocText(
            '`checked` turns items into one choice of several. The checked '
            'item shows a check before its label and is bold. Every item of '
            'the menu keeps room for the check, so the labels line up; the '
            'check comes before any icon. Screen readers hear radio items, '
            'checked or not. [Select](/components/select) uses the same '
            'check.',
          ),
          DocText(
            'For a setting that turns on or off on its own ("Show grid"), '
            'or several that can be checked together, add '
            '`checkRole: .checkbox`: the item looks the same, and screen '
            'readers hear a checkbox item instead of one choice of a set. '
            '[Multi-select](/components/multi-select) options are checkbox '
            'items.',
          ),
          DocText(
            'Set `checked` on every item of the group, `false` on the others, '
            'so they all keep the column. For many on/off settings at once, '
            'switches in a [Popover](/components/popover) may read better.',
          ),
          Example(snippet: 'menu-choice', child: _ChoiceDemo()),
        ],
      ),
      DocSection(
        title: 'Context menus',
        children: [
          DocText(
            '`DsContextMenuRegion` opens a menu where the user right-clicks '
            'or long-presses its child. From the keyboard, Shift+F10 or the '
            'Menu key opens it at the focused control, so the child needs '
            'something focusable, such as a row with `onPressed`. On the '
            'web, the browser\'s own context menu stays away while the '
            'pointer is over the region.',
          ),
          Example(snippet: 'menu-context', child: _ContextDemo()),
        ],
      ),
      DocSection(
        title: 'Long menus',
        children: [
          DocText(
            'A menu with more than 100 entries builds only the rows that '
            'show. Arrow keys, type-ahead and the item it opens on work the '
            'same; its labels keep to one line. This one has 180 people and '
            'opens on the current assignee.',
          ),
          Example(snippet: 'menu-long', child: _LongDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            '`style` on the anchor changes the panel (`DsMenuStyle`); '
            '`DsMenuItemTheme` changes the items below it. Menus are opaque '
            'by default; for a frosted menu, see [Layers and '
            'glass](/guides/glass). Placement, Escape, focus and the back '
            'button work as for every layer: see [Layer '
            'behavior](/components/popover).',
          ),
          Example(snippet: 'menu-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Enter / Space',
              'On the trigger, opens the menu and focuses its first item. On '
                  'an item, chooses it.',
            ),
            ('Down / Up', 'Moves to the next or previous item; wraps around.'),
            ('Home / End', 'Moves to the first or last item.'),
            ('A-Z', 'Moves to the next item that starts with the letter.'),
            (
              'Right',
              'On a submenu item, opens the submenu and focuses its first '
                  'item (Left in right-to-left layouts).',
            ),
            (
              'Left',
              'In a submenu, closes it and returns to its item (Right in '
                  'right-to-left layouts).',
            ),
            (
              'Escape',
              'Closes the innermost menu; focus goes back to the trigger or '
                  'the submenu item.',
            ),
            (
              'Tab / Shift+Tab',
              'Closes every level and moves focus to the control after (or '
                  'before) the trigger.',
            ),
            (
              'Shift+F10 / Menu',
              'In a context menu region, opens the menu at the focused '
                  'control.',
            ),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The menu is named by `semanticLabel`; items are menu items, '
                '`checked` items are radio items with their state, or '
                'checkbox items with `checkRole: .checkbox`.',
            'A `DsButton` trigger is announced as expanded or collapsed '
                'without any wiring. Another kind of trigger needs '
                '`Semantics(expanded: controller.isOpen)`.',
            'Submenu items are announced as expanded or collapsed; the '
                'submenu is named by the item\'s label.',
            'Hover and keyboard focus share one highlight. The keyboard '
                'item also draws an inset ring, so the active item is never '
                'shown by color alone.',
            'Screen readers read shortcut hints by key name in the app\'s '
                'language: "⇧⌘E" is "Shift Command E".',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsMenuAnchor'),
          ApiTable([
            ('items', 'List<Widget>', '`DsMenuItem`s and `DsMenuDivider`s.'),
            (
              'builder',
              'DsOverlayTriggerBuilder?',
              'Builds the trigger with the controller that opens the menu.',
            ),
            (
              'controller',
              'DsOverlayController?',
              'Pass one to open the menu from elsewhere; made when null.',
            ),
            (
              'child',
              'Widget?',
              'A trigger that does not need the controller (pass a '
                  '`controller` then).',
            ),
            ('side', 'DsSide', 'Preferred side; `bottom` by default.'),
            ('align', 'DsAlign', 'Alignment along the trigger; `start`.'),
            ('semanticLabel', 'String?', 'Names the menu for screen readers.'),
            ('style', 'DsMenuStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsMenuItem'),
          ApiTable([
            ('label', 'Widget', 'Usually a short `Text`; drives type-ahead.'),
            (
              'onPressed',
              'VoidCallback?',
              'Runs when chosen, then the menu closes. Null disables it.',
            ),
            ('leading', 'Widget?', 'An icon before the label.'),
            ('shortcut', 'String?', 'A key hint on the end side, muted.'),
            ('trailing', 'Widget?', 'A widget on the end side.'),
            ('destructive', 'bool', 'Colors the item as a dangerous action.'),
            (
              'checked',
              'bool?',
              'Makes the item one choice of several (a radio item). When '
                  'true, a check shows before the label.',
            ),
            (
              'checkRole',
              'DsMenuCheckRole',
              '`radio` (default) for one choice of a set, `checkbox` for an '
                  'on/off setting; how a `checked` item is announced.',
            ),
            ('autofocus', 'bool', 'Takes focus when the menu opens.'),
            (
              'submenu',
              'List<Widget>',
              'With `DsMenuItem.submenu`: the items of the submenu.',
            ),
          ]),
          DocHeading('DsContextMenuRegion'),
          ApiTable([
            ('items', 'List<Widget>', '`DsMenuItem`s and `DsMenuDivider`s.'),
            ('child', 'Widget', 'The area that opens the menu.'),
            ('semanticLabel', 'String?', 'Names the menu for screen readers.'),
            ('style', 'DsMenuStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _OverviewDemo extends StatelessWidget {
  const _OverviewDemo();

  @override
  Widget build(BuildContext context) {
    // #region menu-overview
    return DsMenuAnchor(
      semanticLabel: 'Project actions',
      items: [
        DsMenuItem(label: const Text('Edit'), shortcut: '⌘E', onPressed: () {}),
        DsMenuItem(
          label: const Text('Duplicate'),
          shortcut: '⌘D',
          onPressed: () {},
        ),
        DsMenuItem(label: const Text('Share…'), onPressed: () {}),
        const DsMenuDivider(),
        DsMenuItem(
          label: const Text('Delete'),
          shortcut: '⌘⌫',
          destructive: true,
          onPressed: () {},
        ),
      ],
      builder: (context, controller, _) => DsButton(
        variant: .secondary,
        trailing: const DsIcon(DsIcons.chevronDown),
        onPressed: controller.toggle,
        child: const Text('Actions'),
      ),
    );
    // #endregion
  }
}

class _IconsDemo extends StatelessWidget {
  const _IconsDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // #region menu-icons
        DsMenu(
          semanticLabel: 'File',
          children: [
            DsMenuItem(
              leading: const DsIcon(DsIcons.link),
              label: const Text('Copy link'),
              shortcut: '⇧⌘C',
              onPressed: () {},
            ),
            DsMenuItem(
              leading: const DsIcon(DsIcons.copy),
              label: const Text('Duplicate'),
              shortcut: '⌘D',
              onPressed: () {},
            ),
            DsMenuItem(
              leading: const DsIcon(DsIcons.upload),
              label: const Text('Export'),
              onPressed: null,
            ),
            DsMenuItem(label: const Text('Rename'), onPressed: () {}),
            const DsMenuDivider(),
            DsMenuItem(
              leading: const DsIcon(DsIcons.trash),
              label: const Text('Delete'),
              shortcut: '⌘⌫',
              destructive: true,
              onPressed: () {},
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              'Search',
              style: t.typography.body.copyWith(color: t.colors.textMuted),
            ),
            DsShortcut(
              '⌘K',
              textStyle: t.typography.caption.copyWith(
                color: t.colors.textSubtle,
              ),
            ),
          ],
        ),
        // #endregion
      ],
    );
  }
}

class _SubmenuDemo extends StatelessWidget {
  const _SubmenuDemo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      const DsIcon(DsIcons.fileText),
      Flexible(
        child: Text(
          'Brand guidelines.pdf',
          style: DsTheme.of(context).typography.body,
        ),
      ),
      // #region menu-submenu
      DsMenuAnchor(
        semanticLabel: 'File actions',
        items: [
          DsMenuItem(label: const Text('Open'), onPressed: () {}),
          DsMenuItem(label: const Text('Rename'), onPressed: () {}),
          DsMenuItem.submenu(
            label: const Text('Move to'),
            submenu: [
              DsMenuItem(label: const Text('Archive'), onPressed: () {}),
              DsMenuItem(label: const Text('Design'), onPressed: () {}),
              DsMenuItem(label: const Text('Sprint 14'), onPressed: () {}),
              const DsMenuDivider(),
              DsMenuItem(label: const Text('Choose folder…'), onPressed: () {}),
            ],
          ),
          const DsMenuDivider(),
          DsMenuItem(
            label: const Text('Delete'),
            destructive: true,
            onPressed: () {},
          ),
        ],
        builder: (context, controller, _) => DsButton.icon(
          variant: .ghost,
          icon: const DsIcon(DsIcons.ellipsis),
          semanticLabel: 'More',
          onPressed: controller.toggle,
        ),
      ),
      // #endregion
    ],
  );
}

class _ChoiceDemo extends StatefulWidget {
  const _ChoiceDemo();

  @override
  State<_ChoiceDemo> createState() => _ChoiceDemoState();
}

class _ChoiceDemoState extends State<_ChoiceDemo> {
  String _sort = 'Due date';

  @override
  Widget build(BuildContext context) {
    // #region menu-choice
    return DsMenuAnchor(
      semanticLabel: 'Sort by',
      items: [
        for (final option in ['Due date', 'Priority', 'Last updated'])
          DsMenuItem(
            label: Text(option),
            checked: option == _sort,
            autofocus: option == _sort,
            onPressed: () => setState(() => _sort = option),
          ),
      ],
      builder: (context, controller, _) => DsButton(
        variant: .ghost,
        trailing: const DsIcon(DsIcons.chevronsUpDown),
        onPressed: controller.toggle,
        child: Text('Sort: $_sort'),
      ),
    );
    // #endregion
  }
}

class _ContextDemo extends StatelessWidget {
  const _ContextDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    const files = [
      ('Q3 roadmap', 'Edited 2 hours ago'),
      ('Brand guidelines', 'Edited yesterday'),
      ('Hiring plan', 'Edited Monday'),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Right-click or long-press a file. With the keyboard, Tab to a '
            'file and press Shift+F10.',
            style: t.typography.caption.copyWith(color: t.colors.textMuted),
          ),
          DsListSection(
            children: [
              // #region menu-context
              for (final (name, edited) in files)
                DsContextMenuRegion(
                  semanticLabel: name,
                  items: [
                    DsMenuItem(label: const Text('Open'), onPressed: () {}),
                    DsMenuItem(
                      label: const Text('Copy link'),
                      shortcut: '⇧⌘C',
                      onPressed: () {},
                    ),
                    const DsMenuDivider(),
                    DsMenuItem(
                      label: const Text('Delete'),
                      destructive: true,
                      onPressed: () {},
                    ),
                  ],
                  child: DsListRow(
                    leading: const DsIcon(DsIcons.fileText),
                    title: Text(name),
                    detail: Text(edited),
                    onPressed: () {},
                  ),
                ),
              // #endregion
            ],
          ),
        ],
      ),
    );
  }
}

/// 180 names for the long menu: every first name with every last name.
final teamMembers = [
  for (final last in const [
    'Acar',
    'Brooks',
    'Chen',
    'Diaz',
    'Eriksen',
    'Fischer',
    'García',
    'Haddad',
    'Ito',
    'Jensen',
    'Kowalski',
    'Lopez',
    'Moreau',
    'Novak',
    'Okafor',
  ])
    for (final first in const [
      'Ada',
      'Ben',
      'Cleo',
      'Deniz',
      'Elif',
      'Femi',
      'Grace',
      'Hugo',
      'Iris',
      'Jonas',
      'Kemal',
      'Lena',
    ])
      '$first $last',
]..sort();

class _LongDemo extends StatefulWidget {
  const _LongDemo();

  @override
  State<_LongDemo> createState() => _LongDemoState();
}

class _LongDemoState extends State<_LongDemo> {
  String _assignee = 'Lena Novak';

  @override
  Widget build(BuildContext context) {
    // #region menu-long
    return DsMenuAnchor(
      semanticLabel: 'Assignee',
      items: [
        for (final person in teamMembers)
          DsMenuItem(
            label: Text(person),
            checked: person == _assignee,
            autofocus: person == _assignee,
            onPressed: () => setState(() => _assignee = person),
          ),
      ],
      builder: (context, controller, _) => DsButton(
        variant: .secondary,
        leading: const DsIcon(DsIcons.user),
        onPressed: controller.toggle,
        child: Text(_assignee),
      ),
    );
    // #endregion
  }
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) {
    // #region menu-custom
    return DsMenuItemTheme(
      data: DsMenuItemThemeData(
        style: DsMenuItemStyle(borderRadius: BorderRadius.circular(999)),
      ),
      child: DsMenuAnchor(
        style: DsMenuStyle(
          minWidth: 240,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(8),
        ),
        items: [
          DsMenuItem(label: const Text('Profile'), onPressed: () {}),
          DsMenuItem(label: const Text('Settings'), onPressed: () {}),
          const DsMenuDivider(),
          DsMenuItem(label: const Text('Sign out'), onPressed: () {}),
        ],
        builder: (context, controller, _) => DsButton(
          variant: .ghost,
          leading: const DsAvatar(initials: 'EC', size: .xs),
          onPressed: controller.toggle,
          child: const Text('Elif Chen'),
        ),
      ),
    );
    // #endregion
  }
}
