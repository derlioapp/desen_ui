import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import 'frame.dart';

class BottomNavPage extends StatelessWidget {
  const BottomNavPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Bottom navigation',
    lead:
        'The main navigation of a phone app: three to five destinations '
        'along the bottom of the screen, each with an icon and a short '
        'label. On wider screens, use a [Sidebar](/components/sidebar).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The default `floating` variant is an opaque bar that floats '
            'above the content, centered, and sizes to its items. The '
            'selected destination is filled with the theme\'s selection '
            'style.',
          ),
          Example(
            snippet: 'bottom-nav-overview',
            padding: EdgeInsets.all(16),
            child: _FloatingDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Full-width bar',
        children: [
          DocText(
            'The `bar` variant runs edge to edge along the bottom, with a '
            'hairline on top. It adds the bottom safe area to its padding, '
            'so the items stay clear of the home indicator.',
          ),
          Example(
            snippet: 'bottom-nav-bar',
            padding: EdgeInsets.all(16),
            child: _BarDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Five destinations',
        children: [
          DocText(
            'Floating items are 72px wide. When five do not fit, as on a '
            '375px phone, they share the width evenly. A long label wraps '
            'onto a second line between words, and every item keeps room for '
            'two lines so the bar stays even; a word that still does not fit '
            'ellipsizes, and the item then shows its whole label in a tooltip '
            'on a long press. Keep labels to one short word. With large text, '
            'the items grow taller.',
          ),
          Example(
            snippet: 'bottom-nav-five',
            padding: EdgeInsets.all(16),
            child: _FiveDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Disabled destination',
        children: [
          DocText(
            '`enabled: false` on an item dims it and keeps it from being '
            'chosen: taps, Tab and the arrow keys pass it by, and screen '
            'readers announce it as disabled. A null `onChanged` disables '
            'the whole bar.',
          ),
          Example(
            snippet: 'bottom-nav-disabled',
            padding: EdgeInsets.all(16),
            child: _DisabledDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            '`style` changes the container and `itemStyle` the destinations; '
            '`DsBottomNavTheme` and `DsBottomNavItemTheme` do the same for a '
            'subtree, with a style per variant in `variants`; '
            '`DsBottomNavTheme` also sets the default `variant`. Set '
            '`capsuleSize` to mark the selected destination with a capsule '
            'behind the icon instead of filling the whole item.',
          ),
          Example(
            snippet: 'bottom-nav-custom',
            padding: EdgeInsets.all(16),
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
              'Moves focus into the bar, to the current destination, and '
                  'out of it: the bar is one Tab stop.',
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
              'Opens the focused destination. Each one swaps the whole '
                  'screen, so moving focus alone never does.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The bar is a navigation landmark named by `semanticLabel`, or '
                'the localized "Navigation" by default, holding a tab bar.',
            'Each destination is a tab, announced with its label and, on '
                'iOS and Android, its position ("Tab 2 of 4", localized); on '
                'the web the tab role tells the position. The current one is '
                'announced as selected and a disabled one as disabled. '
                '`semanticLabel` on an item overrides its label.',
            'A tap plays the selection haptic, or the command one on the '
                'current destination; the keyboard plays none.',
            'The selected destination is marked by a fill and a semibold '
                'label, not by color alone.',
            'Destinations are 50px tall (52px in the full-width bar), above '
                'the 44px touch minimum.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsBottomNav'),
          ApiTable([
            (
              'items',
              'List<DsBottomNavItem<T>>',
              'The destinations, start to end.',
            ),
            ('value', 'T', 'The current destination\'s value.'),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the chosen value. Null disables the bar.',
            ),
            (
              'variant',
              'DsBottomNavVariant?',
              '`floating` or `bar`. Defaults to the theme\'s, then '
                  '`floating`.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the navigation; the localized "Navigation" by default.',
            ),
            (
              'focusNode',
              'FocusNode?',
              'Stands for the bar; focusing it focuses the current '
                  'destination.',
            ),
            ('autofocus', 'bool', 'Focuses the current destination at first.'),
            ('style', 'DsBottomNavStyle?', 'The container\'s style.'),
            ('itemStyle', 'DsBottomNavItemStyle?', 'The destinations\' style.'),
          ]),
          DocHeading('DsBottomNavItem'),
          ApiTable([
            ('value', 'T', 'The value this destination selects.'),
            ('icon', 'Widget', 'Usually a `DsIcon`.'),
            ('label', 'Widget', 'A short `Text` under the icon.'),
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

const _titles = ['Home', 'Inbox', 'Calendar', 'Profile', 'Search'];

class _FloatingDemo extends StatefulWidget {
  const _FloatingDemo();

  @override
  State<_FloatingDemo> createState() => _FloatingDemoState();
}

class _FloatingDemoState extends State<_FloatingDemo> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => PhoneFrame(
    title: _titles[_tab],
    // #region bottom-nav-overview
    bar: DsBottomNav<int>(
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
      semanticLabel: 'Main',
      items: const [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Home'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Inbox'),
        ),
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Calendar'),
        ),
        DsBottomNavItem(
          value: 3,
          icon: DsIcon(DsIcons.user),
          label: Text('Profile'),
        ),
      ],
    ),
    // #endregion
  );
}

class _BarDemo extends StatefulWidget {
  const _BarDemo();

  @override
  State<_BarDemo> createState() => _BarDemoState();
}

class _BarDemoState extends State<_BarDemo> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) => PhoneFrame(
    title: _titles[_tab],
    floating: false,
    // #region bottom-nav-bar
    bar: DsBottomNav<int>(
      variant: DsBottomNavVariant.bar,
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
      semanticLabel: 'Main',
      items: const [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Home'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Inbox'),
        ),
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Calendar'),
        ),
        DsBottomNavItem(
          value: 3,
          icon: DsIcon(DsIcons.user),
          label: Text('Profile'),
        ),
      ],
    ),
    // #endregion
  );
}

