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
            ('Enter / Space', 'Turns the focused toggle on or off.'),
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

/// Lets a bar scroll sideways when a phone is too narrow for it.
class _Fit extends StatelessWidget {
  const _Fit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: child,
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
  Widget build(BuildContext context) => _Fit(
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
  Widget build(BuildContext context) => _Fit(
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
    return _Fit(
      // #region toolbar-selection
      child: DsToolbar(
        semanticLabel: 'Selected tasks',
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: Text(
              '3 selected',
              style: t.typography.label.copyWith(color: t.colors.text),
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

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _tool = 'Inbox';

  @override
  Widget build(BuildContext context) => _Fit(
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
