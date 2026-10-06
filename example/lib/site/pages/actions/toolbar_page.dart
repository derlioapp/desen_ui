import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Floating tool bars: toggles, icon buttons, dividers.
class ToolbarPage extends StatelessWidget {
  const ToolbarPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Actions',
    title: 'Toolbar',
    lead:
        'A floating bar of tools for the content under it: text formatting, '
        'canvas tools, actions on the selected rows. It holds toggles, ghost '
        'icon buttons, dividers and at most one primary button.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'toolbar-overview', child: _EditorDemo())],
      ),
      DocSection(
        title: 'Toggles',
        children: [
          DocText(
            '`DsToolbarToggle` is an icon that stays on or off. It takes the '
            'theme\'s selection look while on and is announced as a toggle '
            'button. For one choice out of several, mark the toggle of the '
            'current choice `selected`, as below. A null `onChanged` disables '
            'a toggle.',
          ),
          Example(snippet: 'toolbar-toggles', child: _ViewDemo()),
        ],
      ),
      DocSection(
        title: 'Actions on a selection',
        children: [
          DocText(
            'Ghost icon buttons and a short label fit too. Give every icon '
            'button a `semanticLabel` and a [Tooltip](/components/tooltip), '
            'and keep destructive actions apart with a divider.',
          ),
          Example(snippet: 'toolbar-selection', child: _SelectionDemo()),
        ],
      ),
      DocSection(
        title: 'Overflow',
        children: [
          DocText(
            'Items that do not fit move, from the end, into a menu that a '
            '"More actions" (⋯) button at the end of the bar opens, and they '
            'come back when there is room. Drag the slider to narrow the bar. '
            'A toggle becomes an item that is checked while it is on, a '
            'button an item named by its text or `semanticLabel`, and a '
            'tooltip\'s `shortcut` shows beside the item. A divider is never '
            'left at the end of the bar or at either end of the menu.',
          ),
          Example(snippet: 'toolbar-overflow', child: _OverflowDemo()),
          DocText(
            'Any other item needs a `DsToolbarItem` that gives its menu '
            'items, or an empty list for an item that only shows something, '
            'like the "3 selected" label above. A bar with a child that has '
            'no menu form scrolls instead, so nothing disappears: wrap custom '
            'children in `DsToolbarItem` to let them collapse. It also gives a '
            'toggle or button a menu form of its own. Set `overflow: .scroll` '
            'to keep every item in the bar and scroll the row sideways '
            'instead.',
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one bar with `style`, or every bar in a part of the app '
            'with `DsToolbarTheme`; `DsToolbarToggleTheme` does the same for '
            'toggles. Toolbars are opaque by default. To make one frosted '
            'glass, see [Layers and glass](/guides/glass).',
          ),
          Example(snippet: 'toolbar-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves to the next item. Every item is a Tab stop.'),
            (
              'Left / Right',
              'Moves to the previous or next item and wraps at the ends. '
                  'Mirrored in right-to-left layouts.',
            ),
            ('Home / End', 'Moves to the first or last item.'),
            (
              'Enter / Space',
              'Turns the focused toggle on or off. On the More actions '
                  'button, opens its menu and focuses the first item.',
            ),
            (
              'Up / Down',
              'In the More actions menu, moves between its items. Home and '
                  'End jump to the first and last, Enter or Space chooses.',
            ),
            (
              'Escape',
              'Closes the More actions menu. Focus returns to its button.',
            ),
          ]),
          DocText(
            'The WAI-ARIA toolbar pattern uses a single Tab stop. Desen keeps '
            'one stop per item, because Flutter has no toolbar role to tell '
            'screen reader users that the arrow keys reach the others.',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            '`semanticLabel` names the bar ("Formatting") for screen readers.',
            'Toggles are announced as toggle buttons, on or off, named by '
                'their required `semanticLabel`.',
            'On phones each item gets a 44px tap area. The bar keeps its '
                'height and the items spread out instead.',
            'The More actions button is named in the app\'s language and '
                'announced as collapsed or expanded, like every menu button. '
                'Toggles in its menu are announced as checkbox items, checked '
                'or not.',
            'At large text sizes, items that grow past the bar move into the '
                'menu instead of being cut off.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsToolbar'),
          ApiTable([
            ('children', 'List<Widget>', 'The items, start to end.'),
            ('semanticLabel', 'String?', 'Names the bar for screen readers.'),
            ('style', 'DsToolbarStyle?', 'Laid over the theme and defaults.'),
            (
              'overflow',
              'DsToolbarOverflow',
              'Items that do not fit move into a More actions menu '
                  '(`.menu`, the default) or the row scrolls (`.scroll`).',
            ),
          ]),
          DocHeading('DsToolbarItem'),
          ApiTable([
            ('child', 'Widget', 'The item in the bar.'),
            (
              'menuItems',
              'List<Widget>',
              '`DsMenuItem`s and `DsMenuDivider`s the item stands for in the '
                  'overflow menu. Empty for an item that only shows '
                  'something.',
            ),
          ]),
          DocHeading('DsToolbarToggle'),
          ApiTable([
            ('icon', 'Widget', 'Usually a `DsIcon`.'),
            (
              'semanticLabel',
              'String',
              'What the toggle does; required, since it has no text.',
            ),
            ('selected', 'bool', 'Whether the toggle is on.'),
            (
              'onChanged',
              'ValueChanged<bool>?',
              'Called with the new value. Null disables the toggle.',
            ),
            (
              'style',
              'DsToolbarToggleStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsToolbarDivider'),
          DocText('A thin vertical line between groups. It takes no options.'),
        ],
      ),
    ],
  );
}

