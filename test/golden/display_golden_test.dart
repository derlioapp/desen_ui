@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for the display components (avatar, status, count,
/// skeleton, progress, link, breadcrumb, card), light and dark.
void main() {
  // Freeze endless animations (shimmer, indeterminate progress).
  Map<String, DsThemeData> frozen(DsSeed seed) => {
    for (final MapEntry(:key, :value) in themesFor(seed).entries)
      key: value.copyWith(motion: const DsMotion(reduced: true)),
  };

  Widget panel(double width, Widget child) =>
      SizedBox(width: width, child: child);

  for (final MapEntry(key: mode, value: theme) in frozen(DsSeed.blue).entries) {
    testWidgets('badges and counts $mode', (tester) async {
      final ring = DsCountStyle(ringColor: theme.colors.canvas);
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                for (final s in DsStatus.values)
                  DsBadge(status: s, label: Text(s.name)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                for (final tone in DsCountTone.values) ...[
                  // The bubbles sit on the canvas here, not the surface.
                  DsCount(3, tone: tone, style: ring),
                  DsCount(128, tone: tone, style: ring),
                ],
                for (final s in DsStatus.values)
                  DsStatusDot(status: s, label: Text(s.name)),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/badges_$mode.png');
    });

    testWidgets('avatars $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                for (final s in DsSize.values)
                  DsAvatar(initials: 'AK', size: s, toneIndex: s.index),
                DsAvatar(
                  initials: 'EÖ',
                  status: .success,
                  style: DsAvatarStyle(ringColor: theme.colors.canvas),
                ),
                const DsAvatar(size: .lg),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                for (var i = 0; i < DsAvatar.toneCount; i++)
                  DsAvatar(initials: 'MD', size: .sm, toneIndex: i),
              ],
            ),
            DsAvatarGroup(
              style: DsAvatarGroupStyle(ringColor: theme.colors.canvas),
              // Status dots stay above the next avatar.
              avatars: const [
                DsAvatar(initials: 'AK', status: .success),
                DsAvatar(initials: 'MD', status: .warning),
                DsAvatar(initials: 'EÖ'),
                DsAvatar(initials: 'ZT'),
                DsAvatar(initials: 'BC'),
              ],
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/avatars_$mode.png');
    });

    testWidgets('alerts and progress $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        panel(
          360,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final s in [
                DsStatus.info,
                DsStatus.success,
                DsStatus.warning,
                DsStatus.danger,
              ])
                DsAlert(
                  status: s,
                  title: Text('${s.name} başlığı'),
                  description: const Text(
                    'Açıklama metni iki satıra kadar uzayabilir.',
                  ),
                ),
              const SizedBox(height: 8),
              for (final v in [0.0, .3, .64, 1.0]) DsProgressBar(value: v),
              const SizedBox(height: 8),
              const Row(
                spacing: 12,
                children: [
                  DsProgressRing(value: 0),
                  DsProgressRing(value: .3),
                  DsProgressRing(value: .72),
                  DsProgressRing(value: 1),
                ],
              ),
            ],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/alerts_progress_$mode.png');
    });

    testWidgets('card, skeleton and links $mode', (tester) async {
      await pumpGolden(
        tester,
        theme: theme,
        panel(
          360,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const DsCard(child: Text('Kart içeriği')),
              const DsCard(
                child: DsShimmer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          DsSkeleton.circle(size: 36),
                          DsSkeleton(width: 140, height: 10, strong: true),
                        ],
                      ),
                      // A block (an image) takes the theme's corners.
                      DsSkeleton(height: 72),
                      DsSkeleton(),
                      DsSkeleton(width: 200),
                      DsSkeleton.block(width: 88, height: 28),
                    ],
                  ),
                ),
              ),
              DsBreadcrumb(
                items: [
                  DsBreadcrumbItem(label: 'Projeler', onPressed: () {}),
                  DsBreadcrumbItem(label: 'Derlio Web', onPressed: () {}),
                  const DsBreadcrumbItem(label: 'Ayarlar'),
                ],
              ),
              Row(
                spacing: 16,
                children: [
                  DsLink(label: 'kılavuz', onPressed: () {}),
                  DsLink(label: 'destek', external: true, onPressed: () {}),
                  const DsLink(label: 'pasif', onPressed: null),
                ],
              ),
            ],
          ),
        ),
      );
      await expectGolden(tester, 'goldens/card_skeleton_links_$mode.png');
    });

    // A long path: wrapped (each separator stays with the level before
    // it), collapsed to one line ("…" for the middle levels), and as a
    // pane header title at 390.
    testWidgets('breadcrumb overflow $mode', (tester) async {
      List<DsBreadcrumbItem> path() => [
        for (final label in [
          'Acme',
          'Website redesign',
          'Settings',
          'Integrations',
        ])
          DsBreadcrumbItem(label: label, onPressed: () {}),
        const DsBreadcrumbItem(label: 'Webhooks'),
      ];
      Widget caption(String text) => Text(
        text,
        style: theme.typography.caption.copyWith(
          color: theme.colors.textSubtle,
        ),
      );
      await pumpGolden(
        tester,
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            caption('wrap · 260'),
            panel(260, DsBreadcrumb(items: path())),
            caption('collapse · 260'),
            panel(
              260,
              DsBreadcrumb(
                items: path(),
                overflow: DsBreadcrumbOverflow.collapse,
              ),
            ),
            caption('pane header · 390'),
            panel(
              390,
              ColoredBox(
                color: theme.colors.surface,
                child: DsPaneHeader(
                  title: DsBreadcrumb(
                    items: [
                      DsBreadcrumbItem(label: 'Acme', onPressed: () {}),
                      DsBreadcrumbItem(
                        label: 'Website redesign',
                        onPressed: () {},
                      ),
                      const DsBreadcrumbItem(label: 'Launch plan'),
                    ],
                  ),
                  actions: [
                    DsButton.icon(
                      icon: const DsIcon(DsIcons.ellipsis),
                      semanticLabel: 'More',
                      onPressed: () {},
                    ),
                    DsButton(
                      variant: .primary,
                      size: .sm,
                      onPressed: () {},
                      child: const Text('Publish'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      await expectGolden(tester, 'goldens/breadcrumb_overflow_$mode.png');
    });
  }

  testWidgets('status colors across tones', (tester) async {
    Widget row(DsSeed seed, Brightness b) => DsTheme(
      data: DsThemeData(seed: seed, brightness: b, platform: goldenPlatform),
      child: Builder(
        builder: (context) => Container(
          color: DsTheme.colorsOf(context).canvas,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              for (final s in DsStatus.values)
                DsBadge(status: s, label: Text(s.name)),
              const DsCount(7),
              const DsAvatar(initials: 'AK', size: .sm),
              const SizedBox(width: 120, child: DsProgressBar(value: .6)),
            ],
          ),
        ),
      ),
    );
    await pumpGolden(
      tester,
      theme: DsThemeData(platform: goldenPlatform),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in Brightness.values)
            for (final seed in const [
              DsSeed.blue,
              DsSeed.navy,
              DsSeed.graphite,
              DsSeed.oxblood,
              DsSeed.forest,
              DsSeed.indigo,
            ])
              row(seed, b),
        ],
      ),
    );
    await expectGolden(tester, 'goldens/display_tones.png');
  });
}