class _FiveDemo extends StatefulWidget {
  const _FiveDemo();

  @override
  State<_FiveDemo> createState() => _FiveDemoState();
}

class _FiveDemoState extends State<_FiveDemo> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => PhoneFrame(
    title: _titles[_tab],
    // #region bottom-nav-five
    bar: DsBottomNav<int>(
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
      semanticLabel: 'Main',
      items: const [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Home'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Inbox'),
        ),
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Calendar'),
        ),
        DsBottomNavItem(
          value: 3,
          icon: DsIcon(DsIcons.user),
          label: Text('Profile'),
        ),
        DsBottomNavItem(
          value: 4,
          icon: DsIcon(DsIcons.search),
          label: Text('Search'),
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
  int _tab = 0;

  @override
  Widget build(BuildContext context) => PhoneFrame(
    title: _titles[_tab],
    floating: false,
    // #region bottom-nav-custom
    bar: DsBottomNav<int>(
      variant: DsBottomNavVariant.bar,
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
      semanticLabel: 'Main',
      itemStyle: const DsBottomNavItemStyle(capsuleSize: Size(56, 30)),
      items: const [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Home'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Inbox'),
        ),
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Calendar'),
        ),
      ],
    ),
    // #endregion
  );
}

class _DisabledDemo extends StatefulWidget {
  const _DisabledDemo();

  @override
  State<_DisabledDemo> createState() => _DisabledDemoState();
}

class _DisabledDemoState extends State<_DisabledDemo> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => PhoneFrame(
    title: _titles[_tab],
    // #region bottom-nav-disabled
    bar: DsBottomNav<int>(
      value: _tab,
      onChanged: (v) => setState(() => _tab = v),
      semanticLabel: 'Main',
      items: const [
        DsBottomNavItem(
          value: 0,
          icon: DsIcon(DsIcons.house),
          label: Text('Home'),
        ),
        DsBottomNavItem(
          value: 1,
          icon: DsIcon(DsIcons.inbox),
          label: Text('Inbox'),
        ),
        // Not available until the account is verified.
        DsBottomNavItem(
          value: 2,
          icon: DsIcon(DsIcons.calendar),
          label: Text('Calendar'),
          enabled: false,
        ),
        DsBottomNavItem(
          value: 3,
          icon: DsIcon(DsIcons.user),
          label: Text('Profile'),
        ),
      ],
    ),
    // #endregion
  );
}