class _EditorDemo extends StatefulWidget {
  const _EditorDemo();

  @override
  State<_EditorDemo> createState() => _EditorDemoState();
}

class _EditorDemoState extends State<_EditorDemo> {
  bool _bold = true;
  bool _italic = false;
  bool _underline = false;

  @override
  Widget build(BuildContext context) => Center(
    // #region toolbar-overview
    child: DsToolbar(
      semanticLabel: 'Formatting',
      children: [
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.bold),
          semanticLabel: 'Bold',
          selected: _bold,
          onChanged: (v) => setState(() => _bold = v),
        ),
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.italic),
          semanticLabel: 'Italic',
          selected: _italic,
          onChanged: (v) => setState(() => _italic = v),
        ),
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.underline),
          semanticLabel: 'Underline',
          selected: _underline,
          onChanged: (v) => setState(() => _underline = v),
        ),
        const DsToolbarDivider(),
        DsTooltip(
          message: 'Add link',
          shortcut: '⌘K',
          child: DsButton.icon(
            variant: .ghost,
            size: .sm,
            icon: const DsIcon(DsIcons.link),
            semanticLabel: 'Add link',
            onPressed: () {},
          ),
        ),
        const DsToolbarDivider(),
        DsButton(size: .sm, onPressed: () {}, child: const Text('Comment')),
      ],
    ),
    // #endregion
  );
}

class _ViewDemo extends StatefulWidget {
  const _ViewDemo();

  @override
  State<_ViewDemo> createState() => _ViewDemoState();
}

class _ViewDemoState extends State<_ViewDemo> {
  String _view = 'list';

  @override
  Widget build(BuildContext context) => Center(
    // #region toolbar-toggles
    child: DsToolbar(
      semanticLabel: 'View',
      children: [
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.list),
          semanticLabel: 'List',
          selected: _view == 'list',
          onChanged: (_) => setState(() => _view = 'list'),
        ),
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.layoutGrid),
          semanticLabel: 'Grid',
          selected: _view == 'grid',
          onChanged: (_) => setState(() => _view = 'grid'),
        ),
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.calendar),
          semanticLabel: 'Calendar',
          selected: false,
          onChanged: null,
        ),
      ],
    ),
    // #endregion
  );
}

