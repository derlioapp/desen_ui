import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class BreadcrumbPage extends StatelessWidget {
  const BreadcrumbPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Breadcrumb',
    lead:
        'Shows where a page sits in a hierarchy and leads back up it: '
        'folders, a project\'s settings, a product category. It works best '
        'at the top of a pane, often as the title of a '
        '[Pane header](/components/pane-header).',
    sections: [
      const DocSection(
        title: 'Overview',
        children: [
          DocText(
            'Upper levels are links in muted ink; the last item is the '
            'current page, in full ink and not pressable. Chevrons separate '
            'the levels and mirror in right-to-left layouts.',
          ),
          Example(snippet: 'breadcrumb-overview', child: _FolderDemo()),
        ],
      ),
      const DocSection(
        title: 'Icons',
        children: [
          DocText(
            'A level can lead with an `icon`, such as a house on the first '
            'level. It takes the label\'s color and the style\'s `iconSize` '
            '(14 by default), and stays with its level when the path wraps '
            'or collapses; the "…" menu shows it too. The label still names '
            'the level for screen readers.',
          ),
          Example(snippet: 'breadcrumb-icons', child: _IconDemo()),
        ],
      ),
      const DocSection(
        title: 'Long paths',
        children: [
          DocText(
            '`overflow` decides what a path that does not fit does. '
            '`DsBreadcrumbOverflow.wrap` moves it onto more lines. Each '
            'chevron stays with the level before it, so no line starts with '
            'a chevron.',
          ),
          DocText(
            '`DsBreadcrumbOverflow.collapse` keeps the path on one line. The '
            'first level and as many of the last as fit stay; the middle '
            'ones go behind a "…" button that lists them in a menu. When '
            'even "first › … › current" does not fit, only "… › current" '
            'shows, and the current page is cut with an ellipsis.',
          ),
          DocText(
            'Without `overflow`, a breadcrumb collapses where its text keeps '
            'to one line, as in a [Pane header](/components/pane-header) '
            'title, and wraps elsewhere. Keep level names short either way.',
          ),
          Example(snippet: 'breadcrumb-long', child: _LongDemo()),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Change one breadcrumb with `style`, or every one in a subtree '
            'with `DsBreadcrumbTheme`. `selected` is the current page\'s '
            'look; `separatorColor` and `separatorSize` style the chevrons.',
          ),
          Example(snippet: 'breadcrumb-custom', child: _CustomDemo()),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves through the upper levels and the "…" button; each one '
                  'is a Tab stop. The current page is not.',
            ),
            ('Enter', 'Opens the focused level.'),
            (
              'Space',
              'Does nothing on a level, as on links in browsers; on the web '
                  'the page scrolls.',
            ),
            (
              'Enter / Space on "…"',
              'Opens the menu of the hidden levels. Arrows move through it, '
                  'Enter opens one, Escape closes it.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a navigation named "Breadcrumb", in the app\'s '
                'language; rename it with `semanticLabel`.',
            'Upper levels are announced as links. The last item is '
                'announced with "Current page".',
            'The chevrons are hidden from screen readers.',
            'The "…" button is a menu button named "More levels", announced '
                'as expanded or collapsed. Its menu lists the hidden levels '
                'by name.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsBreadcrumb'),
          ApiTable([
            (
              'items',
              'List<DsBreadcrumbItem>',
              'The levels, top first; the last is the current page.',
            ),
            (
              'overflow',
              'DsBreadcrumbOverflow?',
              '`wrap` or `collapse`. Null collapses where text keeps to one '
                  'line and wraps elsewhere.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the navigation; defaults to "Breadcrumb".',
            ),
            (
              'style',
              'DsBreadcrumbStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
          DocHeading('DsBreadcrumbItem'),
          ApiTable([
            ('label', 'String', 'The level\'s name.'),
            ('icon', 'Widget?', 'An icon before the label.'),
            (
              'onPressed',
              'VoidCallback?',
              'Opens the level. Ignored on the last item.',
            ),
          ]),
        ],
      ),
    ],
  );
}

const _folders = {
  'Drive': ['Marketing', 'Engineering'],
  'Marketing': ['Campaigns', 'Brand'],
  'Campaigns': ['Spring launch', 'Webinars'],
  'Engineering': ['Specs', 'Postmortems'],
};

class _FolderDemo extends StatefulWidget {
  const _FolderDemo();

  @override
  State<_FolderDemo> createState() => _FolderDemoState();
}

class _FolderDemoState extends State<_FolderDemo> {
  final _path = ['Drive', 'Marketing', 'Campaigns'];

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final inside = _folders[_path.last] ?? const <String>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        // #region breadcrumb-overview
        DsBreadcrumb(
          items: [
            for (final (i, name) in _path.indexed)
              DsBreadcrumbItem(
                label: name,
                onPressed: () =>
                    setState(() => _path.removeRange(i + 1, _path.length)),
              ),
          ],
        ),
        // #endregion
        if (inside.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Text(
              'This folder has no subfolders.',
              style: t.typography.small.copyWith(color: t.colors.textMuted),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in inside)
                DsButton(
                  variant: DsButtonVariant.secondary,
                  size: DsSize.sm,
                  leading: const DsIcon(DsIcons.folder),
                  onPressed: () => setState(() => _path.add(name)),
                  child: Text(name),
                ),
            ],
          ),
      ],
    );
  }
}

class _IconDemo extends StatelessWidget {
  const _IconDemo();

  @override
  Widget build(BuildContext context) =>
      // #region breadcrumb-icons
      DsBreadcrumb(
        items: [
          DsBreadcrumbItem(
            label: 'Home',
            icon: const DsIcon(DsIcons.house),
            onPressed: () {},
          ),
          DsBreadcrumbItem(label: 'Projects', onPressed: () {}),
          const DsBreadcrumbItem(label: 'Website redesign'),
        ],
      );
  // #endregion
}

class _LongDemo extends StatelessWidget {
  const _LongDemo();

  @override
  Widget build(BuildContext context) {
    // #region breadcrumb-long
    // One path, both overflow modes:
    final path = [
      DsBreadcrumbItem(label: 'Acme', onPressed: () {}),
      DsBreadcrumbItem(label: 'Website redesign', onPressed: () {}),
      DsBreadcrumbItem(label: 'Settings', onPressed: () {}),
      DsBreadcrumbItem(label: 'Integrations', onPressed: () {}),
      const DsBreadcrumbItem(label: 'Webhooks'),
    ];
    return Wrap(
      spacing: 40,
      runSpacing: 24,
      children: [
        SizedBox(
          width: 260,
          child: DsBreadcrumb(overflow: .wrap, items: path),
        ),
        SizedBox(
          width: 260,
          child: DsBreadcrumb(overflow: .collapse, items: path),
        ),
      ],
    );
    // #endregion
  }
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) =>
      // #region breadcrumb-custom
      DsBreadcrumb(
        style: const DsBreadcrumbStyle(
          textStyle: TextStyle(fontSize: 15),
          separatorSize: 16,
          gap: 6,
          selected: DsBreadcrumbStyle(foreground: Color(0xFF0B6E4F)),
        ),
        items: [
          DsBreadcrumbItem(label: 'Store', onPressed: () {}),
          DsBreadcrumbItem(label: 'Furniture', onPressed: () {}),
          const DsBreadcrumbItem(label: 'Desks'),
        ],
      );
  // #endregion
}
