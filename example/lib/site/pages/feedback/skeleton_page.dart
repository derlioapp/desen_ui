import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// A card's width on a phone.
Widget _cardWidth(Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 340),
  child: child,
);

class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Feedback',
    title: 'Skeleton',
    lead:
        'Gray shapes that stand in for content while it loads, so the '
        'layout does not jump when the content arrives. `DsShimmer` sweeps '
        'a soft light across them. Use a skeleton when you know the shape '
        'of what is coming; for a short wait in a control, use a '
        '[Spinner](/components/spinner).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          const DocText(
            'A comment card while it loads. Turn off the switch to compare it '
            'with the loaded card.',
          ),
          Example(
            snippet: 'skeleton-overview',
            child: _cardWidth(const _CommentDemo()),
          ),
        ],
      ),
      DocSection(
        title: 'Shapes',
        children: [
          const DocText(
            '`DsSkeleton` stands in for a line of text: 8px tall by default '
            'and as wide as its space. Set `width` and `height` to match the '
            'content it stands for. Up to 16px tall '
            '(`DsSkeleton.lineMaxHeight`) it stays fully rounded. '
            '`DsSkeleton.circle` stands in for an avatar, and `strong` uses '
            'the darker tone, for a title line.',
          ),
          const DocText(
            'A taller `DsSkeleton` is a block, such as an image, and so is '
            '`DsSkeleton.block` at any height, such as a button. A block '
            'takes the radius of media inside a card, the card radius less '
            'its padding (`radii.nested`), never rounder than a capsule.',
          ),
          Example(
            snippet: 'skeleton-shapes',
            child: _cardWidth(
              Builder(
                builder: (context) {
                  // #region skeleton-shapes
                  // Theme sizes:
                  final t = DsTheme.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      // An image: taller than 16px, so a block.
                      const DsSkeleton(height: 96),
                      const DsSkeleton(width: 160, height: 12, strong: true),
                      const DsSkeleton(),
                      const DsSkeleton(width: 220),
                      Row(
                        spacing: 12,
                        children: [
                          const DsSkeleton.circle(size: 32),
                          const DsSkeleton.circle(size: 32),
                          // A button.
                          DsSkeleton.block(width: 88, height: t.sizes.sm),
                        ],
                      ),
                    ],
                  );
                  // #endregion
                },
              ),
            ),
          ),
          const DocText(
            'A `borderRadius` in the style wins over all of these, for a '
            'shape that must match a control\'s corners exactly.',
          ),
        ],
      ),
      DocSection(
        title: 'Shimmer',
        children: [
          const DocText(
            'Wrap a group of skeletons, not each one, in `DsShimmer`, so one '
            'light sweeps across all of them. Give it the `borderRadius` of '
            'the container it fills, so the sweep stays inside the corners, '
            'and a `semanticLabel` that says what is loading. When the '
            'system asks to reduce motion, the sweep is off and the shapes '
            'stay still.',
          ),
          Example(
            snippet: 'skeleton-shimmer',
            child: _cardWidth(
              Builder(
                builder: (context) {
                  // #region skeleton-shimmer
                  // Theme radii:
                  final t = DsTheme.of(context);
                  return DsCard(
                    style: const DsCardStyle(padding: EdgeInsets.zero),
                    child: DsShimmer(
                      borderRadius: BorderRadius.circular(t.radii.card),
                      semanticLabel: 'Loading invoices',
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          spacing: 16,
                          children: [
                            for (var i = 0; i < 3; i++)
                              const Row(
                                spacing: 12,
                                children: [
                                  Expanded(child: DsSkeleton()),
                                  DsSkeleton(width: 56),
                                ],
                              ),
                          ],
                        ),
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
            'Change one shape with `style`, or every skeleton below a point '
            'with `DsSkeletonTheme`: its tones, default height and corners. '
            'The shimmer\'s light comes from the theme\'s `shimmer` color.',
          ),
          Example(
            snippet: 'skeleton-custom',
            child: _cardWidth(
              // #region skeleton-custom
              const DsSkeletonTheme(
                data: DsSkeletonThemeData(
                  style: DsSkeletonStyle(
                    height: 12,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                child: Column(
                  spacing: 10,
                  children: [DsSkeleton(), DsSkeleton(), DsSkeleton()],
                ),
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
            'Screen readers skip the shapes inside a `DsShimmer` and hear '
                'its `semanticLabel` instead. Set one, such as "Loading '
                'comments".',
            'A `DsSkeleton` outside a shimmer adds nothing for screen '
                'readers.',
            'The shimmer stops when the system asks to reduce motion.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsSkeleton'),
          ApiTable([
            ('width', 'double?', 'Null fills the available width.'),
            (
              'height',
              'double?',
              'Null uses the style\'s height (8). Over 16, a block.',
            ),
            ('strong', 'bool', 'Uses the darker tone.'),
            ('style', 'DsSkeletonStyle?', 'Tones, height and corners.'),
          ]),
          DocHeading('DsSkeleton.block'),
          ApiTable([
            ('width / height', 'double?', 'The block\'s size.'),
            ('strong', 'bool', 'Uses the darker tone.'),
          ]),
          DocHeading('DsSkeleton.circle'),
          ApiTable([
            ('size', 'double', 'The diameter.'),
            ('strong', 'bool', 'Uses the darker tone.'),
          ]),
          DocHeading('DsShimmer'),
          ApiTable([
            ('child', 'Widget', 'The skeleton layout.'),
            (
              'borderRadius',
              'BorderRadius',
              'Clips the sweep. Default `BorderRadius.zero`.',
            ),
            ('semanticLabel', 'String?', 'What is loading.'),
          ]),
        ],
      ),
    ],
  );
}

class _CommentDemo extends StatefulWidget {
  const _CommentDemo();

  @override
  State<_CommentDemo> createState() => _CommentDemoState();
}

class _CommentDemoState extends State<_CommentDemo> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    // #region skeleton-overview
    final placeholder = DsShimmer(
      borderRadius: BorderRadius.circular(DsTheme.of(context).radii.card),
      semanticLabel: 'Loading comment',
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(
              spacing: 12,
              children: [
                DsSkeleton.circle(size: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    DsSkeleton(width: 120, height: 10, strong: true),
                    DsSkeleton(width: 72),
                  ],
                ),
              ],
            ),
            DsSkeleton(),
            DsSkeleton(width: 180),
          ],
        ),
      ),
    );
    // #endregion
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsSwitch(
            label: const Text('Loading'),
            value: _loading,
            onChanged: (v) => setState(() => _loading = v),
          ),
        ),
        DsCard(
          style: const DsCardStyle(padding: EdgeInsets.zero),
          child: _loading
              ? placeholder
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          const DsAvatar(
                            initials: 'EK',
                            size: .sm,
                            semanticLabel: 'Elif Kaya',
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Elif Kaya',
                                style: t.typography.labelStrong.copyWith(
                                  color: k.text,
                                ),
                              ),
                              Text(
                                '2 hours ago',
                                style: t.typography.caption.copyWith(
                                  color: k.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'The new onboarding flow tested well. Can we ship it '
                        'behind a flag on Monday?',
                        style: t.typography.body.copyWith(color: k.text),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