class _SelectionDemo extends StatelessWidget {
  const _SelectionDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Center(
      // #region toolbar-selection
      child: DsToolbar(
        semanticLabel: 'Selected tasks',
        children: [
          // A label has nothing to do in the overflow menu.
          DsToolbarItem(
            menuItems: const [],
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              child: Text(
                '3 selected',
                style: t.typography.label.copyWith(color: t.colors.text),
              ),
            ),
          ),
          const DsToolbarDivider(),
          DsTooltip(
            message: 'Move to project',
            child: DsButton.icon(
              variant: .ghost,
              size: .sm,
              icon: const DsIcon(DsIcons.folder),
              semanticLabel: 'Move to project',
              onPressed: () {},
            ),
          ),
          DsTooltip(
            message: 'Assign',
            child: DsButton.icon(
              variant: .ghost,
              size: .sm,
              icon: const DsIcon(DsIcons.user),
              semanticLabel: 'Assign',
              onPressed: () {},
            ),
          ),
          const DsToolbarDivider(),
          DsTooltip(
            message: 'Delete',
            shortcut: '⌘⌫',
            child: DsButton.icon(
              variant: .dangerSoft,
              size: .sm,
              icon: const DsIcon(DsIcons.trash),
              semanticLabel: 'Delete',
              onPressed: () {},
            ),
          ),
        ],
      ),
      // #endregion
    );
  }
}

class _OverflowDemo extends StatefulWidget {
  const _OverflowDemo();

  @override
  State<_OverflowDemo> createState() => _OverflowDemoState();
}

class _OverflowDemoState extends State<_OverflowDemo> {
  double _width = 220;
  bool _bold = true;
  bool _italic = false;
  bool _underline = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 24,
    children: [
      SizedBox(
        width: 280,
        child: DsSlider(
          value: _width,
          min: 120,
          max: 420,
          semanticLabel: 'Toolbar width',
          onChanged: (v) => setState(() => _width = v),
        ),
      ),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _width),
        // #region toolbar-overflow
        child: DsToolbar(
          semanticLabel: 'Formatting',
          children: [
            DsToolbarToggle(
              icon: const DsIcon(DsIcons.bold),
              semanticLabel: 'Bold',
              selected: _bold,
              onChanged: (v) => setState(() => _bold = v),
            ),
            DsToolbarToggle(
              icon: const DsIcon(DsIcons.italic),
              semanticLabel: 'Italic',
              selected: _italic,
              onChanged: (v) => setState(() => _italic = v),
            ),
            DsToolbarToggle(
              icon: const DsIcon(DsIcons.underline),
              semanticLabel: 'Underline',
              selected: _underline,
              onChanged: (v) => setState(() => _underline = v),
            ),
            const DsToolbarDivider(),
            DsTooltip(
              message: 'Add link',
              shortcut: '⌘K',
              child: DsButton.icon(
                variant: .ghost,
                size: .sm,
                icon: const DsIcon(DsIcons.link),
                semanticLabel: 'Add link',
                onPressed: () {},
              ),
            ),
            DsButton.icon(
              variant: .ghost,
              size: .sm,
              icon: const DsIcon(DsIcons.copy),
              semanticLabel: 'Duplicate',
              onPressed: () {},
            ),
            const DsToolbarDivider(),
            DsButton(size: .sm, onPressed: () {}, child: const Text('Comment')),
          ],
        ),
        // #endregion
      ),
    ],
  );
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _tool = 'Inbox';

  @override
  Widget build(BuildContext context) => Center(
    // #region toolbar-custom
    child: DsToolbar(
      semanticLabel: 'Tools',
      style: DsToolbarStyle(
        borderRadius: BorderRadius.circular(999),
        padding: const EdgeInsets.all(6),
        gap: 6,
      ),
      children: [
        for (final (tool, icon) in [
          ('Inbox', DsIcons.inbox),
          ('Calendar', DsIcons.calendar),
          ('Search', DsIcons.search),
          ('Settings', DsIcons.settings),
        ])
          DsToolbarToggle(
            icon: DsIcon(icon),
            semanticLabel: tool,
            selected: _tool == tool,
            style: DsToolbarToggleStyle(
              borderRadius: BorderRadius.circular(999),
            ),
            onChanged: (_) => setState(() => _tool = tool),
          ),
      ],
    ),
    // #endregion
  );
}
