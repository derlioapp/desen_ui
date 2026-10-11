import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'frame.dart';

class TopNavPage extends StatelessWidget {
  const TopNavPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Top navigation',
    lead:
        'The main navigation of an app in its header: a few destinations in '
        'a row, each one a page. It is the wide-screen counterpart of '
        '[Bottom navigation](/components/bottom-navigation), and the '
        'horizontal one of a [Sidebar](/components/sidebar). To switch '
        'sections within a page, use [Tabs](/components/tabs); to choose a '
        'value, a [Segmented control](/components/segmented-control).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'Put it in the app\'s header, beside the app\'s name and actions. '
            'The current destination takes the theme\'s selection, as a '
            'sidebar\'s current page does. Labels keep one weight, so moving '
            'the selection moves nothing beside it.',
          ),
          Example(
            snippet: 'top-nav-overview',
            padding: EdgeInsets.all(16),
            child: _OverviewDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Choosing the current destination',
        children: [
          DocText(
            'Choosing the current destination calls `onChanged` too, with the '
            'current value. Use it as iOS and Android tab bars and a web '
            'header\'s links do: go back to that page\'s first screen, or '
            'scroll it to the top. Choose Podcasts below, then choose it '
            'again.',
          ),
          Example(
            snippet: 'top-nav-again',
            padding: EdgeInsets.all(16),
            child: _AgainDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Icons',
        children: [
          DocText(
            '`icon` adds an icon before the label. It takes the label\'s '
            'color in every state.',
          ),
          Example(
            snippet: 'top-nav-icons',
            padding: EdgeInsets.all(16),
            child: _IconsDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Overflow',
        children: [
          DocText(
            'Destinations that do not fit scroll sideways. The edge that '
            'hides them fades out, and the current one, or the one that '
            'takes keyboard focus, scrolls into view. Keep to a few short '
            'labels; on a phone, switch to bottom navigation.',
          ),
          Example(
            snippet: 'top-nav-overflow',
            padding: EdgeInsets.all(16),
            child: _OverflowDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Disabled destination',
        children: [
          DocText(
            '`enabled: false` on an item dims it and keeps it from being '
            'chosen: taps and the arrow keys pass it by, and screen readers '
            'announce it as disabled. A null `onChanged` disables the whole '
            'row.',
          ),
          Example(
            snippet: 'top-nav-disabled',
            padding: EdgeInsets.all(16),
            child: _DisabledDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            '`style` changes the row and its destinations, state by state '
            '(`hovered`, `selected`, `disabled` …); `DsTopNavTheme` does the '
            'same for a subtree. Keep the label weight the same in every '
            'state, so the destinations beside a newly selected one do not '
            'move.',
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves focus into the row, to the current destination, and '
                  'out of it: the row is one Tab stop.',
            ),
            (
              'Left / Right',
              'Moves focus to the previous or next enabled destination, '
                  'wrapping around, without opening it. Mirrored in '
                  'right-to-left layouts.',
            ),
            (
              'Home / End',
              'Moves focus to the first or last enabled destination.',
            ),
            (
              'Enter / Space',
              'Opens the focused destination, or reports the current one '
                  'again.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The row is a navigation landmark named by `semanticLabel`, or '
                'the localized "Navigation" by default.',
            'Each destination is a button, as links in a web navigation '
                'are: it swaps the page, where a tab would switch a panel '
                'within it. It is announced with its label and its position '
                '("2 of 4", localized). The current one is announced as '
                'selected (the current item on the web) and a disabled one '
                'as disabled. `semanticLabel` on an item overrides its '
                'label; the position stays.',
            'A tap plays the selection haptic, or the command one on the '
                'current destination; the keyboard plays none.',
            'The current destination is marked by a fill, not by color '
                'alone.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsTopNav'),
          ApiTable([
            (
              'items',
              'List<DsTopNavItem<T>>',
              'The destinations, start to end.',
            ),
            (
              'value',
              'T',
              'The current destination\'s value; one that matches no '
                  'destination marks none.',
            ),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the chosen value, the current one too. Null '
                  'disables the row.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the navigation; the localized "Navigation" by default.',
            ),
            (
              'focusNode',
              'FocusNode?',
              'Stands for the row; focusing it focuses the current '
                  'destination.',
            ),
            ('autofocus', 'bool', 'Focuses the current destination at first.'),
            ('style', 'DsTopNavStyle?', 'The row\'s and destinations\' style.'),
          ]),
          DocHeading('DsTopNavItem'),
          ApiTable([
            ('value', 'T', 'The value this destination selects.'),
            ('label', 'Widget', 'A short `Text`.'),
            ('icon', 'Widget?', 'An icon before the label.'),
            (
              'semanticLabel',
              'String?',
              'Overrides the label screen readers announce.',
            ),
            (
              'enabled',
              'bool',
              'False dims the destination and keeps it from being chosen. '
                  'Default `true`.',
            ),
          ]),
        ],
      ),
    ],
  );
}

const _titles = ['Radio', 'Podcasts', 'TV', 'Library', 'Charts', 'Events'];

class _OverviewDemo extends StatefulWidget {
  const _OverviewDemo();

  @override
  State<_OverviewDemo> createState() => _OverviewDemoState();
}

class _OverviewDemoState extends State<_OverviewDemo> {
  int _page = 0;

  @override
  Widget build(BuildContext context) => HeaderFrame(
    title: _titles[_page],
    // #region top-nav-overview
    nav: DsTopNav<int>(
      value: _page,
      onChanged: (v) => setState(() => _page = v),
      items: const [
        DsTopNavItem(value: 0, label: Text('Radio')),
        DsTopNavItem(value: 1, label: Text('Podcasts')),
        DsTopNavItem(value: 2, label: Text('TV')),
        DsTopNavItem(value: 3, label: Text('Library')),
      ],
    ),
    // #endregion
  );
}

class _AgainDemo extends StatefulWidget {
  const _AgainDemo();

  @override
  State<_AgainDemo> createState() => _AgainDemoState();
}

class _AgainDemoState extends State<_AgainDemo> {
  int _page = 0;
  bool _again = false;

  @override
  Widget build(BuildContext context) => HeaderFrame(
    title: _again ? '${_titles[_page]}: back to the start' : _titles[_page],
    // #region top-nav-again
    nav: DsTopNav<int>(
      value: _page,
      onChanged: (v) => setState(() {
        // The current destination again: back to its first screen.
        _again = v == _page;
        _page = v;
      }),
      items: const [
        DsTopNavItem(value: 0, label: Text('Radio')),
        DsTopNavItem(value: 1, label: Text('Podcasts')),
        DsTopNavItem(value: 2, label: Text('TV')),
      ],
    ),
    // #endregion
  );
}

class _IconsDemo extends StatefulWidget {
  const _IconsDemo();

  @override
  State<_IconsDemo> createState() => _IconsDemoState();
}

class _IconsDemoState extends State<_IconsDemo> {
  int _page = 1;

  @override
  Widget build(BuildContext context) => HeaderFrame(
    title: _titles[_page],
    // #region top-nav-icons
    nav: DsTopNav<int>(
      value: _page,
      onChanged: (v) => setState(() => _page = v),
      items: const [
        DsTopNavItem(
          value: 0,
          icon: DsIcon(DsIcons.radio),
          label: Text('Radio'),
        ),
        DsTopNavItem(
          value: 1,
          icon: DsIcon(DsIcons.mic),
          label: Text('Podcasts'),
        ),
        DsTopNavItem(
          value: 2,
          icon: DsIcon(DsIcons.monitorPlay),
          label: Text('TV'),
        ),
      ],
    ),
    // #endregion
  );
}

class _OverflowDemo extends StatefulWidget {
  const _OverflowDemo();

  @override
  State<_OverflowDemo> createState() => _OverflowDemoState();
}

class _OverflowDemoState extends State<_OverflowDemo> {
  int _page = 4;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 380,
      child: HeaderFrame(
        title: _titles[_page],
        // #region top-nav-overflow
        nav: DsTopNav<int>(
          value: _page,
          onChanged: (v) => setState(() => _page = v),
          items: [
            for (var i = 0; i < _titles.length; i++)
              DsTopNavItem(value: i, label: Text(_titles[i])),
          ],
        ),
        // #endregion
      ),
    ),
  );
}

class _DisabledDemo extends StatefulWidget {
  const _DisabledDemo();

  @override
  State<_DisabledDemo> createState() => _DisabledDemoState();
}

class _DisabledDemoState extends State<_DisabledDemo> {
  int _page = 0;

  @override
  Widget build(BuildContext context) => HeaderFrame(
    title: _titles[_page],
    // #region top-nav-disabled
    nav: DsTopNav<int>(
      value: _page,
      onChanged: (v) => setState(() => _page = v),
      items: const [
        DsTopNavItem(value: 0, label: Text('Radio')),
        DsTopNavItem(value: 1, label: Text('Podcasts')),
        // Not available in this region.
        DsTopNavItem(value: 2, label: Text('TV'), enabled: false),
        DsTopNavItem(value: 3, label: Text('Library')),
      ],
    ),
    // #endregion
  );
}
