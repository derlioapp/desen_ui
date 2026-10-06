import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class EmptyStatePage extends StatelessWidget {
  const EmptyStatePage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'Empty state',
    lead:
        'Fills a list, table or pane that has nothing to show yet, and '
        'says what to do next. Write the title as an invitation and offer '
        'the one action that fills the space.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'empty-state-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // #region empty-state-overview
              child: DsCard(
                style: const DsCardStyle(padding: EdgeInsets.zero),
                child: DsEmptyState(
                  icon: const DsIcon(DsIcons.inbox),
                  title: const Text('No tasks yet'),
                  description: const Text(
                    'Add your first task or start from a template.',
                  ),
                  actions: [
                    DsButton(
                      size: .sm,
                      onPressed: () {},
                      child: const Text('Add task'),
                    ),
                    DsButton(
                      variant: .ghost,
                      size: .sm,
                      onPressed: () {},
                      child: const Text('Templates'),
                    ),
                  ],
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'No results',
        children: [
          const DocText(
            'When a search or filter finds nothing, say what was searched and '
            'offer a way back. Use a quieter action than for a first-run '
            'state: the content exists, it is only hidden.',
          ),
          Example(
            snippet: 'empty-state-search',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // #region empty-state-search
              child: DsEmptyState(
                icon: const DsIcon(DsIcons.searchX),
                title: const Text('No matches for "invoice 2025"'),
                description: const Text(
                  'Check the spelling or search all projects.',
                ),
                actions: [
                  DsButton(
                    variant: .secondary,
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Clear search'),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Without an icon or actions',
        children: [
          const DocText(
            'Every part but the title is optional. A short message with no '
            'action suits panes that fill on their own, such as an activity '
            'feed.',
          ),
          Example(
            snippet: 'empty-state-minimal',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // #region empty-state-minimal
              child: const DsEmptyState(
                title: Text('No activity this week'),
                description: Text('Changes your team makes show up here.'),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'In a table',
        children: [
          const DocText(
            'A [Table](/components/table) shows its `emptyView` when it has '
            'no rows. It gives the slot a compact theme, with a small icon '
            'and no tone disk, so the same `DsEmptyState` fits a table row '
            'area.',
          ),
          Example(
            snippet: 'empty-state-table',
            padding: const EdgeInsets.all(16),
            // #region empty-state-table
            child: DsTable<String>(
              semanticLabel: 'Members',
              rows: const [],
              rowKey: (name) => name,
              columns: [
                DsTableColumn(id: 'name', label: 'Name', value: (n) => n),
              ],
              emptyView: DsEmptyState(
                icon: const DsIcon(DsIcons.user),
                title: const Text('No members match "Active"'),
                actions: [
                  DsButton(
                    variant: .ghost,
                    size: .xs,
                    onPressed: () {},
                    child: const Text('Show all members'),
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
            'Change one empty state with `style`, or every one below a point '
            'with `DsEmptyStateTheme`. The description wraps at 280px by '
            'default (`descriptionMaxWidth`) to keep lines short.',
          ),
          Example(
            snippet: 'empty-state-custom',
            child: Builder(
              builder: (context) {
                // #region empty-state-custom
                // Theme colors:
                final k = DsTheme.colorsOf(context);
                return DsEmptyState(
                  icon: const DsIcon(DsIcons.circleCheck),
                  title: const Text('All caught up'),
                  description: const Text('You have read every message.'),
                  style: DsEmptyStateStyle(
                    iconBoxColor: k.success.tint,
                    iconColor: k.success.text,
                    iconBoxSize: 56,
                    iconBoxRadius: BorderRadius.circular(28),
                    iconSize: 24,
                  ),
                );
                // #endregion
              },
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The title is announced as a heading, so screen reader users '
                'can find the message by jumping between headings.',
            'The icon is decorative and hidden from screen readers.',
            'Text is centered and the description wraps at 280px, so lines '
                'stay short at any width.',
            'In a table, the empty view is a polite live region: it is '
                'announced when a filter empties the table.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('title', 'Widget', 'What is empty, as an invitation.'),
            ('icon', 'Widget?', 'Shown in the tone disk, usually a `DsIcon`.'),
            ('description', 'Widget?', 'One or two sentences on what to do.'),
            ('actions', 'List<Widget>', 'Buttons; at most one primary.'),
            (
              'style',
              'DsEmptyStateStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
        ],
      ),
    ],
  );
}
