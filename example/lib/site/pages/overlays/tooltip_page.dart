import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Tooltips with optional shortcut hints.
class TooltipPage extends StatelessWidget {
  const TooltipPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Overlays',
    title: 'Tooltip',
    lead:
        'A short label for a control, mostly for icon buttons. It names '
        'the control and can show its keyboard shortcut. Anything people '
        'must read or click belongs in a [Popover](/components/popover) '
        'instead.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(snippet: 'tooltip-overview', child: _OverviewDemo()),
        ],
      ),
      DocSection(
        title: 'Shortcut hints',
        children: [
          DocText(
            '`shortcut` adds a muted key hint after the message. The Command, '
            'Option, Shift, Delete and Return symbols are drawn as icons, so '
            'they look the same in every font. Show the shortcut of the '
            'platform people use.',
          ),
          Example(snippet: 'tooltip-shortcut', child: _ShortcutDemo()),
        ],
      ),
      DocSection(
        title: 'Placement',
        children: [
          DocText(
            'A tooltip prefers the top of its control and centers on it. '
            '`side` picks another side; near a window edge it flips. Put '
            'tooltips of a vertical rail on the `end` side so they do not '
            'cover the neighbors.',
          ),
          Example(snippet: 'tooltip-side', child: _SideDemo()),
        ],
      ),
      DocSection(
        title: 'When it shows',
        children: [
          DocList([
            'After the pointer rests on the control for 500ms, at once when '
                'another tooltip has just closed, so moving along a toolbar '
                'feels quick.',
            'When the control gets keyboard focus, and after a long press '
                'on touch screens.',
            'It stays while the pointer moves onto the tooltip itself, and '
                'hides on Escape, on a press on the control, or when the '
                'pointer and focus leave.',
          ]),
          DocText(
            'This follows WCAG 1.4.13 (content on hover or focus). The delays '
            'come from the theme\'s motion (`hoverDelay`, `hoverGrace`).',
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            '`style` changes one tooltip (`DsTooltipStyle`: `maxWidth`, '
            '`padding`, `background`…), `DsTooltipTheme` a part of the app. '
            'Long messages wrap at 280px by default.',
          ),
          Example(snippet: 'tooltip-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Focusing the control shows its tooltip.'),
            (
              'Escape',
              'Hides the tooltip. That Escape stops there: a dialog behind '
                  'it stays open.',
            ),
          ]),
          DocText(
            'See [Layer behavior](/components/popover) for what all layers '
            'share.',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Screen readers get the message as the control\'s own tooltip, '
                'on the same node, and do not read the floating label twice. '
                'Wrap a single control, not a group.',
            'A tooltip does not name an icon button. Give the button its own '
                '`semanticLabel` as well.',
            'The tooltip never takes focus, so it cannot hold links or '
                'buttons.',
            'Message and shortcut keep 4.5:1 contrast on the tooltip fill in '
                'both modes and every contrast level.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('message', 'String', 'The label.'),
            ('child', 'Widget', 'The control it describes.'),
            ('shortcut', 'String?', 'A key hint after the message, muted.'),
            ('side', 'DsSide', 'Preferred side; `top` by default.'),
            ('style', 'DsTooltipStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _OverviewDemo extends StatelessWidget {
  const _OverviewDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      // #region tooltip-overview
      DsTooltip(
        message: 'Share',
        child: DsButton.icon(
          variant: .ghost,
          icon: const DsIcon(DsIcons.share),
          semanticLabel: 'Share',
          onPressed: () {},
        ),
      ),
      DsTooltip(
        message: 'Notifications',
        child: DsButton.icon(
          variant: .ghost,
          icon: const DsIcon(DsIcons.bell),
          semanticLabel: 'Notifications',
          onPressed: () {},
        ),
      ),
      DsTooltip(
        message: 'Settings',
        child: DsButton.icon(
          variant: .ghost,
          icon: const DsIcon(DsIcons.settings),
          semanticLabel: 'Settings',
          onPressed: () {},
        ),
      ),
      // #endregion
    ],
  );
}

class _ShortcutDemo extends StatelessWidget {
  const _ShortcutDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      // #region tooltip-shortcut
      DsTooltip(
        message: 'Copy link',
        shortcut: '⇧⌘C',
        child: DsButton.icon(
          variant: .secondary,
          icon: const DsIcon(DsIcons.link),
          semanticLabel: 'Copy link',
          onPressed: () {},
        ),
      ),
      DsTooltip(
        message: 'Search',
        shortcut: '⌘K',
        child: DsButton(
          variant: .secondary,
          leading: const DsIcon(DsIcons.search),
          onPressed: () {},
          child: const Text('Search'),
        ),
      ),
      // #endregion
    ],
  );
}

class _SideDemo extends StatelessWidget {
  const _SideDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      // #region tooltip-side
      for (final (side, label) in [
        (DsSide.top, 'Top'),
        (DsSide.bottom, 'Bottom'),
        (DsSide.start, 'Start'),
        (DsSide.end, 'End'),
      ])
        DsTooltip(
          message: 'Opens on the ${side.name} side',
          side: side,
          child: DsButton(
            variant: .secondary,
            onPressed: () {},
            child: Text(label),
          ),
        ),
      // #endregion
    ],
  );
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) {
    // #region tooltip-custom
    return DsTooltip(
      message: 'Show only the tasks assigned to you, in every project',
      style: const DsTooltipStyle(maxWidth: 200),
      child: DsButton.icon(
        variant: .ghost,
        icon: const DsIcon(DsIcons.user),
        semanticLabel: 'My tasks',
        onPressed: () {},
      ),
    );
    // #endregion
  }
}
