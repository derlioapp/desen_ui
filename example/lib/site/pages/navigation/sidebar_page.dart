import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'frame.dart';

class SidebarPage extends StatelessWidget {
  const SidebarPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Sidebar',
    lead:
        'The main navigation of a desktop or tablet app: a column of pages '
        'along the start edge, grouped into sections. On phones, use '
        '[Bottom navigation](/components/bottom-navigation) instead.',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The sidebar runs edge to edge, from the top of the window to the '
            'bottom. Give it the full height, for example as the first child '
            'of a `Row` with `crossAxisAlignment: .stretch`. Its contents '
            'scroll when they do not fit.',
          ),
          DocText(
            'Give each item a `value`, and the sidebar the current `value` '
            'and `onChanged`: the matching item is selected, and pressing '
            'an item reports its value. You can also set `selected` and '
            '`onPressed` on each item yourself; both ways work together.',
          ),
          Example(
            snippet: 'sidebar-overview',
            padding: EdgeInsets.all(24),
            child: _OverviewDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Header, sections and counts',
        children: [
          DocList([
            '`header` sits above the items, for a workspace switcher or a '
                'search button.',
            '`DsSidebarSection` labels a group of items. It is shown as '
                'given, so write it in the case you want to see.',
            '`count` puts a number on the end side of an item, such as '
                'unread messages. Leave it out at zero. Above 99 it shows '
                '"99+", on screen and for screen readers, like a '
                '[Tab](/components/tabs) count. On the selected item it takes '
                'the selected label\'s ink, so it stays readable on the '
                'selection.',
            'Items take a `leading` widget, usually a `DsIcon`; any small '
                'widget works, such as a color dot for a team.',
          ]),
        ],
      ),
      const DocSection(
        title: 'Collapsed rail',
        children: [
          DocText(
            'With `collapsed`, the sidebar narrows to a rail of icons, as in '
            'many web app shells. Your app owns the state: a button that '
            'toggles it, a keyboard shortcut, or a narrow window.',
          ),
          DocList([
            'Each item shows only its `leading` icon. Its label appears as a '
                '[Tooltip](/components/tooltip) on the end side, on hover and '
                'on keyboard focus.',
            'A `count` becomes a small dot on the icon, in the count\'s '
                'color. The number is still announced.',
            'A section label becomes a short line and keeps its height, so '
                'the icons do not move up or down.',
            'The width moves with the theme\'s motion, and at once when the '
                'platform asks for reduced motion. The icons stay where they '
                'are while it moves.',
            'In a collapsed sidebar every item needs a `leading` icon, and a '
                '`Text` label or a `semanticLabel` for its tooltip; debug '
                'builds assert both.',
            '`header` stays as you give it. Read `DsSidebar.collapsedOf` in a '
                'custom header or footer to show a smaller one.',
          ]),
          Example(
            snippet: 'sidebar-collapsed',
            padding: EdgeInsets.all(24),
            child: _RailDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Disabled items',
        children: [
          DocText(
            'An item with a null `onPressed` is disabled: muted, and skipped '
            'by Tab. Prefer hiding pages people cannot open; disable an '
            'item when they should know the page exists.',
          ),
          Example(
            snippet: 'sidebar-disabled',
            padding: EdgeInsets.all(24),
            child: _SettingsDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'The sidebar and its items have separate styles. `DsSidebarStyle` '
            'sets the width, background, padding and section labels; '
            '`DsSidebarItemStyle` sets the rows, through `style` on one item '
            'or `DsSidebarItemTheme` for all of them.',
          ),
          Example(
            snippet: 'sidebar-custom',
            padding: EdgeInsets.all(24),
            child: _CustomDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves focus to the next item; every enabled item is a Tab '
                  'stop.',
            ),
            ('Enter / Space', 'Opens the focused item.'),
            (
              'Escape',
              'Hides the tooltip of a collapsed item; focus stays on it.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The sidebar is a container named by `semanticLabel`; name it, '
                'e.g. "Main".',
            'Items are announced as buttons with their label and count; the '
                'current page is announced as selected.',
            'Section labels are announced as headings, so screen reader '
                'users can jump between groups.',
            'The focus ring is drawn inside each row, so a narrow, clipped '
                'column never cuts it.',
            'Collapsed, items keep their names: screen readers hear the '
                'label, the count and the current page as before, and the '
                'tooltip is not read a second time. Section labels stay '
                'headings.',
            'Collapsing keeps keyboard focus on the focused item.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsSidebar'),
          ApiTable([
            ('children', 'List<Widget>', 'Items and section labels.'),
            ('header', 'Widget?', 'Shown above the items.'),
            (
              'value',
              'T?',
              'The current page: the item with this value is selected.',
            ),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the value of the pressed item.',
            ),
            (
              'collapsed',
              'bool',
              'Narrows the sidebar to a rail of icons, labels as tooltips.',
            ),
            ('semanticLabel', 'String?', 'Names the navigation.'),
            ('style', 'DsSidebarStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsSidebarSection'),
          ApiTable([('label', 'Widget', 'A short `Text`, shown as given.')]),
          DocHeading('DsSidebarItem'),
          ApiTable([
            ('label', 'Widget', 'A short `Text`; it ellipsizes.'),
            (
              'value',
              'T?',
              'Identifies the item to the sidebar\'s `value` and `onChanged`.',
            ),
            ('leading', 'Widget?', 'Before the label, usually a `DsIcon`.'),
            ('count', 'int?', 'A number on the end side; "99+" above 99.'),
            (
              'countSemanticLabel',
              'String?',
              'What screen readers hear for the count ("4 unread"); the '
                  'number when null.',
            ),
            (
              'selected',
              'bool',
              'Whether this is the current page, besides matching `value`.',
            ),
            (
              'onPressed',
              'VoidCallback?',
              'Called when the item is chosen. With neither this nor a '
                  '`value` the sidebar reports, the item is disabled.',
            ),
            (
              'style',
              'DsSidebarItemStyle?',
              'Laid over the theme and defaults.',
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
  String _page = 'Inbox';

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return AppFrame(
      title: _page,
      // #region sidebar-overview
      sidebar: DsSidebar<String>(
        semanticLabel: 'Main',
        value: _page,
        onChanged: (page) => setState(() => _page = page),
        header: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 12),
          child: Text(
            'Acme Inc.',
            style: t.typography.bodyStrong.copyWith(color: t.colors.text),
          ),
        ),
        children: const [
          DsSidebarItem(
            value: 'Inbox',
            leading: DsIcon(DsIcons.inbox),
            label: Text('Inbox'),
            count: 4,
          ),
          DsSidebarItem(
            value: 'Today',
            leading: DsIcon(DsIcons.sun),
            label: Text('Today'),
          ),
          DsSidebarItem(
            value: 'Calendar',
            leading: DsIcon(DsIcons.calendar),
            label: Text('Calendar'),
          ),
          DsSidebarSection(label: Text('PROJECTS')),
          DsSidebarItem(
            value: 'Website redesign',
            leading: DsIcon(DsIcons.folder),
            label: Text('Website redesign'),
            count: 128,
          ),
          DsSidebarItem(
            value: 'Mobile app',
            leading: DsIcon(DsIcons.folder),
            label: Text('Mobile app'),
          ),
        ],
      ),
      // #endregion
    );
  }
}

class _RailDemo extends StatefulWidget {
  const _RailDemo();

  @override
  State<_RailDemo> createState() => _RailDemoState();
}

class _RailDemoState extends State<_RailDemo> {
  String _page = 'Inbox';
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      DsButton(
        variant: .secondary,
        onPressed: () => setState(() => _collapsed = !_collapsed),
        child: Text(_collapsed ? 'Expand sidebar' : 'Collapse sidebar'),
      ),
      AppFrame(
        title: _page,
        // #region sidebar-collapsed
        sidebar: DsSidebar<String>(
          semanticLabel: 'Main',
          collapsed: _collapsed,
          value: _page,
          onChanged: (page) => setState(() => _page = page),
          children: const [
            DsSidebarItem(
              value: 'Inbox',
              leading: DsIcon(DsIcons.inbox),
              label: Text('Inbox'),
              count: 4,
            ),
            DsSidebarItem(
              value: 'Calendar',
              leading: DsIcon(DsIcons.calendar),
              label: Text('Calendar'),
            ),
            DsSidebarSection(label: Text('PROJECTS')),
            DsSidebarItem(
              value: 'Website redesign',
              leading: DsIcon(DsIcons.folder),
              label: Text('Website redesign'),
            ),
            DsSidebarItem(
              value: 'Settings',
              leading: DsIcon(DsIcons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        // #endregion
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
  String _page = 'Profile';

  @override
  Widget build(BuildContext context) => AppFrame(
    title: _page,
    height: 300,
    // #region sidebar-disabled
    sidebar: DsSidebar(
      semanticLabel: 'Settings',
      children: [
        const DsSidebarSection(label: Text('ACCOUNT')),
        DsSidebarItem(
          leading: const DsIcon(DsIcons.user),
          label: const Text('Profile'),
          selected: _page == 'Profile',
          onPressed: () => setState(() => _page = 'Profile'),
        ),
        DsSidebarItem(
          leading: const DsIcon(DsIcons.bell),
          label: const Text('Notifications'),
          selected: _page == 'Notifications',
          onPressed: () => setState(() => _page = 'Notifications'),
        ),
        const DsSidebarSection(label: Text('WORKSPACE')),
        const DsSidebarItem(
          leading: DsIcon(DsIcons.settings),
          label: Text('Billing (admins only)'),
          onPressed: null,
        ),
      ],
    ),
    // #endregion
  );
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _page = 'Docs';

  @override
  Widget build(BuildContext context) => AppFrame(
    title: _page,
    height: 240,
    // #region sidebar-custom
    sidebar: DsSidebarItemTheme(
      data: DsSidebarItemThemeData(
        style: DsSidebarItemStyle(
          height: 36,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        ),
      ),
      child: DsSidebar(
        semanticLabel: 'Library',
        style: const DsSidebarStyle(width: 190),
        children: [
          for (final page in ['Docs', 'Drafts', 'Shared with me'])
            DsSidebarItem(
              label: Text(page),
              selected: _page == page,
              onPressed: () => setState(() => _page = page),
            ),
        ],
      ),
    ),
    // #endregion
  );
}
