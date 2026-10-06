import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The pre-1.0 API round, rule 7: links, breadcrumbs, avatars, counts,
/// status dots, progress, spinners and skeletons take a generated style
/// and theme instead of ad-hoc look parameters.
void main() {
  final theme = DsThemeData.light();
  const red = Color(0xFFFF0000);

  Size sizeOf(WidgetTester tester, Finder finder) => tester.getSize(finder);

  testWidgets('progress bar: style height, theme fill', (tester) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsProgressBarTheme(
          data: DsProgressBarThemeData(
            style: DsProgressBarStyle(fillColor: red),
          ),
          child: SizedBox(
            width: 200,
            child: DsProgressBar(
              value: .5,
              style: DsProgressBarStyle(height: 4),
            ),
          ),
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsProgressBar)).height, 4);
    final fill = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(DsProgressBar),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      fill.any(
        (b) => switch (b.decoration) {
          DsBoxDecoration(:final color) => color == red,
          _ => false,
        },
      ),
      isTrue,
    );
  });

  testWidgets('progress ring and spinner take their size from the style', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsProgressRing(value: .3, style: DsProgressRingStyle(size: 60)),
            DsSpinner(style: DsSpinnerStyle(size: 30)),
          ],
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsProgressRing)), const Size(60, 60));
    expect(sizeOf(tester, find.byType(DsSpinner)), const Size(30, 30));
  });

  testWidgets('a spinner follows the icon theme when no style sizes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const IconTheme(data: IconThemeData(size: 32), child: DsSpinner()),
      ),
    );
    expect(sizeOf(tester, find.byType(DsSpinner)), const Size(28, 28));
  });

  testWidgets('skeleton: theme height and color, own width', (tester) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsSkeletonTheme(
          data: DsSkeletonThemeData(
            style: DsSkeletonStyle(height: 12, color: red),
          ),
          child: DsSkeleton(width: 80),
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsSkeleton)), const Size(80, 12));
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(DsSkeleton),
        matching: find.byType(Container),
      ),
    );
    expect((box.decoration! as DsBoxDecoration).color, red);
  });

  testWidgets('avatar: per-size theme, style colors win over the tone', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsAvatarTheme(
          data: DsAvatarThemeData(
            sizes: {DsSize.md: DsAvatarStyle(diameter: 44)},
          ),
          child: DsAvatar(
            initials: 'AK',
            toneIndex: 3,
            style: DsAvatarStyle(foreground: red),
          ),
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsAvatar)), const Size(44, 44));
    expect(tester.widget<Text>(find.text('AK')).style!.color, red);
  });

  testWidgets('avatar group overlaps by the style fraction', (tester) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsAvatarGroup(
          size: DsSize.md,
          style: DsAvatarGroupStyle(overlap: .5),
          avatars: [
            DsAvatar(initials: 'A'),
            DsAvatar(initials: 'B'),
          ],
        ),
      ),
    );
    // Two 40px avatars, the first half covered: 20 + 40.
    expect(sizeOf(tester, find.byType(DsAvatarGroup)).width, 60);
  });

  testWidgets('avatar and group sizes default from their themes', (
    tester,
  ) async {
    const avatars = [DsAvatar(initials: 'A'), DsAvatar(initials: 'B')];
    // Without a theme: an avatar is md (40), a group sm (32).
    await tester.pumpWidget(
      host(
        theme: theme,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsAvatar(initials: 'C'),
            DsAvatarGroup(
              style: DsAvatarGroupStyle(overlap: 0, ringWidth: 0),
              avatars: avatars,
            ),
          ],
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsAvatar).first), const Size(40, 40));
    expect(sizeOf(tester, find.byType(DsAvatarGroup)).width, 64);

    await tester.pumpWidget(
      host(
        theme: theme,
        const DsAvatarTheme(
          data: DsAvatarThemeData(size: DsSize.xs),
          child: DsAvatarGroupTheme(
            data: DsAvatarGroupThemeData(size: DsSize.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsAvatar(initials: 'C'),
                DsAvatar(initials: 'D', size: DsSize.sm),
                DsAvatarGroup(
                  style: DsAvatarGroupStyle(overlap: 0, ringWidth: 0),
                  avatars: avatars,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(sizeOf(tester, find.byType(DsAvatar).at(0)), const Size(24, 24));
    expect(sizeOf(tester, find.byType(DsAvatar).at(1)), const Size(32, 32));
    expect(sizeOf(tester, find.byType(DsAvatarGroup)).width, 96);
  });

  testWidgets('bottom nav variant and per-variant styles come from the theme', (
    tester,
  ) async {
    const items = [
      DsBottomNavItem(value: 0, icon: DsIcon(DsIcons.house), label: Text('A')),
      DsBottomNavItem(value: 1, icon: DsIcon(DsIcons.user), label: Text('B')),
    ];
    Widget nav({DsBottomNavVariant? variant}) => SizedBox(
      width: 360,
      child: Align(
        child: DsBottomNav<int>(
          variant: variant,
          items: items,
          value: 0,
          onChanged: (_) {},
        ),
      ),
    );
    Widget themed(Widget child) => DsBottomNavTheme(
      data: const DsBottomNavThemeData(
        variant: DsBottomNavVariant.bar,
        variants: {DsBottomNavVariant.bar: DsBottomNavStyle(background: red)},
      ),
      child: DsBottomNavItemTheme(
        data: const DsBottomNavItemThemeData(
          variants: {DsBottomNavVariant.bar: DsBottomNavItemStyle(height: 60)},
        ),
        child: child,
      ),
    );
    bool paintsRed() => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(DsBottomNav<int>),
            matching: find.byType(DecoratedBox),
          ),
        )
        .any((b) => (b.decoration as DsBoxDecoration?)?.color == red);

    await tester.pumpWidget(host(theme: theme, nav()));
    final floatingWidth = sizeOf(tester, find.byType(DsBottomNav<int>)).width;
    expect(floatingWidth, lessThan(360), reason: 'floating by default');

    await tester.pumpWidget(
      host(
        theme: theme,
        DsBottomNavTheme(
          data: const DsBottomNavThemeData(variant: DsBottomNavVariant.bar),
          child: nav(),
        ),
      ),
    );
    final barHeight = sizeOf(tester, find.byType(DsBottomNav<int>)).height;

    await tester.pumpWidget(host(theme: theme, themed(nav())));
    expect(sizeOf(tester, find.byType(DsBottomNav<int>)).width, 360);
    expect(paintsRed(), isTrue);
    expect(
      sizeOf(tester, find.byType(DsBottomNav<int>)).height,
      barHeight + 8,
      reason: 'bar items 60 tall instead of 52, from the item theme',
    );

    // The widget's own variant wins over the theme's.
    await tester.pumpWidget(
      host(theme: theme, themed(nav(variant: DsBottomNavVariant.floating))),
    );
    expect(sizeOf(tester, find.byType(DsBottomNav<int>)).width, floatingWidth);
    expect(paintsRed(), isFalse);
  });

  testWidgets('count and status dot take per-variant theme styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        const DsCountTheme(
          data: DsCountThemeData(
            tones: {DsCountTone.danger: DsCountStyle(minSize: 24)},
          ),
          child: DsStatusDotTheme(
            data: DsStatusDotThemeData(
              statuses: {DsStatus.danger: DsStatusDotStyle(dotSize: 12)},
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsCount(3, tone: DsCountTone.danger),
                DsCount(3),
                DsStatusDot(status: DsStatus.danger, label: Text('Down')),
              ],
            ),
          ),
        ),
      ),
    );
    final counts = find.byType(DsCount);
    expect(sizeOf(tester, counts.first).height, 24);
    expect(sizeOf(tester, counts.last).height, 18);
    final dot = find.descendant(
      of: find.byType(DsStatusDot),
      matching: find.byType(Container),
    );
    expect(sizeOf(tester, dot.first), const Size(12, 12));
  });

  testWidgets('link and breadcrumb take their colors from the style', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: theme,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsLink(
              label: 'Docs',
              onPressed: () {},
              style: const DsLinkStyle(foreground: red),
            ),
            DsBreadcrumb(
              style: const DsBreadcrumbStyle(
                selected: DsBreadcrumbStyle(foreground: red),
              ),
              items: [
                DsBreadcrumbItem(label: 'Home', onPressed: () {}),
                const DsBreadcrumbItem(label: 'Page'),
              ],
            ),
          ],
        ),
      ),
    );
    final link = tester.widget<Text>(
      find.descendant(of: find.byType(DsLink), matching: find.byType(Text)),
    );
    expect(link.textSpan!.style!.color, red);
    expect(tester.widget<Text>(find.text('Page')).style!.color, red);
    expect(
      tester.widget<Text>(find.text('Home')).style!.color,
      theme.colors.textMuted,
    );
  });
}
