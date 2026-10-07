import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class BadgePage extends StatelessWidget {
  const BadgePage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'Badge',
    lead:
        'Small labels for status and counts. `DsBadge` names a state such '
        'as "Overdue"; `DsCount` shows a number such as unread messages; '
        '`DsStatusDot` marks presence such as "Online". `DsAnchoredBadge` '
        'pins any of them to the corner of an icon.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'badge-overview',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region badge-overview
                const DsBadge(status: .success, label: Text('Published')),
                DsAnchoredBadge(
                  badge: const DsCount(3, semanticLabel: '3 unread'),
                  child: DsButton.icon(
                    variant: .ghost,
                    icon: const DsIcon(DsIcons.bell),
                    semanticLabel: 'Notifications',
                    onPressed: () {},
                  ),
                ),
                const DsStatusDot(label: Text('Online')),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Status badges',
        children: [
          DocText(
            'Five statuses. `neutral` (the default) suits drafts and other '
            'quiet states. Each badge has a soft tint, text in the status '
            'ink and a dot, so status is never told by color alone.',
          ),
          Example(
            snippet: 'badge-statuses',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // #region badge-statuses
                DsBadge(label: Text('Draft')),
                DsBadge(status: .info, label: Text('New')),
                DsBadge(status: .success, label: Text('Published')),
                DsBadge(status: .warning, label: Text('In review')),
                DsBadge(status: .danger, label: Text('Overdue')),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Dot and icon',
        children: [
          DocText(
            'Replace the dot with a 12px `icon`, or hide it with '
            '`dot: false` when the word alone carries the meaning, such as '
            'a version tag.',
          ),
          Example(
            snippet: 'badge-icons',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // #region badge-icons
                DsBadge(
                  status: .success,
                  icon: DsIcon(DsIcons.check),
                  label: Text('Verified'),
                ),
                DsBadge(
                  status: .warning,
                  icon: DsIcon(DsIcons.clock),
                  label: Text('Expires soon'),
                ),
                DsBadge(dot: false, label: Text('v2.4')),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Counts',
        children: [
          const DocText(
            '`DsCount` uses tabular figures. Numbers above `max` (99 by '
            'default) show as "99+". `accent` marks unread items, `danger` '
            'items that need attention, and `neutral` plain totals, such as '
            'the count beside a tab or a list row.',
          ),
          Example(
            snippet: 'badge-counts',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region badge-counts
                const DsCount(4),
                const DsCount(128, tone: .danger),
                const DsCount(12, tone: .neutral),
                const DsCount(1500, max: 999, tone: .neutral),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Anchored to an icon',
        children: [
          const DocText(
            '`DsAnchoredBadge` places the badge on the top-end corner of its '
            'child, mirrored in right-to-left text. `offset` moves it out '
            'past the edge; wider counts need a larger x. The count draws a '
            '2px ring in the surface color to stand off what it covers. '
            'Screen readers hear the badge with its anchor, as one node '
            '("Messages, 2 new messages"), so name the count with its '
            '`semanticLabel`.',
          ),
          Example(
            snippet: 'badge-anchored',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // #region badge-anchored
                DsAnchoredBadge(
                  badge: const DsCount(2, semanticLabel: '2 new messages'),
                  child: DsButton.icon(
                    variant: .secondary,
                    icon: const DsIcon(DsIcons.mail),
                    semanticLabel: 'Messages',
                    onPressed: () {},
                  ),
                ),
                DsAnchoredBadge(
                  offset: const Offset(10, -6),
                  badge: const DsCount(
                    240,
                    tone: .danger,
                    semanticLabel: '99+ failed jobs',
                  ),
                  child: DsButton.icon(
                    variant: .secondary,
                    icon: const DsIcon(DsIcons.inbox),
                    semanticLabel: 'Jobs',
                    onPressed: () {},
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Status dot',
        children: [
          DocText(
            'A colored dot with a soft halo and a required label. `success` '
            'is the default. The label is required because a bare dot would '
            'tell the status by color alone.',
          ),
          Example(
            snippet: 'badge-dots',
            child: Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region badge-dots
                DsStatusDot(label: Text('Online')),
                DsStatusDot(status: .warning, label: Text('Away')),
                DsStatusDot(status: .danger, label: Text('Do not disturb')),
                DsStatusDot(status: .neutral, label: Text('Offline')),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Each part takes a `style`. `DsBadgeTheme` and '
            '`DsStatusDotTheme` take a style for every status and one per '
            'status in `statuses`; `DsCountTheme` takes one per tone in '
            '`tones`. Below, every badge is square-cornered and warnings '
            'use a brand orange.',
          ),
          Example(
            snippet: 'badge-custom',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // #region badge-custom
                DsBadgeTheme(
                  data: DsBadgeThemeData(
                    style: DsBadgeStyle(borderRadius: BorderRadius.circular(4)),
                    statuses: const {
                      DsStatus.warning: DsBadgeStyle(
                        foreground: Color(0xFF9A3412),
                        background: Color(0xFFFFEDD5),
                      ),
                    },
                  ),
                  child: const Wrap(
                    spacing: 8,
                    children: [
                      DsBadge(status: .info, label: Text('Beta')),
                      DsBadge(status: .warning, label: Text('Trial')),
                    ],
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Badges and status dots are read as their label text. Write a '
                'label that makes sense alone ("Overdue", not "!").',
            'A count is read as its number. Set `semanticLabel` to say '
                'what it counts ("3 unread").',
            'Label ink keeps 4.5:1 contrast on its tint in every status and '
                'both modes.',
            'Badge text keeps one line and grows the pill in height with '
                'large text instead of clipping.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsBadge'),
          ApiTable([
            ('label', 'Widget', 'The text, usually a short `Text`.'),
            ('status', 'DsStatus', 'Defaults to `neutral`.'),
            ('dot', 'bool', 'Shows the leading dot. Default `true`.'),
            ('icon', 'Widget?', 'Replaces the dot.'),
            ('style', 'DsBadgeStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsCount'),
          ApiTable([
            ('count', 'int', 'The number (positional).'),
            ('tone', 'DsCountTone', '`accent` (default), `danger`, `neutral`.'),
            ('max', 'int', 'Larger counts show as `max+`. Default 99.'),
            ('semanticLabel', 'String?', 'Replaces the announced number.'),
            ('style', 'DsCountStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsAnchoredBadge'),
          ApiTable([
            ('child', 'Widget', 'The anchor, such as an icon button.'),
            ('badge', 'Widget', 'Usually a `DsCount`.'),
            (
              'offset',
              'Offset',
              'Past the end edge (x) and above the top (y). Default (5, -4).',
            ),
          ]),
          DocHeading('DsStatusDot'),
          ApiTable([
            ('label', 'Widget', 'Text beside the dot. Required.'),
            ('status', 'DsStatus', 'Defaults to `success`.'),
            ('style', 'DsStatusDotStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}
