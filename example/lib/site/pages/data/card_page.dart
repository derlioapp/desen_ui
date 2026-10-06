import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class CardPage extends StatelessWidget {
  const CardPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'Card',
    lead:
        'A surface with a hairline edge and rounded corners that holds one '
        'piece of content: a project, a plan, a summary. Make it pressable '
        'when the whole card opens something. For many records of the same '
        'shape, use a [Table](/components/table) or a '
        '[List](/components/list).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'card-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: const _UsageCard(),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Pressable cards',
        children: [
          const DocText(
            'With `onPressed` the whole card is one button. Hovering lifts '
            'it with a stronger shadow, and keyboard focus draws the focus '
            'ring. Give it a `semanticLabel`: screen readers then hear that '
            'name instead of every line inside.',
          ),
          const Example(snippet: 'card-pressable', child: _ProjectCards()),
        ],
      ),
      DocSection(
        title: 'Padding and media',
        children: [
          const DocText(
            'The default padding is 16px. Set it to zero for content that '
            'runs to the edge, such as an [Empty state](/components/empty-state) '
            'or a cover image, and pad the text below it yourself.',
          ),
          Example(
            snippet: 'card-padding',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              // #region card-padding
              child: DsCard(
                style: const DsCardStyle(padding: EdgeInsets.zero),
                child: DsEmptyState(
                  icon: const DsIcon(DsIcons.folder),
                  title: const Text('No files yet'),
                  description: const Text(
                    'Upload a brief or drop files here to share them with '
                    'the team.',
                  ),
                  actions: [
                    DsButton(
                      size: .sm,
                      leading: const DsIcon(DsIcons.upload),
                      onPressed: () {},
                      child: const Text('Upload'),
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
        title: 'Dashed slot',
        children: [
          const DocText(
            '`dashed: true` turns the card into an empty slot: no fill or '
            'shadow, a dashed outline in the form boundary color (3:1, as a '
            'text field\'s edge) that follows the card corners. Use it for a '
            'place to add something or to drop something onto. Pressable, it '
            'fills and its outline darkens on hover; style it under '
            '`DsCardStyle.dashed` (`borderColor`, '
            '`borderWidth`, `dashLength`, `dashGap`).',
          ),
          Example(
            snippet: 'card-dashed',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Builder(
                builder: (context) {
                  // #region card-dashed
                  // In a build method:
                  final t = DsTheme.of(context);
                  return DsCard(
                    dashed: true,
                    onPressed: () {},
                    semanticLabel: 'Add a widget',
                    child: SizedBox(
                      height: 96,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: [
                          DsIcon(DsIcons.plus, color: t.colors.textMuted),
                          Text(
                            'Add a widget',
                            style: t.typography.small.copyWith(
                              color: t.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one card with `style`, or every card below a point with '
            '`DsCardTheme`. `hovered`, `pressed` and `focused` nest inside '
            'the style. Shadows are `DsShadow` lists, so a card can drop its '
            'edge or take a heavier one.',
          ),
          Example(
            snippet: 'card-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Builder(
                builder: (context) {
                  // #region card-custom
                  // Theme colors:
                  final k = DsTheme.colorsOf(context);
                  return DsCard(
                    style: DsCardStyle(
                      background: k.accentTint,
                      shadows: const [],
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Your trial ends in 5 days. Pick a plan to keep your '
                      'projects.',
                      style: TextStyle(color: k.accentText),
                    ),
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          DocText('A card without `onPressed` is not focusable.'),
          KeyboardTable([
            ('Tab', 'Moves focus to a pressable card.'),
            ('Enter / Space', 'Presses the card.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'A pressable card is announced as a button. With '
                '`semanticLabel`, that name replaces what is inside; '
                'without it, the content is read as the label.',
            'A static card adds nothing for screen readers; its content '
                'reads as it is.',
            'Keep other buttons out of a pressable card. For a card with '
                'several actions, leave the card static and give each action '
                'its own button.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('child', 'Widget', 'The content.'),
            ('onPressed', 'VoidCallback?', 'Makes the whole card pressable.'),
            (
              'dashed',
              'bool',
              'Draws an empty slot with a dashed outline. Default `false`.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names a pressable card for screen readers.',
            ),
            ('style', 'DsCardStyle?', 'Laid over the theme and defaults.'),
            ('focusNode', 'FocusNode?', 'Focus node of a pressable card.'),
            (
              'statesController',
              'WidgetStatesController?',
              'Observes or forces hovered, focused and pressed.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context) {
    // #region card-overview
    // In a build method:
    final t = DsTheme.of(context);
    final muted = t.typography.small.copyWith(color: t.colors.textMuted);
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Storage',
                  style: t.typography.heading.copyWith(color: t.colors.text),
                ),
              ),
              const DsBadge(status: .warning, label: Text('92% full')),
            ],
          ),
          const DsProgressBar(value: .92, semanticLabel: 'Storage used'),
          Text('18.4 GB of 20 GB used. Large files: 6.2 GB.', style: muted),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DsButton(
              variant: .secondary,
              size: .sm,
              onPressed: () {},
              child: const Text('Manage storage'),
            ),
          ),
        ],
      ),
    );
    // #endregion
  }
}

class _ProjectCards extends StatelessWidget {
  const _ProjectCards();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final titleStyle = t.typography.heading.copyWith(color: t.colors.text);
    final mutedStyle = t.typography.small.copyWith(color: t.colors.textMuted);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: 260,
          // #region card-pressable
          child: DsCard(
            semanticLabel: 'Q4 roadmap, 12 tasks, 3 days left',
            onPressed: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                const DsAvatar(initials: 'Q4', size: .sm, toneIndex: 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text('Q4 roadmap', style: titleStyle),
                    Text('12 tasks · 3 days left', style: mutedStyle),
                  ],
                ),
                const DsProgressBar(value: .58),
              ],
            ),
          ),
          // #endregion
        ),
        SizedBox(
          width: 260,
          child: DsCard(
            semanticLabel: 'Website refresh, 8 tasks, 2 weeks left',
            onPressed: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                const DsAvatar(initials: 'WR', size: .sm, toneIndex: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text('Website refresh', style: titleStyle),
                    Text('8 tasks · 2 weeks left', style: mutedStyle),
                  ],
                ),
                const DsProgressBar(value: .25),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
