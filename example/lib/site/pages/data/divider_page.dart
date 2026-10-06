import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class DividerPage extends StatelessWidget {
  const DividerPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'Divider',
    lead:
        'A thin line between rows, sections or groups of controls, in the '
        'same color as every other divider and outline. Reach for space '
        'first: a divider is for when items sit close enough that spacing '
        'alone does not separate them. Lists, menus and toolbars already '
        'draw their own; see [List](/components/list), '
        '[Menu](/components/menu) and [Toolbar](/components/toolbar).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'divider-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Builder(
                builder: (context) {
                  final t = DsTheme.of(context);
                  final text = t.typography.body.copyWith(color: t.colors.text);
                  // #region divider-overview
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text('Account', style: text),
                      const DsDivider(),
                      Text('Notifications', style: text),
                    ],
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Inset',
        children: [
          const DocText(
            'An `indent` keeps the line clear of a leading icon or avatar, '
            'so it starts under the text it separates. It is on the '
            'leading edge, so it moves to the right in right-to-left '
            'languages. `endIndent` insets the other end.',
          ),
          Example(
            snippet: 'divider-inset',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Builder(
                builder: (context) {
                  final t = DsTheme.of(context);
                  Widget row(DsIconData icon, String label) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      spacing: 12,
                      children: [
                        DsIcon(icon, color: t.colors.textMuted),
                        Text(
                          label,
                          style: t.typography.body.copyWith(
                            color: t.colors.text,
                          ),
                        ),
                      ],
                    ),
                  );
                  return Column(
                    children: [
                      row(DsIcons.user, 'Profile'),
                      // #region divider-inset
                      // Starts under the label: icon 16 + gap 12.
                      const DsDivider(indent: 28),
                      // #endregion
                      row(DsIcons.bell, 'Notifications'),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Vertical',
        children: [
          const DocText(
            '`DsDivider.vertical` separates items in a row. It is as tall '
            'as the row lets it be, so give the row a height or wrap it in '
            'an `IntrinsicHeight`, which makes it as tall as its tallest '
            'item.',
          ),
          Example(
            snippet: 'divider-vertical',
            // #region divider-vertical
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  DsButton(
                    variant: .ghost,
                    onPressed: () {},
                    child: const Text('Edit'),
                  ),
                  const DsDivider.vertical(indent: 8, endIndent: 8),
                  DsButton(
                    variant: .ghost,
                    onPressed: () {},
                    child: const Text('Share'),
                  ),
                ],
              ),
            ),
            // #endregion
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'The line takes the theme\'s `border` color. Change the '
            'thickness, color or insets of one '
            'divider with a `DsDividerStyle`, or of every divider below a '
            'point with `DsDividerTheme`.',
          ),
          Example(
            snippet: 'divider-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Builder(
                builder: (context) {
                  // #region divider-custom
                  final k = DsTheme.colorsOf(context);
                  return Column(
                    spacing: 16,
                    children: [
                      DsDivider(
                        style: DsDividerStyle(
                          thickness: 2,
                          color: k.accentText,
                        ),
                      ),
                      DsDividerTheme(
                        data: DsDividerThemeData(
                          style: DsDividerStyle(color: k.borderControl),
                        ),
                        child: const DsDivider(),
                      ),
                    ],
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Decorative: a divider adds nothing for screen readers. The '
                'structure it draws should also come from headings, '
                'section labels or a list.',
            'The default color is a soft line for grouping, not a '
                'boundary someone has to see to use the page.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'DsDivider()',
              'constructor',
              'A horizontal line as wide as its parent allows.',
            ),
            (
              'DsDivider.vertical()',
              'constructor',
              'A vertical line as tall as its parent allows.',
            ),
            (
              'indent',
              'double?',
              'Inset at the start: leading edge, or top when vertical.',
            ),
            (
              'endIndent',
              'double?',
              'Inset at the end: trailing edge, or bottom when vertical.',
            ),
            (
              'style',
              'DsDividerStyle?',
              '`thickness` (default 1), `color` (default `border`), '
                  '`indent`, `endIndent`.',
            ),
          ]),
        ],
      ),
    ],
  );
}
