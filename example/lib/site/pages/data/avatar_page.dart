import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Data display',
    title: 'Avatar',
    lead:
        'A round picture of a person: a photo, their initials, or a person '
        'icon. `DsAvatarGroup` overlaps several of them, for the people on '
        'a project or editing a document.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'avatar-overview',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region avatar-overview
                const DsAvatar(initials: 'DA', semanticLabel: 'Deniz Aksoy'),
                const DsAvatarGroup(
                  semanticLabel: '6 people on this project',
                  avatars: [
                    DsAvatar(initials: 'DA'),
                    DsAvatar(initials: 'EK'),
                    DsAvatar(initials: 'MÖ'),
                    DsAvatar(initials: 'ZT'),
                    DsAvatar(initials: 'SL'),
                    DsAvatar(initials: 'JR'),
                  ],
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Sizes',
        children: [
          DocText(
            'Four sizes: 24, 32, 40 and 48px. `md` (40px) is the default. '
            'Initials scale with the circle, not with the text size setting, '
            'so they always fit.',
          ),
          Example(
            snippet: 'avatar-sizes',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region avatar-sizes
                DsAvatar(initials: 'AK', size: .xs),
                DsAvatar(initials: 'AK', size: .sm),
                DsAvatar(initials: 'AK', size: .md),
                DsAvatar(initials: 'AK', size: .lg),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Content and tones',
        children: [
          const DocText(
            'An avatar shows `image` when given, else `initials` (up to two '
            'letters), else a person icon. The initials show until the photo '
            'has loaded, and stay when it fails to load, so the circle is '
            'never empty. Photos are decoded at the size of the '
            'circle, so a 12 MP upload costs about 100 KB of memory.',
          ),
          const DocText(
            'Initials and icons sit on one of eight soft tones turned from '
            'the selection color (tinted by the brand, gray for a warm brand '
            'in dark mode), each readable at 4.5:1. `toneIndex` picks one; '
            '`DsAvatar.toneFor(id)` gives each person the same tone '
            'everywhere.',
          ),
          Example(
            snippet: 'avatar-tones',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region avatar-tones
                for (final name in [
                  'Deniz Aksoy',
                  'Elif Kaya',
                  'Mert Özkan',
                  'Zeynep Tunç',
                  'Sam Lee',
                ])
                  DsAvatar(
                    initials: name.split(' ').map((w) => w[0]).join(),
                    toneIndex: DsAvatar.toneFor(name),
                    semanticLabel: name,
                  ),
                const DsAvatar(semanticLabel: 'Guest'),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Status',
        children: [
          const DocText(
            '`status` adds a dot on the bottom-end edge, ringed in the '
            'surface color. Screen readers hear it after the name: "Elif '
            'Kaya, Online". The words follow the app\'s language: success is '
            'Online, warning Away, danger Busy and neutral Offline. '
            '`statusLabel` says something else, such as "In a meeting". '
            'Keep `semanticLabel` to the name.',
          ),
          Example(
            snippet: 'avatar-status',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // #region avatar-status
                const DsAvatar(
                  initials: 'EK',
                  toneIndex: 2,
                  status: .success,
                  semanticLabel: 'Elif Kaya',
                ),
                const DsAvatar(
                  initials: 'MÖ',
                  toneIndex: 5,
                  status: .warning,
                  semanticLabel: 'Mert Özkan',
                ),
                const DsAvatar(
                  initials: 'ZT',
                  toneIndex: 3,
                  status: .info,
                  statusLabel: 'In a meeting',
                  semanticLabel: 'Zeynep Tunç',
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Groups',
        children: [
          const DocText(
            'A group shows at most `max` avatars (4 by default). Past that, '
            'the last place becomes a "+N" bubble. Each avatar is overlapped '
            'by a fifth of its width and ringed in the surface color, and '
            'neighbors get different tones unless you set them. All avatars '
            'in a group take the group\'s `size`. Status dots show in a group '
            'too: the group draws them above the stack, so the next avatar '
            'never covers them.',
          ),
          Example(
            snippet: 'avatar-group',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region avatar-group
                const DsAvatarGroup(
                  size: .xs,
                  max: 3,
                  semanticLabel: '5 reviewers',
                  avatars: [
                    DsAvatar(initials: 'DA'),
                    DsAvatar(initials: 'EK'),
                    DsAvatar(initials: 'MÖ'),
                    DsAvatar(initials: 'ZT'),
                    DsAvatar(initials: 'SL'),
                  ],
                ),
                const DsAvatarGroup(
                  size: .md,
                  semanticLabel: '9 people editing, 2 online',
                  avatars: [
                    DsAvatar(initials: 'AK', status: .success),
                    DsAvatar(initials: 'MD', status: .success),
                    DsAvatar(initials: 'EÖ', status: .neutral),
                    DsAvatar(initials: 'ZT'),
                    DsAvatar(initials: 'BC'),
                    DsAvatar(initials: 'NY'),
                    DsAvatar(initials: 'SG'),
                    DsAvatar(initials: 'HO'),
                    DsAvatar(initials: 'JR'),
                  ],
                ),
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
            'The ring around grouped avatars and status dots defaults to '
            'the surface color. On another background, such as the page '
            'canvas or a selected row, set `ringColor` to that color so the '
            'ring blends in. `DsAvatarTheme` sets the default `size` and '
            'takes a style per size in `sizes`; `DsAvatarGroupTheme` sets '
            'the groups\' default `size`.',
          ),
          Example(
            snippet: 'avatar-custom',
            child: Builder(
              builder: (context) {
                // #region avatar-custom
                // On the page canvas:
                final k = DsTheme.colorsOf(context);
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: k.canvas,
                  child: DsAvatarGroup(
                    style: DsAvatarGroupStyle(ringColor: k.canvas),
                    avatars: const [
                      DsAvatar(initials: 'DA'),
                      DsAvatar(initials: 'EK'),
                      DsAvatar(initials: 'MÖ'),
                    ],
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
            'An avatar is announced as an image named by `semanticLabel`, '
                'or by its initials when there is none. Pass the full name.',
            'A group with `semanticLabel` is read as that one label. '
                'Without it, each avatar is read, then "N more".',
            'Initials keep 4.5:1 contrast on every tone, in both modes and '
                'with any brand color.',
            'The status is read after the name ("Elif Kaya, Online"), so it '
                'is never told by color alone. `statusLabel` replaces the '
                'word.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsAvatar'),
          ApiTable([
            ('initials', 'String?', 'Up to two letters.'),
            ('image', 'ImageProvider?', 'A photo, decoded at the circle size.'),
            (
              'size',
              'DsSize?',
              '`xs`, `sm`, `md` or `lg`. Defaults to the theme\'s, then `md`.',
            ),
            (
              'status',
              'DsStatus?',
              'A dot on the bottom-end edge, read after the name.',
            ),
            (
              'statusLabel',
              'String?',
              'What screen readers hear for `status`; "Online", "Away"… by '
                  'default.',
            ),
            (
              'toneIndex',
              'int?',
              'One of 8 tones; wraps around. See `DsAvatar.toneFor`.',
            ),
            ('semanticLabel', 'String?', 'The person\'s name.'),
            ('style', 'DsAvatarStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsAvatarGroup'),
          ApiTable([
            ('avatars', 'List<DsAvatar>', 'The avatars, in order.'),
            (
              'size',
              'DsSize?',
              'Every avatar\'s size. Defaults to the theme\'s, then `sm`.',
            ),
            ('max', 'int', 'Most shown, counting "+N". Default 4.'),
            ('semanticLabel', 'String?', 'Describes the whole group.'),
            (
              'style',
              'DsAvatarGroupStyle?',
              'Ring, overlap and the "+N" bubble.',
            ),
          ]),
        ],
      ),
    ],
  );
}
