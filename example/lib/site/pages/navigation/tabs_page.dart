import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class TabsPage extends StatelessWidget {
  const TabsPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Tabs',
    lead:
        'Moves between sections of the same page, such as the parts of a '
        'settings screen. To change how one set of content is shown, use a '
        '[Segmented control](/components/segmented-control); to move between '
        'pages of an app, a [Sidebar](/components/sidebar) or '
        '[Bottom navigation](/components/bottom-navigation).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'The bar only selects. Show the matching content below it '
            'yourself, keyed by the same value. The underline springs to the '
            'selected tab, and every label keeps the same weight, so nothing '
            'shifts.',
          ),
          Example(
            snippet: 'tabs-overview',
            padding: EdgeInsets.all(24),
            child: _SettingsDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Counts',
        children: [
          DocText(
            '`count` adds a neutral number after the label, such as members '
            'or open items. It is read as part of the tab. Counts above 99 '
            'show as "99+", on screen and for screen readers.',
          ),
          Example(
            snippet: 'tabs-counts',
            padding: EdgeInsets.all(24),
            child: _CountsDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Overflow',
        children: [
          DocText(
            'Tabs that do not fit scroll sideways. The edge that hides tabs '
            'fades out, and a newly selected tab scrolls into view. Keep '
            'labels short so most of them fit.',
          ),
          Example(
            snippet: 'tabs-overflow',
            padding: EdgeInsets.all(24),
            child: _OverflowDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Disabled',
        children: [
          DocText(
            '`enabled: false` turns off one tab; arrow keys skip it. A null '
            '`onChanged` disables the whole bar.',
          ),
          Example(
            snippet: 'tabs-disabled',
            padding: EdgeInsets.all(24),
            child: _DisabledDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one bar with `style`, or every bar in a subtree with '
            '`DsTabsTheme`. `padding` sets the inset of the first and last '
            'tab, `gap` the space between tabs, and `dividerColor` the '
            'hairline under the bar.',
          ),
          Example(
            snippet: 'tabs-custom',
            padding: EdgeInsets.all(24),
            child: _CustomDemo(),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocText(
            'The bar is one Tab stop; the arrows move the selection, which '
            'moves the content with it.',
          ),
          KeyboardTable([
            (
              'Tab',
              'Moves focus to the bar; the ring shows on the selected tab.',
            ),
            (
              'Right / Left',
              'Selects the next or previous tab, skipping disabled ones and '
                  'wrapping around. Mirrored in right-to-left layouts.',
            ),
            ('Home / End', 'Selects the first or last enabled tab.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a tab bar, named by `semanticLabel`, with each tab '
                'as a tab and the selected one marked selected.',
            'On iOS and Android each tab also reads its position after its '
                'label ("Tab 2 of 4", localized); on the web the tab role '
                'tells the position.',
            'Focus is reported on the selected tab, so a screen reader names '
                'it when the bar takes focus.',
            'The underline stands 3:1 against the surface, also under a '
                'bright accent.',
            'The keyboard focus ring stands clear of the label, so accents '
                'above capitals stay visible.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsTabs'),
          ApiTable([
            ('value', 'T', 'The selected value.'),
            (
              'onChanged',
              'ValueChanged<T>?',
              'Called with the newly selected value. Null disables the bar.',
            ),
            ('tabs', 'List<DsTab<T>>', 'The tabs, start to end.'),
            ('semanticLabel', 'String?', 'Names the bar for screen readers.'),
            ('style', 'DsTabsStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsTab'),
          ApiTable([
            ('value', 'T', 'The value this tab selects.'),
            ('label', 'Widget', 'A short `Text`.'),
            ('count', 'int?', 'A neutral number after the label.'),
            ('enabled', 'bool', 'Whether the tab can be selected.'),
            (
              'semanticLabel',
              'String?',
              'Overrides the label screen readers announce.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// A card that clips its children to its corners, for a bar that runs
/// edge to edge.
class _Flush extends StatelessWidget {
  const _Flush({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: DsCard(
      style: const DsCardStyle(padding: EdgeInsets.zero),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsTheme.of(context).radii.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

/// The body of a tab: a heading and a line of text.
class _Panel extends StatelessWidget {
  const _Panel(this.title, this.body);

  final String title, body;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            title,
            style: t.typography.heading.copyWith(color: t.colors.text),
          ),
          Text(
            body,
            style: t.typography.body.copyWith(color: t.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingsDemo extends StatefulWidget {
  const _SettingsDemo();

  @override
  State<_SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<_SettingsDemo> {
  String _tab = 'general';

  static const _panels = {
    'general': ('General', 'Project name, URL and default language.'),
    'members': ('Members', 'Invite people and set what each of them can do.'),
    'billing': ('Billing', 'Your plan, payment method and past invoices.'),
  };

  @override
  Widget build(BuildContext context) {
    final (title, body) = _panels[_tab]!;
    return _Flush(
      children: [
        // #region tabs-overview
        DsTabs<String>(
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
          semanticLabel: 'Project settings',
          tabs: const [
            DsTab(value: 'general', label: Text('General')),
            DsTab(value: 'members', label: Text('Members')),
            DsTab(value: 'billing', label: Text('Billing')),
          ],
        ),
        // #endregion
        _Panel(title, body),
      ],
    );
  }
}

class _CountsDemo extends StatefulWidget {
  const _CountsDemo();

  @override
  State<_CountsDemo> createState() => _CountsDemoState();
}

class _CountsDemoState extends State<_CountsDemo> {
  String _tab = 'open';

  @override
  Widget build(BuildContext context) => _Flush(
    children: [
      // #region tabs-counts
      DsTabs<String>(
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
        semanticLabel: 'Issues',
        tabs: const [
          DsTab(value: 'open', label: Text('Open'), count: 24),
          DsTab(value: 'review', label: Text('In review'), count: 3),
          DsTab(value: 'closed', label: Text('Closed'), count: 418),
        ],
      ),
      // #endregion
      const _Sketch(),
    ],
  );
}

class _OverflowDemo extends StatefulWidget {
  const _OverflowDemo();

  @override
  State<_OverflowDemo> createState() => _OverflowDemoState();
}

class _OverflowDemoState extends State<_OverflowDemo> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: _Flush(
      children: [
        // #region tabs-overflow
        DsTabs<String>(
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
          semanticLabel: 'Repository',
          tabs: const [
            DsTab(value: 'overview', label: Text('Overview')),
            DsTab(value: 'issues', label: Text('Issues')),
            DsTab(value: 'pulls', label: Text('Pull requests')),
            DsTab(value: 'actions', label: Text('Actions')),
            DsTab(value: 'wiki', label: Text('Wiki')),
            DsTab(value: 'settings', label: Text('Settings')),
          ],
        ),
        // #endregion
        const _Sketch(),
      ],
    ),
  );
}

class _DisabledDemo extends StatefulWidget {
  const _DisabledDemo();

  @override
  State<_DisabledDemo> createState() => _DisabledDemoState();
}

class _DisabledDemoState extends State<_DisabledDemo> {
  String _tab = 'profile';

  @override
  Widget build(BuildContext context) => _Flush(
    children: [
      // #region tabs-disabled
      DsTabs<String>(
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
        semanticLabel: 'Account',
        tabs: const [
          DsTab(value: 'profile', label: Text('Profile')),
          DsTab(value: 'security', label: Text('Security')),
          DsTab(value: 'sso', label: Text('Single sign-on'), enabled: false),
        ],
      ),
      // #endregion
      const _Sketch(),
    ],
  );
}

class _CustomDemo extends StatefulWidget {
  const _CustomDemo();

  @override
  State<_CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<_CustomDemo> {
  String _tab = 'activity';

  @override
  Widget build(BuildContext context) => _Flush(
    children: [
      // #region tabs-custom
      DsTabs<String>(
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
        semanticLabel: 'Task',
        style: const DsTabsStyle(
          height: 40,
          gap: 16,
          padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
          indicatorHeight: 3,
          indicatorColor: Color(0xFF0B6E4F),
        ),
        tabs: const [
          DsTab(value: 'activity', label: Text('Activity')),
          DsTab(value: 'comments', label: Text('Comments'), count: 5),
          DsTab(value: 'files', label: Text('Files')),
        ],
      ),
      // #endregion
      const _Sketch(),
    ],
  );
}

/// Two skeleton lines: the body of a tab that is not the point.
class _Sketch extends StatelessWidget {
  const _Sketch();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          FractionallySizedBox(
            widthFactor: .72,
            child: DsSkeleton(strong: true),
          ),
          FractionallySizedBox(widthFactor: .48, child: DsSkeleton()),
        ],
      ),
    ),
  );
}
