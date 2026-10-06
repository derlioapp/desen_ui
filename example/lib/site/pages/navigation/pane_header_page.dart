import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class PaneHeaderPage extends StatelessWidget {
  const PaneHeaderPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Pane header',
    lead:
        'The top row of a pane: where you are on the start side, the pane\'s '
        'actions on the end side, and a hairline between it and the '
        'content. Use one per pane, above a document, a list or a detail '
        'view.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          const DocText(
            'The title is usually a [Breadcrumb](/components/breadcrumb). '
            'Actions are ordinary buttons; use small ones, with at most one '
            'primary.',
          ),
          Example(
            snippet: 'pane-header-overview',
            padding: const EdgeInsets.all(16),
            child: _Pane(
              // #region pane-header-overview
              header: DsPaneHeader(
                title: DsBreadcrumb(
                  items: [
                    DsBreadcrumbItem(
                      label: 'Website redesign',
                      onPressed: () {},
                    ),
                    const DsBreadcrumbItem(label: 'Launch plan'),
                  ],
                ),
                actions: [
                  DsTooltip(
                    message: 'Share',
                    child: DsButton.icon(
                      variant: .ghost,
                      size: .sm,
                      icon: const DsIcon(DsIcons.share),
                      semanticLabel: 'Share',
                      onPressed: () {},
                    ),
                  ),
                  DsButton(
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Publish'),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Long titles',
        children: [
          const DocText(
            'Any widget can be the title. It takes the width the actions '
            'leave and keeps to one line: a `Text` is cut with an ellipsis, '
            'and a breadcrumb collapses its middle levels into a "…" menu. '
            'These panes are held to 320px.',
          ),
          Example(
            snippet: 'pane-header-text',
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: _Pane(
                // #region pane-header-text
                header: DsPaneHeader(
                  title: const Text('Quarterly planning notes, engineering'),
                  actions: [
                    DsTooltip(
                      message: 'More',
                      child: DsButton.icon(
                        variant: .ghost,
                        size: .sm,
                        icon: const DsIcon(DsIcons.ellipsis),
                        semanticLabel: 'More',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                // #endregion
              ),
            ),
          ),
          Example(
            snippet: 'pane-header-collapse',
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: _Pane(
                // #region pane-header-collapse
                header: DsPaneHeader(
                  title: DsBreadcrumb(
                    items: [
                      DsBreadcrumbItem(label: 'Acme', onPressed: () {}),
                      DsBreadcrumbItem(
                        label: 'Website redesign',
                        onPressed: () {},
                      ),
                      DsBreadcrumbItem(label: 'Launch', onPressed: () {}),
                      const DsBreadcrumbItem(label: 'Press kit'),
                    ],
                  ),
                  actions: [
                    DsButton(
                      size: .sm,
                      onPressed: () {},
                      child: const Text('Publish'),
                    ),
                  ],
                ),
                // #endregion
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one header with `style`, or every one in a subtree with '
            '`DsPaneHeaderTheme`. `height` is a minimum: the row grows with '
            'large text. A transparent `dividerColor` hides the hairline.',
          ),
          Example(
            snippet: 'pane-header-custom',
            padding: const EdgeInsets.all(16),
            child: _Pane(
              // #region pane-header-custom
              header: DsPaneHeader(
                style: const DsPaneHeaderStyle(
                  height: 60,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
                  dividerColor: Color(0x00000000),
                ),
                title: const Text('Inbox'),
                actions: [
                  DsButton(
                    variant: .secondary,
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The row is announced as a header, so screen reader users can '
                'jump to it.',
            'It has no keys of its own. Its title and actions keep theirs: '
                'Tab moves through the breadcrumb levels (and its "…" button '
                'when collapsed), then the actions.',
            'Name icon-only actions with `semanticLabel` and pair them with '
                'a tooltip.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'title',
              'Widget',
              'Usually a `DsBreadcrumb` or a `Text`; takes the remaining '
                  'width on one line.',
            ),
            ('actions', 'List<Widget>', 'Buttons on the end side.'),
            (
              'style',
              'DsPaneHeaderStyle?',
              'Laid over the theme and defaults.',
            ),
          ]),
        ],
      ),
    ],
  );
}

/// A pane: a header over sketched content, in a card.
class _Pane extends StatelessWidget {
  const _Pane({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final radius = BorderRadius.circular(t.radii.card);
    return Container(
      decoration: DsBoxDecoration(
        color: t.colors.surface,
        borderRadius: radius,
        shadows: t.shadows.surface,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DefaultTextStyle.merge(
          style: t.typography.bodyStrong.copyWith(color: t.colors.text),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, const _Lines()],
          ),
        ),
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          FractionallySizedBox(
            widthFactor: .62,
            child: DsSkeleton(strong: true),
          ),
          FractionallySizedBox(widthFactor: .84, child: DsSkeleton()),
          FractionallySizedBox(widthFactor: .4, child: DsSkeleton()),
        ],
      ),
    ),
  );
}
